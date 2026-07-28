# 07 - 内置 spec-driven 的 config.yaml 上下文路由（源码深挖）

> 范围：本文只讨论仓库随包发布的 [`schemas/spec-driven/`](../../schemas/spec-driven/)；不展开自定义 schema、`store:` 根指针或无关 workflow。Explore 与 Archive 只用于划定 config 注入边界。源码基线为 `af94ff8`。这里的“内置 `spec-driven`”特指最终解析到 package source 的那一份 schema，而不只是名字恰好叫 `spec-driven`。

四个 artifact 的结构契约、完成判定和 Apply gate 由 [`05-schema-driven-控制面.md`](05-schema-driven-控制面.md) 集中解释；本文在该基础上只追踪 `config.yaml` 的消费者与阶段边界。

## 结论先行

内置 `spec-driven` 只有四个 planning artifact，ID 必须写成：

1. `proposal`
2. `specs`
3. `design`
4. `tasks`

`apply` 不是第五个 artifact，而是 schema 中独立的执行阶段配置。因而 `config.yaml` 的合法 `rules` key 只有 `proposal`、`specs`、`design`、`tasks`；`rules.apply`、`rules.explore`、`rules.archive` 都没有消费者。四个 artifact 与 `apply` block 的权威定义都在 [`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml)；schema 类型也把 `artifacts` 与可选的 `apply` 定义为两个不同字段（[`SchemaYamlSchema`](../../src/core/artifact-graph/types.ts)）。

`config.yaml` 也不是覆盖所有阶段的通用提示词路由器：

- `context` 与 `rules.<artifact-id>` 只进入 `openspec instructions <artifact>`。
- `references` 进入 `openspec instructions <artifact>` 和 `openspec instructions apply`，但只是实时生成的上游 spec 索引，不内联 spec 正文。
- Apply 从 change 中已有的四类 artifact 生成 `contextFiles`，并使用 schema 的 `apply.instruction`；它不接收 config `context` 或 `rules`。
- Explore 与 Archive 不调用 artifact/apply instructions，因而三者都不会被自动注入。

上述调用边界由 [`instructionsCommand()`、`applyInstructionsCommand()` 与 `loadRootConfigContext()`](../../src/commands/workflow/instructions.ts) 共同决定；`references` 的“索引而非正文”契约在 [`assembleReferenceIndex()`](../../src/core/references.ts) 中实现。

## 1. 先确认你真的在使用内置 schema

`schema: spec-driven` 是一个**解析名称**，不是“钉死 package 文件”的语法。`getSchemaDir()` 的优先级是：

```text
<project-root>/openspec/schemas/spec-driven/
    > user data dir/schemas/spec-driven/
    > package/schemas/spec-driven/
```

所以项目或用户目录中的同名 schema 会遮蔽本文研究的内置版本。该顺序由 [`getSchemaDir()` 与 `resolveSchema()`](../../src/core/artifact-graph/resolver.ts) 实现，并由 [`resolver.test.ts`](../../test/core/artifact-graph/resolver.test.ts) 覆盖。维护本文所述配置前，先从实际 OpenSpec project root 运行：

```bash
openspec schema which spec-driven --json
```

只有输出的 `source` 为 `package` 时，后文的四 artifact、DAG、template 和 Apply 契约才完全成立。`schema which` 当前以 `process.cwd()` 作为 project root，所以不能在任意子目录运行后把结果当成 resolved-root 证明；命令本身的实现与 shadow 检测见 [`getSchemaResolution()`](../../src/commands/schema.ts)。

## 2. 四个 artifact 的真实 DAG

`schema.yaml` 顶部描述使用了 `proposal → specs → design → tasks` 的线性简写，但 `requires` 定义的真实 DAG 是：

```text
                 ┌────────> specs ────────┐
proposal ────────┤                        ├────> tasks ────> Apply gate
                 └────────> design ───────┘       requires      requires
                                                   both          tasks
```

也就是说，`proposal` 完成后，`specs` 和 `design` **同时 ready**；`design` 并不依赖 `specs`。`ArtifactGraph.getNextArtifacts()` 只检查直接 `requires`，`getBuildOrder()` 用排序后的 Kahn 队列产生确定顺序（[`graph.ts`](../../src/core/artifact-graph/graph.ts)）。对当前 ID 而言，拓扑输出实际是 `proposal, design, specs, tasks`；`status` 又按这个顺序输出 artifact（[`formatChangeStatus()`](../../src/core/artifact-graph/instruction-loader.ts)）。集成测试也明确断言 proposal 完成后 ready 集合为 `design` 与 `specs`（[`workflow.integration.test.ts`](../../test/core/artifact-graph/workflow.integration.test.ts)）。

### 每个 artifact 的直接依赖与产物

| Artifact ID | `generates` / template | schema `requires` | `instructions <artifact>` 返回的直接 `dependencies` | 完成后直接解锁 |
|---|---|---|---|---|
| `proposal` | `proposal.md` / [`proposal.md`](../../schemas/spec-driven/templates/proposal.md) | `[]` | `[]` | `design`, `specs` |
| `specs` | `specs/**/*.md` / [`spec.md`](../../schemas/spec-driven/templates/spec.md) | `[proposal]` | `proposal -> proposal.md` | 等 `design` 也完成后解锁 `tasks` |
| `design` | `design.md` / [`design.md`](../../schemas/spec-driven/templates/design.md) | `[proposal]` | `proposal -> proposal.md` | 等 `specs` 也完成后解锁 `tasks` |
| `tasks` | `tasks.md` / [`tasks.md`](../../schemas/spec-driven/templates/tasks.md) | `[specs, design]` | `specs -> specs/**/*.md`; `design -> design.md` | 满足 Apply 的 artifact gate |

表中定义来自 [`schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml)。`generateInstructions()` 通过 `getDependencyInfo()` 只返回当前 artifact 的**直接**依赖，并保留 schema 的 output path；因此 `tasks.dependencies.specs.path` 是 glob `specs/**/*.md`，不是已展开的文件数组（[`instruction-loader.ts`](../../src/core/artifact-graph/instruction-loader.ts)）。

