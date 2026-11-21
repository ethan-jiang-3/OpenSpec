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
| `src/core/store/` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/worksets.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/references.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/root-selection.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/relationship-health.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/working-set.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/openers.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/file-state.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/openspec-root.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/commands/store.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/commands/context.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/commands/workset.ts`、`src/commands/workset-input.ts`、`src/commands/workset-prompts.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/commands/doctor.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/commands/shared-gather.ts`、`src/commands/shared-output.ts` | `../mechanisms/01-store-模型与仓库协同.md` |
| `src/core/command-generation/` | `../mechanisms/02-tool-delivery.md`（v1.9.0 含 Command Code adapter；v1.12.0 含 Code Assistant adapter `adapters/codeassistant.ts`；v1.14.0 新增 atomcode/codestudio/easycode/gigacode adapter 与 `command-generation/toml.ts`。**v2.0.0 起不再生成任何 command 文件**，34 个 adapter 保留但只用于识别旧路径，调用方只剩 `migration` / `command-reconcile` / `tool-detection` / `profile-sync-drift` / `released-output-sweep`） |
| `src/core/shared/skill-generation.ts` | `../mechanisms/02-tool-delivery.md` |
| `src/core/shared/tool-detection.ts`、`src/core/available-tools.ts` | `../mechanisms/02-tool-delivery.md`（v1.12.0 起 tool-detection 有 command-drift 检测） |
| `src/core/init.ts`、`src/core/update.ts` | `../mechanisms/02-tool-delivery.md`（v1.12.0 `.gitkeep` + 共享 restart；v1.13.0 损坏 command 检测） |
| `src/core/shared/ide-restart.ts` | `../mechanisms/02-tool-delivery.md`（v1.12.0 新增） |
| `src/core/onboarding-commands.ts` | `../mechanisms/02-tool-delivery.md`（v1.13.0 `formatOptionalWorkflowsNote`） |
| `src/core/migration.ts`、`src/core/legacy-cleanup.ts`、`src/core/profile-sync-drift.ts` | `../mechanisms/02-tool-delivery.md`（legacy-cleanup 自 v1.17.0 起判据改为“只删没人编辑过的发布版原样输出”，并补 Cline/Qwen 精确文件名） |
| `src/core/shared/generated-fingerprint.ts`、`src/core/shared/released-generated-fingerprints.ts`、`src/core/released-output-sweep.ts` | `../mechanisms/05-cli-infra.md`（v1.17.0 指纹库与旧产物清扫；指纹表是**生成物**，勿手改） |
| `src/core/shared/command-reconcile.ts`、`src/core/command-surface.ts` | `../mechanisms/02-tool-delivery.md`（v1.17.0 命令文件弃用与 reconcile 三分） |
| `src/core/parsers/`、`src/core/validation/`、`src/core/schemas/` | `../mechanisms/03-spec-model.md`（v1.13.0 delta sections 改 list、`[-*+]` 标记、advisory merge preflight） |
| `src/core/validation/purpose-placeholder.ts`、`src/core/validation/constants.ts` | `../mechanisms/03-spec-model.md`（v1.11.0 Purpose 占位符检测；与 archive writer 共享 `PURPOSE_PLACEHOLDER_PREFIX/SUFFIX`） |
| `src/utils/requirement-diff.ts` | `../spec_cli/04-command-deep-dive.md`、`../spec_cli/01-human-facing-cli.md`（v1.11.0 `show --diff` 的统一 diff） |
| `src/core/shared-skill-target.ts` | `../mechanisms/02-tool-delivery.md`（v1.11.0 的 `resolveSharedSkillWriters()` 仲裁**在 v2.0.0 已删除**；现在只读写 `.agents/skills/.openspec-target` 这份「工具清单」，每行一个工具 id） |
| `src/commands/workflow/status.ts` | `../spec_cli/03-workflow-runtime-api.md`、`../spec_cli/02-machine-facing-cli.md`（v1.11.0 `status --all` envelope 与故障隔离） |
| `src/core/list.ts`、`src/core/view.ts`、`src/core/converters/json-converter.ts` | `../mechanisms/03-spec-model.md` |
| `src/core/templates/workflows/` | `../mechanisms/04-workflow-templates.md`（v1.12.0 propose/ff 先读代码、explore 依赖感知；v1.13.0 spec-inventory guidance） |
| `src/core/templates/skill-templates.ts`、`src/core/templates/types.ts`、`src/core/templates/index.ts` | `../mechanisms/04-workflow-templates.md`、`../mechanisms/02-tool-delivery.md` |
| `src/core/completions/` | `../mechanisms/05-cli-infra.md` |
| `src/core/completion-tip.ts` | `../mechanisms/05-cli-infra.md` |
| `src/commands/completion.ts` | `../mechanisms/05-cli-infra.md`（v1.12.0 PowerShell managed setup 文档化） |
| `src/telemetry/`、`src/commands/feedback.ts` | `../mechanisms/05-cli-infra.md` |
| `src/core/change-metadata/`、`src/utils/change-metadata.ts`、`src/core/change-status-policy.ts` | `../internal-spec-driven/03-apply-实施执行.md`、`../spec_cli/03-workflow-runtime-api.md` |
| `src/commands/workflow/instructions.ts` | `../internal-spec-driven/03-apply-实施执行.md`（v1.13.0 no-spec 警告 + `missingPrerequisites` 链） |
| `src/core/specs-apply.ts` | `../internal-spec-driven/04-archive-归档合并.md`（v1.13.0 fence 外空行压缩） |
| `src/core/id.ts` | 未专章覆盖：它只有 store id / change id / legacy initiative id 共享的 kebab 语法（`KEBAB_ID_REGEX`、`isKebabId`、`KEBAB_ID_DESCRIPTION`），散见于 `../mechanisms/01-store-模型与仓库协同.md` 与 `../spec_cli/` 的 id 讨论 |

## 部分覆盖

| 源码 | 当前覆盖 | 后续建议 |
|------|----------|----------|
| `src/commands/schema.ts` | `../schema/06-自定义-schema-实战.md`、`../spec_cli/04-command-deep-dive.md` | 后续可补 schema CLI 子命令逐实现 |
| `src/commands/config.ts` | `../spec_cli/05-config-profile-delivery.md`、`../mechanisms/02-tool-delivery.md` | 后续可补 config key-path 操作细节 |
| `src/commands/show.ts`、`src/commands/validate.ts`、`src/commands/change.ts`、`src/commands/spec.ts` | `../mechanisms/03-spec-model.md`、`../spec_cli/04-command-deep-dive.md`（v1.11.0 `show --diff`、v1.12.0 `validate --report findings` 已进 04/01/02 命令面） | 后续可补人类浏览 UX 细节 |
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

## v1.14.x 新增模块（0011 同步后待深化的覆盖点）

| 新源码 | 职责 | 主要测试 |
|--------|------|----------|
| `src/utils/line-endings.ts` | `detectLineEnding`（dominant 判定，CRLF 平局胜出）/`applyLineEnding`/`matchLineEnding`：specs-apply 写回、completions 安装与 `removeMarkerBlock` 保持文件原有行尾（只有文件不存在才写 LF） | `test/utils/line-endings.test.ts`、`test/core/specs-apply.line-endings.test.ts` |
| `src/core/command-generation/toml.ts` | EasyCode TOML 命令序列化共享模块（`escapeTomlBasicString`/`escapeTomlMultilineBasicString`） | `test/core/command-generation/adapters.test.ts`（easycode 命令形态） |
| `src/core/command-generation/adapters/atomcode.ts` | AtomCode adapter：`.atomcode` skills + `/opsx-<id>` Markdown 命令，`args: optional`（收 `$ARGUMENTS`）或 `args: none` | `test/core/command-generation/adapters.test.ts` |
| `src/core/command-generation/adapters/codestudio.ts` | Code Studio adapter：`.codestudio` skills + `.prompt.md` 命令，`requiresIdeRestart` | `test/core/command-generation/adapters.test.ts` |
| `src/core/command-generation/adapters/easycode.ts` | EasyCode adapter：`.easycode` skills + TOML 命令 `/opsx:<id>` | `test/core/command-generation/adapters.test.ts` |
| `src/core/command-generation/adapters/gigacode.ts` | GigaCode adapter：`.gigacode` skills + Markdown 命令 `opsx-<id>.md` | `test/core/command-generation/adapters.test.ts` |
| `src/core/version-check.ts`（扩展） | `openspec version [--json] [--check]` 支撑：install 识别（scope/package manager/ephemeral runner）与 `getCliInstallInfo`/`checkForCliUpdate`/`canSelfUpgrade`/`buildVersionReportLines` | `test/core/version-check.test.ts` |

## v1.15.0 新增模块

| 新源码 | 职责 | 主要测试 |
|--------|------|----------|
| `src/core/update-plan.ts` | `openspec update` 的写入接缝：`UpdateFileOps`、`realFileOps`、`UpdatePlanRecorder`、`formatUpdatePlan`；dry-run 复用同一条生成路径 | `test/core/update-dry-run.test.ts`、`test/core/update-dry-run.property.test.ts` |
| `src/commands/install-standalone.ts` | `openspec install [version]`：解析目标目录、调用官方安装脚本、检查 PATH、给移除旧副本命令 | `test/commands/install-standalone.test.ts` |
| `src/core/standalone-tip.ts` | 全局包管理器用户的 standalone 一次性提示（update 后、非 TTY/CI 延迟） | `test/core/standalone-tip.test.ts` |
| `src/utils/executable-path.ts` | `findCopiesOnPath` / `samePath`：PATH 上实际生效的副本判定 | `test/core/version-check.test.ts`、`test/commands/install-standalone.test.ts` |
| `scripts/binary/` + `.github/workflows/binaries.yml` | standalone 单文件的构建、安装、校验、8 目标验证与 release 资产 | `test/commands/install-standalone.test.ts`、`test/core/standalone-tip.test.ts`（CLI 侧） |
| `src/core/version-check.ts`（standalone 扩展） | `markStandaloneBinary` / `getStandaloneBinaryPath`；`scope: 'standalone'`；升级命令 `openspec install` | `test/core/version-check.test.ts` |

## v2.0.0–v2.1.1 新增模块

v2.0 换的是**接口形态**：命令文件层整体移除，安装层外包给第三方包，并新增全局作用域。

| 新源码 | 职责 | 主要测试 |
|--------|------|----------|
| `src/core/skill-installer.ts` | 技能安装层。**运行时依赖包 `skills`**（`installSkills` / `removeSkills` / `getSupportedAgents`），不再自建各工具目录规则；`expectedSkillContents` 生成期望内容；v2.1.1 起从 **npm 包**安装（不 clone） | `test/core/skills-2-0-hardening.test.ts`、`test/core/project-skills-vercel.test.ts`、`test/cli-e2e/upgrade-from-releases.test.ts` |
| `src/core/global-skills.ts` | 技能作用域 `SkillScope = 'global' \| 'project'`；`supportsGlobalSkills` 经 `installerAgent(toolId).globalSkillsDir` 判定；`isHomeFolder` 防把家目录当项目 | `test/core/global-skills.test.ts` |
| `src/core/known-projects.ts` | 本机用过 OpenSpec 的项目清单（全局数据目录下的纯文件）。**永不使命令失败**：读不了/写不了都当空处理 | `test/core/known-projects.test.ts` |
| `src/core/shared/shared-skill-install.ts` | 共享目录 `.agents/skills/` 的安装与比对 | `test/core/skills-2-0-hardening.test.ts` |
| `src/core/shared/skill-links.ts` | 每技能一条**相对链接**指向共享真身，建不了链接退化为拷贝。`SkillLinkSpot` 五态 `missing` / `link` / `copy` / `released` / `user`；`released` 与 `user` 的区分复用指纹 `isReleasedGeneratedContent` | `test/core/shared/skill-links.test.ts` |
| `src/core/retired-tools.ts` | 退役工具清理。`RETIRED_TOOLS` 表（`id` / `name` / `folder` / `reason` / `successor`），`init --tools <retired>` 报错并指路（Amazon Q → Kiro） | `test/core/retired-tools.test.ts` |
| `src/core/project-skills-scope.ts`、`src/core/project-dir.ts` | 项目级作用域与目录判定 | `test/core/global-skills.test.ts`、`test/core/project-skills-scope.test.ts` |

**删除**：`src/core/templates/optional-workflow.ts`（v2.0.0）。

**能力删除但模块保留**：`src/core/command-generation/adapters/` 的 34 个适配器仍在，`shouldGenerateCommandsForTool` 与 `formatCommandDeprecationNotice` 已从 `command-surface.ts` 移除。

## 导出 API 面变化（1.17.0 → 2.1.1）

用 `export function|const|class|interface|type` 逐个比对：**945 → 991**，删 18、增 64。删除的 18 条几乎全指向同一件事——**命令层与共享写入权仲裁**：

| 被删除的导出 | 所属 | 含义 |
|---|---|---|
| `shouldGenerateCommandsForTool` | `command-surface.ts` | 不再生成命令文件 |
| `shouldGenerateSkillsForTool`、`shouldRemoveSkillsForTool` | `command-surface.ts` | 不再由 delivery 决定要不要 skills |
| `formatCommandDeprecationNotice`、`COMMAND_DEPRECATION_URL` | `command-surface.ts` | 弃用提示已完成使命 |
| `areCommandFilesUpToDate` | `tool-detection.ts` | 命令文件不再需要「是否最新」判断 |
| `resolveSharedSkillWriters`、`readSharedSkillTarget`、`writeSharedSkillTarget`、`sharedSkillRootOwnedByOther`、`sharedSkillRootOwner`、`sharedSkillTargetMarkerPath`、`isSharedSkillTargetActive`、`reconcileSharedSkillTargets` | `shared-skill-target.ts` | **共享写入权仲裁整套删除**：只剩一份真身，没有「谁写」的问题 |
| `optionalWorkflow`、`resolveOptionalWorkflows`、`onlyWithWorkflow`、`assertWorkflowConditionalsResolved` | `templates/optional-workflow.ts` | 整个文件删除；技能正文改为运行时判断「那个技能装了没有」 |

新增的 64 条集中在三个簇：**skills 安装/链接**（`installSharedSkills`、`createSkillLink`、`classifySkillLinkSpot`、`expectedSkillContents`…）、**作用域与全局**（`SkillScope`、`SKILL_SCOPES`、`installGlobalSkills`、`readGlobalSkills`、`supportsGlobalSkills`、`isHomeFolder`…）、**工具清单与退役**（`RETIRED_TOOLS`、`cleanUpRetiredTools`、`readSkillToolList`、`formatSkillToolList`、`SKILL_LINKED_TOOL_IDS`、`KNOWN_PROJECTS_FILE_NAME`…）。

一句话：**「生成什么」的判定被删掉，「装到哪、怎么链、怎么清」成为新的 API 主干。**
