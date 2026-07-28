---
title: "13 — Agentic Business Simulation：MD/Agent 协作 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_tool_bsimulation/openspec/config.yaml"
applies_to:
  - "Agentic Business Simulation at case_source"
  - "that project's framework-maintenance and project/run-bundle runtime boundary"
read_when:
  - "正在维护或复核 case_source 对应的商业模拟框架配置。"
  - "需要区分 Markdown/Agent 协作图、只读 checker、Gate procedure、人类 H node 与 OpenSpec maintenance。"
focus:
  - "保留该项目四份 maintenance policy 的明确引用，收缩其在 context 中重复的解释。"
  - "让 framework-maintenance 的 proposal/design 记录 policy 结论；让具体 project/run-bundle simulation 回到 START_HERE、playbook、state 和 Gate procedure。"
not_for:
  - "不要把本项目的 B1 判断、H/A/T node、D-ID、PEV、Gate 或 runtime layout 复制为其他项目的 config 模板。"
  - "不要把 policy、config 或 planning artifact 当作 RUN_STATE、WORKFLOW_NODES、stage transition、human decision 或 mutation permission 的权威。"
next_read:
  - "案例边界与其他项目：README.md"
  - "初始 Flow 基线：../00-initial-config-baselines.md"
  - "通用归位规则：../01-design-config-yaml.md"
---

# 13 — Agentic Business Simulation：MD/Agent 协作 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_tool_bsimulation/openspec/config.yaml`。

## 项目是什么

Agentic Business Simulation 是商业决策模拟 framework。运行时由 Agent 按 Markdown charter、ops、playbook 和 H/A/T collaboration node 推进工作；Human H node 保留目标、风险、内部事实、情景选择和计划采纳；Node.js checker 只给确定性、只读诊断。`state/RUN_STATE.md` 是可变状态权威，`WORKFLOW_NODES.md` 拥有合法协作 edge/guard，`GATE_PROCEDURE.md` 将正式 verdict 写进 owning runtime log。

## 使用边界

本文只审计上述 `config.yaml` 的 framework-maintenance authoring role。它不改变具体 project/run-bundle simulation 的实际入口、Node、Gate、state、candidate、PEV、D-ID 或人类决策方式。其他项目最多借鉴“先识别 Flow/Gate/state 的真实 owner，再按 artifact 消费时机归位信息”的方法，不能复制这里的术语、路径、policy、命令或判断。

## 审计判断

该项目属于 [`00-initial-config-baselines.md`](../00-initial-config-baselines.md) 的 **B1：MD/Agent 控制 Flow，传统程序做 Gate**。虽然 `WORKFLOW_NODES.md` 定义了合法 collaboration graph，但它是 Agent 读取并执行的 Markdown authority；`workflows/manifest.json` 只是节点定位；checker 不推进 route、不能写 runtime，也不能授权 stage movement。Agent 在现有 route/authority 内执行协作与机械工作，正式 Gate procedure 和人类 H node 共同约束下一步。

因此，config 应保留这张稳定 authority map 和四份 maintenance policy 的短入口；它不应把完整 node graph、runtime vocabulary、Gate procedure、repair catalog、capability planning table 或 simulation 操作手册重复注入 proposal、specs、design、tasks。

## Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| Markdown/Agent、checker、Gate procedure、Human 的控制权与 `RUN_STATE` 边界 | 4-18 | 所有 planning artifact 都需要的稳定 B1 authority profile。 | `context`，压缩为约 8-12 行；保留唯一 state、checker 不授权 movement、Human 保留业务决策。 |
| framework maintenance 与 project/run-bundle 生产数据边界 | 20-32 | 稳定且高价值，能阻止把 production data 当 fixture。 | `context` 留短 scope boundary；完整目录表留 `AGENTS.md`。 |
| Sources of Truth 的完整十行表 | 34-51 | 框架/运行时 authority 的少量入口很重要，但每个 artifact 不需要完整索引。 | `context` 留 charter / ops / playbook / main spec / active delta / runtime state 六类入口；具体 `WORKFLOW_NODES`、knowledge、stage 与 dispatcher 在触发的 design/tasks 读取。 |
| Runtime 概念分层 | 53-66 | `current_node`/`current_stage`、D-ID、project/run bundle 的区别很稳定；candidate、PEV、immutable baseline 等细节不是每次维护规划的背景。 | `context` 留 3-4 个不可混淆术语；详细 layout/contract 留 charter。 |
| 技术栈与 gate execution 细节 | 68-75 | Node ESM 是稳定约束；resolved checker、日志 writer、movement authorization 是 runtime/design 专属。 | `context` 留栈与“checker read-only”；详细规则留 charter/ops，相关 design/tasks rule 指向。 |
| OpenSpec 开发循环 | 77-80 | 是 framework maintenance 的稳定生命周期，但不需要解释每步含义。 | `context` 留一句 lifecycle；具体 Apply 行为留 tasks/schema/playbook。 |
| 四份 policy 的完整解释与 declaration 定义 | 82-122 | 四份 policy 的**路径与顺序必须保留**：项目的 accepted `framework-maintenance-workflow` contract/test 要求所有 artifact instructions 收到四-policy injection。现在的问题是重复了大量 policy 正文。 | 将 82-122 替换为短的四路径 policy map；proposal/design rules 记录触发、结论与证据。不要删除 policy 文件或 config 引用。 |
| 规划 capability 表 | 124-146 | 明说“不是 main spec 已存在”，仍会制造第二份长期 registry。 | 从 `context` 删除；proposal/specs 先检查实际 `openspec/specs/`，若需发现索引则生成薄链接表。 |
| 版本策略 | 148-153 | 只在 framework/version change 触发。 | `rules.proposal` / `rules.tasks`，实际 `VERSION`/log 保持权威。 |

## 四份 policy 的引用不能丢

本案例不是“删掉 policy”的建议。下列四份文件应原样保留，config 也应保留明确路径；删除的只是当前 context 对每份 policy 的长解释。

| 触发 | canonical policy | proposal/design 应留下 | runtime authority 仍在 |
|---|---|---|---|
| 新增或实质重解释 reader-facing representation | `openspec/policies/abstraction-semantic-precision.md` | semantic-admission declaration：reader、bounded question、answer-changing distinction、honest stopping point。 | owning spec、charter、state/typed decision、runtime contract。 |
| gate、readiness、controller、state、validator、retry、fallback、recovery 或 quality-control change | `openspec/policies/simple-reliable-control.md` | control-impact declaration：direct authority、最短闭环、删除/合并的复杂度、最近合法动作、negative proof。 | owning evaluator/checkpoint/repair contract。 |
| human H node、业务决定、human handoff、continuation 或 hard-stop 分类 | `openspec/policies/human-decision-boundaries.md` | hard-stop / human-decision / agent-handled 的分类、protected invariant 或最小人类决定。 | `WORKFLOW_NODES.md`、typed H decision、Gate/runtime contract。 |
| writer、evaluator、diagnostic、sanctioned repair、durable record、control-path recovery | `openspec/policies/agent-control-integrity.md` | writer/reader、binding、freshness、invalidation、授权 repair 或 missing-contract boundary。 | owning writer/interface、state、spec 与 executable evidence。 |

设计顺序只处理“要设计什么、控制形状、谁应决定/执行”：

```text
semantic precision
  -> simple reliable control
  -> human-decision boundaries
  -> agent-control integrity
```

这不覆盖一个已观察 condition 的处置顺序。该顺序仍由 `human-decision-boundaries.md` 定义：先 hard-stop，再 human decision，最后才是 Agent-handled。policy 不会授予 route、writer、permission、waiver 或 state mutation。

## Rules 归位

| Rules 组 | 现有优势 | 建议调整 |
|---|---|---|
| `proposal`（156-176） | control-impact / semantic-admission declarations 已经是很好的 change-local 分类；capability 与 scope 也有 owner。 | 保留 declarations，但增加四份 policy 的明确路径与选择顺序。proposal 只记录本次适用性、authority owner 和最小结论，不复制 policy 教程。 |
| `specs`（178-195） | 能把 classification 变成 observable outcome、subject owner、bypass/recovery contract。 | 只在 applicable change 写这些约束；引用 owning capability/runtime authority，不把 policy prose 变成 schema 或 pass/fail truth。 |
| `design`（197-214） | 已适合记录 writer、binding、freshness、repair 与 semantic surface 的实际取舍。 | 作为四-policy 的主审查与技术证据 owner：明确读到的 policy、runtime contract、direct SoR、checker/ops/playbook 影响、测试界限。 |
| `tasks`（216-230） | 已把 wrong-authority mutation、same-check/H-node recovery 与真实观察边界变成实施证明。 | 保留；确保 tasks 从 design 继承具体 command/fixture/observation，不假设 Apply 会重读 config。 |

