# 答案：guru——改 schema 本身（结构层）

## 一句话

guru 不只调 `config.yaml`（提示层），而是重塑工作流的**结构层**——fork / init 一个 schema，定义自己的 artifact 种类 / instruction / template / 依赖 DAG / apply。四条路里操作对象最深。区别于 [`answer-expert.md`](answer-expert.md)：那里你在 spec-driven schema **之内**精通 config（context / rules），不动工作流结构；这里你**改工作流结构本身**。

## 什么时候该升到 guru

边界论断（[`../../_openspec_handbook/04-高级-config-schema-与项目边界.md`](../../_openspec_handbook/04-高级-config-schema-与项目边界.md) `:56`）：

> **`config.yaml` 改的是提示层，`schema` 改的是结构层。**

判断你的需求是哪一层：

- **prompt 味**（项目背景、写作约束、默认 schema 选择）→ 留 `config.yaml`（见 [`answer-expert.md`](answer-expert.md)）。
- **structure 味**（artifact 种类、依赖关系、apply 前置、模板组织）→ 升到 schema。

一句话自检：你要改的是**生成什么 artifact、它们怎么排、生成时走什么骨架**——这些 config 表达不了，就该 fork schema。

## schema 能改、config 改不了的 5 件事

结构定义在 `src/core/artifact-graph/types.ts:4-31`（`ArtifactSchema`：id / generates / template / instruction / requires；`ApplyPhaseSchema`：requires / tracks / instruction；`SchemaYamlSchema` 把它们组合起来）：

1. **artifact 种类**——加 / 改名 / 删。community schema `superpowers-bridge` 就加了个 spec-driven 没有的 `retrospective` artifact。config rules 再怎么写也变不出一个新 artifact。
2. **每个 artifact 的 `instruction`**——agent 生成该 artifact 时遵循的 prompt 骨架。config 的 rules 只能**补充**它，**替换**不了。
3. **`templates/*.md`**——artifact 的输出骨架（段落结构、HTML 注释引导）。这是**结构**，区别于 rules（**内容约束**）。
4. **依赖 DAG（`requires`）**——可以完全重画，不必是 `proposal → specs → design → tasks`。
5. **`apply` 块**——自己的 `requires` 门、`tracks` 文件、自己的 `instruction`。`schemas/workspace-planning/schema.yaml` 就用它强制"把 linked repos 当只读"——这种**结构级护栏**，任何 config rule 都表达不了。

## 工具

`src/commands/schema.ts`（命令文档见 [`../../docs/customization.md`](../../docs/customization.md) "Custom Schemas"）：

```bash
openspec schema fork spec-driven my-driven   # 复制内置再改（推荐：版本控制、覆盖 package 默认）
openspec schema init my-driven               # 从零脚手架（含 templates stub + DAG 连线）
openspec schema validate my-driven           # 查语法 / 模板存在 / 循环依赖 / 合法 ID
openspec schema which my-driven              # 查它从哪解析（project > user > package）
```

fork 优先——它落到 `openspec/schemas/my-driven/`，跟代码一起版本控制，且覆盖 package 默认。别直接改 package 内置的 spec-driven，升级会被覆盖。

## 关键契约：config 与 schema 是 key-coupled 的

你改了 artifact 集合（比如换成 `brief` / `outline` / `draft`），config.yaml 里 `rules` 的 key **必须跟着改**——`validateConfigRules`（`src/core/project-config.ts:173-191`，在 `instruction-loader.ts:300-316` 用**当前 schema 的 artifact 集**校对）会对你写 `rules.proposal:` 报 `Unknown artifact ID in rules: "proposal". Valid IDs for schema "my-driven": brief, draft, outline`，且规则永不注入。**结构层一动，提示层的 key 就得对齐。**

## 三层一起用

guru 区别于 expert 的完整控制力，在于三层都调：

```text
template    = 结构（段落总在那）
instruction = 框架（agent 生成时的 prompt 骨架）
rules       = 内容约束（条件性的，在 config 里）
```

expert 在 rules 里磨；guru 三个都调——先 fork schema 定结构 / instruction，再用 config rules 收紧内容。

## 粒度：per-change pin schema

不必项目级切换。某个 change 需要特殊工作流，就在它的 `.openspec.yaml` 写 `schema: my-driven`，只那一个 change 用（解析序：CLI flag > change metadata > config.yaml > default，`src/utils/change-metadata.ts:155-198`）。项目默认 spec-driven，特殊 change pin 自定义。

## 缺口怎么补（再往上：改 OpenSpec 本身）

连 schema 层都不够——要改的是 OpenSpec 本身（给 skill 加引导、加 CLI 命令）——那是贡献者级的事。[`answer-beginner.md`](answer-beginner.md) 的现状盘点讲过：config.yaml 没有编辑工具是个真实缺口。两个方向都建立在已有源码上，代价不大：

**方向 A：让 agent 帮——给 workflow 加一句引导。** 在 `onboard` 或 `explore` skill 里加一条："如果 `openspec/config.yaml` 的 `context` 为空，用 AskUserQuestion 问用户技术栈、领域、质量优先级，然后提议（不是替用户决定）一份 `context` 和初始 `rules`，让用户确认后写入。" 复用已有的 `readProjectConfig()` 读 + 文件写入，不改 CLI。

**方向 B：给 CLI 加项目级命令。** 实现 `config.ts:273-279` 那个 preAction 钩子已经在等的 `--scope project`：

```bash
openspec config context set "Tech stack: ..."
openspec config rule add proposal "Include rollback plan"
```

复用已有的 `readProjectConfig()`（`src/core/project-config.ts`，目前纯只读，需加一个 write）+ `stringifyYaml`（`schema.ts:878` 已有先例：parse-modify-restringify）。门槛低，且正好堵上那个 "not yet implemented"。

方向 A 让普通用户不用碰 YAML（靠对话），方向 B 给愿意用命令行的人结构化入口。两者互补。

## 守则

- **fork，不改 package 内置。** 直接改内置 spec-driven，升级会被覆盖。fork 落 `openspec/schemas/` 跟代码一起版本控制。
- **改完先 `validate` 再用。** `openspec schema validate <name>` 查语法 / 模板存在 / 循环依赖 / 合法 ID——结构层写错不像 config 的 fail-open，是硬错误。
- **结构层一动，`rules` key 跟着对齐。** artifact 集合改了，config.yaml 里 `rules` 的 key 必须匹配新 schema 的 artifact ID（否则 `validateConfigRules` 报 warning 且规则永不注入）。
- **per-change pin 优先于项目级切换。** 大多数 change 还用默认 spec-driven；只有特殊工作流的 change 在 `.openspec.yaml` pin 自定义 schema。
- **三层一起调。** template（结构）+ instruction（框架）+ rules（内容约束）配合，而不是只改一层。

> 全部源码与文档引用集中在一个文件：[`sources.md`](sources.md)。
