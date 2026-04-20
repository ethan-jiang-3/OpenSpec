# Workflow Runtime API

这是整套 CLI 里最关键的一层。这里专门讲几个 workflow 命令背后的核心思想。

## 总体认识

workflow 命令不是围绕“文本文件操作”设计的，而是围绕“change 生命周期推进”设计的。

它们背后统一处理的是几个运行时对象：

- schema
- artifact graph
- completed set
- change context
- apply phase config

其中最重要的逻辑是：

1. 用 schema 声明 artifact、依赖、输出路径、模板和 apply 配置。
2. 用 graph 把 artifact 关系组织起来。
3. 用文件存在性检测当前 change 已经完成了哪些 artifact。
4. 把这些状态编译成 status 或 instructions，供人和 AI 决策。

## 1. `openspec new change`

### 本质想干什么

把一个抽象的“我要开始做这件变更”转成一个具体的 change 实例目录。

### 输入

- change 名称。
- 可选 schema 名称。
- 可选简短描述。
- 项目根目录。

### 输出

- `openspec/changes/<name>/` 目录。
- change metadata，供后续自动检测 schema。
- 如果带描述，可能写入 `README.md`。

### 它影响什么

- 它创建了一个新的运行实例。
- 从这之后，`status`、`instructions`、`apply` 都有了上下文载体。
- 没有 change 目录，workflow 只能停留在抽象层。

### 它不负责什么

- 不负责生成 proposal/spec/design/tasks 内容。
- 不负责判断下一步该做什么。

### 它的系统意义

`new change` 的意义不是“建个文件夹”，而是“为一个 schema 驱动的生命周期实例化上下文”。

## 2. `openspec status`

### 本质想干什么

把一个 change 当前在 artifact 生命周期里的位置解释成状态图，而不是让用户自己读目录猜。

### 输入

- `changeName`
- 可选 `schema`
- project root
- schema 中声明的 artifacts
- change 目录中当前已经存在的输出文件

### 内部处理

它背后大体做四件事：

1. 校验 change 是否存在。
2. 解析 schema，构建 `ArtifactGraph`。
3. 通过输出文件存在性检测 completed artifacts。
4. 把 graph + completed set 格式化成状态对象。

### 输出

文本模式下，人看到的是：

- change 名称
- schema 名称
- 完成数
- 每个 artifact 的状态
- 哪些 artifact 被哪些依赖阻塞

JSON 模式下，本质上输出的是一个结构化 `ChangeStatus`。

### 状态语义

最关键的不是 done 数量，而是 artifact 状态分类：

- `done`: 输出已存在。
- `ready`: 依赖已满足，可以开始创建。
- `blocked`: 依赖未满足，暂时不应创建。

### 它影响谁

- 人类用户会据此决定下一步该写 proposal、spec、design 还是 tasks。
- OPSX 会据此决定 `/opsx:continue` 该推进哪个 artifact。
- apply 阶段的入口判断也依赖这个状态背景。

### 它帮助什么

- 避免 out-of-order 乱写 artifact。
- 让 workflow 具有确定的推进顺序。
- 把“目录现状”翻译成“流程状态”。

### 核心思想

`status` 不是做展示，它是在做“状态投影”：

把文件系统里的事实投影为工作流层的 readiness / blockedness。

## 3. `openspec instructions <artifact>`

### 本质想干什么

为一个具体 artifact 编译出一份 AI 可执行说明包。

### 输入

- `changeName`
- `artifactId`
- 可选 schema
- schema 里的 artifact 定义
- template 文件
- 已完成 artifacts
- 项目 config 中的 context 与 rules

### 内部处理

它内部主要做这些事情：

1. 加载 change context。
2. 在 graph 中找到目标 artifact。
3. 读取 artifact 对应 template。
4. 计算依赖列表及其完成状态。
5. 计算当前 artifact 完成后会解锁哪些 artifact。
6. 读取项目 config 里的公共 context 和该 artifact 对应 rules。
7. 拼装成 `ArtifactInstructions`。

### 输出包含什么

- artifact 基础身份信息
- 输出路径
- artifact 描述与 instruction
- project context
- artifact rules
- dependencies
- template 内容
- unlocks

文本输出采用了标签化结构，例如：

- `<artifact>`
- `<warning>`
- `<task>`
- `<project_context>`
- `<rules>`
- `<dependencies>`
- `<output>`
- `<instruction>`
- `<template>`
- `<unlocks>`

