# 自定义 Schema

想要一套**完全不一样的工作流**（比如先 research 再 propose、加一个 review artifact、删掉 design），就得自己写 schema。

## 两种创建方式

### 1. Fork 现有的（推荐新手）

```bash
openspec schema fork spec-driven my-workflow
```

产物：

```
openspec/schemas/my-workflow/
├── schema.yaml               # 复制自 spec-driven
└── templates/
    ├── proposal.md
    ├── spec.md
    ├── design.md
    └── tasks.md
```

直接改 YAML 和模板就行。

### 2. 从零建

```bash
# 交互式
openspec schema init research-first

# 非交互
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

## `schema.yaml` 字段

```yaml
name: my-workflow
version: 1
description: My team's custom workflow

artifacts:
  - id: proposal
    generates: proposal.md
    description: Initial proposal document
    template: proposal.md
    instruction: |
      Create a proposal that explains WHY this change is needed.
      Focus on the problem, not the solution.
    requires: []

  - id: design
    generates: design.md
    description: Technical design
    template: design.md
    instruction: |
      Create a design document explaining HOW to implement.
    requires:
      - proposal

  - id: tasks
    generates: tasks.md
    description: Implementation checklist
    template: tasks.md
    requires:
      - design

apply:
  requires: [tasks]
  tracks: tasks.md
```

### 字段说明

| 字段 | 作用 |
|------|------|
| `id` | 唯一标识，用于命令和 rules |
| `generates` | 产物文件名，支持 glob（`specs/**/*.md`） |
| `template` | `templates/` 下的文件名 |
| `instruction` | 注入到 agent 提示里的写作指令 |
| `requires` | 依赖列表（必须都 done 才能进入 ready） |

## 模板文件

`templates/<name>.md`，可以包含：

- 节标题（AI 来填内容）
- HTML 注释作为给 AI 的提示
- 示例格式

例：

```markdown
<!-- templates/proposal.md -->
## Why

<!-- Explain the motivation for this change. What problem does this solve? -->

## What Changes

<!-- Describe what will change. Be specific about new capabilities or modifications. -->

## Impact

<!-- Affected code, APIs, dependencies, systems -->
```

## 校验

写完了就跑一下：

```bash
openspec schema validate my-workflow
```

会检查：
- `schema.yaml` 语法
- 所有 `template:` 引用的文件都存在
- 没有循环依赖
- artifact id 合法

## 使用

```bash
# 方法 1：CLI flag（优先级最高）
openspec new change feature --schema my-workflow

# 方法 2：在 openspec/config.yaml 设为默认
# schema: my-workflow
```

新建 change 后，子目录里会自动写 `.openspec.yaml` 绑定这个 schema：

```yaml
schema: my-workflow
created: 2025-04-20
```

## 两个典型例子

### 例 1：Rapid（最小工作流）

适合快速迭代，跳过 specs 和 design：

```yaml
name: rapid
artifacts:
  - id: proposal
    generates: proposal.md
    requires: []
  - id: tasks
    generates: tasks.md
    requires: [proposal]

apply:
  requires: [tasks]
  tracks: tasks.md
```

依赖图：`proposal → tasks`

### 例 2：Research-first（先调研再提案）

```yaml
name: research-first
artifacts:
  - id: research
    generates: research.md
    requires: []

  - id: proposal
    generates: proposal.md
    requires: [research]

  - id: tasks
    generates: tasks.md
    requires: [proposal]
```

依赖图：`research → proposal → tasks`

### 例 3：With-review（加审核步骤）

基于 `spec-driven` fork，加一个 review artifact：

```yaml
artifacts:
  # ... spec-driven 原有的 proposal / specs / design ...

  - id: review
    generates: review.md
    description: Pre-implementation review checklist
    template: review.md
    instruction: |
      Create a review checklist based on the design.
      Include security, performance, and testing considerations.
    requires:
      - design

  - id: tasks
    generates: tasks.md
    template: tasks.md
    requires:
      - specs
      - design
      - review    # 多了一个依赖
```

## 两种存放位置

- **项目级**：`openspec/schemas/<name>/`（推荐，随代码版本化）
- **用户级**：`~/.local/share/openspec/schemas/<name>/`（跨项目复用）

项目级优先级更高（见 [schema-resolution-order.md](schema-resolution-order.md)）。
