---
title: "从零开始：选择 config.yaml 的初始基线"
document_kind: "initial-baseline"
applies_to:
  - "traditional-deterministic runtime"
  - "B1: MD/Agent-controlled Flow"
  - "B2: program/Graph-controlled Flow"
  - "nested control boundaries"
read_when:
  - "新建 config.yaml，或重构前还没有判断下游运行时谁拥有 Flow。"
  - "项目用了 LLM，但不确定它只是 Model-as-Input，还是 B1 / B2 混合智能运行时。"
focus:
  - "先判定 Flow owner，再选择最小 authority map 与初始 config 骨架。"
  - "区分长期 planning guidance、change artifacts、schema 与 runtime contracts 的 owner。"
not_for:
  - "不要把 B1 / B2 名称写成未实现的 config.yaml 字段。"
  - "不要用本文设计具体 graph、prompt、state schema、tool permission 或 Apply 流程。"
next_read:
  - "归位每条信息：01-design-config-yaml.md"
  - "已有配置不生效或需要迁移：02-diagnose-maintain-config-yaml.md"
---

# 从零开始：选择 `config.yaml` 的初始基线

这份指南回答的不是“如何把更多内容写进 config”，而是：**下游项目是什么运行时，哪些稳定事实值得让 planning artifacts 一开始就知道？**

它遵守 `internal-spec-driven` 的三个边界：schema 定义 workflow，artifact DAG 传递一次 change 的事实，`config.yaml` 只为 planning artifact 提供简短、稳定的项目 guidance。它不会把 runtime 控制逻辑、运行状态或 Apply 专属流程伪装成 config rule。

## 先做分类，不要先套 YAML

OpenSpec 的 Host Agent 存在于所有项目的开发过程，因而**不是**分类依据。看的是下游产品运行时：

| 问题 | 是 | 否 |
|---|---|---|
| 产品运行时是否有被授权做语义判断、内容判断或路径选择的 Agent / 模型 actor？ | 继续判断 Flow owner。 | 采用“传统确定性运行时”基线。 |
| Runtime Agent / Markdown controller 是否拥有节点顺序、语义路由和恢复策略？ | 采用 B1：MD/Agent 控制 Flow。 | 继续判断程序是否拥有 Flow。 |
| 可执行程序或 graph 是否拥有节点顺序、条件转移、状态、重试和恢复？ | 采用 B2：程序/Graph 控制 Flow。 | 先补足 runtime control contract，不能靠 config 替代。 |
| 程序是否仍拥有明确状态、权限、校验、receipt 或最终 verdict？ | 这是正常的混合系统；明确各自 owner。 | 不要用 config 假装补足缺失控制面，先设计 runtime contract。 |
| LLM 只生成摘要、分类建议或结构化候选，程序会校验并自行决定下一步？ | 采用传统基线，加“Model-as-Input”叠加规则。 | 不适用。 |

**关键结论：**“项目用了模型”不等于“项目是 Agentic runtime”。即使属于混合智能运行时，也必须继续区分**谁拥有 Flow**：MD/Agent 控制 Flow 与程序/Graph 控制 Flow 会产生不同的 source of truth、设计问题和验证证据。

## 两类项目共同遵守的底线

无论选择哪条基线，都先保持以下事实：

在默认 `spec-driven` schema 中，四个 planning artifacts 是 `proposal`、`specs`、`design` 和 `tasks`；使用自定义 schema 时，则以该 schema 的实际 artifact ID 为准。

```text
稳定、短、所有 planning artifacts 都需要的事实 -> context
一个 artifact 的长期写作/审查约束             -> rules.<artifact-id>
本次 change 的范围、决定、风险、验证事实        -> proposal / specs / design / tasks
Apply 的固定流程或新的 workflow 节点             -> schema / template / workflow skill
不可绕过的规则                                   -> checker / test / lint / CI
运行时状态、回执、授权记录                       -> runtime-owned files / records
```

默认从 `spec-driven` 开始是合理的；项目属于哪一类**本身**不是 fork schema 的理由。只有需要新的 artifact、依赖、Apply gate 或输出契约时，才把结构需求升级到 schema。

