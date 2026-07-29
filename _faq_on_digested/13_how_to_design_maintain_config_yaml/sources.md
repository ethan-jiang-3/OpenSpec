# 证据索引

本 FAQ 优先以当前仓库源码为机制事实来源；`_digested` 文档用于解释工作流语义和识别需要补充的视角。源码会演进，因此正文尽量以函数名和行为而非脆弱行号引用。

## 当前 OpenSpec 源码

| 来源 | 支撑的结论 |
|---|---|
| [`src/core/project-config.ts`](../../src/core/project-config.ts) | 解析的 `schema`、`context`、`rules`、`operations`、`references`、`store`；`config.yaml` 优先于 `.yml`；50 KiB context；逐字段 fail-open；未知顶层字段不会进入返回 config。 |
| [`src/core/artifact-graph/instruction-loader.ts`](../../src/core/artifact-graph/instruction-loader.ts) | `generateInstructions()` 读取 project config，只取全局 context 与当前 `rules[artifactId]`，并校验 rules key。 |
| [`src/commands/workflow/instructions.ts`](../../src/commands/workflow/instructions.ts) | artifact instructions 的渲染顺序；Apply/Archive instructions 使用 schema/artifacts 与 operation input：project context、`operations.apply/archive.guidance`；artifact rules 仍只属于 artifact instructions。 |
| [`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml) | 默认 artifact DAG、artifact instruction、dependencies、template 与 `apply` 的结构。 |
| [`src/core/templates/workflows/explore.ts`](../../src/core/templates/workflows/explore.ts) | Explore 是 stance；其常规路径使用 `list/status` 和按需 artifact 读取，同时读取 project context/rules；没有 Explore operation guidance。 |
| [`src/core/templates/workflows/apply-change.ts`](../../src/core/templates/workflows/apply-change.ts) | apply skill 要求依据 `contextFiles` 读取 change artifacts。 |
| [`src/core/templates/workflows/archive-change.ts`](../../src/core/templates/workflows/archive-change.ts) | archive 使用 status、tasks、delta specs 和 `instructions archive` 的 workflow 行为。 |
| [`src/utils/change-metadata.ts`](../../src/utils/change-metadata.ts) | schema 解析优先级：显式参数 → `.openspec.yaml` → project config → default。 |
| [`src/utils/change-utils.ts`](../../src/utils/change-utils.ts) | new change 对 `config.schema` 的读取，以及 schema 名称写入 metadata 的行为。 |
| [`src/core/root-selection.ts`](../../src/core/root-selection.ts) | `store:` 仅对 config-only 目录充当 pointer；本地 planning shape 优先，pointer 配置字段不会成为有效项目配置。 |
| [`src/commands/schema.ts`](../../src/commands/schema.ts) | `schema init --default` 当前写入 `defaultSchema`，而它不是有效 project config 字段。 |
| [`src/core/references.ts`](../../src/core/references.ts) | references 组装为 store/spec 索引，按需 fetch，且有独立 50 KiB rendered index budget。 |
| [`test/core/project-config.test.ts`](../../test/core/project-config.test.ts) | parser 的 references、50 KiB、warning 和 unknown rule key 行为的回归证据。 |

## 内部消化材料

| 来源 | 用法 |
|---|---|
| [`../../_digested/internal-spec-driven/00-四条命令的共有机制.md`](../../_digested/internal-spec-driven/00-四条命令的共有机制.md) | schema/CLI/agent 分工、四层注入、DAG 和四条命令的共同基础。 |
| [`../../_digested/internal-spec-driven/01-explore-探索模式.md`](../../_digested/internal-spec-driven/01-explore-探索模式.md) | Explore 的位置与边界。 |
| [`../../_digested/internal-spec-driven/02-propose-提案生成.md`](../../_digested/internal-spec-driven/02-propose-提案生成.md) | artifact 生成与 dependency handoff。 |
| [`../../_digested/internal-spec-driven/03-apply-实施执行.md`](../../_digested/internal-spec-driven/03-apply-实施执行.md) | apply gate、contextFiles 与任务追踪。 |
| [`../../_digested/internal-spec-driven/04-archive-归档合并.md`](../../_digested/internal-spec-driven/04-archive-归档合并.md) | archive 的验证、同步与移动语义。 |
| [`../../_digested/internal-spec-driven/05-schema-driven-控制面.md`](../../_digested/internal-spec-driven/05-schema-driven-控制面.md) | 内置 `spec-driven` 的四 artifact、真实 DAG、文件存在式 completion 与 Apply gate 边界。 |
| [`../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md`](../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md) | 传统 config 模型、50KB、rules key、fail-open 的消化说明。该文未覆盖当前源码新增的 references/store，需按当前源码复核。 |
| [`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md) | 内置 `spec-driven` 的四 artifact DAG、workflow × config consumer 边界、schema 名称固定与 Apply/contextFiles 行为；本 FAQ 的主要机制补充。 |

## 既有项目内指导

| 来源 | 用法 |
|---|---|
| [`../08_config-yaml-growth/answer.md`](../08_config-yaml-growth/answer.md) | 已有 FAQ 的总入口。 |
| [`../08_config-yaml-growth/answer-expert.md`](../08_config-yaml-growth/answer-expert.md) | context/rules 的强规则、schema 术语和维护节奏。 |
| [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) | config/specs/changes 的基本归位模型。 |
| [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) | 高杠杆、可判断、长期稳定的 rule 写法。 |

## 用户提供的项目特定样例

这些来源只支撑对应项目的审计，不支撑可直接套用的 `config.yaml` 建议。其他项目必须重新验证自己的 Flow owner、artifact consumer、runtime contract 和确定性证据。绝对路径仅用于在当前机器定位原始项目，在其他 workspace 中可能不存在。

| 项目 | 项目说明 | 来源与对应审计 |
|---|---|---|
| Deep Research Tool | 证据支撑、多波次、带 Gate 的 Agentic research framework；Agent/Markdown flow 负责研究与语义判断，JavaScript Engine 负责 schema、状态、receipt 和确定性 Gate。 | `/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml`；[`10-deep-research-tool-config-audit.md`](project-cases/10-deep-research-tool-config-audit.md) |
| Agentic PPT workflow | Agent/Markdown controller 负责演示文稿的内容、视觉判断和流程推进，JavaScript/CLI 负责解析、校验、状态、证据与 Gate；包含 framework maintenance 和 run-bundle production。 | `/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml`；[`11-agentic-ppt-workflow-config-audit.md`](project-cases/11-agentic-ppt-workflow-config-audit.md) |
| DeerFlow Deep Research | 基于 DeerFlow 2.1 的下游深度研究产品；`agent/` 为主要实现，Python `StateGraph`、typed state 和 node contract 拥有主要运行时控制边界。 | `/Users/bowhead/ai_deerflow_deep_research/openspec/config.yaml`；[`12-deerflow-deep-research-config-audit.md`](project-cases/12-deerflow-deep-research-config-audit.md) |
