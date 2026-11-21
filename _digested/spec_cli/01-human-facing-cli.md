# 面向人类的 CLI

这一篇不按源码模块写，而按一个开发者实际会遇到的任务流来写。

## 1. 开启 OpenSpec

**全局行为（对下面所有命令生效）**：首次可读、且 action 真正到达 root `postAction` 的交互式 CLI 运行会在 stderr 一次性提示 `openspec completion install`；设置 `OPENSPEC_NO_COMPLETIONS=1` 可抑制。JSON、completion 自身、CI、非 TTY、已安装或不支持的 shell 不污染 stdout，其中 deferred 场景保留到以后可读运行。设置 `process.exitCode` 的失败仍会到达 hook；直接 `process.exit(1)` 的失败会跳过 hook且不消费提示。zsh 的 uninstall 自 v1.14.0 起与 bash 一样逐字节还原：只删 install 加的 separator 行（且仅当 block 在文件顶部），用户自己的空行不动。完整边界见 `../mechanisms/05-cli-infra.md`。

### `openspec init`

本质目标：

- 在项目里建立 OpenSpec 运行基础设施。
- 识别/配置 AI 工具（87 个可选工具）。
- 按 `profile` 与 `skillsScope` 安装对应的标准 skills（新项目默认安装到本机全局 `~/.agents/skills/`；v2.0.0 起不再生成 commands）。
- 在需要时创建 `openspec/config.yaml`。

输入：

- 目标项目路径。
- 可选 `--tools <all|none|ids>`，用于非交互指定配置哪些 AI 工具（支持 `windsurf → devin` 别名；传入退役工具如 `amazon-q` 会报错并指路 `kiro`）。
- 可选 `--scope <global|project>`：技能装在本机全局（默认，供本机所有项目使用）还是当前项目仓库内（`.agents/skills/` + 工具链接）；也可由环境变量 `OPENSPEC_SKILLS_SCOPE` 或全局 `config.json` 的 `skillsScope` 指定。
- 可选 `--profile <core|custom>`，覆盖全局配置中的 profile。
- 可选 `--language <language>`：只在 greenfield 初始化时为新 `openspec/config.yaml` 种下 `context`，要求 artifact prose 使用该语言，同时保留英文结构 headings 与 `SHALL/MUST`。它不是持续的语言开关。
- 可选 `--force`（免确认清理旧文件）、`--no-animation`（静态欢迎屏）、`--copilot-cloud` / `--no-copilot-cloud`（非交互显式启用/跳过 GitHub Copilot 云端 agent 文件；启用云端文件要求 `--scope project`）。
- 全局配置中的 `profile`、`workflows`、`skillsScope`（1.x 还有 `delivery`，v2.0.0 起退役）。
- （v1.2.0+）自动检测项目目录中已存在的 AI 工具目录（如 `.claude/`、`.cursor/`），预选检测到的工具。

输出：

- 项目中的 `openspec/` 目录及配置文件，项目路径记入 `<globalDataDir>/projects.json`。
- 全局（`~/.agents/skills/` 及各工具全局目录 + `.skill-lock.json`）或项目内（`.agents/skills/` 真身 + 工具相对链接/拷贝）的 `SKILL.md` 文件（1.x 的 commands 文件自 v2.0.0 起不再生成）。
- 控制台上的“已创建 / 已刷新 / 已跳过 / 已删除”的安装报告。

影响：

- 它决定这个项目是否真正接入 OpenSpec 工作流。
- 它决定外部工具能不能看到实际安装的工作流入口。入口语法由宿主决定：Claude Code 等是 `/openspec-*` 技能调用（1.x 是 `/opsx:*` 命令文件），Codex v1.8.0 是 `$openspec-*` skills，不能混为一谈。
- 它不会直接创建业务 change，但会决定后续 change workflow 以什么外壳呈现。

容易误解：

