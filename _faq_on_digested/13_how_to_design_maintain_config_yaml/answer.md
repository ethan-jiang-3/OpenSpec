# 答案：让 config.yaml 在正确阶段给出正确指导

## 一句话

把 `config.yaml` 当成**项目 profile + artifact-specific / operation-specific guidance**，不要当成项目百科或运行时控制器。真正的阶段化上下文主要由 schema 的 artifact DAG 和 change artifacts 承担：proposal 记录分类和决定，specs/design 直接读取 proposal 并分别细化行为与技术后果，tasks 再读取 specs/design，Apply 最后读取当前已有的实际 artifacts；再把 project context 与 Apply/Archive guidance 明确路由到两个 operation。

## 先拆掉一个错误前提

当前原生机制不是“每个阶段都读 config”：

| 阶段 | 实际上下文来源 | `context` / `rules` 是否自动出现 |
|---|---|---|
| Explore | skill、`list/status`、按需读文件 | 是：读取 project `context` 与 artifact `rules`；没有 `operations.explore` |
| proposal/specs/design/tasks | instructions + schema + dependency artifacts | 是，分别为全局 context 与当前 artifact rules |
| apply | generated Apply instructions：schema `apply.instruction`、`contextFiles`、task progress、project context、`operations.apply.guidance` | 是：context + apply guidance；不是 artifact rules |
| archive | workflow、status、tasks、delta specs、archive instructions | 是：context + `operations.archive.guidance`；不是 artifact rules |

所以长 context 的坏处不只是 token 多：它把 apply/runtime/Explore 专属知识交给了不需要它的 artifact，同时没有保证真正需要它的阶段收到。

## A. 已确认的机制边界