## 基线 A：传统确定性运行时

适用于 Web 服务、CLI、库、桌面程序、批处理、数据管道，以及“代码拥有业务流程和真相”的系统。`context` 的职责是让 proposal/specs/design/tasks 作者快速知道产品边界、权威来源和长期质量目标；不应成为架构手册或代码风格全集。

```yaml
schema: spec-driven

context: |-
  Product: <the user-facing product and its stable domain boundary>
  Authority: <where behavior contracts, implementation truth, and data truth live>
  Quality priorities: <two or three enduring priorities, such as compatibility or safety>
  Vocabulary: <only terms every planning artifact must use consistently>

rules:
  proposal:
    - Identify the owning capability, affected contract, non-goals, and compatibility risk.
  specs:
    - State observable behavior and scenarios in the owning capability; do not copy implementation details into the contract.
  design:
    - Record the chosen owner, integration boundary, migration or rollback consequence when one exists.
  tasks:
    - Turn each required test, migration, and acceptance proof into a verifiable task.
```

初始审查问题：

1. 这条 `context` 是否每个 planning artifact 都需要？
2. 这条 rule 是否只在它所属的 artifact 编写时有价值？
3. 这是不是一次 change 的事实，应写入 proposal/design/tasks？
4. 这是不是代码、测试或 CI 必须强制的事实？若是，不要只写 prompt。

## 基线 B：混合智能运行时

混合系统不是单一基线。二者都会把 Agent/模型与确定性组件结合起来，但**Flow 的 authoritative owner 相反**：

| 问题 | B1：MD/Agent 控制 Flow | B2：程序/Graph 控制 Flow |
|---|---|---|
| Flow 的事实源 | Markdown playbook / controller 与 Runtime Agent 的显式决策 | executable graph、state machine 或 orchestration code |
| 谁选下一节点、分支或语义恢复 | Runtime Agent / MD controller | 程序/graph 依据已声明的 transition predicate 处理 node 结果 |
| 传统程序的角色 | Gate、校验、状态/证据、receipt、结构化诊断；不得暗中编排第二条流程 | 控制顺序、状态、重试、恢复和外部动作边界，并调用智能 node |
| config 应留下的稳定边界 | controller、Gate、状态/证据和人类授权的 owner | graph、node contract、evaluator、状态和人类授权的 owner |
| 设计与验证的重点 | handoff、Gate、可读诊断、同一检查点恢复、真实 Agent flow evidence | graph transition、node I/O contract、state mutation、failure policy、deterministic graph test + model evaluation |

这些名称是本 FAQ 的**归位和诊断术语**，不是 OpenSpec 的新 YAML API。不要新增 `flow_owner:`、`agentic_mode:` 等字段并期待它们生效；仍应使用现有 `context`、`rules`、artifacts、schema 与 runtime-owned contracts。

### B1：MD/Agent 总控制 Flow，传统程序做 Gate

适用于 Markdown-first controller、playbook Agent 或 Coding Agent 执行的 Agentic workflow：Runtime Agent 负责节点顺序、语义路由、内容判断和恢复策略；传统程序只提供可验证的 Gate、状态、receipt 和诊断。传统程序不能悄悄成为第二套 controller。

```yaml
schema: spec-driven

context: |-
  Product: <the runtime outcome the system exists to produce>
  Flow authority: Markdown / Runtime Agent owns sequencing, semantic routing, and recovery choices.
  Gate authority: deterministic components own validation, state/receipt records, and bounded diagnostics.
  Human authority: <irreducible risk, approval, or meaning decisions>
  Source of truth: <the canonical playbook, runtime record, and capability specs>

rules:
  proposal:
    - When a change affects controller routing, an agent decision, a gate, state ownership, or recovery, record the authority owner, protected invariant, and required evidence.
  design:
    - State the controller handoff, gate input/output, persisted record, failure signal, and same-check recovery path; do not create a second controller in code.
  tasks:
    - Include deterministic gate coverage and the required native Agent-flow or runtime evidence for each changed control boundary.
```

