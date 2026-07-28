# 两份 config.yaml 的归位审计（进行中）

> 目的不是批评两份配置“写得太长”，而是识别每段信息的正确所有者、消费时机和验证方式。行号指向用户提供的两份样例；“建议去处”是设计方向，最终应由项目实际文件结构确认。

## 判定口径

| 信息性质 | 首选去处 | 原因 |
|---|---|---|
| 所有 artifact 都需知道、跨 change 稳定且很短的背景事实 | `config.context` | 原生会对每个 artifact 注入 |
| 只影响一个 artifact 的长期写作/审查约束 | `config.rules.<artifact>` | 原生有精确 injection scope |
| 影响多个但非全部 artifact 的详细政策 | 各目标 `rules` 中保留一条短指针；正文放 canonical policy | 原生没有 artifact group scope；重复“指针”优于重复“正文” |
| 某个 change 的动机、分类、取舍、风险、适用政策 | proposal/specs/design/tasks | DAG dependency 会把它在正确时机传给下游 |
| workflow 节点、artifact 次序、apply 固定行为 | custom `schema.yaml` / workflow skill | `config` 无法定义结构，也不会自动指导 explore/archive；apply 不消费 context/rules |
| 必须成立的规则或归档前检查 | validator/test/lint/CI + task 中的明确验证动作 | 提示不能替代确定性证据 |
| 跨团队上游 spec 的发现 | `references` + `openspec show ... --store ...` | 当前实现只注入索引，按需读取正文 |
| runtime/run 的短期状态 | 显式 state/run 文件 | config 是项目级长期配置，不是跨 tool-call state |

## 样例一：Deep Research Tool

来源：`/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml`。

### Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 项目一句话、Agent / Engine / 文件的基本分工 | 4-10 | 跨 artifact 的稳定理解，值得保留；当前细节可压缩。 | `context`，保留为 5-8 行 profile |
| 核心原则与 JS/MD 边界 | 12-21、30-44 | 其中“谁拥有决策”是背景；具体错误处理、env/routing 规则不是所有 artifact 都需要。 | context 留 ownership 摘要；详细边界移至 charter；proposal/design rules 用条件化指针 |
| 技术栈及允许依赖 | 23-28 | 对 design/tasks 有强影响，对 proposal/specs 价值较低。 | `rules.design` / `rules.tasks`；context 只留一句技术栈摘要 |
| Evolution Directions | 51-60 | 明确标为 proposal/design 评审顺序，却在所有 artifact 注入，是典型作用域错配。 | `rules.proposal`、`rules.design`；完整正文留在现有 guidelines |
| 命名规范 | 62-65 | UI 语言/路径语言可能全局；capability prefix 与 bundle 命名是条件性规则。 | context 只留全局语言约定；capability 命名进 proposal/specs；bundle 命名进 design/tasks 或 runtime playbook |
| Requirement Traceability | 67-77 | 每条要求有不同消费者：分配 ID、写 spec header、写实现标记、收尾检查。 | proposal / specs / tasks 各自短 rule；registry 与 checks 保持 canonical；可执行检查继续承担验证 |
| Governance 工具与 registry 组织细则 | 79-91 | 详细的登记格式不是 proposal、design、tasks 都需要。 | `rules.specs` / `rules.tasks` 的指针；正文只留 registry 文档/validator |
| Verification routing | 93-109 | 是 change-level verification policy；“本次计划”应该进入 change 的 `verification-plan.yaml` 和 tasks。 | proposal 触发创建计划；tasks 生成具体动作；分类定义留 policy/checker，不进 context |
| 实验体系 | 111-128 | 主要面向 experiment/run 的设计与实施，不是所有 spec artifact 的背景。 | policy/runbook；相关 design/tasks rule 指针；必要硬约束交给 supervisor/engine |
| 根目录与 framework/bundle 详细地图 | 130-165 | 有少量全局导向价值，但完整树是静态索引，重复注入性价比低。 | context 保留 3-5 条 root/ownership 摘要；完整地图放 README/charter |

### Rules 归位

现有规则已经比 context 更接近正确的注入位置，建议是**压缩重复内容并增强“触发 → 动作 → 留痕”的清晰度**，不是把它们再次全部搬走。

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（168-177） | 能明确语言、source、capability、版本等长期约束。 | 多条与 context 的 Evolution Directions 重复；不同 change 类型适用性不同。保留摘要和明确路径，详细政策转为短指针。 |
| `design`（178-183） | 技术栈、状态机、source-of-record 非常适合 design。 | “只能用依赖”应是项目硬约束的同时有 package/test 支撑；不要只靠 rule。 |
| `tasks`（184-200） | done condition、依赖排序、requirement ID、收尾验证都能转化为可读任务。 | apply 本身不重新注入 config；必须让生成出的 `tasks.md` 写出收尾验证，且由 CI/checker 复核。 |
| `specs`（201-227） | Capability / requirement 的约束有明确 artifact owner。 | 主 spec 结构与 ID 格式最好由现有 governance checker 保障；长的边界测试可从 inline rule 移为 policy 指针。 |

