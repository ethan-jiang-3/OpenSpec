# Workflow Templates · 总览

## 位置

workflow templates 是 OpenSpec 的内核。它们不是 TypeScript 里的硬编码执行流程，而是投递给 coding agent 的**操作手册源码**。

```text
OpenSpec CLI runtime API          ← TS 机械层
  → status/instructions/validate/new change
workflow template                 ← MD 智力层的操作手册
  → 告诉 agent 如何串这些 API
宿主 coding agent                 ← 推理、写文件、跑测试
```

CLI 负责保存和解释状态（确定性的），template 负责告诉 agent 怎么操作（策略性的），agent 负责实际执行（智能的）。三层分离让行为可解释但不完全硬编码。

## 全部 workflow 一览

源码目录：`src/core/templates/workflows/`

| 文件 | workflow id | 类型 | 一句话 |
|---|---|---|---|
| `explore.ts` | `explore` | 发现 | stance，非 workflow；探索想法、调查问题、澄清需求，经确认可直接捕获为 change 与 artifacts |
| `propose.ts` | `propose` | 规划 | 快速路径：澄清实质歧义 + 加载项目 context + 创建新 change + 生成传递必需闭包内全部 artifact |
| `new-change.ts` | `new` | 规划 | 只创建 change scaffold 并展示首个 ready artifact 模板，不写产物内容 |
| `continue-change.ts` | `continue` | 规划 | 增量路径：先补完半写 glob 产物，否则每次只推进一个 ready artifact |
| `ff-change.ts` | `ff` | 规划 | fast-forward：创建新 change 并倾向做合理假设一次性生成全部必需 artifact |
| `apply-change.ts` | `apply` | 实施 | 按 tracked tasks checkbox（精确到 `sourcePath:line`）逐项实施业务代码 |
| `sync-specs.ts` | `sync` | 同步 | agent-driven 智能合并 delta specs 到主 specs（含 `validate --specs` 校验） |
| `verify-change.ts` | `verify` | 验证 | 从完整性、正确性、一致性三维核验实现与 change artifacts 是否对齐 |
| `archive-change.ts` | `archive` | 收尾 | agent 层收尾：写前预检归档目标 + sync 评估/内联合并 + 移动 change 到 archive |
| `bulk-archive-change.ts` | `bulk-archive` | 收尾 | 批量归档多个 changes，基于代码库证据消解跨 change 的 spec 冲突 |
| `onboard.ts` | `onboard` | 引导 | 11 阶段教学式端到端实操引导（从扫描真实小任务到 `openspec archive --yes`） |
| `update-change.ts` | `update` | 修订 | 双向修订已有 planning artifacts，保持产物间自洽。**绝不改代码。** |

`feedback.ts`、`store-selection.ts` 和 `project-root.ts` 也在 workflows 目录下，但不在 profile selection 里，属于共享辅助片段/模块。

## 用户可见的调用方式

每个 workflow 现在只有一种投递形态：**skill**（agent 可自动选，也可按名调用）。1.x 时代还并列投递 slash command（`/opsx:*`），**v2.0.0 起命令文件已移除**，下表第二列仅作历史对照。部分 workflow 还有独立的 CLI 命令：

| workflow | （1.x）command adapter 示例 | skill 名 | 独立 CLI？ | profile |
|---|---|---|---|---|
| explore | （1.x）`/opsx:explore [想法]` | `openspec-explore` | 无 | **core** |
| propose | （1.x）`/opsx:propose <name>` | `openspec-propose` | 无 | **core** |
| new | （1.x）`/opsx:new <name>` | `openspec-new-change` | `openspec new change` 存在，但模板围绕其做了更多 | custom |
| continue | （1.x）`/opsx:continue [name]` | `openspec-continue-change` | 无 | custom |
| ff | （1.x）`/opsx:ff <name>` | `openspec-ff-change` | 无 | custom |
| apply | （1.x）`/opsx:apply [name]` | `openspec-apply-change` | 无 | **core** |
| sync | （1.x）`/opsx:sync [name]` | `openspec-sync-specs` | 无（也被 archive 内部调用） | **core** |
| verify | （1.x）`/opsx:verify [name]` | `openspec-verify-change` | `openspec validate` 类似但不同 | custom |
| archive | （1.x）`/opsx:archive [name]` | `openspec-archive-change` | **有**：`openspec archive`（路径不同） | **core** |
| bulk-archive | （1.x）`/opsx:bulk-archive` | `openspec-bulk-archive-change` | 无 | custom |
| onboard | （1.x）`/opsx:onboard` | `openspec-onboard` | 无 | custom |
| **update** | （1.x）`/opsx:update [name]` | `openspec-update-change` | 无 | **core**（新增；现已进入默认集） |

