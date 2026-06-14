# 问题

Explore 已经把一个想法收敛成了明确 change，接下来触发 propose。这个 propose 动作内部到底发生什么？

更具体地说：

- change name 或 description 如何变成一个真实的 change 目录？
- `.openspec.yaml` 和 schema 是怎么决定后续 artifact 顺序的？
- agent 如何知道先写 proposal，再写 specs/design，最后写 tasks？
- `openspec instructions <artifact> --json` 到底给了 agent 什么？
- 什么情况下算 propose 完整完成？
- 完成后为什么就可以进入 `/opsx:apply`？

# 背景

`explore-to-propose-change/` 已经回答了“什么时候应该 propose 什么 change”。这个问题从下一秒开始：**已经决定 propose 了，怎么从一个 change name 走到 apply-ready？**

这里不讨论是否应该 propose，也不实施代码。终点是：

```text
schema.apply.requires 中要求的 artifacts 都已完成
openspec instructions apply --change "<name>" --json 能返回可执行上下文
agent 可以开始 /opsx:apply
```

需要把 skill prompt、CLI、schema、artifact DAG、文件状态和 agent 写文件之间的配合讲完整。