- 它不是只创建一个目录。
- 它更像“给项目安装一套工作流接入层”。
- 若已有 config，`--language` 拒绝覆盖并要求手工把语言说明加入 `context`；空值、多行、控制/不可见格式字符以及导致 context 超过 50KB 的值会在写文件前失败。
- v1.12.0 起 init 给空的 openspec/ 子目录写 `.gitkeep`，空目录会被 Git 跟踪；重跑 init 会安全恢复缺失的 marker 文件。
- v1.13.0 起 init/update 会点名 profile 没装的 workflow（如 core 之外的 new/continue/ff 等），不再让缺失的 `/opsx:` 命令读起来像安装坏了。
- v1.14.0 曾新增 10 个 `--tools` 目标（`dsh`、`codestudio`、`gigacode`、`atomcode`、`easycode`、`gsd`、`amp`、`grok`、`warp`、`veai`），并将 "Bob Shell" 更名为 "IBM Bob"（tool id `bob` 不变）；Kilo Code 1.x 命令目录修正为 `.kilo/command/`。**注意 v2.x 演进**：v2.0.0 起已全面移除 command 文件生成；v2.1 接入 `skills@1.8.1` 包后，`AI_TOOLS` 共 **87 个工具**（49 个 `existingTools` + 38 个从 `skills` 包自动追加；33 个 `universal` 工具直读 `.agents/skills/`，54 个工具建相对链接/拷贝），其中 `atomcode`、`costrict`、`dsh`、`easycode`、`gigacode`、`gsd`、`oh-my-pi`、`codeassistant`、`veai` 9 个工具回退到 `'universal'` `.agents/skills/`（不再创建 `.dsh/skills/` 或 `.veai/skills/`），仅 `eve` 与 `promptscript` 不支持全局技能。

### `openspec update`

本质目标：

- 将本机全局与项目内已配置工具的 OpenSpec skills 更新到当前版本和当前配置。
- 同步 `profile` 与作用域变化，删除已取消的 workflow 技能（1.x 的 `delivery` 已于 v2.0.0 退役）。
- 从任意旧版本（0.12 起）一次升级到位，并清扫旧版本留在项目里、**没人编辑过**的 OpenSpec 文件（含 1.x command 文件与退役工具残留）。

输入：

- 可选项目路径（**当本机已安装全局 skills 时，`openspec update` 不要求当前目录存在 `openspec/`**，在任意目录运行都能刷新全局 skills）。
- 现有全局与项目工具配置状态（含项目 `openspec/config.yaml` 的 `skillsScope: project`）。
- 当前 OpenSpec 版本。
- 全局配置中的 `profile` / `workflows`。
- 可选 `--force`（已是最新也强制重写）、`--dry-run`、`--json`（`--json` 只能与 `--dry-run` 同用）。

输出：

- 更新后的全局和/或项目 skills 文件（及各工具目录链接/拷贝）。
- 删除不再需要的产物，包括未选中的 workflow skills、未编辑过的 1.x command 文件，以及旧版本写在“当前版本根本不会写”的路径上且内容仍是某发布版原样输出的文件（清扫只回收空目录，不碰非空目录）。
- 控制台上的更新计划与结果；清扫过时会单独一行说明删了几个旧文件。
- `--dry-run` 时只报告计划：`add` / `update` / `delete`、每个文件归属的 tool、交互式运行会问的步骤（`notes`）、以及会失败的工具（`failures`，不中断其余计划）；不写任何文件。
- **`notes[].code` 是稳定代号，v2.x 从 2 个增到 6 个**（`src/core/update-plan.ts` 的 `UpdatePlanNoteCode`）：
  - 1.x 就有：`legacy-tool-directories`（要迁移的旧工具目录）、`legacy-artifacts`（要清理的旧产物）
  - v2.x 新增：`edited-skills`（技能被改过、会被替换）、`global-skills`（本次还会动到项目之外的全局技能）、`removed-skills`（会被移除的技能）、`left-alone-skills`（保留不动的技能）
  - `global-skills` 这条尤其要注意：dry-run 的 `changes[]` 只列**项目内**文件，而这条 note 说明还有**项目外**的动作，光看 `changes[]` 会以为什么都不动。

影响：

- 它让 IDE/AI 工具层的 workflow 外壳与当前配置一致。
- 它不会改变 change/spec 内容，但会改变用户和 AI 如何访问这些能力。

容易误解：

