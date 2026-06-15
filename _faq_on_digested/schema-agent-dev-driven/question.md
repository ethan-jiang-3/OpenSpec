# 问题

OpenSpec 的 schema 系统能不能脱离传统软件开发的 `spec-driven`，用来**开发 AI Agent 本身**——产出 charter（授权与护栏）、skills（可被 harness 自动发现的 MD 能力单元）、slash-commands（MD 格式）、tools（工具/运行时契约）、evals（行为测试用例）、CLI（命令行界面/状态 API），即一个智能体 harness 要消费的那组组件，而不是代码？

如果可以，一个 `agent-dev-driven` schema 长什么样？需要避开哪些坑？和已有的 `spec-driven`、`article-driven` 是什么关系？

# 背景

社区已有过一个 4-artifact 雏形（persona → skills → {scripts, tests}），证明了 OpenSpec 的 schema 系统可以用来管理 agent 开发工作流。但它缺了三样 agent harness 真正需要的东西：

- **commands**（slash-command，MD 格式）——agent 的「用户界面」层。用户敲 `/agent:do-x`，agent 把若干 skill 串成一个工作流。已有雏形只有 skills，没有用户可调用的命令入口。
- **cli**——如果目标 agent 是一个 CLI 工具，它需要自己的命令行界面（入口、子命令映射到 skills、状态读取 API），不是只有几个执行脚本。
- **接入流水线**（tasks + apply.tracks）——可勾选的集成清单和进度跟踪。已有雏形的 apply 直接 gate 在 skills/scripts/tests 上，没有 checklist 概念。

设计上借用了 OpenSpec 作为 agent harness 的核心原则：workflow 的语义定义和交付形式是解耦的。定义一次能力（capability），通过 adapter 渲染成不同形式（skill MD、slash-command MD、CLI 子命令），落到不同 harness 的约定目录和格式。「author once, render to N harnesses」。agent-dev-driven 照搬这一条：charter 和 skills 是语义源，commands、tools、cli 是交付外壳。

# 答案摘要

改的是一套 schema.yaml + 7 个模板（不改一行 OpenSpec 源码）。底层仍然是同一套 artifact DAG + 模板 + CLI 解释器。

兼容策略：保持 `tracks: tasks.md`。OpenSpec 的 change 列表 UI 把 `[tasks X/Y]` 进度计数硬编码到了 `tasks.md` 这个文件名——不管 schema 的 `apply.tracks` 设什么，列表只看文件名叫 `tasks.md` 的那个。所以 tracking 文件叫 tasks.md 最省事（artifact 名和 DAG 完全自由）。

完整 schema-package 和模板在 [`schema-package/`](schema-package/)，设计解释在 [`answer.md`](answer.md)，schema 扩展实操指南在 [`answer-add-schema.md`](answer-add-schema.md)。
