# 命令输入输出矩阵

这一页适合做快速查表。前面的几篇讲思路，这一篇讲压缩后的全景视图。

## 说明

列的含义：

- 主要受众：更偏人类还是更偏机器。
- 输入来源：命令主要依赖哪些事实源。
- 直接输出：命令最直接产出的内容。
- 间接影响：命令产出会进一步影响谁。
- 是否改状态：是否会改变项目或工具状态。

## 总表

> **v1.13.1**：`status` 的 text 输出结尾新增 `Next: <command>` 行（仅 text，JSON 不变；`new change` 自 v1.5.0 即有同款收尾）。
>
> **v1.14.0**：新增 `version [--json] [--check]`；`list` 支持 `--archived/--all`；`view` 加 workflow status 行与 "Archived Changes" 分区；`show --json` 的 requirement/scenario 带 `name`；`status --json` 的 `actionContext.allowedEditRoots` 纳入 store 声明项目；`instructions apply --json` 的任务项带 `sourcePath`/`line`。
>
> **v1.14.1**：`view` **移除**了 v1.14.0 加的 "Archived Changes" 分区——归档多时它把活动工作挤出屏幕，现在只看当前工作；`list --archived/--all` 仍然照看归档。
>
> **v1.15.0**：新增 `install [version]`（standalone 安装/切换）；`update` 新增 `--dry-run`/`--json`；`version` 的 `scope` 可报 `standalone`；`new change` 的进度行显示实际解析出的 schema。standalone 状态下 `--check` 给出的升级命令是 `openspec install`。

