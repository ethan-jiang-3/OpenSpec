---
title: "10 — Deep Research Tool：MD/Agent 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml"
applies_to:
  - "B1: MD/Agent-controlled Flow with deterministic gates"
read_when:
  - "项目由 Markdown / Runtime Agent 选择流程、语义路由与恢复，传统程序只做 Gate、状态、receipt 或诊断。"
  - "需要审计一份 B1 配置中哪些 runtime/playbook 细节被过早注入所有 planning artifacts。"
focus:
  - "把 Flow/Gate authority profile 留在 context，把条件化 policy、verification 与 registry 路由到正确 artifact 或 deterministic owner。"
  - "用 Change Context Card 让下游 artifacts 继承本次分类，而不是从全局 context 反复猜测。"
not_for:
  - "不要把本案例当作 B2 程序/Graph 控制 Flow 的模板；那类项目应读 12。"
  - "不要复制此项目的 capability、bundle、实验或验证细节到无关项目。"
next_read:
  - "通用归位规则：01-design-config-yaml.md"
  - "B2 程序/Graph 对照案例：12-deerflow-deep-research-config-audit.md"
---

# 10 — Deep Research Tool：MD/Agent 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml`。

这个项目属于 [`00-initial-config-baselines.md`](00-initial-config-baselines.md) 的 **B1：MD/Agent 控制 Flow，传统程序做 Gate**。配置中已经准确表达了 Agent 负责搜索、阅读、写作、综合、决策，Engine 负责 schema、状态机、receipt 和 Gate 校验；问题不在这套模型本身，而在过多 runtime/playbook 细节被重复注入每个 planning artifact。

> 目的不是批评配置“写得太长”，而是识别每段信息的正确 owner、消费时机和验证方式。建议去处是设计方向，最终仍应以项目实际文件结构为准。

## Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 项目一句话、Agent / Engine / 文件的基本分工 | 4-10 | 跨 artifact 的稳定理解，值得保留；当前细节可压缩。 | `context`，保留为 5-8 行 authority profile。 |
| 核心原则与 JS/MD 边界 | 12-21、30-44 | “谁拥有决策”是稳定背景；具体错误处理、env/routing 规则不是所有 artifact 都需要。 | context 留 ownership 摘要；详细边界移至 charter；proposal/design rules 用条件化指针。 |
| 技术栈及允许依赖 | 23-28 | 对 design/tasks 有强影响，对 proposal/specs 价值较低。 | `rules.design` / `rules.tasks`；context 只留一句技术栈摘要。 |
| Evolution Directions | 51-60 | 明确标为 proposal/design 评审顺序，却在所有 artifact 注入，是典型作用域错配。 | `rules.proposal`、`rules.design`；完整正文留在现有 guidelines。 |
| 命名规范 | 62-65 | UI 语言/路径语言可能全局；capability prefix 与 bundle 命名是条件性规则。 | context 只留全局语言约定；capability 命名进 proposal/specs；bundle 命名进 design/tasks 或 runtime playbook。 |
| Requirement Traceability | 67-77 | 每条要求有不同消费者：分配 ID、写 spec header、写实现标记、收尾检查。 | proposal / specs / tasks 各自短 rule；registry 与 checks 保持 canonical；可执行检查继续承担验证。 |
| Governance 工具与 registry 组织细则 | 79-91 | 详细的登记格式不是 proposal、design、tasks 都需要。 | `rules.specs` / `rules.tasks` 的指针；正文只留 registry 文档/validator。 |
| Verification routing | 93-109 | 是 change-level verification policy；“本次计划”应该进入 change 的 `verification-plan.yaml` 和 tasks。 | proposal 触发创建计划；tasks 生成具体动作；分类定义留 policy/checker，不进 context。 |
| 实验体系 | 111-128 | 主要面向 experiment/run 的设计与实施，不是所有 spec artifact 的背景。 | policy/runbook；相关 design/tasks rule 指针；必要硬约束交给 supervisor/engine。 |
| 根目录与 framework/bundle 详细地图 | 130-165 | 有少量全局导向价值，但完整树是静态索引，重复注入性价比低。 | context 保留 3-5 条 root/ownership 摘要；完整地图放 README/charter。 |

## Rules 归位

现有规则已经比 context 更接近正确的注入位置。目标是压缩重复内容，并加强“触发 -> 动作 -> 留痕”，不是把它们再次全部搬走。

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（168-177） | 能明确语言、source、capability、版本等长期约束。 | 多条与 context 的 Evolution Directions 重复；不同 change 类型适用性不同。保留摘要和明确路径，详细政策转为短指针。 |
| `design`（178-183） | 技术栈、状态机、source-of-record 非常适合 design。 | “只能用依赖”应是项目硬约束的同时有 package/test 支撑；不要只靠 rule。 |
| `tasks`（184-200） | done condition、依赖排序、requirement ID、收尾验证都能转化为可读任务。 | Apply 本身不重新注入 config；必须让生成出的 `tasks.md` 写出收尾验证，且由 CI/checker 复核。 |
| `specs`（201-227） | Capability / requirement 的约束有明确 artifact owner。 | 主 spec 结构与 ID 格式最好由现有 governance checker 保障；长的边界测试可从 inline rule 移为 policy 指针。 |

## 可行的渐进收缩目标

1. 将 `context` 缩成“项目 profile + Flow/Gate authority + 最高优先级”摘要，不复制流程、目录树、检查器细节。
2. 每个 artifact 保留 3-6 条真正稳定的 rule；一条 rule 应能回答“何时触发、做什么、在哪留下证据”。
3. 用 proposal 的 Change Context Card 记录是否涉及 framework、version、experiment、verification plan；下游 artifacts 从 proposal 读这一结论。
4. 将不可协商的 registry / spec / verification 规则继续放入 checker；真正的 Agent-flow 顺序留在 Markdown controller/playbook，而非 config。
