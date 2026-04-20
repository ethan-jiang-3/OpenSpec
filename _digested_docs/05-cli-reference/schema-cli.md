# CLI · Schema 管理

管理**自定义 workflow schema** 的四个子命令。源码在 [src/commands/schema.ts](../../src/commands/schema.ts)。

关于 schema 怎么手写，见 [07-customization/custom-schemas.md](../07-customization/custom-schemas.md)。

---

## §0 OpenSpec 里的 "schema" 到底是什么

> **一句话**：schema = **一种"开发工作流的可执行定义文件"**，用 YAML 写成，描述一次变更要产出哪几种 artifact、它们之间的依赖关系、每种 artifact 用什么模板和什么 AI 指令来生成。

### 字面定义（来自 [`src/core/artifact-graph/types.ts:24-31`](../../src/core/artifact-graph/types.ts)）

```typescript
export const SchemaYamlSchema = z.object({
  name: z.string(),                               // schema 名字
  version: z.number().int().positive(),
  description: z.string().optional(),
  artifacts: z.array(ArtifactSchema).min(1),     // ← 关键：要产出哪些 artifact
  apply: ApplyPhaseSchema.optional(),            // ← 写代码阶段的契约
});

export const ArtifactSchema = z.object({
  id: z.string(),                                // artifact 的逻辑名（proposal、specs...）
  generates: z.string(),                         // 输出文件名/glob（proposal.md、specs/**/*.md）
  description: z.string(),
  template: z.string(),                          // 用哪个模板（templates/proposal.md）
  instruction: z.string().optional(),            // 喂给 LLM 的指令
  requires: z.array(z.string()).default([]),     // 依赖哪些 artifact（DAG 边）
});
```

**它就是这么个 plain-old YAML 文件**。schema = 工作流的 schema，不是数据库表的 schema。

### 看个真东西：内置 `spec-driven` schema 的核心结构

