# 问题

OpenSpec 的 schema 系统能不能脱离传统软件开发的 `spec-driven`，用来**开发 AI Agent 本身**——产出 charter（授权与护栏）、skills（可被 harness 自动发现的 MD 能力单元）、slash-commands（MD 格式）、tools（工具/运行时契约）、evals（行为测试用例）、CLI（命令行界面/状态 API），即一个智能体 harness 要消费的那组组件，而不是代码？

如果可以，一个 `agent-dev-driven` schema 长什么样？需要避开哪些坑？和已有的 `spec-driven`、`article-driven` 是什么关系？

# 背景

`_digested/schema/07-超越-spec-driven-的应用场景.md` 记录的场景 3「Agent/Skill 内容开发」给过一个 4-artifact 雏形 `agent-development`（charter → skills → {scripts, tests}）。但它缺了两样 Agent harness 真正需要的产物：**commands**（用户可调用的 slash-command，MD 格式，是 agent 的「用户界面」层）和 **cli**（agent 自己的命令行界面和状态读取 API）。本 FAQ 把它精化到 7 个 artifact，并融入 OpenSpec 作为 harness 本身的设计原则——「author once, render to N harnesses via adapters」（`_digested/mechanisms/02-tool-delivery.md:7`）。

# 答案摘要

改的是一套 schema.yaml + 7 个模板（不改一行 OpenSpec 源码）。底层仍然是同一套 artifact DAG + 模板 + CLI 解释器。

兼容策略：保持 `tracks: tasks.md`（让 `openspec change --long` 的 `[tasks X/Y]` 进度计数正常工作——`src/commands/change.ts:106,159` 硬编码了 tasks.md 作为 tracking 文件名），其余 artifact 名和 DAG 完全自由。

完整 schema-package 和模板在 [`schema-package/`](schema-package/)，解释在 [`answer.md`](answer.md)。
