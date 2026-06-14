# System 地图

## 一句话定位

OpenSpec 当前不是单一的“spec 文件夹工具”，而是一套本地协作系统：

- 用 repo-local `openspec/` 管项目当前规格和一次次增量 change。
- 用 schema 把一次 change 的 artifact 结构显式化。
- 用 CLI workflow 命令给 agent 提供结构化 runtime API。
- 用 init/update 把这些 workflow 投递给不同 coding agent。
- 用 workspace/context-store/initiative 扩展到多仓库、多目录的本地协调视图。

这个专题只讲这些层之间怎么拼起来。具体命令 IO、schema 字段、默认四类 artifact 的细节，分别去 `spec_cli/`、`schema/`、`internal-spec-driven/`。

如果你已经熟悉 SDD、AI Coding、agent workflow，但还没建立 OpenSpec 的概念体系，建议先读 `07-OpenSpec-工程思想.md` 和 `08-对照常见-SDD-与-AI-Coding.md`。这两篇不是新机制，而是把下面五层模型翻译成更容易迁移的工程直觉。

## 五层系统模型

```text
OpenSpec 当前系统

1. Repo-local planning
   repo-root/openspec/specs/
   repo-root/openspec/changes/
   repo-root/openspec/config.yaml
   repo-root/openspec/schemas/

2. Schema runtime
   schemas/<name>/schema.yaml
   schemas/<name>/templates/*.md
   artifact graph / status / instructions

3. Agent runtime API
   openspec status --json
   openspec instructions ... --json
   openspec new change
   openspec schemas/templates

4. Tool delivery
   global config profile + delivery
   skills / commands
   per-tool command adapters

5. Workspace coordination
   managed workspace local view
   context store registry
   initiative collection
   linked repos/folders
```

这五层不是替代关系，而是叠加关系。repo-local 仍然是单仓库工作的默认形态；workspace 不是把所有 linked repo 合并成一个大 repo，而是在本机创建一个协调视图。

## 每层回答的问题

| 层 | 它回答的问题 | 主要状态 |
|----|--------------|----------|
| Repo-local planning | 这个 repo 当前承认什么规格？这次 change 准备怎么改？ | `openspec/specs/`、`openspec/changes/` |
| Schema runtime | 一次 change 应该有哪些 artifact，依赖关系是什么？ | `schema.yaml`、templates |
| Agent runtime API | agent 此刻应该写什么、能写什么、缺什么？ | `status` / `instructions` JSON |
| Tool delivery | 哪些 workflow 以什么形式交给哪个 coding agent？ | global config、skills、commands |
| Workspace coordination | 多个 repo/folder 如何作为本地协作上下文出现？ | `.openspec-workspace/view.yaml`、context stores、initiatives |

## 现有专题怎么分工

```text
system/
  先回答：OpenSpec 这套系统有哪些层，每层边界在哪。

spec_cli/
  再回答：CLI 每个入口怎么把状态编译成可消费的 IO。

schema/
  再回答：schema 怎样定义 artifact DAG、模板、注入和自定义。

internal-spec-driven/
  最后回答：默认 spec-driven 下 explore/propose/apply/archive 的源码机制。
```

推荐阅读顺序：

```text
00-map
  → 07-OpenSpec-工程思想
  → 08-对照常见-SDD-与-AI-Coding
  → 01-系统心智模型
  → 02-目录与状态边界
  → 按问题进入 spec_cli/schema/internal-spec-driven/mechanisms
```

## 当前版本里最重要的变化

和旧消化材料相比，当前源码里多了一个必须进入总体模型的轴：workspace / context-store / initiative。

这个轴带来的核心变化是：

- `PlanningHome` 会判断当前规划家在哪里：repo 还是 workspace。
- repo-local 默认 schema 是 `spec-driven`。
- workspace 默认 schema 是 `workspace-planning`。
- workspace 是本机视图，不是远端协作服务，也不替 linked repo 做实现归属。
- context store 和 initiative 承担更持久的团队协调上下文。

所以新的总体专题不能只讲 `openspec/specs/` 和 `openspec/changes/`，还必须讲清楚 workspace 这层和 repo-local 之间的边界。

## 源码入口

| 主题 | 当前源码入口 |
|------|--------------|
| PlanningHome 判定 | `src/core/planning-home.ts` |
| workflow runtime API | `src/commands/workflow/` |
| artifact graph | `src/core/artifact-graph/` |
| project config | `src/core/project-config.ts` |
| global config/profile/delivery | `src/core/global-config.ts`、`src/core/profiles.ts` |
| init/update 投递 | `src/core/init.ts`、`src/core/update.ts` |
| tool command adapters | `src/core/command-generation/` |
| workspace 状态 | `src/core/workspace/` |
| context store | `src/core/context-store/` |
| initiative collection | `src/core/collections/initiatives/` |
