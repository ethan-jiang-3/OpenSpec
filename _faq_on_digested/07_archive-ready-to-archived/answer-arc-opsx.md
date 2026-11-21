# 答案 ARC OPSX：`/openspec-archive-change` 和 CLI archive 为什么不一样

## 一句话

`/openspec-archive-change` 是投递给 coding agent 的操作模板；`openspec archive` 是 CLI 程序。它们都叫 archive，但不是同一条执行路径。

```text
openspec archive
  -> ArchiveCommand.execute()
  -> programmatic validate / merge / move

/openspec-archive-change
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

## `/openspec-archive-change` 模板主线

OPSX 模板在：

```text
src/core/templates/workflows/archive-change.ts
```

它指导 agent 做（全程**不调用 `openspec archive` CLI**）：

1. 选择 change（未显式传入且有歧义时，运行 `openspec list --json` 让用户选择），并运行 `openspec instructions archive --change "<name>" --json` 读取可选的 `context` 与 `operationGuidance`。
2. 运行 `openspec status --change "<name>" --json`，检查所有 artifacts 是否均为 `done` 或 `skipped`（有未完成项时警告并请用户确认）。
3. 运行 `openspec list --json`，从匹配该 change 的条目读取 schema-aware 的 `totalTasks` 与 `completedTasks`（不直接假设顶层 `tasks.md`）；存在未完成任务时警告并请用户确认。
4. **先预检归档目标路径** `<planningHome.changesDir>/archive/<target-name>` 是否已存在（v2.1.1 `#2277`，在写任何主 spec 前硬拦目标冲突！）。
5. 用 `artifactPaths.specs.existingOutputPaths` 找 delta specs，与 `<planningHome.root>/openspec/specs/<capability-path>/spec.md` 做 delta sync assessment 并向用户询问。
6. 若用户选择同步：再次确认归档目标未占用，运行 `openspec instructions specs --change "<name>" --json` 获取 rules 快照，随后同步内联执行 `openspec-sync-specs`（或内联智能合并）并校验主 specs。
7. 创建 `<planningHome.changesDir>/archive` 目录（`mkdir -p`），移动前最后复检目标不存在，执行 `mv` 移动 `changeRoot` 并输出摘要。

这条路径是独立的 agent 操作手册，不是 `ArchiveCommand.execute()` 的 wrapper。

## 为什么 archive skill 要先跑 status 与 list

因为 agent 运行在宿主会话里，不能硬编码目录名、schema 或任务文件名。`status --json` 与 `list --json` 给它：

```text
schemaName
planningHome
changeRoot
artifactPaths
actionContext
artifacts
totalTasks / completedTasks
```

尤其是：

- `changeRoot` 与 `planningHome`：不能硬编码当前目录下的 `openspec/changes/<name>` 或 `openspec/specs/`。
- `artifactPaths.specs.existingOutputPaths`：唯一的 delta spec 文件列表来源。
- CLI `ArchiveCommand` 同样支持 `--store <id>`、项目 `store:` 指针与全局 `defaultStore`（进程内通过 `resolveRootForCommand` 解析 root）；而 archive skill 运行在外部 coding agent 中，所以通过 `status --json` / `list --json` 获取这些已解析的路径和计数。

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

所以 `/openspec-archive-change` 先做 sync assessment 是安全网，不是 `ArchiveCommand.execute()` 中的一步。

## 手动 move 也是模板层行为

OPSX 模板的 archive step 写的是：

```bash
mkdir -p "<planningHome.changesDir>/archive"
mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
```

它要求 agent 根据 status JSON 中的路径移动目录。

CLI archive 则调用 `moveDirectory()`，优先 `fs.rename()`；EPERM/EXDEV 时先把 source 改名到私有 staging path，再执行 fingerprint-protected copy、验证和可恢复清理。

两者最终文件系统目标相同，但执行机制不同。

## 读文档时怎么避免混淆

推荐按这条规则读：

| 你关心的问题 | 应该看哪条路径 |
|---|---|
| `openspec archive` 命令实际做什么 | CLI 主线：`ArchiveCommand.execute()` |
| `/openspec-archive-change` 为什么让 agent 先检查 status | 模板主线：`archive-change.ts` |
| delta spec 程序化合并算法 | `specs-apply.ts` |
| agent 如何智能同步 specs | `sync-specs.ts` 模板 |

## 参考来源

源码引用以 [`../../_digested/README.md`](../../_digested/README.md) 声明的「当前源码基线」（`0c737dc1`）为准：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/archive-change.ts` | `/openspec-archive-change` 模板步骤、sync assessment、manual move |
| `src/core/templates/workflows/sync-specs.ts` | agent-driven spec sync 语义 |
| `src/core/archive.ts` | CLI archive 与模板路径的差异 |
| `_digested/internal-spec-driven/04-archive-归档合并.md` | CLI 和 OPSX 两条路径的分层说明 |
