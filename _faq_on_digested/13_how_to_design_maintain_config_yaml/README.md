# 13 — 如何设计和维护 config.yaml

本目录是一套最终的配置决策与诊断指南：如何让不同阶段得到准确、可追溯的上下文与指导，而不是将所有项目知识堆入全局 `context`。

通用阅读顺序：

1. [`question.md`](question.md)：问题、背景与结论摘要。
2. [`answer.md`](answer.md)：直接回答和最短行动路线。
3. [`00-initial-config-baselines.md`](00-initial-config-baselines.md)：先按下游运行时的 Flow owner 选择传统确定性、MD/Agent 控制 Flow 或程序/Graph 控制 Flow 的初始基线。
4. [`01-design-config-yaml.md`](01-design-config-yaml.md)：信息归位、project profile、rules 与 schema 升级的设计手册。
5. [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)：生效 root、schema、instructions、迁移和验证的诊断/维护手册。
6. [`sources.md`](sources.md)：源码、消化文档和项目特定样例的证据索引。

三篇通用指南读完后，如需观察归位方法如何落到具体项目，再进入 [`project-cases/README.md`](project-cases/README.md)。其中 10、11、12 分别审计 Deep Research Tool、Agentic PPT workflow 和 DeerFlow Deep Research；它们不属于通用阅读主线，也不是可以套到其他项目的配置模板。

## 先用 frontmatter 路由

三篇通用指南（00、01、02）和三篇项目审计（10、11、12）的开头都使用同一组决策型 frontmatter；先读它，再决定是否进入正文：

- `document_kind`：它是初始基线、设计手册、诊断手册还是项目审计。
- `applies_to`：它覆盖的 runtime model 或项目条件。
- `read_when`：何时值得打开这篇。
- `focus`：进入正文后优先寻找的结论。
- `not_for`：不应把这篇拿来解决的事情；对项目审计，还会列出不能复制到其他项目的内容。
- `next_read`：当前问题判断完后应转向的文档。

这些字段是本 FAQ 的阅读路由 metadata，不是 OpenSpec 的 `config.yaml` 字段。维护时只更新文档的适用边界、阅读重点和跳转关系；不要把正文摘要、研究历史或运行时事实再次复制进 frontmatter。案例的项目介绍、证据边界与可借鉴方法统一由 [`project-cases/README.md`](project-cases/README.md) 导航。

内置 `spec-driven` 的源码层上下文路由说明在 [`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)；root/store 等通用证据由 [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md) 与 [`sources.md`](sources.md) 索引。运行时模型术语见 [`../../CONTEXT.md`](../../CONTEXT.md)。本目录不保留已经完成的研究日志或计划；新证据应直接更新相应的最终指导与来源索引。

核心结论：`config.yaml` 是“项目 profile + 单 artifact 指导”的提示层，不是工作流状态机、change 记录、apply playbook 或 deterministic enforcement 的替代品。
