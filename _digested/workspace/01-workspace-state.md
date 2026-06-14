# Workspace State

## 当前状态文件

当前 workspace 的主状态文件是：

```text
<workspace-root>/.openspec-workspace/view.yaml
```

源码类型是 `WorkspaceViewState`，在 `src/core/workspace/foundation.ts`。它包含：

- `version: 1`
- `name`
- `context`
- `links`
- `preferred_opener`
- `tools`
- `workspace_skills`

这份文件是本机私有状态，不是团队共享事实。它保存的是“这台机器如何打开这组上下文”。

## links 的语义

`links` 是 link name 到本机路径的映射：

```yaml
links:
  api: /repos/api
  web: /repos/web
```

路径可以是 repo，也可以是普通 folder。`workspace link` 和 `workspace relink` 只记录现有目录，不 clone、不初始化、不修改 linked path 内容。

校验入口：

- `validateWorkspaceLinkName()`：只禁止路径分隔符等危险名字，不要求 kebab-case。
- `resolveExistingDirectory()`：要求目标是现有目录，并 canonicalize 后保存。
- `parseWorkspaceSetupLinkInput()`：支持 `<path>` 和 `<name>=<path>` 两种输入。

## managed workspace registry

managed workspace root 来自：

```text
getGlobalDataDir()/workspaces/<workspace-name>
```

registry 文件是：

```text
getGlobalDataDir()/workspaces/registry.yaml
```

`src/core/workspace/registry.ts` 同时支持：

- 读取旧 registry。
- 扫描 managed workspaces 目录。
- 合并两种来源形成 `listKnownWorkspaceEntries()`。

这就是为什么 `workspace list` 不是只读一个 registry 文件：它也能发现 managed workspace 目录中存在的 view state。

## legacy state 兼容

旧 workspace 状态分成 shared/local 两份：

```text
.openspec-workspace/workspace.yaml
.openspec-workspace/local.yaml
```

当前源码仍保留兼容读取：

- `parseWorkspaceSharedState()`
- `parseWorkspaceLocalState()`
- `workspaceStatePartsToViewState()`

兼容策略是：优先读新的 `view.yaml`；没有时读取 legacy shared/local，再转换成 `WorkspaceViewState`。

这也是 workspace 文档容易过时的地方：现在不能再把 root-level `workspace.yaml` 当成 OpenSpec 当前状态文件。

## createManagedWorkspace 的关键步骤

`createManagedWorkspace()` 在 `src/commands/workspace/operations.ts`：

1. 校验 workspace name。
2. 计算 managed workspace root。
3. 创建目录。
4. 写入 `view.yaml`。
5. 同步 open surface。
6. 返回 JSON 友好的 `WorkspaceOutput`。

失败时会尝试清理刚创建的 workspace root，避免留下半初始化目录。

## doctor 的核心视角

workspace doctor 本质是在检查“这台机器还能不能解析 view state 里的路径”：

- view state 是否可读。
- linked path 是否存在。
- context store / initiative 是否可解析。
- workspace skills 是否和当前 global profile/delivery drift。

它不检查远端仓库同步状态，也不验证 linked repo 的业务规格是否正确。