- 它不是业务数据升级工具。
- 它主要更新的是“工具接入层”。
- v1.7.0 的交互式 `update` 还能发现 PATH 中过旧的全局 CLI 并提示升级；它提示的是二进制版本，和当前源码 checkout 的 Git 版本是两件事。v1.14.0 起按需的版本/更新检查由 `openspec version [--check]` 承担，不必等一次交互式 update。
- v1.8.0 起，`update` 会把旧 `.codex` skill 树原地迁移到共享的 `.agents/skills/`（Codex 与 vendor-neutral `agents` 目标共用根，`.openspec-target` marker 记录归属），并保留用户定制文件。v1.9.0 起，若 `.agents` 已被 `agents` 目标占用，遗留 Codex 升级不会劫持该树。
- v1.10.0 起该共享根由 Codex、Zed Agent 与 vendor-neutral `agents` 三方协调；Zed 的 tool id 是 `zed`。`update` 只有实际更新带 `requiresIdeRestart` 的 IDE-resident surface 才提示重启；CLI-only/skills 即时加载工具通常不提示。
- v1.13.0 起 `update` 会刷新内容已 drift 的生成文件（不只看版本戳，`d9e1a28c`）；v1.13.1 起与 init 共享同一套 IDE restart 提示逻辑，workflow 被移除时也准确提示。
- v1.11.0 起 Antigravity 从 `.agent` 迁入共享 `.agents/` 根；1.x 时期曾用 `resolveSharedSkillWriters()` 仲裁每个物理 root 的 active writer（v2.0.0 已删除该函数，改由 `.agents/skills/` 单一真身 + `.openspec-target` 工具列表替代，详见 `mechanisms/02-tool-delivery.md`）。
- v1.15.0 起，预演和真实更新走同一条写入路径（`src/core/update-plan.ts` 的 `UpdateFileOps` 接缝：真实运行用 `realFileOps`，预演用 `UpdatePlanRecorder`）；它不是“少写一部分”的另一套逻辑。`--json` 单独使用会报 `--json is only available with --dry-run.`。
- v1.15.0 起，全局包管理器安装的用户在 update 后可能在 stderr 看到一次 standalone 提示（非 TTY/CI 延迟显示；只提示，不自动切换）。
- v1.17.0 起，`update` 能从 **0.12 以来任意版本一次跑完**，且**不再需要 `--force`**。删旧文件的判据不是版本戳（命令文件根本没有版本戳），而是内容指纹：内容归一化后，等于某个已发布版本原样写出过的文件才删。编辑过的旧文件**保留并列出**（`kept`），读不了/删不了的单独列为 `unchecked`。例外是 `~` 里的共享 prompt 文件——它被同一台机器的多个项目共用，仍然只在 `--force` 或终端确认时删除。
- v1.17.0 起，清扫**永不跨链接**：路径上任何一段是 symlink 就不搜索、不判断、不删除，即使加了 `--force` 也一样。工具更新失败或用户拒绝过清扫时，整个清扫跳过——旧文件可能还是该工具能用的唯一一份。
- v1.17.0 起，命令文件被标记弃用，`update` 在“某个已配置工具仍会得到命令文件”时打印提示（历史形态；该提示函数在 2.0 已删除）。
- v2.0.0 起（#2223），**命令文件不再生成**，`delivery` 配置项退役——skills / commands / both 三态不再存在，一律装 skills。`update` 按指纹清理早期版本生成的 command 文件：没人改过的删掉，改过的保留并列出。skills 只有一份真身，在 `.agents/skills/`；其他工具用自己的 `skills/` 目录放指向它的链接，建不了链接时退化为拷贝。
- v2.1.0 起（#2241），技能作用域分 `global`（新项目 `init` 默认，写入 `~/.agents/skills/`）与 `project`（`update` 保留在项目内时写入 `openspec/config.yaml` 的 `skillsScope: project`，团队不再被重复询问；全局 `config.json` 也可设默认 `skillsScope`）；非交互环境（CI、agent 调用）不弹问题，就地刷新。v2.1.1 起（#2283），`init` / `update` 把当前 npm 包内置的技能文本写进本地临时目录 `os.tmpdir()/openspec-skills-*` 再安装——完全离线、不依赖 `git` 或 GitHub 网络，版本永远与当前 CLI 一致。

### `openspec install [version]`

本质目标：

- 把当前 OpenSpec 换成不依赖 Node.js 的 standalone 单文件；默认装最新完整 release，也可钉一个版本。

输入：

