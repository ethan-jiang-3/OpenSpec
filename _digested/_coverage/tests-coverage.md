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
| `test/core/parsers/`、`test/core/validation*.test.ts`、`test/core/converters/` | `../mechanisms/03-spec-model.md` |
| `test/core/templates/` | `../mechanisms/04-workflow-templates.md` |
| `test/core/templates/main-spec-paths.test.ts` | `../schema/02-内置-spec-driven-详解.md`、`../internal-spec-driven/02-propose-提案生成.md` |
| `test/package-install-scripts.test.ts` | `../mechanisms/05-cli-infra.md` |
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


## v1.13.x 新增测试（0009 同步）

| 新测试 | 覆盖主题 | 对应 digest |
|--------|----------|-------------|
| `test/commands/validate.findings.test.ts`、`test/cli-e2e/validate-findings.test.ts` | `validate --report findings` | `../spec_cli/02/04` |
| `test/cli-e2e/validate-task-checkboxes.test.ts` | 全标记 task 计数 | `../internal-spec-driven/03-apply-实施执行.md` |
| `test/commands/apply-instructions-warnings.test.ts`、`apply-instructions-blocked.test.ts` | apply 无 spec 警告 / blocked | `../spec_cli/03-workflow-runtime-api.md` |
| `test/core/validation.task-checkboxes`（在 validation 测试内） | 共享 checkbox 计数器 | `../internal-spec-driven/03` |
| `test/commands/store-remove-nested.test.ts`、`store-setup-no-init-git.test.ts`、`store-phantom-root.test.ts` | store 三修复 | `../mechanisms/01-store-模型与仓库协同.md` |
| `test/core/artifact-graph/schema-apply-references.test.ts`、`test/commands/schema-apply-references.test.ts` | apply block 引用校验 | `../schema/00-map.md` |
| `test/commands/workflow-instructions-injection.test.ts`、`validate.name-guard.security.test.ts`、`completion-tip.atomic-write.security.test.ts` | #1835 安全加固 | `../mechanisms/05-cli-infra.md` |
| `test/commands/config-edit.test.ts` | 不可解析 config 防重写 | `../spec_cli/05-config-profile-delivery.md` |
| `test/commands/profile-handoffs.test.ts` | optional-workflow 生成时 handoff 解析 | `../spec_cli/05`、`../workflows/00-overview.md` |
| `test/core/completions/installers/bash-installer.round-trip.test.ts` | bash 卸载逐字节还原 | `../mechanisms/05-cli-infra.md` |
| `test/cli-e2e/archive-closed-requirement-heading.test.ts`、`archive-requirement-name-near-miss.test.ts` | archive 收尾 `#`、大小写近名拒绝 | `../internal-spec-driven/04-archive-归档合并.md` |
