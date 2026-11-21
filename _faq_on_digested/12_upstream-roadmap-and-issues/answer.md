# 答案：OpenSpec 上游 Roadmap、主要问题与社区状况

> **综合来源**：GitHub Issues/Discussions（Fission-AI/OpenSpec）、官方文档（ROADMAP.md, faq.md, migration-guide.md, workspace-roadmap.md）、Release Notes 与社区讨论（HN, Discord, 博客）；涉及当前运行时行为的结论均以 [`_digested/README.md`](../../_digested/README.md) 的 SSOT 基线源码为准，逐版本演进见 [`_change_log/`](../../_digested/_change_log/README.md)。
>
> **交叉验证**：多项发现与我们 `_digested/` 和 `_faq_on_digested/` 中的独立分析高度吻合。

---

## 一、Roadmap：上游在做什么

### 1.1 已交付（历史至 v1.6，其后逐版补入，最新至 v2.1.1）

| 版本 | 关键交付 | 对应我们的研究 |
|------|----------|---------------|
| v1.0.0 | OPSX 品牌迁移：`/openspec:*` → `/openspec-*`，`project.md` → `config.yaml`，线性 phase-lock → 灵活 action 系统 | `_faq_on_digested/04_propose-to-apply-ready/` 研究的正是 OPSX 工作流 |
| v1.2.0 | Profile 系统（`core` / `custom`），`/openspec-verify-change` | `_digested/spec_cli/05-config-profile-delivery.md` 覆盖了 profile 机制 |
| v1.4.0 | `/openspec-update-change` workflow、Kimi CLI、Mistral Vibe 支持 | `_digested/workflows/` 深挖了 workflow templates |
| v1.5.0 | Stores（早期 beta）、sync workflow 进 core profile | `_digested/system/03-planning-home-与-store-模型.md` 覆盖了 store 模型 |
| v1.6.0-beta.1 | Canonical resolution 统一、auto-approve CLI | — |
| v1.7.0 | nested main specs、`skip_specs`、operation guidance / `instructions archive`、Purpose carry-through、early-sync no-op、Codex skills-only | v1.7.0 同步的当前依据 |
| v1.8.0 | vendor-neutral `agents` 目标（`.agents/skills/`）、GitHub Copilot（本地 + opt-in cloud）、MiniMax/Rovo、`retire_capabilities`、`status.isPlanningComplete`、validate SHALL/MUST 放宽 + scenario-loss 前置、archive 可重跑命令 | v1.8.0 同步的当前依据（见 [`0005`](../../_digested/_change_log/0005-v1.7.0-to-v1.8.0.md)） |
| v1.9.0 | Command Code、`validate --archived`、bulk list/validate 拒绝空 implicit root、scenario 认所有 `####`、apply pause-on-scope、archive 非 TTY / spec 重建保真、`schema fork` YAML 保真、遗留 Codex 不抢 `.agents` | v1.9.0 同步的当前依据（见 [`0006`](../../_digested/_change_log/0006-v1.8.0-to-v1.9.0.md)） |
| v1.10.0 | 多语言 init、Zed、store-aware specs instruction、task verification、no-spec 自动 marker、retirement blocked-content、profile sync 依赖、OpenCode 参数、completion/telemetry stderr、条件化 restart、feedback 保真 | v1.10.0 完整 commit-range 依据（见 [`0007`](../../_digested/_change_log/0007-v1.9.0-to-v1.10.0.md)） |
| v1.11.0 | `show --diff`、`status --all`、Explore 写入前确认、Antigravity 迁 `.agents` + `resolveSharedSkillWriters()` 通用仲裁、validate Purpose 占位符 warning、archive rename 保序、`schema init --default` 修键+回滚、Fish completion 修、移除本地项目级 agent-dev-driven/requirement-driven（**非上游改动**，见下） | v1.11.0 完整 commit-range 依据（见 [`0008`](../../_digested/_change_log/0008-v1.10.0-to-v1.11.0.md)） |
| v1.12.0 | `validate --report findings`、validate advisory merge preflight、SourceCraft Code Assistant、`init` 写 `.gitkeep`、共享 ide-restart、propose/ff 先读代码、explore 依赖感知提问、npm git 免 pnpm + Node20 chalk + PowerShell completion 文档 | v1.12.0 依据（见 [`0009`](../../_digested/_change_log/0009-v1.11.0-to-v1.13.1.md)） |
| v1.13.0 | apply 无 spec 警告 + `missingPrerequisites`、parser 三修复（重复 section / `*` 与 `+` 列表标记 / 换行 bullet）、archive fence 空行保真、update 检测损坏 command、init 列出遗漏 workflow、propose 加载项目 context、spec-inventory guidance | v1.13.0 依据（见 [`0009`](../../_digested/_change_log/0009-v1.11.0-to-v1.13.1.md)） |
| v1.13.1 | 安全加固（config 值注入、恶意文件挂起、`.npmrc` 注册表劫持、`DO_NOT_TRACK` 口径、completion 路径引用、git probe 限额）；task checkbox 认所有列表标记且未识别标记算未完成；archive/parser 拒收（仅大小写不同的 requirement 名、畸形 RENAMED、无正文 scenario、section 外 requirement、merge path 读不到的 delta）；`status` 给 `Next:` 行；explore「用户主动请求 capture 即确认」（且 handoff 改为工作流中立表述，不硬编码点名 propose/apply）；`/openspec-update-change` 先起草（step 4）确认后写入（step 5）；workflow 不擅自 `init` 项目、skills 只提 profile 内 workflow；artifact 模板带顶层标题；store / `EDITOR` 带参 / bash completion 逐字节还原等修复 | v1.13.1 依据（见 [`0009`](../../_digested/_change_log/0009-v1.11.0-to-v1.13.1.md)） |
| v1.13.2 | 正确性收尾（patch）：CRLF 保持（写回文件行尾不再被重写成全文件 diff）、Windows archive 的 EPERM/EXDEV 复制回退（fingerprint + snapshots 回滚）、Kilo Code 命令目录修正（`.kilo/command/`）、artifact 输出认 brace expansion/extglob、归档工作流认 schema-aware 任务进度、Continue 命令开头改「直接跟随 workflow」、fast-forward/onboarding 确认口径统一 | v1.13.2 依据（见 [`0011`](../../_digested/_change_log/0011-v1.13.1-to-v1.14.0.md)） |
| v1.14.0 | 工具生态大扩张 + 可观测性（minor）：10 个新 `--tools` 目标（`dsh`/`codestudio`/`gigacode`/`atomcode`/`easycode`/`gsd`/`amp`/`grok`/`warp`/`veai`，`.agents` 共享 root 变六方）、`list --archived/--all`、view 显示 workflow status 与归档分区、`openspec version --check --json`、apply 任务源定位（`sourcePath`/`line`）、archive workflow 的 sync 阻塞语义与 sync 后结构验证、verify 模板按 status 契约重写（Not applicable 语义）、`.openspec.yaml` 未知键告警、IBM Bob 改名 | v1.14.0 依据（见 [`0011`](../../_digested/_change_log/0011-v1.13.1-to-v1.14.0.md)） |
| v1.14.1 | 补丁：requirement / ADDED 正文 >500 字从 INFO 升 WARNING；退役清理失败改用独立错误码 `archive_retirement_cleanup_failed`（文案分清"已归档"与"清理未完成"）；glob 工件「done 但文件不全」的补完协议（`PARTIAL_ARTIFACT_CHECK`）与 specs 逐文件写入；apply `all_done` 不再暗示可归档 + tasks 模板新增 `## Workflow follow-up`；verify 按输出路径发现工件；CLI 按需加载（`--help` 485→24 模块）；`view` 撤回归档分区；CI 钉 Node 20/22/24 | v1.14.1 依据（见 [`0012`](../../_digested/_change_log/0012-v1.14.0-to-v1.14.3.md)） |
| v1.14.2 | 补丁：delta 里「归档不会带走」的文本（首个 `##` 前正文 / 首个 requirement 前散文 / 额外 `##` 段）报 WARNING；`.openspec.yaml` 接受顶层 `x-` 扩展键；`openspec/`、`changes/`、`specs/` 可为项目内 symlink（`archive/` 不行）；explore 捕获表限定默认 schema；update 的 glob 新文件例外写在两处；verify 的 REMOVED 先读主 spec 基线；`__complete` 跳过遥测（344→48 模块） | v1.14.2 依据（见 [`0012`](../../_digested/_change_log/0012-v1.14.0-to-v1.14.3.md)） |
| v1.14.3 | 补丁：artifact 创建前先定并校验输出路径（propose/ff/continue/explore 统一，glob 工件必须落在 change 目录内）；单条 `specs/<capability>/spec.md` 可为指向项目内其他位置的 symlink；glob 引擎由 `fast-glob` 换到 `tinyglobby`（brace 嵌套 ≤16、展开 ≤1024，移走 `braces` 传递依赖）；零宽 TTY 下 spinner 不再挂死；website 预览改零依赖脚本 | v1.14.3 依据（见 [`0012`](../../_digested/_change_log/0012-v1.14.0-to-v1.14.3.md)） |
| v1.15.0 | 独立安装 + update 预演（minor）：8 平台 standalone 单文件（无需 Node.js）、`openspec install` 切换安装形态、`openspec update --dry-run/--json`、feedback 对齐 bug 表单、`new change` 显示实际 schema、verify 的 REMOVED 按精确规范化名称匹配、`--json` 不加载 ora | v1.15.0 依据（见 [`0013`](../../_digested/_change_log/0013-v1.14.3-to-v1.15.0.md)） |
| v1.16.0 | 基础设施 + 校验收紧（minor，含一个 Breaking）：npm 包要求 **Node 22.12.0+**（Node 20 EOL）、release 资产改 `.tar.gz` / `.zip` 归档、安装入口收敛到 `openspec.dev/cli`、`validate` 三条收紧（scenario 无 WHEN/THEN → WARNING；未识别 `## ... Requirements` 段 → ERROR 且 archive 拒绝；坏 `config.yaml` → 退出 1）、parser 三修复（行内三反引号、无空格 `###Requirement:`、闭合 `#` run）、store 提示按 origin 仓库名点名、zsh 补全写 `$ZDOTDIR/.zshrc` | v1.16.0 依据（见 [`0014`](../../_digested/_change_log/0014-v1.15.0-to-v1.17.0.md)） |
| v1.16.1 | 补丁：显式 `version --check` 不再受遥测/CI 影响、standalone 只提示有 `SHA256SUMS` 的版本（HTTP 改 `node:http(s)` 以免 abort 后句柄滞留）、`validate` 拒绝未识别 delta 段（从“警告并静默丢弃”改为 ERROR）、闭合 `#` run 支持 | v1.16.1 依据（见 [`0014`](../../_digested/_change_log/0014-v1.15.0-to-v1.17.0.md)） |
| v1.17.0 | **迁移基础设施**（minor）：历史产物指纹库（2867 指纹 / 1130 路径 / 42 个版本，4010 行生成物）+ 旧文件清扫，使 `update` 从 0.12 以来任意版本一次升级、**不再需要 `--force`**；切换 skills-only 不再删用户编辑过的 command 文件；**command 文件标记弃用**（2.0 移除，本版仍生成）；上游自家 19 个 change 归档 | v1.17.0 依据（见 [`0014`](../../_digested/_change_log/0014-v1.15.0-to-v1.17.0.md)） |
| v2.0.0 | **大版本：只装 skills**（major）：`/openspec-*` command 文件不再生成；skills 收成 `.agents/skills/` 单份真身，各工具用自己的 `skills/` 目录指链接（建不了链接退化拷贝）；`delivery` 退役；Amazon Q Developer 退役（读不了 skills，转 Kiro）；命令生成能力删除但 34 个适配器保留、只做旧文件路径解析；Windows 需 `core.symlinks` 与开发者模式。另有补丁：cmd.exe 不再改写 PowerShell 配置、多行 task 不再被截断 | v2.0.0 依据（见 [`0015`](../../_digested/_change_log/0015-v1.17.0-to-v2.1.1.md)） |
| v2.1.0 | 全局 skills + Node 门槛（minor）：**Node 门槛抬到 `>=22.20.0`**（`#2241`）；技能默认按本机全局作用域安装（`skillsScope: global` 默认，`project` 记在 `openspec/config.yaml`）；安装改走 `skills` 包（`getSupportedAgents`，总计 **87 个 `AI_TOOLS`** = 49 个精选目标 + `skills@1.8.1` 的 38 个目标），新增 `known-projects` 本机项目清单（永不使命令失败） | v2.1.0 依据（见 [`0015`](../../_digested/_change_log/0015-v1.17.0-to-v2.1.1.md)） |
| v2.1.1 | 补丁：新建主 spec 在 `## Purpose` 后补空行（`#2267`）；`openspec-archive-change` 写主 spec 前先预检归档目标目录（`#2277`）；`retire_capabilities` 放行 `<` 开头的续行普通文本（`#2266`）；validate 豁免 delta 顶部 YAML frontmatter（`#2273`）、MODIFIED >500 字符且比主 spec 基线更长时告警（`#2265`）；`version` 识别 Homebrew/Nix 安装而不再误报 npm 升级命令（`#2264`）；**直接从本地 npm 包安装 skills（不再 git clone，离线可用，`#2283`）**并能刷新 `npx skills add` 装进去的技能 | v2.1.1 依据（见 [`0015`](../../_digested/_change_log/0015-v1.17.0-to-v2.1.1.md)） |

