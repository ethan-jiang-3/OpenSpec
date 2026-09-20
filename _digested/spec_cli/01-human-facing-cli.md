# 面向人类的 CLI

这一篇不按源码模块写，而按一个开发者实际会遇到的任务流来写。

## 1. 开启 OpenSpec

### `openspec init`

本质目标：

- 在项目里建立 OpenSpec 运行基础设施。
- 识别/配置 AI 工具目录。
- 根据 profile 和 delivery 生成对应 skills/commands。
- 在需要时创建 `openspec/config.yaml`。

输入：

- 目标项目路径。
- 可选 `--tools`，用于非交互指定配置哪些 AI 工具（v1.9.0 起含 `command-code`）。
- 可选 `--profile`，覆盖全局配置中的 profile。
- 可选 `--language <language>`：只在 greenfield 初始化时为新 `openspec/config.yaml` 种下 `context`，要求 artifact prose 使用该语言，同时保留英文结构 headings 与 `SHALL/MUST`。它不是持续的语言开关。
- 全局配置中的 `profile`、`delivery`、`workflows`。
- （v1.2.0+）自动检测项目目录中已存在的 AI 工具目录（如 `.claude/`、`.cursor/`），预选检测到的工具。

输出：

- 项目中的 `openspec/` 目录及配置文件。
- 对应 AI 工具目录中的 skills/commands 文件。
- 控制台上的“已创建 / 已刷新 / 已跳过 / 已删除”的安装报告。

影响：

- 它决定这个项目是否真正接入 OpenSpec 工作流。
- 它决定外部工具能不能看到实际安装的工作流入口。入口语法由宿主 adapter 决定：Claude 可以是 `/opsx:*`，Codex v1.8.0 是 `$openspec-*` skills，不能混为一谈。
- 它不会直接创建业务 change，但会决定后续 change workflow 以什么外壳呈现。

容易误解：

- 它不是只创建一个目录。
- 它更像“给项目安装一套工作流接入层”。
- 若已有 config，`--language` 拒绝覆盖并要求手工把语言说明加入 `context`；空值、多行、控制/不可见格式字符以及导致 context 超过 50KB 的值会在写文件前失败。
- v1.12.0 起 init 给空的 openspec/ 子目录写 `.gitkeep`，空目录会被 Git 跟踪；重跑 init 会安全恢复缺失的 marker 文件。
- v1.13.0 起 init/update 会点名 profile 没装的 workflow（如 core 之外的 new/continue/ff 等），不再让缺失的 `/opsx:` 命令读起来像安装坏了。

### `openspec update`

本质目标：

- 将已配置工具中的 OpenSpec 工作流文件更新到当前版本和当前配置。
- 同步 profile/delivery 变化，删除已取消的 workflow 产物。

输入：

- 项目路径。
- 现有工具配置状态。
- 当前 OpenSpec 版本。
- 全局配置中的 profile/delivery/workflows。

输出：

- 更新后的 skills/commands 文件。
- 删除不再需要的产物。
- 控制台上的更新计划与结果。

影响：

- 它让 IDE/AI 工具层的 workflow 外壳与当前配置一致。
- 它不会改变 change/spec 内容，但会改变用户和 AI 如何访问这些能力。

容易误解：

- 它不是业务数据升级工具。
- 它主要更新的是“工具接入层”。
- v1.7.0 的交互式 `update` 还能发现 PATH 中过旧的全局 CLI 并提示升级；它提示的是二进制版本，和当前源码 checkout 的 Git 版本是两件事。
- v1.8.0 起，`update` 会把旧 `.codex` skill 树原地迁移到共享的 `.agents/skills/`（Codex 与 vendor-neutral `agents` 目标共用根，`.openspec-target` marker 记录归属），并保留用户定制文件。v1.9.0 起，若 `.agents` 已被 `agents` 目标占用，遗留 Codex 升级不会劫持该树。
- v1.10.0 起该共享根由 Codex、Zed Agent 与 vendor-neutral `agents` 三方协调；Zed 的 tool id 是 `zed`。`update` 只有实际更新带 `requiresIdeRestart` 的 IDE-resident surface 才提示重启；CLI-only/skills 即时加载工具通常不提示。
- v1.13.0 起 `update` 会刷新内容已 drift 的生成文件（不只看版本戳，`d9e1a28c`）；v1.13.1 起与 init 共享同一套 IDE restart 提示逻辑，workflow 被移除时也准确提示。
- v1.11.0 起 Antigravity 从 `.agent` 迁入共享 `.agents/` 根；`resolveSharedSkillWriters()` 通用仲裁取代了硬编码的三方排序。init/update 均使用同一仲裁函数决定每个物理 root 的 active writer。（详见 `mechanisms/02-tool-delivery.md`。）

