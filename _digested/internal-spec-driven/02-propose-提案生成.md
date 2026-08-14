# 02 — propose：Proposal 生成

propose 是四条命令中最核心的一条。它执行完整的“从零到可实施”流程：创建 change、按 DAG 的可用性推进 artifact，直到满足 apply 条件。调用名由宿主决定：Claude 可显示 `/opsx:propose`，Codex v1.8.0 使用 `$openspec-propose-change`。

---

## 1. 完整流程（5 步）

![propose 三方架构实例化](figures/02-propose-flow.svg)

来自 `src/core/templates/workflows/propose.ts`。

### Step 1：理解用户意图，导出 change name

agent 从用户输入中导出 kebab-case name。如果用户只描述了想做什么而没有给名字，agent 必须用 AskUserQuestion 追问。

```
User: "add user authentication"  →  change name: "add-user-auth"
```

**name 验证规则**（`validateChangeName()` in `src/utils/change-utils.ts`）：
- 正则：`/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/`
- 拒绝：大写字母、空格、下划线、首尾连字符、连续连字符、数字开头

### Step 2：创建 change 目录

```bash
openspec new change "<name>"
```

**实际行为**（`createChange()` in `src/utils/change-utils.ts`）：

1. 创建目录：`openspec/changes/<name>/`
2. 创建 `.openspec.yaml` 元数据文件：
   ```yaml
   schema: spec-driven        # 解析后的 schema 名
   created: "2026-06-14"      # 创建日期
   ```
3. **仅当 `--description` 提供时**才创建 `README.md`（内容为 `# <name>\n\n<description>`）

**重要**：此时不创建任何 artifact 文件（proposal.md、design.md 等）。这些由 agent 在后续步骤中逐个创建。

### Step 2.5（隐含）：schema 解析

`new change` 内部解析 schema 的优先级 (`change-utils.ts:132-147`)：

1. 显式 `--schema` flag
2. `openspec/config.yaml` 中的 `schema` 字段
3. `options.defaultSchema`，回退到硬编码 `DEFAULT_SCHEMA = 'spec-driven'`

> **注意**：代码中第 3 级是 `const defaultSchema = options.defaultSchema ?? DEFAULT_SCHEMA;`，即 `options.defaultSchema` 和硬编码 `'spec-driven'` 合并为一级。上面拆成两级是为了可读性——实际代码是 3 级而非 4 级。

解析结果写入 `.openspec.yaml` 的 `schema` 字段。

### Step 3：获取 artifact DAG 状态

```bash
openspec status --change "<name>" --json
```

此时所有 artifact 的状态都是 `blocked`（除了 proposal 是 `ready`），因为目录是空的。

返回的关键字段：
```json
{
  "artifacts": [
    { "id": "proposal", "status": "ready" },
    { "id": "specs",    "status": "blocked", "missingDeps": ["proposal"] },
    { "id": "design",   "status": "blocked", "missingDeps": ["proposal"] },
    { "id": "tasks",    "status": "blocked", "missingDeps": ["specs", "design"] }
  ],
  "applyRequires": ["tasks"]
}
```

agent 从 `applyRequires` 知道：需要 tasks 完成才能实施。

### Step 4：核心循环 —— 按 DAG 顺序逐一创建 artifact

这是 propose 最关键的部分。agent 循环执行：

```
while (不是所有 applyRequires 中的 artifact 都 done):
    取一个状态为 ready 的 artifact
    调用: openspec instructions <artifact-id> --change "<name>" --json
    解析返回的 JSON
    读已完成的依赖文件（dependencies 字段告诉 agent 读什么）
    在 resolvedOutputPath 创建 artifact 文件
    重新调用: openspec status --change "<name>" --json
    检查 applyRequires 是否全部 done
```

**循环终止条件**：`applyRequires` 数组中的每个 artifact ID 在最新 status 中都有 `status: "done"`。

