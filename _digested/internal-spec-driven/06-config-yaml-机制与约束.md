# 06 — config.yaml 的机制与约束

前五篇讲的是 schema 驱动的四条命令。但还有一层控制面经常被忽略：`openspec/config.yaml`。它不定义工作流的结构（那是 schema 的事），但它在工作流执行的**每一步**都会被读取和注入。

这篇从源码出发，精确说明 config.yaml 是什么、有什么约束、怎么被消费、以及怎样利用它。

---

## 1. config.yaml 是什么

位于 `<projectRoot>/openspec/config.yaml`（也接受 `.yml`）。它是 **项目级的配置补丁**，叠加在 schema 之上。

**它不是什么**：
- 不是 schema（不定义 artifact DAG）
- 不是 spec（不定义系统能力）
- 不是 change 元数据（不写 `.openspec.yaml` 里的东西）

**它是**：一份告诉 OpenSpec CLI "在这个项目里，AI agent 在生成内容时应该知道哪些背景、遵守哪些约束"的配置文件。

---

## 2. Zod Schema：精确的类型约束

定义在 `src/core/project-config.ts:19-41`：

```typescript
const ProjectConfigSchema = z.object({
  schema: z.string().min(1),                    // 必填：默认使用的 schema 名
  context: z.string().max(51200).optional(),     // 可选：项目背景，最大 50KB
  rules: z.record(                              // 可选：按 artifact ID 的规则
    z.string(),
    z.array(z.string())
  ).optional(),
});
```

### 字段约束表

| 字段 | 必填 | 类型 | 约束 | 默认值 |
|------|------|------|------|--------|
| `schema` | 是 | `string` | 非空 | 无（`openspec init` 自动写入 `spec-driven`） |
| `context` | 否 | `string` | 最大 **50KB**（51,200 字节） | 无 |
| `rules` | 否 | `Record<string, string[]>` | key 应为合法的 artifact ID | 无 |

### 50KB 限制

`project-config.ts:45`：
```typescript
export const MAX_CONTEXT_LENGTH = 50 * 1024; // 50KB
```

如果 `context` 字段超过 50KB，**整个 context 被静默忽略**（产生一个 warning）。不会截断 —— 全有或全无。

### rules key 验证

`config.yaml` 的 `rules` 字段 key 不强制与 schema 的 artifact ID 匹配 —— 但你写了一个不存在的 artifact ID，会在**每次 session 首次生成指令时**产生一个 warning：

```
Warning: config.yaml rules contains unknown artifact ID "review" for schema "spec-driven"
```

验证逻辑在 `instruction-loader.ts:301-316`：
```typescript
if (projectConfig?.rules) {
  const validArtifactIds = new Set(context.graph.getAllArtifacts().map(a => a.id));
  const warnings = validateConfigRules(projectConfig.rules, validArtifactIds, context.schemaName);
  for (const warning of warnings) {
    if (!shownWarnings.has(warning)) {
      console.warn(warning);
      shownWarnings.add(warning);  // 每个 session 只警告一次
    }
  }
}
```

---

## 3. config.yaml 在何时被读取

config.yaml 不是在启动时一次性全局读取的，而是**在需要时才读**。具体时机：

### 时机 1：`openspec instructions <artifact>` 被调用时

`instruction-loader.ts:290-298`：
```typescript
let projectConfig = null;
if (effectiveProjectRoot) {
  try {
    projectConfig = readProjectConfig(effectiveProjectRoot);
  } catch {
    // 读不到就跳过，不阻塞指令生成
  }
}
```

即每次 agent 调用 `openspec instructions proposal --change X --json`，都会重新读 config.yaml。这保证了**最新修改立即生效**，不需要重启或重新 init。

### 时机 2：`openspec new change` 创建 change 时

`change-utils.ts:132-147`：读取 `config.schema` 来决定新 change 的默认 schema。

### 时机 3：`openspec status` 显示 nextSteps 时

`change-status-policy.ts` 中 `buildActionContext()` 使用 config 信息构造机器可读约束。

### resilience 设计

config 读取失败（文件不存在、YAML 解析错误、字段类型不匹配）**不会抛异常中断流程**。每个消费点都有独立的 try/catch，失败时降级为空 config。

---

## 4. context 和 rules 如何注入到指令中

### 4.1 context 的注入

来自 `config.context`。在 `generateInstructions()` (`instruction-loader.ts:319`)：

```typescript
const configContext = projectConfig?.context?.trim() || undefined;
```

注入后的效果（printInstructionsText 的格式化输出）：

```xml
<project_context>
<!-- This is background information for you. Do NOT include this in your output. -->

Project: ProcureFlow
Domain: Internal procurement request and approval platform
Stack: TypeScript, React, Node.js, PostgreSQL
</project_context>
```

**关键**：`context` 被包裹在 `<!-- -->` 注释中，且明确标注 "Do NOT include this in your output"。它是给 AI agent 看的背景信息，**不是给输出文件的内容**。

### 4.2 rules 的注入

来自 `config.rules[artifactId]`。在 `generateInstructions()` (`instruction-loader.ts:320-321`)：

```typescript
const rulesForArtifact = projectConfig?.rules?.[artifactId];
const configRules = rulesForArtifact && rulesForArtifact.length > 0 ? rulesForArtifact : undefined;
```

注入后的效果：

```xml
<rules>
<!-- These are constraints for you to follow. Do NOT include this in your output. -->
- Keep proposals under 500 words
- Always include a "Non-goals" section
</rules>
```

同样被包裹在注释中，同样标注 "Do NOT include in your output"。