### 三个容易混淆的“上下文”名词

| 名称 | 出现位置 | 含义 |
|---|---|---|
| `dependencies` | artifact instructions | 当前 artifact 的直接 DAG 前置项；给出 ID、完成状态、schema output path 和描述。 |
| `contextFiles` | Apply instructions | change 中**所有当前已存在** artifact 的已展开绝对文件路径；不只限于 `apply.requires`，也不等同于 DAG 直接依赖。 |
| `context` | `config.yaml` / artifact instructions | 项目级 prompt 背景，只约束四个 planning artifact 的作者；不是文件列表。 |

`dependencies` 由 [`getDependencyInfo()`](../../src/core/artifact-graph/instruction-loader.ts) 构造；`contextFiles` 由 [`generateApplyInstructions()`](../../src/commands/workflow/instructions.ts) 遍历 schema 的全部 artifact 并调用 `resolveArtifactOutputs()` 构造；config `context` 则由 [`readProjectConfig()`](../../src/core/project-config.ts) 解析并在 `generateInstructions()` 中取出。

## 3. Root、change schema 与 config 的读取时序

正常 instructions 调用链是：

```text
resolveRootForCommand()
  -> 得到 resolved root.path / changesDir
  -> loadChangeContext()
       -> 解析 change 使用的 schema 名称
       -> resolveSchema(name, root.path)
       -> 构建 ArtifactGraph + 按文件存在性检测 completed
  -> loadRootConfigContext(root)
       -> readProjectConfig(root.path)
       -> 如有 references，实时构建上游 spec 索引
  -> generateInstructions(...) 或 generateApplyInstructions(...)
```

关键维护含义：

