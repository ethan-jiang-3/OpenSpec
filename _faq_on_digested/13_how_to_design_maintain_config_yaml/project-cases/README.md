# 项目特定案例索引

本目录保存四份**项目特定审计**。它们不是 `config.yaml` 模板，也不是对同类项目自动成立的建议。每份结论只用于解释对应项目为什么需要那样归位；审计其他项目时，必须重新阅读该项目的 schema、runtime owner、policy、代码和实际消费路径。

先读父目录的通用主线：

1. [`00-initial-config-baselines.md`](../00-initial-config-baselines.md)：判断下游运行时的 Flow owner，并选择初始基线。
2. [`01-design-config-yaml.md`](../01-design-config-yaml.md)：按 consumer、阶段、证据和强制方式归位信息。
3. [`02-diagnose-maintain-config-yaml.md`](../02-diagnose-maintain-config-yaml.md)：按生效 root、schema 和 instructions 诊断配置。

## 四个项目分别是什么

| 案例 | 项目 | 为什么审计它 |
|---|---|---|
| [`10-deep-research-tool-config-audit.md`](10-deep-research-tool-config-audit.md) | **Deep Research Tool**：把宽泛研究问题转化为证据支撑、多波次、带 Gate 报告的 Agentic research framework。Agent 与 Markdown flow 负责研究和语义决策，JavaScript Engine 负责 schema、状态、receipt 和确定性 Gate。 | 检查该项目的 runtime/playbook、requirement registry 与 verification routing 是否被过早放进所有 planning artifacts。 |
| [`11-agentic-ppt-workflow-config-audit.md`](11-agentic-ppt-workflow-config-audit.md) | **Agentic PPT workflow**：AI 演示文稿生产系统。Agent 与 Markdown controller 负责内容、视觉判断和流程推进，JavaScript/CLI 负责解析、校验、状态、证据和 Gate；项目同时有 framework maintenance 与 run-bundle production 两类工作域。 | 检查该项目是否先在 proposal 分类两个工作域，再按触发条件把 policy 路由到对应 artifact。 |
| [`12-deerflow-deep-research-config-audit.md`](12-deerflow-deep-research-config-audit.md) | **DeerFlow Deep Research**：基于 DeerFlow 2.1 的下游深度研究产品。`agent/` 是主要实现，`backend/` 与 `frontend/` 是上游 mirror；嵌套 Python `StateGraph`、typed state 和 node contract 拥有运行时控制边界。 | 检查该项目是否把 Flow、state、route、permission 和 recovery 的权威留在 executable graph/runtime，而不是交给 config 或 prompt。 |
| [`13-business-simulation-config-audit.md`](13-business-simulation-config-audit.md) | **Agentic Business Simulation**：商业决策模拟 framework。Agent 读取 Markdown charter/ops/playbook 与 H/A/T collaboration node 推进工作；Human H node 保留业务决策；Node checker 只提供只读诊断。 | 检查四份 maintenance policy 是否保留明确引用，同时避免把 runtime graph、Gate procedure、layout、capability planning 或 simulation 操作手册广播进所有 planning artifacts。 |

## 可以借鉴什么

- 先确认谁消费一条信息、何时消费、应在哪个 artifact 留证据，以及是否必须由机器强制。
- 先确认 Flow、Gate、state、policy 与 human approval 的真实 owner，再决定信息进入 `context`、`rules`、change artifacts、schema/workflow 或 checker。
- 用目标项目的 rendered instructions、runtime source 和 deterministic evidence 复核归位结果。

## 不能直接套用什么

不能复制这些项目的名称、目录、capability、policy、Gate、命令、验证流程、state owner、工具权限或结论。案例中的 B1/B2 判定也只描述对应项目，不能因为另一个项目技术栈相似就沿用；必须重新验证它真正的 Flow owner。

各案例 frontmatter 中的 `case_source` 是本机上用于定位原始配置的绝对路径。它不是可移植依赖，在其他 workspace 中可能不存在，也不能作为泛化结论的依据。