### 4.3 context vs rules 的区别

| | context | rules |
|------|------|------|
| **作用范围** | 所有 artifact 共享 | 按 artifact ID 分别注入 |
| **内容类型** | 项目背景信息（技术栈、领域等） | 可执行的工程约束 |
| **AI 怎么用** | 理解项目上下文 | 遵守具体规则 |
| **典型长度** | 屏幕半页 | 3-5 条规则 |
| **注入位置** | `<project_context>` 标签 | `<rules>` 标签 |

---

## 5. config.yaml 与 schema.yaml 的交互

### 5.1 `config.schema` 是桥梁

```yaml
# config.yaml
schema: spec-driven     # 选择用哪个 schema
```

这个字段决定了：
- `openspec new change` 创建 change 时用哪个 schema
- `openspec instructions` 加载哪个 DAG 的 artifact 定义
- `openspec status` 按哪个 DAG 判断 artifact 状态

### 5.2 rules key 校验依赖 schema

`config.rules` 的 key（artifact ID）是否合法，取决于所选 schema 定义了哪些 artifact：

```yaml
# config.yaml
schema: spec-driven
rules:
  proposal: [...]    # ✓ spec-driven 有 proposal artifact
  specs: [...]       # ✓ spec-driven 有 specs artifact
  review: [...]      # ✗ spec-driven 没有 review → 会产生 warning
```

### 5.3 context 的 50KB 限制是全局的

无论选什么 schema，`context` 字段共享同一个 50KB 上限。这是运行时硬限制，不在 schema 定义中。

---

## 6. 技术层面的推荐

### 6.1 rules 应该按 artifact 角色写

不同 artifact 在 DAG 中有不同角色，rules 应该匹配这种角色差异：

```yaml
rules:
  proposal:
    # proposal 是 scope 文档 → 约束 scope
    - Each proposal must identify affected existing capabilities
    - Breaking changes must be explicitly called out with **BREAKING**

  specs:
    # specs 是行为规约 → 约束行为完整性
    - Every requirement must have at least one unhappy-path scenario
    - Role-sensitive behavior must include explicit authorization scenarios

  design:
    # design 是技术方案 → 约束技术决策质量
    - Design decisions must include the alternative that was rejected and why
    - Migration risk must be explicitly assessed

  tasks:
    # tasks 是实施清单 → 约束可追踪性
    - Each task group must reference the spec requirement it implements
    - Tasks must be ordered by dependency
```

### 6.2 context 应包含"不变的背景"，不包含"这次要做什么"

- **放**：技术栈、领域术语、质量优先级、兼容性约束
- **不放**：这个 sprint 的目标、当前 change 的具体内容、临时的技术决策

因为 context 会被注入到**所有** artifact 的所有指令中，临时内容会反复干扰 agent。

### 6.3 新项目从 4 行 context + 1-2 条 rules 开始

```
context: 项目名、领域、技术栈、质量优先级
rules:
  proposal: 1-2 条最关键的 scope 约束
```

不要一开始写满。在用了几个 change 之后，看 agent 反复犯什么错误，再针对性地加 rules。

### 6.4 弱规则不如不写

```yaml
# 弱 —— 没有判断力，浪费 token
rules:
  proposal:
    - Write clean code
    - Follow best practices

# 强 —— 有对象、有约束、有判断方向
rules:
  proposal:
    - Changes affecting the authorization module must reference existing auth spec requirements
    - New public API endpoints must document their error response contract
```

---

## 7. 常见误用（从源码角度看为什么是误用）

### 误用 1：把 rules 当成 "所有 artifact 都用同一套规则"

`config.rules` 是按 artifact ID 分别注入的。如果你写：

```yaml
rules:
  all:
    - Write good code
```

`all` 不是合法的 artifact ID → 每次生成指令都会收到 warning → 这条规则**永远不会被注入**。

**正确做法**：明确写清楚每条规则属于哪个 artifact：

```yaml
rules:
  proposal:
    - ...
  specs:
    - ...
```

### 误用 2：在 context 里写 PRD

context 50KB 限制的存在是有原因的 —— 太长的 context 会挤占 agent 的注意力。如果把 PRD 的详细功能列表放进 context，agent 在面对每个 artifact 时都会被这些细节干扰。

**更合适的做法**：PRD 级别的详细需求应该放在 `openspec/specs/` 中作为主 spec，然后在 proposal 中引用。

### 误用 3：在 rules 里引用只有当前 change 才相关的信息

```yaml
rules:
  tasks:
    - The CSV export must use RFC 4180 format
```

这条规则只对 "add-csv-export" 这个 change 有意义。它应该写在那个 change 的 spec 中，而不是全局 config。

### 误用 4：context 超过 50KB

超过后**静默忽略**（全有或全无）。如果你发现 agent 好像看不到你的 context，检查文件大小。

---

## 8. config.yaml 的解析容错策略

`readProjectConfig()` (`project-config.ts`) 的设计是 **fail-open**：

1. 文件不存在 → 返回空 `{}`
2. YAML 解析失败 → 报错但不阻断（调用方 catch）
3. `schema` 字段缺失 → 使用默认值 `'spec-driven'`
4. `context` 超过 50KB → 忽略并 warning
5. `context` 不是 string → 忽略
6. `rules` 不是合法 record → 忽略
7. `rules` 中有未知 artifact ID → warning，不阻断

这种设计的意图是：**config 不应该成为工作流的中断点**。即使 config 写得不好，agent 仍然可以工作 —— 只是质量可能下降。
