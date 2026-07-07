# 源码覆盖矩阵（v1.5.0）

> **v1.5.0 刷新**：`src/core/workspace/`、`src/core/context-store/`、`src/core/collections/initiatives/`、`src/core/collections/runtime.ts` 已删除。新增 `src/core/store/`、`src/core/worksets.ts`、`src/core/references.ts`、`src/core/root-selection.ts`、`src/core/relationship-health.ts`、`src/core/working-set.ts`、`src/core/openers.ts`、`src/core/file-state.ts`、`src/core/openspec-root.ts`、`src/core/id.ts`、`src/core/zod-issues.ts`。新增命令 `src/commands/store.ts`、`src/commands/context.ts`、`src/commands/workset.ts`、`src/commands/doctor.ts`、`src/commands/shared-gather.ts`、`src/commands/shared-output.ts`。删除命令 `src/commands/workspace.ts`+`src/commands/workspace/`、`src/commands/context-store.ts`、`src/commands/initiative.ts`。

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
| `src/core/command-generation/` | `../mechanisms/02-tool-delivery.md` |
| `src/core/shared/skill-generation.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/shared/tool-detection.ts`、`src/core/available-tools.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/init.ts`、`src/core/update.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/migration.ts`、`src/core/legacy-cleanup.ts`、`src/core/profile-sync-drift.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/parsers/`、`src/core/validation/`、`src/core/schemas/` | `../mechanisms/03-spec-model.md` |
| `src/core/list.ts`、`src/core/view.ts`、`src/core/converters/json-converter.ts` | `../mechanisms/03-spec-model.md` |
| `src/core/templates/workflows/` | `../mechanisms/04-workflow-templates.md` |
| `src/core/templates/skill-templates.ts`、`src/core/templates/types.ts`、`src/core/templates/index.ts` | `../mechanisms/04-workflow-templates.md`、`../mechanisms/02-tool-delivery.md` |
| `src/core/completions/` | `../mechanisms/05-cli-infra.md` |
| `src/commands/completion.ts` | `../mechanisms/05-cli-infra.md` |
| `src/telemetry/`、`src/commands/feedback.ts` | `../mechanisms/05-cli-infra.md` |
| `src/core/change-metadata/`、`src/utils/change-metadata.ts`、`src/core/change-status-policy.ts` | `../internal-spec-driven/03-apply-实施执行.md`、`../spec_cli/03-workflow-runtime-api.md` |
| `src/core/id.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |

### 已删除（v1.5.0 移除）

| 旧源码 | 曾覆盖位置 | 状态 |
|--------|------------|------|
| `src/core/workspace/` | 曾：`../mechanisms/01-workspace-coordination.md` | 已删除 |
| `src/commands/workspace.ts`、`src/commands/workspace/` | 曾：同上 | 已删除 |
| `src/core/context-store/` | 曾：同上 | 已删除 |
| `src/commands/context-store.ts` | 曾：同上 | 已删除 |
| `src/core/collections/initiatives/` | 曾：同上 | 已删除 |
| `src/commands/initiative.ts` | 曾：同上 | 已删除 |
| `src/core/collections/runtime.ts` | 曾：同上 | 已删除 |
| `schemas/workspace-planning/` | 曾：`../schema/03-内置-workspace-planning-详解.md` | 已删除 |

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
