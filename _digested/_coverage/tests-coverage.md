# 测试覆盖矩阵

## 已对应专题

| 测试目录 | 对应 digest |
|----------|-------------|
| `test/core/artifact-graph/` | `../schema/` |
| `test/core/workspace/`、`test/commands/workspace*.test.ts` | `../workspace/` |
| `test/core/context-store/`、`test/commands/context-store.test.ts` | `../workspace/03-context-store-and-initiative.md` |
| `test/core/collections/initiatives/`、`test/commands/initiative.test.ts` | `../workspace/03-context-store-and-initiative.md` |
| `test/core/command-generation/`、`test/core/shared/` | `../tool-delivery/` |
| `test/core/completions/`、`test/commands/completion.test.ts` | `../cli-infra/01-shell-completion.md` |
| `test/core/parsers/`、`test/core/validation*.test.ts`、`test/core/converters/` | `../spec-model/` |
| `test/core/templates/` | `../workflow-templates/` |
| `test/telemetry/`、`test/commands/feedback.test.ts` | `../cli-infra/02-telemetry-feedback-utils.md` |
| `test/specs/` | `_coverage/specs-coverage.md` |

## 仍偏地图级覆盖

| 测试目录 | 当前覆盖 |
|----------|----------|
| `test/cli-e2e/` | `../spec_cli/` 和 `../system/` 间接覆盖 |
| `test/commands/config*.test.ts` | `../spec_cli/05-config-profile-delivery.md`、`../tool-delivery/` |
| `test/commands/schema.test.ts` | `../schema/06-自定义-schema-实战.md` |
| `test/utils/` | `../cli-infra/02-telemetry-feedback-utils.md` 归档级覆盖 |
| `test/prompts/` | `../cli-infra/02-telemetry-feedback-utils.md` 归档级覆盖 |
| `test/fixtures/`、`test/fixtures/tmp-init/` | 测试支撑数据，不对应独立源码机制 |
