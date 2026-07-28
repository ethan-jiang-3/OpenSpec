# 答案：OpenSpec 上游 Roadmap、主要问题与社区状况

> **综合来源**：GitHub Issues/Discussions（Fission-AI/OpenSpec）、官方文档（ROADMAP.md, faq.md, migration-guide.md, workspace-roadmap.md）、Release Notes（v1.0.0–v1.6.0-beta.1）、社区讨论（HN, Discord, 博客）
>
> **交叉验证**：多项发现与我们 `_digested/` 和 `_faq_on_digested/` 中的独立分析高度吻合。

---

## 一、Roadmap：上游在做什么

### 1.1 已交付（v1.0.0–v1.6.0-beta.1）

| 版本 | 关键交付 | 对应我们的研究 |
|------|----------|---------------|
| v1.0.0 | OPSX 品牌迁移：`/openspec:*` → `/opsx:*`，`project.md` → `config.yaml`，线性 phase-lock → 灵活 action 系统 | `_faq_on_digested/04_propose-to-apply-ready/` 研究的正是 OPSX 工作流 |
| v1.2.0 | Profile 系统（`core` / `custom`），`/opsx:verify` | `_digested/spec_cli/05-config-profile-delivery.md` 覆盖了 profile 机制 |
| v1.4.0 | `/opsx:update` workflow、Kimi CLI、Mistral Vibe 支持 | `_digested/workflows/` 深挖了 workflow templates |
| v1.5.0 | Stores（早期 beta）、sync workflow 进 core profile | `_digested/system/03-planning-home-与-store-模型.md` 覆盖了 store 模型 |
| v1.6.0-beta.1 | Canonical resolution 统一、auto-approve CLI | — |

### 1.2 近期待交付（从 Discussion #111 和维护者确认）

