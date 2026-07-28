# 问题：OpenSpec 上游项目的 Roadmap 和主要问题是什么？

## 背景

我们在 `_digested/` 和 `_faq_on_digested/` 里已经深度消化了 OpenSpec 的内部机制——从 explore→propose→apply→archive 的完整生命周期、schema 系统、CLI 三层架构、spec 漂移问题等等。但这些研究全部基于**当前已发布的代码和文档**。

我们的视角缺少一个关键维度：**上游项目的走向和已知问题**。具体说：

1. **Roadmap** — 上游 Fission-AI 团队正在开发什么？Context Store / Initiatives / Workspace 这些概念是什么？版本路线图是怎么规划的？
2. **最主要的问题** — 社区实际使用中遇到的最严重 bug、架构层面的设计限制、迁移/升级的 pain points 是什么？
3. **社区最常问什么** — 除了官方 FAQ，真实用户在 Discord/GitHub Issues 里反复问的问题是什么？

## 为什么要探究这个

- 我们的 `_digested/` 消化材料是基于当前版本的静态分析。不了解上游走向，我们就不知道哪些机制是"稳定核心"、哪些是"正在剧烈演变的表面 API"。
- 我们在 `_faq_on_digested/11_keep-specs-aligned/` 里已经识别了 spec 漂移问题，但上游是否有计划解决？有没有相关的 issue/discussion？
- `_faq_on_digested/08_config-yaml-growth/` 问的是 config 怎么配——但上游 v1.0.0 大版本迁移有没有造成更大的 config 断裂？
- 我们写了大量关于 explore/propose/apply/archive 的研究，但上游是否在改变这四个动词的语义？workspace/initiative 概念是否会让现有模型过时？

## 探究范围

- 来源：GitHub Issues、Discussions、官方文档（ROADMAP.md, workspace-roadmap.md, faq.md, migration-guide.md）、Release Notes
- 时间范围：重点 v1.0.0（OPSX 迁移）至今，向前看 1-2 个版本
- 不追求列举所有 issue，而是**归纳出模式**：哪些问题是结构性的、哪些是暂时的、哪些是设计取舍