- config 从**命令已经解析出的 root** 读取，而不是无条件从 shell 当前目录读取。入口见 [`resolveRootForCommand()`](../../src/core/root-selection.ts) 和 [`instructionsCommand()`](../../src/commands/workflow/instructions.ts)。
- 新 change 创建时，`createChange()` 按显式 `--schema` -> config `schema` -> 默认 `spec-driven` 选名，并把结果写入 change 的 `.openspec.yaml`（[`createChange()`](../../src/utils/change-utils.ts)）。
- 已有 change 按显式 `--schema` -> `.openspec.yaml` -> config `schema` -> `spec-driven` 解析名称（[`resolveSchemaForChange()`](../../src/utils/change-metadata.ts)）。因此修改 config `schema` 不会悄悄迁移已有、带 metadata 的 change。
- 相反，`context`、`rules`、`references` 没有写入 change metadata；每次 instructions 命令都会从当前 resolved root 重新读取，所以它们对活跃 change 是动态生效的（[`loadRootConfigContext()`](../../src/commands/workflow/instructions.ts)）。

## 4. `context`、`rules`、`references` 的精确注入路径

### Artifact instructions：四个 artifact 共用一条路径

对 `proposal`、`specs`、`design`、`tasks` 中任一个执行：

```bash
openspec instructions <artifact-id> --change <change> --json
```

`instructionsCommand()` 读取 root config 和 reference index，再把两者传给 `generateInstructions()`。后者：

1. 从内置 schema 取该 artifact 的 `instruction`、`template`、`requires` 和 `generates`。
2. 将 `config.context` trim 后放入 JSON `context`；空白字符串变成 `undefined`。
3. 只精确读取 `config.rules[artifactId]`，没有 `all` wildcard，也不做跨 artifact 继承。
4. 将 reference index 放入独立的 JSON `references`。
5. 保持 `context`、`rules`、`template` 三者分离，不把 config 文本拼进 template。

实现见 [`generateInstructions()`](../../src/core/artifact-graph/instruction-loader.ts)，字段分离由 [`instruction-loader.test.ts`](../../test/core/artifact-graph/instruction-loader.test.ts) 覆盖。人类可读输出的顺序由 [`printInstructionsText()`](../../src/commands/workflow/instructions.ts) 固定为：

```text
<artifact>
  [<warning>]             # 直接依赖未满足时
  <task>
  [<project_context>]     # config.context
  [<referenced_stores>]   # config.references -> 实时索引
  [<rules>]               # config.rules[artifactId]
  [<dependencies>]
  <output>
  [<instruction>]         # schema artifact instruction
  <template>              # schema template
  <success_criteria>
  [<unlocks>]
</artifact>
```

生成的 Propose/Continue workflow 明确要求 agent 先读 dependency 文件，并把 `context`、`rules` 当约束而不是 artifact 正文（[`propose.ts`](../../src/core/templates/workflows/propose.ts)、[`continue-change.ts`](../../src/core/templates/workflows/continue-change.ts)）。因此 config 指导是 prompt-time guidance，不是可审计地持久化到 change 的事实。

### `references` 不是第三种自由文本 prompt

`readProjectConfig()` 将 `references` 规范化为 store declaration；`loadRootConfigContext()` 用一份 registry snapshot 实时调用 `assembleReferenceIndex()`。索引只列 store、spec ID、`Purpose` 首行摘要与 fetch 命令；不内联 spec 正文，只跟随一层，解析失败降级为 warning（[`project-config.ts`](../../src/core/project-config.ts)、[`references.ts`](../../src/core/references.ts)）。

该索引同时进入 artifact 与 Apply instructions；命令级测试明确覆盖“两种 surface、JSON 与 human mode”以及“不出现 spec 正文”（[`store-references.test.ts`](../../test/commands/store-references.test.ts)）。`references` 还会被 `openspec context` 与 `openspec doctor` 以不读取 spec 正文的 health mode 消费，用于 working-set/relationship-health 输出；那是诊断与发现 surface，不是 planning/Apply prompt 注入（[`gatherRelationshipData()`](../../src/commands/shared-gather.ts)）。

### 注入矩阵

| 消费 surface | config `context` | 匹配的 `rules.*` | config `references` | change-local 文件上下文 |
|---|---:|---:|---:|---|
| `instructions proposal` | 是 | `rules.proposal` | 索引非空时 | 无直接 dependency |
| `instructions specs` | 是 | `rules.specs` | 索引非空时 | `proposal.md` |
| `instructions design` | 是 | `rules.design` | 索引非空时 | `proposal.md`；当前不会自动给 specs |
| `instructions tasks` | 是 | `rules.tasks` | 索引非空时 | `specs/**/*.md`、`design.md` |
| `instructions apply` | **否** | **否** | 索引非空时 | 所有当前已存在 artifact 的 concrete `contextFiles` |
| Explore workflow | **否** | **否** | **否** | 通过 `status.artifactPaths.*.existingOutputPaths` 按需直读 |
| Archive workflow | **否** | **否** | **否** | 通过 `status`、tasks 和 delta specs 直读 |