完整文件：[`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml) 共 154 行，浓缩看：

```yaml
name: spec-driven
version: 1
description: Default OpenSpec workflow - proposal → specs → design → tasks
artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    instruction: |
      Create the proposal document that establishes WHY this change is needed.
      Sections: Why / What Changes / Capabilities / Impact ...
    requires: []                    ← 不依赖任何东西，最先做

  - id: specs
    generates: "specs/**/*.md"
    template: spec.md
    instruction: |
      Create specification files that define WHAT the system should do.
      Delta operations: ADDED / MODIFIED / REMOVED / RENAMED Requirements ...
    requires: [proposal]            ← 依赖 proposal

  - id: design
    generates: design.md
    template: design.md
    instruction: |
      Create the design document that explains HOW to implement ...
    requires: [proposal]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    instruction: |
      Create the task list that breaks down the implementation work ...
    requires: [specs, design]       ← 依赖前两个

apply:
  requires: [tasks]                 ← 写代码前必须先有 tasks.md
  tracks: tasks.md                  ← 进度通过这个文件的 checkbox 跟踪
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
```

读完这个例子，你就掌握了 schema 的全部精髓：**它是一份 DAG + 每个节点的提示材料**。

### 为什么用 "schema" 这个词（命名考据）

OpenSpec 借用了 **JSON Schema / 数据库 schema** 的语义——它定义的是 **"什么算合法的 artifact 集合"**：

| 传统语义里的 schema | OpenSpec 里的 schema |
|---------------------|---------------------|
| 定义"什么样的 JSON 对象算合法" | 定义"什么样的 change 文件夹算合法" |
| 字段定义 + 字段类型 + 必填关系 | artifact 定义 + 模板路径 + 依赖关系 |
| 数据库表里行的"形状契约" | change 文件夹里 artifact 的"形状契约" |
| 是数据，不是代码 | 是 YAML，不是代码 |
| 可以由用户自定义 | 可以由用户自定义 |

**所以 schema 不是 prompt、不是模板、不是配置，而是"一次变更应该长什么样"的契约**。

### Schema vs 其它术语 —— 别搞混

| 术语 | 是什么 | 在哪 | 谁用 |
|------|--------|------|------|
| **schema** | 工作流定义（YAML）| `openspec/schemas/<name>/schema.yaml` 或 npm 包内置 | 决定整个 change 的骨架 |
| **artifact** | schema 里定义的产物类型 | schema 的 `artifacts:` 数组 | proposal / specs / design / tasks 等 |
| **template** | artifact 实例的初始填充文 | `templates/<id>.md` | 给 LLM 当填空模板 |
| **instruction** | 给 LLM 的人话指令 | schema 里 artifact 节点的 `instruction:` 字段 | 告诉 LLM 这个 artifact 怎么写 |
| **change** | schema 的一次具体实例 | `openspec/changes/<change-name>/` | 实际产出的文件夹 |
| **profile** | 给 OpenSpec **CLI 命令**分组（core/custom）| 全局配置 | 决定装多少个斜杠命令，**跟 schema 无关** |
| **config.yaml** | 项目级配置 | `openspec/config.yaml` | 决定本项目用哪个 schema、注入什么 context/rules |
| **workflow** | 一个 OPSX 命令（propose/apply/...）| 模板代码里 | OPSX 用语，跟 schema 是**正交概念** |

⚠️ 容易混的两个对：
- **schema ≠ workflow**：schema 是"产物形状"，workflow 是"OPSX 命令名"。`/opsx:propose` 这个 workflow **不管你用哪个 schema 都能跑**——它通过 `openspec status --json` 实时去查"当前 change 用的 schema 长啥样"。
- **schema ≠ template**：schema 是 YAML（描述结构），template 是 Markdown（具体内容填空格）。schema 只**引用**template 的路径。

### 为什么要把它做成"可定义的 schema"而不是写死在源码里

这是 OPSX 相比 legacy 最关键的进化点。Legacy 时代："所有 change 都必须是 proposal → specs → design → tasks 这四样"是**硬编码在 source 里的**。OPSX 把它抽成 YAML，于是：

1. **支持多种工作流** —— 你可以写 `rapid.yaml`（只有 proposal+tasks）、`research-first.yaml`（先 research 再 proposal）、`with-review.yaml`（加一个 review artifact）等
2. **同项目可共存多 schema** —— 不同 change 用不同 schema：探索性 PR 用 rapid，架构变更用 with-design-review
3. **Schema 可继承** —— `openspec schema fork spec-driven my-team` 复制一份再改
4. **Agent 不用升级** —— 因为 agent 只调 `openspec instructions <id> --json` 实时查询，schema 一改，agent 立刻按新结构干活
5. **三层覆盖**（项目 > 用户 > 包内置）—— 同一个 schema 名字可以在项目级被覆盖，方便统一团队规范

### Schema 在整个数据流里的位置

```text
[用户跑 /opsx:propose]
        ↓
[Agent 读 .commands/opsx-propose.md，里面写着"调 openspec status --json"]
        ↓
[OpenSpec CLI 收到请求]
        ↓
[CLI 查 openspec/changes/<name>/.openspec.yaml 拿到 schema 名]
        ↓
[CLI 按解析顺序加载 schema.yaml （project > user > package）]   ← schema 在这里被用上
        ↓
[CLI 用 schema 的 artifacts 数组算 DAG，得出 ready/blocked/done 状态]
        ↓
[Agent 再调 openspec instructions <next-artifact> --json]
        ↓
[CLI 找到 schema 里那个 artifact 节点，把它的 template+instruction
 加上项目 context+rules+依赖 artifact 内容，打包成 JSON 返回]
        ↓
[Agent 把这个 JSON 拼成 prompt 喂自己的 LLM 生成 artifact]
        ↓
[Agent 写到 schema 定义的 generates 路径]
```

**Schema 是这条数据流的"中央词典"** —— 没有它，CLI 不知道下一个 artifact 是什么、模板在哪、要等哪些前置依赖。

### 一张图记住

```text
┌─────────── schema (YAML) ───────────┐
│                                      │
│  name + version + description        │
│                                      │
│  artifacts:                          │
│    ┌──────┐  ┌──────┐  ┌──────┐    │
│    │  A   │→ │  B   │→ │  D   │    │
│    └──────┘  └──────┘↗ └──────┘    │
│              ┌──────┐ /              │
│              │  C   │/               │
│              └──────┘                │
│   每个节点 = { id, generates,        │
│              template,               │
│              instruction,            │
│              requires: [...] }       │
│                                      │
│  apply: { requires, tracks,          │
│           instruction }              │
└──────────────────────────────────────┘
        ↓               ↓
   决定 DAG       决定 LLM prompt
   决定文件路径   决定写代码前置条件
```

### 你现在该明白：

- 为什么会有 `openspec schema init / fork / validate / which` —— 因为 schema 是数据文件，需要 CRUD 工具
- 为什么 `openspec/config.yaml` 里有个 `schema:` 字段 —— 是用来**指定本项目默认用哪个 schema**
- 为什么 `openspec instructions` 命令的输出包含 `template/instruction/dependencies` —— 这些都是从 schema 里提取的
- 为什么 [06-schemas-and-artifacts/](../06-schemas-and-artifacts/) 单独成章 —— schema 不是辅助概念，是 OPSX 的核心数据模型

**结论一句话**：schema 是 OpenSpec 把"软件开发工作流"做成**数据**而不是**代码**的关键抽象，所有 OPSX 命令都是围绕"读 schema、按 schema 编排 LLM、按 schema 写文件"展开的。

---

## `openspec schema init`

从零创建一个项目 schema。

```
openspec schema init <name> [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--description <text>` | schema 描述 |
| `--artifacts <list>` | 逗号分隔的 artifact ID（默认 `proposal,specs,design,tasks`）|
| `--default` | 设为项目默认 schema |
| `--no-default` | 不问设为默认 |
| `--force` | 覆盖已存在的 schema |
| `--json` | JSON 输出 |

### 示例

```bash
# 交互式
openspec schema init research-first

# 非交互 + 指定 artifact + 设为默认
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

### 产物

```
openspec/schemas/<name>/
├── schema.yaml
└── templates/
    ├── proposal.md
    ├── specs.md
    ├── design.md
    └── tasks.md
```

---

## `openspec schema fork`

复制一份已有 schema 做定制。

```
openspec schema fork <source> [name] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--force` | 覆盖目标 |
| `--json` | JSON 输出 |

### 示例

```bash
# fork 内置 spec-driven 到项目里
openspec schema fork spec-driven my-workflow

# 不指定新名字时默认 <source>-custom
openspec schema fork spec-driven
# → 产出 spec-driven-custom
```

---

## `openspec schema validate`

校验 schema 的 YAML 结构 + 模板引用是否齐全。

```
openspec schema validate [name] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--verbose` | 打印详细校验步骤 |
| `--json` | JSON 输出 |

### 示例

```bash
# 校验指定 schema
openspec schema validate my-workflow

# 不带名字 = 校验所有 schema
openspec schema validate
```

校验内容：
- `schema.yaml` 语法对不对
- 每个 `template` 字段指向的文件是否存在
- 有没有循环依赖
- artifact ID 合法

---

## `openspec schema which`

看某个 schema 从哪个来源解析出来的，用来调试优先级问题。

```
openspec schema which [name] [--all] [--json]
```

### 示例

```bash
# 看单个
openspec schema which spec-driven

# 列出全部 schema 和它们的来源
openspec schema which --all
```

### 输出

```
spec-driven resolves from: package
  Source: /usr/local/lib/node_modules/@fission-ai/openspec/schemas/spec-driven
```

来源三种：
1. **project** — `openspec/schemas/<name>/`（最高优先级）
2. **user** — `~/.local/share/openspec/schemas/<name>/`
3. **package** — npm 包内置

详见 [07-customization/schema-resolution-order.md](../07-customization/schema-resolution-order.md)。
