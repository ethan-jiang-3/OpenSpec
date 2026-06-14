# PlanningHome 与 workspace

## PlanningHome 解决什么问题

当前源码里，很多 workflow 命令不能再简单假设“当前目录就是某个 repo”。用户可能在 repo 里，也可能在 managed workspace 里。`PlanningHome` 就是这个分流抽象。

核心类型在 `src/core/planning-home.ts`：

```ts
type PlanningHomeKind = 'repo' | 'workspace';
```

一个 planning home 至少包含：

- `kind`
- `root`
- `changesDir`
- `defaultSchema`
- workspace 名称和 links（仅 workspace）

## repo planning home

repo-local 的判定依据是从当前路径向上找 `openspec/` 目录。

repo planning home 的结果形状是：

```text
kind: repo
root: <repo-root>
changesDir: <repo-root>/openspec/changes
defaultSchema: spec-driven
```

这就是传统 OpenSpec 项目形态。change、spec、config、project-local schema 都在 repo 的 `openspec/` 下。

## workspace planning home

workspace 的判定依据是从当前路径向上找 `.openspec-workspace/view.yaml`。

workspace planning home 的结果形状是：

```text
kind: workspace
root: <workspace-root>
changesDir: <workspace-root>/changes
defaultSchema: workspace-planning
workspace:
  name: <view name>
  links: <registered link names>
```

注意这里的 `changesDir` 是 workspace-local 的 `changes/`。它适合保存 workspace planning artifact，而不是悄悄替某个 linked repo 创建 repo-local implementation plan。

## 同时在 repo 和 workspace 下时怎么选

`resolveCurrentPlanningHomeSync()` 同时查 workspace root 和 repo root。当前逻辑的关键点是：

- 如果当前路径在 workspace root 下，并且 workspace root 比 repo root 更近或没有 repo root，则返回 workspace。
- 否则返回 repo。
- 如果找不到任何 planning home，默认可以把当前目录当作 implicit repo root；调用方也可以禁止这个 fallback。

这个规则让 workspace 下的 OpenSpec 命令不会误把 linked repo 或父目录当成唯一上下文。

## workspace 是本地视图，不是业务归属

workspace 的源码命名很准确：`WorkspaceViewState`。

它记录的是：

- 本机 workspace 名称
- 当前打开的 initiative context
- link name 到本机路径的映射
- opener 和工具选择
- workspace-local skill profile 状态

它不记录：

- 远端仓库 clone 状态
- git branch / worktree 归属
- linked repo 的 specs 自动合并结果
- 自动跨 repo apply/archive 的事务状态

所以 workspace 更像“给 agent 打开的协作驾驶舱”，不是多仓库状态数据库。

## context store 与 initiative 的位置

workspace 可以绑定 initiative context：

```yaml
context:
  kind: initiative
  store:
    id: platform
    selector:
      kind: registry
      id: platform
  initiative:
    id: billing-launch
```

context store 通过 registry 或 path selector 解析。initiative 文件实际存放在 context store 的 collection mount 下。workspace 只保存“我当前打开哪个 context”的本机记录。

这也是为什么 workspace 适合本机打开和探索，而 initiative 更适合长期协调。

## workspace skills 的特殊点

`src/core/workspace/skills.ts` 明确把 workspace skill 安装视为 skills-only：

- profile 仍来自 global config。
- workflow ids 仍由 `getProfileWorkflows()` 决定。
- delivery 即使不是 `skills`，workspace 也只生成 skills，并给出 notice。
- 生成位置在 workspace root 下对应工具的 skills 目录。

这和 repo-local `init/update` 不同。repo-local 可以按 delivery 生成 skills、commands 或两者；workspace 当前不生成 command 文件。

## 对 agent 的实际含义

agent 在 workspace 中做事时，关键约束是：

- 先解析 workspace/context/links，不要假设 cwd 就是 owning repo。
- linked repos/folders 可以作为探索上下文。
- 实现编辑需要明确 allowed edit root 或 owning repo。
- repo-local change 应该从 owning repo 创建。
- workspace planning artifact 使用 `workspace-planning`，repo-local artifact 使用 `spec-driven` 或项目配置的 schema。

这些约束会出现在 `status` 的 `actionContext` 中，构造入口在 `buildActionContext()`。

## 源码入口

| 主题 | 入口 |
|------|------|
| planning home 判定 | `resolveCurrentPlanningHomeSync()` in `src/core/planning-home.ts` |
| repo/workspace 默认 schema | `repoPlanningHome()`、`workspacePlanningHome()` in `src/core/planning-home.ts` |
| workspace view state | `WorkspaceViewState` in `src/core/workspace/foundation.ts` |
| workspace registry | `src/core/workspace/registry.ts` |
| workspace skill 安装 | `src/core/workspace/skills.ts` |
| action context | `buildActionContext()` in `src/core/change-status-policy.ts` |
| workspace CLI | `src/commands/workspace.ts` |
