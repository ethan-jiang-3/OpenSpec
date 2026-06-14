# CLI 地图

## 一句话定位

`openspec` CLI 不是单纯的“命令行工具集合”，而是 OpenSpec 工作流系统的本地运行时接口。它一头连着项目目录里的 `openspec/` 数据结构，一头连着人类用户和 AI 工作流。

更具体一点：

- 对人类来说，它是一个用来初始化、查看、校验、归档 change/spec 的工具。
- 对 OPSX 来说，它是一组稳定的本地协议端点，用来读取状态、获取模板、获取下一步说明、判断能否进入 apply、以及感知 schema。
- 对 IDE / AI 工具集成来说，它还是一个“投递目标”，`init` / `update` 会把工作流模板安装成 skills 或 commands。
- 对 workspace 来说，它还是跨仓库规划的协调接口，`workspace setup/open/update` 负责管理多仓库协作上下文。

## 三类受众 + workspace operator

### 1. 人类用户

人类用户关心的是：

- 我现在项目有没有启用 OpenSpec。
- 当前有哪些 change / spec。
- 某个 change 做到哪一步了。
- proposal / spec / design / tasks 是什么内容。
- 这个 change 合不合法，什么时候能 archive。
- 我该如何定制 schema、workflow、profile。
- 我有哪些 workspace，它们关联了哪些仓库。

对应常用命令：

- `init`
- `update`
- `list`
- `show`
- `validate`
- `archive`
- `config`
- `schema`
- `view`
- `workspace list` / `workspace doctor`

### 2. OPSX / AI 工作流

OPSX 关心的是：

- 当前 change 的结构化状态。
- 哪个 artifact 已完成，哪个被阻塞。
- 某个 artifact 的依赖、模板、输出路径、规则和上下文。
- apply 阶段是否可开始，缺少什么，任务跟踪文件里还有什么待办。
- 当前项目有哪些 schemas、某个 schema 的 templates 在哪里。

对应常用命令：

- `status --json`
- `instructions <artifact> --json`
- `instructions apply --json`
- `schemas --json`
- `templates --json`
- `list --json`
- `new change`

### 3. Workspace operator

Workspace operator 关心的是：

- 跨仓库规划的 workspace 如何创建和链接仓库。
- 如何在 agent/editor 中打开 workspace 上下文。
- workspace 级 skill 文件是否需要同步。
- workspace 级 change 的规划与仓库级 change 的关系。
- context store 和 initiative 的团队协调状态。

对应常用命令：

- `workspace setup` / `workspace link`
- `workspace open`
- `workspace update` / `workspace doctor`
- `new change`（workspace 上下文内）
- `context-store setup`
- `initiative create`

## 四层结构

### 1. 项目状态层

这是最底层，被 CLI 直接读写的状态对象主要在 `openspec/` 目录里：

- `openspec/changes/<change>/`
- `openspec/specs/<spec>/`
- `openspec/config.yaml`
- `openspec/schemas/`

这个层面上的对象包括：

- change
- spec
- artifact outputs，例如 `proposal.md`、`design.md`、`tasks.md`
- schema 定义
- 应用阶段跟踪文件

### 2. Workspace 层

在项目状态层之上，workspace 引入了跨仓库的规划状态：

- `.openspec-workspace/view.yaml` — workspace 视图状态（名称、链接仓库、已选工具、profile drift 记录）
- `workspace changes/` — workspace 级 change（使用 `workspace-planning` schema，不同于 repo-local `spec-driven`）
- `~/.local/share/openspec/workspaces/registry.yaml` — 本地 workspace 注册表

Workspace 的核心设计规则：**规划在 workspace 层，实现在 linked repo 层**。

- `PlanningHome` 抽象在运行时判断当前路径属于 workspace 还是 repo。
- workspace 的 skill 生成是 skills-only（此版本的约束），command 生成预留到后续版本。

### 3. 运行时解释层

这是 OpenSpec 的真正核心。CLI 不只是列目录，而是在解释这些文件的含义：

- `ArtifactGraph` 负责理解 schema 中 artifact 的依赖关系。
- `detectCompleted()` 根据 artifact 期望输出是否存在，判断哪些 artifact 已完成。
- `loadChangeContext()` 把 change、schema、graph、completed 状态组装成运行时上下文。
- `generateInstructions()` 把模板、规则、依赖、输出位置编译成 AI 可执行说明。

这一层决定了 workflow 命令的真正价值。在 workspace 上下文中，schema 解析会自动切换到 `workspace-planning`。

### 4. 工具投递层

这一层对应 `init` / `update` / `workspace update`：

- 根据全局配置里的 `profile` 决定启用哪些 workflow。
- 根据 `delivery` 决定是生成 skills、commands，还是两者都生成。
- 根据不同 AI 工具的 adapter，把同一份工作流内容格式化成不同外壳文件。
- `workspace update` 在 workspace root 生成 skills（skills-only 模式），并通过 `workspace_skills` 状态跟踪 profile drift。

也就是说，OpenSpec CLI 不只管理项目内容，还负责把“如何使用这些内容”的工作流安装到外部工具，**以及管理 workspace 级的跨仓库规划上下文**。

## 为什么 workflow 命令最关键

顶层命令里最值得重点理解的是：

- `openspec status`
- `openspec instructions <artifact>`
- `openspec instructions apply`
- `openspec new change`
- `openspec schemas`
- `openspec templates`

因为这组命令不是传统意义上的“操作命令”，而是工作流运行时 API：

- `status` 提供决策状态。
- `instructions` 提供下一步执行包。
- `new change` 提供运行实例。
- `schemas` / `templates` 提供工作流定义的可发现性。

## 如何理解每条命令

这套 digest 文档统一使用五个问题来理解命令：

1. 这条命令本质上想干什么。
2. 它读入什么信息。
3. 它产出什么信息。
4. 它产出之后影响谁。
5. 它与哪些命令边界相邻，但不能互相替代。

例如：

- `status` 不是“列文件”，而是“把 change 当前进度映射成 artifact 状态图”。
- `instructions` 不是“打印模板”，而是“把可执行上下文编译给 AI”。
- `apply` 不是“开始编码”，而是“把实施条件与任务清单编译成工作单”。
- `init` 不是“初始化目录”，而是“把 OpenSpec 工作流安装到具体 AI 工具”。

## 建议阅读路径

### 先抓主干

先读：

- `03-workflow-runtime-api.md`
- `06-opsx-call-chains.md`

因为这两篇最能解释“CLI 在整个项目里到底干什么”。

### 再补边界

然后读：

- `01-human-facing-cli.md`
- `02-machine-facing-cli.md`
- `05-config-profile-delivery.md`

### 最后查表

最后把：

- `07-command-io-matrix.md`
- `08-glossary-and-models.md`

当作长期参考页。
