---
title: "12 — DeerFlow Deep Research：程序/Graph 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_deerflow_deep_research/openspec/config.yaml"
applies_to:
  - "B2: program/Graph-controlled Flow with bounded intelligence nodes"
  - "LangGraph-style stateful orchestration with node contracts and deterministic admission"
read_when:
  - "可执行 graph / state machine 决定节点、转移、状态、重试和恢复，模型能力只在 node 内完成有界工作。"
  - "需要审计 config 是否把 graph、state、node contract、tool permission 或 recovery 的运行时权威放错位置。"
focus:
  - "保留短的 B2 authority map；把 graph/state/node contract 交还给 executable runtime，把 review 仅作为 proposal/design 的路由。"
  - "用 graph transition、state writer ownership、candidate admission 与 deterministic evidence 判断谁真正拥有 Flow。"
not_for:
  - "不要把本案例套到 MD/Agent 总控制 Flow；那类项目应读 10 或 11。"
  - "不要把 config、prompt 或 review record 当作 node role、route、state write、tool permission 或 recovery 的权威来源。"
next_read:
  - "通用归位规则：01-design-config-yaml.md"
  - "运行时/配置未按预期生效：02-diagnose-maintain-config-yaml.md"
---

# 12 — DeerFlow Deep Research：程序/Graph 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_deerflow_deep_research/openspec/config.yaml`。

这个项目属于 [`00-initial-config-baselines.md`](00-initial-config-baselines.md) 的 **B2：程序/Graph 控制 Flow，智能能力受限于 Node**，不是 B1 的“MD/Agent 控制 Flow，程序做 Gate”。`agent/README.md` 明确将 controller 定义为嵌套 Python `StateGraph`；`graph/builder.py` 登记节点与每条条件转移；`domain/state.py` 则用带 writer ownership 的 reducer 拒绝未授权状态写入。模型/Agent 可以在 node 内完成有界的认知工作，但不能凭 prompt、proposal review 或 config 获得 graph route、state write、tool permission、retry 或 recovery 权限。

> 目的不是压缩文字本身，而是让每段信息由正确的 owner 在正确阶段消费。对 B2 而言，尤其不能把 graph、state 或 node contract 的运行时权威误放进 `openspec/config.yaml`。

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
| `tasks`（70-71） | 要求 red-before-green、窄验证命令和 archive 前的完整检查，能把 guidance 变为可执行 evidence。 | Apply 不会重新注入 config rules。因此生成的 `tasks.md` 必须写出具体 test / `make verify` / OpenSpec validation，而 mirror cleanliness 等不可协商事实还应由 checker、test 或 CI 验证，不能只留在 task prose。 |

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

1. 将 `context` 收敛为“downstream/mirror 边界 + B2 authority map + canonical source locator”；保留短路由，删除会在普通 planning artifact 中重复出现的运行时操作细节。
2. 在 proposal 中把 Change Focus、触发的 charter policy、受影响 graph/node/state boundary 和 evidence seam 写成一次 change 的事实；完整 review table 格式只在触发时从 charter 读取。
3. 对 node 或 graph 改动，让 design 记录实际 graph/state/node contract，而不是要求每个 planning artifact 都携带 node 列表、prompt 或 topology。
4. 让 `tasks.md` 生成并执行具体 graph/reducer/node tests 与项目 gate；将必须成立的 ownership、mirror 和验证不变量交给 deterministic checker、test 或 CI。

这份配置的方向已经相当接近正确：它主动声明了短 context 边界、把 review 放在 proposal、并明确 config/review/prompt 不授予运行时权力。主要可继续优化之处是减少 policy 正文在 config 中的重复，让 graph、state、node contract 和 charter 分别继续做各自的唯一 authority。
