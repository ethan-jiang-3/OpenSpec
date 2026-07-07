# 答案 ARC Guards：Archive 什么时候停止、警告或带风险继续

## 一句话

archive 不是“无条件把目录挪走”。它有几类不同强度的 guard：

```text
hard stop       -> 不写 specs，不移动 change
warning confirm -> 用户确认后可以继续
skip option     -> 用户显式绕过某部分
risk zone       -> 已进入 I/O 写入或移动，可能没有事务回滚
```

理解这些区别，比只记“archive 会验证”更重要。

## hard stop：必须停止

这些情况会直接停止 archive。

| 条件 | 结果 |
|---|---|
| 没有 `openspec/changes/` | 抛错，提示先 `openspec init`。 |
| 指定 change 不存在 | 抛错。 |
| delta spec validation 有 ERROR | 打印 validation failed，return。 |
| `buildUpdatedSpec()` 失败 | 打印错误和 `Aborted. No files were changed.` |
| rebuilt main spec validation 失败 | 写入前中止，change 不移动。 |
| archive target 已存在 | 抛错，不覆盖。 |

这些都是“不能安全完成 archive”的状态。

## warning confirm：可以继续，但需要用户确认

这些不是 hard stop：

| 条件 | CLI 行为 |
|---|---|
| proposal validation 不通过 | 打印 warning，不阻止。 |
| tasks 有未完成 checkbox | 询问是否继续；`--yes` 直接继续并打印 warning。 |
| spec updates 存在 | 询问是否更新；用户可以拒绝。 |
| `--no-validate` | 没有 `--yes` 时询问是否确认跳过 validation。 |

这体现了 archive 的现实取舍：它鼓励完整性，但允许用户显式做治理上的例外。

## 缺 tasks.md

CLI archive 中，缺 `tasks.md` 不阻塞。

`getTaskProgressForChange()` 读不到文件时返回：

```text
total = 0
completed = 0
```

随后显示：

```text
Task status: No tasks
```

这和 apply instructions 的规则不同。apply 阶段如果 schema 配置了 `tracks: tasks.md`，缺 tracking file 会 blocked；archive CLI 则把 tasks 视为 warning/progress 信息。

## 缺 specs 或没有 delta specs

如果 change 没有：

```text
specs/<capability>/spec.md
```

`findSpecUpdates()` 返回空数组。CLI 不更新主 specs，但仍可 archive。

这适用于某些 infra、tooling、docs-only change，也解释了为什么 CLI 提供 `--skip-specs`。

## `--skip-specs`

`--skip-specs` 会跳过 spec update operations：

```bash
openspec archive <name> --skip-specs
```

结果：

- 主 `openspec/specs/` 不变。
- change 仍会移动到 archive。
- delta specs 如果存在，只保留在 archived change 里。

这不是失败，而是用户显式选择“只收起 change，不合并 specs”。

## `--no-validate`

`--no-validate` 会跳过：

- proposal validation。
- delta spec validation。
- rebuilt main spec validation。

没有 `--yes` 时，CLI 会先确认：

```text
WARNING: Skipping validation may archive invalid specs. Continue?
```

这很危险，因为 archive 的意义是把 change 吸收到 formal baseline。跳过 validation 可能把结构不合法的 specs 写进去。

## spec merge 的原子性边界

在 build 阶段，CLI 会避免部分写入：

1. 先对所有 updates 做 `buildUpdatedSpec()`。
2. 只要任何一个 build 失败，就提示 `Aborted. No files were changed.`。
3. 这时确实还没有进入写入循环。

随后进入 prepared 列表循环，每个 spec 都是：

```text
validateSpecContent(current rebuilt)
writeUpdatedSpec(current rebuilt)
```

所以如果第一个 spec 已经写入，第二个 spec 才验证失败或写入失败，CLI 没有跨 spec transaction 回滚。已经写过的文件不会自动恢复。

这是文件系统操作的风险边界，和 validation failure 不是一回事。

## move 阶段风险

移动 change 时：

```text
fs.rename()
fallback: copyDirRecursive() + fs.rm(src)
```

如果 `rename` 成功，通常是原子移动。

如果 fallback 到 copy + remove，中途 I/O 异常可能留下部分复制结果或源目录仍在。CLI 没有更高层事务机制。

## archived 后的风险

archive 后没有内置 unarchive。

如果发现主 specs 合并错了：

- 手工修正 `openspec/specs/<capability>/spec.md`。
- 或从 archived change 中参考 delta artifacts 再重建。
- 不能依赖 CLI 自动回滚。

所以 archive 前建议至少确认：

```text
tasks 完成
tests / validation 已跑
delta specs 与 main specs 同步语义清楚
archive 没有跳过关键 validation
```

## 参考来源

源码引用基于 commit `487ea92`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/archive.ts` | hard stop、warnings、skip specs、skip validation、move fallback |
| `src/core/specs-apply.ts` | prepare before write、merge failure behavior |
| `src/utils/task-progress.ts` | missing tasks and checkbox progress |
| `src/core/templates/workflows/archive-change.ts` | OPSX  |
| `test/core/archive.test.ts` | missing tasks/specs、skip specs、declined updates、archive exists、interactive confirmation |
