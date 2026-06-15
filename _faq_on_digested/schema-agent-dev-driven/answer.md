# 答案：Agent-Dev-Driven Schema — 用 OpenSpec 开发 AI Agent 本身

## 直接回答

可以。`agent-dev-driven` schema 把 OpenSpec 的「交付物」从代码（`spec-driven`）或文章（`article-driven`）换成**一个 AI agent**——即 charter、skills、commands、tools、evals、cli 这组一个智能体 harness 可消费的组件。不改一行 OpenSpec 源码，复用同一套 artifact DAG + 模板 + CLI 解释器。

```text
spec-driven       交付 = 软件（代码）
article-driven    交付 = 文章（内容）
agent-dev-driven  交付 = agent（它的 anatomy：charter/skills/commands/tools/evals/cli）
```

## 为什么会想到这个

`_digested/schema/07-超越-spec-driven-的应用场景.md` 的场景 3「Agent/Skill 内容开发」给过一个 4-artifact 雏形——`agent-development` schema：

```text
persona → skills → {scripts, tests}
```

- **`persona`**（即本 schema `charter` 的前身）：只定义名字、能力范围、沟通风格——没有硬约束表格（什么输入→什么拒绝话术），也没有显式的基线 prompt 段落。本 schema 的 charter 在这基础上补了「授权/Grant/Constraints/输出契约/基线 Prompt」五段框架。
- **`skills`**：每个 skill 一个 MD，结构和本 schema 基本一致。
- **`scripts`**（本 schema `tools` 的前身）：定义为 Python/Shell/JS 脚本——没有 harness 适配说明，也没有反向索引（哪个 skill/command 调用了这个工具）。
- **`tests`**（本 schema `evals` 的前身）：行为测试用例，但没有区分「正常/边界/拒绝」三类，也没有要求给出可重复执行的判定命令。

这个雏形证明了 OpenSpec 可以管理 agent 开发工作流，但缺三样 agent harness 真正需要的东西：

1. **没有 commands**。场景 3 有 skills 和 scripts，但没有 **slash-command**——用户可调用的命令（MD，如 `/opsx:apply`）才是 agent 的「用户界面」。OpenSpec 自己的设计已经体现了这一点：同一个 workflow 导出**两个交付形式**——skill（agent 自动发现的 MD）和 command（用户敲的 MD），内容同源、外壳不同。这个「author once, render to N harnesses」的原则是本 schema 的核心依据：charter 和 skills 是语义源（semantic source），commands、tools、cli 是交付外壳（delivery shell）——同一套语义通过 adapter 渲染进 Claude Code、Cursor、自建 runtime 等不同 harness 的约定目录和格式。

2. **没有 CLI**。如果目标 agent 是一个 CLI 工具（就像 Claude Code 本身），它需要自己的命令行界面——入口、子命令映射到 skills、flags、状态读取 API（类比 `openspec status --json`）。

3. **没有接入流水线**。场景 3 的 apply 直接 requires `[skills, scripts, tests]`，没有 `tasks`（可勾选的接入清单）和 `tracks`（进度跟踪）。本 schema 补了 `tasks` artifact + `apply.tracks: tasks.md`，让 `openspec change --long` 显示进度计数。

本 schema 把这三样补上，从 4 artifact 精化到 7。

## 核心设计：7 个 artifact 的 DAG

```
charter
  │
  ▼
skills
  │
  ├─→ commands ──┐
  ├─→ tools ─────┤
  └─→ evals ─────┤
                  ▼
                tasks
                  │
                  ▼
                apply

  cli（独立：requires [skills]，不阻塞 tasks——非 CLI agent 可跳过）
```

**每个 artifact 做什么——和 `spec-driven` 的对应**：

| `agent-dev-driven` artifact | 做什么 | `spec-driven` 中的对应 |
|---|---|---|
| `charter` | agent 身份、能力边界、系统立场（含 system-prompt 段落）、拒绝话术模板 | 没有直接对应——spec-driven 不定义「谁在开发」 |
| `skills` | 可被 harness 自动发现的 MD 能力单元（YAML frontmatter + 正文） | `specs`——能力规格，区别在于 spec 描述系统行为、skill 描述 agent 行为 |
| `commands` | 用户可调用的 slash-command（MD）——把 skill 串成用户意图工作流 | 没有对应——agent 独有的「用户界面」层 |
| `tools` | 运行时工具/脚本（入参 schema、返回格式、副作用、harness 适配说明） | `tasks` 的可执行对应 + 部分 `design` |
| `evals` | 行为测试用例（正常/边界/拒绝，形状断言，不依赖模型 eval） | 没有直接对应——spec-driven 靠 CI/tests，agent 靠 evals |
| `cli` | agent 自己的命令行界面（入口、子命令、flags、状态读取 API、安装/打包说明）——独立 artifact，不阻塞 tasks | 没有对应——spec-driven 产出的不是 CLI 工具 |
| `tasks` | 接入与发布清单（可勾选 checkbox，OpenSpec CLI 解析为进度） | `tasks`——同名，职责一致：可追踪进度 |