> 表中 `/opsx:*` 一列是 **1.x 的历史形态**（command adapter 时代，例如 Claude Code 的 `/opsx:propose`），v2.0.0 起 command 文件不再生成，该列只用于读旧项目。**当前唯一形态是 skill**：Claude Code 等工具里按 `/openspec-<name>` 调用，Codex 用 `$openspec-<name>`，Zed Agent 用 `/openspec-*` 或 `@openspec-*`；也可以直接用自然语言要求（「帮我 propose 一个 change」），由 agent 自行选择技能。支持**项目级**（`.agents/skills/`）与 **v2.1 全局级**（`~/.agents/skills/`，通过 `openspec/config.yaml` 的 `skillsScope: global | project` 记录偏好）两种安装作用域；项目级下真身只有一份在 `.agents/skills/`，其余工具目录放指向它的链接（建不了链接退化为拷贝），见 `../mechanisms/02-tool-delivery.md`。

> **v2.1.1 状态注记：command 文件已移除。** `delivery` 配置项随之退役（1.x 的 skills / commands / both 三态不再存在），一律装 skills。升级旧项目时 `openspec update` 会按指纹清理早期版本生成的 command 文件：没人改过的删掉，改过的保留并列出。**这是 packaging 的变化，不是 workflow 的变化**——两列指向的是同一份 template。
>
> 注意不要让这层状态影响对**机制**的理解：command 与 skill 只是同一份 template 的两种 packaging，两者内部都在调用 CLI（`openspec instructions` / `openspec status` / `openspec archive` …）。**精确的校验与合并发生在 CLI，不发生在 prompt 里。**

> **core profile**（默认）：propose, explore, apply, update, sync, archive —— 6 个。大多数用户只看到这些。
> **custom profile**：需在 `customWorkflows` 中显式启用，才能解锁全部 12 个。
> custom 选择 `archive` 或 `bulk-archive` 时会自动在第一个依赖者前补 `sync`；已有 `sync` 不重复、不重排，profile 仍保持 custom。

## 七类 workflow（共 12 个）

### 发现类（1 个）

**explore** — 和其他所有 workflow 不同，它是 stance 不是 workflow。没有固定步骤、没有强制输出。agent 被要求好奇、纯 ASCII 可视化、扎根代码；经用户明确确认或主动要求后，也可直接在原会话中捕获 change 与指定 artifacts。

### 规划类（4 个）

**propose / new / continue / ff** — 四个模板共享同一套 artifact DAG（来自 schema），区别在于**操作粒度与交互节奏**：

| workflow | 创建新 change | 生成 artifact | 粒度与歧义策略 |
|---|---|---|---|
| `propose` | **会**（仅限新 change） | 会，覆盖 `applyRequires` 传递闭包 | 快速完整；先跑 `context --json`，遇实质歧义停下提问，严守规划边界 |
| `new` | **会**（仅限新 change） | 不会（只展示首个 ready 模板） | scaffold |
| `continue` | **不创建**（作用于已有 change） | 一次一个（优先补完半写 glob 产物） | 增量推进，每步可审阅 |
| `ff` | **会**（仅限新 change；同名已存在则停下建议改用 `continue`） | 会，覆盖 `applyRequires` 传递闭包 | 快速直推；跳过 `context --json` 预检，倾向做合理假设保持推进势头 |

这就是 OpenSpec "动作而非阶段锁定" 的体验基础：用户可以从不同粒度切入同一条 artifact DAG。

### 修订类（1 个）

**update** — 修订已有 change 的既有 planning artifacts（含补齐非空 glob 产物下缺失的单文件），双向保持产物间自洽。**绝不改业务代码，也不推进未创建的后续阶段产物。**

### 实施类（1 个）

**apply** — 常规工作流中唯一修改业务代码的模板。消费 `openspec instructions apply --json`，按 `sourcePath:line` 逐项执行并勾选 tracked tasks 的 checkbox。

### 验证类（1 个）