- 可选版本号（如 `1.15.0`；省略或 `latest` 表示最新）。
- 官方安装脚本：`https://raw.githubusercontent.com/Fission-AI/OpenSpec/main/scripts/binary/install.sh`（Windows 为 `install.ps1`），所以代理/证书行为与文档里的一行安装命令一致。
- 环境变量：`OPENSPEC_INSTALL_DIR` 指定安装目录；`OPENSPEC_DOWNLOAD_URL` / `OPENSPEC_RELEASES_URL` 供镜像或测试；安装器自身还认 `OPENSPEC_VERSION`。

输出：

- 默认安装/覆盖 `~/.local/bin/openspec`（Windows：`%LOCALAPPDATA%\Programs\openspec\openspec.exe`）。
- 检查 PATH 上实际生效的是不是刚装的文件；若仍先命中旧副本，会说明先命中谁、要开新终端还是怎么切。
- 给出去掉旧包管理器副本的命令（npm / pnpm / yarn / bun / volta / brew）；**不会自动删**旧副本，切不切、什么时候切由用户决定。

影响：

- 安装形态从包管理器变成单文件；`openspec version` 会标 `(standalone)`。
- 不改项目内容与 config；切换后 CLI 自身的升级用 `openspec install` 原地重装，再跑一次 `openspec update` 刷新工具侧文件。

容易误解：

- 它不是“升级项目里的 OpenSpec 工作流文件”——那是 `openspec update`。
- 它不会替你卸载旧的全局包，只给命令。
- 它默认装“最新完整 release”，不是 `main` 分支快照；`latest` 也要等 `SHA256SUMS` 已上传才认。
- 单文件不需要 Node.js；但 `npm install -g` 方式需要 Node.js **22.20.0+**（v2.1.1 起；v1.16.0–v2.1.0 是 22.12.0；Node 20 已于 2026-04-30 EOL）。release 资产自 v1.16.0 起是 `.tar.gz`（Windows `.zip`）归档，不是裸二进制。

### `openspec version`

本质目标：

- 报告当前安装的 OpenSpec 版本与安装形态，需要时检查是否有新版本。

输入：

- 可选 `--json`：输出结构化报告。
- 可选 `--check`：只有带上它才查询 registry 对比最新版本；不带时完全不发网络请求。

输出：

- 默认人类可读的版本报告（版本、安装位置、包管理器、scope，以及 `--check` 时的更新结论）；standalone 安装的 scope 是 `standalone` 并标 `(standalone)`。
- `--json` 输出 `{ schemaVersion: 1, version, install, update? }`：`install` 含 `location` / `packageManager`（`npm`/`pnpm`/`bun`/`yarn`/`volta`/`homebrew`/`nix`/`null`）/ `scope`；`update` 只在 `--check` 时出现，含 `status`（`available`/`current`/`disabled`/`offline`）、`latest`，以及 `command` 与 `canSelfUpgrade`（`status: "available"` 时 `homebrew` 给 `brew upgrade openspec`，`nix` 因升级方式取决于 profile/flake/home-manager 而令 `command` 为 `null` 并在人类输出提示通过 Nix 升级，`src/core/version-check.ts:605-652,793-795`）。

影响：

- 它是自述与升级决策端点，不改任何项目或工具状态。
- 它把"这份安装是谁装的、能不能原地升级"的判断从用户转移给了 CLI（`version-check.ts` 的 `getCliInstallInfo` / `checkForCliUpdate` / `canSelfUpgrade` / `buildVersionReportLines`）。

容易误解：

- `disabled`（检查被关闭或 registry 不可用）与 `offline` 是显式状态而不是错误；`canSelfUpgrade` 会拒绝非默认 registry 等不确定归属的安装，不给出可能落错的升级命令。
- 它提示的是已安装二进制版本，和源码 checkout 的 Git 版本是两件事（与 `update` 的升级提示同口径）。
- v1.16.1 起（#2204），**显式 `--check` 不受遥测开关与 CI 检测影响**。用户主动要这一下，只有 `OPENSPEC_NO_UPDATE_CHECK` 和测试守卫还能挡；`update` 的后台检查**仍然**尊重 telemetry opt-out 与 CI。设计取舍写在源码注释里：设了 `DO_NOT_TRACK` 的用户没同意“另一种出站请求”，但主动敲 `--check` 是另一回事。
- v1.16.1 起（#2206），standalone 的 `--check` 只提示**真能装上**的版本：按 `install.sh` / `install.ps1` 的找法，在 releases atom 源里从新到旧找第一个 `SHA256SUMS` 存在的稳定 tag。npm 的 `latest` 不能当答案——它比 GitHub 资产早几分钟发布，资产 job 一失败就永远没有对应文件；提示一个装不上的版本，会让 `openspec install` 悄悄退回旧版。
- HTTP 实现从 `fetch` 换成 `node:http(s)`：abort 一个还在 TCP 握手的 `fetch`（防火墙丢包、强制门户）会留下连接句柄，CLI 退不出去，比提示本身还久。

