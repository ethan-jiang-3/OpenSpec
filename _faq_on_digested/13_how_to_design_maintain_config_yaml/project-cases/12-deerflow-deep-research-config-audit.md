---
title: "12 — DeerFlow Deep Research：程序/Graph 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_deerflow_deep_research/openspec/config.yaml"
applies_to:
  - "DeerFlow Deep Research at case_source"
  - "that project's audited StateGraph/state/node-contract boundary"
read_when:
  - "正在维护或复核 case_source 对应的 DeerFlow Deep Research 配置。"
  - "需要理解该项目是否把 graph、state、node contract、tool permission 或 recovery 的运行时权威放错位置。"
focus:
  - "保留该项目简短的 B2 authority map；把 graph/state/node contract 交还给 executable runtime，把 review 仅作为 proposal/design 的路由。"
  - "用该项目的 graph transition、state writer ownership、candidate admission 与 deterministic evidence 判断谁真正拥有 Flow。"
not_for:
  - "不要把本项目的 B2 判断当作其他 DeerFlow、LangGraph 或 Agentic 项目的分类依据或配置模板。"
  - "不要把 config、prompt 或 review record 当作 node role、route、state write、tool permission 或 recovery 的权威来源。"
next_read:
  - "案例边界与四个项目介绍：README.md"
  - "通用归位规则：../01-design-config-yaml.md"
  - "运行时/配置未按预期生效：../02-diagnose-maintain-config-yaml.md"
---

# 12 — DeerFlow Deep Research：程序/Graph 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_deerflow_deep_research/openspec/config.yaml`。

## 项目是什么

DeerFlow Deep Research 是建立在 DeerFlow 2.1 上的下游深度研究产品，主要实现位于 `agent/`；仓库中的 `backend/` 与 `frontend/` 是上游 DeerFlow mirror。它用嵌套 Python `StateGraph` 编排研究节点，以 typed state、writer ownership、node contract 和 evaluator 限制智能 node 的权限。

## 使用边界

本文只审计这个项目在上述来源路径中的 `config.yaml` 及其 `agent/` runtime boundary，不是 LangGraph、DeerFlow 或 B2 项目的通用模板。其他项目最多借鉴“运行时 authority 必须落回 graph/state/node contract”的审计方法；不能复制这里的 mirror 边界、Change Focus、charter policy、node review 表、验证命令、模块路径或 state owner。

## 审计判断

这个项目属于 [`00-initial-config-baselines.md`](../00-initial-config-baselines.md) 的 **B2：程序/Graph 控制 Flow，智能能力受限于 Node**，不是 B1 的“MD/Agent 控制 Flow，程序做 Gate”。`agent/README.md` 明确将 controller 定义为嵌套 Python `StateGraph`；`graph/builder.py` 登记节点与每条条件转移；`domain/state.py` 则用带 writer ownership 的 reducer 拒绝未授权状态写入。模型/Agent 可以在 node 内完成有界的认知工作，但不能凭 prompt、proposal review 或 config 获得 graph route、state write、tool permission、retry 或 recovery 权限。

> 目的不是压缩文字本身，而是让每段信息由正确的 owner 在正确阶段消费。对 B2 而言，尤其不能把 graph、state 或 node contract 的运行时权威误放进 `openspec/config.yaml`。

> **先看这一结论：**前面的归位分析是未来 context-budget/governance change 的诊断材料，**不是当前配置的删除或搬迁清单**。本次建议严格是 additions-only：`context` 6–54、`rules.proposal` 58–62、`rules.specs` 64–65、现有 `rules.design` 67–68 和 `rules.tasks` 70–71 全部原样保留；只在 `rules.design` 数组追加后文的一条 rule。policy 名称、触发条件、`## Workflow Outcome Review`、`## Node Agent Review` 和 `Change Focus` 都不改。

## Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 下游 `agent/` 的所有权、上游 `backend/` / `frontend/` mirror 边界 | 6-9 | 是每个 planning artifact 都应知道的稳定边界；它能阻止无意扩大到上游。 | `context` 保留为 2-3 行摘要；proposal rule 要求这次变更若跨该边界必须显式取得批准。 |
| “这是短 OpenSpec authoring route，不是项目手册” | 13-16 | 这是正确的 config 自我约束，避免把运行时架构和历史 material 再次塞进全局 prompt。 | `context` 保留。它应成为收缩 context 时的判断准则。 |
| Sources of Truth | 18-30 | “spec / code / typed contract / test 各自拥有何种事实”是稳定导航；完整的结构协议和 charter 细则则按需读取。 | `context` 只留简短 authority map 与入口；`project-structure.toml`、architecture policy、charter 继续是 canonical source。 |
| Test Evidence | 32-36 | “最低负责 deterministic seam”是重要原则，但 test-bearing change 才需要详细动作。 | `rules.tasks` 负责要求生成具体测试与命令；涉及方案选择时由 `rules.proposal` / `rules.design` 指向 test-evidence policy，而不是在 `context` 复制测试政策。 |
| Start A Local Change 与 `Change Focus` 步骤 | 38-54 | 这是 proposal 的变更分类与 scope-admission 流程，不是所有 artifact 的背景。`agent/AGENTS.md` 已经是更合适的本地阅读入口。 | `rules.proposal` 保留“必须产生 Change Focus”的短约束；完整字段、邻接模块准入和 charter policy 归 Agent Charter / `AGENTS.md`。 |

这里的最小稳定 profile 应说明：产品边界、`agent/` 与 upstream mirror 的边界、**StateGraph 拥有 Flow / checkpointed state / route，node 只拥有有界认知工作**，以及 graph、state、node contracts、capability specs 的查找入口。它不应复制 topology、11 个 node 列表、prompt、provider/tool 配置、test catalog 或恢复细节。

## Rules 归位

现有 `rules` 已经把多数变更指导投放到 proposal/specs/design/tasks，比把它们放进 `context` 更接近正确位置。下一步应是把长的表头和运行时免责声明收敛为“触发条件 -> 动作 -> canonical policy -> artifact 证据”的短路由。

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（58-62） | `Change Focus` 强制声明 causal owner、evidence seam、scope 与 triggered policies；对 Flow 或 node 变更，Workflow Outcome Review 与 Node Agent Review 能让审查聚焦于边界。 | 保留 Focus Card 和条件触发；表格字段、分类定义、policy 解释应由 Agent Charter 作唯一权威，config 只保留短指针。尤其不要把 review record 写成会赋予 node role、route、state write、model invocation、tool permission 或 recovery 的东西。 |
| `specs`（64-65） | 要求 observable/mechanically verifiable behavior，并坚持最低 deterministic evidence，符合 B2 的外部行为契约。 | main spec / active delta 才是 requirement ID 与行为的权威；spec 不应以 prompt 文本替代 graph、state 或 node 的可执行契约。 |
| `design`（67-68） | 要求说明 state、checkpoint、artifact、evidence、recovery 的 owner，并禁止 competing controller；这是 B2 最重要的设计 guardrail。 | 对 graph/node change，design 应从实际 owner 记录 node input/output、允许 transition predicate、state mutation / reducer、candidate admission evaluator、retry/fallback 与 deterministic graph test。不要只靠“模型会如何判断”的叙述。 |
| `tasks`（70-71） | 要求 red-before-green、窄验证命令和 archive 前的完整检查，能把 guidance 变为可执行 evidence。 | Apply 不会重新注入 artifact `rules`（但会接收 project `context` 与 apply guidance）。因此生成的 `tasks.md` 必须写出具体 test / `make verify` / OpenSpec validation，而 mirror cleanliness 等不可协商事实还应由 checker、test 或 CI 验证，不能只留在 task prose。 |

## B2 的专属诊断问题

当配置或 change 文档让人难以判断“到底谁控制 Flow”时，先按下面四项追问；其中任何一项无法落到代码或 typed contract，都不应由 config 补写成事实。

| 问题 | DeerFlow 的 authoritative owner | 应留下的证据 |
|---|---|---|
| 谁决定下一 node、条件分支、循环和结束？ | `graph/builder.py` 的 `StateGraph`、`add_conditional_edges` 与 `_route`。 | graph topology / routing 的 deterministic test。 |
| 谁能写 checkpointed lifecycle state？ | `ResearchState` 的 reducer 和 `WriterRole` ownership。 | reducer / state transition test，拒绝未授权 writer 的反例。 |
| Node Agent 能做什么，不能做什么？ | node contract、runtime bridge、parser/evaluator/materializer；Node Agent 只返回 candidate。 | node I/O contract、admission test、tool/runtime policy test。 |
| provider/tool/worker 失败后谁恢复或终结？ | graph/node handler、gate 与 typed lifecycle contract；proposal 的 review 仅暴露缺失决定。 | bounded retry / terminal disposition 的 deterministic evidence，以及必要的 scenario/live evaluation。 |

