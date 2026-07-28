# 07 — config.yaml 的上下文路由与阶段边界（源码深挖）

**范围。** 本文是 `06-config-yaml-机制与约束.md` 的当前源码补充，专门
服务于 config 的设计与维护。它审计当前工作树的 `f6f3141`，记录决定
“某条指导应该放到 `openspec/config.yaml` 的哪里，还是根本不该放进去”的
运行时事实。

## 核心结论

`config.yaml` 不是一个通用的“按阶段分发指导”机制。正常生命周期中，
`context` 和 `rules` 只会由**生成 artifact 的指令**
（`openspec instructions <artifact>`）加载；它们不会作为 config 提示内容
进入 Apply、Explore、Sync 或 Archive。因此：

- 把稳定、项目级的背景放在 `context`。
- 把“编写某一个规划 artifact 时必须遵守”的可复用约束放在
  `rules.<artifact-id>`。
- 把只在 Apply 时需要的指导放在所选 schema 的 `apply.instruction`；把
  持久的实施事实写进 Apply 实际会读取的 change artifacts。
- 若某个新阶段或 artifact 需要自己的指导通道，应改 custom
  schema/template/skill；新增一个顶层 config key 会被忽略。

当前源码还增加了消化材料未覆盖的两个配置面：`references` 和 `store`。

## 当前有效字段与消费者

| 字段 | 当前消费者与读取时机 | 对维护的含义 |
|---|---|---|
| `schema` | `createChange()` 创建 change 时读取它，并把解析后的值写入该 change 的 `.openspec.yaml`（[`src/utils/change-utils.ts:132-189`](../../src/utils/change-utils.ts)）。之后 `loadChangeContext()` 的优先级是显式 flag -> change metadata -> project config -> `spec-driven`（[`src/utils/change-metadata.ts:153-197`](../../src/utils/change-metadata.ts)）。 | 修改它只会改变未来的新 change（或缺 metadata 的 change）的默认 schema，不能拿它迁移一个正常的活跃 change。 |
| `context` | 只由 `generateInstructions()` 返回给 `openspec instructions <artifact>`（[`src/core/artifact-graph/instruction-loader.ts:273-341`](../../src/core/artifact-graph/instruction-loader.ts)）。 | 它会覆盖全部规划 artifact，因此必须稳定、紧凑，不能写某次 change 的临时细节。 |
| `rules` | 同一条 artifact-instructions 路径；查找严格等于 `rules[artifactId]`，并以该 change 的有效 schema 为准（[`src/core/artifact-graph/instruction-loader.ts:301-336`](../../src/core/artifact-graph/instruction-loader.ts)）。 | key 是 **artifact ID**，不是 workflow/stage 名称，也没有 `all` 通配符。规则应始终能匹配活跃 change 实际使用的 schema。 |
| `references` | 解析 string store ID 或 `{ id, remote }`，再标准化和去重（[`src/core/project-config.ts:67-128`](../../src/core/project-config.ts)）；它会在 artifact 和 Apply 的 instructions 中生成实时、只读的 store-spec 索引（[`src/commands/workflow/instructions.ts:69-98`](../../src/commands/workflow/instructions.ts)）。 | 它用于发现外部规约，不是粘贴外部内容的位置。索引只追一层，且不会内联内容（[`src/core/references.ts:1-10`](../../src/core/references.ts)）。 |
| `store` | 只用于 root 解析：当 `openspec/` 是没有 `specs/`、`changes/` 的 config-only 指针目录时，解析器会选择已注册的 store root；之后正常命令会从该 resolved root 读取 config（[`src/core/root-selection.ts:261-345`](../../src/core/root-selection.ts)，[`src/commands/workflow/instructions.ts:74-96`](../../src/commands/workflow/instructions.ts)）。若本地存在 planning shape，本地 root 胜出且 `store:` 会被 warning 后忽略。 | 指针目录中的 `schema`、`context`、`rules`、`references` 都不会成为正常命令的执行配置，只有 `store` 用来选择 root。不要把本地 planning root 与 `store:` 当作常规组合。 |

`references` 被有意排除在 `ProjectConfigSchema` 之外、改由手写代码解析；
所以不能再把这个 Zod object 当成整个文件的完整契约
（[`src/core/project-config.ts:19-65`](../../src/core/project-config.ts)）。

## 指令边界与精确顺序

artifact-instructions 命令会从**已解析 root** 读取一次 config、组装
references，然后把两者交给 `generateInstructions()`
（[`src/commands/workflow/instructions.ts:74-155`](../../src/commands/workflow/instructions.ts)）。
JSON 输出保留为独立字段；人类/XML 输出的实际顺序是：

```text
<artifact>
  [blocked warning]
  <task>
  <project_context>       # config.context
  <referenced_stores>     # config.references 导出的实时索引
  <rules>                 # config.rules[artifactId]
  <dependencies>
  <output>
  <instruction>           # schema artifact instruction
  <template>              # schema template
  <success_criteria>
  <unlocks>
</artifact>
```

