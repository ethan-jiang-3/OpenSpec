---
title: "10 — Deep Research Tool：MD/Agent 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml"
applies_to:
  - "Deep Research Tool at case_source"
  - "that project's audited B1 runtime boundary"
read_when:
  - "正在维护或复核 case_source 对应的 Deep Research Tool 配置。"
  - "需要理解该项目中哪些 runtime/playbook 细节被过早注入所有 planning artifacts。"
focus:
  - "区分可在后续治理 change 中归位的信息，与当前已受 accepted spec 和 regression test 约束、必须继续留在 context 的 Evolution Directions 路由。"
  - "为本项目给出一项可直接实施的、带精确 policy 路径的 design rule 修改建议。"
not_for:
  - "不要把本项目的 B1 判断当作其他 MD/Agent 项目的分类依据或配置模板。"
  - "不要复制此项目的 capability、bundle、实验或验证细节到无关项目。"
next_read:
  - "案例边界与四个项目介绍：README.md"
  - "通用归位规则：../01-design-config-yaml.md"
---

# 10 — Deep Research Tool：MD/Agent 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml`。

## 项目是什么

Deep Research Tool 是一个把宽泛研究问题转化为证据支撑、多波次、带 Gate 研究报告的 Agentic framework。运行时由 Agent 执行搜索、阅读、写作、综合和语义判断；Markdown 提供 Agent-facing flow；JavaScript Engine 负责 schema、状态、receipt 与确定性 Gate。

## 使用边界

本文只审计这个项目在上述来源路径中的 `config.yaml`，不是 B1 项目的通用模板。其他项目最多借鉴“先识别 consumer、再归位信息、把硬约束交给确定性 owner”的审计方法；不能复制这里的 capability、bundle、实验体系、requirement registry、verification routing、目录、命令或行号结论。

## 审计判断

这个项目属于 [`00-initial-config-baselines.md`](../00-initial-config-baselines.md) 的 **B1：MD/Agent 控制 Flow，传统程序做 Gate**。配置中已经准确表达了 Agent 负责搜索、阅读、写作、综合、决策，Engine 负责 schema、状态机、receipt 和 Gate 校验；问题不在这套模型本身，而在过多 runtime/playbook 细节被重复注入每个 planning artifact。

> 目的不是批评配置“写得太长”，而是识别每段信息的正确 owner、消费时机和验证方式。建议去处是设计方向，最终仍应以项目实际文件结构为准。

> **阅读边界：**下面的“归位”两表是未来治理重构时可逐项验证的候选清单，**不是当前可以批量移动或删除的改动清单**。本次经 spec/test 复核后，唯一可直接实施的 YAML 改动见后文“可直接实施的 YAML 改写”。

## Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 项目一句话、Agent / Engine / 文件的基本分工 | 4-10 | 跨 artifact 的稳定理解，值得保留；当前细节未来可审计。 | 后续治理 change 才能评估是否压缩为 authority profile。 |
| 核心原则与 JS/MD 边界 | 12-21、30-44 | “谁拥有决策”是稳定背景；具体错误处理、env/routing 规则未必由所有 artifact 消费。 | 后续治理 change 中，先查 consumer、spec 与测试，再决定是否保留摘要或改为条件化指针。 |
| 技术栈及允许依赖 | 23-28 | 对 design/tasks 有强影响，对 proposal/specs 价值较低。 | 后续治理 change 中，确认没有隐含 consumer 后，再考虑移到 `rules.design` / `rules.tasks`。 |
| Evolution Directions | 51-60 | 从信息归位角度看，它们主要服务 proposal/design；**但本项目的 accepted spec 与 regression test 明确要求 OpenSpec `context` 以此顺序路由三条 Directions**。 | 当前不得移走。保留此处的有序路径与摘要；在 `rules.design` 增强“何时深入阅读、结论落在哪里”的要求。 |
| 命名规范 | 62-65 | UI 语言/路径语言可能全局；capability prefix 与 bundle 命名是条件性规则。 | 后续治理 change 中，按实际 consumer 决定是否拆分到 proposal/specs、design/tasks 或 runtime playbook。 |
| Requirement Traceability | 67-77 | 每条要求有不同消费者：分配 ID、写 spec header、写实现标记、收尾检查。 | 后续治理 change 中，确认 proposal / specs / tasks 与 checks 的现有契约后再拆分。 |
| Governance 工具与 registry 组织细则 | 79-91 | 详细的登记格式未必是所有 artifact 都需要的上下文。 | 后续治理 change 中，先验证 registry/checker consumer，再决定能否改为 `rules.specs` / `rules.tasks` 指针。 |
| Verification routing | 93-109 | 是 change-level verification policy；“本次计划”应该进入 change 的 `verification-plan.yaml` 和 tasks。 | 后续治理 change 中，确认 lifecycle tests 后，才可考虑把分类定义交给 policy/checker。 |
| 实验体系 | 111-128 | 主要面向 experiment/run 的设计与实施，不是所有 spec artifact 的背景。 | 后续治理 change 中，确认 playbook/supervisor 的实际读取路径后，再审计是否可改为 policy/runbook 指针。 |
| 根目录与 framework/bundle 详细地图 | 130-165 | 有少量全局导向价值，但完整树是静态索引。 | 后续治理 change 中，确认 agent 是否依赖该地图后，再评估 README/charter 的替代方案。 |

## Rules 归位

