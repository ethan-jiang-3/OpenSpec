# 测试覆盖矩阵（v1.5.0）

> **v1.5.0 刷新**：删除 `test/core/workspace/`、`test/commands/workspace*.test.ts`、`test/core/context-store/`、`test/commands/context-store.test.ts`、`test/core/collections/initiatives/`、`test/commands/initiative.test.ts`。新增大量 store/workset/context/doctor 测试。

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
| `test/core/completions/`、`test/commands/completion.test.ts` | `../mechanisms/05-cli-infra.md` |
| `test/core/parsers/`、`test/core/validation*.test.ts`、`test/core/converters/` | `../mechanisms/03-spec-model.md` |
| `test/core/templates/` | `../mechanisms/04-workflow-templates.md` |
| `test/telemetry/`、`test/commands/feedback.test.ts` | `../mechanisms/05-cli-infra.md` |
| `test/specs/` | `_coverage/specs-coverage.md` |
| `test/vocabulary-sweep.test.ts` | v1.5.0 新增术语扫描测试 |

## 已删除测试（v1.5.0 移除）

| 旧测试目录/文件 | 状态 |
|-----------------|------|
| `test/core/workspace/` | 随 workspace 源码删除 |
| `test/commands/workspace*.test.ts` | 随 workspace 命令删除 |
| `test/core/context-store/` | 随 context-store 源码删除 |
| `test/commands/context-store.test.ts` | 随 context-store 命令删除 |
| `test/core/collections/initiatives/` | 随 initiatives 源码删除 |
| `test/commands/initiative.test.ts` | 随 initiative 命令删除 |

## 仍偏地图级覆盖

| 测试目录 | 当前覆盖 |
|----------|----------|
| `test/cli-e2e/`（含新增 `capstone-journeys.test.ts`、`store-lifecycle.test.ts`、`workset-journey.test.ts`） | `../spec_cli/` 和 `../system/` 间接覆盖 |
| `test/commands/config*.test.ts` | `../spec_cli/05-config-profile-delivery.md`、`../mechanisms/02-tool-delivery.md` |
| `test/commands/schema.test.ts` | `../schema/06-自定义-schema-实战.md` |
| `test/utils/` | `../mechanisms/05-cli-infra.md` 归档级覆盖 |
| `test/prompts/` | `../mechanisms/05-cli-infra.md` 归档级覆盖 |
| `test/fixtures/`、`test/fixtures/tmp-init/` | 测试支撑数据，不对应独立源码机制 |
