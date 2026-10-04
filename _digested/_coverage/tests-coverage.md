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
| `test/core/purpose-placeholder.test.ts`、`test/core/validation.purpose-placeholder.test.ts` | `../mechanisms/03-spec-model.md`（v1.11.0 Purpose 占位符检测） |
| `test/commands/show-diff.test.ts` | `../spec_cli/04-command-deep-dive.md`（v1.11.0 `show --diff`） |
| `test/commands/status-all.test.ts` | `../spec_cli/03-workflow-runtime-api.md`（v1.11.0 `status --all`） |
| `test/core/completions/generators/`、`test/core/completions/validation-report.test.ts` | `../mechanisms/05-cli-infra.md`（v1.11.0 Fish 不再回退文件路径） |
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


## v1.13.x 新增测试（0009 同步）

| 新测试 | 覆盖主题 | 对应 digest |
|--------|----------|-------------|
| `test/commands/validate.findings.test.ts`、`test/cli-e2e/validate-findings.test.ts` | `validate --report findings` | `../spec_cli/02/04` |
| `test/cli-e2e/validate-task-checkboxes.test.ts` | 全标记 task 计数 | `../internal-spec-driven/03-apply-实施执行.md` |
| `test/commands/apply-instructions-warnings.test.ts`、`apply-instructions-blocked.test.ts` | apply 无 spec 警告 / blocked | `../spec_cli/03-workflow-runtime-api.md` |
| `test/commands/validate-task-checkboxes` 相关（core+e2e） | 「无 checkbox」检测与全标记计数 | `../internal-spec-driven/03` |
| `test/commands/store-remove-nested.test.ts`、`store-setup-no-init-git.test.ts`、`store-phantom-root.test.ts` | store 三修复 | `../mechanisms/01-store-模型与仓库协同.md` |
| `test/core/artifact-graph/schema-apply-references.test.ts`、`test/commands/schema-apply-references.test.ts` | apply block 引用校验 | `../schema/00-map.md` |
| `test/commands/workflow-instructions-injection.test.ts`、`validate.name-guard.security.test.ts`、`completion-tip.atomic-write.security.test.ts` | #1835 安全加固 | `../mechanisms/05-cli-infra.md` |
| `test/commands/config-edit.test.ts` | 不可解析 config 防重写 | `../spec_cli/05-config-profile-delivery.md` |
| `test/commands/profile-handoffs.test.ts` | optional-workflow 生成时 handoff 解析 | `../spec_cli/05`、`../workflows/00-overview.md` |
| `test/core/completions/installers/bash-installer.round-trip.test.ts` | bash 卸载逐字节还原 | `../mechanisms/05-cli-infra.md` |
| `test/cli-e2e/archive-closed-requirement-heading.test.ts`、`archive-requirement-name-near-miss.test.ts` | archive 收尾 `#`、大小写近名拒绝 | `../internal-spec-driven/04-archive-归档合并.md` |

## v1.14.x 新增测试（0011 同步，含 v1.13.2）

| 新测试 | 覆盖主题 | 对应 digest |
|--------|----------|-------------|
| `test/utils/line-endings.test.ts`、`test/core/specs-apply.line-endings.test.ts` | 行尾检测与写回保持（CRLF 不再被重写成全文件 diff） | `../internal-spec-driven/04-archive-归档合并.md`、`../specs_truth/` |
| `test/core/warp.test.ts` | Warp 集成全流程（`.warp` skills、init/update、command surface、detection） | `../mechanisms/02-tool-delivery.md` |
| `test/core/validation.unknown-metadata-keys.test.ts` | `.openspec.yaml` 未知键告警、`validate --strict` 失败 | `../spec_cli/03-workflow-runtime-api.md`、`../mechanisms/03-spec-model.md` |
| `test/core/templates/archive-task-progress.test.ts` | archive/bulk-archive 工作流用 `list --json` 的 schema-aware 任务进度（自定义任务文件/glob 不误报） | `../internal-spec-driven/04-archive-归档合并.md`、`../mechanisms/04-workflow-templates.md` |
| `test/core/templates/list-json-contract.test.ts` | `list --json` 输出契约（含 `archived` 标记与空态文案） | `../spec_cli/02-machine-facing-cli.md` |
| `test/core/templates/requirement-length-guidance.test.ts` | specs instruction 的 500 字符口径（写短不拆已有） | `../internal-spec-driven/02-propose-提案生成.md`、`../schema/02-内置-spec-driven-详解.md` |
| `test/core/templates/verify-change.test.ts`、`verify-change-delta-operations.test.ts` | verify 模板按 status 契约重写（tasks/progress、Not applicable）+ 四种 delta 操作覆盖 | `../mechanisms/04-workflow-templates.md` |
| `test/core/templates/schema-docs-instruction-parity.test.ts` | schema instruction 与 docs 声明一致 | `../schema/02-内置-spec-driven-详解.md` |
| `test/core/completions/installers/zsh-installer.round-trip.test.ts` | zsh completion 卸载逐字节还原（对齐 0009 的 bash 版） | `../mechanisms/05-cli-infra.md` |
| `test/commands/store-action-context.test.ts` | store-only 场景 `actionContext.allowedEditRoots` 列入 store 路径项目（#2013） | `../mechanisms/01-store-模型与仓库协同.md`（pending） |
| `test/core/config-prompts.test.ts` | config 模板引导口径（项目文档与代码事实不进 config.yaml） | `../mechanisms/05-cli-infra.md` |
| `test/utils/path-containment.test.ts` | `assertPathWithin` 受管写路径防越界（symlink、`openspec-evil` 前缀陷阱） | `../mechanisms/05-cli-infra.md` |
| `test/apply-docs-claims.test.ts`、`test/init-store-docs-claims.test.ts`、`test/setup-docs-claims.test.ts`、`test/skills-docs-claims.test.ts` | 用户 docs 中命令/行为声明的一致性校验 | docs-lab 文档面，digest 未单列 |

既有测试文件的大幅扩展（非新增，不单列行）：`test/core/archive.test.ts`（Windows EPERM/EXDEV 复制回退与快照回滚，+499 行）、`test/core/version-check.test.ts`（install info / update check，+211 行）、`test/core/list.test.ts`、`test/core/view.test.ts`（archived 分区与 workflow status）、`test/core/init.test.ts`、`test/core/update.test.ts`（新工具目标注册）、`test/core/command-generation/adapters.test.ts`（4 个新 adapter + TOML）、`test/commands/apply-instructions-tasks.test.ts`（`sourcePath`/`line`）。