## 2. 发现当前项目里有什么

### `openspec list`

本质目标：

- 浏览当前活跃的 changes、已归档的 changes，或已有 specs。

输入：

- `openspec/changes/` 目录内容；v1.14.0 起 `--archived`/`--all` 还会读 `changes/archive/` 子目录。
- 对每个 change 的任务跟踪信息。
- 每个 change 目录下文件的最近修改时间；archived 条目的 mtime 用 symlink 自身的 `lstat`（archive 里是移动过去的 symlink），移动 change 不再污染排序。

输出：

- 文本模式下的列表视图；`--all` 时 active 与 archived 分成两组各带标题。
- `--json` 时的结构化 change 列表；启用归档浏览（`--archived`/`--all`）时每个条目带 `archived: true/false`。
- 空输出文案三态：`--all` 是 `No changes found.`，`--archived` 是 `No archived changes found.`，默认是 `No active changes found.`。

影响：

- 它帮助人类快速知道当前有哪些进行中的工作。
- 对机器来说，它也是一个轻量发现接口。

注意点：

- change 列表的“完成度”主要来自 tasks 进度，而不是 artifact graph。
- `list` 是概览，不是 workflow 决策引擎。
- v1.9.0 起，项目外跑 `list`（没有 OpenSpec root、也没有遗留 `openspec/project.md`）会失败并非零退出，不再假装空项目通过。`--json` 失败时带共享诊断而不是空数组。
- `--archived` 与 `--all` 只对 change 列表有意义：`list --specs` 模式下带这两个 flag 会直接报错。
- **排序可切换**：`--sort <order>` 接受 `recent`（默认，按上面说的 mtime）或 `name`（按 change 名字母序）。默认口径见上；要按名字扫一遍用 `openspec list --sort name`。

### `openspec view`

本质目标：

- 提供一个交互式总览面板。

输入：

- 解析后的 OpenSpec root 中的 changes 和 specs；可用 `--store` 选择 store root。

输出：

- 交互式 dashboard。
- v1.14.0 起，每个 active change 行下新增 `└─ [schemaName]` workflow status 行，逐 artifact 标注状态（done 加 ✓、ready 加 →、blocked 置灰、skipped 标 `(skipped)`）；某个 change 的 workflow 加载不出来时保留任务进度并给出警告。
- **v1.14.1 起不再有 "Archived Changes" 分区**：dashboard 显示 `Draft Changes`（无任务项，`view.ts:29`）、`Active Changes`（任务未全完成，`view.ts:38`）、`Completed Changes`（任务全勾完，`view.ts:63`）与 `Specifications`（`view.ts:73`）——但**不读 archive 目录**。v1.14.0 引入的归档分区（以及它带来的"归档 change 也算进计数/排序"问题）被 #2031 整体撤回——要看归档记录用 `openspec list --archived`。

影响：

- 更适合人工浏览，不适合作为机器协议端点。
- 它不能假定总是读取当前 cwd 下最近的 `openspec/`；v1.7.0 会按 root selection 读取被选中的 root。
- 想看归档 change：`openspec list --archived` 或 `--all`（文本模式分两组、JSON 带 `archived` 标记），不要找 view。

## 3. 查看某个具体对象

### `openspec show <item>`

本质目标：

- 统一入口查看某个 change 或 spec 的内容。
- 自动识别 item 是 change 还是 spec，也支持 `--type` 强制指定。

输入：

- item 名称。
- 当前项目中可发现的 change IDs 和 spec IDs。
- 可能附带的显示 flags，比如 change 的 `--deltas-only`、`--diff`（v1.11.0 新增）。