对于 spec-driven schema，`applyRequires: ["tasks"]`。正常路径是 proposal 后 specs 与 design 都 ready、二者完成后 tasks ready；v1.7.0 的同级推荐顺序按 schema 声明（specs 在 design 前），但这不是新增 DAG 依赖。

### Step 5：最终状态展示

```bash
openspec status --change "<name>"     # 纯文本模式，给人看
```

---

## 2. 每个 artifact 的创建细节

### 2.1 proposal（立即可做，`requires: []`）

**模板** (`schemas/spec-driven/templates/proposal.md`)：
```markdown
## Why
<!-- Explain the motivation for this change. What problem does this solve? Why now? -->

## What Changes
<!-- Describe what will change. Be specific about new capabilities, modifications, or removals. -->

## Capabilities
### New Capabilities
<!-- Capabilities being introduced. Replace <name> with kebab-case identifier... -->
- `<name>`: <brief description>

### Modified Capabilities
<!-- Existing capabilities whose REQUIREMENTS are changing... -->
- `<existing-name>`: <what requirement is changing>

## Impact
<!-- Affected code, APIs, dependencies, systems -->
```

**instruction** (`schema.yaml:10-26`) 强调的关键点：
- Capabilities 部分是**关键契约** —— 它建立了 proposal 和 specs 阶段之间的连接
- 每个列出的 capability 需要一个对应的 spec 文件（`specs/<capability-path>/spec.md`）；v1.7.0 可以用嵌套 path，如 `identity/session`。
- "Keep it concise (1-2 pages). Focus on the 'why' not the 'how' — implementation details belong in design.md."

**proposal 在 DAG 中的位置**：`requires: []`，是 DAG 的根节点，立即可做。完成后解锁 specs 和 design。

### 2.2 specs（依赖 proposal，`requires: [proposal]`）

**模板** (`schemas/spec-driven/templates/spec.md`)：
```markdown
## ADDED Requirements
### Requirement: <!-- requirement name -->
<!-- requirement text -->
#### Scenario: <!-- scenario name -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->
```

模板只给出了 ADDED 的例子，但 instruction (`schema.yaml:34-83`) 详细描述了全部四种 delta 操作：

```
## ADDED Requirements
### Requirement: <name>
<SHALL/MUST text>
#### Scenario: <name>
- **WHEN** <condition>
- **THEN** <expected outcome>

## MODIFIED Requirements
### Requirement: <name>
<full updated requirement text including all scenarios>

## REMOVED Requirements
### Requirement: <name>
**Reason**: <why>
**Migration**: <how to handle>

## RENAMED Requirements
FROM: ### Requirement: <old-name>
TO: ### Requirement: <new-name>
```

**instruction 中的关键约束**：

1. **Scenario 必须用 4 个 hashtag**（`#### `）。用 3 个或 bullet 会**静默失败** —— 解析器不识别。约定写法是 `#### Scenario:`；v1.9.0 起 validate/archive 的 scenario-loss 把 requirement 下任何非 fence 的 `#### ` 子标题都算作 scenario（`#### Edge case` 也会被计数，省略它会在 authoring 阶段失败）。
2. **每个 requirement 至少要有一个 scenario**。
3. **MODIFIED 必须复制完整的 requirement block**（包括所有 scenario）—— "Common pitfall: Using MODIFIED with partial content loses detail at archive time."
4. **用 SHALL/MUST** 写规范性需求，避免 should/may。v1.8.0 起 normal 模式下这条只是 guidance（缺失给 WARNING，非英语 spec 也能过），只有 `validate --strict` 才强制；写作建议不变。
5. MODIFIED 的 workflow：
   > 1. 在 `openspec/specs/<capability-path>/spec.md` 中找到已有 requirement
   > 2. 复制完整的 requirement block（从 `### Requirement:` 到所有 scenario）
   > 3. 粘贴到 `## MODIFIED Requirements` 下，编辑以反映新行为
   > 4. 确保 header 文本完全匹配（对空白不敏感）