**verify** — 归档前的建议性核验（Completeness / Correctness / Coherence 三维评估），读取 `status --json` 与 `instructions apply --json` 后对照真实代码库检查实现覆盖度、REMOVED 行为是否确已移除及设计遵循度。

### 收尾与同步类（3 个）

**sync / archive / bulk-archive** — 处理 delta specs → main specs 的智能合并（及能力退役）与 change 目录的归档移动。

### 引导类（1 个）

**onboard** — 面向初次上手用户的 11 阶段教学向导：在真实代码库里挑选一个小任务，边讲解边走完 explore → new → proposal → specs → design → tasks → 实施 → `openspec archive --yes` 全周期。

## 每个 template 的统一结构

读任何 workflow template 源码时，关注这六个区域：

| 区域 | 内容 |
|---|---|
| **Input** | 接受什么参数（change name、描述、空） |
| **Steps** | 按顺序做的动作（CLI 命令 + agent 行为） |
| **Output** | 成功/暂停/失败时输出什么格式 |
| **Guardrails** | 绝对不能做的事 |
| **Artifact Creation Guidelines** | （仅规划类）怎么写 artifact |
| **Fluid Workflow Integration** | （仅 apply）和其他 workflow 怎么交织 |

## 跨模板共享守卫与引用改写机制

- **引用改写取代 `optional-workflow.ts`**（v2.0.0 #2223）：1.x 时代的 `src/core/templates/optional-workflow.ts` 已删除。当前各模板的正文 handoff 已改为工作流无关的自然语言或通用 CLI 命令（如 `openspec instructions <artifact>`），而模板中残留的 `/opsx:<id>` 占位在生成 `.agents/skills/` 单份共享真身时由 `src/utils/command-references.ts` 的 **`transformToSharedSkillReferences()`** 统一改写为裸技能名 `openspec-<skill>`。
- **store 选择守卫**（`STORE_SELECTION_GUIDANCE` in `src/core/templates/workflows/store-selection.ts`）：全量注入全部 12 个 workflow。当用户点名或工作位于独立 store 时，先跑 `openspec store list --json` 查注册表，随后在支持 `--store <id>` 的全部命令（`new change`、`status`、`instructions`、`list`、`show`、`validate`、`archive`、`doctor`、`context`、`schemas`、`view`）上将 `--store <id>` 作为粘滞参数全程携带。
- **project-root 守卫与畸形 `store:` 拦截**（`PROJECT_ROOT_GUARD` in `src/core/templates/workflows/project-root.ts`）：所有 workflow 在**第一个写文件的步骤之前**（`new change`、`archive`、`sync specs`、或落盘 artifact）先跑 `openspec list --json` 并读 `root`：
  - `root` 是对象才算已初始化；`"root": null`（连同非零退出码）表示此处没有可用根。
  - **畸形或未注册 `store:` 声明特例（`project-root.ts:27`）**：若 `"root": null` 同时伴随 `status` 错误信息以 `Declared in` 或 `Invalid store declaration in` 开头并点名本项目的 `openspec/config.yaml`（或 `config.yml`），说明该项目确实通过 `store:` 指针使用 OpenSpec，只是本机尚未注册该 store 或 `store:` 语法损坏——**严禁将其当成未初始化项目处理**，必须在任何写操作前立即停止，原样向用户展示该错误的 `message` 与 `fix`。
  - 普通无根场景下按触发方式分流：模型自发选中的技能直接静默退回普通回答，绝不推销安装；用户显式点名 OpenSpec 或该技能时则停下询问（`openspec init` / `--store <id>` / 本次不用 OpenSpec），两边都严禁把创建 `openspec/` 当副作用。
- **顶层标题**（v1.13.1 `3312af47`）：proposal/spec/design/tasks 模板以 `# <Artifact>` 开头。
- **`Next:` 行**（v1.13.1）：`status` text 输出结尾给出推进命令。

## v1.14.0 template 层新机制

