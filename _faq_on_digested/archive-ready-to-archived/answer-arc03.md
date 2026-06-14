# 答案 ARC03：`ArchiveCommand.execute()` 的主流程和 flags

## 一句话

`openspec archive` 的 CLI 主线在 `src/core/archive.ts` 的 `ArchiveCommand.execute()`。它做的是一个程序化收束：

```text
validate change
check tasks
update main specs unless skipped
move change to archive
```

它不通过 `openspec status --json` 构建 artifact DAG，也不调用 `instructions apply`。那些是 agent workflow 模板会做的事情。

## CLI 入口

`src/cli/index.ts` 注册：

```text
openspec archive [change-name]
```

可用 flags：

| flag | 作用 |
|---|---|
| `-y, --yes` | 跳过确认提示。 |
| `--skip-specs` | 不更新主 specs，只 archive change。 |
| `--no-validate` | 跳过 validation，不推荐；没有 `--yes` 时还会额外确认。 |

内部 options 还支持 `validate: false`，这是 commander `--no-validate` 的语义形态，测试里也覆盖了。

## 选择 change

如果命令传了 name：

```bash
openspec archive add-auth
```

CLI 直接用它。

如果没传 name，`selectChange()` 会读取 `openspec/changes/` 下的 active change 目录，排除 `archive/`，并用 inquirer 让用户选择。

这和 `/opsx:archive` 模板不同。OPSX 模板要求没有 name 时总是用 `openspec list --json` 加 AskUserQuestion，由 agent 组织选择。

## 目录验证

`execute()` 首先检查：

```text
openspec/changes/
openspec/changes/<change>/
```

不存在就报错或中止。这个阶段不会读取 schema，也不会判断 artifact graph。

CLI archive 是 repo-local 的老牌命令路径；它以当前目录下的 `openspec/` 为根。

## validation pass

默认情况下：

1. 如果有 `proposal.md`，调用 `Validator.validateChange()`。
2. 如果发现 delta-formatted specs，调用 `Validator.validateChangeDeltaSpecs()`。

proposal validation 是 warning，不阻塞 archive。

delta spec validation 有 ERROR 时会阻塞：

```text
Validation failed. Please fix the errors before archiving.
To skip validation (not recommended), use --no-validate flag.
```

`--no-validate` 会跳过这些验证。没有 `--yes` 时，它会先问用户是否确认跳过；有 `--yes` 时直接打印 warning 并继续。

## task progress check

validation 后，CLI 调：

```text
getTaskProgressForChange(changesDir, changeName)
formatTaskStatus(progress)
```

统计来自固定文件：

```text
openspec/changes/<change>/tasks.md
```

如果文件不存在，结果是：

```text
total = 0
completed = 0
No tasks
```

如果有未完成 checkbox：

```text
Warning: N incomplete task(s) found. Continue?
```

没有 `--yes` 时用户可以取消；有 `--yes` 时打印 warning 后继续。

注意这里和 `instructions apply` 的 state 不完全相同：

| 阶段 | task 缺失/未完成怎么处理 |
|---|---|
| apply instructions | `tasks.md` 缺失或无 checkbox 可能是 `blocked`。 |
| archive CLI | 没有 `tasks.md` 可以继续；未完成 tasks 是 warning + confirmation。 |

## spec updates

如果没有 `--skip-specs`，CLI 会查找并合并 change 下的 delta specs。

如果找到 updates，CLI 显示每个 capability 是 `create` 还是 `update`，没有 `--yes` 时询问：

```text
Proceed with spec updates?
```

用户拒绝时，CLI 不更新主 specs，但仍然 archive change。

`--skip-specs` 更直接：完全跳过 spec update 操作。

## move 阶段

最后生成目标：

```text
openspec/changes/archive/YYYY-MM-DD-<change>/
```

如果已存在，抛错，不覆盖。

移动使用 `moveDirectory()`：

```text
fs.rename()
fallback on EPERM/EXDEV: copyDirRecursive() + fs.rm(src)
```

完成后 active change 目录消失，archived change 目录保留全部原 artifacts 和 `.openspec.yaml`。

## 小结

`ArchiveCommand.execute()` 的关键特点：

- 它是 CLI 程序路径，不是 agent instructions API。
- 它可以在 warnings 下继续 archive。
- 它默认会 programmatic merge delta specs。
- 它允许用户跳过 specs 或 validation。
- 它最终通过文件系统移动结束 active change 生命周期。

## 参考来源

源码引用基于 commit `487ea92`：

| 来源 | 用到的结论 |
|---|---|
| `src/cli/index.ts` | archive CLI 注册和 flags |
| `src/core/archive.ts` | `ArchiveCommand.execute()`、`selectChange()`、`moveDirectory()` |
| `src/utils/task-progress.ts` | task progress 统计 |
| `test/core/archive.test.ts` | skip specs、skip validation、interactive selection、incomplete tasks 行为 |
