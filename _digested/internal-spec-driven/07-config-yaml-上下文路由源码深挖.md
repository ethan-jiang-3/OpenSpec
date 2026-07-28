# 07 - config.yaml 的上下文路由与阶段边界（源码深挖）

> 范围：本文是 [`06-config-yaml-机制与约束.md`](06-config-yaml-机制与约束.md) 的当前源码补充，专注于如何设计与维护 `config.yaml`。结论基于工作区快照 `f6f3141`，不修改 FAQ 的论述；后续是否同步入 FAQ 另行决定。

## 先给结论

`config.yaml` **不是通用的、分阶段的 guidance router**。在正常生命周期中，`context` 与 `rules` 只由创建 planning artifact 时的
`openspec instructions <artifact>` 读取。它们不会以 config prompt 的形式进入 Apply、Explore、Sync 或 Archive。

因此，当一条知识或约束需要被安放时，应按它的消费者来分类：

- 所有 planning artifact 都需知道的简短、稳定项目背景：`context`。
- 仅对一个 planning artifact 作者重复有效的约束：`rules.<artifact-id>`。
- Apply 阶段必须收到的稳定指导：选定 schema 的 `apply.instruction`；该次 change 的具体事实则写入 change artifacts。
- 新的审查节点、不同的依赖顺序或不同的交付结构：自定义 schema/template/workflow skill，而非自行新增 config 顶层 key。
- 不可妥协的约束：checker、test、lint、CI 或 validator，不只是 prompt。

此外，当前源码已比 `06` 所描述的字段集合多出 `references` 与 `store`。它们不是新的提示词容器，而是「上游 spec 发现」和「planning root 选择」两个不同的机制。

## 当前生效字段与消费者

| 字段 | 真实消费者与时机 | 维护意味 |
|---|---|---|
| `schema` | `createChange()` 在创建 change 时读取它，并将解析结果写入该 change 的 `.openspec.yaml`（[`change-utils.ts:132-189`](../../src/utils/change-utils.ts)）。后续读取 schema 的优先级是显式 flag -> change metadata -> project config -> `spec-driven`（[`change-metadata.ts:153-197`](../../src/utils/change-metadata.ts)）。 | 改它是修改今后 new change 的默认值，不是迁移一个普通活跃 change 的方法。 |
| `context` | 只在 `generateInstructions()` 为 `openspec instructions <artifact>` 组装返回值时取出（[`instruction-loader.ts:273-341`](../../src/core/artifact-graph/instruction-loader.ts)）。 | 它对所有 planning artifacts 都重复注入，因而应当稳定、精简、不属于单个 change。 |
| `rules` | 同样只走 artifact-instructions 路径；查找方式是严格的 `rules[artifactId]`，合法 key 以当前 change 实际解析出的 schema 为准（[`instruction-loader.ts:301-336`](../../src/core/artifact-graph/instruction-loader.ts)）。 | key 是 artifact ID，不是 workflow/stage 名称，也没有 `all` wildcard。多 schema 项目中必须对每种可能活跃的 schema 审计 key。 |
| `references` | 解析为 store ID 或 `{ id, remote }`，先规范化、去重（[`project-config.ts:67-128`](../../src/core/project-config.ts)）；再在 artifact 与 Apply instructions 中生成实时的、只读的 store-spec 索引（[`instructions.ts:69-98`](../../src/commands/workflow/instructions.ts)）。 | 它是上游依赖发现，不是外部文档的内联引用。索引只跟随一层、不内联 spec 正文（[`references.ts:1-10`](../../src/core/references.ts)）。 |
| `store` | 只在 `openspec/` 是 config-only 目录（没有 `specs/` 且没有 `changes/`）时被 root resolver 当作指针。如果本地已有 planning shape，本地 root 必然胜出，指针被忽略并发出 warning（[`root-selection.ts:261-345`](../../src/core/root-selection.ts)）。 | 不要把 `store:` 与本地 planning root 当作常规组合。config-only pointer 解决后，正常命令从解析出的 store root 读 config；pointer 目录自己的 `schema`/`context`/`rules`/`references` 都不会成为命令配置。 |

