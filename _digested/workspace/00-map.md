# Workspace 内核地图

## 一句话

workspace 是 OpenSpec 的本机协调视图：它把 context store、initiative、linked repos/folders、opener、workspace-local skills 放到一个 managed workspace root 里，但不把 linked repo 合并成一个新的业务事实源。

## 三个核心对象

| 对象 | 位置 | 本质 |
|------|------|------|
| workspace view | `getGlobalDataDir()/workspaces/<name>/.openspec-workspace/view.yaml` | 本机私有视图状态 |
| context store | `getGlobalDataDir()/context-stores/<id>` 或用户指定路径 | 可共享协调数据容器 |
| initiative | `<context-store>/initiatives/<id>/` | 一次跨 repo/团队使命的持久上下文 |

workspace 可以绑定 initiative，也可以只作为 linked repo/folder 的本地视图。context store 和 initiative 不要求某个 workspace 才能存在。

## 运行链路

```text
workspace setup
  → createManagedWorkspace()
  → writeWorkspaceViewState()
  → syncWorkspaceOpenSurface()
  → optional workspace skill install

workspace open
  → readWorkspaceViewState()
  → resolve initiative context
  → syncWorkspaceOpenSurface()
  → buildWorkspaceOpenLaunchCommand()
  → spawn opener

context-store setup
  → prepareContextStoreSetup()
  → setupPreparedContextStore()
  → commitContextStoreRegistration()

initiative create/show/list
  → selectContextStoreForInitiative()
  → mountInitiativesCollection()
  → create/list/read initiative files
```

## 关键源码入口

| 机制 | 路径 |
|------|------|
| workspace 状态 schema | `src/core/workspace/foundation.ts` |
| workspace view state IO | `src/core/workspace/state-io.ts` |
| legacy workspace 兼容 | `src/core/workspace/legacy-state.ts` |
| managed workspace registry | `src/core/workspace/registry.ts` |
| workspace CLI operations | `src/commands/workspace/operations.ts` |
| open surface 生成 | `src/core/workspace/open-surface.ts` |
| opener 选择和启动 | `src/core/workspace/openers.ts`、`src/commands/workspace/open.ts` |
| workspace skills | `src/core/workspace/skills.ts` |
| context store | `src/core/context-store/` |
| initiative collection | `src/core/collections/initiatives/` |

## 测试锚点

- `test/core/workspace/`
- `test/commands/workspace*.test.ts`
- `test/core/context-store/`
- `test/commands/context-store.test.ts`
- `test/core/collections/initiatives/`
- `test/commands/initiative.test.ts`