### 1.2 近期待交付（从 Discussion #111 和维护者确认）

- **Q&A Proposal 模式** — agent 在 propose 阶段主动追问澄清性问题，减少遗漏。这直接关联我们 `_faq_on_digested/04` 和 `05` 中识别的"propose artifacts 质量不稳定"问题。
- **Interactive change walkthrough** — 渐进式 review，类似 PR review 的步骤体验。
- **Roadmapping 功能** — 多 change 规划、优先级排序、依赖追踪。
- **TUI dashboard** — 探索 `opentui` 做终端可视化。
- **多工具原生集成转向统一 Skills 生态** — 早期路线图曾设想为所有工具维护自定义 slash command；v2.0.0–v2.1.1 已演进为 **skills-only**（退役 command 文件与 `delivery` 配置，通过 `skills@1.8.1` 覆盖 **87 个 `AI_TOOLS`**，下一步聚焦第 5 步 router skill + 更瘦的 skills）。

### 1.2b OpenSpec 2.0 的五步分批计划（issue #2022）

这是目前**唯一有公开分批计划**的方向，也是理解 v1.16–v2.1 的关键：先有 1.16/1.17 清路，才有 2.0 落刀，2.1 再补全局安装。维护者（TabishB）在 #2022 里列了五步：

| # | 版本 | 内容 | 状态 |
|---|------|------|------|
| 1–2 | **1.17.0** | `update` 能从 0.12 起任意版本一次升级；没人编辑过的旧文件删掉、编辑过的保留；`update` 预告 command 文件在 2.0 消失 | **已交付**（#2213） |
| 3 | **2.0** | 每个 skill 只留一份真身放 `.agents/skills/`，只读自己目录的工具用软链指回来；不再生成 command 文件；Amazon Q Developer 退役（AWS 已转向 Kiro） | **已交付**（#2223，2.0.0） |
| 4 | **2.1** | 可选的**每机全局** skill 安装，对齐 `npx skills` | **已交付**（#2241，2.1.0；2.1.1 改为从 npm 包装而不 clone） |
| 5 | 2.x | router skill + references，然后是更瘦的 skill | 未交付：第 4 步之后，每次改动前先量 |

