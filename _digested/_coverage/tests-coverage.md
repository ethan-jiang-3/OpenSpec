# 测试覆盖矩阵

## 已对应专题

| 测试目录 | 对应 digest |
|----------|-------------|
| `test/core/artifact-graph/` | `../schema/` |
| `test/core/store/` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/commands/store*.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/commands/context.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/commands/workset.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/commands/doctor.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/commands/declared-store-fallback.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/commands/legacy-groups-removed.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/references.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/root-selection.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/relationship-health.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/working-set.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/openers.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/file-state.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/openspec-root.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/worksets.test.ts` | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/command-generation/`、`test/core/shared/` | `../mechanisms/02-tool-delivery.md` |
| `test/core/completions/`、`test/core/completion-tip.test.ts`、`test/cli-e2e/completion-tip.test.ts`、`test/commands/completion.test.ts` | `../mechanisms/05-cli-infra.md` |
| `test/core/parsers/`、`test/core/validation*.test.ts`、`test/core/converters/` | `../mechanisms/03-spec-model.md`（v1.13.0 新增 `test/core/specs-apply.fence-preservation.test.ts`、`test/core/validation.archive-preflight.test.ts`） |
| `test/core/templates/` | `../mechanisms/04-workflow-templates.md`（v1.13.0 新增 `test/core/templates/spec-inventory.test.ts`） |
| `test/core/templates/main-spec-paths.test.ts` | `../schema/02-内置-spec-driven-详解.md`、`../internal-spec-driven/02-propose-提案生成.md` |
| `test/package-install-scripts.test.ts` | `../mechanisms/05-cli-infra.md`（v1.12.0 git 安装免 pnpm） |
| `test/core/update.test.ts` | `../mechanisms/02-tool-delivery.md`（v1.13.0 command-drift 检测 `test/core/shared/tool-detection-command-drift.test.ts`） |
| `test/telemetry/`、`test/commands/feedback.test.ts` | `../mechanisms/05-cli-infra.md` |
| `test/specs/` | `_coverage/specs-coverage.md` |
| `test/vocabulary-sweep.test.ts` |术语扫描测试 |

## 仍偏地图级覆盖

| 测试目录 | 当前覆盖 |
|----------|----------|
| `test/cli-e2e/`（含新增 `capstone-journeys.test.ts`、`store-lifecycle.test.ts`、`workset-journey.test.ts`） | `../spec_cli/` 和 `../system/` 间接覆盖 |
| `test/commands/config*.test.ts` | `../spec_cli/05-config-profile-delivery.md`、`../mechanisms/02-tool-delivery.md` |
| `test/commands/schema.test.ts` | `../schema/06-自定义-schema-实战.md` |
| `test/utils/` | `../mechanisms/05-cli-infra.md` 归档级覆盖 |
| `test/prompts/` | `../mechanisms/05-cli-infra.md` 归档级覆盖 |
| `test/fixtures/`、`test/fixtures/tmp-init/` | 测试支撑数据，不对应独立源码机制 |
