# PlanningHome 与 store 模型（v1.5.0）

> **v1.5.0 重写**：v1.4.0 的 workspace + initiative + context-store 三概念统一为 store 模型。PlanningHome 大幅简化。

## PlanningHome：只剩下 repo

v1.4.0 的 `PlanningHomeKind` 是 `'repo' | 'workspace'`。v1.5.0 只剩一种：

```ts
// src/core/planning-home.ts
type PlanningHomeKind = 'repo';

interface PlanningHome {
  kind: PlanningHomeKind;
  root: string;
  changesDir: string;
  defaultSchema: string;  // 始终是 'spec-driven'
}
```

`resolveCurrentPlanningHomeSync()` 的唯一逻辑是从当前目录向上找 `openspec/` 目录。找不到时，如果 `allowImplicitRepoRoot !== false`，把当前目录当 implicit root。

**workspace planning home 已被完全移除。** 没有 `workspace-planning` 默认 schema，没有 `.openspec-workspace/view.yaml` 查找逻辑。

## 那多仓库协同去哪了？Store 模型

v1.5.0 用一套更简单的机制替代了旧的 workspace/initiative/context-store 三件套：

```
旧模型（v1.4.0）:
  workspace（本地视图，view.yaml）
  + context-store（团队共享上下文，registry/binding）
  + initiative（长期协调，collection）

新模型（v1.5.0）:
  store（注册的仓库）
  + reference（项目声明的 store 依赖）
  + working set（组装后的上下文）
  + workset（个人保存的工作视图）
```

### Store：注册一个仓库

Store 是**全局注册的仓库 checkout**。数据放在 `~/.openspec/stores/`：

```yaml
# ~/.openspec/stores/registry.yaml
version: 1
stores:
  platform-api:
    backend:
      type: git
      local_path: /Users/alice/workspace/platform-api
      remote: https://github.com/team/platform-api.git
      branch: main
```

每个 store checkout 下有一个 `.openspec-store/store.yaml` 记录身份：

```yaml
# <checkout>/.openspec-store/store.yaml
version: 1
id: platform-api
remote: https://github.com/team/platform-api.git  # 可选，slice 3.3
```

CLI 操作：

```bash
openspec store register <path> --id <store-id>   # 注册
openspec store list                               # 列出
openspec store unregister <id>                    # 注销
openspec store info <id>                          # 详情
```

### Reference：声明依赖

项目的 `openspec/config.yaml` 可以声明它引用了哪些 store：

```yaml
# openspec/config.yaml
references:
  - platform-api
  - shared-schemas
```

这些 reference 告诉 agent：当前项目的工作可能涉及这些 store 的 specs。agent 通过 `openspec context` 获取引用 store 的 spec 索引（id + 摘要 + fetch recipe），但不内联内容。

### Working Set：组装后的上下文

`openspec context` 命令把 root + references 组装成一个 **working set**：

```text
Working context for my-project (/path/to/my-project)

OpenSpec root
  my-project  /path/to/my-project

Referenced stores
  platform-api  /Users/alice/workspace/platform-api
  shared-schemas  （not available — run: git clone ... && openspec store register ...）
```

核心模块 `src/core/working-set.ts` 的 `assembleWorkingSet()` 只做组装，不做 clone/sync。不可解析的 member 报告给用户，不猜测。

### Workset：个人工作视图

`openspec workset` 提供纯本地的、手动组合的、命名的多仓库打开视图：

```bash
openspec workset save my-session --root . --store platform-api
openspec workset open my-session   # 在编辑器里打开所有 member
openspec workset list
```

数据存在 `~/.openspec/worksets/worksets.yaml`。不提交、不共享、不写入 member 目录。

### Doctor：健康检查

`openspec doctor` 检查 store 引用和 root 的健康状态：

- 引用的 store 是否已注册
- store checkout 是否存在且可读
- store metadata 是否有效

源码入口：`src/commands/doctor.ts`、`src/core/relationship-health.ts`。

## 和 v1.4.0 workspace 的根本区别

| 维度 | v1.4.0 workspace | v1.5.0 stores |
|------|-----------------|---------------|
| PlanningHome 种类 | repo + workspace 两种 | 只有 repo |
| 多仓库入口 | `.openspec-workspace/view.yaml` | `~/.openspec/stores/registry.yaml`（全局） |
| 默认 schema | workspace-planning | 无——只有 spec-driven |
| 动作范围 | workspace 有独立的 changes/ | store 不承载 change——change 始终在某个 PlanningHome repo 下 |
| 上下文机制 | context store binding → initiative collection | references 声明 → working set 组装 |
| Agent guard | `actionContext.mode = "workspace-planning"` 阻止 apply/archive | `actionContext.mode` 始终 `"repo-local"`——不再需要 workspace guard |
| 团队共享 | context store 作为共享 registry | store remote 作为 clone 来源；不内置团队同步 |
| 个人视图 | 无 | workset（纯本地） |

## 对 agent 的实际含义

v1.5.0 的命令都通过 `src/core/root-selection.ts` 解析操作目标：

- `--store <id>` 选择注册的 store 的 root
- 无 `--store` 时，向上找最近的 `openspec/` 目录
- 旧 workspace view state 从不被当作 root

`actionContext.mode` 始终是 `'repo-local'`。旧的 workspace guard（阻止在 workspace 中 apply/archive）不再需要——因为根本就没有 workspace planning home 了。

## 源码入口

| 主题 | v1.5.0 入口 |
|------|-------------|
| planning home 判定 | `resolveCurrentPlanningHomeSync()` in `src/core/planning-home.ts` |
| store 基础数据 | `src/core/store/foundation.ts`（metadata, registry state, path helpers） |
| store CRUD | `src/core/store/operations.ts`（1196 行，最重的文件） |
| store registry | `src/core/store/registry.ts` |
| store git 操作 | `src/core/store/git.ts` |
| root 选择 | `resolveRootForCommand()` in `src/core/root-selection.ts` |
| references 索引 | `src/core/references.ts` |
| working set 组装 | `src/core/working-set.ts` |
| workset 管理 | `src/core/worksets.ts` |
| 关系健康检查 | `src/core/relationship-health.ts` |
| openspec root 判定 | `src/core/openspec-root.ts` |
| 文件状态与原子写 | `src/core/file-state.ts` |
| store CLI | `src/commands/store.ts` |
| context CLI | `src/commands/context.ts` |
| workset CLI | `src/commands/workset.ts`、`workset-input.ts`、`workset-prompts.ts` |
| doctor CLI | `src/commands/doctor.ts` |
| action context | `buildActionContext()` in `src/core/change-status-policy.ts` |
