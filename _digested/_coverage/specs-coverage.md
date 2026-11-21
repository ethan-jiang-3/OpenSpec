# OpenSpec 自身 Specs 覆盖矩阵

> 当前仓库 `openspec/specs/*/spec.md` 共 **44** 个有效 capability spec（另 `billing`、`identity` 两个空目录无 `spec.md`），已全量纳入下表追踪。

## 已有强覆盖

| spec | 覆盖位置 |
|------|----------|
| `artifact-graph` | `../schema/`、`../internal-spec-driven/05-schema-driven-控制面.md` |
| `change-creation` | `../system/03-planning-home-与-store-模型.md`、`../mechanisms/04-workflow-templates.md` |
| `cli-artifact-workflow`、`graceful-status-empty` | `../spec_cli/03-workflow-runtime-api.md`、`../internal-spec-driven/` |
| `cli-archive-instructions` | `../spec_cli/03-workflow-runtime-api.md`、`../spec_cli/02-machine-facing-cli.md` |
| `schema-resolution` | `../schema/04-schema-解析优先级.md` |
| `schema-init-command`、`schema-fork-command`、`schema-validate-command`、`schema-which-command` | `../schema/06-自定义-schema-实战.md`、`../spec_cli/04-command-deep-dive.md` |
| `context-injection`、`rules-injection`、`operation-guidance`、`instruction-loader` | `../schema/05-四层注入机制.md`、`../spec_cli/08-glossary-and-models.md` |
| `config-loading` | `../schema/05-四层注入机制.md`、`../internal-spec-driven/06-config-yaml-机制与约束.md` |
| `cli-archive` | `../internal-spec-driven/04-archive-归档合并.md` |
| `specs-sync-skill` | `../mechanisms/04-workflow-templates.md`、`../workflows/07-sync.md` |
| `command-generation`、`ai-tool-paths`、`oh-my-pi-tool`、`cli-init`、`cli-update`、`global-config` | `../mechanisms/02-tool-delivery.md`、`../spec_cli/01-human-facing-cli.md`、`../spec_cli/05-config-profile-delivery.md`（注：`command-generation` 与 `oh-my-pi-tool` 的上游 spec 仍停留在 1.x 命令生成口径，v2.0+ 真实行为以源码与 `02-tool-delivery.md` 为准） |
| `cli-version` | `../spec_cli/01-human-facing-cli.md`、`../spec_cli/02-machine-facing-cli.md`、`../mechanisms/05-cli-infra.md` |
| `cli-completion` | `../mechanisms/05-cli-infra.md` |
| `telemetry` | `../mechanisms/05-cli-infra.md` |
| `cli-feedback` | `../mechanisms/05-cli-infra.md`、`../mechanisms/04-workflow-templates.md` |

## 部分覆盖

| spec | 覆盖位置 |
|------|----------|
| `cli-config` | `../spec_cli/05-config-profile-delivery.md` |
| `cli-list`、`cli-show`、`cli-view`、`cli-validate` | `../mechanisms/03-spec-model.md`、`../spec_cli/01-human-facing-cli.md` |
| `cli-change`、`cli-spec` | `../spec_cli/04-command-deep-dive.md`、`../mechanisms/03-spec-model.md` |
| `legacy-cleanup` | `../mechanisms/02-tool-delivery.md` |
| `opsx-apply-skill`、`opsx-archive-skill`、`opsx-bulk-archive-skill`、`opsx-verify-skill`、`opsx-onboard-skill`、`opsx-update-skill` | `../mechanisms/04-workflow-templates.md`、`../workflows/` |

## 待后续评估（stores 设计文档）

| 文档/目录 | 说明 |
|-----------|------|
| `openspec/work/simplify-context-and-workspace-model/` | stores 重构的 roadmap、capstone、8 个 slices — 是理解 stores 设计意图的重要来源，待消化 |
| `openspec/work/AGENTS.md`、`openspec/work/README.md` | stores 工作的 agent 指引和入口 |
| `ci-nix-validation` | 更偏仓库工程/发布支撑 |
| `openspec-conventions` | 横跨所有专题，当前分散覆盖 |
| `docs-agent-instructions` | 和 workflow templates / docs 维护有关 |

## v1.11.0→v1.13.0 新增/变更的 specs

| spec | 变化 | 说明 |
|------|------|------|
| `cli-show` | v1.11.0 扩展 | `--diff`（MODIFIED unified diff、ADDED 全文、REMOVED Reason/Migration、RENAMED FROM/TO；`--json --diff` 加 `diff`/`warning`；`--store`）。本仓库 `openspec/specs/cli-show/spec.md` 尚未同步 diff 段，以 `../spec_cli/04-command-deep-dive.md` 与源码为准 |
| `cli-artifact-workflow` | v1.11.0 / v1.13.0 | v1.11.0 `status --all`（batch envelope、故障隔离）；v1.13.0 apply no-spec 警告 + `missingPrerequisites` 缺失链 |
| `cli-validate` | v1.11.0 / v1.12.0 | v1.11.0 Purpose 占位符 warning；v1.12.0 `--report findings`、advisory merge preflight findings（上游 `openspec/changes/add-validation-findings-report/` 的 design/tasks 是权威来源） |
| `ai-tool-paths` | v1.11.0 / v1.12.0 | v1.11.0 Antigravity `.agent`→`.agents`；v1.12.0 docs 对齐当前行为（#1707） |
| `command-generation` | v1.12.0 扩展 | 新增 SourceCraft Code Assistant adapter（`.codeassistant/commands/`） |