- **Q&A Proposal 模式** — agent 在 propose 阶段主动追问澄清性问题，减少遗漏。这直接关联我们 `_faq_on_digested/04` 和 `05` 中识别的"propose artifacts 质量不稳定"问题。
- **Interactive change walkthrough** — 渐进式 review，类似 PR review 的步骤体验。
- **Roadmapping 功能** — 多 change 规划、优先级排序、依赖追踪。
- **TUI dashboard** — 探索 `opentui` 做终端可视化。
- **Native integration** — 所有支持自定义 slash command 的 AI 工具的深度集成。

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
| `/opsx:repair` — 规范化 spec 对齐修复循环 | [#821](https://github.com/Fission-AI/OpenSpec/issues/821) | **直接命中** `_faq_on_digested/11_keep-specs-aligned/` 和 `_digested/specs_truth/` 的核心结论 |
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
- **上游态度**：Issue #821（`/opsx:repair`）说明上游意识到这个问题，但目前给出的方案仍然是"人 + 纪律 + 巡检"，没有自动化对账的计划。
- **社区 workaround**：手动运行 `/opsx:verify`，但 verify 也只是让 agent 对比 specs 和代码，不是结构化 diff 工具。

> 和我们 `_digested/specs_truth/README.md` 的结论一致：**"漂移是默认状态——把 specs 弄对根本上是用 delta + archive 重新表达，不是手搓 spec 文件；长期对齐是人 + 纪律 + 巡检的责任，不是某个命令的责任。"**

#### B. Apply 和 Archive 不做语义验证

这是我们在 `_faq_on_digested/06_apply-ready-to-archive-ready/` 和 `07_archive-ready-to-archived/` 中独立发现的，而上游的行为确认了这一点：

- `/opsx:apply` 只检查 4 个 artifact 文件**是否存在**，不检查 tasks 是否真正完成。
- `/opsx:archive` 报告 "All tasks complete" 即使所有 checkbox 都未勾选。
- Archive 不会自动合并 delta specs 到 `openspec/specs/`——需手动操作。

这不是 bug，而是**刻意的轻量化设计取舍**。代价是：workflow 的"完成"信号不可靠，依赖人工 review。

#### C. 工具集成模型有根本性摩擦

`_digested/system/08-对照常见-SDD-与-AI-Coding.md` 描述了 OpenSpec 如何通过 delivery 层将同一套 workflow 语义投放给不同 AI 工具。但上游实际暴露出的是：

- **Windsurf 用 workflows 而非 commands**：OpenSpec 生成的 `commands/opsx` 文件对 Windsurf 不兼容（[#591](https://github.com/Fission-AI/OpenSpec/issues/591)）。v1.0.2 甚至删除了用户已有的工作 Windsurf 配置。
- **Cursor 双重加载**：从 `.claude/` 和 `.cursor/` 同时加载 skills 导致重复。
- **Codex CLI 回归**：v0.117.0 起所有 `/opsx:*` slash commands 不被识别（[#890](https://github.com/Fission-AI/OpenSpec/issues/890)）。
- **多项目配置失败**：只有第一个项目生成 slash commands（[#195](https://github.com/Fission-AI/OpenSpec/issues/195)）。

**根本原因**：OpenSpec 的 "universal delivery" 抽象层（同一套 workflow semantics → skills → commands → per-tool adapters）在面对真实工具差异时，adapter 层的健壮性不足。每增加一个工具支持，不是"零成本"，而是可能引入新的断裂点。

### 2.2 高频 Bug（影响面大）

| Bug | Issue | 严重度 | 和我们研究的关联 |
|-----|-------|--------|-----------------|
| Task 进度追踪不可靠（多模型不更新 metadata） | [#374](https://github.com/Fission-AI/OpenSpec/issues/374) | ⚠️ 高 | `_faq_on_digested/06` 详细研究了 apply 阶段的 task 追踪机制，这个 bug 说明模型在实施中会"偏离 OpenSpec 约定" |
| 交互模式阻塞 AI agent（`validate` 等待人类输入） | [#492](https://github.com/Fission-AI/OpenSpec/issues/492) | ⚠️ 高 | — |
| Shell 补全缺失父级 flags（Bash/PowerShell） | [#463](https://github.com/Fission-AI/OpenSpec/issues/463) | 低 | `_digested/mechanisms/05-cli-infra.md` 覆盖了 CLI 基础设施 |
| 非标准 artifact 生成（header 不符合自身约定） | [#490](https://github.com/Fission-AI/OpenSpec/issues/490) | 中 | 和 `_faq_on_digested/04` 研究的 "propose 产出 artifacts 的质量不稳定" 直接对应 |
| "Universal / Other tools" 选项缺失 | [#653](https://github.com/Fission-AI/OpenSpec/issues/653) | 中 | `_digested/spec_cli/05-config-profile-delivery.md` 描述了 init/delivery 机制，这个 bug 说明自定义工具路径被遗漏了 |

### 2.3 迁移痛点（v1.0.0 OPSX 断裂）

v1.0.0 是迄今为止最大的 breaking change：

- **命令重命名**：`/openspec:proposal` → `/opsx:propose`，`/openspec:apply` → `/opsx:apply`，`/openspec:archive` → `/opsx:archive`
- **文件变化**：不再生成 `CLAUDE.md` / `.cursorrules` / `AGENTS.md`；`project.md` 被 `config.yaml` 取代
- **工作流模型变化**：从线性 phase-lock 变为灵活 action 系统
- **手动步骤**：`project.md` 不会自动删除，用户需要手动把有用内容迁移到 `config.yaml` 的 `context:` 字段
- **迁移命令**：`openspec init`（会检测旧文件、引导清理）；CI 环境：`openspec init --force --tools claude`

此后（v1.0.x–v1.6.x）无进一步 breaking changes。计划中的 schema 重命名（`spec-driven` → `openspec-default`）会使用别名保持兼容。

---

## 三、社区最常见问题（来自官方 FAQ + Discord + GitHub）

### 3.1 入门类

| Q | A | 对应我们已有的研究 |
|---|---|---|
| OpenSpec 是什么？ | 在 AI 写代码前让开发者和 AI 在 spec 上达成一致的轻量层 | `_digested/system/01-系统心智模型.md` |
| 绑死某个 AI 工具吗？ | 否，支持 25+ 工具 | `_digested/system/04-agent-contract-与工具投递.md` |
| 能在已有大项目上用吗？ | 是，brownfield-first：只 spec 每次改动触及的部分 | `_digested/system/08-对照常见-SDD-与-AI-Coding.md` |
| 最简单的用法是什么？ | `/opsx:explore`（可选）→ `/opsx:propose` → `/opsx:apply` → `/opsx:archive` | `_faq_on_digested/03` 到 `07` 覆盖了每一步 |

### 3.2 混淆高发区

| Q | A |
|---|---|
| Slash commands 不出现怎么办？ | 运行 `openspec update` → 重启 IDE → 检查 `.claude/skills/` 是否有文件。确认在 AI chat 里输入（不是终端） |
| Terminal vs AI Chat 的区别？ | `openspec ...` 在终端；`/opsx:...` 在 AI 助手的 chat 里。语法因工具而异（`/opsx:propose` vs `/opsx-propose`）——这是 **#1 支持问题** |
| 怎么升级？ | `npm install -g @fission-ai/openspec@latest` 然后每个项目里执行 `openspec update` |
| 怎么自定义？ | `openspec/config.yaml` 的 `context:` / `rules:` / `schema:` 字段；自定义 schema 用 `openspec schema fork spec-driven my-workflow` |

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
| v1.0.0 OPSX 迁移 | `_faq_on_digested/04–07` 全部基于 OPSX 工作流 | 迁移本身的断裂（旧 `/openspec:*` 用户的体验）没专门研究 |
| Profile/delivery 机制 | `_digested/spec_cli/05-config-profile-delivery.md` | Windsurf/Cursor 的实际 bug 是 adapter 层健壮性问题，我们没覆盖 |
| Store 模型 | `_digested/system/03-planning-home-与-store-模型.md` | Initiative 跨 repo 协调层我们没研究 |
| SDD 工具对比 | `_digested/system/08-对照常见-SDD-与-AI-Coding.md` | 和 SpecKit/Kiro 的具体对比我们已有 |
| Config 怎么配 | `_faq_on_digested/08_config-yaml-growth/` | `project.md` → `config.yaml` 的迁移痛点和我们问的"普通程序员怎么配 config"是同一个问题的不同阶段 |

---

## 五、关键判断

1. **"轻量" 是特性也是限制**：OpenSpec 不做 TDD 强制执行、不做自动化 spec-code 对账、不做结构化 requirement ID——这些都是刻意的设计取舍。如果项目需要这些，应该评估 SpecKit（更重但更严格）。

2. **Initiative 概念会让现有模型变旧**：我们今天理解的 "一个 change 是一个 repo 内的修改" 是 Phase 1 产物。Phase 2 initiative 引入后，change 变成跨 repo 的子资源。`_faq_on_digested/` 里对 explore/propose/apply/archive 的分析到时候需要重新审视。

3. **工具集成脆弱性是长期问题**：只要 OpenSpec 的策略是 "同一 workflow 投放给 N 个工具"，per-tool adapter 的维护负担就会随工具数量线性增长。上游尚无自动化测试覆盖每个工具的集成。

4. **社区 fork（`openspec-plus`）说明定制需求未被满足**：`openspec-plus` 增加了 apply/archive 的 config 注入——这正是 `_faq_on_digested/08` 问的 "普通程序员怎么配 config" 的社区回答：有人觉得上游不够灵活，直接 fork 了。

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
- [Issue #821 — /opsx:repair](https://github.com/Fission-AI/OpenSpec/issues/821)
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