输出：

- 人类可读内容。
- 或 `--json` 结构化内容（`--diff` 时 MODIFIED delta 增补 `diff` 和 `warning` 字段）。v1.14.0 起 requirement 与 scenario 带 `name` 字段：requirement 是 `{ name, text, scenarios: [{ name, rawText }] }`，name 由 `normalizeRequirementName` 规范化（去 `Requirement:` 前缀与收尾 `#` run），即 archive 匹配 MODIFIED/REMOVED/RENAMED 用的名字。

影响：

- 是“看对象内容”的通用入口。
- 适合调试文档结构和解析结果。
- v1.11.0 的 `--diff` 让审阅者直接看清 delta 相对 main spec 真正改了哪些行（绿色新增、红色删除），不再需要人工文件 diff。

容易误解：

- 它不是 workflow 指令生成器。
- 它主要是展示已有内容，不负责判断下一步该做什么。

## 4. 校验内容是否合法

### `openspec validate`

v1.12.0 新增 `--report findings`（bulk scope 下只输出 findings 列表）；同版起（#1710）validate 将 delta 内 merge-conflict 标记报告为 informational findings（不改退出码），并区分文件系统读取错误与 spec 缺失。详见 `04-command-deep-dive.md`。

本质目标：

- 校验 change delta specs 和正式 specs 是否符合 OpenSpec 结构规则。

输入：

- 指定的 change/spec，或通过 `--all`、`--changes`、`--specs` 批量发现的对象。
- v1.9.0 起可选 `--archived`：只检查 `changes/archive/` 里 tasks 是否全部勾完（独立 scope，不改其他 validate 调用）。
- strict 模式开关。
- 并发配置。

输出：

- 文本报告或 JSON 报告。
- 退出码体现是否合法。

影响：

- 是进入 archive 前最关键的守门器之一。
- 对 change 来说，重点检查 delta spec 结构和 scenario 完整性。
- 对 spec 来说，重点检查正式规范结构与 requirement/scenario 完整性。
- `--archived` 适合 CI / pre-commit，抓“归档时 tasks 没勾完”的工作；它不重验已应用的 delta。
- v1.14.0 起，`.openspec.yaml` 里出现已知键（`schema`/`created`/`goal`/`affected_areas`/`initiative`/`skip_specs`/`retire_capabilities`）之外的未知键会以 WARNING 报告（`status` 与 archive 流程同样告警）；`--strict` 下该 WARNING 升级为失败。
- v1.16.0 起（#2079），`Scenario:` 没有 WHEN/GIVEN 触发步、或没有 THEN 结果步时报告 **WARNING**。**级别很重要**：普通 `validate` 与 `archive` 的行为不变，只有 `--strict` 失败。该检查对 delta 与主 spec 走同一批 `#### ` 块，所以“什么都不断言”的场景在哪个位置都会被报出来；只写 AND 行或纯散文仍然算场景，但会被标警告。
- v1.16.1 起（#2207），requirement 落在 `## DEPRECATED Requirements`、`## Add Requirements` 这类“读起来像 delta 操作、但不是 ADDED/MODIFIED/REMOVED/RENAMED 四个合法段”的标题下时报告 **ERROR**：`validate` 报错，`archive` 拒绝。以前是“警告 + 静默丢掉那条 requirement”——这是本版收紧里唯一改级别的一处。`## Notes`、`## Behavior` 这类散文段下的孤立 requirement **仍是 WARNING**，区别在于标题是否读起来像 delta 操作。
- v1.16.0 起（#2127），`openspec/config.yaml` 读不了或 YAML 解析失败时 `validate` **退出 1**，而不是“通过但所有规则被忽略”。**只有 `validate` 硬失败**，其他命令仍只警告继续——CI 需要一个地方拦住坏 config。JSON 输出的 code 是 `unreadable_config` / `unparseable_config`。
- 解析器同步收紧（同版本）：v1.16.1 起（#2205）接受 CommonMark 闭合 `#` run，`## Purpose ##` 与 `## Purpose` 等价、`### Requirement: Foo ###` 的名字是 `Foo`（只有 `#` 前是空格/制表符才剥，所以 `C#` 保留 `#`）；v1.16.0 起（#2133）`###Requirement:`（**没有空格**）也按 archive 的读法进入主 spec 结构检查；v1.16.0 起（#2131）行内三反引号（```` ```npm test``` ````）不再被当成代码围栏开头——以前这一行会把**之后所有 requirement 都藏起来**。

