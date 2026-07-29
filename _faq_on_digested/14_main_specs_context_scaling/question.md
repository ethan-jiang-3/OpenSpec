# 问题：archive 后主 specs 越积越大，agent 的上下文怎么办？

`openspec archive` 会把 change 的 delta 合并进 `openspec/specs/`。长期使用后，主 specs 的 capability 数量和单个 capability 的 requirement 数都会增加。

这带来一个看似矛盾的问题：

1. 下一次 `/opsx:propose`、`/opsx:explore` 或 `/opsx:apply` 若要理解既有系统，是否必须读完所有 main specs？
2. 若把整个 `openspec/specs/` 塞进 agent context，几十个 capability 或一个很长的 spec 很快会耗尽上下文；不塞又可能漏掉已有契约、重复造 capability，或破坏跨域约束。
3. OpenSpec 现在是否已有分片、目录索引、按需读取或 token budget 的正式机制？若没有，项目应如何组织 specs 和工作流，才不会把积累的主 specs 变成 agent 根本用不起来的档案？

这里的“main specs”指整个 `openspec/specs/` 当前 capability 基线，不是 `changes/archive/` 中的历史 change。后者只在需要回答“当时为什么这样改”时才是上下文来源。

本问题特别要求区分三件事：

- 本 checkout 的实际代码（`HEAD d4f1903`，`package.json` 为 v1.5.0）；
- `_digested/` 所记录、但本 checkout 尚未合入的后续 upstream 同步快照（其中包括 nested spec discovery）；
- 2026-07-29 查询到的 upstream `main` 与公开 Issue/PR 状态。

否则很容易把“上游已实现但本地没升级”“开放提案”“当前 CLI 真正会自动注入的内容”混成一件事。