前五行由 [`instructions.ts`](../../src/commands/workflow/instructions.ts) 的两条 command path 决定；Explore 与 Archive 的命令清单分别见 [`explore.ts`](../../src/core/templates/workflows/explore.ts) 和 [`archive-change.ts`](../../src/core/templates/workflows/archive-change.ts)。

## 5. Apply 的真实 gate 与 `contextFiles`

内置 schema 的 Apply 配置是：

```yaml
apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
    Pause if you hit blockers or need clarification.
```

这里有四个必须分开的事实：

1. **Gate 只直接检查 `tasks`。** `generateApplyInstructions()` 不递归复查 `tasks` 的 `specs`/`design` 依赖；它只按 `apply.requires` 查对应 output 是否存在。
2. **`contextFiles` 扫描全部四个 artifact。** 对当前存在的 `proposal.md`、所有匹配 `specs/**/*.md` 的文件、`design.md`、`tasks.md` 分别建立数组；缺失类别直接省略。
3. **`tracks: tasks.md` 决定进度。** checkbox parser 只识别行首 `- [ ]`、`* [ ]`、`- [x]` 或 `* [x]`；tasks 文件缺失、没有 checkbox，或缺少 required artifact 时都会得到 `blocked`。
4. **schema instruction 只在 `ready` 分支使用。** `blocked` 与 `all_done` 会改用运行时生成的提示；全部 checkbox 完成时返回 `all_done` 和 archive 建议。

实现均在 [`parseTasksFile()` 与 `generateApplyInstructions()`](../../src/commands/workflow/instructions.ts)，行为测试见 [`artifact-workflow.test.ts`](../../test/commands/artifact-workflow.test.ts)。Apply skill 随后要求 agent 读取 `contextFiles` 中的**每一条**路径再实施（[`apply-change.ts`](../../src/core/templates/workflows/apply-change.ts)）。

Apply command 虽然调用 `loadRootConfigContext()`，但调用处只解构并传递 `references`；`GenerateApplyInstructionsOptions` 也只有 `planningHome` 与 `references`。所以 `rules.tasks` 会约束 `tasks.md` 的作者，却不会在实施时再次出现；`rules.apply` 既不是合法 artifact rule，也不会进入 Apply。

## 6. Explore 与 Archive 的边界

### Explore

Explore 是 stance，不是 schema phase。生成的 workflow 先调用 `openspec list --json`；有相关 change 时调用 `openspec status --change ... --json`，再从 `artifactPaths.<artifact>.existingOutputPaths` 读取已有 artifact。它没有调用 `openspec instructions <artifact>` 或 `openspec instructions apply`（[`getExploreSkillTemplate()`](../../src/core/templates/workflows/explore.ts)）。

所以 Explore 可以看到 change 中已经持久化的 `proposal`、`specs`、`design`、`tasks`，但不会自动看到 config `context`、`rules` 或 `references`。尤其值得注意：Explore workflow 允许用户要求时更新 planning artifact，但该路径本身没有保证先加载 artifact instructions；不能把 config rules 当成 Explore 编辑的强制 guardrail。

### Archive

生成的 Archive workflow 调用 `list`、`status`，直接检查 tasks 和 delta specs，再移动 change 目录；它同样不调用两种 instructions surface（[`getArchiveChangeSkillTemplate()`](../../src/core/templates/workflows/archive-change.ts)）。CLI 的 `ArchiveCommand` 也直接做 root resolution、validation、spec apply 与 move，没有读取 project `context`、`rules`、`references`（[`archive.ts`](../../src/core/archive.ts)）。

因此 Archive 所能审计的是已落盘 artifact、task checkbox、delta spec 与 validator 结果。需要在归档时可验证的要求，必须在这些持久化输入或自动检查中，而不能只放在 config prompt。

