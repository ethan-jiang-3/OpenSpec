---
title: "11 — Agentic PPT workflow：MD/Agent 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml"
applies_to:
  - "Agentic PPT workflow at case_source"
  - "that project's framework-maintenance and run-bundle-production domains"
read_when:
  - "正在维护或复核 case_source 对应的 Agentic PPT workflow 配置。"
  - "需要理解该项目如何分类 framework maintenance 与 run-bundle production，并路由长 policy。"
focus:
  - "将该项目的 framework-maintenance / run-bundle-production 分类写入 proposal，再按触发条件给 specs/design/tasks 路由 policy。"
  - "避免把该项目的 controller playbook、CLI protocol 和 bundle 操作说明塞进所有 planning artifacts。"
not_for:
  - "不要把本项目的 B1 判断当作其他 Markdown-first、PPT 或 Agentic 项目的分类依据或配置模板。"
  - "不要把 PPT 或 run-bundle 的具体术语、路径和 Gates 视为通用 config 规则。"
next_read:
  - "案例边界与三个项目介绍：README.md"
  - "通用归位规则：../01-design-config-yaml.md"
  - "配置不生效或 Apply 需要稳定指导：../02-diagnose-maintain-config-yaml.md"
---

# 11 — Agentic PPT workflow：MD/Agent 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml`。

## 项目是什么

Agentic PPT workflow 是一个 AI 驱动的演示文稿生产系统：Agent 阅读方法与项目资料、做内容和视觉判断，并通过 Markdown controller 推进 PPT 工作流；JavaScript/CLI 负责解析、校验、状态、证据和 Gate。项目同时包含 framework maintenance 与具体 deck 的 run-bundle production 两类工作域。

## 使用边界

本文只审计这个项目在上述来源路径中的 `config.yaml`，不是 Markdown-first、PPT 或 B1 项目的通用模板。其他项目最多借鉴“先分类 change domain、再按条件路由 policy”的方法；不能复制这里的 deck/run-bundle、refresh path、Gate 分类、capability 表、目录、命令或生产步骤。

## 审计判断

这个项目也属于 [`00-initial-config-baselines.md`](../00-initial-config-baselines.md) 的 **B1：MD/Agent 控制 Flow，传统程序做 Gate**：Markdown controller / Agent 拥有流程、节点、路径选择和创意判断；JS/CLI 拥有解析、校验、状态、证据和结构化诊断。审计重点是让 config 只保留这张稳定 authority map，而不把 playbook、控制政策和 run-bundle 操作手册重复投放给所有 planning artifacts。

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

## 对本文建议的复核

这份审计关于“收缩 `context`、把长 policy 改为条件化指针、不要期待 Apply 重读 config”的方向是对的。但它有一个需要先纠正的边界：**framework maintenance 与指定 deck 的 run-bundle production 不是 OpenSpec 中两个对等的 change domain。**

本项目的 `AGENTS.md` 已经把四个 framework 源码目录与 `deck_*` 生产对象分开：维护 framework 时才走 OpenSpec；用户指定 deck 后，Agent 应进入 `BOOTSTRAP.md`、`AGENT_CONTRACT.md` 和当前 controller/playbook。run bundle 当然是 framework change 需要评估的兼容对象，但不是普通 deck 生产时要创建 proposal/specs/design/tasks 的理由。

这一区分会直接影响 config 的写法：它不应把生产工作塞进 OpenSpec artifact 的分类选项；它应在项目 profile 中声明 OpenSpec 的维护范围，并把生产操作路由到真正的 controller/playbook。

### 原建议哪里还不够准确

| 问题 | 为什么是问题 | 应怎样调整 |
|---|---|---|
| 把 `framework maintenance` 和 `run-bundle production` 都称为 proposal 的 `change domain`。 | 这会暗示“用户要改一个指定 deck”也应开启 OpenSpec change。实际上 deck 是 production data，framework 在该路径下只读；其流程、状态与 Gate 都由 run-bundle/controller 持有。 | proposal 只处理 **framework maintenance**。它需要记录的是：本次框架 change 是否影响 run-bundle contract、已有 deck 的兼容/迁移策略、以及生产数据绝不能被当作 fixture。指定 deck 的操作从 `BOOTSTRAP.md` / playbook 进入，不经过 proposal 分类。 |
| 建议在 `context` 保留“两种工作域”的事实，却没有写明 OpenSpec 的适用边界。 | “双域”若只是一条平行事实，后续 Agent 仍须猜现在是在维护 framework，还是应去运行 deck。最容易发生的错误正是把 `deck_*` 当源码或测试夹具。 | `context` 保留一条短而硬的 scope boundary：OpenSpec 管四个 framework 源码域；`deck_*`、`dpt_*` 和 `_generated/` 是生产/输入数据，只有用户指定 deck 时由 production playbook 消费。完整目录表留在 `AGENTS.md` 或 layout document。 |
| 三份 control policy 的建议只说“按条件路由”，没有指定谁完成实质审查、结论落在哪里。 | 同一段长 policy 现在同时散落在 context、proposal、specs、design 和 tasks。若只把它们搬成数个短 pointer，仍可能出现 proposal、specs、design 各自写一套近似解释，或 Apply 时完全看不到已作出的取舍。 | `proposal` 只登记触发的 policy 与风险/authority owner；`design` 是 gate/control/quality policy 的主审查和证据 owner；`specs` 只在行为契约确实变化时定义可观察的 outcome/invariant；`tasks` 只落实已决定的实现和 proof，不重新复述 policy。 |
| 本文把完整 capability 表“移至 capability index”说得太轻。 | 如果 index 需要人工维护，它会成为 `openspec/specs/` 之外第二份 capability registry，和本项目“main spec 是当前行为权威”的原则冲突。 | 优先让 `openspec/specs/<capability>/spec.md` 保持唯一权威；如确实需要快速发现入口，index 必须是从 specs 生成或只含路径链接的薄索引，不能复制责任、schema 或行为描述。 |
| “run-bundle 的真实执行入口放到 playbook/AGENTS/schema apply instruction”仍混合了两条流程。 | `schema apply.instruction` 只适用于 framework change 的 Apply；它不会也不应成为用户制作某个 deck 的入口。 | production routing 归 `AGENTS.md` + `BOOTSTRAP.md` + MD controller/playbook；framework Apply 的固定实施约束才考虑 schema `apply.instruction`。两者不要共用一个“执行入口”表述。 |