`references` 故意不在 `ProjectConfigSchema` 中，而是由手写解析器处理。因而不能再把这个 Zod object 误认为整份 YAML 的完整契约（[`project-config.ts:19-65`](../../src/core/project-config.ts)）。

## 与 06 的源码漂移账本

`06` 中的「三字段 + artifact 注入」基础模型仍然有效，但它不能再被当成当前的完整行为契约。为后续同步而非立即改写 `06`，以下记录实际差异：

| 早期表述 | 当前源码 | 对 config 设计的影响 |
|---|---|---|
| config 在 workflow 每一步都读取并注入 | `context`/`rules` 只出现在 artifact instructions；Apply 只带 references，Explore/Sync/Archive 不会自动拿到这两项 | 不能用全局 context 承载 Apply 或 Archive 的必须规则。 |
| 有效顶层字段只有 `schema`/`context`/`rules` | 还有 `references` 和 `store`；`references` 并不在 Zod 对象内 | 上游 spec 发现与 root 选择要进入字段定义和维护流程。 |
| `schema` 被视为 config 的必填值 | 运行时是逐字段 fail-open，缺失时由消费者回退 | 「写得下去」不等于「显式选中了预期 workflow」。 |
| config 的 schema 可统一控制活跃 change | 普通 new change 会把 schema 写入 `.openspec.yaml`，它在后续解析中优先于 config | 切换默认 schema 需要视为一次「新 change 策略」，不是对进行中 change 的隐式迁移。 |
| `schema init --default` 可安全设置默认值 | 当前实现写入没有消费者的 `defaultSchema` | 在上游修复前不能以它作为维护操作；应显式写 `schema:`。 |

## artifact instruction 的精确边界

`instructions <artifact>` 命令先读取**已解析 root** 的 config，组装 references index，然后再传给 `generateInstructions()`（[`instructions.ts:74-155`](../../src/commands/workflow/instructions.ts)）。JSON 字段彼此分离。人类/XML 输出的顺序是：

```text
<artifact>
  [blocked warning]
  <task>
  <project_context>       # config.context
  <referenced_stores>     # config.references 生成的实时索引
  <rules>                 # config.rules[artifactId]
  <dependencies>
  <output>
  <instruction>           # schema 的 artifact instruction
  <template>              # schema template
  <success_criteria>
  <unlocks>
</artifact>
```

证据：[`instructions.ts:172-289`](../../src/commands/workflow/instructions.ts)。当前标签是 `<project_context>`，不是早期材料中的 `<context>`。`context` 与 `rules` 仍是「供 agent 遵守、不应写入 artifact」的约束，它们不是 artifact 内容。

这也说明 config 不会替代 DAG 上下文。schema 计算依赖关系，instructions 把已完成依赖的路径交给 agent；`propose` skill 再要求 agent 在写下一个 artifact 前阅读这些文件（[`propose.ts:55-80`](../../src/core/templates/workflows/propose.ts)）。这才是 change-local 决策、需求和设计能在正确时机传递的原生路径。

## 阶段空洞：为什么 rules 不能解决「后面也给对的上下文」

1. **Propose / Continue**

   它们调用 `openspec instructions <artifact>`。因而会得到 `context`、当前 artifact 的 `rules`、schema instruction/template、依赖路径和 references。这是唯一个原生的 config prompt injection 点（[`continue-change.ts:58-75`](../../src/core/templates/workflows/continue-change.ts)）。

2. **Apply**

   `generateApplyInstructions()` 只接受 `planningHome` 与 `references`；它把 schema 中**所有已存在 artifact 的输出**收集为 `contextFiles`，并使用 `schema.apply.instruction`（[`instructions.ts:321-432`](../../src/commands/workflow/instructions.ts)）。命令调用处传入的是 `references`，不是 `projectConfig`（[`instructions.ts:459-464`](../../src/commands/workflow/instructions.ts)）。

   所以 `rules.tasks` 能帮助写出更好的 `tasks.md`，但不会在稍后的 implementation pass 重新注入。实施者真正会收到的是：

   - `contextFiles` 中的该次 change artifacts；
   - `apply.instruction`；
   - tasks 进度与未完成任务；
   - 可选的 references index。

   测试也体现了这个不对称契约：artifact-instruction 测试断言 `context`/`rules` 注入，Apply 测试断言 `contextFiles` 和进度（[`artifact-workflow.test.ts:422-468`](../../test/commands/artifact-workflow.test.ts)，[`artifact-workflow.test.ts:825-880`](../../test/commands/artifact-workflow.test.ts)）。当前没有一个专门测试断言「Apply 不包含 context/rules」；此结论直接来自函数签名和命令调用链。