现有规则已经比 context 更接近正确的注入位置。目标是压缩重复内容，并加强“触发 -> 动作 -> 留痕”，不是把它们再次全部搬走。

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（168-177） | 能明确语言、source、capability、版本等长期约束。 | 多条与 context 的 Evolution Directions 重复；不同 change 类型适用性不同。保留摘要和明确路径，详细政策转为短指针。 |
| `design`（178-183） | 技术栈、状态机、source-of-record 非常适合 design。 | “只能用依赖”应是项目硬约束的同时有 package/test 支撑；不要只靠 rule。 |
| `tasks`（184-200） | done condition、依赖排序、requirement ID、收尾验证都能转化为可读任务。 | Apply 不会重新注入 artifact `rules`（但会接收 project `context` 与 `operations.apply.guidance`）；必须让生成出的 `tasks.md` 写出收尾验证，且由 CI/checker 复核。 |
| `specs`（201-227） | Capability / requirement 的约束有明确 artifact owner。 | 主 spec 结构与 ID 格式最好由现有 governance checker 保障；长的边界测试可从 inline rule 移为 policy 指针。 |

## 对本文 Evolution Directions 建议的复核（以当前项目契约为准）

此前本文把三条 Evolution Directions 归为“从 `context` 移到 `rules.proposal` / `rules.design`”的内容。这个判断从减少重复注入的角度可以理解，**但对这个项目不能直接执行，故在此撤回为当前配置建议**。

原因不是偏好，而是该项目已有两项明确约束：

1. `openspec/specs/guidance-constitution/spec.md` 的 `Current evolution directions route relevant design through ordered reviews` 要求 Project Charter、Guidelines Index 和 **OpenSpec proposal/design context** 都路由当前顺序：semantic precision → simple reliable control → helper-oriented action responsibility。
2. `tests/integration/md/evolution-direction-governance.test.mjs` 会解析 `openspec/config.yaml` 的 `context`，断言三个完整 guideline 路径都在那里，且顺序正确；同时断言 `rules.proposal` 和 `rules.design` 分别保有相应的路由语句。

因此，当前 `config.yaml` 的 51–60 行并非可自由压缩的重复文字。删掉它们，或把 context 从 3–165 行整体压为 5–8 行而不保留这个路由，会使 accepted spec 和回归测试同时失效。要改变这一点，必须另开一个**治理契约变更**：先修改 accepted spec、相应测试和相关 guidance，再讨论新的注入模型；不能把它混入一次普通的 config 整理。

### 这次建议到底改什么

这是一个非常窄的建议，编辑类型如下：

| 位置 | 编辑类型 | 具体动作 | 不做什么 |
|---|---|---|---|
| `context` 51–60 | **保留** | 保持三条 Directions 的完整路径、顺序和基础摘要。 | 不删除、不搬迁、不把 context 压到 5–8 行。 |
| `rules.proposal` 172–174 | **保留** | 保持现有 semantic reflection、net simplification、责任边界三项要求。 | 不新增 Change Context Card，不要求 proposal 再写一份完整 review。 |
| `rules.design` 183 | **修改一条现有 rule** | 将笼统的“三条 Directions”改成三个精确路径，并说明何时深入阅读、结论写到 `design.md` 的何处。 | 不增加第二个 rule，不新建 `Apply target manifest` 文件，不强制固定标题或表格。 |
| 其余 `context` / `rules` | **不动** | 保持项目当前的 traceability、verification、实验和目录约束。 | 不进行本次审计最初设想的全局清理。 |

换句话说：这不是“只往 config 里添几条”的 additions-only 修改，而是**把 `rules.design` 的第 183 行替换成更可执行的一条 rule**；没有删除 context，也没有其他结构性改动。

### 为什么只改 design rule

现有 proposal rules 已经分别要求：语义反思、控制的净简化、以及 user / Agent / Engine 边界。它们回答“这个 change 为什么值得做、预期不破坏什么”。

真正需要加强的是 design：作者在选数据结构、控制闭环、恢复方式和职责边界时，需要被明确带到三份 canonical policy 的原文，并把实际取舍留在设计产物。`context` 负责让正确顺序始终可见；proposal 负责提出变化；design 负责给出技术取舍。这样不会要求同一段论证在 proposal 和 design 中抄两遍。

也不建议立即把 `## Evolution review` 或 `## Apply target manifest` 设成硬编码标题。当前项目的 config、模板和 checker 没有定义它们；只改 prompt 就把它们变成硬门槛，会制造“写了但无人消费”的伪结构。将来若希望稳定强制这两个小节，应单独修改 template/checker/spec，明确其 consumer 和验证方式。

### 可直接实施的 YAML 改写

只替换 `rules.design` 当前第 183 行；其他 YAML 原样保留：

```yaml
rules:
  design:
    - >
      architecture、recovery、mutation、Agent/user responsibility 或具名概念/状态/view 变更，
      必须按顺序考虑 semantic precision → simple reliable control → helper-oriented responsibility。
      对实际新增或实质改变的层，阅读并应用
      guidelines/evolution-abstraction-semantic-precision.md、
      guidelines/evolution-simple-reliable-control.md、
      guidelines/evolution-helper-oriented-agent.md；在 design.md 的相应设计论证中简短记录
      语义边界、direct Source of Record / 最短合法闭环 / net simplification，以及
      user decision / authorized Agent execution / Engine verdict 的边界。未改变的层可说明不适用。
```

这里完整列出三个路径，是为了让 config 在 design 阶段有可审查、可导航的明确引用，而不是把三份 guideline 正文复制进 YAML。它也保留了现有测试所要求的短语 `semantic precision → simple reliable control → helper-oriented responsibility`。

### 后续可以另开讨论、但不是当前改动的事项

`context` 里其他很长的内容，例如 registry 组织细则、verification routing、实验体系和目录树，仍值得逐段做 consumer/owner 审计；其中一部分未来可能适合改成短指针并交给 checker、policy 或 runtime playbook。这是另一项有风险的治理重构：每一段都要先确认是否有 spec、测试或 agent workflow 读取它，不能因“看起来太长”而一并删除。
