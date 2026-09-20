# 源码覆盖矩阵

## 机制级覆盖

| 源码 | 覆盖位置 |
|------|----------|
| `src/core/artifact-graph/` | `../schema/`、`../internal-spec-driven/05-schema-driven-控制面.md` |
| `schemas/spec-driven/` | `../schema/02-内置-spec-driven-详解.md`、`../internal-spec-driven/` |
| `src/commands/workflow/` | `../spec_cli/03-workflow-runtime-api.md`、`../internal-spec-driven/` |
| `src/core/archive.ts`、`src/core/specs-apply.ts` | `../internal-spec-driven/04-archive-归档合并.md` |
| `src/core/project-config.ts` | `../schema/05-四层注入机制.md`、`../internal-spec-driven/06-config-yaml-机制与约束.md` |
| `src/core/planning-home.ts` | `../system/03-planning-home-与-store-模型.md` |
| `src/core/config.ts`、`src/core/global-config.ts`、`src/core/profiles.ts`、`src/core/config-schema.ts` | `../spec_cli/05-config-profile-delivery.md`、`../mechanisms/02-tool-delivery.md` |
| `src/core/store/` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/worksets.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/references.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/root-selection.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/relationship-health.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/working-set.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/openers.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/file-state.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/openspec-root.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/commands/store.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/commands/context.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/commands/workset.ts`、`src/commands/workset-input.ts`、`src/commands/workset-prompts.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/commands/doctor.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/commands/shared-gather.ts`、`src/commands/shared-output.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `src/core/command-generation/` | `../mechanisms/02-tool-delivery.md`（v1.9.0 含 Command Code adapter） |
| `src/core/shared/skill-generation.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/shared/tool-detection.ts`、`src/core/available-tools.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/init.ts`、`src/core/update.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/migration.ts`、`src/core/legacy-cleanup.ts`、`src/core/profile-sync-drift.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/parsers/`、`src/core/validation/`、`src/core/schemas/` | `../mechanisms/03-spec-model.md` |
| `src/core/list.ts`、`src/core/view.ts`、`src/core/converters/json-converter.ts` | `../mechanisms/03-spec-model.md` |
| `src/core/templates/workflows/` | `../mechanisms/04-workflow-templates.md` |
| `src/core/templates/skill-templates.ts`、`src/core/templates/types.ts`、`src/core/templates/index.ts` | `../mechanisms/04-workflow-templates.md`、`../mechanisms/02-tool-delivery.md` |
| `src/core/completions/` | `../mechanisms/05-cli-infra.md` |
| `src/core/completion-tip.ts` | `../mechanisms/05-cli-infra.md` |
| `src/commands/completion.ts` | `../mechanisms/05-cli-infra.md` |
| `src/telemetry/`、`src/commands/feedback.ts` | `../mechanisms/05-cli-infra.md` |
| `src/core/change-metadata/`、`src/utils/change-metadata.ts`、`src/core/change-status-policy.ts` | `../internal-spec-driven/03-apply-实施执行.md`、`../spec_cli/03-workflow-runtime-api.md` |
| `src/core/id.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |

## 部分覆盖

| 源码 | 当前覆盖 | 后续建议 |
|------|----------|----------|
| `src/commands/schema.ts` | `../schema/06-自定义-schema-实战.md`、`../spec_cli/04-command-deep-dive.md` | 后续可补 schema CLI 子命令逐实现 |
| `src/commands/config.ts` | `../spec_cli/05-config-profile-delivery.md`、`../mechanisms/02-tool-delivery.md` | 后续可补 config key-path 操作细节 |
| `src/commands/show.ts`、`src/commands/validate.ts`、`src/commands/change.ts`、`src/commands/spec.ts` | `../mechanisms/03-spec-model.md`、`../spec_cli/04-command-deep-dive.md` | 后续可补人类浏览 UX 细节 |
| `src/core/config-prompts.ts`、`src/core/styles/palette.ts` | `../mechanisms/05-cli-infra.md` | CLI 展示/配置模板支撑层，不单独开专题 |
| `src/utils/` | `../mechanisms/05-cli-infra.md` | 仅归档级覆盖，不逐函数消化 |
| `src/prompts/`、`src/ui/` | `../mechanisms/05-cli-infra.md` | 仅归档级覆盖 |

## 地图级覆盖

| 源码 | 覆盖位置 |
|------|----------|
| `src/cli/index.ts` | `../system/06-源码地图与扩展点.md`、`../spec_cli/04-command-deep-dive.md` |
| `src/index.ts`、`src/core/index.ts` | `../system/06-源码地图与扩展点.md` |


## v1.13.x 新增模块（0009 同步后待深化的覆盖点）

| 新源码 | 内容 | 计划覆盖 |
|--------|------|----------|
| `src/core/command-generation/adapters/codeassistant.ts` | SourceCraft（VS Code 扩展）adapter | `../mechanisms/02-tool-delivery.md`（已列 adapter 表） |
| `src/core/shared/ide-restart.ts` | init/update 共享 IDE restart 提示 | `../mechanisms/05-cli-infra.md`（已记） |
| `src/utils/task-progress.ts`（扩展）+ `src/core/validation/task-checkboxes.ts`（新） | 全标记计数 / 无 checkbox 检测 | `../internal-spec-driven/03`、`../specs_truth/06`（已记） |
| `src/core/completions/installers/shell-quote.ts` | completion 安装 shell 引用 | `../mechanisms/05-cli-infra.md`（已记） |
| `src/telemetry/opt-out.ts` | 遥测 opt-out | `../mechanisms/05-cli-infra.md`（待展开） |
| `src/core/templates/optional-workflow.ts` | profile 未装 workflow 的提示支撑 | 待消化 |
| `src/core/templates/workflows/project-root.ts` | workflow 写前 init 检查 | `../workflows/`（行为已记） |
| `src/utils/nested-change.ts` | namespace 目录中 change 的报告 | `../specs_truth/06`（已记锚点） |

安全加固（#1835，v1.13.1）涉及 validator/init/update/archive 多处输入校验，暂记于 `../mechanisms/05-cli-infra.md`，未单列模块。
