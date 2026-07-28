# 证据索引

本 FAQ 优先以当前仓库源码为机制事实来源；`_digested` 文档用于解释工作流语义和识别需要补充的视角。源码会演进，因此正文尽量以函数名和行为而非脆弱行号引用。

## 当前 OpenSpec 源码

| 来源 | 支撑的结论 |
|---|---|
| [`src/core/project-config.ts`](../../src/core/project-config.ts) | 解析的 `schema`、`context`、`rules`、`references`、`store`；50KB context；逐字段 fail-open；未知顶层字段不会进入返回 config。 |
| [`src/core/artifact-graph/instruction-loader.ts`](../../src/core/artifact-graph/instruction-loader.ts) | `generateInstructions()` 读取 project config，只取全局 context 与当前 `rules[artifactId]`，并校验 rules key。 |
| [`src/commands/workflow/instructions.ts`](../../src/commands/workflow/instructions.ts) | artifact instructions 的渲染顺序；`generateApplyInstructions()` 使用 schema apply instruction、artifacts contextFiles 和 references，但不携带 context/rules。 |
| [`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml) | 默认 artifact DAG、artifact instruction、dependencies、template 与 `apply` 的结构。 |
| [`src/core/templates/workflows/explore.ts`](../../src/core/templates/workflows/explore.ts) | Explore 是 stance；其常规路径使用 `list/status` 和按需 artifact 读取，而不是 artifact instructions 注入。 |
| [`src/core/templates/workflows/apply-change.ts`](../../src/core/templates/workflows/apply-change.ts) | apply skill 要求依据 `contextFiles` 读取 change artifacts。 |
| [`src/core/templates/workflows/archive-change.ts`](../../src/core/templates/workflows/archive-change.ts) | archive 使用 status、tasks、delta specs 的 workflow 行为。 |
| [`src/utils/change-metadata.ts`](../../src/utils/change-metadata.ts) | schema 解析优先级：显式参数 → `.openspec.yaml` → project config → default。 |
| [`src/utils/change-utils.ts`](../../src/utils/change-utils.ts) | new change 对 `config.schema` 的读取与 metadata 固化。 |
| [`src/core/references.ts`](../../src/core/references.ts) | references 组装为 store/spec 索引，按需 fetch，且有独立 50KB rendered index budget。 |
| [`test/core/project-config.test.ts`](../../test/core/project-config.test.ts) | parser 的 references、50KB、warning 和 unknown rule key 行为的回归证据。 |

## 内部消化材料

| 来源 | 用法 |
|---|---|
| [`../../_digested/internal-spec-driven/00-四条命令的共有机制.md`](../../_digested/internal-spec-driven/00-四条命令的共有机制.md) | schema/CLI/agent 分工、四层注入、DAG 和四条命令的共同基础。 |
| [`../../_digested/internal-spec-driven/01-explore-探索模式.md`](../../_digested/internal-spec-driven/01-explore-探索模式.md) | Explore 的位置与边界。 |
| [`../../_digested/internal-spec-driven/02-propose-提案生成.md`](../../_digested/internal-spec-driven/02-propose-提案生成.md) | artifact 生成与 dependency handoff。 |
| [`../../_digested/internal-spec-driven/03-apply-实施执行.md`](../../_digested/internal-spec-driven/03-apply-实施执行.md) | apply gate、contextFiles 与任务追踪。 |
| [`../../_digested/internal-spec-driven/04-archive-归档合并.md`](../../_digested/internal-spec-driven/04-archive-归档合并.md) | archive 的验证、同步与移动语义。 |
| [`../../_digested/internal-spec-driven/05-schema-driven-控制面.md`](../../_digested/internal-spec-driven/05-schema-driven-控制面.md) | schema 是结构性升级路径的依据。 |
| [`../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md`](../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md) | 传统 config 模型、50KB、rules key、fail-open 的消化说明。该文未覆盖当前源码新增的 references/store，需按当前源码复核。 |

## 既有项目内指导

| 来源 | 用法 |
|---|---|
| [`../08_config-yaml-growth/answer.md`](../08_config-yaml-growth/answer.md) | 已有 FAQ 的总入口。 |
| [`../08_config-yaml-growth/answer-expert.md`](../08_config-yaml-growth/answer-expert.md) | context/rules 的强规则、schema 术语和维护节奏。 |
| [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) | config/specs/changes 的基本归位模型。 |
| [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) | 高杠杆、可判断、长期稳定的 rule 写法。 |

## 用户提供的配置样例

| 样例 | 用法 |
|---|---|
| `/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml` | 分析“长全局 context + 已有 artifact rules”的典型。 |
| `/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml` | 分析“多工作域、长政策正文、阶段化/条件化指导”的典型。 |
