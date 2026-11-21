# PlanningHome 与 store 模型

## PlanningHome

`PlanningHomeKind` 只有一种：

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

`resolveCurrentPlanningHomeSync()` 从当前目录向上找 `openspec/` 目录。找不到时，如果 `allowImplicitRepoRoot !== false`，把当前目录当 implicit root。

**会误报空项目通过的命令关掉了这条 fallback**：`list` 只在 cwd 仍有遗留 `openspec/project.md` 时允许 implicit；`validate --all/--changes/--specs` 设 `allowImplicitRoot: false`。项目外跑它们会非零退出，不再 exit 0 报空列表。单条 `validate <name>` 和其他有意使用 implicit root 的工作流不变。`openspec schemas` 走同一套 canonical root selection，并接受 `--store <id>`。

## Store 模型

多仓库协同通过 store 模型实现：

- **store**：全局注册的仓库 checkout
- **reference**：项目声明的 store 依赖
- **working set**：组装后的上下文
- **workset**：个人保存的工作视图

### `defaultStore` 不是项目 root 覆盖

可通过全局配置设置 `defaultStore`。它是机器上的低优先级 fallback；有显式 `--store`、项目配置或当前目录可解析 root 时，后者优先。root JSON 可把这一来源标为 `global_default`。因此不能把 default store 解释成“所有 change 都改到这个仓库”。

### Store：注册一个仓库

Store 是**全局注册的仓库 checkout**。数据放在 `<globalDataDir>/stores/`（macOS/Linux 是 `~/.local/share/openspec/stores/`，**不是** `~/.openspec`）：

```yaml
# <globalDataDir>/stores/registry.yaml
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
remote: https://github.com/team/platform-api.git
```

CLI 操作：

```bash
openspec store setup [id] --path <path> [--remote <url>] [--no-init-git]
  # 在本地初始化并注册新 store 目录（绝不 clone 远端仓库；--remote 仅作为团队 canonical clone 元数据写入 store.yaml，不执行 git remote add origin）
openspec store register [path] --id <store-id>    # 注册已有的本地 checkout（仅接受 --id/--yes/--json）
openspec store list                               # 列出
openspec store unregister <id>                    # 注销（保留文件）
openspec store remove <id>                        # 连本地文件夹一起删
openspec store doctor [id]                        # 健康检查
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
openspec workset create my-session --member . --member platform-api=<path/to/platform-api>
openspec workset open my-session   # 在编辑器里打开所有 member（不支持 --json，传了报 workset_open_json_unsupported）
openspec workset list
```

- `workset create` 把成员与可选首选工具写入 `<globalDataDir>/worksets/worksets.yaml`（纯本地，不提交、不共享、不写入 member 目录）。
- `workset open <name>` 每次运行时在锁内按当前仍存在的成员目录重新生成 `<globalDataDir>/worksets/<name>.code-workspace`，再交给 opener 启动；由于它把当前终端交接给外部工具，显式拒绝 `--json`（`workset_open_json_unsupported`）。
- 内置 opener 分两类（`src/core/openers.ts`）：`workspace-file` 风格（`code`、`cursor`）默认启用；CLI-agent `attach-dirs` 风格（`claude`、`codex`）默认被门禁关闭，需显式设置 `OPENSPEC_ENABLE_CLI_AGENT_OPENERS=1` 才允许打开。

### Doctor：健康检查

`openspec doctor` 检查 store 引用和 root 的健康状态：

- 引用的 store 是否已注册
- store checkout 是否存在且可读
- store metadata 是否有效

源码入口：`src/commands/doctor.ts`、`src/core/relationship-health.ts`。

## 对 agent 的实际含义

命令通过 `src/core/root-selection.ts` 解析操作目标：

- `--store <id>` 选择注册的 store 的 root
- 无 `--store` 时，优先解析项目/当前目录 root；必要时才使用机器级 `defaultStore` fallback

`actionContext.mode` 始终是 `'repo-local'`。

`openspec view` 也使用同一 root-selection 语义，并支持 `--store`；它展示的不是固定 cwd 下的目录。

## 源码入口

| 主题 | 入口 |
|------|------|
| planning home 判定 | `resolveCurrentPlanningHomeSync()` in `src/core/planning-home.ts` |
| store 基础数据 | `src/core/store/foundation.ts`（metadata, registry state, path helpers） |
| store CRUD | `src/core/store/operations.ts`（1267 行） |
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
