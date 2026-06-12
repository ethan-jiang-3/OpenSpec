# 02 · 内置 spec-driven 详解

> 回 [导读](00-map.md)

`spec-driven` 是 OpenSpec 的默认内置 schema，也是所有自定义 schema 的参考原型。这一篇逐字段拆解它的结构。

---

## 完整 schema.yaml

```yaml
name: spec-driven
version: 1
description: Default OpenSpec workflow - proposal → specs → design → tasks

artifacts:
  - id: proposal
    generates: proposal.md
    description: Initial proposal document outlining the change
    template: proposal.md
    instruction: |
      Create the proposal document that establishes WHY this change is needed.
      ...
    requires: []

  - id: specs
    generates: "specs/**/*.md"
    description: Detailed specifications for the change
    template: spec.md
    instruction: |
      Create specification files that define WHAT the system should do.
      ...
    requires: [proposal]

  - id: design
    generates: design.md
    description: Technical design document with implementation details
    template: design.md
    instruction: |
      Create the design document that explains HOW to implement the change.
      ...
    requires: [proposal]

  - id: tasks
    generates: tasks.md
    description: Implementation checklist with trackable tasks
    template: tasks.md
    instruction: |
      Create the task list that breaks down the implementation work.
      ...
    requires:
      - specs
      - design

apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
```

---

## 四个 artifact 逐字段解析

### proposal（提案）

| 字段 | 值 | 含义 |
|------|---|------|
| `id` | `proposal` | 唯一标识，用于 CLI、rules 匹配、依赖引用 |
| `generates` | `proposal.md` | 输出到 change 目录根下的单个文件 |
| `template` | `proposal.md` | 使用 `templates/proposal.md` 作为生成骨架 |
| `requires` | `[]` | 无依赖，是整条链的起点（root artifact） |

**instruction 核心内容**：
- Why（问题/机会）
- What Changes（具体变更列表）
- Capabilities（新增/修改的 capability，每个对应一个 spec 文件）
- Impact（影响范围）

**关键设计**：Capabilities 部分是 proposal 和 specs 之间的"合同"——proposal 里列出的每个 capability，specs 阶段都要生成对应的 `specs/<name>/spec.md`。

### specs（规格说明）

| 字段 | 值 | 含义 |
|------|---|------|
| `id` | `specs` | 标识 |
| `generates` | `specs/**/*.md` | 支持 glob，可生成多个 spec 文件 |
| `requires` | `[proposal]` | 依赖 proposal 先完成 |

**instruction 核心内容**：
- Delta 操作：ADDED / MODIFIED / REMOVED / RENAMED Requirements
- 格式强制：`### Requirement:` + `#### Scenario:` (必须是 4 个 #)
- GIVEN / WHEN / THEN 场景格式
- MODIFIED 要求复制完整 requirement（防止 archive 时信息丢失）

### design（技术设计）

| 字段 | 值 | 含义 |
|------|---|------|
| `id` | `design` | 标识 |
| `generates` | `design.md` | 单个文件 |
| `requires` | `[proposal]` | 依赖 proposal |

**instruction 核心内容**：
- 仅在跨模块、新依赖、安全/性能/迁移复杂等场景才需要写
- 包含 Context、Goals/Non-Goals、Decisions、Risks/Trade-offs、Migration Plan、Open Questions

### tasks（任务清单）

| 字段 | 值 | 含义 |
|------|---|------|
| `id` | `tasks` | 标识 |
| `generates` | `tasks.md` | 单个文件 |
| `requires` | `[specs, design]` | 依赖 specs 和 design 都完成 |

**instruction 核心内容**：
- 强制 checkbox 格式：`- [ ] X.Y Task description`
- 要求按依赖排序
- 每个任务要小到可在一个 session 完成

---

## apply 阶段

```yaml
apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
```

| 字段 | 含义 |
|------|------|
| `requires` | 实现阶段的前置条件（这里：tasks 完成后才能开始实现） |
| `tracks` | 实现阶段追踪哪个文件来判定进度 |
| `instruction` | 给实现阶段的专属指令 |

---

## 依赖图

```text
proposal (root)
   ├──→ specs
   │      │
   └──→ design
          │
          └──→ tasks ──→ apply
```

注意：specs 和 design 是**并行**的（都只依赖 proposal），但 tasks 必须等它们**都完成**。

---

## 模板文件

每个 artifact 的模板在 `schemas/spec-driven/templates/` 下：

| 模板文件 | 核心结构 |
|---------|---------|
| `proposal.md` | `## Why` / `## What Changes` / `## Capabilities` / `## Impact` |
| `spec.md` | `## ADDED Requirements` / `### Requirement:` / `#### Scenario:` |
| `design.md` | `## Context` / `## Goals / Non-Goals` / `## Decisions` / `## Risks` |
| `tasks.md` | `## 1. <Group>` / `- [ ] 1.1 <Task>` |

模板里的 HTML 注释（`<!-- ... -->`）作为给 AI 的内联提示。

---

## 这套 schema 适合什么场景

- 软件工程项目，需要明确的行为规格
- 团队协作，需要 review 和归档
- 变更影响面大，需要 design 文档
- 需要可追溯的 requirement → implementation 链路

不适合：
- 快速原型（太重）
- 纯内容创作（artifact 结构偏向代码工程）
- 单人探索性项目（design 阶段可能多余）