容易误解：

- 它不是检查代码编译或测试结果。
- 它主要检查的是 OpenSpec 文档语义结构。
- `--all`/`--changes`/`--specs` 在项目外会失败（v1.9.0），不要把空结果当成“全部通过”。单条 `validate <name>` 不变。

## 5. 完成并 archive change

### `openspec archive [change]`

本质目标：

- 将一个 change 从”进行中 change”收束为”已纳入主 specs 的历史 change”。

它做的不只是移动目录，而是一个收尾流水线：

1. 校验 proposal 和 delta specs。
2. 查看 tasks 进度，必要时提醒仍有未完成项。
3. 找出 change 对主 specs 的影响。
4. 生成合并后的目标 spec 内容。
5. 对重建后的 spec 再做校验。
6. 写入更新后的 specs。
7. 将 change 目录移入 archive。

输入：

- 指定的 change。
- 该 change 下的 proposal、spec deltas、tasks。
- 主 `openspec/specs/` 目录。

输出：

- 更新后的正式 specs。
- 被移动到 archive 的 change 目录。
- archive 过程报告。

影响：

- 它是最强的状态改变命令之一。
- 它会改变主规范库，并改变 change 生命周期状态。

容易误解：

- 它不是简单的“标记完成”。
- 它真正做的是把 change 里的 delta specs 吸收到正式 specs。
- v1.16.1 起（#2207），delta spec 把 requirement 放在未识别的 `## ... Requirements` 段下时 archive **直接拒绝**，而不是“警告后把那一条悄悄丢掉”。理由很直接：archive 是唯一把 delta 合并进主 specs 的动作，静默丢弃等于让 change 声称做了它没做的事。散文段（`## Notes` 等）下的孤立 requirement 不在此列，仍是警告。

## 6. 配置 OpenSpec 的工作方式

### `openspec config`

本质目标：

- 管理全局 OpenSpec 配置。

重点不是业务 change，而是工作流投递策略：

- `profile`: 选哪些 workflows。
- `delivery`: 以 skills、commands 还是 both 的方式投递。**v2.0.0 起该配置项退役**（#2223）：一律 skills，配置里不再有这一项；写入它不再改变任何行为。v1.17.0 曾把 `commands` 标记弃用，切换时只删 OpenSpec 生成的命令文件、用户编辑过的保留并列出——这段处理逻辑随 2.0 一并移除。
- `workflows`: 自定义 profile 时启用哪些工作流。

输入：

- 全局配置文件。
- 用户交互选择。

输出：

- 更新后的全局配置。
- 配置差异提示。
- 对项目漂移的提醒，例如需要运行 `openspec update`。

影响：

- 它改变的是“工具层工作流可见性”，不是单个项目里的 change 内容。

### `openspec schema`

本质目标：

- 发现、初始化、检查 schema。

它面向的是“定制 workflow 的作者”，而不是普通使用者。

典型用途：

- 查看 schema 解析来源与 shadowing 情况。
- 校验 schema.yaml 及其 template 文件是否齐全。
- 初始化一个自定义 schema 脚手架。

影响：

- 它改变的是 workflow 定义层，而不是单次 change 内容。

## 7. workflow 命令对人类有什么价值

虽然 `status`、`instructions`、`new change` 更偏 runtime API，但人类直接用也很有价值。

### `openspec new change <name>`

本质目标：

- 创建一个新的 change 实例目录，并绑定 schema。

对人类意义：

- 这是把”一个新需求/change”正式放进 OpenSpec 生命周期的起点。

### `openspec status`

本质目标：

- 告诉你 change 的 artifact 走到哪一步，哪些已完成，哪些被阻塞。
- 默认看单个 change（`--change <name>`），v1.11.0 新增 `--all` 一次看全部 active change。
- v1.13.1 起 `status` 结尾输出 `Next:` 行，直接命名推进该 change 的下一条命令——恢复一个搁置的 change 不再需要背工作流。

对人类意义：

