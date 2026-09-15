---
title: "如何设计 config.yaml"
document_kind: "design-guide"
applies_to:
  - "all runtime models after the Flow owner is known"
read_when:
  - "准备新建、收缩或重写 config.yaml，需要决定一段信息该放在哪里。"
  - "需要把长 policy、change-local 决定、Apply 行为或硬约束从 context 中迁出。"
focus:
  - "在 context、rules、change artifacts、schema/workflow、checker/test/CI、references 与 runtime record 之间归位。"
  - "把 rule 写成触发条件、动作、canonical source 与 evidence 落点。"
not_for:
  - "不要用本文首次判定传统、B1 或 B2；先读 00-initial-config-baselines.md。"
  - "不要用本文排查为什么某条配置没有生效；那是 root/schema/instructions 的诊断问题。"
next_read:
  - "配置不生效、schema 切换或多 schema 维护：02-diagnose-maintain-config-yaml.md"
  - "需要观察归位方法如何用于特定项目：project-cases/README.md"
---

# 如何设计 `config.yaml`

本文件面向“新建配置”或“重新归位现有内容”。先用 [`00-initial-config-baselines.md`](00-initial-config-baselines.md) 选择项目运行时基线；这里回答每条稳定信息究竟应放在哪里。默认 `spec-driven` schema 的四个 planning artifacts 是 `proposal`、`specs`、`design` 和 `tasks`，下文出现的 artifact-specific guidance 均先按这四个真实 ID 理解。

## 先接受配置的能力边界

`config.yaml` 不是项目百科，也不是任意阶段都可自由扩展的 guidance router；有明确的 Apply/Archive operation slots：

| 内容 | 正确位置 | 原因 |
|---|---|---|
| 所有 planning artifacts 都需要的短、稳定背景 | `context` | 注入 artifact instructions；也会进入 Apply/Archive operation inputs。 |
| 一个 artifact 的长期写作或审查约束 | `rules.<artifact-id>` | 只会在该 artifact 的 instructions 中出现。 |
| 本次 change 的范围、分类、取舍、风险、验证事实 | proposal / specs / design / tasks | 通过 artifact DAG 在正确时机交给下游。 |
| Apply 的稳定项目步骤 | `operations.apply.guidance` | 与 context 一起进入 `instructions apply`；不改变 schema gate。 |
| Archive 的稳定项目步骤 | `operations.archive.guidance` | 与 context 一起进入 `instructions archive`；不改变 archive CLI 的确定性合并。 |
| Apply 的新 gate、额外 review 节点或新输出结构 | schema / template / workflow skill | operation guidance 是 prompt input，不是结构控制器。 |
| 必须成立的约束 | checker / test / lint / CI / validator | prompt 不能证明或强制结果。 |
| 跨团队上游 spec 的发现 | `references` | 生成可按需读取的索引，而不是内联正文。 |
| 运行中的状态、receipt、授权或进度 | runtime-owned state / record | config 是项目级长期配置。 |

在这个 schema 中，`apply` 是独立的实施阶段，不是第五个 artifact，也不是合法的 rule key。项目使用自定义 schema 时，必须改以它的实际 artifact ID 为准。

## 逐条做归位判断

对准备写进 config 的每一句话，按这个顺序判断：

```text
它是当前运行状态、receipt、授权或进度吗？
  是 -> runtime-owned state / record
  否 -> 它是已注册 store 中上游 spec 的发现入口吗？
          是 -> references；需要时再读取正文
          否 -> 它是否必须被确定性地强制或证明？
                  是 -> owning spec/policy + checker / test / lint / CI；artifact/task 记录影响与证据
                  否 -> 它是否是 Apply/Archive 都只需短稳定指导的 operation 行为？
                          是 -> operations.apply/archive.guidance
                          否 -> 它是否改变 artifact、依赖、gate 或 Apply 行为？
                                  是 -> schema / template / workflow skill
                          否 -> 它是否只属于一个 change？
                                  是 -> proposal / specs / design / tasks
                                  否 -> 它是否只服务一个 artifact？
                                          是 -> rules.<artifact-id>
                                          否 -> 它是否是四个 planning artifacts 都需要的稳定短背景？
                                                  是 -> context
                                                  否 -> canonical guide / playbook，由目标 rule 指向
```

这个顺序的重要性在于：不要用 `context` 填补缺失的 schema、state 或 validator。内容写得正确但消费者不对，仍然不会在需要时出现。

## 设计短而稳定的 project profile

好的 `context` 只回答每个 planning artifact 都需要的四类问题：