### 它影响谁

- 直接影响 AI 如何生成 proposal/spec/design/tasks。
- 也影响人工撰写时的结构和边界。

### 它帮助什么

- 把“文档模板 + 依赖上下文 + 项目规则”一次性打包。
- 降低 AI 自己到处读文件、猜顺序、猜格式的需要。

### 它不做什么

- 它不直接写文件。
- 它不负责验证最终内容是否合规。

### 核心思想

`instructions <artifact>` 不是查看器，而是编译器。

它把零散的 workflow 资源编译成一个“单步执行包”。

## 4. `openspec instructions apply`

### 本质想干什么

把文档阶段的产物编译成实施阶段的工作单，并判断当前能否进入 apply。

### 输入

- `changeName`
- schema.apply 配置
- required artifacts
- tracking file 路径
- 当前已存在的 artifact 输出文件
- tasks 文件内容

### 内部处理

它主要做六件事：

1. 读取 schema 的 apply 配置。
2. 确认 apply 前置要求需要哪些 artifacts。
3. 检查这些 prerequisite artifacts 是否已经产生输出。
4. 收集所有现存 artifact 输出文件作为 context files。
5. 如果配置了 tracking file，则解析 tasks 内容和完成状态。
6. 归纳当前 apply state，并给出 instruction。

### 输出包含什么

- `state`
- `contextFiles`
- `progress`
- `tasks`
- `missingArtifacts`
- `instruction`

### 典型状态

#### `blocked`

触发条件可能有：

- apply 依赖的 artifacts 还没生成。
- tracking file 被要求存在，但文件还不存在。
- tracking file 存在，但里面没有任务。

意义：

- 现在不能进入代码实施，应该先补前置文档或任务清单。

#### `ready`

触发条件：

- 必需 artifacts 已齐备。
- 如果需要 tracking file，则也已存在并含有任务，或者 schema 根本不要求 tracking file。

意义：

- 可以开始基于上下文文件实施改动。

#### `all_done`

触发条件：

- tracking file 中任务全部完成。

意义：

- apply 阶段已经完成，下一步更接近验证和归档。

### 它影响谁

- `/opsx:apply` 直接依赖这个命令来决定要不要开始编码。
- AI 会根据 `contextFiles` 决定要先读哪些文档。
- 人也能据此理解“为什么 apply 被拦住了”。

### 它帮助什么

- 在文档产物与代码实施之间建立桥梁。
- 防止在缺少 proposal/spec/design/tasks 的情况下直接进入实现。
- 提供一致的 apply 阶段入口检查。

### 核心思想

`instructions apply` 不是“去执行 apply”，而是“编译 apply 的前置条件与实施上下文”。

## 5. `openspec templates`

### 本质想干什么

暴露 schema 中每个 artifact 实际会解析到哪个 template 文件。

### 输入

- schema 名称
- schema 解析结果
- schema 所在目录

### 输出

- 每个 artifact 对应的 template 路径
- 模板来源层级：project / user / package

### 它影响什么

- 帮助调试 schema 覆盖问题。
- 帮助理解为什么某个 artifact 最终使用了这份模板。

### 核心思想

模板系统是 workflow 定义的一部分，而不是隐藏实现细节。`templates` 把它公开了出来，便于观察和诊断。

## 6. `openspec schemas`

### 本质想干什么

列出当前项目可见的 workflow schemas。

### 输入

- schema 搜索路径上的 project/user/package 三层来源。

### 输出

- schema 名称
- 描述
- artifact 顺序
- 来源信息

### 它影响什么

- 决定工作流有哪些模型可选。
- 对 schema 作者和高级使用者非常重要。

### 核心思想

OpenSpec workflow 不是硬编码的单一流程，而是由 schema 定义驱动的流程族。`schemas` 暴露的是这个“流程定义空间”。

## runtime API 的共同本质

把这些命令放在一起看，会更容易理解：

- `new change` 创建实例。
- `status` 读取实例状态。
- `instructions <artifact>` 编译单步说明。
- `instructions apply` 编译实施说明。
- `templates` 暴露模板解析结果。
- `schemas` 暴露可用流程定义。

它们一起构成了一套本地 workflow runtime API。

这也是为什么在整个项目里，workflow 命令远比表面上看起来更重要。它们不是附属功能，而是 OpenSpec 能被 AI 驱动起来的核心接口层。

