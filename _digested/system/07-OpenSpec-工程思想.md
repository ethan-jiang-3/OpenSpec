# OpenSpec 工程思想

## 先说一句话

OpenSpec 的核心不是“让 AI 帮你写几份 spec”，而是把 AI Coding 中最容易漂移的部分拆成几层可以检查的本地协议：

```text
文件系统保存状态
CLI 解释状态
schema 定义产物图
template 编译操作说明
agent 负责推理和执行
tool delivery 负责把说明交给不同工具
```

这就是它和很多 prompt-first 工具的差别。OpenSpec 没有试图把所有判断塞进一个超长 prompt，而是把“事实在哪里”“谁解释事实”“谁生成内容”“谁负责投递”拆开。

## 第一性边界

| 常见理解 | OpenSpec 的真实边界 |
|----------|---------------------|
| 它是 spec 文档管理工具 | 它管理的是当前 capability 基线和一次次增量 change，不只是存放文档 |
| 它是 IDE 插件 | 它是 CLI + 文件状态 + agent 指令投递，IDE/agent 只是消费方 |
| 它是 LLM wrapper | 它不做创造性推理，推理发生在宿主 coding agent |
| 它是固定流程引擎 | schema 定义 artifact DAG，workflow 只是围绕 DAG 的动作入口 |
| skill/command 是核心资产 | skill/command 是投递产物，核心资产仍是 `openspec/`、schema 和模板 |
| workspace 是多仓库事实源 | workspace 是本机协调视图，不替 linked repo 决定业务归属 |

这些边界解释了为什么 OpenSpec 源码里会同时有 parser、validator、artifact graph、workflow template、tool adapter、workspace opener。它们不是散装功能，而是服务同一个分层目标。

## 文件状态优先

repo-local 形态下，最重要的事实源是：

```text
openspec/specs/
openspec/changes/
openspec/config.yaml
openspec/schemas/
```

`specs/` 代表当前已经成立的 capability 基线。`changes/` 代表一次准备中的增量 change。OpenSpec 不靠隐藏数据库记录“到了哪个阶段”，而是通过文件是否存在、delta spec 怎么写、tasks checkbox 是否完成判断当前状态。

这个取舍的好处是：

- 人类可以 review。
- Git 可以追踪。
- agent 不需要信任一段不可见 memory。
- CLI 可以重复解释同一组文件，得到稳定状态。

代价是文档格式必须更严格，所以才需要 parser、schema、validator 和 archive merge 机制。Markdown 是人类界面，不是自由文本沙盒。

## CLI 是解释器，不是执行者

OpenSpec CLI 的关键职责是把文件状态解释成 agent 可消费的结构：

```text
openspec status --json
openspec instructions <artifact> --json
openspec instructions apply --json
openspec templates
openspec schemas
```

这些命令像本地 runtime API。它们回答：

- 当前 change 用哪个 schema？
- 哪些 artifact 已经完成？
- 哪些 artifact ready？
- agent 应该读哪些依赖文件？
- 这次生成应该使用什么 instruction、template、context、rules？
- apply 能不能开始？如果不能，缺什么？

CLI 不负责写 proposal 的创造性内容，也不负责实现业务代码。它负责让 agent 不靠猜目录、不靠复述旧上下文、不靠隐式阶段判断来工作。

## schema 是产物图，不是模板集合

很多人第一次看 OpenSpec，会把 schema 理解成“模板配置”。这会错过关键点。

schema 的核心是 artifact DAG：

```text
artifact ids
  → generates outputs
  → requires dependencies
  → apply requires / tracks
  → instruction + template references
```

template 只是 artifact 的输出骨架；instruction 只是 agent 的写作/执行说明。真正把 workflow 变成可计算系统的是 `requires`、`generates`、`apply.requires` 和 `apply.tracks`。

因此 OpenSpec 的 workflow 不是写死在 TypeScript 里的阶段表，而是由 schema 数据驱动。默认 `spec-driven` 只是一个内置实例；项目可以 fork 或 init 自己的 schema。

## agent 负责推理，但不独占事实