### 建议采用的路由形状

```text
用户指定 deck，要生产或迭代 PPT
  -> BOOTSTRAP.md / AGENT_CONTRACT.md / 当前 controller playbook
  -> run-bundle state、Gate 与生成物规则拥有事实
  -> 不创建 OpenSpec planning artifacts

要修改 framework 的持久行为、contract、CLI、controller 或测试
  -> OpenSpec proposal
  -> 记录 framework 源码范围、control owner、run-bundle compatibility impact
  -> specs 定义改变的 observable contract
  -> design 完成 policy review 与验证取舍
  -> tasks 落实实现、迁移和 proof
```

这里不是否认 run bundle 的重要性。相反，框架 change 只要会读、写、解释或迁移 run-bundle contract，就应把它写入 proposal/design；区别在于它是**受影响的 runtime contract**，不是 OpenSpec workflow 中与 framework maintenance 对等的工作域。

### 三份 policy 的正确承接

三份 canonical policy 都应离开全局 `context` 的长正文，但不能只留下“遇到相关情况请阅读”的口号。推荐的分工如下：

| 阶段 | 应留下的最小信息 |
|---|---|
| proposal | 此 change 是否触发 `human-centered-gates`、`agent-assistance-and-control`、`simple-reliable-control`；涉及的 direct authority、control owner 与 protected runtime contract。 |
| specs | 仅当改变行为契约时，定义 `guide` / `confirm` / `hard-stop` 的可观察结果、protected invariant 或 deterministic contract；不复制 CLI schema，也不把 policy prose 当 requirement。 |
| design | 在一个简短 `## Control-policy review` 中，说明适用 policy 的实际选择：outcome/invariant、direct Source of Record、最短 evaluator/recovery path、用户/Agent/JS 的责任、以及新增控制面删除或合并了什么。 |
| tasks | 从 design 拆出实现、迁移、negative test 和验证任务；不要要求实施者重新读 policy 后自行决定另一套 owner 或 recovery path。 |

若希望这个 review 每次稳定出现，应更新 proposal/design template；仅在 config 中写一条长 rule 不能保证有一致的 evidence landing，也不能在 Apply 时自动重现。

### 对 `config.yaml` 的具体改写建议

下面的形状刻意不复制 policy 正文，也不在 config 中编排 deck production。它只让正确的 planning artifact 在 framework change 中加载正确的判断标准。

```yaml
context: |-
  这是 Markdown-first 的 Agentic PPT framework：MD Controller / Agent 拥有流程与创意判断，
  JS / CLI 拥有确定性解析、校验、状态、证据和诊断，人类拥有内容与风险判断。
  OpenSpec 只管理 framework maintenance 的源码域；deck_*、dpt_* 与 _generated/ 是运行时生产/输入数据。
  指定 deck 的生产从 BOOTSTRAP.md、AGENT_CONTRACT.md 与当前 controller playbook 进入；
  framework change 的当前行为以 openspec/specs/<capability>/spec.md 为准。

rules:
  proposal:
    - >
      Framework maintenance proposal 必须列出源码范围、MD/JS/MD⇔JS protocol control owner，
      以及对 run-bundle contract 的 none / compatible / migration impact；不得把 production deck
      当源码、夹具或待自动迁移对象。若涉及 gate、control path 或 quality control，记录触发的
      canonical policy 与 design.md 必须完成的 review。

  design:
    - >
      当 change 涉及 gate/readiness/validation/override、controller/state/recovery/diagnostic，
      或新的/修改的 quality-control path 时，读取对应 openspec/policies/*.md，并在 design.md
      的 `## Control-policy review` 记录：direct Source of Record、outcome/invariant、最短合法
      evaluator/recovery path、human/Agent/JS responsibility，以及新增控制面删除、合并或避免的复杂度。
      具体 schema、CLI 字段和 permission 仍以 owning capability spec 为准。

  tasks:
    - >
      tasks 必须把 design 已决定的 contract migration、implementation、focused negative coverage
      和验证证据落为可验收动作；不得重新创造 competing authority、recovery path 或 waiver semantics。
```

这样修改后，`config.yaml` 给每个 framework change 的设计过程提供了足够早的 policy 提醒，却不会把一整套 controller/run-bundle 操作规则重复注入 proposal、specs、design、tasks，更不会误导 Agent 在真正制作 PPT 时先走 OpenSpec。