**specs 在 DAG 中的位置**：`requires: [proposal]`。和 design 并行。完成后（与 design 一起）解锁 tasks。

**generates 的特殊性**：`specs/**/*.md` 是 glob 模式。`detectCompleted()` 用 `fast-glob` 检查 —— 只要 `specs/` 下存在至少一个 `.md` 文件就算完成。这意味着 specs 可以是一个文件（`specs/data-export/spec.md`）也可以是多个；每个 capability 的身份是 `specs/` 下的相对 path，而不是仅仅末级目录名。change delta 必须用同一相对 path，根级 `changes/<change>/specs/spec.md` 不构成 capability，会被 validate/archive 拒绝。

### 2.3 design（依赖 proposal，`requires: [proposal]`）

**模板** (`schemas/spec-driven/templates/design.md`)：
```markdown
## Context
<!-- Background and current state -->

## Goals / Non-Goals
**Goals:** <!-- What this design aims to achieve -->
**Non-Goals:** <!-- What is explicitly out of scope -->

## Decisions
<!-- Key design decisions and rationale -->

## Risks / Trade-offs
<!-- Known risks and trade-offs -->

## Migration Plan
<!-- Steps to deploy, rollback strategy (if applicable) -->

## Open Questions
<!-- Outstanding decisions or unknowns to resolve -->
```

**instruction** (`schema.yaml:89-112`) 的关键约束：
- **不是每次都要创建 design.md**。只有满足以下条件之一才需要：
  - 跨多个服务/模块的变更，或新的架构模式
  - 新的外部依赖，或重大数据模型变更
  - 涉及安全、性能或迁移复杂度
  - 在写代码前需要技术决策来消除歧义
- design 关注"为什么做这个技术决策"（而不是具体怎么逐行实现）
- 引用 proposal 了解动机，引用 specs 了解需求

**design 在 DAG 中的位置**：`requires: [proposal]`，和 specs 是并行的。可以同时创建（agent 可以先创建 proposal 后同时创建 specs 和 design）。

### 2.4 tasks（依赖 specs 和 design，`requires: [specs, design]`）

**模板** (`schemas/spec-driven/templates/tasks.md`)：
```markdown
## 1. <!-- Task Group Name -->
- [ ] 1.1 <!-- Task description -->
- [ ] 1.2 <!-- Task description -->

## 2. <!-- Task Group Name -->
- [ ] 2.1 <!-- Task description -->
- [ ] 2.2 <!-- Task description -->
```

**instruction** (`schema.yaml:117-146`) 的约束：

1. **"Follow the template below exactly."**
   > "The apply phase parses checkbox format to track progress. Tasks not using `- [ ]` won't be tracked."

2. checkbox 解析（v1.8.0 起统一走共享 parser `parseTaskLines()` in `src/utils/task-progress.ts`）：
   ```typescript
   const TASK_LINE_PATTERN = /^\s*[-*]\s*\[([\sxX])\]\s*(.*)/;
   // done = checkboxMatch[1].toLowerCase() === 'x'
   ```
   - `- [ ]` → 未完成
   - `- [x]` 或 `- [X]` → 完成
   - 允许前导缩进——`  - [ ] 1.1.1` 子任务照常计数（v1.8.0；旧版只认列 0 的 checkbox）
   - 不需要 `X.Y` 编号格式（只是建议，解析器不强求）

3. 分组用 `## N. Group Name` 二级标题

4. 每个 task 应该小到可以在一次 session 中完成

5. 按依赖排序（先做什么后做什么）

**tasks 在 DAG 中的位置**：`requires: [specs, design]`。是 DAG 最后一个 artifact。完成后 + 所有 applyRequires 满足 → propose 阶段完成。

---

## 3. DAG 顺序保证

agent 不是随意创建 artifact 的。顺序由 `ArtifactGraph.getBuildOrder()` (`src/core/artifact-graph/graph.ts`) 保证 —— 用 **Kahn 算法**（拓扑排序）：