**requires 关系**：

```text
charter  requires: []
skills   requires: [charter]                        # 能力必须先知道「是谁的能力、被允许做什么」
commands requires: [skills]                         # 命令编排的是 skill
tools    requires: [skills]                         # 工具被 skill 调用
evals    requires: [skills]                         # 验证的是 skill 行为
cli      requires: [skills]                         # CLI 子命令映射到 skill（不阻塞 tasks——非 CLI agent 可跳过）
tasks    requires: [skills, commands, tools, evals]  # 核心交付物就绪才能列接入清单
apply    requires: [tasks], tracks: tasks.md
```

## 关键设计决策

### 决策 1：为什么 tracking 文件仍然叫 `tasks.md`

**约束**：`openspec change` 的列表 UI（`src/commands/change.ts:106,159`）硬编码了 `path.join(changeDir, 'tasks.md')` 来渲染 `[tasks X/Y]` 进度计数——它忽略 schema 的 `apply.tracks` 字段。注意：`openspec archive` **并不依赖 tasks.md**（`src/core/templates/workflows/archive-change.ts:55` 明确「If no tasks file exists: Proceed without task-related warning」）。真正的硬编码只在列表 UI。

**决策**：保持 `generate: tasks.md` 和 `apply.tracks: tasks.md`，以确保 `openspec change --long` 的进度计数正常显示——那是用户感知「这个 change 做完了吗」的唯一可视化信号，不改 schema 名比改名更实用。

**移除条件**：把 `change.ts:106,159` 的 `tasksPath` 改为从 schema 的 `apply.tracks` 字段读取；则该 tracking 文件可自由命名（如 `release.md`），`tasks` artifact 也可改名。

### 决策 2：为什么 commands 和 cli 分开

**约束**：slash-command（MD，落在 `.claude/commands/`）是**人**调用的——用户敲 `/agent:do-x`；cli（二进制入口、子命令、状态 API）是**程序**调用的——上层 orchestrator 跑 `my-agent status --json`。它们的消费者、生命周期、测试方式都不同。

**决策**：拆成两个 artifact。command 测的是「用户输入 → 正确 skill 编排 → 预期输出形态」；cli 测的是「给定子命令 → 正确入口/返回/exit code」。合在一起会模糊两者的测试边界。

**移除条件**：如果目标 agent 不是 CLI 工具——直接跳过 cli.md 不写即可（cli 不阻塞 tasks，没有任何下游依赖它）。如果你需要一个轻量版，cli 可以退化成一个「调用契约」文档放在 tools 里。

### 决策 3：为什么保留顶层 charter artifact（尽管 OpenSpec 自己没有全局 system-prompt）

**约束**：OpenSpec 没有顶层授权文件——它的「agent 应该怎么做」是 per-skill 定义的：每个 workflow 模板（如 `explore.ts`）各自的 `instructions` 里写了该 skill 的 stance——explore 是「Curious, Patient, Grounded, Don't-implement」，apply 是另一种。没有一个统一的文件说「这个 agent 整体上不能做什么、对什么输入必须拒绝」。但一个专用 agent（不是通才 coding agent）需要**单一**身份来源——尤其是硬约束和拒绝话术不能在多个 skill 里各自表述。

**决策**：charter 作为语义源，内部用五段框架（授权/Grant/Constraints/输出契约/基线 Prompt）把 agent 的身份、边界、拒绝条件集中在一处。下游 commands/tools/cli 的 adapter 层从这个单一源渲染成不同 harness 需要的外壳（Claude Code 的 system prompt、OpenSpec skill 的 frontmatter、自建 runtime 的角色 prompt）。这正是「author once, render to N harnesses」原则——charter 是 semantic source，adapter 是 delivery shell。

**移除条件**：OpenSpec v1.4+ 的 workspace schema 已埋了「workspace 级 system-prompt」的伏笔。如果这一能力落地，charter 可降级为 workspace 配置而非 schema artifact。

## 这验证了什么

1. **artifact DAG 的通用性**。换一套 `id`/`generates`/`requires`/`instruction` 定义，CLI 照常渲染——这次产物是 agent 组件而非代码/文章。`openspec status` 和 `openspec instructions` 对 charter 和 proposal 一视同仁——它们只读 schema.yaml + 查文件系统（`src/core/artifact-graph/outputs.ts:40`：glob 匹配到 ≥1 个文件即视为「完成」）。

