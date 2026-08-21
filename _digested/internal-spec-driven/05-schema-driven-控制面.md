# 05 - spec-driven schema 控制面

本文只讨论仓库内置的 [`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml)，不把自定义 schema 的可能性混入默认工作流的事实描述。它回答的是：四个 artifact 如何组成 DAG、什么时候被视为完成，以及独立的 Apply block 实际约束什么。

`config.yaml` 的字段、root 选择和阶段注入边界由 [`07-config-yaml-上下文路由源码深挖.md`](07-config-yaml-上下文路由源码深挖.md) 负责。这里先把 schema 的结构契约钉牢，避免把 schema、config 和 workflow skill 的职责混成一个“控制器”。

## 1. 先固定四个 artifact

内置 `spec-driven` schema 只有四个 artifact ID：

| Artifact ID | 产物 | 直接依赖 | 主要职责 |
|---|---|---|---|
| `proposal` | `proposal.md` | 无 | 说明为什么改、改什么、涉及哪些 capability 与影响面。 |
| `specs` | `specs/**/*.md` | `proposal` | 记录可观察、可验证的需求 delta。 |
| `design` | `design.md` | `proposal` | 记录实现方法、技术决定、风险与迁移。 |
| `tasks` | `tasks.md` | `specs`、`design` | 把实现拆成可追踪、可验证的 checkbox。 |

v1.10.0 把“可验证”具体化为：每个 checkbox 自身写 test、command、observable behavior 或 delivered artifact；跨多个实现项的验证才另列 Integration Verification。这仍是 schema instruction，不是 validator 的逐项质量硬校验。

`apply` 不是第五个 artifact。它是 schema 中与 `artifacts` 并列的独立 block，因此：

- `rules.proposal`、`rules.specs`、`rules.design`、`rules.tasks` 才是这个 schema 的合法 artifact rules。
- `rules.apply` 无效；Apply 的稳定 instruction 来自 `schema.apply.instruction`。
- Explore、Sync 和 Archive 也不是 artifact ID，不能通过同名 `rules` 获得指导。

v1.7.0 还要区分 schema instruction 和项目 operation input：`context` 会进入 Apply/Archive，`operations.apply.guidance` 与 `operations.archive.guidance` 分别提供这两个 operation 的项目级指引；它们不改变 schema 的 DAG 或 apply hard gate。

## 2. schema 拥有什么，不拥有什么

把 `schema.yaml` 称为控制面是有边界的。它是 artifact DAG 与 Apply contract 的声明源，不是整个 OpenSpec 生命周期的全部源码。

| schema 直接拥有 | schema 不直接拥有 |
|---|---|
| artifact ID、输出 pattern、description | 项目级 `context`、`rules`、`references` |
| artifact 的 `requires` 依赖边 | change 中已经写下的业务决定 |
| 每个 artifact 的 instruction 与 template 路径 | Explore、Propose、Apply、Sync、Archive skill 的步骤 |
| Apply 的直接前置项、tracking file 与 instruction | artifact 内容的完整语义质量与项目硬约束 |

结构定义由 [`src/core/artifact-graph/types.ts`](../../src/core/artifact-graph/types.ts) 的 `ArtifactSchema`、`ApplyPhaseSchema` 和 `SchemaYamlSchema` 约束；加载时，[字符解析与结构验证](../../src/core/artifact-graph/schema.ts) 还会拒绝重复 artifact ID、无效的 artifact `requires` 引用和循环依赖。

模板决定输出骨架，instruction 决定生成时的语义指导。二者必须一起读：

- [`templates/proposal.md`](../../schemas/spec-driven/templates/proposal.md)
- [`templates/spec.md`](../../schemas/spec-driven/templates/spec.md)
- [`templates/design.md`](../../schemas/spec-driven/templates/design.md)
- [`templates/tasks.md`](../../schemas/spec-driven/templates/tasks.md)

## 3. 真实 DAG 不是文件中的箭头文案

`schema.yaml` 的 description 写作 `proposal -> specs -> design -> tasks`，artifact 的声明顺序也是 `proposal`、`specs`、`design`、`tasks`。但真正控制 ready/blocked 的只有每个 artifact 的 `requires`：

```text
             +-> specs --+
proposal ---+            +-> tasks
             +-> design -+
```

因此当前结构是：

1. 初始只有 `proposal` ready。
2. `proposal` 完成后，`specs` 与 `design` 同时 ready。
3. `specs` 与 `design` 都完成后，`tasks` ready。

[`ArtifactGraph.getBuildOrder()`](../../src/core/artifact-graph/graph.ts) 使用 Kahn 拓扑排序；v1.7.0 对同级 ready artifact 按 schema 声明顺序稳定排序。因此它给当前 schema 的确定性推荐总序是：

```text
proposal -> specs -> design -> tasks
```

这只是合法拓扑序，不表示 `design` 依赖 `specs`。要区分三个概念：

- **声明顺序**：YAML 中列出的 `proposal, specs, design, tasks`。
- **依赖偏序**：`proposal` 后 `specs/design` 可并行，二者之后才是 `tasks`。
- **CLI 的确定性展示/选择顺序**：同级 ready 的 `specs` 在 `design` 前，因为内置 schema 的声明顺序如此。

### 当前 schema 内部的两个张力

第一，`design.instruction` 要求“Reference the proposal for motivation and specs for requirements”，但 `design.requires` 只有 `proposal`。生成 design instructions 时，`dependencies` 不会把 change specs 当成硬依赖；虽然内置推荐顺序会先显示 specs，agent 仍不能把这种顺序提示当成 DAG 保证。

第二，`design.instruction` 写着“create only if any apply”，但 `tasks.requires` 固定包含 `design`。在当前 DAG 中，不创建 `design.md` 就无法让 `tasks` 进入 ready，因此 design 实际上是结构必需项。

维护 schema 前应先决定目标语义：

- 若希望 specs 与 design 并行，应修改 description 和 design instruction，不要让 design 假设 change specs 已存在。
- 若希望严格 `proposal -> specs -> design -> tasks`，应让 `design.requires` 包含 `specs`，并补相应图与 workflow 测试。
- 若 design 真正可选，当前 schema 数据模型没有 conditional artifact；不能只靠 instruction 中的“可选”实现结构可选。

## 4. 完成判定只是文件存在

[`detectCompleted()`](../../src/core/artifact-graph/state.ts) 遍历四个 artifact，并通过 [`resolveArtifactOutputs()`](../../src/core/artifact-graph/outputs.ts) 判断输出是否存在：

| Artifact | 当前 done 条件 |
|---|---|
| `proposal` | `proposal.md` 是文件。 |
| `specs` | `specs/**/*.md` 至少匹配一个文件。 |
| `design` | `design.md` 是文件。 |
| `tasks` | `tasks.md` 是文件。 |

这里没有内容质量、数量完整性或依赖闭包验证：

- 空文件也会让对应 artifact 变成 done。
- proposal 声明多个 capability 时，一个 specs 文件就足以让 `specs` 变成 done。
- 手工先创建下游文件，会直接把下游标为 done；completion detector 不会因上游缺失而撤销这个状态。

`getNextArtifacts(completed)` 和 `getBlocked(completed)` 只约束“尚未完成的 artifact 现在是否可创建”，不会证明已存在文件是按 DAG 顺序、按 instruction 或按 template 产生的。

Archive 的 validation 也不能被概括成“保证四个 artifact 的内容质量”：[归档实现](../../src/core/archive.ts)对 proposal 的问题只作非阻塞提示，重点阻塞 delta specs 的结构错误；未完成 tasks 可经确认继续，design 没有通用语义 validator。需要不可绕过的不变量时，仍要使用项目自己的 checker、test、lint 或 CI。

## 5. artifact instructions 的四层与依赖交接

创建 artifact 时，[`generateInstructions()`](../../src/core/artifact-graph/instruction-loader.ts) 组装四个 authoring layers：

| 层 | 来源 | 对 spec-driven 的作用 |
|---|---|---|
| `context` | `openspec/config.yaml` | 同样注入四个 artifact 的稳定项目背景。 |
| `rules` | `config.rules[artifactId]` | 只注入当前 `proposal/specs/design/tasks` 的长期约束。 |
| `instruction` | `schema.yaml` 当前 artifact | 说明该 artifact 应表达什么。 |
| `template` | `schemas/spec-driven/templates/*.md` | 给出输出结构骨架。 |

`dependencies` 和 `references` 也会出现在完整 instruction payload 中，但它们不是上述四层的同类信息：

- `dependencies` 来自 schema 的直接 `requires`，负责把本次 change 已完成的上游 artifact 路由给下游。
- `references` 来自 project config，负责提供外部 store specs 的只读发现索引。
- `specs` artifact 的 main-spec 路径根来自 instruction payload 的 `planningHome.root`。MODIFIED 读取和既有 Purpose 直编都使用 `<planningHome.root>/openspec/specs/<capability-path>/spec.md`；这不等于 references 自动 retrieval。

当前四个 artifact 的直接 dependency payload 是：

```text
proposal.dependencies = []
specs.dependencies    = [proposal]
design.dependencies   = [proposal]
tasks.dependencies    = [specs, design]
```

它不会自动展开传递依赖。例如 `tasks.dependencies` 没有 `proposal`；proposal 中的重要分类必须先被 specs/design 继承，或由执行者按 change artifacts 的整体上下文读取。

`rules` 只属于 artifact instructions，不会因为 schema 中有 Apply block 就自动进入 Apply。v1.7.0 的 project `context` 会进入 Apply/Archive，额外 operation guidance 放在 `operations.apply/archive.guidance`；完整阶段边界见 [`07-config-yaml-上下文路由源码深挖.md`](07-config-yaml-上下文路由源码深挖.md)。

## 6. Apply block 的精确语义

### no-spec schema 的实例 marker

若解析后的 schema 根本不产生 specs artifact（路径归一化后没有 `specs/` 下的输出），v1.10.0 的 `openspec new change` 会自动在 `.openspec.yaml` 写 `skip_specs: true`。识别会统一 `./specs/`、`specs/` 与 Windows separator，避免同一输出因写法不同被误判。由此产生的 specs 状态是 `skipped`；schema 作者无需伪造 specs artifact，也无需手写 marker。若 schema 实际产生 specs，或 change 后来发生 spec-level 行为变化，则不能用 marker 绕过真实 delta。

内置 schema 的 Apply block 是：

```yaml
apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
    Pause if you hit blockers or need clarification.
```

[`generateApplyInstructions()`](../../src/commands/workflow/instructions.ts) 对它的消费方式如下：

1. 读取 project `context` 与 `operations.apply.guidance`，并只直接检查 `apply.requires` 中的 `tasks` 输出是否存在。
2. 读取 `tasks.md` 的 checkbox，计算 total、complete 与 remaining。
3. 收集 schema 中**所有已经存在**的 artifact 输出，形成 `contextFiles`。
4. 有待办任务且前置条件成立时，使用 `apply.instruction`；缺 artifact、缺 tracking file、没有 checkbox 或全部完成时，返回相应的诊断/结束 instruction。

“正常生成路径”与“硬保证”必须分开：

- 正常路径中，`tasks` 只有在 specs/design done 后才 ready，所以通常四个 artifact 都已存在。
- Apply 实现本身只检查 `tasks`，不会计算其传递依赖闭包。若有人手工创建了含 checkbox 的 `tasks.md`，缺少 proposal/specs/design 不一定使 Apply blocked，`contextFiles` 也只包含实际存在的文件。
- `apply.requires` 是可用性 gate，不是 artifact 语义 validator，也不证明实现正确。

因此，不应把“`apply.requires: [tasks]`”表述成无条件保证四个 artifact 都完整。更准确的说法是：DAG 的正常 authoring 路径要求先完成上游，而 Apply 当前直接以 `tasks` 和 tracking file 作为准入检查。

## 7. schema 名称被固定，不等于 schema 内容被快照

创建 change 时，[`createChange()`](../../src/utils/change-utils.ts) 把解析出的 schema **名称**写入 `.openspec.yaml`；后续 [`resolveSchemaForChange()`](../../src/utils/change-metadata.ts) 优先使用这个名称。因此修改 `config.schema` 不会让已有 change 自动切换到另一个 schema 名称。

但 `.openspec.yaml` 没有保存 `schema.yaml` 内容、hash 或 version。每次命令仍通过 [schema resolver](../../src/core/artifact-graph/resolver.ts) 读取当前同名 schema：

```text
project-local spec-driven
  -> user override spec-driven
  -> package built-in spec-driven
```

所以“已有 change 锁定 schema”只应理解为**锁定名称**：

- 修改 `config.schema`：已有 change 仍选择 metadata 中的 `spec-driven`。
- 修改或覆盖同名 `spec-driven/schema.yaml`：已有 change 的 DAG/instructions 可能随当前解析结果变化。
- `version: 1` 目前不是 change metadata 中的内容快照。

本文的结构结论专指仓库内 [package built-in 文件](../../schemas/spec-driven/schema.yaml)。诊断实际项目时，仍要确认没有同名的 project/user override；具体步骤见 `07`。

## 8. 修改 spec-driven 前的验证清单

1. 四个 artifact ID、输出 pattern 和 template 是否仍一一对应。
2. description、instruction 与真实 `requires` 是否表达同一顺序和可选性。
3. `getBuildOrder()`、`getNextArtifacts()`、`getBlocked()` 的预期是否有图测试。
4. 每个 done 条件是否只需要文件存在；需要更强保证时，validator 在哪里。
5. `apply.requires` 是否表达直接 gate；是否需要额外检查传递依赖闭包。
6. `apply.tracks` 与 tasks template 的 checkbox 格式是否一致。
7. artifact instructions、status 与 Apply JSON 的契约测试是否一起更新。
8. `config.rules` 仍只使用 `proposal`、`specs`、`design`、`tasks`。

## 9. 关键源码

| 主题 | Primary source |
|---|---|
| 内置四 artifact 与 Apply contract | [`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml) |
| 四个输出模板 | [`schemas/spec-driven/templates/`](../../schemas/spec-driven/templates/proposal.md) |
| schema 数据结构 | [`src/core/artifact-graph/types.ts`](../../src/core/artifact-graph/types.ts) |
| schema 解析与图合法性 | [`src/core/artifact-graph/schema.ts`](../../src/core/artifact-graph/schema.ts) |
| DAG 查询与拓扑排序 | [`src/core/artifact-graph/graph.ts`](../../src/core/artifact-graph/graph.ts) |
| 文件存在式 completion | [`src/core/artifact-graph/state.ts`](../../src/core/artifact-graph/state.ts)、[`outputs.ts`](../../src/core/artifact-graph/outputs.ts) |
| artifact instruction 与 status | [`src/core/artifact-graph/instruction-loader.ts`](../../src/core/artifact-graph/instruction-loader.ts) |
| Apply instruction、tracking 与 contextFiles | [`src/commands/workflow/instructions.ts`](../../src/commands/workflow/instructions.ts) |
| schema 名称选择与 change metadata | [`src/utils/change-metadata.ts`](../../src/utils/change-metadata.ts)、[`change-utils.ts`](../../src/utils/change-utils.ts) |
| 同名 schema 的解析优先级 | [`src/core/artifact-graph/resolver.ts`](../../src/core/artifact-graph/resolver.ts) |
| Archive 的实际 validation 边界 | [`src/core/archive.ts`](../../src/core/archive.ts) |
