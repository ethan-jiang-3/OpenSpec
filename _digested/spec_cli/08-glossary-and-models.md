# 术语与模型

这一页给整套 CLI 建统一词汇表。很多概念如果不先对齐，后面很容易混淆。

## change

一个 change 是一次待推进的 change 实例。

它通常有：

- 一个唯一名称。
- 一个目录 `openspec/changes/<change>/`。
- 若干 artifact 输出，例如 `proposal.md`、`design.md`、`tasks.md`。
- 可能还带有 schema 元数据。

不要把 change 理解成“单个 markdown 文件”。它更像一个change 工作区。

## spec

spec 是正式规范空间里的 capability 定义，通常位于 `openspec/specs/<spec>/spec.md`。

不要把 spec 和 change 混为一谈：

- change 是正在进行中的 change 实例。
- spec 是较稳定、已纳入主规范库的正式结果。

## schema

schema 是 workflow 模型定义。

它通常声明：

- artifacts 有哪些。
- 它们的依赖关系。
- 每个 artifact 生成什么路径。
- 每个 artifact 用哪个 template。
- apply 阶段依赖哪些 artifacts、跟踪哪个文件、给什么 instruction。

schema 决定了“这条 change 生命周期长什么样”。

## artifact

artifact 是 change 生命周期中的一个产物节点。

典型 artifact 可能有：

- `proposal`
- `spec`
- `design`
- `tasks`

每个 artifact 通常会有：

- `id`
- `description`
- `template`
- `generates`
- `requires`
- 可选 `instruction`

artifact 不是抽象步骤，而是有明确输出路径的产物节点。

## artifact graph

artifact graph 是 artifact 及其依赖关系构成的有向图。

它回答的问题包括：

- 当前 workflow 顺序是什么。
- 哪些 artifact 被谁阻塞。
- 哪些 artifact 在某个节点完成后会解锁。

这是 `status` 和 `instructions` 的基础结构。

## completed set

completed set 是当前 change 已完成 artifact 的集合。

它通常通过”artifact 对应输出文件是否存在”推导，而不是通过数据库字段标记。

## change context

change context 是运行时打包后的上下文对象，通常包含：

- changeName
- schemaName
- changeDir
- graph
- completed
- projectRoot

它是 workflow 命令计算状态与 instructions 的核心输入之一。

## template

template 是某个 artifact 的输出骨架。

它不是最终内容，而是：

- 节结构模板
- 输出形状约束
- 生成时的起始框架

`instructions <artifact>` 会把 template 内容放入输出包里。

## context

这里的 context 往往指项目级背景信息，可能来自配置。

它的用途是：

- 告诉 AI 这个项目有哪些额外背景。
- 补充 artifact 生成时不可从模板本身得知的约束。

## rules

rules 通常是对具体 artifact 的额外限制。

例如：

- 输出时必须覆盖哪些内容。
- 不得包含哪些内容。
- 需要遵守哪些团队约束。

rules 不是模板本身，而是模板之上的行为约束。

## apply phase

apply phase 指从文档产物进入实现执行的阶段。

它通常需要：

- 某些 artifacts 已完成。
- 某个 tracking file 已存在。
- tracking file 中存在任务。

`instructions apply` 暴露的就是这个阶段的入口状态和工作单。

## tracking file

tracking file 是 apply 阶段用于跟踪任务进度的文件，通常类似 `tasks.md`。

它的作用不是描述需求，而是记录实施任务及勾选进度。

## profile

profile 决定启用哪些 workflows。

它回答的是“系统装哪些工作流”。

## delivery

delivery 决定 workflow 以什么形式投递到 AI 工具中。

它回答的是“系统怎么把这些工作流交给工具消费”。

## skill

skill 是某些 AI 工具可消费的一种工作流文件形态。

OpenSpec 会把 workflow 语义内容生成 skill 文件，安装到对应工具目录。

## command

command 是另一种工具可消费的工作流文件形态，通常表现为 slash command 或命令文件。

skill 和 command 通常表达的是同一 workflow 语义，只是外壳不同。

## ready / blocked / done

这是 workflow 状态里最重要的几个词：

- `done`: 当前 artifact 输出已存在。
- `ready`: 依赖满足，可以开始创建。
- `blocked`: 依赖未满足，不应直接推进。

这些状态不是人工标记，而是 CLI 根据 schema 和文件系统推导出的运行时语义。

## workspace

workspace 是跨仓库规划的本地视图。它是一个目录，包含：

- `.openspec-workspace/view.yaml` — 视图状态文件
- `changes/` — workspace 级 change 目录

workspace 通过 `links` 关联多个仓库目录（link name → local path），但它本身不包含、不修改任何 linked repo 的内容。设计规则：**规划在 workspace，实现在 linked repo。**

workspace 不是临时 feature——它设计为持久存在的协调 home，可以容纳多个 initiative 和 change 的规划过程。

## workspace link

一个 workspace link 是 workspace 与某个仓库目录的关联。link name 默认从目录 basename 推断（可以显式用 `name=path` 命名）。link 只记录关系，不创建、不复制、不初始化被链接的仓库。

## context store

context store 是团队共享的协调数据目录。可以放在任意路径，通常用 Git 管理。它包含一个或多个 **initiative**。

- `openspec context-store setup <name> --path <path>` 创建
- 内部结构：`initiatives/<name>/requirements.md`、`design.md`、`decisions.md` 等

## initiative

initiative 是 context store 中的一个协调单元。它代表一个跨仓库或跨团队的使命，包含需求、设计、决策、提问、任务等协调文件。workspace 可以绑定到某个 initiative。

## PlanningHome

`PlanningHome` 是运行时抽象，判断当前工作目录属于 workspace 还是 repo。它从 cwd 向上搜索 `.openspec-workspace/view.yaml`（workspace root）或 `openspec/` 目录（repo root），决定使用 `workspace-planning` schema 还是 repo-local schema。

## workspace-planning schema

与 repo-local 的 `spec-driven` schema 不同，`workspace-planning` 是 workspace 级 change 使用的内置 schema。它针对跨仓库规划场景定义了不同的 artifact 依赖和 apply 条件。

## community schema

社区贡献的 schema 定义，可以通过 schema 搜索路径被发现和复用。README 中已新增 Community Schemas 章节。

## auto-detection

`openspec init` 现在会自动扫描项目目录中已有的 AI 工具目录（`.claude/`、`.cursor/` 等），预选检测到的工具，而不是要求用户手动指定 `--tools`。这降低了首次配置的摩擦。

## 本项目里最重要的模型关系

如果用一句话串起来：

用户/AI 通过 workflow 选择一个 change，`PlanningHome` 判断是 workspace 级还是 repo 级，change 使用对应的 schema（`workspace-planning` 或 `spec-driven`），schema 定义 artifact graph，CLI 根据 graph 和文件状态推导 completed/readiness，再通过 instructions 把 template/context/rules 编译成下一步执行包。

这就是 OpenSpec CLI 的核心模型闭环。
