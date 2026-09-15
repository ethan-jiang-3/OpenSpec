# 研究笔记：OpenSpec v1.7.0 的长期 capability 治理边界

> 基线：上游 [`v1.7.0`](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.7.0)。本文只区分已发布的运行时能力、已发布但由 agent 执行的 workflow，以及仍需项目自行治理的部分；不改变任何 runtime 行为。后续复核至 v1.13.0：capability 身份/治理结论未变。

## 结论先行：两种不同强度的“contract”

专题的主轴是对的，但长期使用时必须把下面两层分开：

| 层 | v1.7.0 实际保证什么 | 不保证什么 |
|---|---|---|
| **硬 contract：filesystem identity** | `specs/**/spec.md` 所在目录相对 `specs/` 的路径就是 slash-separated spec ID；delta 会映射到 main specs 的同一相对路径 | domain 的父子语义、owner、依赖图、别名、深度上限、命名政策 |
| **软 contract：proposal / agent workflow** | 默认 `spec-driven` instruction 要求 proposal 写 New / Modified Capabilities，并要求 agent 研究既有 specs | proposal 的 Capabilities 文本与 delta path 一一对应、catalog 已读、taxonomy 合理、迁移完整或并发安全 |

因此，更准确的长期模型是：**capability path 是 OpenSpec 的硬地址；capability taxonomy、catalog、ownership、迁移和并发协议是项目的治理 overlay。**

## 已有的、值得复用的运行时支持

### 1. Nested path 已是正式的 identity 与生命周期地址

`discoverSpecFiles()` 递归寻找非隐藏目录中的 `spec.md`，将目录相对路径正规化为 `/` 分隔的 ID；它跳过 `specs/spec.md`、不跟随目录 symlink、但接受有效的 `spec.md` 文件 symlink，并对不可读目录报错而不是静默漏读。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/utils/spec-discovery.ts#L4-L62) `findSpecUpdates()` 再将每个 ID 的分段重新拼到 `mainSpecsDir/<id>/spec.md`。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/specs-apply.ts#L48-L77)