3. **Explore**

   Explore 生成的 skill 调用 `list`/`status`，并按需直读已存在的 artifact 路径；它不调用 artifact instructions（[`explore.ts:82-134`](../../src/core/templates/workflows/explore.ts)）。因而不存在 config `context`/`rules` 的自动注入。

4. **Sync / Archive**

   两者的生成 workflow 主要使用 `status`、其返回的 artifact 路径和直接文件阅读。Archive 根据 schema/status 评估完成度（[`sync-specs.ts:32-57`](../../src/core/templates/workflows/sync-specs.ts)，[`archive-change.ts:31-64`](../../src/core/templates/workflows/archive-change.ts)）。它们都不调用 artifact instructions，所以也没有 `context`/`rules` 注入。

当前 `spec-driven` schema 把这个区分写死在结构中：`proposal`、`specs`、`design`、`tasks` 是 artifacts，`apply` 则是一个独立的 block，有自己的 `instruction`（[`schema.yaml:4-153`](../../schemas/spec-driven/schema.yaml)）。因此对这个 schema 写 `rules: { apply: ... }` 是无效的：`apply` 不是 artifact ID，只会在每个进程首次生成 artifact instructions 时获得一次未知 key warning（[`instruction-loader.ts:301-316`](../../src/core/artifact-graph/instruction-loader.ts)）。

## schema 是升级点，不是额外 config key

schema 拥有 artifact ID、`requires`、template、artifact instruction、`apply.requires`、`apply.tracks` 和 `apply.instruction`（[`schema.ts`](../../src/core/artifact-graph/schema.ts)，[`schema.yaml:4-153`](../../schemas/spec-driven/schema.yaml)）。下列需求已经超出 config 的能力边界，应当升级到 schema、template 或 workflow skill：

- 需要一个有自身 rules 和依赖关系的 review/security/test artifact；
- 需要改变 artifact 的顺序、Apply gate 或实施前置条件；
- 需要让 guidance 确实到达 Apply，而不只是让 `tasks.md` 的作者看见；
- 需要不同的交付文件结构或检查契约。

项目本地 schema 在解析时优先于 package 内置 schema，因而可以和项目一起版本化（[`resolver.ts`](../../src/core/artifact-graph/resolver.ts)；另参见 [`customization.md:94-132`](../../docs/customization.md)）。

## 解析与维护陷阱

