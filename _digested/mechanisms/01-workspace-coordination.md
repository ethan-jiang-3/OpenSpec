# Workspace Coordination

## 它解决的不是“多仓库合并”

熟悉 AI Coding 的人很容易期待一个多仓库工具能做这件事：把几个 repo 放进一个大上下文，然后让 agent 自动决定哪里规划、哪里实现、哪里归档。OpenSpec 当前没有这样做。

workspace 的设计更克制：它是 **local coordination view**。它帮一台机器上的 agent 同时看见多个 repo/folder、一个 initiative 上下文、合适的 opener 和 workspace-local skills；但它不把 linked repo 合并成新的事实源，也不替 repo 决定 durable change 应该落在哪里。

这个取舍的工程意义是：跨仓库探索可以集中，业务规格和实现归属仍然清晰。workspace 负责“打开上下文”，repo-local OpenSpec 负责“承载可归档的变更”。

## 三个状态对象

| 对象 | 位置 | 本质 |
|------|------|------|
| workspace view | `<workspace-root>/.openspec-workspace/view.yaml` | 这台机器如何打开一组上下文 |
| context store | `getGlobalDataDir()/context-stores/<id>` 或用户指定路径 | 可用 Git 管理的协调数据容器 |
| initiative | `<context-store>/initiatives/<id>/` | 一次跨 repo/团队使命的持久上下文 |

workspace 可以绑定 initiative，也可以只保存 linked repos/folders。context store 和 initiative 不依赖某个 workspace 才能存在。

## view.yaml 为什么是本机状态

`WorkspaceViewState` 在 `src/core/workspace/foundation.ts`，包含：

- `version: 1`
- `name`
- `context`
- `links`
- `preferred_opener`
- `tools`
- `workspace_skills`

这份文件保存的是“本机怎么打开这组上下文”，不是团队共享业务事实。`links` 是 link name 到本机路径的映射，路径可以是 repo，也可以是普通 folder。`workspace link` 和 `workspace relink` 只记录现有目录，不 clone、不初始化、不修改 linked path 内容。

这正是 workspace 和 monorepo 的差别：monorepo 把代码组织成一个版本控制事实；workspace 把本机可见的多个位置组织成一个工作视图。

## managed workspace registry

managed workspace root 来自：

```text
getGlobalDataDir()/workspaces/<workspace-name>
```

registry 文件是：

```text
getGlobalDataDir()/workspaces/registry.yaml
```

`src/core/workspace/registry.ts` 同时支持读取旧 registry 和扫描 managed workspaces 目录，再合并成 `listKnownWorkspaceEntries()`。所以 `workspace list` 不是只读一个 registry 文件；它也能发现 managed workspace 目录中存在的 view state。

## legacy state 说明了这层还在演进

旧 workspace 状态分成 shared/local 两份：

```text
.openspec-workspace/workspace.yaml
.openspec-workspace/local.yaml
```

当前源码仍保留兼容读取：优先读新的 `view.yaml`；没有时读取 legacy shared/local，再转换成 `WorkspaceViewState`。因此文档里不能再把 root-level `workspace.yaml` 当成当前状态文件。

这个细节也说明 workspace 是 OpenSpec v1.4.x 里仍在成形的系统层。写机制结论时要避免把 beta 行为说成长期协议。

## open surface：让 agent 看到正确上下文

`workspace open` 不只是启动编辑器。它会先生成 workspace-local open surface：

```text
<workspace-root>/AGENTS.md
<workspace-root>/<workspace-name>.code-workspace
```

源码入口是 `src/core/workspace/open-surface.ts`。

OpenSpec 管理 `AGENTS.md` 中 marker 包起来的 guidance block：

```text
<!-- OPENSPEC:WORKSPACE-GUIDANCE:START -->
...
<!-- OPENSPEC:WORKSPACE-GUIDANCE:END -->
```

策略是：完整 marker block 存在就替换；marker 不完整就报错；文件为空就写入；已有用户内容就追加到末尾。这保证 OpenSpec 只管理自己那段 guidance，不覆盖用户手写内容。

`.code-workspace` 则按顺序包含 valid linked repos/folders、selected initiative context、workspace root 自身。顺序有意图：先让用户看到实现上下文，再看到 initiative，最后看到 OpenSpec workspace 文件。

## opener 是启动策略，不是状态事实

`WorkspacePreferredOpener` 分两类：

```text
agent: codex-cli / claude / github-copilot
editor: vscode
```

`workspace open` 会根据 explicit override 或 stored preferred opener 选择实际启动方式。VS Code / GitHub Copilot 打开 `.code-workspace` 文件；agent opener 以 workspace root 为 cwd，并把 initiative/link paths 作为附加目录传入。Codex CLI opener 如果有 attached paths，会加 `--sandbox workspace-write`。

opener 不可用通常只是本机环境问题，不代表 workspace 状态坏了。

## context store 与 initiative

context store 有两层状态：

```text
getGlobalDataDir()/context-stores/registry.yaml
<store-root>/.openspec-store/store.yaml
```

registry 记录本机已知 store id 到 backend 的映射；metadata 记录 store 自己的 id。当前 backend 只有 `git`：

```yaml
backend:
  type: git
  local_path: /path/to/store
  remote: optional
  branch: optional
```

这里的 `git` 表示 context store 可用 Git 管理。OpenSpec setup 可以 init git，但 pull/push/conflict handling 不属于当前实现。

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

workspace view state 只保存 selector 和 initiative id；实际 initiative 内容仍在 context store。也就是说，workspace 不是复制 initiative，而是记录“当前视图打开哪一个 coordination context”。

## 工程洞察

- workspace 把“探索上下文”从“业务事实”中分离出来，降低跨 repo agent 操作的误伤风险。
- context store 把跨 repo 长期协调内容放到 repo 之外，避免把团队级 initiative 错塞到某个业务 repo。
- open surface 把 agent guidance 和 editor multi-root view 作为生成物，而不是 source of truth。
- workspace doctor 的核心是检查本机路径、context、initiative、skills drift，不验证 linked repo 的业务正确性。

## 源码锚点

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
