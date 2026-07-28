# 阶段化上下文下，如何设计与维护 `config.yaml`

## 结论先行

不要把 `config.yaml` 当作“任何阶段都能拿到一切知识”的容器。当前 OpenSpec 原生提供的是：

```text
所有 artifact 的稳定背景       -> context
单个 artifact 的长期指导       -> rules[artifactId]
一次 change 的事实、分类和决定 -> proposal / specs / design / tasks
workflow 阶段与 apply 行为     -> schema.yaml / workflow skill
必须可靠成立的规则             -> checker / test / CI
```

这样才能让信息在需要时出现、在需要留痕时写入 artifact、在必须强制时由确定性机制负责。将这些东西混进全局 `context`，即使内容完全正确，也会造成注意力稀释、重复、错误的执行时机和不可验证的“软约束”。

## 先理解当前能力边界

### 原生注入面

| 配置字段 | 当前实际消费者 | 适合装什么 | 不适合装什么 |
|---|---|---|---|
| `schema` | 新 change 的默认 schema 解析 | 默认 workflow 选择 | 项目指导文字 |
| `context` | `openspec instructions <artifact>` | 所有 artifact 都需要的短、稳定项目 profile | 一次 change、阶段专用政策、运行时步骤 |
| `rules.<artifact>` | 对应 artifact 的 instructions | 该 artifact 的长期判断约束 | `apply` / `archive` / `explore` 的专用流程 |
| `references` | artifact/apply instructions | 上游 store 的 spec 索引与按需 fetch 路由 | 把上游正文完整塞进 prompt |
| `store` | root resolution | 外置 planning store 指针 | 上下文或规则 |

默认 `spec-driven` 的合法 `rules` key 是 `proposal`、`specs`、`design`、`tasks`。`apply` 不是 artifact key；写 `rules.apply` 会产生 unknown-artifact warning，且不会注入 apply instructions。

### 特别容易误判的阶段

```text
explore     不自动读取 context/rules；它是 workflow skill 的对话/探索姿态
proposal    得到 context + rules.proposal + schema instruction
specs       得到 context + rules.specs + proposal dependency
design      得到 context + rules.design + proposal dependency
tasks       得到 context + rules.tasks + specs/design dependencies
apply       得到 schema apply instruction + 现有 artifacts 的 contextFiles；不带 context/rules
archive     主要由 archive workflow 读取 status/tasks/specs；不带 context/rules
```

这张图是设计配置前的硬前提。尤其不要把“apply 时必须遵守”只放进 `rules.tasks`，也不要把“Explore 时必须调查”只放进 `context`。

## 信息放置的决策树

对准备写进 config 的每一句话，按下面顺序判断：

```text
它是否必须被确定性地强制或证明？
  是 -> test / lint / validator / CI；artifact/task 只记录如何运行它
  否 -> 它是否改变 artifact、依赖、gate 或 apply 行为？
          是 -> schema.yaml / workflow skill
          否 -> 它是否只属于一个 change？
                  是 -> proposal / specs / design / tasks
                  否 -> 它是否只服务一个 artifact？
                          是 -> config.rules.<artifact>
                          否 -> 它是否是所有 artifact 都要知道的稳定短背景？
                                  是 -> config.context
                                  否 -> canonical guide / playbook，由目标 rule 指向
```

另有两个横向情况：跨团队的上游需求用 `references`；单次执行的状态放显式 state/run 文件，绝不放 config。

## 推荐的信息架构

| 层 | 所有者 | 生命周期 | 典型内容 |
|---|---|---|---|
| 0. 可执行事实 | validator/test/CI | 长期 | schema 合法性、registry 一致性、测试门槛 |
| 1. 工作流结构 | schema / skill | 长期 | artifact DAG、template、apply gate、Explore/Archive 行为 |
| 2. 项目 profile | `config.context` | 长期 | 项目本质、核心 domain、稳定 ownership、最高质量优先级 |
| 3. Artifact guidance | `config.rules.<id>` | 长期 | 该 artifact 的触发条件、动作、证据/权威来源 |
| 4. Change context card | proposal/specs/design/tasks | 单个 change | scope、分类、适用政策、取舍、风险、验证计划 |
| 5. 上游规格发现 | `config.references` | 长期但可更新 | store ID、按需读取的 spec 索引 |
| 6. Runtime state | run/state/receipt 文件 | 短期 | 当前 phase、gate verdict、任务进度、产物 receipt |

其中第 4 层是“不同阶段拿到准确上下文”的主力。proposal 先把这次 change 的分类和适用政策写下来；下游 artifact 通过 DAG dependency 读取 proposal；tasks 继续把实施和验证细化；apply 再读取所有实际 artifact。它比全局 prompt 更可追溯，也不会让下游重新猜测。

