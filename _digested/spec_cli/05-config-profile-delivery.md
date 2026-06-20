# 配置、Profile 与 Delivery

这一层非常关键，因为它解释了为什么同样是 OpenSpec，在不同项目、不同 AI 工具里看到的工作流外壳会不一样。

## 1. 为什么这层重要

如果只看业务命令，会以为 OpenSpec 是一个纯项目内工具。但 `init` / `update` 的源码说明，OpenSpec 还负责把工作流“投递”到具体 AI 工具。

这就引出了三个关键概念：

- profile
- workflows
- delivery

## 2. `profile` 是选什么 workflow

`profile` 决定“启用哪些工作流”。

当前核心认识：

- `core` profile 会启用默认核心 workflows。
- `custom` profile 允许用户自定义启用哪些 workflows。

在当前源码里，`core` 默认工作流是 5 个：

- `propose`
- `explore`
- `apply`
- `sync`
- `archive`

系统里可用的全部 workflows 则更广（11 个），包括：

- `propose`
- `explore`
- `new`
- `continue`
- `apply`
- `ff`
- `sync`
- `archive`
- `bulk-archive`
- `verify`
- `onboard`

所以，profile 回答的是：

“这套项目/用户要安装哪几条工作流路径？”

## 3. `delivery` 是怎么投递

`delivery` 决定“以什么形式把 workflow 安装进工具”。

它通常有三种意义：

- `skills`
- `commands`
- `both`

也就是说，同一份 OpenSpec workflow 内容，不一定总以同一种形式出现。

例如：

- 某些工具更适合读 skill 文件。
- 某些工具更适合读 slash command 文件。
- 有的场景则两者都要生成。

所以，delivery 回答的是：

“这些 workflow 产物最终要以什么外壳落到工具目录里？”

## 4. `init` 在做什么

`init` 的行为可以概括为：

1. 读取全局配置中的 profile/delivery。
2. 根据 profile 选出要启用的 workflows。
3. 根据 delivery 决定生成 skill templates、command contents，或两者都生成。
4. 针对每个配置的 AI 工具，使用对应 adapter 生成落盘文件。
5. 在必要时创建项目级 OpenSpec config。
6. 在 delivery 变化时删除不再需要的 skill 或 command 产物。

从系统角度看，`init` 是一次“工作流安装过程”。

## 5. `update` 在做什么

`update` 的本质不是重新安装，而是同步：

- 同步 OpenSpec 版本变化。
- 同步 profile 变化。
- 同步 delivery 变化。
- 同步 workflow selection 变化。
- 处理 legacy 目录和旧配置。

它还会判断：

- 哪些工具需要版本更新。
- 哪些工具虽然版本没变，但配置已经漂移，需要同步。
- 哪些 workflow 现在不再启用，需要删除对应文件。

所以 `update` 更像“声明式同步器”。

## 6. Skills 与 Commands 是同一内容的不同外壳

源码里的 `skill-generation` 和 `command-generation` 非常说明问题：

- 系统先维护一组 workflow 模板内容。
- 然后把这些内容映射成 skill templates 或 command contents。
- 再通过不同 adapter 生成不同工具需要的文件格式。

这说明：

OpenSpec 真正稳定的资产不是某个具体工具的文件，而是“workflow 语义内容”。

skill / command 只是投递载体。

## 7. 为什么 `propose` 很特殊

从 profile 默认值和 `init` 完成后的 onboarding 提示可以看出，`propose` 放在非常显眼的位置。

这说明项目正在把默认体验向以下模式收束：

- 从用户意图出发，先 propose。
- 再通过 continue/apply/archive 等工作流推进。

也就是说，OpenSpec 并不只是维护静态规范文件，而是在尝试提供一个完整的变更工作流入口。

## 8. `config` 命令改变的不是业务数据，而是投递策略

这点非常重要。

用户运行 `openspec config`，通常不是在编辑某个 change，也不是在修改 schema 本身，而是在改：

- 启用哪些 workflow。
- 这些 workflow 怎样出现在 AI 工具里。

还要补一个当前实现边界：

- 这里改的是全局配置。
- 源码里已经明确限制 `--scope` 目前只支持 `global`，project-local config 还没有实现。

所以 `config` 的影响路径通常是：

`config` -> `init/update` -> tool artifacts -> 用户/AI 的使用入口发生变化

而不是：

`config` -> 某个 proposal/spec/design 立即变化

## 9. 为什么需要把这一层单独写出来

如果不把 profile/delivery 单独讲出来，很容易把 `init/update` 理解错：

- 误以为只是项目脚手架命令。
- 看不出 OpenSpec 其实还在做 AI 工具工作流投递。
- 看不出为什么同一个 workflow 要同时存在 skill 和 command 两种形态。

但一旦理解了这一层，你就会明白：

OpenSpec CLI 同时管理三种空间：

- 项目内状态空间（repo-local `openspec/`）
- 工具侧入口空间（skills/commands）
- Workspace 协调空间（跨仓库规划层）

而 profile/delivery 正是连接这些空间的桥。

当前实现里，workspace 的 skill 投递是 **skills-only**（不做 command 生成）。这意味着 workspace 级的工作流目前只以 skill 形式出现，command 形式的 workspace 工作流预留到后续版本。此外，workspace 通过 `workspace_skills` 状态字段实现独立的 profile drift 跟踪——与 repo-local 的 profile drift 检测机制相同，但数据存储在 workspace 自己的 `view.yaml` 中。
