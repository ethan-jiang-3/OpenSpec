# 问题

`propose` 已经完整生成 artifacts，change 已经 apply-ready。接下来运行 `/opsx:apply` 时，OpenSpec 和 coding agent 到底怎么从 planning artifacts 进入真实代码实施？

更具体地说：

- `/opsx:apply` 如何选择要实施的 change？
- 为什么 apply 还要先跑 `openspec status --change "<name>" --json`？
- `openspec instructions apply --change "<name>" --json` 返回了什么？
- agent 为什么必须先读 `contextFiles`？
- pending tasks 是怎么解析出来的？
- agent 如何实施代码，并把 `tasks.md` 的 checkbox 从 `- [ ]` 改成 `- [x]`？
- 什么时候暂停，什么时候继续，什么时候算所有 tasks 完成？
- 为什么所有 tasks 完成后还不是 archive，而只是 archive-ready？

# 背景

`propose-to-apply-ready/` 已经回答了：propose 如何创建 change、生成 proposal/specs/design/tasks，并让 apply 可以开始。

这个问题从下一秒开始：**`/opsx:apply` 已经可以运行，agent 如何安全地改真实项目代码？**

这里的边界是：

```text
起点：openspec instructions apply --json 返回 state: "ready"
过程：agent 读取 contextFiles，逐个执行 pending tasks，更新 checkbox
终点：所有 checkbox tasks 完成，apply 输出完成总结并建议 archive
```

apply 是四条核心命令里唯一真正修改业务代码的阶段，所以需要把 guardrails、停止条件和状态更新机制讲清楚。