- **`schema` 类型必填，但运行时可选。** `ProjectConfigSchema` 把非空 `schema` 声明为必填（[`project-config.ts:19-31`](../../src/core/project-config.ts)），但 `readProjectConfig()` 是逐字段解析，`schema` 缺失或无效时仍会返回含其他合法字段的 partial config（[`project-config.ts:166-175`](../../src/core/project-config.ts)，[`project-config.ts:254-261`](../../src/core/project-config.ts)）。真正的回退发生在消费者：`createChange()` 使用传入的默认 schema，`resolveSchemaForChange()` 最终回退到 `spec-driven`（[`change-utils.ts:132-150`](../../src/utils/change-utils.ts)，[`change-metadata.ts:175-197`](../../src/utils/change-metadata.ts)）。因此 context/rules-only 的 config 仍可工作，但它不等同于显式选择了 workflow。非法 schema 与合法 context/rules 共存的 partial-config 行为已有测试覆盖（[`project-config.test.ts:71-95`](../../test/core/project-config.test.ts)）。
- **逐字段 fail-open。** 只要 YAML 仍可解析，无效字段会被丢弃，合法兄弟字段仍会保留；不可解析或非 object 的文件则没有任何 config（[`project-config.ts:151-261`](../../src/core/project-config.ts)）。未知顶层 key 不会被复制到返回对象，因而没有效果。维护时要检查真实 instruction JSON，不要把「YAML 可解析」当成「行为已生效」。
- **50 KiB 是字节上限，不是字符数。** 超过上限的 `context` 会被整段丢弃，计算使用 `Buffer.byteLength` 的 UTF-8 字节数（[`project-config.ts:130-195`](../../src/core/project-config.ts)）。references 索引的渲染也共享同一数值级别的 50 KiB 预算（[`references.ts:40-47`](../../src/core/references.ts)）。
- **文件名优先级。** 同时存在 `config.yaml` 与 `config.yml` 时，前者胜出；后者只是 fallback（[`project-config.ts:420-428`](../../src/core/project-config.ts)，测试见 [`project-config.test.ts:453-502`](../../test/core/project-config.test.ts)）。
- **rules 是 schema-relative。** 同一份 project config 面对不同 schema 的活跃 changes 时，某个 schema 的合法 artifact ID 可能是另一个 schema 的未知 key。warning 还会在同一进程中去重，不能指望它每次都出现（[`instruction-loader.ts:22-23`](../../src/core/artifact-graph/instruction-loader.ts)，[`instruction-loader.ts:301-316`](../../src/core/artifact-graph/instruction-loader.ts)）。
- **`openspec config` 不是本地 config 编辑器。** 该命令的 `--scope` 仅支持 global config，项目局部配置被明确拒绝（[`config.ts:208-219`](../../src/commands/config.ts)）。

## 已确认的 `schema init --default` 漂移

这是当前实现的 defect/recommendation hazard，不是一个可依赖的 config 字段：

1. `schema init --default` 向 `openspec/config.yaml` 写入 `defaultSchema: <name>`（[`schema.ts:869-887`](../../src/commands/schema.ts)）。
2. `readProjectConfig()` 只读 `schema`、`context`、`rules`、`references` 和 `store`，从不读 `defaultSchema`（[`project-config.ts:166-255`](../../src/core/project-config.ts)）。
3. 正常 root 的 default 目前硬编码为 `spec-driven`（[`root-selection.ts:52-121`](../../src/core/root-selection.ts)）；`createChange()` 有 `schema` 时使用 `config.schema`，否则使用这个 default（[`change-utils.ts:132-150`](../../src/utils/change-utils.ts)）。
因而当前生成的 `defaultSchema` 字段是静默无效的。现有测试覆盖了 parser 行为和 root default 常量，但没有测试断言 `schema init --default` 会改变后续 `new change` 的 schema 选择（[`schema.test.ts:247-390`](../../test/commands/schema.test.ts)）。在上游修复前，应手动写 `schema: <name>`，并通过新 change 的 `.openspec.yaml` 验证。

## 供后续 FAQ 同步的路由准则

后续 FAQ 应把 config 维护视为一个「信息应该在何时被谁消费」的决策，而不是纯粹的 prose 编辑。最小决策表是：

```text
稳定项目事实，且只需在 planning 期使用？        context
重复的单 artifact 写作/审查约束？                    rules.<artifact-id>
单个 change 的需求、决策或实施事实？                change artifact
Apply-only 或新阶段行为？                              schema / template / skill
上游外部 spec 的发现？                               references
要把 planning 根外置到已注册 store？                 store（仅 config-only 目录）
必须确定实现的约束？                              checker / test / lint / CI
```

每次修改 config 后，应直接验证真实消费者：

```bash
openspec instructions <artifact-id> --change <change> --json
openspec instructions apply --change <change> --json
openspec status --change <change> --json
```

第一条确认 `context`/`rules`；第二条确认独立的 Apply contract 与 `contextFiles`；第三条确认现有 change 实际锁定的 schema。

## 验证说明

本轮已阅读当前源码与对应的 Vitest 测试。尝试运行 parser、declared-store 和 references 的 focused Vitest 命令时，该工作区缺少 `node_modules/.bin/vitest`，`pnpm exec vitest ...` 因 `ENOENT` 未能启动。因此上述测试覆盖结论均为源码阅读结果，不是在本工作区成功执行后的测试结果。