详细 playbook 顺序、tool protocol、state schema、权限和 recovery 仍属于其 runtime owner；它们不会因为被写进 `context` 或 `rules` 就在 Apply 或产品运行时自动执行。

### B2：程序/Graph 控制 Flow，智能能力受限于 Node

适用于 LangGraph 一类的 code-owned orchestration：程序或 graph 决定 node 顺序、条件转移、状态、重试、恢复和外部动作边界；模型/Agent 只在被调用的 node 内完成受约束的分类、提取、生成或工具选择。模型输出可以参与分支条件，但 graph 必须拥有允许的 transition、评价 predicate 和权威状态写入；node 不能自行改写这些控制边界。

```yaml
schema: spec-driven

context: |-
  Product: <the runtime outcome the system exists to produce>
  Flow authority: <graph or program> owns transitions, state mutation, retries, recovery, and action boundaries.
  Intelligence-node authority: <the bounded semantic transformation or tool decision at each node>
  Evaluator authority: <the validator or policy that accepts, rejects, or routes node output>
  Source of truth: <the graph, state schema, node contracts, and capability specs>

rules:
  proposal:
    - When a change affects graph control flow or an intelligence node, identify the graph owner, affected node contract, state impact, and required evidence.
  specs:
    - State observable behavior and the authoritative graph/state owner; do not make prompt text a second control-flow source.
  design:
    - Record node input/output contracts, transition predicate, state mutation, evaluator, retry/fallback policy, and trace or evaluation evidence.
  tasks:
    - Include deterministic graph coverage plus the required model-evaluation evidence for each changed node contract.
```

LangGraph 只是一个代表；判定标准始终是 executable graph 是否拥有 Flow。模型输出影响分支并不自动变成 B1，只要 graph 仍定义允许的 transition、评价 predicate 和权威状态写入。若智能 node 能绕过 graph 自行选择路线，或在 contract 外写入权威状态，才需要重新划定 control boundary。

### 嵌套控制：不要强迫整个项目只选一个标签

真实系统可以让 Program-Controlled 外层 graph 调用一个 Agent-Controlled 子流程，或让 MD/Agent controller 调用内部 code-owned graph。此时按**每个 control boundary**写 owner：

```text
outer flow        -> Program/Graph 或 MD/Agent，二者择一并写明事实源
agent subflow     -> Agent/MD 的允许路线、Gate 和返回 contract
graph subflow     -> graph 的 transition、state mutation 和 node contract
cross-boundary    -> handoff input/output、authority、evidence 和 failure/recovery owner
```

config 只保留这张稳定 boundary map；每次 change 的实际嵌套、选路和风险必须写入 proposal/design/tasks，并由对应 runtime contract 和测试验证。

## 边界情况：模型只是输入

例如，传统服务调用模型生成摘要、候选标签或结构化提议，随后由程序校验格式、权限和业务条件，并由程序决定是否写入或执行。它应采用**传统确定性运行时**基线，并按需增加短 rule：

```text
当 change 修改模型输出的消费方式时，在 design 中记录输出 contract、校验者、拒绝/降级路径和可观测证据。
```

只有模型输出本身被授权决定后续路线、状态或外部动作，才升级为混合智能运行时的 authority map。这个判定避免把每个 LLM feature 都过度架构成 Agentic system。

## 建好初稿后立刻验证

1. 确认每个 `rules` key 是当前 schema 的真实 artifact ID。
2. 用一个代表性 change 检查 `openspec instructions <artifact-id> --change <change> --json`，确认 profile 和 rule 真的出现。
3. 单独检查 `openspec instructions apply --change <change> --json`；Apply 不会重新收到 `context`/`rules`。
4. 将运行时不变量交给其 owner 的 schema、validator、test 或 CI，而不是留在 config 的 prose 中。

更细的规则设计见 [`01-design-config-yaml.md`](01-design-config-yaml.md)；配置不生效、schema 切换或 `store:` 问题见 [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)。
