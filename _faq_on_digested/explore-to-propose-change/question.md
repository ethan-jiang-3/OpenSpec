# 问题

Explore 到底是怎么一步步 figure out 是否应该 propose change 的？

更具体地说：用户通常只会给一个意图、想法、痛点或方向，例如“这个 auth 系统有点乱”“我想做实时协作”“这里是不是应该重构一下”。这些话本身还不足以决定 OpenSpec change 的边界。

真正的问题是：

- Explore 在什么时候只是继续探索？
- 什么时候应该进入 propose？
- 什么时候应该更新已有 change，而不是新建 change？
- 什么时候应该拆成多个 changes？
- 什么时候根本不应该创建 OpenSpec change？

# 背景

前面的 `_digested/` 已经消化过 `explore` 和 `propose` 的机制：`explore` 是 stance，不是固定 workflow；`propose` 是创建 change 并生成 artifacts 的 workflow。

但这里还缺一个更精确的桥接解释：**从用户意图到 change 边界，中间到底发生了什么判断？**

这个判断不能只来自用户一句话，也不能由 OpenSpec CLI 自动算出来。它必须综合：

- 用户表达的目标、问题和约束
- 当前 OpenSpec active changes
- 既有 `openspec/specs/` 能力基线
- 既有 change artifacts
- 真实项目代码、架构、模块边界和测试形态

需要把这个过程讲清楚。

还有一个极端但常见的首次使用场景：这是一个已经存在的项目，但第一次引入 OpenSpec，`openspec list --json` 没有 active changes，`openspec/specs/` 也是空的。此时不能说“没有 specs 就没法判断”，也不能直接把用户意图硬变成 proposal；Explore 必须先从真实代码、README/docs、测试和现有行为里反推出事实 baseline，再决定是否要 formalize 成 change。