## 一个足够小的原生配置形状

以下是结构示例，不是要求逐字照抄：

```yaml
schema: spec-driven

context: |-
  Product: <what this project is>
  Stable ownership: <who decides intent / who owns deterministic checks>
  Quality priorities: <two or three enduring priorities>
  Authority: behavior is owned by openspec/specs; implementation truth is owned by code and tests.
  Vocabulary: <only terms every planning artifact must understand>

rules:
  proposal:
    - Before proposing, inspect existing main specs and state the change classification, affected capability owners, and non-goals.
    - When <trigger>, read <canonical policy>; record the resulting decision and source in the proposal.

  specs:
    - Model observable behavior in the owning capability; do not copy another capability's producer contract.
    - When <trigger>, state the owner, invariant, and required scenario in the delta spec.

  design:
    - For <trigger>, compare the chosen owner/source of truth with the rejected alternative and record migration or recovery implications.

  tasks:
    - Turn every required validation, migration, and acceptance obligation into a verifiable task with its command or evidence target.
```

`context` 的目标是让人可以在一屏内看懂“这是哪类项目、什么不可混淆、优先什么”；不是充当项目百科。没有原生的字数建议阈值，但 50KB 是硬上限，且超限时整个 context 字段被忽略。实践上应远低于这个上限。

## Rule 的写法：短、可触发、能留痕

一个有效 rule 通常具备四个部分：

```text
触发条件 -> 必须动作 -> 权威来源 -> 证据/落点
```

例如：

```text
当 change 改动 gate、readiness 或 override 时，阅读 openspec/policies/human-centered-gates.md；
在 proposal 中记录 guide/confirm/hard-stop 分类、被保护的不变量和需要人类决定的部分。
```

相比“遵守 gates 最佳实践”，这条 rule 明确了谁在什么情况下做什么，以及结论应该出现在哪个 artifact。

### 重复指针，不重复正文

OpenSpec 没有 `proposal+design` 这种 group scope。若同一政策只影响 proposal 和 design，正确的原生做法是：

```yaml
rules:
  proposal:
    - When a change alters a control path, read openspec/policies/control.md and record scope and ownership.
  design:
    - When a change alters a control path, read openspec/policies/control.md and record evaluator, recovery, and tests.
```

两处重复的是一个短路由，不是几十行政策正文。正文只保留在 `openspec/policies/control.md` 的 canonical source 中。

这也避免两个样例中已经出现的漂移风险：同一套 Evolution / Gate / Control 原则分别在 context、rules、specs 和操作文档中被改写，最终很难知道哪个版本有效。

## 用 change context card 路由条件化知识

当项目有多个工作域，例如“framework maintenance”与“run-bundle production”，不要让每个后续 artifact 从全局 context 推断当前属于哪个域。应在 proposal 中显式记录：

```markdown
## Change Context Card

- Change class: framework maintenance | run-bundle production
- Affected capability owners: ...
- Applicable policies / guidance packs: ...
- Authoritative sources read: ...
- Non-goals / excluded domains: ...
- Required verification evidence: ...
```

随后：

```text
proposal   产出分类与路由决定
specs      读取 proposal，只写实际改变的行为合同
design     读取 proposal，展开适用的技术/控制政策
tasks      读取 specs + design，将验证和执行具体化
apply      读取这些真实 artifacts，不依赖全局 config 回忆
```

如果这张 card 每次都必要，应该 fork `spec-driven` schema 并把它写进 proposal template，而不是长期依赖 agent 自觉添加。

## 大段 guidance 的“指针包”模式

建议把长政策和领域指南作为项目内可版本控制文档，例如：

```text
openspec/
  policies/
    gates.md
    control-paths.md
    verification-routing.md
  guidance/
    run-bundle-production.md
    framework-maintenance.md
    capability-index.md
```

然后从目标 artifact 的 rule 指向它。这样带来三个好处：

1. 每次只加载当前阶段真正需要的文档。
2. 正文可以有自己的 owner、版本、目录和 review 节奏。
3. 当 policy 变化时不必同时修改 `context`、多个 rule 和 generated artifact。

注意：当前 OpenSpec 不会因为 rule 里出现路径就自动读取该文件；这是对 agent 的明确指令。若某指南必须被系统级、确定性地加载或验证，应升级到 schema/skill/CLI 能力，不要把“请阅读”误当成强制机制。

## 什么时候必须离开 config

### 需要 apply 专属指导

把稳定的 apply 行为写到 custom schema 的 `apply.instruction`；把一次 change 的实际实施细节写进 tasks/design。`rules.tasks` 不会被 apply instruction 再次注入。