## 7. 源码自洽性审计：后续应改善的地方

这次只修文档、不修改 runtime；但以下漂移会直接影响今后的 config 设计判断。

### 7.1 线性文案与真实 DAG 冲突

schema description、onboard/continue 文案都常写 `proposal → specs → design → tasks`，但 `design.requires` 只有 `proposal`。`status` 的确定顺序甚至会把 `design` 排在 `specs` 前，而 Continue workflow 会选择 status 中第一个 ready artifact（[`schema.yaml`](../../schemas/spec-driven/schema.yaml)、[`graph.ts`](../../src/core/artifact-graph/graph.ts)、[`continue-change.ts`](../../src/core/templates/workflows/continue-change.ts)）。

在源码修改前，文档应统一画成 `proposal -> {design, specs} -> tasks`。若产品意图确实是“先规格、后设计”，应修改 `design.requires` 并补精确 build-order 测试，而不是靠文案暗示顺序。

### 7.2 `design` 的“可选”文案与 DAG 冲突

`design.instruction` 写着“create only if any apply”，但 artifact 类型没有 optional 字段，`tasks.requires` 又强制包含 `design`。因此在当前 runtime 中，`design.md` 是到达 `tasks` 的必需文件，不是可选项（[`schema.yaml`](../../schemas/spec-driven/schema.yaml)、[`ArtifactSchema`](../../src/core/artifact-graph/types.ts)）。

在机制改变前，应把这句话理解为“简单变更也要创建一个最小 design，说明为何无需复杂设计”，否则 workflow 会停在 blocked。

### 7.3 `design` instruction 与 template 不完全一致

schema instruction 要求 `Migration Plan`、`Open Questions` 等 section，但内置 [`templates/design.md`](../../schemas/spec-driven/templates/design.md) 只提供 Context、Goals / Non-Goals、Decisions、Risks / Trade-offs。instructions 同时告诉 agent“使用 template 作为结构”和“遵循 instruction”，存在双重契约。后续应让两者字段集合一致，避免项目 config rules 被迫弥补内置漂移。

### 7.4 “done”是文件存在，不是语义完整

`detectCompleted()` 调用 `artifactOutputExists()`；对 `specs/**/*.md`，任一匹配 Markdown 文件就足以把整个 `specs` artifact 标为 done。它不会核对 proposal 中每个 capability 是否都有 `specs/<capability>/spec.md`，也不会检查正文质量（[`state.ts`](../../src/core/artifact-graph/state.ts)、[`outputs.ts`](../../src/core/artifact-graph/outputs.ts)）。集成测试还明确覆盖了乱序文件也会被标为 completed（[`workflow.integration.test.ts`](../../test/core/artifact-graph/workflow.integration.test.ts)）。

所以 DAG/status 是编排信号，不是内容 validator；不可妥协的规范仍需 validator/test/CI。

### 7.5 Apply gate 是浅 gate

`apply.requires: [tasks]` 只检查 `tasks.md` output；手工制造一个带 checkbox 的 tasks 文件，即使其他 artifact 缺失，也可能进入 ready。正常 Propose/Continue 通过 DAG 避免这种路径，但 runtime 本身没有传递闭包校验。后续测试应加入“只有 tasks 存在”的 builtin-spec-driven case，明确这是接受的流动工作流还是需要收紧的 invariant（[`generateApplyInstructions()`](../../src/commands/workflow/instructions.ts)）。

### 7.6 四 artifact 名称在生成文案中仍有漏项

`getOpsxProposeSkillTemplate()` 的开场列表只列 `proposal.md`、`design.md`、`tasks.md`，漏掉 `specs`，尽管后续循环会按 schema 生成它；config profile 的 Propose 描述也写成“proposal, design, and tasks”（[`propose.ts`](../../src/core/templates/workflows/propose.ts)、[`commands/config.ts`](../../src/commands/config.ts)）。面向用户与维护者的所有基线文档应始终明确四个 artifact：`proposal`、`specs`、`design`、`tasks`。

### 7.7 注入边界缺少直接的负向回归测试

