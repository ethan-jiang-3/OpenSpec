# Context Store 与 Initiative

## context store 的状态

context store 有两层状态：

```text
getGlobalDataDir()/context-stores/registry.yaml
<store-root>/.openspec-store/store.yaml
```

registry 记录本机已知 store id 到 backend 的映射。metadata 记录 store 自己的 id。

源码入口：

- `src/core/context-store/foundation.ts`
- `src/core/context-store/registry.ts`
- `src/core/context-store/operations.ts`

## backend 形状

当前 backend 只有一种：

```yaml
backend:
  type: git
  local_path: /path/to/store
  remote: optional
  branch: optional
```

这里的 `git` 不是说 OpenSpec 自动同步远端，而是 context store 可用 Git 管理。setup 可以 init git，但 pull/push/conflict handling 不属于当前实现。

## registry 冲突检查

`assertNoRegisteredStoreConflict()` 同时防两类冲突：

- 同一个 id 指向不同 path。
- 不同 id 指向同一个 path。

这保证本机 registry 不会把一个 store root 当成两个不同 store，也不会把一个 id 解析成两个地方。

## setup / register / remove 的边界

| 操作 | 行为边界 |
|------|----------|
| setup | 可创建 store root、metadata、registry entry，可选 git init |
| register | 注册已有 store path，可补 metadata |
| unregister | 只移除 registry entry，保留磁盘文件 |
| remove | 删除 managed local store folder，属于破坏性操作，需要明确确认 |
| doctor | 检查 registry、metadata、git 状态，返回 diagnostics |

## collection runtime

context store 内部不是硬编码只有 initiative。`src/core/collections/runtime.ts` 提供 collection registry/mount 抽象：

- collection 有 `id` 和 `mount`。
- mount 后得到 `MountedCollection`。
- collection path 必须是相对路径，禁止绝对路径、Windows drive path、dot segment。

initiative 是当前唯一重要 collection，但 runtime 已经为后续 collection 留了扩展点。

## initiative 文件形状

initiative collection mount 是：

```text
initiatives/<initiative-id>/
├── initiative.yaml
├── requirements.md
├── design.md
├── decisions.md
├── questions.md
└── tasks.md
```

`createInitiative()` 会：

1. 校验 collection id 是 `initiatives`。
2. normalize initiative state。
3. 创建 initiative 目录。
4. 独占写入 `initiative.yaml` 和默认 Markdown 文件。
5. 失败时清理刚创建的目录。

## initiative resolution

`src/core/collections/initiatives/resolution.ts` 负责把用户输入解析成具体 initiative：

- `<initiative-id>`
- `<store>/<initiative-id>`
- `<initiative-id> --store <store>`
- `<initiative-id> --store-path <path>`

如果没有明确 store，会通过 context-store selector 解析。错误会转换成 initiative diagnostic，供 CLI JSON 输出。

## workspace 绑定 initiative

workspace view state 里的 context 只保存 selector 和 initiative id：

```yaml
context:
  kind: initiative
  store:
    id: team-context
    selector:
      kind: registry
      id: team-context
  initiative:
    id: billing-launch
```

实际 initiative 内容仍在 context store。workspace 只是记录“当前本机视图打开哪一个 coordination context”。