## 具体编辑类型

这是一次**混合修改**，不是 additions-only，也不是整份 config replacement：

| 位置 | 操作 |
|---|---|
| 四份已列名的 `openspec/policies/` 文件 | **保留，不改。** |
| `context` 4-80 | **压缩/替换。** 保留 authority profile、maintenance/runtime boundary、短 SoT locator、少量术语和 Node ESM；移走目录树、runtime procedure 与细粒度 contract。 |
| `context` 82-122 | **替换为短 policy map，不删除引用。** 必须仍出现四个 canonical policy path 和 semantic → control → human → agent 的设计顺序，以满足四-policy instruction injection。 |
| `context` 124-153 | **删除或迁到触发 rule。** capability planning table 不能是第二 registry；version policy 只在版本 change 消费。 |
| `rules.proposal` 167-176 | **修改，不追加重复 rule。** 保留两份 declaration，但逐条引用上述 policy 文件与本次触发面。 |
| `rules.design` 207-214 | **修改。** 加入四-policy route、设计证据落点和 runtime authority locator；保留已有 writer/recovery/semantic 约束。 |
| `rules.specs`、`rules.tasks` | **基本保留。** 只把本次从 proposal/design 已决定的 requirement、owner、proof 具体化。 |

## 建议的短 policy map

以下是替换 context 82-122 的形状。它不取代四份 policy，也不把 runtime contract 重新写入 config。

```yaml
context: |-
  Framework-maintenance design uses these guidance-only policies in order when applicable:
  1. `openspec/policies/abstraction-semantic-precision.md`
  2. `openspec/policies/simple-reliable-control.md`
  3. `openspec/policies/human-decision-boundaries.md`
  4. `openspec/policies/agent-control-integrity.md`
  They guide change admission only. Charter/ops/playbook, accepted specs, RUN_STATE,
  typed human decisions, sanctioned writers, code, and tests retain their own runtime
  facts and permissions. For an observed condition, human-decision policy classifies
  hard-stop -> human-decision -> agent-handled before any mechanical execution.
```

## 建议的 proposal/design 短路由

以下是对既有 declaration rules 的修改形状；不是追加第二套 declaration。

```yaml
rules:
  proposal:
    - >
      Every framework-maintenance proposal records `control-impact declaration` and
      `semantic-admission declaration`. When applicable, read and name the triggered
      `openspec/policies/abstraction-semantic-precision.md`,
      `simple-reliable-control.md`, `human-decision-boundaries.md`, and/or
      `agent-control-integrity.md` from the ordered policy map; record affected direct
      authorities, protected invariant or smallest human decision, semantic reader/question,
      and the evidence seam. Policy does not create runtime schema, writer, route, or permission.

  design:
    - >
      For an applicable semantic/control/human/agent surface, read the corresponding
      `openspec/policies/abstraction-semantic-precision.md`,
      `simple-reliable-control.md`, `human-decision-boundaries.md`, and/or
      `agent-control-integrity.md` in the required order. Record the owning charter/ops/playbook
      or spec, direct Source of Record, writer/evaluator, legal H-node or repair boundary,
      compatibility/retirement choice, and deterministic versus controlled-observation proof.
```

四个 policy path 都在示例中逐条出现；它们不是未知 YAML 功能、glob 或可任意扩张的 policy family。真实 config 应保留这些已知路径，方便注入测试、reviewer 和后续维护者检查。

## 具体 simulation 不走 OpenSpec

用户要运行某个商业模拟时，应经 `BSIM_FRAMEWORK/START_HERE.md`、`BSIM_FRAMEWORK/AGENTS.md`、`state/RUN_STATE.md`、`workflows/manifest.json` 和 exact node/playbook 执行。它不应创建 OpenSpec proposal/specs/design/tasks，也不得顺手修改 framework。OpenSpec change 只在要改 framework 的持久行为、charter/ops/playbook、checker、scaffold、tests 或 accepted spec 时启动；届时 proposal 记录对 project/run-bundle contract 的 compatible/migration impact，但 production runtime 继续是受影响对象，而非第二种 OpenSpec work domain。
