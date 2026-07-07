# 答案 ARC OPSX：`/opsx:archive` 和 CLI archive 为什么不一样

## 一句话

`/opsx:archive` 是投递给 coding agent 的操作模板；`openspec archive` 是 CLI 程序。它们都叫 archive，但不是同一条执行路径。

```text
openspec archive
  -> ArchiveCommand.execute()
  -> programmatic validate / merge / move

/opsx:archive
  -> agent reads template
  -> status / warning / sync assessment / move
```

这个区别是理解 archive 最容易踩坑的地方。

## CLI 主线

CLI 主线是：

```bash
openspec archive <change>
```

源码入口：

```text
src/cli/index.ts
src/core/archive.ts
src/core/specs-apply.ts
```

它直接在程序里做：

- proposal/delta validation。
- tasks progress warning。
- programmatic delta spec merge。
- main spec rebuilt validation。
- active change 目录移动到 archive。

CLI 不需要 agent 读 `status --json`，也不需要 `openspec-sync-specs`。

## `/opsx:archive` 模板主线

OPSX 模板在：

```text
src/core/templates/workflows/archive-change.ts
```

它指导 agent 做：

1. 没有 change name 时，运行 `openspec list --json` 并让用户选择。
2. 运行 `openspec status --change "<name>" --json`。
3. 检查 artifact completion。
4. 读取 tasks file，警告未完成 tasks。
6. 用 `artifactPaths.specs.existingOutputPaths` 找 delta specs。
7. 做 delta sync assessment。
8. 必要时调用 `openspec-sync-specs`。
9. 创建 archive 目录并移动 change。

这条路径更像 agent 操作手册，不是 `ArchiveCommand.execute()` 的 wrapper。

## 为什么 OPSX 要先跑 status

因为 agent 不能假设路径和 schema。`status --json` 给它：

```text
schemaName
planningHome
changeRoot
artifactPaths
actionContext
artifacts
```

尤其是：

- `changeRoot`：不能硬编码 `openspec/changes/<name>`。
- `artifactPaths.specs.existingOutputPaths`：delta spec 文件列表。
CLI `ArchiveCommand` 是 repo-local 文件系统命令；OPSX 模板要适配 agent runtime，所以需要 status JSON。

## sync assessment 是模板层，不是 CLI 内部步骤

OPSX 模板要求：

```text
if delta specs exist:
  compare delta spec with main spec
  summarize changes
  prompt user:
    Sync now
    Archive without syncing
```

如果用户选择 sync，模板会让 agent 调用 `openspec-sync-specs`。

这和 CLI archive 的 programmatic merge 不同：

| 维度 | CLI archive | OPSX sync |
|---|---|---|
| 执行者 | TypeScript 程序 | coding agent |
| 入口 | `ArchiveCommand.execute()` | `openspec-sync-specs` skill/template |
| MODIFIED 语义 | 完整 requirement block 替换 | 可智能合并局部 intent |
| 是否移动 change | CLI archive 会移动 | sync 只更新主 specs，change 仍 active |

所以 `/opsx:archive` 先做 sync assessment 是安全网，不是 `ArchiveCommand.execute()` 中的一步。

## 手动 move 也是模板层行为

OPSX 模板的 archive step 写的是：

```bash
mkdir -p "<planningHome.changesDir>/archive"
mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
```

它要求 agent 根据 status JSON 中的路径移动目录。

CLI archive 则调用 `moveDirectory()`，优先 `fs.rename()`，必要时 fallback copy + remove。

两者最终文件系统目标相同，但执行机制不同。

## 读文档时怎么避免混淆

推荐按这条规则读：

| 你关心的问题 | 应该看哪条路径 |
|---|---|
| `openspec archive` 命令实际做什么 | CLI 主线：`ArchiveCommand.execute()` |
| `/opsx:archive` 为什么让 agent 先检查 status | 模板主线：`archive-change.ts` |
| delta spec 程序化合并算法 | `specs-apply.ts` |
| agent 如何智能同步 specs | `sync-specs.ts` 模板 |

## 参考来源

源码引用基于 commit `487ea92`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/archive-change.ts` | `/opsx:archive` 模板步骤、sync assessment、manual move |
| `src/core/templates/workflows/sync-specs.ts` | agent-driven spec sync 语义 |
| `src/core/archive.ts` | CLI archive 与模板路径的差异 |
| `_digested/internal-spec-driven/04-archive-归档合并.md` | CLI 和 OPSX 两条路径的分层说明 |
