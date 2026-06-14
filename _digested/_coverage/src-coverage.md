# 源码覆盖矩阵

## 机制级覆盖

| 源码 | 覆盖位置 |
|------|----------|
| `src/core/artifact-graph/` | `../schema/`、`../internal-spec-driven/05-schema-driven-控制面.md` |
| `schemas/spec-driven/` | `../schema/02-内置-spec-driven-详解.md`、`../internal-spec-driven/` |
| `schemas/workspace-planning/` | `../schema/03-内置-workspace-planning-详解.md` |
| `src/commands/workflow/` | `../spec_cli/03-workflow-runtime-api.md`、`../internal-spec-driven/` |
| `src/core/archive.ts`、`src/core/specs-apply.ts` | `../internal-spec-driven/04-archive-归档合并.md` |
| `src/core/project-config.ts` | `../schema/05-四层注入机制.md`、`../internal-spec-driven/06-config-yaml-机制与约束.md` |
| `src/core/planning-home.ts` | `../system/03-planning-home-与-workspace.md` |
| `src/core/config.ts`、`src/core/global-config.ts`、`src/core/profiles.ts`、`src/core/config-schema.ts` | `../spec_cli/05-config-profile-delivery.md`、`../tool-delivery/02-init-update-drift.md` |
| `src/core/workspace/` | `../workspace/` |
| `src/commands/workspace.ts`、`src/commands/workspace/` | `../workspace/` |
| `src/core/context-store/` | `../workspace/03-context-store-and-initiative.md` |
| `src/core/collections/initiatives/` | `../workspace/03-context-store-and-initiative.md` |
| `src/core/collections/runtime.ts` | `../workspace/03-context-store-and-initiative.md` |
| `src/commands/context-store.ts`、`src/commands/initiative.ts` | `../workspace/03-context-store-and-initiative.md` |
| `src/core/command-generation/` | `../tool-delivery/` |
| `src/core/shared/skill-generation.ts` | `../tool-delivery/01-skill-command-pipeline.md` |
| `src/core/shared/tool-detection.ts`、`src/core/available-tools.ts` | `../tool-delivery/01-skill-command-pipeline.md` |
| `src/core/init.ts`、`src/core/update.ts` | `../tool-delivery/02-init-update-drift.md` |
| `src/core/migration.ts`、`src/core/legacy-cleanup.ts`、`src/core/profile-sync-drift.ts` | `../tool-delivery/02-init-update-drift.md` |
| `src/core/parsers/`、`src/core/validation/`、`src/core/schemas/` | `../spec-model/` |
| `src/core/list.ts`、`src/core/view.ts`、`src/core/converters/json-converter.ts` | `../spec-model/03-read-commands.md` |
| `src/core/templates/workflows/` | `../workflow-templates/` |
| `src/core/templates/skill-templates.ts`、`src/core/templates/types.ts`、`src/core/templates/index.ts` | `../workflow-templates/`、`../tool-delivery/01-skill-command-pipeline.md` |
| `src/core/completions/` | `../cli-infra/01-shell-completion.md` |
| `src/commands/completion.ts` | `../cli-infra/01-shell-completion.md` |
| `src/telemetry/`、`src/commands/feedback.ts` | `../cli-infra/02-telemetry-feedback-utils.md` |
| `src/core/change-metadata/`、`src/utils/change-metadata.ts`、`src/core/change-status-policy.ts` | `../internal-spec-driven/03-apply-实施执行.md`、`../spec_cli/03-workflow-runtime-api.md` |

## 部分覆盖

| 源码 | 当前覆盖 | 后续建议 |
|------|----------|----------|
| `src/commands/schema.ts` | `../schema/06-自定义-schema-实战.md`、`../spec_cli/04-command-deep-dive.md` | 后续可补 schema CLI 子命令逐实现 |
| `src/commands/config.ts` | `../spec_cli/05-config-profile-delivery.md`、`../tool-delivery/` | 后续可补 config key-path 操作细节 |
| `src/commands/show.ts`、`src/commands/validate.ts`、`src/commands/change.ts`、`src/commands/spec.ts` | `../spec-model/03-read-commands.md`、`../spec_cli/04-command-deep-dive.md` | 后续可补人类浏览 UX 细节 |
| `src/core/config-prompts.ts`、`src/core/styles/palette.ts` | `../cli-infra/02-telemetry-feedback-utils.md` | CLI 展示/配置模板支撑层，不单独开专题 |
| `src/utils/` | `../cli-infra/02-telemetry-feedback-utils.md` | 仅归档级覆盖，不逐函数消化 |
| `src/prompts/`、`src/ui/` | `../cli-infra/02-telemetry-feedback-utils.md` | 仅归档级覆盖 |

## 地图级覆盖

| 源码 | 覆盖位置 |
|------|----------|
| `src/cli/index.ts` | `../system/06-源码地图与扩展点.md`、`../spec_cli/04-command-deep-dive.md` |
| `src/index.ts`、`src/core/index.ts`、`src/core/collections/index.ts`、`src/core/shared/index.ts` | `../system/06-源码地图与扩展点.md` |