`openspec/config.yaml` 在这张表中的工作只是让 change author 在正确 artifact 回答这些问题。它不是第四个 runtime controller，也不能充当 `ResearchState`、graph builder 或 runtime bridge 的替身。

## 可行的渐进收缩目标

本节只说明未来独立治理 change 可以验证的方向，不扩大上文已经界定的 additions-only 范围。

1. 将 `context` 收敛为“downstream/mirror 边界 + B2 authority map + canonical source locator”；保留短路由，删除会在普通 planning artifact 中重复出现的运行时操作细节。
2. 在 proposal 中把 Change Focus、触发的 charter policy、受影响 graph/node/state boundary 和 evidence seam 写成一次 change 的事实；完整 review table 格式只在触发时从 charter 读取。
3. 对 node 或 graph 改动，让 design 记录实际 graph/state/node contract，而不是要求每个 planning artifact 都携带 node 列表、prompt 或 topology。
4. 让 `tasks.md` 生成并执行具体 graph/reducer/node tests 与项目 gate；将必须成立的 ownership、mirror 和验证不变量交给 deterministic checker、test 或 CI。

这份配置的方向已经相当接近正确：它主动声明了短 context 边界、把 review 放在 proposal、并明确 config/review/prompt 不授予运行时权力。主要可继续优化之处是减少 policy 正文在 config 中的重复，让 graph、state、node contract 和 charter 分别继续做各自的唯一 authority。

## 对本文建议的复核

本案例的主判断是对的：DeerFlow 是 B2，图、typed state、node contract 和 executable evidence 才拥有运行时事实；`openspec/config.yaml` 只能把 change author 路由到恰当的审查。不过，不能把“完整 policy 正文不应重复”误解为“config 不再明确引用 policy”，更不能把这里的 proposal review 机械地下沉到 design。

**本次对实际 `config.yaml` 的建议是 additions-only：保留现有 `context` 与 rules，不删除、不搬迁已有的 Change Focus、policy route、review heading 或 archive task。** 下文若谈到更短的 context，只是未来另开 change 时可以评估的收缩方向，不是这次应执行的 config 编辑。

该项目有一个重要的已接受合同：`deep-research-agent-charter` spec 与 `check_agent_charter.py` 要求 config 保留 `workflow-outcome-review`、`node-agent-workflow-integrity`、`## Change Focus` 和相应 review heading 的 authoring route。checker 可以确定所选 policy 是否有要求的 proposal record，却不会判断表格中的语义是否真实，更不会创造 graph route、state writer 或 tool permission。当前 config 已用 Charter README 指针加 canonical policy name 完成这条路由；未来若另行做 context 收缩，也必须保留这种明确引用和 record 触发。

### 原建议需要补强的地方

| 问题 | 为什么是问题 | 应怎样调整 |
|---|---|---|
| “完整 review table 格式只在触发时从 charter 读取”说得过于抽象。 | 这里不是普通的可选建议。accepted spec 要求所选的 `workflow-outcome-review` / `node-agent-workflow-integrity` 必须产生 proposal review，治理 checker 也检查 policy 名和 review heading。若 config 只剩“按需读 charter”，作者容易漏掉 record。 | 保留当前 `rules.proposal` 的两个 named trigger rules、review heading 与 context 中的 Charter README 指针。它们已经构成明确路由；表格列定义、分类和值域继续留在 policy、main spec 与 checker，不在 config 再复制一遍。 |
| 将 Change Focus 的完整 Start A Local Change 步骤从 context 移走，却没有说明它必须迁到哪里。 | 若简单删除 context 38–54 行，proposal rule 只会要求“填写卡片”，却不再提醒作者先读 `agent/AGENTS.md`、owner spec/delta、closest implementation 与最低证据 seam；Focus Card 会沦为空表。 | **本次不移动。** 保留这段简短 bootstrap route 与现有 proposal rule。将来若有独立的 context-budget change，才可把它收敛为一条 proposal preflight，但必须同时保留 checker 所需的 scope-expansion anchor。 |
| 建议将 Test Evidence 从 context 路由到 rules，却没有说明 policy 本身要求保留 config bootstrap pointer。 | `test-evidence-policy.md` 明确说 config 与 `agent/AGENTS.md` 应保留简短入口。完全删除 config 入口会违反该项目自己的治理设计；继续把详细测试政策留在 context 又会无差别注入所有 artifact。 | **本次不移动。** 现有 32–36 行已经是简短 bootstrap pointer；保留它。需要更细的证据选择时，proposal/design/tasks 再按现有 policy 和 task rule 留痕。 |
| 审计正确说“review 不授予 runtime authority”，但没有区分 proposal 与 design 的不同证据。 | `Workflow Outcome Review` / `Node Agent Review` 是 proposal 的 admission record，用来暴露缺失决策；它们不应替代 design 中对 graph/node/state 的实际映射。把两个表搬到 design，反而会违反现有 spec 的 proposal contract。 | proposal 保留 charter-required reviews；design 只在 graph/node/state 真的变化时，记录实际 `StateGraph` transition/predicate、typed input/output、writer/reducer、candidate evaluator/admission、retry/terminal bound 与对应 deterministic test。 |
| “交给 checker、test 或 CI”还缺少强制边界。 | `check_agent_charter.py` 能检查 Focus Card 和 table 的结构，不能证明某一 node 真有该 tool policy，也不能验证 reducer 拒绝错误 writer。若把语义可靠性误交给 prose checker，会把 B2 又拉回 prompt governance。 | review-record shape 交给 charter checker；observable behavior 交给 owning spec + graph/reducer/node tests；跨边界或 release claim 再由 test-evidence policy 的证据等级决定。三者不互相替代。 |