**为什么是这个顺序**：2.0 要删掉 command 文件，而 1.x 项目里堆着两个版本布局的残留（同一套 workflow 一份 skill 一份 command）。如果用户带着这些残留直接进 2.0，要么丢文件要么看到重复。所以 1.17.0 必须先让 `update` 具备「证明这个文件没人改过」的能力——这就是那个 4000 行指纹库的由来。**它不是内务，是迁移的前置条件。**

**风险分级（维护者自评）**：第 1–2 步低（只在内容匹配某发布版时才删）；第 3 步中（习惯 `/openspec-propose` 的人要改说 skill 名；Windows 软链依赖 git 的 `core.symlinks`，没有就退化成写真副本）。

### 1.3 Workspace & Multi-Repo 四阶段路线图

这是上游最宏大的路线图，定义在 `workspace-roadmap.md`：

| 阶段 | 目标 | 状态评估 |
|------|------|----------|
| **Phase 1** | 单根内更好结构：嵌套 spec 路径、信息引用、多区域规划 | 基本完成 |
| **Phase 2** | 薄跨 repo 协调：initiative artifacts、关联 per-repo changes、协调规划 workspace | **开发中** |
| **Phase 3** | 团队共享协调硬化：共享协调 repo、成员 onboarding、重新链接流程 | 规划中 |
| **Phase 4** | 共享契约与治理成熟度：ownership 流程、策略检查（opt-in） | 远期 |

