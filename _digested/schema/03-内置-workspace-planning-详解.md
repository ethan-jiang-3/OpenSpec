# 03 · 内置 workspace-planning 详解

> 回 [导读](00-map.md)

`workspace-planning` 是 OpenSpec v1.4.0 引入的第二套内置 schema，专门为**跨仓库/跨区域规划**场景设计。

---

## 和 spec-driven 的关键区别

| 维度 | spec-driven | workspace-planning |
|------|------------|-------------------|
| **适用场景** | 单仓库内的变更 | 跨多个 repo/folder 的协调规划 |
| **spec 基线** | `openspec/specs/`（有主基线） | 无主基线（spec 在各 linked repo 中） |
| **artifact 视角** | repo-local | workspace-scoped（跨受影响区域） |
| **proposal 内容** | Why / What / Capabilities / Impact | Why / What / **Affected Areas** / Capabilities / Impact |
| **specs 组织** | `specs/<capability>/spec.md` | `specs/<area-or-repo>/<capability>/spec.md` |
| **实现权限** | 当前 repo 可自由编辑 | 必须先确认 allowed edit root |

---

## 完整 schema.yaml

```yaml
name: workspace-planning
version: 1
description: Workspace planning workflow for cross-area changes

artifacts:
  - id: proposal
    generates: proposal.md
    description: Shared workspace proposal with the product goal, scope, affected areas, and impact
    template: proposal.md
    instruction: |
      Create the workspace-level proposal that captures the shared product goal once.
      ...
      - **Affected Areas**: Name known affected areas using registered workspace link names.
      ...
    requires: []

  - id: specs
    generates: "specs/**/*.md"
    description: Workspace-scoped specs organized by affected area and capability
    template: spec.md
    instruction: |
      Use `specs/<area-or-repo>/<capability>/spec.md` for area-specific requirements.
      ...
      These are planning artifacts under the workspace change root.
      Do not create repo-local spec files in linked repos during workspace planning.
    requires: [proposal]

  - id: design
    generates: design.md
    description: Cross-area technical design and coordination decisions
    template: design.md
    instruction: |
      Focus on decisions that affect multiple areas, handoffs between areas,
      shared constraints, sequencing risks.
      ...
      Avoid line-by-line implementation details.
    requires: [proposal]

  - id: tasks
    generates: tasks.md
    description: Coordination checklist for workspace planning
    template: tasks.md
    instruction: |
      Group tasks by phase or affected area.
      When implementation tasks are area-specific, name the affected area
      and keep the task at planning granularity.
      ...
    requires: [specs, design]

apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read the workspace planning context before applying.
    Select an affected area and confirm an allowed edit root before making implementation edits.
    Until an explicit implementation context is available, treat linked repos
    and folders as read-only exploration context.
```

---

## 关键设计理念

### Affected Areas（受影响区域）

workspace-planning 的 proposal 多了 `Affected Areas` 字段：

```markdown
## Affected Areas
- Known: frontend-repo, billing-service
- Unresolved: notification-system
```

这取代了 spec-driven 的 Capabilities 中"每个 capability 直接对应 spec 文件"的简单映射。workspace 场景下，capability 的归属是分区域的。

### 实现边界保护

workspace-planning 的 apply 指令明确要求：
- 必须先选择一个 affected area
- 必须先确认 allowed edit root
- linked repos 默认只读

这防止了 AI 在 workspace 规划阶段就越权修改 linked repo 的代码。

### 无主基线

workspace 没有 `openspec/specs/` 主基线——每个 linked repo 自己维护自己的 specs。workspace 的 planning artifacts 是跨区域协调的"胶水层"，不是新的单点权威。

---

## 什么时候用 workspace-planning

- 你的变更涉及 2+ 个 repo
- 需要在动手前先做跨区域影响分析
- 团队需要一个"协调中心"而不只是各 repo 各自改

## 什么时候不用

- 单 repo 变更 → 用 spec-driven
- 纯内容/文档项目 → 自定义 schema 更合适