### 可行的渐进收缩目标

1. 将 `context` 缩成“项目 profile + ownership + 最高优先级”摘要，不复制流程、目录树、检查器细节。
2. 每个 artifact 保留 3-6 条真正稳定的 rule；一条 rule 最好能回答“何时触发、做什么、在哪留下证据”。
3. 用 proposal 中的 change classification 记录是否涉及 framework、version、experiment、verification plan；下游 artifacts 从 proposal 读这一结论。
4. 将不可协商的 registry / spec / verification 规则继续放入 checker，而非视 config 为执行保证。

## 样例二：Agentic PPT workflow

来源：`/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml`。

### Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 项目本质与控制面所有权 | 4-19 | 是项目最重要的稳定模型，但可以更短。 | `context`：保留 Markdown-first、MD/JS/human ownership 摘要 |
| 工作域与对象边界 | 20-45 | “framework maintenance vs run-bundle production”是 proposal 需要的 change classification；详细目录/读法不需要每次注入。 | context 留双域事实；proposal rule 要求分类和记录；详细 map 放 charter/layout docs |
| 权威源与查找顺序 | 46-61 | 有用的 source-of-record 索引，但 full table 应按任务需求读取。 | context 留总原则 + 入口；proposal/specs/design rules 指向相关 authority docs |
| 技术栈与运行时铁律 | 62-77 | 技术栈是稳定背景；禁止的生产路径主要是 design/tasks 约束。 | context 仅栈/主入口；design/tasks rules 或 executable check 承担细则 |
| CLI 失败回执 | 78-90 | 只与 CLI / controller protocol 变更相关。 | `rules.design`（条件触发）+ `cli-surface` / `node-specification` spec；不放 context |
| Gates、Agent control、simple reliable control | 91-126 | 是重要但条件化的政策；当前对所有 artifact 全量投放会淹没普通 PPT change。 | proposal/specs/design rules 加“涉及 X 时读 Y”的短指针；完整政策留在 `openspec/policies/` |
| Capability 注册表和完整 capability 表 | 127-173 | 它是 proposal/specs 做归属判断的索引，不是所有 stages 的背景。 | proposal/specs rules 指向 `openspec/specs/`；由实际 main specs 作为权威；完整表可移至 capability index |
| Workflow 术语、生产语义、refresh paths | 174-200 | 专属 run-bundle production / implementation 的知识。 | proposal 先分类；run-bundle design/tasks guidance pack；不是 context |
| Agent 入口与 OpenSpec 开发循环 | 201-212 | 这是行动 playbook。尤其 apply/explore 不自动读 context，放在这里不能保证实际执行者看见。 | `AGENTS.md` / playbook / schema `apply.instruction`；change 的 tasks 写明实际步骤 |

### Rules 归位

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（215-247） | 非常清楚地维护 proposal 的信息密度、capability 契约、change domain 和 control owner。 | 八条长规则承载了三种 change class 和三条 policy；建议变为基础 rule + 条件化 policy-pointer，分类结果写入 proposal。 |
| `specs`（248-277） | 对 delta、owner、archive safety、gate semantics 的要求具体。 | 能力名和 canonical vocabulary 不应仅靠 context；实际 main specs / glossary 应为 source。只让有相关风险的 spec 加载对应 policy。 |
| `design`（278-303） | owner、验证策略、migration、gate/recovery 都是 design 的正确职责。 | 很多条只在 framework control path 变化时适用；把 trigger 前置，避免常规视觉/文案改动承受不相关的控制语言。 |
| `tasks`（304-325） | 覆盖变化、依赖顺序、tests、gate-sensitive tasks，有可执行性。 | 仍要注意 apply 不会加载这些 config rules；任务必须在生成时具体化，强制部分需有 tests/checks。 |

### 可行的渐进收缩目标

1. `context` 只保留“项目是何物、两种工作域、谁拥有决策、去哪里找权威”的短导航。
2. 将 gate/control/quality 三套长政策改成 canonical 文档；在 proposal/specs/design 中仅留下有触发条件的阅读与留痕要求。
3. 把 framework-maintenance / run-bundle-production 分类作为 proposal 的显式输出，而不是让每个后续 artifact 从全局 context 自行猜测。
4. run-bundle 的真实执行入口和 gate 规则放入 playbook / `AGENTS.md` / schema apply guidance；不要期待 config 在实际 apply 中出现。

## 跨样例的共同结论（暂定）

两份 config 的问题不是“规则太严格”，而是把下面四类信息混在同一段全局 prompt 中：

```text
稳定背景       <-> 具体写作指导
项目长期政策   <-> 单个 change 的分类/决定
Agent 提示     <-> 可执行/可验证的约束
artifact 生成  <-> explore/apply/archive/runtime 的操作说明
```

拆分后，应让“短导航”留在 `context`，让“artifact-specific 判断”进入 `rules`，让“change classification 与决定”进入 artifact，让“runtime/确定性约束”回到真正拥有它的 schema、playbook、state 或 checker。