**关键判断**：Phase 2 的 initiative 概念会显著改变现有模型。我们今天理解的"一个 change = 一个 repo 内的一次修改"是 Phase 1 的产物。Phase 2 引入跨 repo initiative 后，change 可能变成 initiative 的子资源。这是我们 `_faq_on_digested/` 中尚未覆盖的维度。

### 1.4 Context Store & Initiatives（当前重点工程）

19 个跟踪项，约 12 完成、7 进行中：

- **已完成**：context store 基础、collection 基础、initiative MVP、agent-first initiative 发现、repo-local changes 链接到 initiatives
- **进行中**：manual beta reality pass（新用户体验走查）、context store 首次运行和清理 UX、agent 交付输出打磨、workspace beta 指南拆分
- **计划中**：escalation UX、团队硬化、initiative-hosted changes、review beta 兼容

**和我们研究的关系**：context store 是 `_digested/system/03-planning-home-与-store-模型.md` 研究的延续——我们分析的是 v1.5.0 的 "PlanningHome 简化 + store 模型"，而上游正在把这个模型从 "单机引用系统" 扩展为 "跨 repo 协调系统"。

### 1.5 社区呼声最高的 Feature Requests

| 需求 | 对应 Issue | 和我们已有研究的关联 |
|------|-----------|---------------------|
| `/openspec-repair` — 规范化 spec 对齐修复循环 | [#821](https://github.com/Fission-AI/OpenSpec/issues/821) | **直接命中** `_faq_on_digested/11_keep-specs-aligned/` 和 `_digested/specs_truth/` 的核心结论 |
| Brownfield baseline — 从已有代码逆向生成 spec | [#434](https://github.com/Fission-AI/OpenSpec/issues/434) | — |
| Constitution/steering docs — 类似 Spec-Kit 的治理层 | [#434](https://github.com/Fission-AI/OpenSpec/issues/434) | — |
| 子 agent 上下文窗口管理 | 社区讨论 | `_digested/system/08-对照常见-SDD-与-AI-Coding.md` 提到过 agent memory vs 显式 spec 的取舍 |
| 并行开发支持 | 社区讨论 | — |
| 后端存储插件（Notion/Confluence/Jira/Linear/SQLite） | 社区讨论 | — |

---

## 二、最主要的问题

### 2.1 结构性限制（不会通过小补丁解决）

#### A. Spec-code 漂移是默认状态，无工具自动化

这是我们 `_digested/specs_truth/` 专题的核心结论，而上游 GitHub Issues 和社区反馈完全印证了这一点：

- **现状**：spec 只在 `archive` 时写入；requirement 没有稳定 ID（只有 Markdown 标题文本）；没有任何持续对账工具。`openspec validate` 只是结构 linter，抓不出 specs↔代码漂移。
- **上游态度**：Issue #821（`/openspec-repair`）说明上游意识到这个问题，但目前给出的方案仍然是"人 + 纪律 + 巡检"，没有自动化对账的计划。
- **社区 workaround**：手动运行 `/openspec-verify-change`，但 verify 也只是让 agent 对比 specs 和代码，不是结构化 diff 工具。

> 和我们 `_digested/specs_truth/README.md` 的结论一致：**"漂移是默认状态——把 specs 弄对根本上是用 delta + archive 重新表达，不是手搓 spec 文件；长期对齐是人 + 纪律 + 巡检的责任，不是某个命令的责任。"**

#### B. Apply 和 Archive 不做语义验证

这是我们在 `_faq_on_digested/06_apply-ready-to-archive-ready/` 和 `07_archive-ready-to-archived/` 中独立发现的，而上游的行为确认了这一点：

- `openspec-apply-change` 通过 `openspec instructions apply --json` 检查 `apply.requires` 文件存在性并解析 `apply.tracks` 的复选框，但它只认 `[x]` 字符本身，不校验某个已勾选 `[x]` 的任务在真实业务代码里是否真的写对。
- `openspec-archive-change` 早期（v1.13.2 `#1973` 之前）曾存在即使复选框未勾选也报 "All tasks complete" 的历史 bug；**v1.13.2 起已通过调用 `openspec list --json`（schema-aware `totalTasks - completedTasks`，仅认 `x`/`X`）修复**，存在未完成任务时会明确告警并要求用户确认，但它同样不会去跑代码级语义对账。
- `openspec archive` 默认会程序化合并 delta specs；宿主 archive workflow 也会先做归档目标冲突预检（`#2277`）并评估/验证 inline sync。但用户仍可显式 `--skip-specs` 或选择 "Archive without syncing"，因此“archived”本身仍不等于代码实现与主 specs 必然语义一致。

这不是 bug，而是**刻意的轻量化设计取舍**。代价是：workflow 的"完成"信号不可靠，依赖人工 review。

> **v1.13.2–v1.14.0 的部分补强**：归档工作流改用 schema-aware 任务进度（自定义任务文件不再误报未完成）、verify 模板按 status 契约重写（Not applicable/advisory 语义）、OPSX archive 模板的 sync 失败立即停止归档并做 sync 后结构验证。结构错误与"假完成"类失真被进一步前移，但 spec↔代码漂移仍无对账。

> **v1.14.1–v1.14.3 的部分补强**：apply 的 `all_done` 不再暗示"可以归档"（改成"跟踪任务已完成，归档前请复核或验证"），只有归档后才能做的步骤移进 tasks.md 的 `## Workflow follow-up`（纯项目符号，不计入进度）；verify 改为按输出路径发现工件，并规定 REMOVED requirement 必须先读主 spec 基线、拿不到可用基线就标 not verified 而不是空手去代码里猜；delta 里"归档不会带走"的文本与超长 requirement 都升级成 WARNING，可被 `--strict` 拦住。**"假完成"的两个口子（`all_done` 等于可归档、delta 散文静默丢失）被收掉了**，但 spec↔代码漂移仍无自动对账。

#### C. 工具集成模型从 1.x 双轨摩擦演进到 v2.0+ Skills-Only 收敛

`_digested/system/08-对照常见-SDD-与-AI-Coding.md` 与 `04-agent-contract-与工具投递.md` 记录了这一层的演进。1.x 时代同时维护 `skills` 与各工具专属 `commands/opsx` 曾暴露出大量摩擦：

- **1.x 历史痛点**：Windsurf 用 workflows 而非 commands（[#591](https://github.com/Fission-AI/OpenSpec/issues/591)，后更名为 Devin Desktop `devin`）；Cursor 同时读 `.claude/` 和 `.cursor/` 导致重复；Codex 旧 slash-command 回归（[#890](https://github.com/Fission-AI/OpenSpec/issues/890)，早在 v1.7–v1.8 已转 `$openspec-*` skills-only）；多项目配置冲突（[#195](https://github.com/Fission-AI/OpenSpec/issues/195)）。
- **v2.0.0–v2.1.1 的结构性收敛**：v2.0.0（`#2223`）彻底**删除了 command 文件生成能力并退役 `delivery` 配置项**（不支持 skills 的 Amazon Q Developer 同步退役并转向 Kiro）；v2.1.0（`#2241`）将默认作用域切为**每机全局 skills**（项目内保留则记 `skillsScope: project`，项目级采用 `.agents/skills/` 单份真身 + 各工具目录软链/拷贝回退），并接入 `skills@1.8.1` 将支持目标扩展到 **87 个 `AI_TOOLS`**（`src/core/config.ts` 中 49 个精选目标 + `skills@1.8.1` 的 38 个目标，另配 `agents` 通用兜底解决 `#653`）；v2.1.1（`#2283`）进一步改为直接从本地已安装的 npm 包拷贝/安装 skills（无需联网 git clone，离线可用）。

**当前剩余边界**：砍掉 command 双轨后，维护复杂度大幅下降，剩余摩擦主要集中在平台文件系统差异（如 Windows 创建项目级软链需开启 `core.symlinks` 与开发者模式，否则退化为文件拷贝）以及各宿主加载 skills 的机制差异（如部分 IDE 驻留工具更新后需重启 IDE、Hermes 需 `hermes skills trust`）。

### 2.2 高频 Bug（影响面大）

| Bug | Issue | 严重度 | 和我们研究的关联 |
|-----|-------|--------|-----------------|
| Task 进度追踪不可靠（多模型不更新 metadata） | [#374](https://github.com/Fission-AI/OpenSpec/issues/374) | ⚠️ 高 | `_faq_on_digested/06` 详细研究了 apply 阶段的 task 追踪机制，这个 bug 说明模型在实施中会"偏离 OpenSpec 约定" |
| 交互模式阻塞 AI agent（`validate` 等待人类输入） | [#492](https://github.com/Fission-AI/OpenSpec/issues/492) | ⚠️ 高（已通过 `--no-interactive` 与非 TTY 处理收敛） | — |
| Shell 补全缺失父级 flags（Bash/PowerShell） | [#463](https://github.com/Fission-AI/OpenSpec/issues/463) | 低 | `_digested/mechanisms/05-cli-infra.md` 覆盖了 CLI 基础设施 |
| 非标准 artifact 生成（header 不符合自身约定） | [#490](https://github.com/Fission-AI/OpenSpec/issues/490) | 中 | 和 `_faq_on_digested/04` 研究的 "propose 产出 artifacts 的质量不稳定" 直接对应 |
| "Universal / Other tools" 选项缺失 | [#653](https://github.com/Fission-AI/OpenSpec/issues/653) | 中（已由 `agents` = `Other / Universal (shared .agents skills)` 目标补齐） | `_digested/spec_cli/05-config-profile-delivery.md` 覆盖了 profile/投递机制 |

### 2.3 迁移痛点（v1.0.0 OPSX 断裂与 v2.0.0 Skills-Only 迁移）

v1.0.0 是第一次重大 breaking change：

- **命令重命名**：`/openspec:proposal` → `/openspec-propose`，`/openspec:apply` → `/openspec-apply-change`，`/openspec:archive` → `/openspec-archive-change`
- **文件变化**：不再生成 `CLAUDE.md` / `.cursorrules` / `AGENTS.md`；`project.md` 被 `config.yaml` 取代
- **工作流模型变化**：从线性 phase-lock 变为灵活 action 系统
- **手动步骤**：`project.md` 不会自动删除，用户需要手动把有用内容迁移到 `config.yaml` 的 `context:` 字段
- **迁移命令**：`openspec init`（会检测旧文件、引导清理）；CI 环境：`openspec init --force --tools claude`

而 v1.17.0–v2.1.1 完成了第二次结构性演进（详见 [`16_upgrade-openspec-cli-and-projects/`](../16_upgrade-openspec-cli-and-projects/question.md)）：v1.17.0 用 2867 条历史指纹让 `openspec update` 可从 0.12 起任意旧版免 `--force` 清理未编辑过的旧生成物；v2.0.0（`#2223`）正式**移除 command 文件生成并退役 `delivery` 配置项**，全面转向 skills-only；v2.1.0（`#2241`）要求 Node `>=22.20.0`、默认采用每机全局 skills（或 `skillsScope: project`）并接入 `skills@1.8.1` 覆盖 87 个工具目标；v2.1.1（`#2283`、`#2264`）实现离线从本地 npm 包安装 skills 及 Homebrew/Nix 安装源识别。任何早期版本的历史判断都不能直接代替当前源码与测试结论。

---

## 三、社区最常见问题（来自官方 FAQ + Discord + GitHub）

### 3.1 入门类

| Q | A | 对应我们已有的研究 |
|---|---|---|
| OpenSpec 是什么？ | 在 AI 写代码前让开发者和 AI 在 spec 上达成一致的轻量层 | `_digested/system/01-系统心智模型.md` |
| 绑死某个 AI 工具吗？ | 否，支持 **87 个 `AI_TOOLS` 目标**（49 个精选目标 + `skills@1.8.1` 的 38 个目标），外加 `agents`（`.agents/skills`）通用目标 | `_digested/system/04-agent-contract-与工具投递.md` |
| 能在已有大项目上用吗？ | 是，brownfield-first：只 spec 每次改动触及的部分 | `_digested/system/08-对照常见-SDD-与-AI-Coding.md` |
| 最简单的用法是什么？ | explore（可选）→ propose → apply → archive；均以 skill 形态投递（Claude 等写作 `/openspec-*`，Codex 写作 `$openspec-*`，也可自然语言触发） | `_faq_on_digested/03` 到 `07` 覆盖了每一步 |

### 3.2 混淆高发区

| Q | A |
|---|---|
| Skills / 斜杠入口不出现怎么办？ | v2.0.0 起不再生成 command 文件，仅分发 skills（v2.1.0 起默认装在每机全局目录，项目内保留则由 `skillsScope: project` 控制）。运行 `openspec update` 刷新 skills；仅当输出提示更新了 IDE 驻留目标（`requiresIdeRestart`）时重启 IDE，并确认在 AI 对话而非系统终端中输入 |
| Terminal vs AI Chat 的区别？ | `openspec ...` 在终端执行 CLI；工作流由宿主加载 skill 执行（Claude `/openspec-*`，Codex `$openspec-*`，或直接自然语言请求） |
| 怎么升级？ | 运行 `openspec version --check` 查看自动识别的安装源与对应升级命令（npm 全局用 `npm install -g @fission-ai/openspec@latest`，standalone 用 `openspec install`，Homebrew/Nix 等包管理器亦在 v2.1.1 `#2264` 中准确识别、不再误提示 npm）；升完 CLI 后在项目里先 `openspec update --dry-run` 预演、再 `openspec update`（v2.1.1 `#2283` 起离线直接从本地 npm 包刷新 skills，无需联网 clone） |
| 怎么自定义？ | `openspec/config.yaml` 的 `context:` / `rules:` / `operations:` / `schema:` / `skillsScope:` 等字段；自定义 schema 用 `openspec schema fork spec-driven my-workflow` |

### 3.3 什么时候用 / 什么时候不用

社区共识：

- **适合**：项目进入持续迭代、多人协作、有非平凡的改动
- **不适合**：快速原型、单字符 typo 修复
- **代价**：每次 change 生成 proposal/spec/task 文件，修一个 bug 可能消耗 5 小时 token 配额

---

## 四、对照我们在 `_digested/` 中已有的研究

| 上游现实 | 我们在哪里已经分析到 | 哪些是我们的盲区 |
|----------|---------------------|-----------------|
| spec-code 漂移是核心问题 | `_digested/specs_truth/` 专题 + `_faq_on_digested/11` | 上游没有自动化方案，我们也没有 |
| v1.0.0 OPSX 迁移与 v2.0.0 Skills-Only | `_faq_on_digested/04–07` 与 `_faq_on_digested/16` | v2.0.0 之后的第 5 步（router skill + 更瘦 skills）尚未落地 |
| Profile 与 Skills 投递机制（`delivery` 已退役） | `_digested/spec_cli/05-config-profile-delivery.md` + `_faq_on_digested/16` | 各宿主对全局/项目级 skills 软链的真实边缘行为没有端到端宿主回归矩阵 |
| Store 模型 | `_digested/system/03-planning-home-与-store-模型.md` | Initiative 跨 repo 协调层我们没研究 |
| SDD 工具对比 | `_digested/system/08-对照常见-SDD-与-AI-Coding.md` | 和 SpecKit/Kiro 的具体对比我们已有 |
| Config 怎么配 | `_faq_on_digested/08_config-yaml-growth/` | `project.md` → `config.yaml` 的迁移痛点和我们问的"普通程序员怎么配 config"是同一个问题的不同阶段 |

---

## 五、关键判断

1. **"轻量" 是特性也是限制**：OpenSpec 不做 TDD 强制执行、不做自动化 spec-code 对账、不做结构化 requirement ID——这些都是刻意的设计取舍。如果项目需要这些，应该评估 SpecKit（更重但更严格）。

2. **Initiative 概念会让现有模型变旧**：我们今天理解的 "一个 change 是一个 repo 内的修改" 是 Phase 1 产物。Phase 2 initiative 引入后，change 变成跨 repo 的子资源。`_faq_on_digested/` 里对 explore/propose/apply/archive 的分析到时候需要重新审视。

3. **工具集成在 v2.0+ 已靠 Skills-Only 大幅收敛，但宿主侧边缘差异仍在**：v2.0.0–v2.1.1 砍掉 per-tool command 生成、统一收归 `.agents/skills/`（或每机全局 skills）+ `skills@1.8.1` 的 87 个工具目录映射，并改为从本地 npm 包离线安装（`#2283`），消除了 1.x 双轨适配器的主要断裂源；剩余成本转为 Windows 软链支持与少数宿主专属信任步骤。

4. **早期社区 fork（如 `openspec-plus`）暴露的定制诉求已被上游部分吸收，但编写门槛仍在**：早期 `openspec-plus` 为补齐 apply/archive 的配置注入而 fork；上游自 v1.7.0 起已在原生 `openspec/config.yaml` 中交付 `context` + `operations.{apply,archive}.guidance`（分别注入 `instructions apply` 与 `instructions archive`），收掉了机制缺口，但“普通用户如何写出高质量 config”仍是 `_faq_on_digested/08` 与 `13` 讨论的工程实践问题。

5. **我们的研究整体超前于社区平均水平**：`_digested/specs_truth/` 对 spec 漂移机理的分析、`_digested/system/08` 的 SDD 框架对照、`_faq_on_digested/` 对每一步工作流的深挖——这些内容在社区里（包括官方文档里）都还没有同等深度的材料。我们走在前面。

---

## 参考来源

- [OpenSpec GitHub](https://github.com/Fission-AI/OpenSpec)
- [Roadmap Discussion #111](https://github.com/Fission-AI/OpenSpec/discussions/111)
- [Workspace Roadmap](https://github.com/Fission-AI/OpenSpec/blob/main/openspec/explorations/workspace-roadmap.md)
- [Context Store & Initiatives Roadmap](https://github.com/Fission-AI/OpenSpec/blob/main/openspec/initiatives/context-store-and-initiatives/roadmap.md)
- [Official FAQ](https://github.com/Fission-AI/OpenSpec/blob/main/docs/faq.md)
- [Troubleshooting Guide](https://github.com/Fission-AI/OpenSpec/blob/main/docs/troubleshooting.md)
- [Migration Guide](https://github.com/Fission-AI/OpenSpec/blob/main/docs/migration-guide.md)
- [Issue #821 — /openspec-repair](https://github.com/Fission-AI/OpenSpec/issues/821)
- [Issue #434 — Advanced spec/plan generation](https://github.com/Fission-AI/OpenSpec/issues/434)
- [Issue #890 — Codex CLI regression](https://github.com/Fission-AI/OpenSpec/issues/890)
- [Issue #591 — Windsurf/Cursor incompatibility](https://github.com/Fission-AI/OpenSpec/issues/591)
- [Issue #374 — Task progress tracking](https://github.com/Fission-AI/OpenSpec/issues/374)
- [Issue #492 — Interactive mode blocks agents](https://github.com/Fission-AI/OpenSpec/issues/492)
- [Issue #195 — Multi-project config failure](https://github.com/Fission-AI/OpenSpec/issues/195)
- [Issue #490 — Non-standard artifact generation](https://github.com/Fission-AI/OpenSpec/issues/490)
- [Issue #463 — Shell completion bugs](https://github.com/Fission-AI/OpenSpec/issues/463)
- [Issue #653 — Missing Universal tool option](https://github.com/Fission-AI/OpenSpec/issues/653)
- [Discussion #324 — Claude Hooks proposal](https://github.com/Fission-AI/OpenSpec/discussions/324)
- [Discussion #294 — Workflow Diagram](https://github.com/Fission-AI/OpenSpec/discussions/294)
- [v1.6.0-beta.1 Release Notes](https://newreleases.io/project/github/Fission-AI/OpenSpec/release/v1.6.0-beta.1)
- [Community schemas repo](https://github.com/JiangWay/openspec-schemas)

以及我们自己的研究（交叉引用）：`_digested/system/`、`_digested/specs_truth/`、`_digested/spec_cli/`、`_digested/mechanisms/`、`_faq_on_digested/04–11/`