现有测试分别覆盖 artifact 的 `context`/`rules`、两种 instructions surface 的 `references`、Apply `contextFiles` 与进度（[`instruction-loader.test.ts`](../../test/core/artifact-graph/instruction-loader.test.ts)、[`store-references.test.ts`](../../test/commands/store-references.test.ts)、[`artifact-workflow.test.ts`](../../test/commands/artifact-workflow.test.ts)）。但没有一个集中测试直接断言 Apply 不含 `context`/`rules`，以及 Explore/Archive 不加载三种 config guidance。当前边界可由函数签名与调用链证明，但加负向测试能防止未来无意改变信息路由。

## 8. 只面向内置 spec-driven 的 config 写法

```yaml
schema: spec-driven

context: |
  # 四个 planning artifact 作者都需要的、稳定的项目事实
  Runtime: Node.js 22
  API compatibility: preserve public v1 behavior

rules:
  proposal:
    - Separate user-visible scope from implementation detail.
  specs:
    - Give every requirement at least one observable scenario.
  design:
    - Record alternatives and rollback implications.
  tasks:
    - Include verification work as checkbox tasks.

references:
  - shared-platform
```

维护时按真正消费者分配信息：

| 信息 | 应放位置 | 原因 |
|---|---|---|
| 四个 planning artifact 都需知道的稳定背景 | `context` | 每次 artifact instructions 都注入。 |
| 只约束某一 artifact 的重复写作规则 | `rules.proposal/specs/design/tasks` | key 与四个 artifact ID 精确匹配。 |
| 单个 change 的范围、需求、决策、实施事实 | 对应 change artifact | 能沿 DAG dependency 与 Apply `contextFiles` 持久传递。 |
| Apply 必须遵守的约束 | `specs` / `design` / `tasks`，并配合 test、lint、CI | config `context`/`rules` 不进入 Apply。 |
| Explore 或 Archive 必须执行的检查 | 持久化 artifact 或独立自动检查 | 两个 workflow 不加载 config guidance。 |
| 只读上游 spec 的发现入口 | `references` | instructions 只注入实时索引，需要时再 fetch 正文。 |

`readProjectConfig()` 采用逐字段 fail-open：合法兄弟字段会在某字段无效时继续生效；`context` 上限是 50 KiB UTF-8 bytes；rules value 必须是字符串数组，空数组或只含空字符串的数组没有实际效果；未知 rule key 要到 artifact instructions 生成时才会按当前 graph 校验并 warning（[`project-config.ts`](../../src/core/project-config.ts)、[`project-config.test.ts`](../../test/core/project-config.test.ts)）。因此“YAML 能解析”不等于“每条指导都到达目标阶段”。

## 9. 修改后的最小验证闭环

```bash
# 1. 从实际 OpenSpec project root 排除同名 shadow，确认使用 package 内置 schema
openspec schema which spec-driven --json

# 2. 对四个 artifact 分别观察 context/rules/dependencies/references
openspec instructions proposal --change <change> --json
openspec instructions specs    --change <change> --json
openspec instructions design   --change <change> --json
openspec instructions tasks    --change <change> --json

# 3. 单独观察 Apply：应有 contextFiles，可有 references，不应有 context/rules
openspec instructions apply --change <change> --json

# 4. 确认真实 DAG 状态与 applyRequires: [tasks]
openspec status --change <change> --json
```

检查结果应以 JSON 字段为准，不要只看 human output 中是否“似乎提到了”某段文字。特别要确认：四个 artifact 名称完整；`design` 与 `specs` 在 proposal 后并行 ready；tasks 直接依赖两者；Apply 的 `contextFiles` 是已存在文件的 concrete arrays；config `context`/`rules` 没有越过 planning -> implementation 边界。

## 本轮验证说明

本轮完整阅读了内置 schema 与四个 template，并沿 root resolution、change schema resolution、project config parsing、artifact instructions、Apply instructions、reference index、Explore/Archive workflow 及对应测试交叉核验。工作区当前没有 `node_modules/.bin/vitest`，所以未执行 Vitest；测试结论来自测试源码，不宣称本地运行通过。文档层验证使用 `git diff --check`。