1. **项目是什么**：用户面对的产品或稳定 domain 边界。
2. **谁拥有真相**：行为合同、实现、数据、运行时 verdict 分别以什么为权威。
3. **什么长期优先**：例如兼容性、安全、可恢复性、成本或跨平台。
4. **哪些词不能混淆**：所有 artifacts 都会使用的少量术语。

不应放入：一次 change 的目标、完整目录树、长政策正文、完整 API/schema、工具操作手册、运行时状态或只影响 Apply 的步骤。它们会被重复注入给不需要的 artifact，反而掩盖真正重要的背景。

## 让 rule 可触发、可留痕

一个有价值的 rule 应至少能回答：

```text
触发条件 -> 必须动作 -> canonical source -> evidence / artifact 落点
```

例如：

```text
当 change 修改跨平台文件行为时，在 specs 中说明各平台可观察结果与场景；
在 tasks 中加入相应的跨平台验证命令或证据。
```

不要写“保持高质量”“遵守最佳实践”之类没有 consumer、触发条件或证据落点的口号。它们既占用每次 instructions 的注意力，也无法帮助 reviewer 判定是否完成。

### 重复短指针，不重复政策正文

OpenSpec 没有 `proposal+design` 的 group scope。若一套长政策只影响两个 artifacts，允许在两个 rule 中重复短指针：

```yaml
rules:
  proposal:
    - When <trigger>, read <canonical-policy>; record scope and the authority owner.
  design:
    - When <trigger>, read <canonical-policy>; record the chosen control, recovery, and proof.
```

重复的是 routing instruction，不是几十行正文。政策本身应有唯一 canonical source，避免在 `context`、rules、specs 和 playbook 中漂移。

## 用 change context card 路由条件化知识

多个工作域、风险级别或政策包不应让每个后续 artifact 从全局 context 猜测。proposal 应显式留下本次分类：

```markdown
## Change Context Card

- Change class: <domain or risk class>
- Affected capability / authority owners: ...
- Applicable policies: ...
- Authoritative sources read: ...
- Non-goals / excluded domains: ...
- Required verification evidence: ...
```

内置 `spec-driven` 的实际交接链是：

```text
proposal: 保存 Context Card
  -> specs: 读取 proposal，落实行为、capability 与验证后果
  -> design: 读取 proposal，落实技术、owner、风险与证据后果
specs + design
  -> tasks: 读取这两个直接依赖，生成具体实施与验证动作
所有当前已存在的 artifacts
  -> Apply: 通过 contextFiles 读取
```

`tasks` 不直接依赖 `proposal`，所以 Context Card 不会被 CLI 自动穿透注入 tasks instructions。需要交给实施的分类结论，必须先由 specs/design 落成各自负责的合同、决定或证据要求，再由 tasks 具体化；不要指望 tasks 作者重新猜 proposal，也不要把整张 card 原样复制到每个 artifact。若这张 card 对每个 change 都是硬性前置条件，应把它固化到 proposal template，而不是长期依赖 agent 自觉添加。若它需要独立状态、独立审查或不同依赖，再升级为单独的 schema artifact。

## 何时必须离开 config

| 需求 | 正确升级点 |
|---|---|
| Apply 始终需要一项项目稳定指导 | `operations.apply.guidance`；若要改 gate/结构才用 custom schema 的 `apply.instruction` |
| Archive 始终需要一项项目稳定指导 | `operations.archive.guidance` |
| Explore 或 Archive 有专属步骤 | workflow skill、`AGENTS.md`、playbook 或检查清单 |
| 需要新的分类、审查或安全节点 | schema artifact + `requires` |
| 必须保证结构、注册表、权限或验证 | validator / test / CI |
| 需要新的 selector，例如 `operations.explore`、`operations.sync` 或任意未知 key | 先实现 OpenSpec feature 与诊断/测试；现有 operation slots 只有 apply/archive |

项目属于混合智能运行时，不自动意味着必须 fork schema。只有它的 planning lifecycle 真正需要额外 artifact、依赖或 Apply gate 时，schema 才是正确升级点。

## 设计完成前的检查

1. 每条 `context` 都是短、稳定且面向所有 planning artifacts 的事实。
2. 每条 rule 都有当前 schema 中真实存在的 artifact owner。
3. 任何 change-local 决策都已迁出 config，准备由 artifacts 留痕。
4. Apply/Archive 规则只使用 `context` + 对应 `operations.*.guidance`；Explore 只使用 `context` / artifact rules，未假设不存在的 operation slot。
5. 长政策有唯一 source，rules 只保留有条件的短指针。
6. 硬约束有对应的 deterministic owner。

配置已写入却没有生效、需要切换 schema 或维护多个 schema 时，继续阅读 [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)。