- **任务源定位**（apply）：`openspec instructions apply --json` 的每个任务带 `sourcePath` 与 1-based `line`（`LocatedTask` 只附加定位，不改任务解析——源码注释原话 `without changing task parsing`）；apply 模板要求在该位置确认 checkbox 仍匹配描述 → 勾选 → 重跑 apply instructions 确认进度变化。见 [`06-apply.md`](06-apply.md)。
- **verify 改吃 status/apply 契约**：verify 模板不再让 agent 自己解析 checkbox，改用 `instructions apply` 输出的顶层 `tasks`/`progress`（CLI 已按 `apply.tracks` 聚合全部具体任务文件）与 `taskTrackingConfigured`；schema 未定义的检查和 intentional skip（`skip_specs: true`、可选 design、无任务追踪的 schema）标 **Not applicable**，与证据缺失的 **Not verified** 分开；apply 的 `state`/`instruction` 只是 context 不是 verdict。见 [`08-verify.md`](08-verify.md)。
- **archive 阻塞语义**：inline sync 报任何 stop/blocking 条件即视为 sync 失败——立即停止归档，不做 post-sync 内容比对、不移 `changeRoot`，一切未动可重跑；sync 通过后还要做结构验证（主 spec 不残留 delta headers、REMOVED 的 requirement 已删、retired capability 的主 spec 已删除）。模板同时明确 inline sync **不得委托后台任务**。见 [`09-archive.md`](09-archive.md)。

## v1.14.1–v1.14.3 template 层新机制

- **先定输出路径再创建**（v1.14.3 #2104）：propose / ff / continue / explore 的 artifact 创建统一为四步——glob `resolvedOutputPath` 先选成 `changeRoot` 内的具体路径（匹配该 glob）、解析 symlink 后仍在 `changeRoot` 内、委托给 skill/command 时只有它能写到该路径才调用、写完确认文件在该路径。见 [`02-propose.md`](02-propose.md)。
- **局部工件补完**（v1.14.1 #2037）：`PARTIAL_ARTIFACT_CHECK` 注入 continue 的 skill 版与 command 版——glob 工件读作 `done` 不等于文件齐全，先比对 `existingOutputPaths` 与应有文件，只补缺失的，算作本次调用的那一个工件。见 [`04-continue.md`](04-continue.md)。
- **完成 ≠ 可归档**（v1.14.1 #1791）：apply 的 `all_done` 只报「跟踪任务已完成，归档前请复核/验证」；归档之后才能做的步骤写进 tasks.md 末尾的 `## Workflow follow-up`（纯项目符号，不进 checkbox 进度）。见 [`06-apply.md`](06-apply.md)。
- **verify 按输出路径找工件 + REMOVED 先读基线**（v1.14.1 #2028 / v1.14.2 #2083）：spec 工件 = `outputPath` 在 `specs/` 之下者，design 工件 = id 为 `design` 或 `outputPath` 命中 `design.md` 者；REMOVED 分支必须先从主 spec（必要时从该文件历史）取回基线，拿不到可用基线就标 not verified 并跳过搜索。见 [`08-verify.md`](08-verify.md)。
- **specs 逐文件写入**（v1.14.1 #2037）：按 proposal 列出的 capability 从第一个缺失的开始写，草稿完成即落盘，不再先规划全部文件。
- **update 的 glob 新文件例外写在两处**（v1.14.2 #2083）：step 2 与 guardrails 口径一致，避免 blanket 规则推翻流程本身要做的事。见 [`12-update.md`](12-update.md)。
- **explore 捕获表限定默认 schema**（v1.14.2 #2086）：自定义 schema 下按 `artifactPaths` 挑工件，绝不创建 schema 未定义的文件。见 [`01-explore.md`](01-explore.md)。

## 和 CLI runtime API 的关系

每个 template 调用的 CLI 命令是有限的、固定的集合：

