# 问题

`/opsx:propose` 跑完了，`tasks.md` 存在了，mechanical apply gate 通过了。但 artifacts 真的能拿来实施吗？

更具体地说：

- proposal 里写的 scope 和真实代码对得上吗？
- specs 里的 scenario 真的可测试吗，还是漏了边界情况？
- design 的技术决策在真实代码约束下还成立吗？
- tasks 拆得够具体吗，还是有一堆 "Implement X" 这种没法执行的条目？
- 如果有 gap——怎么发现、怎么修、修完怎么确认？

换句话说：**propose 产出的 artifacts 和 "真的可以开始写代码" 之间，最常见的做法是什么？**

# 背景

前面四个 FAQ 已经把四条核心命令的机制讲清楚了：

- `03_explore-to-propose-change/` — Explore 如何判断是否 propose
- `04_propose-to-apply-ready/` — Propose 如何生成 artifacts 并走到 mechanical apply-ready
- `05_apply-ready-to-archive-ready/` — Apply 如何实施
- `06_archive-ready-to-archived/` — Archive 如何收束

但它们之间有一个在实践中极其常见的动作没有被单独拎出来：**propose 完成 → 用 Explore 回头审视 artifacts → 发现 gap → 更新 artifacts → 再审视 → 直到真的可以 apply**。

这个循环不是四条核心命令中的任何一条。它是 Explore 和 Propose 之间的迭代：Explore 提供智力审视，Propose（或 continue）提供 artifact 更新机制。

本问题专门回答这个迭代循环里到底发生了什么。
