# Open Surface 与 Opener

## open surface 是什么

workspace open 不只是启动编辑器。它会先生成 workspace-local open surface：

```text
<workspace-root>/AGENTS.md
<workspace-root>/<workspace-name>.code-workspace
```

源码入口是 `src/core/workspace/open-surface.ts`。

## AGENTS.md guidance block

OpenSpec 管理的 guidance block 用 marker 包起来：

```text
<!-- OPENSPEC:WORKSPACE-GUIDANCE:START -->
...
<!-- OPENSPEC:WORKSPACE-GUIDANCE:END -->
```

`applyWorkspaceGuidanceBlock()` 的策略：

- 如果已有完整 marker block，替换 block。
- 如果 marker 状态不完整，抛错。
- 如果文件为空，写入 block。
- 如果文件已有用户内容，把 block 追加到末尾。

这说明 OpenSpec 只管理 marker 中间的内容，不应该覆盖用户在 AGENTS.md 里的其他手写内容。

## `.code-workspace` 内容

`buildWorkspaceCodeWorkspaceContent()` 生成 VS Code 多根 workspace：

1. valid linked repos/folders。
2. selected initiative context（如果已解析）。
3. OpenSpec workspace root 自身。

顺序有意图：先让用户看到实现上下文，再看到 initiative，最后看到 OpenSpec workspace 文件。

## skipped links

open surface 会把不可打开的 link 放进 skipped 列表：

- `missing-local-path`
- `path-missing`

这符合 workspace 的本机视图定位：某台机器缺少 linked path 是诊断问题，不是团队共享事实损坏。

## opener 类型

`WorkspacePreferredOpener` 分两类：

```text
agent: codex-cli / claude / github-copilot
editor: vscode
```

入口在 `src/core/workspace/openers.ts`。`workspace open` 会根据 explicit override 或 stored preferred opener 选择实际启动方式。

## launch command 生成

`buildWorkspaceOpenLaunchCommand()` 在 `src/commands/workspace/open.ts`：

- VS Code / GitHub Copilot：打开 `.code-workspace` 文件。
- agent opener：以 workspace root 为 cwd，并把 initiative/link paths 作为附加目录传入。
- Codex CLI opener：如果有 attached paths，会加 `--sandbox workspace-write`。

这说明 workspace open 对不同 opener 的边界不同：editor 看的是 workspace file；agent 看的是 cwd、附加目录和最小 prompt。

## 可用性检查

`assertWorkspaceOpenerAvailable()` 会检查 opener executable 是否在 PATH：

- `code` 缺失时会提示可手动打开 `.code-workspace`。
- agent executable 缺失时要求安装或换 opener。

open 命令失败并不意味着 workspace 状态坏了，常见只是本机 opener 不可用。
