# 问题

OpenSpec 的 schema 系统能不能用来做**需求工程**——产出物不是代码，也不是文章，而是一份经过反复沟通打磨成型的需求规格文档（PRD），递交给开发团队去实现？

如果可以，一个 `requirement-driven` schema 长什么样？和 `spec-driven`、`article-driven` 是什么关系？

# 背景

阅读 `_digested/` 中关于 schema、change/apply/archive 的材料，以及已有的 `agent-dev-driven`（agent 开发）和 `article-driven`（内容生产）两个社区 schema 之后，产生的一个追问：

- `spec-driven` 的产出物是代码实现（delta specs → 源码文件）
- `agent-dev-driven` 的产出物是 agent 组件（skills、commands、tools）
- `article-driven` 的产出物是发布文章（标题、正文、SEO 元数据）

这三种本质上都是"一个人+AI 可以独立完成的产出"。但需求工程不一样——**需求不是一个人闭门造出来的，是跟利益相关者反复聊出来的**。这个"反复沟通、不断打磨"的过程能不能建模到 OpenSpec 的 artifact DAG 里？

# 答案摘要

可以。本目录就是概念验证：定义了一套 `requirement-driven` schema，把需求工程流程建模为 6 个 artifact 的 DAG：

- **6 个 artifact**：discovery → needs → spec → review → signoff（+ tasks 追踪全流程）
- **核心动态**：跟利益相关者反复沟通、不断打磨需求、直到成型后递交给开发团队
- **兼容策略**：保留 `tasks.md` 文件名、不改 OpenSpec 源码，和 `agent-dev-driven`、`article-driven` 一样的零侵入方式

详见 [`answer.md`](answer.md)（综合回答）和 [`schema-package/`](schema-package/)（schema 定义 + 6 个阶段模板）。