来源：[`src/commands/workflow/instructions.ts:172-289`](../../src/commands/workflow/instructions.ts)。
当前标签是 `<project_context>`，不是旧文档中的 `<context>`。`context` 和
`rules` 仍是仅供 agent 使用的约束，不能复制进 artifact 输出。

重要的设计含义是：config 不能替代 DAG 上的上下文。dependencies 由 schema
计算，agent 会取得相应路径；`propose` 会针对每个 ready artifact 消费这个
指令包，并在写入前读取已完成依赖
（[`src/core/templates/workflows/propose.ts:55-80`](../../src/core/templates/workflows/propose.ts)）。

## 阶段缺口：为何 rules 无法解决“后面阶段才给正确上下文”

1. **Propose / Continue。** 两者会调用
   `openspec instructions <artifact>`，因此能收到 `context`、匹配的
   `rules`、schema instruction/template、dependency paths 与 references。
   这是唯一原生的 config 提示注入点
   （[`src/core/templates/workflows/continue-change.ts:58-75`](../../src/core/templates/workflows/continue-change.ts)）。

2. **Apply。** `generateApplyInstructions()` 的 options 只包含
   `planningHome` 与 `references`；它把所有已有 schema artifact 的输出
   收集为 `contextFiles`，并使用 `schema.apply.instruction`
   （[`src/commands/workflow/instructions.ts:321-432`](../../src/commands/workflow/instructions.ts)）。命令传入的是
   `references`，不是 `projectConfig`
   （[`src/commands/workflow/instructions.ts:459-464`](../../src/commands/workflow/instructions.ts)）。所以 `rules.tasks`
   只会帮助写出 `tasks.md`，**不会**约束之后的实施。

   现有测试也体现了这个不对称契约：artifact instructions 的测试断言
   context/rules 会注入，Apply 的测试只断言 `contextFiles` 和进度
   （[`test/commands/artifact-workflow.test.ts:422-468`](../../test/commands/artifact-workflow.test.ts)，[`test/commands/artifact-workflow.test.ts:825-880`](../../test/commands/artifact-workflow.test.ts)）。目前没有专门的回归测试断言 Apply 中不存在 config context/rules；这一结论直接来自上述函数签名和命令调用。

3. **Explore。** 生成的 skill 只调用 `list`/`status`，再直接读取已有
   artifact paths；它不调用 artifact instructions
   （[`src/core/templates/workflows/explore.ts:82-134`](../../src/core/templates/workflows/explore.ts)）。这里没有 config context/rules 的注入点。

4. **Sync / Archive。** 生成的 workflow 依赖 `status`、返回的 artifact
   paths 与直接读取；Archive 也只是借 schema/status 判断完成状态
   （[`src/core/templates/workflows/sync-specs.ts:32-57`](../../src/core/templates/workflows/sync-specs.ts)，[`src/core/templates/workflows/archive-change.ts:31-64`](../../src/core/templates/workflows/archive-change.ts)）。两者都不调用 artifact instructions。

当前 `spec-driven` schema 本身也体现这个结构差异：`proposal`、`specs`、
`design`、`tasks` 是 artifacts，而 `apply` 是拥有自己 `instruction` 的独立
块（[`schemas/spec-driven/schema.yaml:4-153`](../../schemas/spec-driven/schema.yaml)）。因此在这个 schema 下，
`rules: { apply: ... }` 是未知 key，并且每个进程最多 warning 一次
（[`src/core/artifact-graph/instruction-loader.ts:301-316`](../../src/core/artifact-graph/instruction-loader.ts)）。

## Schema 才是扩展出口，不是额外 config key

schema 拥有 artifact IDs、`requires`、templates、artifact instructions、
`apply.requires`、`apply.tracks` 与 `apply.instruction`
（[`src/core/artifact-graph/schema.ts`](../../src/core/artifact-graph/schema.ts)，
[`schemas/spec-driven/schema.yaml:4-153`](../../schemas/spec-driven/schema.yaml)）。当需求属于以下任一类时，应修改 schema：

- 新增带独立 rules 与依赖的 review/security/test artifact；
- 改变依赖顺序或实施准入条件；
- 指导必须进入 Apply，而不只是影响 `tasks.md` 的作者；
- 改变输出结构或验证契约。

project-local schema 会在解析时覆盖 package schema，因此 fork 可以随项目
版本控制（[`src/core/artifact-graph/resolver.ts`](../../src/core/artifact-graph/resolver.ts)；另见 [`docs/customization.md:94-132`](../../docs/customization.md)）。

## 解析与维护陷阱

