# config.yaml 设计与维护：研究日志

> 状态：本轮源码、内部材料和样例审计已完成。此文件保留可复核的中间结论；后续若执行 fixture 实验或实现新的 guidance 能力，在此继续追加证据。

## 研究问题

如何让 OpenSpec 的不同阶段拿到恰当的上下文和指导，而不是把项目知识、阶段规则、一次性决策和运行时信息全部塞进 `openspec/config.yaml` 的全局 `context`？

本轮材料：

- `_digested/internal-spec-driven/`，重点为 `00`、`02`、`03`、`05`、`06`
- 当前 OpenSpec 源码（本仓库 `src/` 和 `schemas/`）
- `/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml`
- `/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml`

## 已确认的机制事实

### 1. 原生 `config.yaml` 不是通用的分阶段上下文系统

当前源码的有效提示面分为：

| 配置面 | 谁读取 | 何时出现 | 作用域 |
|---|---|---|---|
| `schema` | 新 change 的 schema 解析 | `openspec new change` 等 | 工作流选择，不是提示 |
| `context` | artifact instructions | 每次 `openspec instructions <artifact>` | 所有 artifact 相同 |
| `rules[artifactId]` | artifact instructions | 每次 `openspec instructions <artifact>` | 单个 artifact |
| `references` | artifact/apply instructions | 指令生成时 | 跨 store 的 spec 索引，不内联正文 |
| `store` | root resolution | 命令入口 | planning root 指针，不是提示 |

证据：`src/core/project-config.ts` 的解析；`src/core/artifact-graph/instruction-loader.ts` 的 `generateInstructions()`；`src/commands/workflow/instructions.ts` 的 `loadRootConfigContext()`。

其中 `context` 会在每个 artifact 指令中原样重复出现，`rules` 只取 `rules[artifactId]`。因此原生能力是“全局 + 单 artifact”，并没有 `proposal+design`、`planning`、`apply` 或某个条件分支的共享 rule scope。

### 2. 工作流本身已经提供了比 config 更精细的上下文路由

`spec-driven` 的 DAG 是：

```text
proposal
  ├── specs ──┐
  └── design ─┴── tasks ──> apply
```

- `specs`、`design` 的 instructions 会列出 `proposal` 为 dependency。
- `tasks` 会得到 `specs` 和 `design` 的 dependency。
- apply instructions 会列出所有已生成 artifact 的 `contextFiles`，让实施者按 change 读取。

这意味着“一次 change 的动机、范围、被选方案、风险、未决项”应优先固化在 proposal/specs/design/tasks 中，通过 dependency/context-files 路由；它们不应回填为全局 `context`。

证据：`schemas/spec-driven/schema.yaml`；`src/core/artifact-graph/instruction-loader.ts`；`src/commands/workflow/instructions.ts` 的 `generateApplyInstructions()`；`_digested/internal-spec-driven/02-propose-提案生成.md` 和 `03-apply-实施执行.md`。

### 3. Apply 是一个容易被忽略的空洞

当前 `generateApplyInstructions()` 只携带 schema 的 apply instruction、任务状态、artifact `contextFiles` 和可选 `references`。它**不读取或返回**项目 `context` / `rules`。

所以把“实施时必须遵守”的长期规则只写进 `rules.tasks` 或全局 `context`，并不能保证 `/opsx:apply` / `openspec instructions apply` 会收到它。应根据规则的性质：

- 能由实现任务表达的，进入 `tasks.md`；
- 是 apply 行为本身的固定流程约束的，进入 schema 的 `apply.instruction`（需要 schema 演进）；
- 是代码仓库的真实硬约束的，交给测试、lint、CI、validator 或项目规范的明确读取路径。

证据：`src/commands/workflow/instructions.ts` 中 `GenerateApplyInstructionsOptions`、`generateApplyInstructions()` 和 `printApplyInstructionsText()`。

### 4. Explore / archive 也不会自动消费 `context` 与 `rules`

Explore 是一个 stance；其 skill template 使用 `openspec list/status` 和按需读取已有 artifacts，没有调用 `openspec instructions <artifact>`。Archive skill 也主要读取 status、tasks 和 specs。两者没有把 config 的提示字段自动注入自己的机制。

