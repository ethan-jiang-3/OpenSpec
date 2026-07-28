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

## A. 已确认的机制边界

这不是一份待执行的研究计划。源码深挖已经汇总在 [`07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)，它给出设计和诊断时必须接受的边界：

| 事实 | 对配置决策的影响 |
|---|---|
| `context` 与 `rules` 只进入 `openspec instructions <artifact>` | 它们只能服务 planning artifacts，不能当作所有阶段的通用 guidance。 |
| Apply 只收到 schema 的 `apply.instruction`、change artifacts、tasks/progress 和可选 references | apply 必须遵守的稳定规则要进入 schema；本次实施事实要进入 artifacts/tasks。 |
| Explore、Sync、Archive 不调用 artifact instructions | 这些阶段的专属行为要进入 workflow skill、`AGENTS.md`、playbook 或 checker。 |
| `schema` 在 new change 时会被写入 change 的 `.openspec.yaml` | 修改项目默认值不会迁移已在进行的 change。 |
| `store` 是 root 选择机制，不是 guidance 字段 | 先确认命令最终选中了哪个 root，再判断正在编辑的 config 是否会被读取。 |

因此，排查顺序也应固定为：**生效 root -> 生效 schema -> 目标消费者 -> rendered instructions -> artifacts / deterministic check**。跳过其中任一步，通常只会继续向 `context` 增加无效正文。

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

在写第一版前，再问“下游运行时谁拥有 Flow”：传统程序、MD/Agent 控制 Flow，或程序/Graph 控制 Flow。这个分类决定 project profile 应描述哪张 authority map；它不是新的 config 字段。两种混合模型的边界和初稿分别见 [`00-initial-config-baselines.md`](00-initial-config-baselines.md)。

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

## 三个样例的核心问题

三个样例的 rules 都已经包含很多高质量、artifact-specific 的约束；问题主要在长 `context` 混入了：

- proposal/design 才适用的长政策；
- 单次 change 应记录的分类与决定；
- apply/runtime 的实际操作说明；
- 应由 registry/checker/CI 保证的硬规则；
- 完整目录树和 capability 索引等按需才需读取的资料。

处理方式不是删掉治理意图，而是将其改为：短 profile、artifact rule、canonical policy 指针、change context card、schema/playbook 或确定性检查。前两个样例是 B1：MD/Agent 控制 Flow；DeerFlow Deep Research 是 B2：graph 拥有 node 顺序、route 和 checkpointed state，智能能力只在 node contract 内工作。因此 B2 配置尤其不能让 prompt、review 或 config 冒充 graph/state/node contract 的运行时权威。

## 何时不该继续改 config

- 要让 apply 始终收到指导：改 custom schema 的 `apply.instruction`。
- 要让 Explore/Archive 遵循专属步骤：改 workflow skill、`AGENTS.md` 或 playbook。
- 要增加前置分类/审查阶段：fork schema，新增 artifact 与 dependency。
- 要不可绕过：写 checker/test/CI。
- 要新的 `guidance` / `stage_context` 选择器：先实现并验证 OpenSpec 功能；当前随意添加的未知 YAML key 不会产生该能力。

## 维护节奏

每次 archive 后回顾 agent 被重复纠正的点。只有它跨多个 future changes、能定位到明确 consumer、可写成可判断动作、且不应该由其他层承担时，才升级为 config rule。改动后用代表性 change 的 `openspec instructions <artifact> --json` 逐个检查注入结果，并单独检查 `openspec instructions apply --json`，不要假设 config 会随 apply 出现。

## 延伸材料

- 从下游项目类型选择初稿：[`00-initial-config-baselines.md`](00-initial-config-baselines.md)
- 信息归位与 rule 设计：[`01-design-config-yaml.md`](01-design-config-yaml.md)
- 配置不生效、schema 切换与维护：[`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)
- Deep Research Tool 审计：[`10-deep-research-tool-config-audit.md`](10-deep-research-tool-config-audit.md)
- Agentic PPT workflow 审计：[`11-agentic-ppt-workflow-config-audit.md`](11-agentic-ppt-workflow-config-audit.md)
- DeerFlow Deep Research 的程序/Graph 控制 Flow 审计：[`12-deerflow-deep-research-config-audit.md`](12-deerflow-deep-research-config-audit.md)
- 源码深挖与阶段路由证据：[`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)
- 源码与材料索引：[`sources.md`](sources.md)