- **`schema` 在类型层必填、在运行时可缺省。** `ProjectConfigSchema` 声明
  `schema` 必须是非空 string（[`src/core/project-config.ts:19-31`](../../src/core/project-config.ts)），但 `readProjectConfig()` 会逐字段解析；它缺失或无效时，仍会返回剩余字段组成的 partial config（[`src/core/project-config.ts:166-175`](../../src/core/project-config.ts)，[`src/core/project-config.ts:254-261`](../../src/core/project-config.ts)）。真正的回退发生在消费者：`createChange()` 会在 `config.schema` 缺失时使用传入 default，`resolveSchemaForChange()` 最终回退到 `spec-driven`（[`src/utils/change-utils.ts:132-150`](../../src/utils/change-utils.ts)，[`src/utils/change-metadata.ts:175-197`](../../src/utils/change-metadata.ts)）。因此只含 context/rules 的 config 仍可工作，但不能被误认为显式选择了某个 workflow。无效 `schema` 但保留合法 context/rules 的行为有测试覆盖（[`test/core/project-config.test.ts:71-95`](../../test/core/project-config.test.ts)）。
- **逐字段 fail-open。** 无效字段会被丢弃，合法的同级字段仍会保留；
  YAML 无法解析或根节点不是 object 时才完全没有 config
  （[`src/core/project-config.ts:151-261`](../../src/core/project-config.ts)）。未知顶层 key 不会复制到返回值，因此没有效果。维护时应检查实际生成的 instructions JSON，而不能只因 YAML 合法就假定行为生效。
- **限制按字节而非字符计。** `context` 超过 50 KiB 会被整体丢弃；
  使用 `Buffer.byteLength` 计算 UTF-8 字节数
  （[`src/core/project-config.ts:130-195`](../../src/core/project-config.ts)）。渲染后的 `references` 索引独立使用相同的 50 KiB 预算
  （[`src/core/references.ts:40-47`](../../src/core/references.ts)）。
- **文件名优先级。** 同时存在时 `config.yaml` 胜过 `config.yml`；`.yml` 是
  支持的 fallback（[`src/core/project-config.ts:420-428`](../../src/core/project-config.ts)，测试见 [`test/core/project-config.test.ts:453-502`](../../test/core/project-config.test.ts)）。
- **rules 相对 schema。** 更换默认 schema 后，旧 rules key 可能变无效；
  warnings 在进程内去重，不能依赖每次都看见它
  （[`src/core/artifact-graph/instruction-loader.ts:22-23`](../../src/core/artifact-graph/instruction-loader.ts)，[`src/core/artifact-graph/instruction-loader.ts:301-316`](../../src/core/artifact-graph/instruction-loader.ts)）。
- **`openspec config` 不是该文件的编辑器。** 它的命令描述与 `--scope` hook
  都只支持 global config，project-local config 被显式拒绝
  （[`src/commands/config.ts:208-219`](../../src/commands/config.ts)）。

## 已确认的 `schema init --default` 漂移

这不是预期的 config 字段，而是当前源码的缺陷/推荐陷阱：

1. `schema init --default` 会把 `defaultSchema: <name>` 写入
   `openspec/config.yaml`（[`src/commands/schema.ts:869-887`](../../src/commands/schema.ts)）。
2. `readProjectConfig()` 读取 `schema`、`context`、`rules`、`references`、
   `store`，但从不读取 `defaultSchema`
   （[`src/core/project-config.ts:166-255`](../../src/core/project-config.ts)）。
3. 正常 root default 被硬编码为 `spec-driven`
   （[`src/core/root-selection.ts:52-121`](../../src/core/root-selection.ts)）；
   `createChange()` 使用 `config.schema`，否则使用该 default
   （[`src/utils/change-utils.ts:132-150`](../../src/utils/change-utils.ts)）。

所以自动生成的 `defaultSchema` 是静默无效的。现有测试覆盖 parser 行为和
常量 root default，但没有断言 `schema init --default` 后新建 change 会真的
选择该 schema：`test/commands/schema.test.ts` 在这个特性周围只测试了构造的
schema/JSON shape（[`test/commands/schema.test.ts:247-390`](../../test/commands/schema.test.ts)）。在上游修复前，应手动写
`schema: <name>`，并用 `openspec new change ...` 及所得的 `.openspec.yaml`
验证。

### 测试执行说明

我尝试运行 parser、declared-store、references 行为相关的 focused Vitest
测试，但当前 checkout 没有 `node_modules/.bin/vitest`，
`pnpm exec vitest ...` 因 `ENOENT` 无法启动。以上测试覆盖结论均来自测试
源码检查，而不是本工作区一次成功的测试运行。

## 面向 FAQ 的证据化指导

FAQ 应把 config 维护建模为“指导路由决策”，而不是写一大段泛化 prose：

```text
稳定的项目事实，且应在规划时始终可见？       context
编写 artifact X 时反复适用的约束？             rules.X
仅本次 change 的需求、决策、实施事实？         change artifact
只在 Apply 生效，或需要一个新阶段？            schema / template / skill
外部 spec 的发现与按需读取？                   references
把 planning 外置到注册的 store？               store（仅 config-only repo）
```

每次修改 config 后，应验证真正的消费者：

```bash
openspec instructions <artifact-id> --change <change> --json
openspec instructions apply --change <change> --json
openspec status --change <change> --json
```

第一条确认 `context`/`rules`；第二条确认独立的 Apply 契约及其
`contextFiles`；第三条确认已有 change 实际固定在哪个 schema 上。
