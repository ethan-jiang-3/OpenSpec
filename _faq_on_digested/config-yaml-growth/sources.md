# 参考来源（config-yaml-growth FAQ 汇总）

本 FAQ 的 answer（hub [`answer.md`](answer.md) + 四条路 [`answer-beginner.md`](answer-beginner.md) / [`answer-intermediate.md`](answer-intermediate.md) / [`answer-expert.md`](answer-expert.md) / [`answer-guru.md`](answer-guru.md)）用到的所有源码与文档引用，集中在这里，避免分散在正文干扰阅读。

源码引用基于 commit `b1523ea`。

## 源码（OpenSpec CLI）

| 来源 | 用到的结论 |
|---|---|
| `src/core/config-prompts.ts:9-39` | init 写的 stub 内容（`schema: spec-driven` + context/rules 注释示例）——agent 照此格式填 |
| `src/core/init.ts:598-620` | `createConfig()`：只在文件不存在时写 stub，不交互式收集 |
| `src/commands/config.ts:268-279` | `openspec config` 只管全局 JSON；preAction 钩子拒绝 project scope（*"Project-local config is not yet implemented"*） |
| `src/commands/schema.ts:870-887` | `schema init --default` 写 `defaultSchema`——init 外唯一写 config.yaml 的地方（不碰 context/rules） |
| `src/core/templates/workflows/propose.ts:64-65,103-105` | agent 把 context/rules 当只读约束（"do NOT include in output"） |
| `src/core/templates/workflows/onboard.ts` | onboard skill 全文不提 config.yaml/context/rules（grep 零匹配） |
| `src/core/artifact-graph/instruction-loader.ts:319-321,335-336` | context/rules 缺失时静默 `undefined`；`openspec instructions` 返回带这两个字段（agent 能看到当前状态）；每次重读、即时生效 |
| `src/core/project-config.ts:103-107,173-191` | context 50KB 硬上限（超了忽略+warning）；`validateConfigRules`：rules 用未知 artifact ID 会 warning 且不注入 |
| `src/core/templates/workflows/explore.ts` | Explore 是 stance（无脚本）、建项目理解（`:42-46`）；capture 表（`:117-124`）和 hand-off（`:250-273`）无 config 行 → "在 Explore 里长 config"是 emergent |
| `src/core/artifact-graph/types.ts:4-31` | schema 结构权威：`ArtifactSchema`(id/generates/template/instruction/requires) + `ApplyPhaseSchema`(requires/tracks/instruction) + `SchemaYamlSchema`——guru 改 schema 时能动的 5 件事 |
| `src/commands/schema.ts` | schema 工具命令：`init` / `fork` / `validate` / `which`（fork 优先：落 `openspec/schemas/` 版本控制、覆盖 package 默认） |
| `src/utils/change-metadata.ts:155-198` | per-change schema 解析序：CLI flag > change metadata（`.openspec.yaml`）> config.yaml > default |

## 范例与配置

| 来源 | 用到的结论 |
|---|---|
| `openspec/config.yaml` | 真实范例：OpenSpec 团队 dogfood 的手写 config（context 分两块、rules 跨 specs/tasks/design，已 echo 部分 schema 术语） |
| `schemas/spec-driven/schema.yaml` | spec-driven 各 artifact 的 instruction 与关键术语（capability / requirement / scenario / SHALL / Non-Goals / Risk→Mitigation 等） |
| `schemas/workspace-planning/schema.yaml` | schema 层范例：同样 artifact ID 但不同 instruction + `apply` 块强制 linked repos 只读——config 表达不了的结构护栏 |

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
| [`../../_openspec_handbook/04-高级-config-schema-与项目边界.md`](../../_openspec_handbook/04-高级-config-schema-与项目边界.md) | config（提示层）vs schema（结构层）的边界 |
| [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) | 三层模型：config（项目全局）/ specs（当前能力）/ changes（本次变更） |
| [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) | 怎么写好：强规则公式、4 类规则、6 bad smell、4 种项目 sample、context 三特质 |