| CLI 命令 | 被哪些 workflow 调用 |
|---|---|
| `openspec list --json` | **全部 12 个**（`${PROJECT_ROOT_GUARD}` 强制在首次写操作前跑）；各模板自身也用于选 change / 查任务数：explore、continue、apply、archive、bulk-archive、sync、verify、update |
| `openspec status --change X --json` | **全部 12 个** workflow（propose/ff 还靠其中的 `applyRequires` + `artifacts[].requires` 计算传递必需闭包；continue 靠 `isPlanningComplete` 判断规划完成） |
| `openspec context --json` | **propose**（Step 2 解析权威规划根以预读 `config.yaml`，及 Step 3 查询可用工作流前） |
| `openspec new change "<name>"` | explore（确认捕获时）、new、propose、ff、onboard（Phase 4 建 change）；**注意 `update` 与 `continue` 绝不调用它**（`update` 只在意图彻底改变时提示用户自己新建） |
| `openspec instructions <artifact> --change <name> --json` | propose、ff、continue、explore（确认捕获时）、new（首个 ready 工件，文本模式）、onboard（Phase 5–8）、update（大改重写或补齐非空 glob 缺失文件时） |
| `openspec instructions apply --change <name> --json` | **仅 apply 与 verify**（verify Step 3 用它读取聚合后的 `contextFiles`、`tasks`、`progress` 与 `taskTrackingConfigured`；**propose / ff / continue / explore 均不调用它**） |
| `openspec instructions archive --change <name> --json` | archive、bulk-archive（按根读取一次 `context` 与 `operations.archive.guidance`） |
| `openspec instructions specs --change <name> --json` | sync、archive、bulk-archive、onboard（sync/archive 用它获取写主 spec 前的 `rules.specs` 快照） |
| `openspec schemas --json` | new、propose（仅当用户询问有哪些工作流时） |
| `openspec validate --specs` | **sync**（Step 5 校验合并后的主 specs），以及 **archive / bulk-archive** 在未安装 `sync` 技能走内联合并兜底（`SYNC_FALLBACK_SAFEGUARDS`）时；verify 自身不跑 `validate` |
| `openspec archive "<name>" --yes` | **onboard**（Phase 10 教学收尾直接调 CLI 归档；`archive` / `bulk-archive` 技能则由 agent 自管 sync 评估 + `mv`） |

`status` 与 `list` 都有，但语义不同：`list` 回答"这个仓库有没有 OpenSpec root"，`status` 回答"这个 change 的工件到哪一步"。

## 运行时要点

- `skip_specs: true` 让没有 spec-level 行为变化的 change 将 specs artifact 标为 `skipped`；规划/apply/归档 workflow 应把它当已满足，而不能创建任何 delta file。
- `specs` 与 `design` 在 proposal 后并行 ready；同级推荐顺序按 schema 声明，内置 schema 先推荐 specs 再 design。
- 除 bulk archive 外，workflow 选择 change 的默认顺序是：显式名称 → 对话推断 → 唯一 active change 自动选择 → 仅在歧义时列出并询问。
- Apply/Archive 通过各自的 instructions API 获得当前 config `context` 和 operation guidance；artifact `rules.*` 仍只约束对应 artifact 的生成。
- status 的 JSON 含 `isPlanningComplete`（与兼容别名 `isComplete`）；planning artifact 的完成与实现进度分开表达。
- **root 缺失时，怎么办取决于是谁发起的**（`#1645`）：模型自己挑中的 workflow（用户没点名 OpenSpec、没点这个 skill、没跑 slash command）应当**直接退出**、按普通请求作答，不许推销安装；用户点名 OpenSpec 的则**停下来问**（`openspec init` / 用已有 store / 这一单先不上 OpenSpec）。这段分叉在 `PROJECT_ROOT_GUARD` 里，同一个字符串同时投给 skill 和 command。
- 归档类 workflow（archive / bulk-archive）的任务完成度来自 `list --json` 的 schema-aware `totalTasks`/`completedTasks`——CLI 自己解析 schema 声明的追踪文件（含自定义任务文件名/glob），agent 不再自己数 tasks.md checkbox。

template 不直接操作文件系统——它通过 CLI 命令获取路径，再由 agent 用自己的文件工具去读写。

## 和 `_faq_on_digested/` 的关系

FAQ 里的四条核心命令（explore→propose→apply→archive）是从**问题驱动**的视角分析的。本目录是从**模板源码**的视角分析的。两者互补：

- FAQ 回答 "这个阶段发生了什么，MD 和 TS 怎么交替"
- 本目录回答 "template 里写了什么指令，agent 看到后会做什么"

## 源码锚点

| 机制 | 路径 |
|---|---|
| workflow 模板源码 | `src/core/templates/workflows/*.ts` |
| 共享根检查与 store 选择片段 | `src/core/templates/workflows/project-root.ts`、`store-selection.ts` |
| skill/command 外壳 | `src/core/templates/skill-templates.ts` |
| 类型定义 | `src/core/templates/types.ts` |
| skill 生成与引用改写 | `src/core/shared/skill-generation.ts`、`src/utils/command-references.ts` |
| 全局/项目技能安装与作用域 | `src/core/skill-installer.ts`、`global-skills.ts`、`project-skills-scope.ts` |
| profile 选择 | `src/core/profiles.ts` |
| runtime API | `src/commands/workflow/` |