| 命令 | 主要受众 | 输入来源 | 直接输出 | 间接影响 | 是否改状态 |
| --- | --- | --- | --- | --- | --- |
| `init` | 人类 + 工具集成 | 项目路径、global config（`profile`/`workflows`/`skillsScope`）、已检测工具目录、可选 `--tools` / `--scope <global\|project>` / `--profile` / `--language` / `--force` / `--no-animation` / `--copilot-cloud` / `--no-copilot-cloud` | `openspec/` 基础设施、全局 `~/.agents/skills/`（新项目默认）或项目 `.agents/skills/` + 工具链接的 `SKILL.md`（v2.0+ 不再生成 commands）、可选 Copilot cloud 文件、`<globalDataDir>/projects.json` 记录与安装报告 | 决定外部工具能否使用 OpenSpec 技能；`--copilot-cloud` 要求 `project` 作用域；已有 config 不被 `--language` 覆盖 | 是 |
| `update` | 人类 + 工具集成 | 可选路径（已装全局 skills 时无需 `openspec/`）、当前版本、global `profile`/`workflows`、项目 `openspec/config.yaml` `skillsScope`、可选 `--force` / `--dry-run` / `--json`（`--json` 必须配 `--dry-run`） | 刷新后的全局与项目 skills（v2.0+ 仅 skills）、清理未编辑的 1.x commands 与退役工具残留、同步报告；dry-run 时输出计划（`add/update/delete` + `notes` + `failures`），不落盘 | 决定本机全局与项目工具侧技能是否与当前版本及 profile 一致 | 是（dry-run 否） |
| `install [version]` | 人类 | 版本号（可选）、官方安装脚本、`OPENSPEC_INSTALL_DIR` | standalone 单文件装到 `~/.local/bin`（Windows：`%LOCALAPPDATA%\Programs\openspec`）；PATH 检查与移除旧副本的命令 | 切换 CLI 安装形态；不改项目内容 | 是（本机安装） |
| `version` | 人类 + 机器 | 当前安装（`location` / `packageManager`: `npm\|pnpm\|bun\|yarn\|volta\|homebrew\|nix\|null` / `scope`）；`--check` 时查 registry | 版本报告，或 `{ schemaVersion, version, install, update? }` JSON（`update` 仅 `--check` 时出现；`homebrew` 升级命令为 `brew upgrade openspec`，`nix` 的 `update.command` 为 `null`） | 提示用户是否/如何升级 CLI；standalone 的升级命令是 `openspec install` | 否 |
| `list` | 人类 + 机器 | changes/specs 目录（`--archived/--all` 含 `changes/archive/`）、task progress、mtime | 列表或 JSON 索引；归档浏览时条目带 `archived: true/false` | 帮助选择目标 change/spec | 否 |
| `view` | 人类 | resolved root 中的 changes/specs（可 `--store`） | 交互式 dashboard：展示 Draft、Active（带 `└─ [schemaName]` workflow status 行）、Completed changes 与 Specifications；**不含归档 change**（v1.14.1 #2031 起移除归档分区，归档改用 `openspec list --archived`） | 改善浏览体验 | 否 |
| `show` | 人类 + 机器 | 指定 change/spec 及其内容 | 对象展示或 JSON（requirement = `{ name, text, scenarios: [{ name, rawText }] }`） | 帮助人工审阅和调试解析结果；JSON 读者可按 `name` 引用 requirement | 否 |
| `validate` | 人类 + 机器 | change delta specs、正式 specs；`--archived` 时为 archive 目录的 tasks；bulk scope 可 `--report findings`（v1.12.0） | 合法性报告、退出码；findings 精简报告（JSON 标识 report/scope） | 决定是否需要修复、是否适合 archive；`--archived` 给 CI 抓未勾完的归档工作；merge-conflict 标记作为 informational findings 报告 | 否 |
| `archive` | 人类 + OPSX | change 内容、主 specs、validate 结果 | 更新后的 specs、archive 目录、报告 | 结束 change 生命周期 | 是 |
| `config` | 人类 | global config、workflow 选择 | 配置变更与摘要 | 影响后续 `init/update` 投递结果 | 是 |
| `schema` | 高级用户/作者 | schema 搜索路径、schema.yaml、templates | schema 列表、校验结果、脚手架 | 改变 workflow 定义层 | 可能 |
| `new change` | 人类 + OPSX | change 名称、schema、项目根目录 | 新建 change 目录与元数据 | 开启一个新的 workflow 实例 | 是 |
| `status` | 人类 + agent workflow | schema、artifact graph、已存在输出文件、`skip_specs` metadata、store/declaring project | artifact 状态图（可含 `skipped`）与 `actionContext`（`allowedEditRoots` 含 store 声明项目） | 决定下一步应推进哪个 artifact；store-only apply 的 edit scope | 否 |
| `instructions <artifact>` | OPSX + 高级用户 | change context、template、rules、dependencies | artifact instruction 包 | 影响 artifact 文档生成质量与顺序 | 否 |
| `instructions apply` | agent workflow + 高级用户 | apply config、context files、tasks、project context、operation guidance | apply instruction 包（任务项含 `sourcePath` + 1-based `line`） | 决定是否进入代码实施阶段；apply workflow 按定位勾选任务 | 否 |
| `instructions archive` | agent workflow + 高级用户 | change、project context、`operations.archive.guidance` | archive operation input | 为 archive skill 提供只读指引 | 否 |
| `templates` | 高级用户/工具 | schema 解析路径、artifact templates | 模板路径与来源 | 帮助调试模板覆盖与解析 | 否 |
| `schemas` | 高级用户/工具 | project/user/package schemas（canonical root；可 `--store`） | schema 列表与来源 | 帮助发现可用 workflow 模型 | 否 |
| `store setup` | 人类 + 机器 | 可选 `[id]`、`--path <path>`、可选 `--remote <url>`、`--init-git`/`--no-init-git`、`--json` | 本地 store 目录（`openspec/` + `.openspec-store/store.yaml`，含可选 `remote` 元数据，默认首次 Git 提交）并写入 `<globalDataDir>/stores/registry.yaml` | 在本地新建并注册 store（**绝不执行 `git clone`**） | 是 |
| `store register` | 人类 + 机器 | 可选本地 `[path]`、可选 `--id <id>`、`--yes`、`--json`（**无 `--remote`/`--branch`**） | `<globalDataDir>/stores/registry.yaml` 条目、必要时补写 `.openspec-store/store.yaml` | 全局注册已有的本地 store checkout | 是 |
| `store list`（`ls`） | 人类 + 机器 | `registry.yaml`、可选 `--json` | store 列表及 backend | 发现本机已注册的 store | 否 |
| `store unregister` | 人类 + 机器 | `<id>`、可选 `--json` | 从 `registry.yaml` 删除条目（保留本地文件） | 注销不再需要的 store 注册 | 是 |
| `store remove` | 人类 + 机器 | `<id>`、`--yes`、可选 `--json` | 从 `registry.yaml` 注销并删除本地 store 文件夹（拒绝删含嵌套已注册 store 的目录） | 彻底移除本机 store 注册与目录 | 是 |
| `store doctor` | 人类 + 机器 | 可选 `[id]`、可选 `--json` | 本地 store 注册表、目录与 `.openspec-store/store.yaml` 健康诊断 | 排查单个或全部本地注册 store 的状态问题 | 否 |
| `context` | 人类 + 机器 | root + `references` | working set（human / `--json` / `--code-workspace`） | 查看当前上下文引用的仓库 spec 索引 | 否（`--code-workspace` 写视图文件） |
| `workset create` / `list` / `remove` | 人类 + 机器 | `name`、`--member`（可重复）、`--tool <id>`、`--yes`（remove）、`--json` | `<globalDataDir>/worksets/worksets.yaml` 的增删查（绝不触碰 member 目录） | 保存、查看与删除个人本地多仓库视图定义 | 是（create/remove）/ 否（list） |
| `workset open` | 人类 + editor | `<name>`、可选 `--tool <id>`（**拒绝 `--json`**，报 `workset_open_json_unsupported`） | 重新生成 `<globalDataDir>/worksets/<name>.code-workspace` 并拉起 opener（`code`/`cursor` 默认启用；`claude`/`codex` 需 `OPENSPEC_ENABLE_CLI_AGENT_OPENERS=1`） | 一键在编辑器或会话中恢复多仓库工作视图 | 是（重生成 `.code-workspace`） |
| `doctor` | 人类 + 机器 | root、`references`、store registry | 项目级 store 引用与 root 诊断报告 | 排查项目 `references:` 到 store checkout 的健康度 | 否 |