因此“Explore 阶段该思考什么”或“Archive 前必须做什么”不能假设由 `config.yaml` 承担。它们要么写进对应 workflow skill/schema，要么由显式的项目 playbook、checklist 或可执行检查承担。

证据：`src/core/templates/workflows/explore.ts`、`apply-change.ts`、`archive-change.ts`。

### 5. `_digested/internal-spec-driven/06` 仍有价值，但并非当前字段全集

`06-config-yaml-机制与约束.md` 正确解释了传统的 `schema` / `context` / `rules` 模型、50KB 上限和 fail-open 行为；但它所依据的较早源码没有覆盖当前的 `references` 与 `store` 字段。最终指南会把“稳定的核心机制”和“当前源码新增能力”明确分开，避免把消化材料当成永久 API 全貌。

## 两个样例的初步观察

| 样例 | 初步结构问题 | 不是问题的部分 |
|---|---|---|
| Deep Research Tool | 全局 `context` 约 160 行，混放项目定位、架构边界、技术栈、治理流程、实验操作、目录地图、生命周期检查；许多内容只与 proposal/design/tasks 或特定 runtime 有关，却会重复注入每个 artifact。 | 对 proposal/design/tasks/specs 分别配置的 rule 已经表达了 artifact 层差异，且含有可判断的项目约束。 |
| Agentic PPT workflow | 全局 `context` 约 210 行，混放产品本质、领域词汇、流程阶段、生产/框架双域、gate/validation 细则；结果是 proposal 与 specs 也要处理大量只与 run-bundle 或 apply 有关的信息。 | artifact rules 的主题大多具有针对性，适合作为拆分后继续保留的候选。 |

逐块归位审计、重复点和迁移方向已写入 [`01-placement-audit.md`](01-placement-audit.md)。

## 当前工作假设（待验证，不是结论）

问题不主要是 context 太长，而是**信息的作用域、生命周期和执行者没有被建模**。写入任何一句前，应先回答：

1. 它是跨所有 change、还是只属于一个 change？
2. 它应影响哪一个 artifact / phase？
3. 它是背景事实、写作指导、输出契约、决策记录，还是可验证的不变量？
4. 谁需要它：proposal 作者、spec 作者、设计者、实施者、归档者、还是 deterministic engine？
5. 它是否必须在 artifact 中留痕并可复核？

预期的归属优先级：

```text
可执行/可验证不变量       -> test / lint / validator / CI
工作流结构或 apply 行为    -> schema.yaml / workflow skill
某 artifact 的长期写作约束 -> config.rules[artifact]
所有 artifact 都需的稳定事实 -> config.context
单个 change 的事实与决策   -> proposal / specs / design / tasks
跨团队上游规格发现         -> config.references + 按需 fetch
一次执行的临时状态         -> change / runtime 的显式状态文件，不进 config
```

本轮已用样例逐项审计和当前源码能力边界交叉验证；后续 fixture matrix 将把这些源码结论进一步变成可重复的 CLI 观测记录。

## 待完成清单

- [x] 核实 `config.yaml` 的当前解析和 instructions 注入路径
- [x] 核实 artifact DAG、依赖路由与 apply 的 context 行为
- [x] 对两个样例逐段分类、找出重复/冲突/误放的信息
- [x] 从 `_digested/internal-spec-driven` 提取“维护时机”和“变更影响”洞察
- [x] 输出可执行的设计/维护指南、审计表和渐进迁移计划
- [x] 用源码与已有 FAQ 交叉复核最终文档
- [ ] 按 `03-deep-dive-plan.md` 建立隔离 fixture matrix，实测每个 command 的 JSON routing contract

## 本轮校验记录

- 新 FAQ 的相对 Markdown 链接已全部解析成功。
- `git diff --check` 通过；未发现新增空白错误。
- 尝试运行 `pnpm test -- test/core/project-config.test.ts test/utils/change-metadata.test.ts`，但当前工作区未安装 `vitest`，因此没有执行测试；未尝试安装依赖或改变环境。
