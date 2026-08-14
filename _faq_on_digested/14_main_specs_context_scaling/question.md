# 问题：archive 后主 specs 越积越大，agent 的上下文怎么办？

`openspec archive` 会把 change 的 delta 合并进 `openspec/specs/`。长期使用后，主 specs 的 capability 数量和单个 capability 的 requirement 数都会增加。

这带来一个看似矛盾的问题：

1. 下一次 `/opsx:propose`、`/opsx:explore` 或 `/opsx:apply` 若要理解既有系统，是否必须读完所有 main specs？
2. 若把整个 `openspec/specs/` 塞进 agent context，几十个 capability 或一个很长的 spec 很快会耗尽上下文；不塞又可能漏掉已有契约、重复造 capability，或破坏跨域约束。
3. OpenSpec 现在是否已有分片、目录索引、按需读取或 token budget 的正式机制？若没有，项目应如何组织 specs 和工作流，才不会把积累的主 specs 变成 agent 根本用不起来的档案？

这里的“main specs”指整个 `openspec/specs/` 当前 capability 基线，不是 `changes/archive/` 中的历史 change。后者只在需要回答“当时为什么这样改”时才是上下文来源。

本文以 **OpenSpec v1.9.0** 为唯一的当前行为基线（release tag `v1.9.0` = `2826b88`）。2026-08-15 已核验本 checkout 的源码合入 upstream 至 v1.9.0。所有“现在是否支持”“当前 CLI 会做什么”的结论都以这个正式发布版为准；v1.7.0 / v1.8.0 的相应结论（nested path 可用、无自动 retrieval）在 v1.9.0 不变。PATH 中的全局 `openspec` 是独立安装，需单独升级到 v1.9.0 后才与本 FAQ 对齐。

源码 checkout 与全局 npm CLI 是两条独立的更新路径。较早版本何时缺少某项能力只保留在同步变更史中，不参与本 FAQ 的当前决策。
