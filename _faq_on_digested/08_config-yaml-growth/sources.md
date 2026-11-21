# 参考来源（config-yaml-growth FAQ 汇总）

本 FAQ 的 answer（hub [`answer.md`](answer.md) + 四条路 [`answer-beginner.md`](answer-beginner.md) / [`answer-intermediate.md`](answer-intermediate.md) / [`answer-expert.md`](answer-expert.md) / [`answer-guru.md`](answer-guru.md)）用到的所有源码与文档引用，集中在这里，避免分散在正文干扰阅读。

源码引用以 [`../../_digested/README.md`](../../_digested/README.md) 声明的「当前源码基线」（`0c737dc1`）为准。`src/core/project-config.ts:34-107` 共定义 8 个顶层配置字段（`schema`、`context`、`rules`、`operations`、`references`、`store`、`githubCopilot`、`skillsScope`）；Apply/Archive instructions 会接收 project `context` 和对应 `operations.*.guidance`。

## 源码（OpenSpec CLI）

| 来源 | 用到的结论 |
|---|---|
| `src/core/config-prompts.ts:9-61` | `serializeConfig()`：init 写的 stub 内容（`schema: spec-driven` + context/rules/operations 注释示例）；`:25-27` 明确提醒不要把通用项目文档或读代码可发现的事实放进 `context` |
| `src/core/init.ts` | `--language` 只为新 config 种入 language context；已有 config、空值、多行、控制字符或超长输入会拒绝 |
| `src/cli/index.ts:265` | `init --language <language>` CLI surface |
| `openspec/specs/cli-init/spec.md`、`test/core/init.test.ts` | flag 行为、已有 config 不覆盖与输入边界 |
| `src/cli/commands/config.ts:13-19` | `openspec config` 只管全局 JSON；`preAction` 钩子拒绝 project scope（*"Project-local config is not yet implemented"*，`:16`） |
| `src/core/init.ts`、`src/commands/schema.ts:397-460`、`src/utils/change-utils.ts:187-194`、`src/core/project-skills-scope.ts:25-54`（及 `src/core/github-copilot/cloud-agent.ts:566-610`） | 源码中写 `openspec/config.yaml` 的 4 条路径：① `init`（初始 stub、`--language` 及可选 `githubCopilot.cloudAgent`/`skillsScope`）、② `schema init --default`（写 `schema` 键并清遗留 `defaultSchema`）、③ `createChange()`（补全隐式 root 时写最小 `schema:`）、④ `init`/`update` 记录或清除 `skillsScope: project`——没有任何一条交互式收集一般 `context`/`rules`/`operations` |
| `src/commands/doctor.ts:32,77,92` | `openspec doctor` 会读取 `openspec/config.yaml` 检查 `store` 指针与 `references` 关联健康度，但不诊断 `context`/`rules` 写作质量 |
| `src/core/templates/workflows/propose.ts:56-65,112-113,164-166` | `propose` 先跑 `openspec context --json` 再读 `<root.path>/openspec/config.yaml`，并把 `context`/`rules` 当只读约束（"do NOT include in output"） |
| `src/core/templates/workflows/onboard.ts` | onboard skill 全文不提 config.yaml/context/rules（grep 零匹配） |
| `src/core/artifact-graph/instruction-loader.ts:369-402,415-416` | `context`/`rules` 缺失时静默 `undefined`；`openspec instructions` 返回带这两个字段（agent 能看到当前状态）；每次重读、即时生效；`:381-394` 用所有已安装 schema 的 artifact ID 并集校验 `rules` key |
| `src/core/project-config.ts:34-107,256,357-363,477-498,514-531` | 8 个顶层字段定义；`MAX_CONTEXT_SIZE` 50KB 硬上限（超限在 `:357-363` warn+丢弃）；`readConfigParseError`（`:477-498`，v1.16.0 `#2127` 让 `openspec validate` 遇不可读或非法 YAML 退出 1）；`validateConfigRules`（`:514-531`）对未知 artifact ID 报 warning 且不注入 |
| `src/core/templates/workflows/explore.ts:59,69,92-96,125-128,156-160,197-205,330-355,361` | Explore 是 stance（`:59`），会读 `<root.path>/openspec/config.yaml` 的 `context`/`rules`（`:156-160`），capture 表（`:197-205`）只针对 change 工件，且 **`:361` 明确禁止在 Explore 内创建或编辑 `openspec/config.yaml`**（需退出 Explore 后再写） |
| `src/core/artifact-graph/types.ts:29-65` | schema 结构权威：`ArtifactSchema`（`:29-36`）+ `ApplyPhaseSchema`（`:39-46`）+ `SchemaYamlSchema`（`:49-65`）——guru 改 schema 时能动的 5 件事 |
| `src/commands/schema.ts` | schema 工具命令：`init` / `fork` / `validate` / `which`（fork 优先：落 `openspec/schemas/` 版本控制、覆盖 package 默认；`:875` 用 `parseDocument` 保 YAML 注释） |
| `src/utils/change-metadata.ts:260-298` | per-change schema 解析序：CLI flag > change metadata（`.openspec.yaml`）> config.yaml > default |

## 范例与配置

| 来源 | 用到的结论 |
|---|---|
| `openspec/config.yaml` | 真实范例：OpenSpec 团队 dogfood 的手写 config（context 分两块、rules 跨 specs/tasks/design，已 echo 部分 schema 术语） |
| `schemas/spec-driven/schema.yaml` | spec-driven 各 artifact 的 instruction 与关键术语（capability / requirement / scenario / SHALL / Non-Goals / Risk→Mitigation 等） |
| `schemas/spec-driven/schema.yaml` | schema 层范例：`apply` 块定义 requires/tracks/instruction——config 表达不了的结构护栏 |

## 官方文档

| 来源 | 用到的结论 |
|---|---|
| [`../../docs/customization.md`](../../docs/customization.md) | 官方手动写 config 的例子（`:29-46`）；`:22-27` 含 doc bug（虚假声称 init 交互式） |

## _digested 消化材料

| 来源 | 用到的结论 |
|---|---|
| [`../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md`](../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md) | config.yaml 完整机制（Zod、读取时机、注入、50KB、fail-open、误用） |

## _openspec_handbook 手册

| 来源 | 用到的结论 |
|---|---|
| [`../../_openspec_handbook/21-高级-config-schema-与项目边界.md`](../../_openspec_handbook/21-高级-config-schema-与项目边界.md) | config（提示层）vs schema（结构层）的边界 |
| [`../../_openspec_handbook/22-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/22-高级-项目级全局约束到底放哪.md) | 三层模型：config（项目全局）/ specs（当前能力）/ changes（本次变更） |
| [`../../_openspec_handbook/23-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/23-高级-config-yaml-怎么写到真正好用.md) | 怎么写好：强规则公式、4 类规则、6 bad smell、4 种项目 sample、context 三特质 |