### 明确的 policy 路由，不是删除引用

下表说明当前 config 经 Charter route 指向的 canonical sources；它不是本次要新增的路径清单。不得删除现有 policy name、trigger 或 review heading。

| 触发 | canonical source | proposal 必须留下 | 运行时事实仍由谁拥有 |
|---|---|---|---|
| 修改 model、tool、provider、worker、retry、terminal、diagnostic 或 lifecycle projection | `openspec/governance/agent-charter/policies/workflow-outcome-review.md` | `## Workflow Outcome Review` | owning capability spec、typed lifecycle/state、graph/node handler 与测试。 |
| 新增、删除或实质改变 node 的 LLM role、tool posture、candidate admission、repair semantics 或 model/non-model classification | `openspec/governance/agent-charter/policies/node-agent-workflow-integrity.md` | `## Node Agent Review` | graph/node handler、runtime bridge、parser/evaluator/materializer 与测试。 |
| test-bearing change | `openspec/governance/test-evidence-policy.md` | 选择的最低负责 deterministic seam 与升级理由 | `evaluation-hardening` spec/delta、test assets 与 checker。 |
| state、projection、human interaction、recovery 等其他 charter trigger | `openspec/governance/agent-charter/README.md` 的 route table 所选 policy | Change Focus 的 Triggered charter policies，以及该 policy 要求的 record | 对应 capability spec 与 executable contract。 |

### 当前建议的执行类型：只添加

这次无需删除或改写任何已有 config 块。现有 context 仍在项目的行数预算内，且 `Change Focus`、两条 triggered policy route、两条 review heading 和 archive commands 都与 accepted spec/checker 绑定。实际应做的 config 调整只有一项：**在现有 `rules.design` 后追加一条 B2 设计证据 rule。**

| 现有 config 块 | 本次处理 |
|---|---|
| `context` 6–54 | 原样保留。 |
| `rules.proposal` 58–62 | 原样保留。它已明确引用 policy name、触发条件和 proposal record。 |
| `rules.specs` 64–65 | 原样保留。 |
| `rules.design` 67–68 | 保留原规则，**新增**一条 graph/node/state change 的设计证据 rule。 |
| `rules.tasks` 70–71 | 原样保留。 |

### 应追加到 `rules.design` 的唯一规则

下面不是 replacement skeleton，也不是要重写 config；只是在当前 `rules.design` 数组中增加一个条目：

```yaml
rules:
  design:
    - >
      当 graph、node、state、checkpoint、candidate admission、retry 或 terminal handling 改变时，
      先从 `openspec/governance/agent-charter/README.md` 选择触发的 policy；node 的 LLM role、
      tool posture 或 candidate admission 读取
      `openspec/governance/agent-charter/policies/node-agent-workflow-integrity.md`，而 model、tool、
      provider、retry、terminal、diagnostic 或 lifecycle projection 读取
      `openspec/governance/agent-charter/policies/workflow-outcome-review.md`。随后在 design 识别 owning
      StateGraph transition/predicate、typed input/output、writer/reducer、evaluator/materializer、
      bounded recovery/terminal disposition 与 deterministic test；不得创建 competing controller 或 authority。
```

这条追加规则让 design 阶段不能只写“模型会判断什么”，而必须从明确的 policy route 回到实际的 StateGraph、reducer、node admission 和测试。它不触碰既有 proposal admission contract 或 context bootstrap，且不会遗漏 policy 的引用。