- 它比单纯看目录更清楚，因为它把依赖关系解释出来了。
- `--all` 适合 dashboards 和 CI，一个进程返回全部状态，单个 change 失败不阻塞其余。

### `openspec instructions <artifact> --change <name>`

本质目标：

- 输出一份完整的 artifact 编写说明。

对人类意义：

- 即使你不让 AI 自动执行，这也是一份极好的“下一步工作说明书”。

### `openspec instructions apply --change <name>`

本质目标：

- 输出 apply 阶段的实施说明，包括 artifact context files、项目 `context`、`operations.apply.guidance`、task 进度和阻塞状态。
- v1.14.0 起，`--json` 列出的每个任务项带 `sourcePath` 与 1-based `line`，可以直接定位到 tracking file 中的那一行勾选。

对人类意义：

- 它把“哪些文档应该先读、当前还缺什么、接下来怎么实施”说明白了。

### `openspec instructions archive --change <name>`

本质目标：

- 只读地输出 archive 阶段的输入包；v1.7.0 的 archive workflow 用它取得当前 context、`operations.archive.guidance` 与 change 状态。
- 它不移动目录，也不替代 `openspec archive <name>` 的写入动作。

## 面向人类的使用顺序

对于一个普通开发者，最自然的路径通常是：

1. `openspec init`
2. `openspec new change <name>`
3. `openspec status --change <name>`
4. `openspec instructions proposal/spec/design/tasks --change <name>`
5. `openspec show <item>` / `openspec validate`
6. `openspec instructions apply --change <name>`
7. `openspec instructions archive --change <name>`（需要 agent/archive 指引时）
8. `openspec archive <name>`

从这个顺序看，CLI 实际上协助人走完从提出 change 到 archive spec 的完整生命周期。它不是一堆孤立命令，而是一条工作流轨道。

## 8. Store / Context / Workset 命令

多条新命令各有独立职责：

`store` 的全部子命令是 `setup` / `register` / `unregister` / `remove` / `list`（别名 `ls`）/ `doctor`——**没有 `info`**。

### `openspec store register <path> --id <id>`

把一个**已存在的**本地 repo checkout 注册为全局 store。选项只有 `--id`（缺省取 store 元数据或文件夹名）、`--yes`（确认给一个健康的 OpenSpec root 写入 store identity 元数据）、`--json`。**`register` 上既没有 `--remote` 也没有 `--branch`**——`--remote <url>` 属于 `store setup`（它才是"新建并注册"），用来把规范 clone 源记进 `store.yaml`。

### `openspec store setup [id] --path <path> [--remote <url>] [--no-init-git]`

在本地新建并初始化一个 store 目录后注册到本机（**绝不执行 `git clone`**；`--remote <url>` 只作为团队 canonical clone 元数据写进 `.openspec-store/store.yaml`，也不跑 `git remote add origin`）。另有 `--init-git`（默认，初始化 Git 仓库并做首次提交）与 `--no-init-git`（跳过一切 Git 操作）及 `--json`。

### `openspec store list` / `unregister` / `remove` / `doctor`

列出、注销（保留文件）、注销**并删除**本地文件夹（`remove`）、检查注册与元数据健康（`doctor`）。

### `openspec context`

查看当前 working set：root + `config.yaml` 中 `references:` 声明的 store 的 spec 索引。输出可选 human JSON 或 `.code-workspace`。

### `openspec workset create` / `open` / `list` / `remove`

保存（`create`，写入 `<globalDataDir>/worksets/worksets.yaml`）、打开（`open`，每次重生成 `<globalDataDir>/worksets/<name>.code-workspace` 后交给工具打开；显式拒绝 `--json` 报 `workset_open_json_unsupported`；`code`/`cursor` 默认启用，`claude`/`codex` 等 `attach-dirs` CLI-agent opener 需设 `OPENSPEC_ENABLE_CLI_AGENT_OPENERS=1`）、列出、删除个人本地的多仓库视图。纯本地，不共享。**没有 `save` 子命令**——保存动作叫 `create`。

### `openspec doctor`

检查 store reference 健康状态。

### 和 repo-local 的关系

Store 提供跨仓库的上下文引用，不替代 repo 级工作流。change 始终在具体 repo 下创建和 archive。设计原则：**上下文引用用 store，实现在 owning repo**。
