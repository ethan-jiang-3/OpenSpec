# CLI 地图

## 一句话定位

`openspec` CLI 不是单纯的“命令行工具集合”，而是 OpenSpec 工作流系统的本地运行时接口。它一头连着项目目录里的 `openspec/` 数据结构，一头连着人类用户和 AI 工作流。

更具体一点：

- 对人类来说，它是一个用来初始化、查看、校验、archive change/spec 的工具。
- 对 agent workflow 来说，它是一组稳定的本地协议端点，用来读取状态、获取模板、获取下一步说明、判断能否进入 apply/archive、以及感知 schema。
- 对 IDE / AI 工具集成来说，它还是一个“投递目标”，`init` / `update` 会把工作流模板安装成 skills 或 commands。
- 对 store operator 来说，它提供跨仓库上下文引用接口，`store register`/`context`/`workset` 负责管理多仓库 spec 引用。

## 三类受众

### 1. 人类用户

人类用户关心的是：

- 我现在项目有没有启用 OpenSpec。
- 当前有哪些 change / spec。
- 某个 change 做到哪一步了。
- proposal / spec / design / tasks 是什么内容。
- 这个 change 合不合法，什么时候能 archive。
- 我该如何定制 schema、workflow、profile。
- 有哪些已注册的 store，它们的 specs 是否可引用。

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
- `store list` / `context`

### 2. Agent / AI 工作流

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
- `instructions archive --json`
- `schemas --json`
- `templates --json`
- `list --json`
- `new change`

### 3. Store operator

Store operator 关心的是：

- 哪些 repo checkout 已注册为 store。
- 当前项目的 `references:` 声明了哪些 store。
- working set 中哪些 store 可用、哪些缺失。
- 如何保存和恢复多仓库打开视图。

对应常用命令：

- `store register` / `store list`
- `context`（human/JSON/.code-workspace）
- `workset save` / `workset open` / `workset list`
- `doctor`

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

### 2. Store 层

store 引入了跨仓库的上下文引用（不创建规划状态，只做索引）：

- `~/.openspec/stores/registry.yaml` — 全局 store 注册表
- `<checkout>/.openspec-store/store.yaml` — store 身份 metadata
- `openspec/config.yaml` 的 `references:` — 项目声明的 store 依赖
- `openspec context` — working set 查询

Store 的核心设计规则：**上下文引用用 store，实现在 owning repo**。

### 3. 运行时解释层

这是 OpenSpec 的真正核心。CLI 不只是列目录，而是在解释这些文件的含义：

- `ArtifactGraph` 负责理解 schema 中 artifact 的依赖关系。
- `detectCompleted()` 根据 artifact 期望输出是否存在，判断哪些 artifact 已完成。
- `loadChangeContext()` 把 change、schema、graph、completed 状态组装成运行时上下文。
- `generateInstructions()` 把模板、规则、依赖、输出位置编译成 AI 可执行说明。

这一层决定了 workflow 命令的真正价值。当前基线见 [`../README.md`](../README.md)：内置 change 默认使用 `spec-driven` schema，但项目也可以选择或提供自定义 schema；不要把历史版本中的默认值写成所有 change 的永久限制。

### 4. 工具投递层

这一层对应 `init` / `update`：

- 根据全局配置里的 `profile` 决定启用哪些 workflow。
- 根据 `delivery` 决定是生成 skills、commands，还是两者都生成。
- 根据不同 AI 工具的 adapter，把同一份工作流内容格式化成不同外壳文件。

也就是说，OpenSpec CLI 不只管理项目内容，还负责把”如何使用这些内容”的工作流安装到外部工具。

## 为什么 workflow 命令最关键

顶层命令里最值得重点理解的是：

- `openspec status`
- `openspec instructions <artifact>`
- `openspec instructions apply`
- `openspec instructions archive`
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
