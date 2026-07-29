# 问题

OpenSpec 的 schema 系统能不能脱离传统软件开发的 `spec-driven`，用来**开发 AI Agent 本身**——产出 persona、skills、slash-commands、tools、evals、CLI 这组一个智能体 harness 要消费的组件，而不是代码？

如果可以，一个 `agent-dev-driven` schema 长什么样？和 `spec-driven` 是什么关系？需要改 OpenSpec 源码吗？

# 背景

已有过一个 4-artifact 雏形（persona → skills → {scripts, tests}），证明了 OpenSpec 可以管理 agent 开发。但它的问题是自建了一套 artifact 名和 DAG，和 spec-driven 不通用——每个用过 spec-driven 的人都要重新学。

本 FAQ 的设计选择：**不发明新 artifact。** agent-dev-driven 和 spec-driven 使用完全相同的 4-artifact 框架（proposal → specs → design → tasks → apply），只改每个 artifact 的 instruction 和 template **内容**。proposal 和 specs 不改——和 spec-driven 同构。design 加重（Skills/Commands/Tools/Evals/CLI 段，agent 的完整实现方案），tasks 跟踪的是 agent 组件构建而非代码实现。agent 的身份、硬约束、system prompt 是项目全局配置——放 `openspec/config.yaml` 的 `context`，不在每个 proposal 里重复；若是 Apply/Archive 的稳定项目步骤，v1.7.0 应写 `operations.apply/archive.guidance`，而不是伪造 artifact rule。

# 答案摘要

和 spec-driven 同框架——4 个 artifact + apply，不改 OpenSpec 源码。spec-driven 的框架是领域无关的，对软件研发和 agent 开发同样适用。

完整 schema-package 和模板在 [`schema-package/`](schema-package/)，设计解释在 [`answer.md`](answer.md)，schema 扩展实操指南在 [`answer-add-schema.md`](answer-add-schema.md)。