这不是一份待执行的研究计划。内置 `spec-driven` 的 config 消费路径已经汇总在 [`07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)；root/store 等通用诊断则由 [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md) 与 [`sources.md`](sources.md) 索引。设计和诊断时必须接受以下边界：

| 事实 | 对配置决策的影响 |
|---|---|
| `rules` 只进入 `openspec instructions <artifact>` | rules 只能服务 planning artifacts，不能当作所有阶段的通用 guidance。 |
| `context` 进入 artifact instructions，也进入 Apply/Archive；operation guidance 进入对应 operation | Apply/Archive 的稳定项目步骤可写入 `operations.apply/archive.guidance`；结构 gate 仍归 schema，单次事实仍归 artifacts/tasks。 |
| Explore 读取 context/rules；Sync 没有 config operation guidance；Archive 读取 archive operation inputs | 不存在 `operations.explore` / `operations.sync`；更复杂专属行为仍归 workflow skill、`AGENTS.md`、playbook 或 checker。 |
| `schema` 在 new change 时会被写入 change 的 `.openspec.yaml` | 修改项目默认值不会迁移已在进行的 change。 |
| `store` 是 root 选择机制，不是 guidance 字段 | 先确认命令最终选中了哪个 root，再判断正在编辑的 config 是否会被读取。 |

因此，排查顺序也应固定为：**生效 root -> 生效 schema -> 目标消费者 -> rendered instructions -> artifacts / deterministic check**。跳过其中任一步，通常只会继续向 `context` 增加无效正文。

## B. 由机制推导出的 config 设计与维护方法

### 信息应该去哪

```text
稳定、短、全局的背景事实           -> config.context
一个 artifact 的长期写作约束        -> config.rules.<artifact>
Apply 的稳定项目步骤                -> config.operations.apply.guidance
Archive 的稳定项目步骤              -> config.operations.archive.guidance
一个 change 的范围、分类、决定      -> proposal / specs / design / tasks
新的 artifact、依赖、apply 行为      -> schema.yaml / workflow skill
必须强制且可验证的不变量            -> checker / test / CI
跨团队上游规格                       -> config.references
当前运行状态                         -> state / receipt / run 文件
```

对每句话先问：谁消费、在何时消费、是否需要在 artifact 中留痕、是否应由机器证明。答案会自然决定位置。

### language context 的落点

`openspec init --language "<language>"` 只是把一条语言偏好写入**新项目**的 `config.context`。因此它会被 artifact instructions 消费，也会随 project context 到达 Apply/Archive；它不是 schema 字段、翻译引擎或结构本地化开关。已有 config 时 init 拒绝覆盖，应手工合并到现有 context。artifact prose 可本地化，但结构 heading 与 `SHALL`/`MUST` 保持英文，确保 parser/validator 契约不变。

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

在内置 `spec-driven` 中，specs/design 会直接收到 proposal；tasks 只直接收到 specs/design，不会自动收到 proposal；Apply 的 `contextFiles` 则包含当前已有的各类 artifacts。因此必须让 specs/design 把分类落实成各自负责的合同、决定和证据要求，再让 tasks 具体化，而不是期待 Context Card 自动穿透整个 DAG，或让每一步重新从全局 context 猜测。

## 三个项目特定案例（非通用结论）

[`project-cases/`](project-cases/README.md) 保存的是对 Deep Research Tool、Agentic PPT workflow 与 DeerFlow Deep Research 三个具体项目的审计，不是三套通用基线。以下判断只描述这些项目当时呈现的配置与 runtime boundary；其他项目只能借鉴“识别 consumer、owner、阶段和 evidence，再决定归位”的方法，不能复制其路径、policy、Gate、命令、capability 或结论。

在这三份特定配置中，rules 已经包含很多高质量、artifact-specific 的约束；共同需要审查的是长 `context` 是否混入了：

- proposal/design 才适用的长政策；
- 单次 change 应记录的分类与决定；
- apply/runtime 的实际操作说明；
- 应由 registry/checker/CI 保证的硬规则；
- 完整目录树和 capability 索引等按需才需读取的资料。

处理方式不是删掉治理意图，而是将其改为：短 profile、artifact rule、canonical policy 指针、change context card、schema/playbook 或确定性检查。对这三个项目的源码边界复核结果是：Deep Research Tool 与 Agentic PPT workflow 属于 B1，DeerFlow Deep Research 属于 B2；这是案例结论，不代表其他 research、PPT、DeerFlow、LangGraph 或 Agentic 项目具有相同控制边界。

## 何时不该继续改 config

- 要让 apply 始终收到项目 guidance：用 `operations.apply.guidance`；要改它的 gate/结构再改 custom schema 的 `apply.instruction`。
- 要让 Archive 收到短稳定 guidance：用 `operations.archive.guidance`；Explore 没有对应 operation 字段，复杂步骤仍改 workflow skill、`AGENTS.md` 或 playbook。
- 要增加前置分类/审查阶段：fork schema，新增 artifact 与 dependency。
- 要不可绕过：写 checker/test/CI。
- 要新的 `guidance` / `stage_context` 选择器：先实现并验证 OpenSpec 功能；当前随意添加的未知 YAML key 不会产生该能力。

## 维护节奏

每次 archive 后回顾 agent 被重复纠正的点。只有它跨多个 future changes、能定位到明确 consumer、可写成可判断动作、且不应该由其他层承担时，才升级为 config rule 或 operation guidance。改动后用代表性 change 的 `openspec instructions <artifact> --json` 逐个检查 rules 注入，并单独检查 `openspec instructions apply --json` 与 `openspec instructions archive --json`，确认 context/guidance 出现在正确 operation。

## 延伸材料

- 从下游项目类型选择初稿：[`00-initial-config-baselines.md`](00-initial-config-baselines.md)
- 信息归位与 rule 设计：[`01-design-config-yaml.md`](01-design-config-yaml.md)
- 配置不生效、schema 切换与维护：[`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)
- 三个项目特定案例及其适用边界：[`project-cases/README.md`](project-cases/README.md)
- 源码深挖与阶段路由证据：[`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)
- 源码与材料索引：[`sources.md`](sources.md)
