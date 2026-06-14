# OpenSpec 自身 Specs 覆盖矩阵

## 已有强覆盖

| spec | 覆盖位置 |
|------|----------|
| `artifact-graph` | `../schema/`、`../internal-spec-driven/05-schema-driven-控制面.md` |
| `change-creation` | `../system/03-planning-home-与-workspace.md`、`../workflow-templates/01-planning-templates.md` |
| `cli-artifact-workflow` | `../spec_cli/03-workflow-runtime-api.md`、`../internal-spec-driven/` |
| `schema-resolution` | `../schema/04-schema-解析优先级.md` |
| `schema-init-command`、`schema-fork-command`、`schema-validate-command`、`schema-which-command` | `../schema/06-自定义-schema-实战.md`、`../spec_cli/04-command-deep-dive.md` |
| `context-injection`、`rules-injection`、`instruction-loader` | `../schema/05-四层注入机制.md` |
| `config-loading` | `../schema/05-四层注入机制.md`、`../internal-spec-driven/06-config-yaml-机制与约束.md` |
| `cli-archive` | `../internal-spec-driven/04-archive-归档合并.md` |
| `specs-sync-skill` | `../workflow-templates/02-implementation-and-closeout.md` |
| `workspace-foundation`、`workspace-links`、`workspace-open`、`workspace-change-planning` | `../workspace/`、`../schema/03-内置-workspace-planning-详解.md` |
| `command-generation`、`ai-tool-paths`、`cli-init`、`cli-update`、`global-config` | `../tool-delivery/`、`../spec_cli/05-config-profile-delivery.md` |
| `cli-completion` | `../cli-infra/01-shell-completion.md` |
| `telemetry`、`cli-feedback` | `../cli-infra/02-telemetry-feedback-utils.md`、`../workflow-templates/03-onboard-and-feedback.md` |

## 部分覆盖

| spec | 覆盖位置 |
|------|----------|
| `cli-config` | `../spec_cli/05-config-profile-delivery.md` |
| `cli-list`、`cli-show`、`cli-view`、`cli-validate` | `../spec-model/03-read-commands.md` |
| `cli-change`、`cli-spec` | `../spec_cli/04-command-deep-dive.md`、`../spec-model/` |
| `legacy-cleanup` | `../tool-delivery/02-init-update-drift.md` |
| `opsx-archive-skill`、`opsx-verify-skill`、`opsx-onboard-skill` | `../workflow-templates/` |

## 待后续评估

| spec | 说明 |
|------|------|
| `ci-nix-validation` | 更偏仓库工程/发布支撑，可后续纳入 infra 或 release 专题 |
| `openspec-conventions` | 横跨所有专题，当前分散覆盖 |
| `docs-agent-instructions` | 和 workflow templates / docs 维护有关，可后续补 docs 专题 |
