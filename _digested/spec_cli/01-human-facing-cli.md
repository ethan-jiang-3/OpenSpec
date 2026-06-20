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
- 可选 `--tools`，用于非交互指定配置哪些 AI 工具。
- 可选 `--profile`，覆盖全局配置中的 profile。
- 全局配置中的 `profile`、`delivery`、`workflows`。
- （v1.2.0+）自动检测项目目录中已存在的 AI 工具目录（如 `.claude/`、`.cursor/`），预选检测到的工具。

输出：

- 项目中的 `openspec/` 目录及配置文件。
- 对应 AI 工具目录中的 skills/commands 文件。
- 控制台上的“已创建 / 已刷新 / 已跳过 / 已删除”的安装报告。

影响：

- 它决定这个项目是否真正接入 OpenSpec 工作流。
- 它决定外部工具能不能看到 `/opsx:*` 这类工作流入口。
- 它不会直接创建业务 change，但会决定后续 change workflow 以什么外壳呈现。

容易误解：

- 它不是只创建一个目录。
- 它更像“给项目安装一套工作流接入层”。

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

### `openspec view`

本质目标：

- 提供一个交互式总览面板。

输入：

- 项目中的 changes 和 specs。

输出：

- 交互式 dashboard。

影响：

- 更适合人工浏览，不适合作为机器协议端点。

## 3. 查看某个具体对象

### `openspec show <item>`

本质目标：

- 统一入口查看某个 change 或 spec 的内容。
- 自动识别 item 是 change 还是 spec，也支持 `--type` 强制指定。

输入：

- item 名称。
- 当前项目中可发现的 change IDs 和 spec IDs。
- 可能附带的显示 flags，比如 change 的 `--deltas-only`。

输出：

- 人类可读内容。
- 或 `--json` 结构化内容。

影响：

- 是“看对象内容”的通用入口。
- 适合调试文档结构和解析结果。

容易误解：

- 它不是 workflow 指令生成器。
- 它主要是展示已有内容，不负责判断下一步该做什么。

## 4. 校验内容是否合法

### `openspec validate`

本质目标：

- 校验 change delta specs 和正式 specs 是否符合 OpenSpec 结构规则。

输入：

- 指定的 change/spec，或通过 `--all`、`--changes`、`--specs` 批量发现的对象。
- strict 模式开关。
- 并发配置。

输出：

- 文本报告或 JSON 报告。
- 退出码体现是否合法。

影响：

- 是进入 archive 前最关键的守门器之一。
- 对 change 来说，重点检查 delta spec 结构和 scenario 完整性。
- 对 spec 来说，重点检查正式规范结构与 requirement/scenario 完整性。

容易误解：

- 它不是检查代码编译或测试结果。
- 它主要检查的是 OpenSpec 文档语义结构。

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

### `openspec status --change <name>`

本质目标：

- 告诉你当前 change 的 artifact 走到哪一步，哪些已完成，哪些被阻塞。

对人类意义：

- 它比单纯看目录更清楚，因为它把依赖关系解释出来了。

### `openspec instructions <artifact> --change <name>`

本质目标：

- 输出一份完整的 artifact 编写说明。

对人类意义：

- 即使你不让 AI 自动执行，这也是一份极好的“下一步工作说明书”。

### `openspec instructions apply --change <name>`

本质目标：

- 输出 apply 阶段的实施说明，包括 context files、task 进度和阻塞状态。

对人类意义：

- 它把“哪些文档应该先读、当前还缺什么、接下来怎么实施”说明白了。

## 面向人类的使用顺序

对于一个普通开发者，最自然的路径通常是：

1. `openspec init`
2. `openspec new change <name>`
3. `openspec status --change <name>`
4. `openspec instructions proposal/spec/design/tasks --change <name>`
5. `openspec show <item>` / `openspec validate`
6. `openspec instructions apply --change <name>`
7. `openspec archive <name>`

从这个顺序看，CLI 实际上协助人走完从提出 change 到 archive spec 的完整生命周期。它不是一堆孤立命令，而是一条工作流轨道。

## 8. Workspace 命令

Workspace 命令面向的场景是：你同时维护多个关联仓库（如 API + Web + Mobile），需要在规划层协调它们。

### `openspec workspace setup`

创建跨仓库规划 home。交互式流程会引导你：
- 给 workspace 命名（kebab-case）
- link 至少一个本地目录
- 选择 preferred opener（VS Code / Codex / Claude / Copilot）
- 选择要为 workspace 生成的 AI 工具 skills

也支持非交互：`openspec workspace setup --no-interactive --name platform --link /path/to/api --link web=/path/to/web`

### `openspec workspace list` / `ls`

列出本地所有已知 workspace 及其 links。

### `openspec workspace link <path>`

将另一个仓库加到已有 workspace 中。link name 默认从目录 basename 推断，可以用 `name=path` 显式命名。

### `openspec workspace open`

在 agent 或 editor 中打开 workspace：
- 生成/刷新 `AGENTS.md`（workspace 级 agent 指导）
- 生成 `.code-workspace`（VS Code 多根工作区文件）
- 可绑定 initiative：`--initiative team-context/billing-launch`

### `openspec workspace update`

刷新 workspace 级的 skill 文件（与 repo-local `openspec update` 不同：workspace 的投递是 skills-only）。

### `openspec workspace doctor`

诊断：哪些 link 的路径在当前机器上不存在、是否需要 relink。

### 与其他命令的关系

Workspace 不替代 repo 级工作流，而是提供一个上一层级的规划层。设计规则：**规划在 workspace，实现在 linked repo**。在 workspace 内创建 change 用的是 `workspace-planning` schema，在各 repo 内创建 change 用的还是 `spec-driven`。