## workflow 命令简表

| 命令 | 读入什么 | 产出什么 | 产出后帮助什么 |
| --- | --- | --- | --- |
| `new change` | 名称、schema、项目目录 | 新 change 实例 | 让后续状态与说明命令有上下文可挂载 |
| `status` | graph、completed outputs | readiness / blockedness | 选择下一步 artifact |
| `instructions <artifact>` | template、rules、deps、output path | 单个 artifact 的执行包 | 生成 proposal/spec/design/tasks |
| `instructions apply` | apply config、tasks、context files、operation inputs | apply 工作单 | 决定能否编码与如何编码 |
| `instructions archive` | change、project context、archive guidance | archive operation input | 归档前读取当前指引，不执行归档 |
| `templates` | schema 目录 | 模板定位信息 | 调试与理解 workflow 定义 |
| `schemas` | schema 搜索路径 | 可用 schema 列表 | 发现和选择工作流模型 |

## 哪些命令更像“本地 API”

最像本地 API 的是：

- `status --json`
- `instructions <artifact> --json`
- `instructions apply --json`
- `instructions archive --json`
- `schemas --json`
- `templates --json`
- `list --json`
- `version --json`
- `store list --json`

共同特征：

- 结构化输出明显。
- 结果更像中间语义而不是最终呈现。
- 常被 OPSX / 上层模板消费。

## 哪些命令最强地改变项目状态

最强的状态改变命令是：

- `init`
- `update`
- `new change`
- `archive`
- 部分 `config` / `schema` 子命令

其中：

- `init/update` 更偏改变工具接入层。
- `new change/archive` 更偏改变业务工作流状态。
- `store register` 更偏改变跨仓库上下文基础设施。
- `config/schema` 更偏改变系统配置与模型定义层。