### 需要 Explore 或 Archive 专属指导

更新相应 workflow skill、项目 `AGENTS.md` / playbook，或建立明确的检查清单。Explore/Archive 当前没有 `context`/`rules` 的自动消费通路。

### 需要新的决策阶段或真实依赖

fork schema，新增 artifact 和 `requires` 关系。例如把高风险 change 的 intake/classification 变成独立 artifact，让 design/tasks 依赖它。只有 schema 才能让这个顺序成为 workflow contract。

### 需要规则不可被忽略

写 checker、测试或 CI。例如 requirement registry、spec 结构、verification assets 都应由机器检查；rule 的任务是让 agent 早些生成正确的 evidence，不是替代检查。

### 不要伪造不存在的 YAML 字段

当前解析器只会提取支持的字段。随意添加：

```yaml
stage_context:
guidance:
shared_rules:
apply_rules:
```

不会得到阶段化能力，且未知顶层字段可能被静默忽略。若要产品化“guidance packs”，应先创建 OpenSpec change，设计并实现解析、selector 校验、instruction 输出、size budget、诊断和测试；不能先把未来 API 写进项目 config。

## 多 schema / schema 迁移的维护规则

1. `config.schema` 是新 change 的默认值；已有 change 的 `.openspec.yaml` schema 优先级更高。改 config 不会迁移正在进行的 change。
2. `rules` 按当前 change 的 schema artifact IDs 校验。一个项目并行使用多个 schema 时，某 schema 专属的 key 在另一个 schema 的 instructions 中会 warning，且不注入。
3. 因此切换 schema 前先盘点 active changes；在旧 change 完结或迁移前，不要假定一份全局 rules 能无噪声地服务两套不兼容 artifact ID。
4. `context`/`rules` 是下次 instructions 调用立即生效的 prompt 输入，不会回写已经生成的 proposal/spec/design/tasks。需要改变历史 artifact 的结论时，应显式更新相应 change，而不是只改 config。

## 维护循环

### 什么时候审计

| 时机 | 问题 | 可能动作 |
|---|---|---|
| 新项目 / 新 schema 前 | 哪些是全局事实，哪些是 workflow contract？ | 建最小 profile，先不写百科 |
| Explore 或 proposal 前 | 这次发现的是项目级模式，还是 change 局部信息？ | 局部信息写 proposal；反复模式进入候选清单 |
| 每次 archive 后 | agent 被重复纠正的点是什么？ | 满足 promotion test 才加 rule |
| schema / 项目架构变更后 | artifact IDs、authority、目录或 apply 行为是否变了？ | 校对 rules keys、guidance 指针、context 摘要 |
| 出现提示不遵守 / 质量问题后 | 是规则写得弱、位置错、还是需要机器验证？ | 按根因移动而非加更多正文 |

### Rule promotion test

只有同时满足这些条件，才把一次经验提升为 config rule：

1. 跨多个未来 change 仍成立。
2. 有清楚的目标 artifact 或所有 artifact 都需要它。
3. 可以写成可判断的触发条件和动作。
4. 不会替代更适合的 spec、schema、state 或 deterministic check。

### 每次修改后的最小验证

1. 对当前 schema 列出 artifact IDs，并确认每个 `rules` key 合法。
2. 对一个代表性 change 运行 `openspec instructions proposal|specs|design|tasks --change <name> --json`，确认只出现预期的 `context` / `rules`。
3. 运行 `openspec instructions apply --change <name> --json`，确认关键 apply guidance 已经来自 schema/artifacts，而不是误以为 config 会注入。
4. 检查 stderr 没有 YAML 解析、50KB、unknown artifact ID 等 warning。
5. 对硬规则运行对应 checker/test/CI；不以“prompt 已出现”作为验收证据。

## 给两个样例的具体收缩顺序

不建议一次性重写。按以下顺序可控地迁移：

1. 从各自 context 提取不超过一屏的项目 profile；其余内容先保留在原有 canonical docs。
2. 为每条长政策确定唯一 canonical source；删掉 context 中的正文，替换为必要 artifact 的短指针。
3. 在 proposal 中加入 change classification / applicable guidance / source-of-record 的留痕，先让下游有准确路由。
4. 将 requirements、verification、registry 等不可协商规则与现有 checker 对齐；缺 checker 的部分列为单独 change。
5. 处理 apply / runtime 规则：转入 tasks、schema `apply.instruction`、playbook 或 runtime validator。
6. 选取三个代表性 change（普通、跨模块、控制路径或 run-bundle）试跑，记录实际漏项和多余注入，再收紧规则。

这比“把所有好的话继续补进 context”慢一小步，但会得到更稳定、更可解释的上下文路由。
