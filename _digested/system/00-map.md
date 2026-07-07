# System 地图

## 一句话定位

OpenSpec 当前不是单一的”spec 文件夹工具”，而是一套本地协作系统：

- 用 repo-local `openspec/` 管项目当前规格和一次次增量 change。
- 用 schema 把一次 change 的 artifact 结构显式化。
- 用 CLI workflow 命令给 agent 提供结构化 runtime API。
- 用 init/update 把这些 workflow 投递给不同 coding agent。
- 用 store/reference/workset 模型支持多仓库上下文引用。（v1.5.0：替代了旧 workspace/context-store/initiative 三件套）

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

5. Store coordination
   global store registry
   declared references
   working set assembly
   personal worksets
```

这五层不是替代关系，而是叠加关系。repo-local 仍然是单仓库工作的默认形态；store 不是把所有 linked repo 合并成一个大 repo，而是通过声明的 reference 关系让 agent 知道「还有哪些仓库的 specs 可以看」。

## 每层回答的问题

| 层 | 它回答的问题 | 主要状态 |
|----|--------------|----------|
| Repo-local planning | 这个 repo 当前承认什么规格？这次 change 准备怎么改？ | `openspec/specs/`、`openspec/changes/` |
| Schema runtime | 一次 change 应该有哪些 artifact，依赖关系是什么？ | `schema.yaml`、templates |
| Agent runtime API | agent 此刻应该写什么、能写什么、缺什么？ | `status` / `instructions` JSON |
| Tool delivery | 哪些 workflow 以什么形式交给哪个 coding agent？ | global config、skills、commands |
| Store coordination | 哪些其他仓库的 specs 与当前项目相关？agent 怎么引用它们？ | `~/.openspec/stores/registry.yaml`、`openspec/config.yaml` references、working set |

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

## 当前版本里最重要的变化（v1.5.0）

和旧消化材料相比，v1.5.0 把 v1.4.0 的 workspace/context-store/initiative 三概念统一为 store 模型：

- `PlanningHome` 简化为只有 `repo`，不再有 workspace 分支。
- 多仓库上下文不再走 `.openspec-workspace/view.yaml`，而是全局 store registry + 项目 `references:` 声明 + working set 组装。
- 新增 `openspec store`、`openspec context`、`openspec workset`、`openspec doctor` 四个命令。
- `actionContext.mode` 始终为 `repo-local`，旧 workspace guard 不再需要。
- Initiative 作为概念已废弃（`--initiative` flag 隐藏，提示不再支持）。

更详细的对比见 `03-planning-home-与-store-模型.md`。

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
| store 状态 | `src/core/store/` |
| root 选择 | `src/core/root-selection.ts` |
| references 索引 | `src/core/references.ts` |
| working set 组装 | `src/core/working-set.ts` |
| workset 管理 | `src/core/worksets.ts` |
| doctor 健康检查 | `src/core/relationship-health.ts` |
| openspec root 判定 | `src/core/openspec-root.ts` |
