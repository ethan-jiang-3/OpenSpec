# 问题

OpenSpec 的 schema 系统能不能用来做**需求工程**——产出物不是代码，也不是文章，而是一份经过反复沟通打磨成型的需求规格文档（PRD），递交给开发团队去实现？

如果可以，怎么用 OpenSpec 原生概念（proposal、specs、tasks）来建模，而不是发明一套新的 artifact 名字？

# 背景

FAQ 里已有三个 schema 示例覆盖三种产出物（只有 `spec-driven` 是 OpenSpec 内置，其余两个是本 FAQ 的项目级副本）：
- `spec-driven`：代码实现（delta specs → 源码文件）——**上游内置**
- `agent-dev-driven`：agent 组件（skills、commands、tools）——和 spec-driven 同框架，只改 instruction/template 内容（见 [`../09_schema-agent-dev/`](../09_schema-agent-dev/)）
- `article-driven`：发布文章（brief → outline → research → draft → edit → publish）（见 [`../02_schema-article-driven/`](../02_schema-article-driven/)）

> **边界**：上游删除了内置的 `agent-dev-driven` 与 `requirement-driven` 两个 schema（长期未维护）。上面的 `agent-dev-driven` 和本目录的 `requirement-driven` 都是项目级自定义 schema，靠 `cp -r schema-package/` 安装，与上游是否内置无关。

这三种本质上都是"一个人+AI 可以独立完成的产出"。但需求工程不一样——**需求不是一个人闭门造出来的，是跟利益相关者反复聊出来的**。

这个问题的关键是：能不能不发明新 artifact 名，用 OpenSpec 用户已经认识的 `proposal → specs → tasks` 来承载需求工程流程，把"反复沟通、不断打磨"编码进 instruction 和 template 里？

# 答案摘要

可以。本目录就是概念验证：用 OpenSpec 原生框架承载需求工程。

- **3 个 artifact**：`proposal → specs → tasks`（和 spec-driven 同框架，去掉了 `design`——需求工程不需要"实现方案"）
- **proposal 合并了 discovery + needs**：问题域探索、利益相关者分析、原始需求草图全部在 proposal 中完成
- **specs = PRD**：FR-N 功能需求（MoSCoW）、NFR、用户故事、验收标准、Approval 章节、Developer Handoff Notes
- **迭代沟通在 apply**：审查、沟通、修改、签收、交接——所有重沟通的工作在 apply 阶段通过 tasks.md 驱动

详见 [`answer.md`](answer.md) 和 [`schema-package/`](schema-package/)。