1. 计算每个节点的初始入度 = **`requires` 数组的完整长度**（不考虑完成状态；这是静态 DAG 的拓扑排序，与运行时哪些 artifact 已完成无关）
2. 入度为 0 的节点进入 ready 队列（排序以保证确定性输出）
3. 弹出 ready 队列中第一个节点，加入 `buildOrder`
4. 遍历所有"requires 中包含该节点"的后继，后继入度减 1；若后继入度变为 0，加入 ready 队列
5. 重复直到 ready 队列为空

> **注意区分两个概念**：
> - `getBuildOrder()`（这里描述的 Kahn 算法）计算的是**静态拓扑序**，入度 = `requires.length`，与任何 `completed` 集合无关。它用于决定"理想创建顺序"。
> - 运行时判断"现在哪些 artifact 可以创建"的是 `getNextArtifacts(completed)`（`src/core/artifact-graph/graph.ts`），它检查的是 `requires` 中**未完成**的依赖是否为空。`getBlocked()` 返回每个 blocked artifact 的未满足依赖列表，用的才是 `requires.filter(req => !completed.has(req))`。不要把这三者混淆。

对于 spec-driven：
```
初始：proposal 入度 0，specs/design 入度 1，tasks 入度 2
proposal done → specs 入度 0，design 入度 0
specs done + design done → tasks 入度 0
```

循环检测在 schema 解析时做（`src/core/artifact-graph/schema.ts`，DFS），有环直接报错拒绝加载。

---

## 4. agent 如何使用 instructions 的返回

当 agent 调用 `openspec instructions <artifact> --change X --json`，它得到 `ArtifactInstructions` 对象。agent 的使用方式（来自 `propose.ts` 模板）：

1. **读 `dependencies`**：把已完成依赖文件读了作为上下文
2. **用 `template` 作为结构**：填充模板的各个 section
3. **应用 `context` 和 `rules` 作为约束**：它们影响 agent 写什么，但**不写进文件里**
4. **遵循 `instruction`**：来自 schema 的指导，比如"specs 的 scenario 必须用 4 个 hashtag"
5. **写到 `resolvedOutputPath`**：绝对路径，agent 直接写

新 capability 的 delta 可以在 requirements 前写 `## Purpose`；v1.7.0 archive 会把可读 Purpose 带入新 main spec。既有 main spec 的 Purpose 不会被 delta 覆盖；没有可读 Purpose 时才回退占位文字。

**agent 绝对不应该做的事**：
- 把 `context`、`rules`、`<project_context>` 标签复制到 artifact 文件中
- 跳过依赖文件不读就创建 artifact
- 不按模板结构自由发挥

---

## 5. propose 完成后的状态

当循环结束，文件系统状态：

```
openspec/changes/<name>/
  .openspec.yaml          ← schema + 创建日期
  proposal.md             ← 为什么做、做什么
  specs/
    <capability-path>/spec.md  ← delta spec（ADDED/MODIFIED/REMOVED/RENAMED，可嵌套）
  design.md               ← 技术方案（如果需要的话）
  tasks.md                ← 实施清单（checkbox 格式）
```

`openspec status --change "<name>" --json` 返回：
```json
{
  "isComplete": true,
  "applyRequires": ["tasks"],
  "artifacts": [
    { "id": "proposal", "status": "done" },
    { "id": "specs",    "status": "done" },
    { "id": "design",   "status": "done" },
    { "id": "tasks",    "status": "done" }
  ]
}
```

若这次变更确实没有 spec-level 行为变化，可在 change metadata 中显式写 `skip_specs: true`：specs artifact 会是 `skipped`，tasks/apply 可继续；它不能与任何非隐藏 delta spec 文件共存。否则此时 agent 提示用户开始 apply（Claude 例子为 `/opsx:apply`，Codex 为 `$openspec-apply-change`）。
