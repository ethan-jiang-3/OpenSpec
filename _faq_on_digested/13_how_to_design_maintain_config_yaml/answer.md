# 答案：让 config.yaml 在正确阶段给出正确指导

## 一句话

把 `config.yaml` 当成**项目 profile + artifact-specific guidance**，不要当成项目百科或运行时控制器。真正的阶段化上下文主要由 schema 的 artifact DAG 和 change artifacts 承担：proposal 记录分类和决定，specs/design/tasks 通过依赖读取并细化，apply 再读取这些实际 artifacts。

## 先拆掉一个错误前提

当前原生机制不是“每个阶段都读 config”：

| 阶段 | 实际上下文来源 | `context` / `rules` 是否自动出现 |
|---|---|---|
| Explore | skill、`list/status`、按需读文件 | 否 |
| proposal/specs/design/tasks | instructions + schema + dependency artifacts | 是，分别为全局 context 与当前 artifact rules |
| apply | schema apply instruction + `contextFiles` + tasks | 否 |
| archive | workflow、status、tasks、delta specs | 否 |

所以长 context 的坏处不只是 token 多：它把 apply/runtime/Explore 专属知识交给了不需要它的 artifact，同时没有保证真正需要它的阶段收到。

## A. 怎样从 internal-spec-driven 深挖这个问题

不是只重读 `06-config-yaml-机制与约束.md`。要把 `00` 到 `06` 改按“上下文从哪里来、何时被谁消费、何时丢失”重新串起来：

| 材料 | 要追的问题 | 对 config 设计的产出 |
|---|---|---|
| `00-四条命令的共有机制` | `status`、instructions、schema、dependency 各承担什么？ | 画出 workflow × context consumer 矩阵，分清 global prompt 与 artifact handoff。 |
| `01-explore-探索模式` | Explore 是否真的会得到 config 提示？ | 找出 Explore 的空洞，避免把 discovery 指导误放 context。 |
| `02-propose-提案生成` | proposal 如何成为下游 specs/design 的依赖？ | 确认 change classification 和决策应写入 proposal，而不是全局 config。 |
| `03-apply-实施执行` | apply 读什么，没读什么？ | 发现 `context`/`rules` 不会进入 apply；确定 tasks/schema/checker 的正确边界。 |
| `04-archive-归档合并` | archive 靠什么完成验证和同步？ | 将归档纪律放入 tasks/checker/workflow，而不是假设 config 会参与。 |
| `05-schema-driven-控制面` | 什么需求已经超出 config 的表达能力？ | 给出升级阈值：新 artifact、依赖、apply 行为必须进入 schema。 |
| `06-config-yaml-机制与约束` | parser、注入、大小、warning、fail-open 的真实边界是什么？ | 明确 context/rules 能做什么、不能做什么，并以当前源码校正资料版本。 |

深挖的交付物应是四张表，而不只是一篇解释文：

1. **消费表面账本**：每个 command/workflow 实际读取哪些 config 字段。
2. **信息归位审计**：每段规则的 scope、owner、lifetime、evidence 和 canonical source。
3. **fixture 验证矩阵**：用 `instructions proposal/specs/design/tasks/apply --json` 验证真实注入结果。
4. **升级决策表**：什么时候留在 config，什么时候转 artifact、schema、skill 或 checker。

当前仓库源码比已有消化文档多了 `references` 和 `store` 等能力，因此深挖必须以源码复核为准，不能把旧的字段表当成永久 API。完整的工作计划在 [`03-deep-dive-plan.md`](03-deep-dive-plan.md)。

## B. 由机制推导出的 config 设计与维护方法

### 信息应该去哪

```text
稳定、短、全局的背景事实           -> config.context
一个 artifact 的长期写作约束        -> config.rules.<artifact>
一个 change 的范围、分类、决定      -> proposal / specs / design / tasks
新的 artifact、依赖、apply 行为      -> schema.yaml / workflow skill
必须强制且可验证的不变量            -> checker / test / CI
跨团队上游规格                       -> config.references
当前运行状态                         -> state / receipt / run 文件
```

对每句话先问：谁消费、在何时消费、是否需要在 artifact 中留痕、是否应由机器证明。答案会自然决定位置。

## 实际写法

`context` 保留一屏内的项目身份、稳定 ownership、质量优先级和最小术语表。`rules` 只放有明确 artifact owner 的长期判断，每条尽量写成：

```text
触发条件 -> 必须动作 -> canonical source -> evidence / artifact 落点
```

例如，不把完整 gate 政策复制进 context，而是在 `proposal` / `design` 的 rules 中写一条短路由：涉及 gate 时阅读该政策，并在对应 artifact 记录分类、owner、invariant 或 recovery。

当一个政策需要多个 artifact，允许重复**短指针**，不要重复几十行正文。当前 config 没有 `proposal+design` 这样的 group scope。

## 关键的阶段化手法

把 change classification 写进 proposal（或需要时新增早期 schema artifact）：

```text
这次属于什么 change domain？
哪些 capability / source of record 受影响？
哪些 policy 或 guidance pack 适用？
哪些验证证据必须产生？
```

这会让 specs、design、tasks 和 apply 从真实 change artifacts 读取准确结论，而不是每一步重新从全局 context 猜测。

## 两个样例的核心问题

两份样例的 rules 已经包含很多高质量、artifact-specific 的约束；问题主要在长 `context` 混入了：

- proposal/design 才适用的长政策；
- 单次 change 应记录的分类与决定；
- apply/runtime 的实际操作说明；
- 应由 registry/checker/CI 保证的硬规则；
- 完整目录树和 capability 索引等按需才需读取的资料。

处理方式不是删掉治理意图，而是将其改为：短 profile、artifact rule、canonical policy 指针、change context card、schema/playbook 或确定性检查。

## 何时不该继续改 config

- 要让 apply 始终收到指导：改 custom schema 的 `apply.instruction`。
- 要让 Explore/Archive 遵循专属步骤：改 workflow skill、`AGENTS.md` 或 playbook。
- 要增加前置分类/审查阶段：fork schema，新增 artifact 与 dependency。
- 要不可绕过：写 checker/test/CI。
- 要新的 `guidance` / `stage_context` 选择器：先实现并验证 OpenSpec 功能；当前随意添加的未知 YAML key 不会产生该能力。

## 维护节奏

每次 archive 后回顾 agent 被重复纠正的点。只有它跨多个 future changes、能定位到明确 consumer、可写成可判断动作、且不应该由其他层承担时，才升级为 config rule。改动后用代表性 change 的 `openspec instructions <artifact> --json` 逐个检查注入结果，并单独检查 `openspec instructions apply --json`，不要假设 config 会随 apply 出现。

## 延伸材料

- 完整的设计/维护方法：[`02-design-maintain-guide.md`](02-design-maintain-guide.md)
- 两份真实 config 的归位审计：[`01-placement-audit.md`](01-placement-audit.md)
- 如何继续深挖 `internal-spec-driven`：[`03-deep-dive-plan.md`](03-deep-dive-plan.md)
- 持续研究日志：[`00-research-log.md`](00-research-log.md)
- 源码与材料索引：[`sources.md`](sources.md)