## v1.13.1→v1.14.0 新增/变更的 specs

`git diff bae58cf6 v1.14.0 -- openspec/specs/` 涉及 11 个既有 spec，无新增 capability 目录；requirement header 层面只有一处增删：

| spec | 变化 | 说明 |
|------|------|------|
| `cli-artifact-workflow` | 新增 requirement `Active Change Workflow Status`，移除 `Experimental Isolation` | 对应 view 在 active change 下显示 workflow status（逐 artifact 标 done/ready/blocked/skipped）；被移除的实验隔离 requirement 不再描述当前实现 |
| `ai-tool-paths`、`artifact-graph`、`cli-config`、`cli-init`、`cli-update`、`cli-view`、`legacy-cleanup`、`openspec-conventions`、`opsx-archive-skill`、`opsx-verify-skill` | scenario/正文级修订，无 requirement header 增删 | 其中 `opsx-verify-skill`（+109 行）与 `opsx-archive-skill` 对应 verify 模板按 status 契约重写与 archive sync 阻塞语义；`ai-tool-paths` 对应 10 个新工具目标的路径声明 |

## v1.14.1→v1.14.3 变更的 specs

`git diff v1.14.0 v1.14.3 -- openspec/specs/` 涉及 5 个既有 spec，无新增 capability 目录。requirement header 层面增删一处：

| spec | 变化 | 说明 |
|------|------|------|
| `artifact-graph` | **新增 requirement `Glob Nesting Limit`** | `generates` / `apply.tracks` 的 brace 或括号嵌套 >16 层时，在任何 glob 匹配之前报错并指名上限（#2061） |
| `cli-archive` | requirement 正文修订 | spec 更新确认提示的默认值从 "No" 改为 **"Yes"**（`Proceed with spec updates? (Y/n)`，回车即继续）；对应 `eb315c9d`（#2065）"文档跟代码不一致"三处修正之一 |
| `schema-resolution` | requirement 正文修订 | schema 解析顺序修正为 **CLI flag → change metadata → project config → planning-home default → 硬编码默认**——config 的 `schema` 现在优先于 planning-home 默认（原 spec 写反了）（#2065） |
| `opsx-verify-skill` | scenario 扩写 | REMOVED requirement 分支改为"先读主 spec 基线，必要时翻文件历史，基线只是标题重述视同缺失，拿不到就标 not verified 并跳过搜索"（#2083） |
| `telemetry` | 文案修订 | 首次提示增加 `or openspec config set telemetry.enabled false`（#2065） |

> 注意 `cli-archive` 与 `schema-resolution` 这两条属于**spec 追认既有代码**，不是本轮的行为变更——它们修正的是 spec 本身写错的地方。资料若按旧 spec 描述过"默认 No"或"config 优先于 flag"，需要改。

## v1.15.0→v2.1.1 新增/变更的 specs

`git diff v1.14.3..0c737dc1 -- openspec/specs/` 共涉及 25 个 spec（新增 8 个 capability 目录，修订 17 个既有 spec）：

| 提交 / 版本 | 涉及 spec | 说明 |
|-------------|-----------|------|
| `ebdd9a53`（#2128，v1.16.0） | **新增 8 个**：`cli-archive-instructions`、`cli-version`、`graceful-status-empty`、`oh-my-pi-tool`、`operation-guidance`、`opsx-apply-skill`、`opsx-bulk-archive-skill`、`opsx-update-skill`；并把 19 个已发布 change 的 delta 补归档进 `ai-tool-paths`、`change-creation`、`cli-archive`、`cli-artifact-workflow`、`cli-init`、`cli-show`、`cli-update`、`cli-validate`、`cli-view`、`command-generation`、`config-loading`、`context-injection`、`opsx-archive-skill`、`schema-resolution`、`specs-sync-skill`、`telemetry` | 上游一次性归档 19 个历史已发版 change，使主 `openspec/specs/` 追平此前代码已落地的功能（如 `show --diff`、`version`、`instructions archive`、`operations.*.guidance` 等） |
| `ae7ad750`（#2127，v1.16.0） | `cli-validate` | `openspec/config.yaml` 不可读或非法 YAML 时 `validate` 直接报错退出 1 |
| `05cc75f2`（#2172，v1.16.0） | `cli-completion` | 设置 `ZDOTDIR` 绝对路径时 zsh 补全写入 `$ZDOTDIR/.zshrc` |
| `ef170faa`（#2204，v1.16.1） | `cli-version` | 显式运行 `openspec version --check` 时不受 telemetry opt-out 与 CI 检测阻拦 |
| `5cd4f7f2`（#2229，v2.0.0） | `cli-completion` | Windows 下不再把 `cmd.exe` 误判为 PowerShell |
| `e6539de0`（#2277，v2.1.1） | `opsx-archive-skill`、`opsx-bulk-archive-skill` | **写任何主 spec 之前**先检查 `<changesDir>/archive/<target-name>` 是否已存在，冲突时立即停止 |

> **治理提醒**：v2.0.0 移除命令文件生成（#2223）与 v2.1.0/v2.1.1 接入 `skills` 包及全局作用域（#2241/#2283）并未同步重写 `openspec/specs/command-generation/spec.md`、`oh-my-pi-tool/spec.md` 等主 spec；核对投递层行为时，一律以真实 TypeScript 源码与 `../mechanisms/02-tool-delivery.md` 为准。