OpenSpec 借用宿主 coding agent 的 LLM 能力。agent 做这些事：

- 理解用户自然语言意图。
- 调 CLI 获取结构化状态。
- 读取依赖 artifact 和项目文件。
- 用 LLM 生成 proposal/spec/design/tasks。
- 实施代码修改、运行测试、更新 checkbox。

但 agent 不应该自己发明 OpenSpec 状态。状态来自文件系统，解释来自 CLI，产物顺序来自 schema。这个分工让 AI 的创造性被放在合适的位置：它生成内容和做工程判断，但不随意改写协议。

这也是 `status` 和 `instructions` 的意义。它们不是给人看的帮助文本，而是给 agent 的稳定操作包。

## template、skill、command 都是投递层

OpenSpec 同时支持多种 AI Coding 工具。不同工具发现指令的方式不同：有的看 skill，有的看 command，有的用全局 prompt 目录，有的用项目内命令目录。

所以源码里有 profile、delivery、skill generation、command adapters。它们的共同目的不是定义业务事实，而是把同一套 workflow 语义投递到不同 agent 外壳。

```text
workflow template
  → skill content
  → command content
  → tool-specific adapter path
  → agent 可发现入口
```

删除或重生成这些投递产物会影响 agent 能不能触发 OpenSpec workflow，但不会直接改变 `openspec/specs/` 或 `openspec/changes/` 的业务事实。

## 不是阶段锁，而是可回写的动作系统

OpenSpec 默认工作流看起来像 propose → apply → archive，但源码机制不是传统 phase machine。

artifact 状态主要来自输出是否存在：

```text
blocked: 依赖 artifact 还没完成
ready: 依赖完成，但自己还没有输出
done: 输出存在
```

这意味着实现中发现设计问题时，可以回头改 design、tasks 或 delta specs。OpenSpec 不把“已经进入 apply”理解成“规划不可再变”。真正的约束是：agent 在每次动作前重新通过 CLI 获取当前状态，并按当前状态行动。

这种设计更贴近 brownfield AI Coding：真实代码库里的理解经常在实施过程中才变清楚。

## workspace 的克制

workspace/context-store/initiative 是当前系统中最容易被误读的一层。它不是把多个 repo 合并成一个超级 OpenSpec，也不是远端协作服务。

它的定位是 local coordination view：

- 让 agent 在本机同时看到多个 repo/folder。
- 绑定一个 initiative 上下文。
- 生成 workspace guidance 和 opener surface。
- 记录本机 link path 和 preferred opener。

业务规格和可归档 change 仍应由 owning repo 承载。workspace 的价值是打开上下文和协调边界，而不是制造新的大一统 source of truth。

## 读源码时的主线

理解 OpenSpec 源码时，不要从“命令很多”或“目录很多”开始。更稳定的读法是：

```text
1. 文件状态是什么
2. schema 怎么定义 artifact graph
3. CLI 怎么解释状态
4. template 怎么告诉 agent 行动
5. delivery 怎么进入不同工具
6. workspace 怎么扩展本机上下文
```

对应专题：

- 文件状态和总体边界：`01-系统心智模型.md`、`02-目录与状态边界.md`
- CLI runtime API：`../spec_cli/03-workflow-runtime-api.md`
- schema 和 artifact DAG：`../schema/01-schema-到底是什么.md`
- 默认核心命令机制：`../internal-spec-driven/00-四条命令的共有机制.md`
- 补充机制：`../mechanisms/`

## 源码锚点

| 工程思想 | 源码入口 |
|----------|----------|
| PlanningHome 判定 | `src/core/planning-home.ts` |
| artifact graph / 状态解释 | `src/core/artifact-graph/` |
| workflow runtime API | `src/commands/workflow/` |
| Markdown parser / validator | `src/core/parsers/`、`src/core/validation/` |
| workflow templates | `src/core/templates/workflows/` |
| skill / command 投递 | `src/core/shared/skill-generation.ts`、`src/core/command-generation/` |
| workspace coordination | `src/core/workspace/`、`src/core/context-store/`、`src/core/collections/initiatives/` |
