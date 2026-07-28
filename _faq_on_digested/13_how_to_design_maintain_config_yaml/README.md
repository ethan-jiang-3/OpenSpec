# 13 — 如何设计和维护 config.yaml

本目录是一套最终的配置决策与诊断指南：如何让不同阶段得到准确、可追溯的上下文与指导，而不是将所有项目知识堆入全局 `context`。

阅读顺序：

1. [`question.md`](question.md)：问题、背景与结论摘要。
2. [`answer.md`](answer.md)：直接回答和最短行动路线。
3. [`00-initial-config-baselines.md`](00-initial-config-baselines.md)：先按下游运行时的 Flow owner 选择传统确定性、MD/Agent 控制 Flow 或程序/Graph 控制 Flow 的初始基线。
4. [`01-design-config-yaml.md`](01-design-config-yaml.md)：信息归位、project profile、rules 与 schema 升级的设计手册。
5. [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)：生效 root、schema、instructions、迁移和验证的诊断/维护手册。
6. [`10-deep-research-tool-config-audit.md`](10-deep-research-tool-config-audit.md)：Deep Research Tool 的 MD/Agent 控制 Flow 审计案例。
7. [`11-agentic-ppt-workflow-config-audit.md`](11-agentic-ppt-workflow-config-audit.md)：Agentic PPT workflow 的 MD/Agent 控制 Flow 审计案例。
8. [`12-deerflow-deep-research-config-audit.md`](12-deerflow-deep-research-config-audit.md)：DeerFlow Deep Research 的程序/Graph 控制 Flow 审计案例。
9. [`sources.md`](sources.md)：源码、消化文档和样例的证据索引。

## 先用 frontmatter 路由

六篇具体指导的开头都使用同一组决策型 frontmatter；先读它，再决定是否进入正文：

- `document_kind`：它是初始基线、设计手册、诊断手册还是项目审计。
- `applies_to`：它覆盖的 runtime model 或项目条件。
- `read_when`：何时值得打开这篇。
- `focus`：进入正文后优先寻找的结论。
- `not_for`：不应把这篇拿来解决的事情，或不能从案例复制的内容。
- `next_read`：当前问题判断完后应转向的文档。

这些字段是本 FAQ 的阅读路由 metadata，不是 OpenSpec 的 `config.yaml` 字段。维护时只更新文档的适用边界、阅读重点和跳转关系；不要把正文摘要、研究历史或运行时事实再次复制进 frontmatter。

源码层的完整上下文路由说明在 [`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)。运行时模型术语见 [`../../CONTEXT.md`](../../CONTEXT.md)。本目录不保留已经完成的研究日志或计划；新证据应直接更新相应的最终指导与来源索引。

核心结论：`config.yaml` 是“项目 profile + 单 artifact 指导”的提示层，不是工作流状态机、change 记录、apply playbook 或 deterministic enforcement 的替代品。
