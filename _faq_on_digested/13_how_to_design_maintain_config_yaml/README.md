# 13 — 如何设计和维护 config.yaml

本目录围绕一个问题组织：如何让不同阶段得到准确、可追溯的上下文与指导，而不是将所有项目知识堆入全局 `context`。

阅读顺序：

1. [`question.md`](question.md)：问题、背景与结论摘要。
2. [`answer.md`](answer.md)：直接回答和最短行动路线。
3. [`00-research-log.md`](00-research-log.md)：持续更新的机制发现与待验证问题。
4. [`01-placement-audit.md`](01-placement-audit.md)：两个真实 config 的逐块归位审计。
5. [`02-design-maintain-guide.md`](02-design-maintain-guide.md)：当前可执行的设计和维护指南。
6. [`03-deep-dive-plan.md`](03-deep-dive-plan.md)：如何继续从 `internal-spec-driven` 深挖并演进资料/能力。
7. [`sources.md`](sources.md)：源码、消化文档和样例的证据索引。

核心结论：`config.yaml` 是“项目 profile + 单 artifact 指导”的提示层，不是工作流状态机、change 记录、apply playbook 或 deterministic enforcement 的替代品。