所以 `identity/session`、`billing/invoices` 或更深路径都能被 list、show、validate、parse 和 archive 使用；这正是 [#1355](https://github.com/Fission-AI/OpenSpec/pull/1355) 修复的跨路径一致性。它是“nested 能安全工作”的强证据，但不把 `identity/` 变成具有继承或聚合语义的 capability。

两个治理含义：

- 根级 `openspec/specs/README.md` 可以存项目 catalog，但它不是 runtime spec，`list/validate` 不会校验它；catalog 必须有自己的同步检查。
- path segment 的 kebab-case、层级深度和何时建立 domain 都是团队约定，而不是 walker 的校验规则。尚未合并的 [#660](https://github.com/Fission-AI/OpenSpec/pull/660) 正在提议 `specStructure`、depth 和 naming validation，反过来也说明 v1.7.0 尚未提供这些 policy。

### 2. Delta / archive 具备有用的局部安全性，但不是全局事务

终端 `openspec archive` 先为所有目标构建并验证结果，随后才逐个写入目标 spec；这样晚到的**构建或验证**失败不会留下已写的 spec。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/archive.ts#L469-L540) 对 `MODIFIED`，它还会在 incoming block 漏掉当前 scenarios 时中止，解决了 [#1246](https://github.com/Fission-AI/OpenSpec/issues/1246) 所揭示的“后归档 change 静默覆盖前一 change 的 scenario”问题。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/specs-apply.ts#L357-L385)

但写入阶段只是顺序 `fs.writeFile`，没有 path lock、compare-and-swap、跨多个 spec 的 rollback 或 archive transaction。[写入源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/specs-apply.ts#L456-L465) 因而“全量预验证”不等于“两个 archive 并发时的可串行化”。`--concurrency` 也只属于批量 **validation**，不是 archive 的并发协调。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/commands/validate.ts#L265-L382)

### 3. 已有两条 workflow 路径，不能混称为一个 CLI 功能

OpenSpec 明确区分终端 `openspec ...` 与聊天中的 `/opsx:*` / skills。[一手说明](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/docs/how-commands-work.md#L1-L75)

- 终端 `openspec archive` 使用上述程序化 delta 合并。
- `openspec-sync-specs` skill 是 **agent-driven**：它读取 delta/main spec 后直接编辑 main spec，明确允许部分 scenario 合并。[已发布 skill](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/skills/openspec-sync-specs/SKILL.md#L12-L123) `openspec-archive-change` skill 会内联执行这个 sync 并复核每个 capability，避免 sync 仍在读 delta 时移动 change；这是 [#1394](https://github.com/Fission-AI/OpenSpec/pull/1394) 修复的 race。[已发布 skill](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/skills/openspec-archive-change/SKILL.md#L86-L125)

第二条路径能处理更富语义的合并，却依赖 agent 忠实执行指令；它不是 runtime lock。长期团队应统一“由哪条路径合并”和升级后如何运行 `openspec update` 刷新生成的 workflow，而不要把 skill 中的 guardrail 误认为 CLI 的强制校验。

## 需要明确补上的 runtime 缺口

### Proposal 的 Capabilities 目前不是机器校验的映射

默认 schema 的 proposal instruction 的确称 Capabilities 为 proposal↔specs 的关键合同，并要求每个列出的 capability 有相应 spec 文件。[schema](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/schemas/spec-driven/schema.yaml#L10-L30) 但 `ChangeParser` 只提取 `Why`、`What Changes` 和实际 delta files；它不读取 `Capabilities` section。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/parsers/change-parser.ts#L22-L75) `ChangeSchema` 也没有 `capabilities` 字段。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/schemas/change.schema.ts#L10-L38)

也就是说，真正被 archive / validate 消费的是 delta 文件的相对 path，而不是 proposal 中的清单。专题应将“proposal 的 capability 列表”表述为**必须由 agent、review 或项目 CI 维护的 soft contract**，不要称为 v1.7.0 的 schema-enforced contract。一个项目若需要硬一致性，应自行检查：proposal 的 New/Modified 列表、active change 的 `specs/**/spec.md`、以及被允许的 `skip_specs` 三者是否一致。

### 没有本地 semantic catalog 或自动 retrieval；但有外部 store 的官方近似物

本地 `openspec list --specs --json` 只给 `{id, requirementCount}`，不是带 Purpose/title/keywords 的 catalog。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/list.ts#L167-L218) `show` 则需要已知的精确 ID 才能读取该 spec。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/commands/spec.ts#L81-L123) 因此，当前项目仍需要薄 catalog 和“候选 → 精确读取”的 discovery protocol。这个缺口不是猜测：本地 catalog / `--detail` / overview 的提案仍公开未落地，见 [#901](https://github.com/Fission-AI/OpenSpec/issues/901)、[#902](https://github.com/Fission-AI/OpenSpec/pull/902)、[#700](https://github.com/Fission-AI/OpenSpec/pull/700) 和 [#978](https://github.com/Fission-AI/OpenSpec/issues/978)。

不过，“catalog / fetch / budget 全都没有 runtime 支持”也不准确：对于**外部 store**，`references:` 已实现 index-then-fetch。instructions 会给出 store ID、各 spec ID、一行 Purpose summary 与精确的 `openspec show <id> --type spec --store <store>` recipe；正文不会被内联。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/references.ts#L1-L10) [收集与 fetch recipe](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/references.ts#L170-L192) [一层、50KB 截断](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/references.ts#L301-L304) [源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/references.ts#L416-L448)。

这是很好的跨仓 capability discovery 机制，但边界也很硬：只针对声明的外部 store、只展开一跳、50KB 会截断、reference 是只读且 store 是 beta；OpenSpec 从不替用户 clone/pull/push，故 checkout 可以是旧的。[官方 guide](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/docs/stores-beta/user-guide.md#L321-L349) 它不替代当前 root 内的 catalog，也不自动完成语义相关性排序。

### config / schema 能塑形，不能凭空执法

`config.context` 会注入每个 artifact instructions，且上限 50KB；`rules` 的键是 artifact ID，而非 capability path；`operations` 只覆盖 apply/archive guidance。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/project-config.ts#L32-L109) [读取上限](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/project-config.ts#L236-L350) 这些内容是 agent 的 prompt-level contract，不是 path/cross-file validator。[官方 CLI 说明](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/docs/cli.md#L808-L828)

项目可 fork / 新建 local schema，把 discovery evidence、taxonomy review 或 migration plan 放进 artifact/DAG；这是官方扩展点。[customization](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/docs/customization.md#L157-L303) [schema resolution](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/artifact-graph/resolver.ts#L76-L180) 但 schema 本身只控制 artifact、依赖和 template 的结构，仍不能自动证明 catalog 同步、active change 没有撞 path，或迁移已经完成。

### `RENAMED` 是 requirement rename，不是 capability rename

delta grammar 的 `RENAMED` 对象只有 requirement header 的 `from/to`，并在**同一 spec ID** 的 requirement block 内操作。[parser](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/parsers/change-parser.ts#L151-L193) [merge](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/specs-apply.ts#L286-L327) 它没有 capability-level `rename`、`split`、`merge`、`retire`、alias 或 `replaces` 元数据。

因此 auth → identity/login、一个 spec 拆为三个或废弃旧 path，仍须是独立的 rebaseline：冻结/重基线 active deltas，审阅 old→new mapping，在 Git 中移动或重建 main specs，更新 catalog/links/references，随后严格校验。将新 path 的 delta 放进普通 archive 只会创建/更新新 target；它不会移动或删除旧 target。

### strict validation 不是基线新鲜度检查

`validateChangeDeltaSpecs()` 校验的是当前 change 内的 delta 结构和 intra-file 冲突，不会比较 canonical main spec，也不会检索 sister active changes。[源码](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/src/core/validation/validator.ts#L128-L335) 因而 `MODIFIED`、`REMOVED` 和 `RENAMED` 的 base 不存在或已经漂移，仍可能等 archive 才失败；这是尚未解决的 [#1112](https://github.com/Fission-AI/OpenSpec/issues/1112) / [#1113](https://github.com/Fission-AI/OpenSpec/pull/1113)。

## 对长期治理的可操作结论

1. **保留四层而非一棵目录树。** `path identity`、main spec 行为真相、薄 catalog/reference 导航、项目 lifecycle overlay 各自独立；不要让 domain 目录假装成为 runtime object model。
2. **给 active change 做 path reservation / freshness gate。** 从每个 active change 的实际 `specs/**/spec.md` 派生 touched paths；同一路径串行 archive，前一 change 落地后让后一 change 重新读 canonical spec 并 rebase。官方团队建议本来就依赖“一 change 一 owner + Git/PR 解决 specs 冲突”，而非 OpenSpec 自动协调。[官方 workflow](https://github.com/Fission-AI/OpenSpec/blob/v1.7.0/docs/team-workflow.md#L49-L65)
3. **将 structural migration 当小型发布。** 维护 old path → new path、owner、状态、冻结的 changes、删除条件和验证结果；普通 feature change 不承担 taxonomy 重构。
4. **让 catalog 可审计。** catalog 是故意位于 runtime 之外的导航层，应由 CI/review 检查其 path 都存在、Purpose 未留 TBD、迁移无旧 path 残留；不要期待 `validate --specs` 覆盖它。
5. **分场景采用 references。** 单 repo 用本地薄 catalog + list/show；跨 repo / 跨团队用官方 `references:` 的 index-then-fetch，并把 store 的 Git freshness 作为日常运维责任。

## 对现有专题应补充或校正的点

- 将“proposal↔specs contract”明确标为 agent/review contract；唯一 runtime-enforced address 是 delta 与 main spec 的同相对 path。
- 将 `03-agent上下文与catalog协议.md` 的“上游 fetch/budget 尚未发布”改为“本地没有，但 external stores 的 `references:` 已发布且受限”；补上 one-hop、50KB、read-only、staleness 边界。
- 在并发部分加入 “scenario overwrite 已被 v1.7 guard 改善，但没有 lock/base freshness/cross-change check” 的精确说法。
- 在 taxonomy migration 部分加入 “`RENAMED` 仅对 requirement” 和 “catalog/README 不会被 native validate 校验”。
- 将 `openspec archive`、`/opsx:sync` 与 `/opsx:archive` 分开叙述，避免把 agent skill 的智能合并与 terminal CLI 的强制行为混为一条能力。

这些补充不会削弱专题的核心判断，反而使它成为一份更准确的长期操作手册：OpenSpec 已把**地址、delta 和基础 lifecycle**做得足够可靠；系统规模增长后，最关键的投入是把未建模的 capability 治理显式化、可审阅化并纳入团队交付流程。
