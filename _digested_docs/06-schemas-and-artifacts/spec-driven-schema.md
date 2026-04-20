# 内置 Schema：`spec-driven`

这是 OpenSpec 目前唯一的**内置** schema，对应大部分 feature 开发场景。所有自定义 schema 都推荐从它 `schema fork` 起步。

完整定义在 [schemas/spec-driven/schema.yaml](../../schemas/spec-driven/schema.yaml)。

## 核心结构

```yaml
name: spec-driven
version: 1
description: Default OpenSpec workflow - proposal → specs → design → tasks

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    requires: []

  - id: specs
    generates: "specs/**/*.md"
    template: spec.md
    requires: [proposal]

  - id: design
    generates: design.md
    template: design.md
    requires: [proposal]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    requires: [specs, design]

apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks,
    mark complete as you go. Pause if you hit blockers
    or need clarification.
```

## 四份模板文件

位置：[schemas/spec-driven/templates/](../../schemas/spec-driven/templates/)

| 模板 | 被哪个 artifact 用 | 关键段落 |
|------|---------------------|----------|
| `proposal.md` | proposal | Why / What Changes / Capabilities / Impact |
| `spec.md` | specs | ADDED / MODIFIED / REMOVED / RENAMED Requirements |
| `design.md` | design | Context / Goals-Non-Goals / Decisions / Risks / Migration / Open Questions |
| `tasks.md` | tasks | `## N.` 分组 + `- [ ] N.X` 打钩任务 |

## Instruction 字段（教 AI 怎么写）

每个 artifact 在 `schema.yaml` 里都有一个 `instruction:` 字段，注入到 `openspec instructions` 返回给 agent 的提示里。几个要点（从源文件摘）：

### proposal
> 简洁（1–2 页），**Capabilities 段是关键**，它创建了 proposal 和 specs 阶段之间的「契约」——每个列出来的 capability 都要对应一个 spec 文件。

- 新 capability → `specs/<kebab-case-name>/spec.md`
- 修改已有 capability → 必须用已有的 folder 名

### specs
> 每个 capability 一个文件。重点格式：
> - `### Requirement:` + 4 个 `#` 的 scenario
> - SHALL / MUST
> - **MODIFIED 必须复制整块原内容再改**

### design
> 只在**必要时**才建，判据：
> - 跨模块 / 跨服务
> - 新外部依赖 / 数据模型变化
> - 安全 / 性能 / 迁移复杂
> - 有歧义需要先做技术决策

### tasks
> **严格按模板**（checkbox 格式被 apply 阶段 parse）：
> ```
> ## 1. Setup
> - [ ] 1.1 Create new module structure
> - [ ] 1.2 Add dependencies to package.json
> ```

## 什么时候该 fork 这个 schema

- 要加一个 `review` artifact（让 AI 在 apply 前生成 review checklist）
- 要去掉 design（超简单流程）
- 要加 `research` artifact（先调研再提案）
- 想自己定义 Scenario 格式（比如必须 Given/When/Then 三件套）

fork 方法见 [07-customization/custom-schemas.md](../07-customization/custom-schemas.md)。
