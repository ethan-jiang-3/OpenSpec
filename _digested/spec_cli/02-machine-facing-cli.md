# 面向机器的 CLI

这一篇专门解释：如果把 `openspec` 当成本地 runtime API，它究竟提供了哪些接口。

核心观点只有一句话：

OpenSpec 里的 OPSX 工作流并不是“纯 prompt 魔法”，而是反复调用 `openspec` CLI 来读取结构化状态、编译上下文，再把这些结果转成后续行动。

## 机器为什么偏爱这些命令

面向机器的命令通常有四个特征：

- 可以稳定地从项目目录推导结果。
- 支持 `--json`，便于程序消费。
- 结果不是最终业务内容，而是工作流决策材料。
- 其输出会直接影响 AI 下一步怎么做。

## 机器最依赖的命令

### `openspec list --json`

作用：

- 发现当前项目有哪些 active changes。
- 提供轻量的索引信息，例如任务完成度和最后修改时间。

对机器的意义：

- 在不知道 change 名称时做候选发现。
- 为选择“当前最相关 change”提供第一层线索。

限制：

- 它并不理解 artifact 依赖。
- 它不能替代 `status`。

### `openspec status --change <name> --json`

作用：

- 读取某个 change 在特定 schema 下的 artifact 完成状态。
- 把结果组织成 `done` / `ready` / `blocked` 等可决策状态。

对机器的意义：

- 它是“下一步该生成哪个 artifact”的主要判断依据。
- 它让 AI 不必自己扫目录推导依赖状态。

为什么重要：

- AI 不擅长可靠地自己做文件系统状态判断。
- `status` 把这件事收敛成一个稳定端点。

### `openspec instructions <artifact> --change <name> --json`

作用：

- 为某个 artifact 编译执行说明包。

这个包通常包含：

- artifact 基本信息。
- 变更名、schema 名、change 目录。
- 输出路径。
- artifact 描述和 instruction。
- 项目级 context。
- artifact 级 rules。
- 依赖 artifact 及其路径和完成状态。
- template 内容。
- 当前 artifact 完成后会解锁哪些 artifact。

对机器的意义：

- 这是生成 proposal/spec/design/tasks 的直接输入。
- AI 模板不需要自己知道 schema 如何存储模板，也不需要自己去算依赖和 unlocks。
- 它把“生成这个 artifact 所需的一切”都编译好了。

### `openspec instructions apply --change <name> --json`

作用：

- 为 apply 阶段编译实施工作单。

这个结果通常包含：

- `state`: `blocked` / `ready` / `all_done`
- `contextFiles`: 可作为实施上下文的 artifact 输出文件集合
- `progress`: 任务总数、已完成、剩余
- `tasks`: 从 tracking file 解析出来的任务项
- `missingArtifacts`: 缺少哪些 prerequisite artifacts
- `instruction`: 当前阶段应执行什么

对机器的意义：

- 这是代码实现阶段最关键的桥接接口。
- 它把文档阶段产物转换成实施阶段输入。
- 它还负责在不满足前置条件时明确阻止进入 apply。

### `openspec schemas --json`

作用：

- 枚举当前项目可见的 schemas 及其来源和 artifact 顺序。

对机器的意义：

- 让上层工作流知道有哪些 workflow 模型可以选。
- 让自定义 schema 的工具或模板具备发现能力。

### `openspec templates --schema <name> --json`

作用：

- 告诉上层：某个 schema 下每个 artifact 对应哪个 template 文件，来源于 project/user/package 哪一层。

对机器的意义：

- 调试 template 覆盖。
- 排查为什么一个 artifact 指向了某个模板。
- 帮助更高级的 tooling 构建 schema 解释视图。

### `openspec new change <name>`

作用：

- 创建一个新的 change 目录实例。

对机器的意义：

- 让工作流从“抽象意图”进入“可落地 change 上下文”。
- 许多 `/opsx:*` 先要确保 change 存在，后续状态与文档生成才有挂载点。

## 机器接口的共同模式

### 模式 1：从文件系统恢复状态

这些命令大量依赖项目目录作为事实来源：

- 哪些文件存在。
- schema 定义如何声明 artifact 和依赖。
- 某个 change 目录内目前有哪些产物。
- tasks 文件中勾选到了哪一步。

也就是说，CLI 不是依赖数据库，而是依赖“项目目录 + schema + 文档结构”。

### 模式 2：输出结构化的中间语义

它们通常不直接返回“请你写一篇 proposal”这类自然语言结论，而是返回中间语义：

- 当前状态
- 依赖关系
- 缺失项
- 输出位置
- 模板
- 规则
- 任务
- 可用 schema

上层模板/agent 再根据这些中间语义采取动作。

### 模式 3：CLI 负责确定性，AI 负责生成性

这里的职责分工非常清楚：

- CLI 负责确定性推导。
- AI 负责生成文档、修改代码、执行人类友好交互。

例如：

- “proposal 模板在哪”这种问题交给 CLI。
- “proposal 内容怎么写”这种问题交给 AI。
- “当前是否允许 apply”这种问题交给 CLI。
- “apply 时如何组织修改步骤”这种问题交给 AI。

## 对机器最关键的不是文本，而是语义稳定性

从 OPSX 的角度看，真正重要的不是 CLI 文本输出漂亮不漂亮，而是这些输出是否稳定表达了：

- item identity
- schema identity
- artifact dependency
- readiness
- context package
- implementation gate

正因如此，`--json` 输出和内部 graph / instruction loader 层才如此重要。

**v1.3.1 重要修复**：此前 `--json` 模式下，spinner 的进度文本仍会泄漏到 stderr，导致 agent 在合并 stdout+stderr 时 JSON 解析失败。v1.3.1 修复了这个问题 —— `--json` flag 传入后，完全抑制 spinner 输出，agent 可以安全合并 stdout/stderr。

## 为什么说 workflow 命令像本地 API

如果从调用方式上看，`status` 和 `instructions` 的体验像普通命令；但从系统角色看，它们更像本地 API：

- 参数就是请求。
- JSON 结果就是响应。
- schema 和文件系统就是数据源。
- AI 模板是客户端。

所以理解 OpenSpec CLI 时，不应只视其为”终端工具”，还应视其为”工作流内核暴露出的本地协议”。

## store 级机器接口

### `openspec store list --json`

- 列出已注册 store 及其 backend 的结构化信息。
- 帮助 agent 发现可用的跨仓库上下文。

### `openspec context --json`

- 输出 working set（root + referenced stores 的 spec 索引）。
- agent 可据此了解当前项目还关心哪些仓库的 specs。

### `--store <id>` flag

- 所有核心命令（`status`、`instructions`、`list` 等）支持 `--store <id>` 选择操作目标 store。
- 无 `--store` 时默认使用 nearest `openspec/` 目录。

### v1.5.0 的 guardrail 变化

v1.4.0 的 workspace guardrail（`actionContext.mode = "workspace-planning"` 阻止 sync/archive）在 v1.5.0 中不再需要——因为 `actionContext.mode` 始终为 `repo-local`，不存在 workspace 级 change。跨仓库操作自然被 store reference 的只读语义保护。