2. **adapter 分层的必要性**。charter 是语义源，commands/tools/cli 是外壳。同一个 agent 可通过不同的 adapter 渲染进 OpenSpec（skills + commands 两个 MD 目录）、Claude Code、Cursor、自建 runtime——换的是外壳文件的位置和 frontmatter 格式，不变的是 schema 里定义的 instruction 语义。

3. **evals 作为「测试」的替代**。OpenSpec 没有 LLM-as-judge 的 model-eval 概念——现有的 test 全部是产物形状断言（`test/core/command-generation/` 里断言文件路径、frontmatter 字段、CLI JSON 结构）。agent-dev-driven 的 evals artifact 沿用同样的策略：用例断言的是**产物形状和字段**（文件存在、JSON 字段匹配、关键词 grep、exit code），不是「agent 对不对」的模糊判断——可重复、可脚本化、不进模型。

4. **CLI 作为无偏解释器**。`openspec status`、`openspec instructions`、`openspec schema validate` 对 agent-dev-driven 和 spec-driven 执行完全相同的逻辑（解析 schema.yaml → 检查文件存在 → 组装指令）——没有一行代码需要知道「这是 agent 开发」还是「软件研发」。schema 是唯一的事实源。

## 使用方式

1. 把 `schema-package/` 复制到 `openspec/schemas/agent-dev-driven/`（fork 也可以用，但直接复制更简单）：
   ```bash
   cp -r schema-package/ openspec/schemas/agent-dev-driven/
   ```

2. 创建一个 change 并绑定这个 schema：
   ```bash
   openspec new change build-my-agent --schema agent-dev-driven
   ```

3. 检查 DAG 状态：
   ```bash
   openspec status --change build-my-agent --json
   # charter=ready（没有 requires——你写 charter.md 即开始）
   # 写完 charter.md 后：skills=ready
   # 写完 skills/ 后：commands/tools/evals 同时 ready（它们都只 require skills）
   # cli=ready（独立——需要 CLI 就写，不需要就跳过）
   # 核心交付物全部写完后：tasks=ready
   # tasks.md 交卷后：apply=ready
   ```

4. 每个 artifact 写什么，看对应的 instruction：
   ```bash
   openspec instructions charter --change build-my-agent --json  # 完整 prompt：context+rules+template+instruction+依赖状态
   ```

5. apply 阶段（`/opsx:apply`）按 `apply.instruction` 做就绪检查 → 把 skills/commands 渲染/拷贝进目标 harness 目录 → 跑 evals → 端到端验证。

> 更完整的 schema 扩展与安装实操指南（fork/init/validate/调试/设为默认）见 [`answer-add-schema.md`](answer-add-schema.md)。

## 已知限制

1. **OpenSpec 无模型 eval**。`evals` artifact 只能断言产物形状（文件存在、字段匹配、关键词 grep），无法判断 agent 输出质量、回复是否「正确」——那是外部 eval 框架要做的事。本 schema 把 evals 定在「可重复执行的形状断言」这层——也符合 OpenSpec 自己的测试策略（`test/core/command-generation/adapters.test.ts` 只断言路径和 frontmatter，不调用 LLM）。

2. **harness 适配差异**。skills/commands 的文件格式（YAML frontmatter + MD 正文）对 OpenSpec 的 skill 发现是原生的（`.claude/skills/<name>/SKILL.md`），但其他 harness（Cursor、自建 runtime）可能有不同的 frontmatter 字段或文件位置。tools artifact 的 instruction 里要求写「harness 适配差异」表——但具体怎么适配、适配多少层，是 ad-hoc 的。

3. **v1.4.0 workspace schema 的影响**。`workspace-planning` schema 在 v1.4.0 引入，可能影响 charter 是否应该作为 workspace 级配置而非 schema artifact（见决策 3）。本 schema 基于当前 schema 系统设计，后续 OpenSpec 版本可能需要调整 charter 定位。

4. **change 列表 tasks.md 硬编码**。见决策 1——`openspec change --long` 的进度计数依赖文件名叫 `tasks.md`，这限制了 tracking 文件的命名自由。不是 blocker（tasks.md 这个名字对「接入清单」来说也合理），但值得知道这不是 schema 系统自己设的，而是一行 UI 代码的余味。

---

> 完整 schema-package（`schema.yaml` + 7 个 `templates/*.md`）在 [`schema-package/`](schema-package/)。
> 本 FAQ 的源码与文档引用集中在同目录的 answer 文件内（`:line` 已给出路径，可自行循证）。不再设独立的 `sources.md`——源码引用数有限。
