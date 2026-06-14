# OpenSpec 自身 Specs 覆盖矩阵

## 已有强覆盖

| spec | 覆盖位置 |
|------|----------|
| `artifact-graph` | `../schema/`、`../internal-spec-driven/05-schema-driven-控制面.md` |
| `change-creation` | `../system/03-planning-home-与-workspace.md`、`../mechanisms/04-workflow-templates.md` |
| `cli-artifact-workflow` | `../spec_cli/03-workflow-runtime-api.md`、`../internal-spec-driven/` |
| `schema-resolution` | `../schema/04-schema-解析优先级.md` |
| `schema-init-command`、`schema-fork-command`、`schema-validate-command`、`schema-which-command` | `../schema/06-自定义-schema-实战.md`、`../spec_cli/04-command-deep-dive.md` |
| `context-injection`、`rules-injection`、`instruction-loader` | `../schema/05-四层注入机制.md` |
| `config-loading` | `../schema/05-四层注入机制.md`、`../internal-spec-driven/06-config-yaml-机制与约束.md` |
| `cli-archive` | `../internal-spec-driven/04-archive-归档合并.md` |
| `specs-sync-skill` | `../mechanisms/04-workflow-templates.md` |
| `workspace-foundation`、`workspace-links`、`workspace-open`、`workspace-change-planning` | `../mechanisms/01-workspace-coordination.md`、`../schema/03-内置-workspace-planning-详解.md` |
| `command-generation`、`ai-tool-paths`、`cli-init`、`cli-update`、`global-config` | `../mechanisms/02-tool-delivery.md`、`../spec_cli/05-config-profile-delivery.md` |
| `cli-completion` | `../mechanisms/05-cli-infra.md` |
| `telemetry`、`cli-feedback` | `../mechanisms/05-cli-infra.md`、`../mechanisms/04-workflow-templates.md` |

## 部分覆盖

| spec | 覆盖位置 |
|------|----------|
| `cli-config` | `../spec_cli/05-config-profile-delivery.md` |
| `cli-list`、`cli-show`、`cli-view`、`cli-validate` | `../mechanisms/03-spec-model.md` |
| `cli-change`、`cli-spec` | `../spec_cli/04-command-deep-dive.md`、`../mechanisms/03-spec-model.md` |
| `legacy-cleanup` | `../mechanisms/02-tool-delivery.md` |
| `opsx-archive-skill`、`opsx-verify-skill`、`opsx-onboard-skill` | `../mechanisms/04-workflow-templates.md` |

## 待后续评估

| spec | 说明 |
|------|------|
| `ci-nix-validation` | 更偏仓库工程/发布支撑，可后续纳入 infra 或 release 专题 |
| `openspec-conventions` | 横跨所有专题，当前分散覆盖 |
| `docs-agent-instructions` | 和 workflow templates / docs 维护有关，可后续补 docs 专题 |
