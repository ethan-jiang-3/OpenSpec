# 问题

Implementation 已经完成，`tasks.md` 里的 checkbox 也都完成了。接下来运行 archive 时，OpenSpec 到底怎么把一个 active change 收束成正式 baseline？

更具体地说：

- `openspec archive` 如何选择 change？
- archive 前会验证什么？哪些验证会阻塞，哪些只是 warning？
- completed tasks 在 archive 里还会不会被检查？
- change 里的 delta specs 怎么合并到主 `openspec/specs/`？
- `ADDED`、`MODIFIED`、`REMOVED`、`RENAMED` 的合并顺序为什么重要？
- 什么情况下会跳过 spec updates，或者 archive 了但 specs 没有更新？
- `/opsx:archive` 为什么看起来会先做 status、sync assessment 和 workspace guard？
- 最终 archived 的文件系统状态是什么？

# 背景

`apply-ready-to-archive-ready/` 已经回答了：`/opsx:apply` 如何读取 planning artifacts、实施 pending tasks、更新 checkbox，并走到 archive-ready。

这个问题从下一步开始：**implementation 已经存在，change 要退出 active workflow，正式进入 archived 状态。**

这里的边界是：

```text
起点：implementation 已完成，通常 tasks.md 全部 - [x]
过程：archive 验证 change、合并 delta specs、移动 change 目录
终点：主 openspec/specs/ 成为新的 baseline，change 进入 openspec/changes/archive/
```

本 FAQ 的主视角是 CLI 主线：`openspec archive` / `ArchiveCommand.execute()`。`/opsx:archive` 是相关但不同的 agent 模板路径，会在单独答案里解释。