首次可读、且 action 真正到达 root `postAction` 的交互式 CLI 运行会在 stderr 一次性提示 `openspec completion install`；设置 `OPENSPEC_NO_COMPLETIONS=1` 可抑制。JSON、completion 自身、CI、非 TTY、已安装或不支持的 shell 不污染 stdout，其中 deferred 场景保留到以后可读运行。设置 `process.exitCode` 的失败仍会到达 hook；直接 `process.exit(1)` 的失败会跳过 hook且不消费提示。完整边界见 `../mechanisms/05-cli-infra.md`。

## 2. 发现当前项目里有什么

### `openspec list`

本质目标：

- 浏览当前活跃的 changes，或已有 specs。

输入：

- `openspec/changes/` 目录内容。
- 对每个 change 的任务跟踪信息。
- 每个 change 目录下文件的最近修改时间。

输出：

- 文本模式下的列表视图。
- `--json` 时的结构化 change 列表。

影响：

- 它帮助人类快速知道当前有哪些进行中的工作。
- 对机器来说，它也是一个轻量发现接口。

注意点：

- change 列表的“完成度”主要来自 tasks 进度，而不是 artifact graph。
- `list` 是概览，不是 workflow 决策引擎。
- v1.9.0 起，项目外跑 `list`（没有 OpenSpec root、也没有遗留 `openspec/project.md`）会失败并非零退出，不再假装空项目通过。`--json` 失败时带共享诊断而不是空数组。

### `openspec view`

本质目标：

- 提供一个交互式总览面板。

输入：

- 解析后的 OpenSpec root 中的 changes 和 specs；可用 `--store` 选择 store root。

输出：

- 交互式 dashboard。

影响：

- 更适合人工浏览，不适合作为机器协议端点。
- 它不能假定总是读取当前 cwd 下最近的 `openspec/`；v1.7.0 会按 root selection 读取被选中的 root。

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
- 或 `--json` 结构化内容（`--diff` 时 MODIFIED delta 增补 `diff` 和 `warning` 字段）。

影响：

- 是“看对象内容”的通用入口。
- 适合调试文档结构和解析结果。
- v1.11.0 的 `--diff` 让审阅者直接看清 delta 相对 main spec 真正改了哪些行（绿色新增、红色删除），不再需要人工文件 diff。

容易误解：

- 它不是 workflow 指令生成器。
- 它主要是展示已有内容，不负责判断下一步该做什么。

## 4. 校验内容是否合法

### `openspec validate`

v1.12.0 新增 `--report findings`（bulk scope 下只输出 findings 列表）；同版起 validate 预报 archive 会拒收的 delta。详见 `04-command-deep-dive.md`。

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

## 6. 配置 OpenSpec 的工作方式

### `openspec config`

本质目标：

- 管理全局 OpenSpec 配置。

重点不是业务 change，而是工作流投递策略：

- `profile`: 选哪些 workflows。
- `delivery`: 以 skills、commands 还是 both 的方式投递。
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

### `openspec store register <path> --id <id>`

将一个本地 repo checkout 注册为全局 store。可选 `--remote` 和 `--branch`。

### `openspec store list` / `unregister` / `info`

列出、注销、查看已注册的 store。

### `openspec context`

查看当前 working set：root + `config.yaml` 中 `references:` 声明的 store 的 spec 索引。输出可选 human JSON 或 `.code-workspace`。

### `openspec workset save` / `open` / `list`

保存、打开、列出个人本地的多仓库视图。纯本地，不共享。

### `openspec doctor`

检查 store reference 健康状态。

### 和 repo-local 的关系

Store 提供跨仓库的上下文引用，不替代 repo 级工作流。change 始终在具体 repo 下创建和 archive。设计原则：**上下文引用用 store，实现在 owning repo**。
