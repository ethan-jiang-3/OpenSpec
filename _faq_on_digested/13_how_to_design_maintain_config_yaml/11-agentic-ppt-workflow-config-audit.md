---
title: "11 — Agentic PPT workflow：MD/Agent 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml"
applies_to:
  - "B1: Markdown-first / Agent-controlled Flow with deterministic JS/CLI gates"
  - "projects with distinct framework-maintenance and run-bundle-production domains"
read_when:
  - "项目由 Markdown controller / Agent 控制流程，但同时有确定性 CLI、Gate、状态和 evidence surface。"
  - "一份 config 同时承载多个工作域、长 policy 与 run-bundle 操作知识，需要先做 change classification。"
focus:
  - "将 framework-maintenance / run-bundle-production 分类写入 proposal，再按触发条件给 specs/design/tasks 路由 policy。"
  - "避免把 controller playbook、CLI protocol 和 bundle 操作说明塞进所有 planning artifacts。"
not_for:
  - "不要把本案例当作 B2 程序/Graph 控制 Flow 的模板；那类项目应读 12。"
  - "不要把 PPT 或 run-bundle 的具体术语、路径和 Gates 视为通用 config 规则。"
next_read:
  - "通用归位规则：01-design-config-yaml.md"
  - "配置不生效或 Apply 需要稳定指导：02-diagnose-maintain-config-yaml.md"
---

# 11 — Agentic PPT workflow：MD/Agent 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml`。

这个项目也属于 [`00-initial-config-baselines.md`](00-initial-config-baselines.md) 的 **B1：MD/Agent 控制 Flow，传统程序做 Gate**：Markdown controller / Agent 拥有流程、节点、路径选择和创意判断；JS/CLI 拥有解析、校验、状态、证据和结构化诊断。审计重点是让 config 只保留这张稳定 authority map，而不把 playbook、控制政策和 run-bundle 操作手册重复投放给所有 planning artifacts。

> 目的不是批评配置“写得太长”，而是识别每段信息的正确 owner、消费时机和验证方式。建议去处是设计方向，最终仍应以项目实际文件结构为准。

## Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 项目本质与控制面所有权 | 4-19 | 是项目最重要的稳定模型，但可以更短。 | `context`：保留 Markdown-first、MD/JS/human ownership 摘要。 |
| 工作域与对象边界 | 20-45 | “framework maintenance vs run-bundle production”是 proposal 需要的 change classification；详细目录/读法不需要每次注入。 | context 留双域事实；proposal rule 要求分类和记录；详细 map 放 charter/layout docs。 |
| 权威源与查找顺序 | 46-61 | 有用的 source-of-record 索引，但 full table 应按任务需求读取。 | context 留总原则 + 入口；proposal/specs/design rules 指向相关 authority docs。 |
| 技术栈与运行时铁律 | 62-77 | 技术栈是稳定背景；禁止的生产路径主要是 design/tasks 约束。 | context 仅栈/主入口；design/tasks rules 或 executable check 承担细则。 |
| CLI 失败回执 | 78-90 | 只与 CLI / controller protocol 变更相关。 | `rules.design`（条件触发）+ `cli-surface` / `node-specification` spec；不放 context。 |
| Gates、Agent control、simple reliable control | 91-126 | 是重要但条件化的政策；当前对所有 artifact 全量投放会淹没普通 PPT change。 | proposal/specs/design rules 加“涉及 X 时读 Y”的短指针；完整政策留在 `openspec/policies/`。 |
| Capability 注册表和完整 capability 表 | 127-173 | 它是 proposal/specs 做归属判断的索引，不是所有 stages 的背景。 | proposal/specs rules 指向 `openspec/specs/`；由实际 main specs 作为权威；完整表可移至 capability index。 |
| Workflow 术语、生产语义、refresh paths | 174-200 | 专属 run-bundle production / implementation 的知识。 | proposal 先分类；run-bundle design/tasks guidance pack；不是 context。 |
| Agent 入口与 OpenSpec 开发循环 | 201-212 | 这是行动 playbook。尤其 Apply/Explore 不自动读 context，放在这里不能保证实际执行者看见。 | `AGENTS.md` / playbook / schema `apply.instruction`；change 的 tasks 写明实际步骤。 |

## Rules 归位

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（215-247） | 非常清楚地维护 proposal 的信息密度、capability 契约、change domain 和 control owner。 | 八条长规则承载了三种 change class 和三条 policy；建议变为基础 rule + 条件化 policy-pointer，分类结果写入 proposal。 |
| `specs`（248-277） | 对 delta、owner、archive safety、gate semantics 的要求具体。 | 能力名和 canonical vocabulary 不应仅靠 context；实际 main specs / glossary 应为 source。只让有相关风险的 spec 加载对应 policy。 |
| `design`（278-303） | owner、验证策略、migration、gate/recovery 都是 design 的正确职责。 | 很多条只在 framework control path 变化时适用；把 trigger 前置，避免常规视觉/文案改动承受不相关的控制语言。 |
| `tasks`（304-325） | 覆盖变化、依赖顺序、tests、gate-sensitive tasks，有可执行性。 | 仍要注意 Apply 不会加载这些 config rules；任务必须在生成时具体化，强制部分需有 tests/checks。 |

## 可行的渐进收缩目标

1. `context` 只保留“项目是何物、两种工作域、Flow/Gate owner、去哪里找权威”的短导航。
2. 将 gate/control/quality 三套长政策改成 canonical 文档；在 proposal/specs/design 中仅留下有触发条件的阅读与留痕要求。
3. 把 framework-maintenance / run-bundle-production 分类作为 proposal 的显式输出，而不是让每个后续 artifact 从全局 context 自行猜测。
4. run-bundle 的真实执行入口和 Gate 规则放入 playbook / `AGENTS.md` / schema `apply.instruction`；不要期待 config 在实际 Apply 中出现。
