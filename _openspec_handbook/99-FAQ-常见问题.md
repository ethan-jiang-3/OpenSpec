# 99 · FAQ：常见问题

> 这一篇汇总了新手与进阶用户在落地时最常问的问题，按主题分类速查（适用 openspec 2.1.1）。

---

## 基础概念

### Q1: OpenSpec 到底是什么？
**A**: **OpenSpec 是一个“先把 change 讲清楚，再去写代码，最后把增量行为沉淀回正式基线”的宿主无关协作层。** 它把一次改动拆成几份能讨论、能校验、能归档的文本文件（`proposal.md` / `specs/` / `design.md` / `tasks.md`）。快速上手流程见 [01 初级·先把 OpenSpec 用起来](01-初级-先把-openspec-用起来.md)。

### Q2: OpenSpec 和传统文档有什么区别？
**A**: 传统 PRD 是“写完锁死或迅速腐烂”，OpenSpec 是“边做边修、归档合入基线”。它用 delta spec 只表达本次增量变化（`ADDED` / `MODIFIED` / `REMOVED` / `RENAMED`），不用每次重写整份系统说明书。三层模型详见 [10 中级·把核心概念真正串起来](10-中级-把核心概念真正串起来.md)。

### Q3: 我必须用 AI 工具吗？
**A**: 不是必须的。你可以纯手工编辑 Markdown 并用终端 `openspec` CLI 校验和归档，但配合支持 Agent Skills 的 AI 工具效率最高。v2.1.1 共内置支持 **87 个 AI 工具目标**（包括 Claude Code、Codex、Cursor、GitHub Copilot、Zed Agent、OpenCode、Cline、Kiro、Devin Desktop、Antigravity、Amp、GSD、DeepSeek Harness、Warp、Grok Build 等，以及兜底的 vendor-neutral 目标 `--tools agents`）。完整列表以 `openspec init --help` 为准。

---

## 命令和工作流

### Q4: OpenSpec 和 OPSX 是两个东西吗？
**A**: 不是。OpenSpec 是整套机制；`opsx` 只是 OpenSpec 1.x 时代部分工具斜杠命令文件的旧命名空间前缀（v2.0.0 起命令文件已移除）。

- `openspec`：终端确定性 CLI，例如 `openspec init`、`openspec status --change <name> --json`、`openspec archive <name>`。
- `openspec-*`：**唯一的宿主工作流形态（skill）**。在 Claude Code、Zed、Cursor 等宿主里按 `/openspec-propose` 调用，在 Codex 里按 `$openspec-propose` 调用，也可直接用自然语言描述任务让 agent 自动选用。
- 技能存放位置：v2.1 默认装在本机全局 `~/.agents/skills/`（Claude Code 等另在 `~/.claude/skills/` 建符号链接）；加 `--scope project` 时则装在项目内 `.agents/skills/` 与 `.claude/skills/`。

分层细节详见 [50 实战·Claude Code 里的 OpenSpec 到底怎么落地](50-实战-claude-code-里的-openspec-到底怎么落地.md)。

### Q5: 宿主 propose workflow 和 CLI 是什么关系？
**A**:
- 技能 `openspec-propose`（Claude Code 里敲 `/openspec-propose`，Codex 里敲 `$openspec-propose`）是宿主侧工作流说明，agent 触发后会按步骤自动调用多条 `openspec` CLI 命令。
- 终端 CLI 里**没有** `openspec propose` 这个子命令。
- 它背后的真实底层调用链是：`openspec new change <name>` → `openspec status --change <name> --json` → 逐个运行 `openspec instructions <artifact> --change <name> --json` 并由模型落盘写文件。
- **状态注记（v2.1.1）**：1.x 时代的 **`/opsx:*` 命令文件已在 v2.0.0 移除**，不再生成；同一份工作流的 **skill**（如 `openspec-propose`）完整保留下来，现在统一通过 `/openspec-propose`（Claude Code 等）、`$openspec-propose`（Codex）或自然语言触发。机器协议详见 [90 附录·给机器看的 Agent 协议](90-附录-给机器看的-agent-协议.md)，升级背景见 [Q27h](#q27h-提示说command-files-are-deprecated-and-go-away-in-openspec-20我的-cli-要没了)。

### Q6: 我必须按 propose → apply → archive 的死顺序走吗？
**A**: 不必死板锁阶段。这是推荐主干，但你在 `apply` 写代码时发现原设计不成立，随时可以回头用 `/openspec-update-change` 或手改修正 `proposal.md` / `design.md` / `specs/` / `tasks.md`——这就是 **"Actions, not phases"**。同时，当实现任务所需范围超出当前 spec 承诺时，apply 工作流要求停下来摊开新增范围，而不是私自缩水或硬塞。节奏与边界详见 [11 中级·定位节奏与边界](11-中级-定位节奏与边界.md)。

### Q7: 什么时候该用 core profile，什么时候用 custom？
**A**:
- **core**（默认，6 个技能）：`propose` / `explore` / `apply` / `update` / `sync` / `archive`，足以覆盖绝大多数个人与团队日常研发。
- **custom**（最多 12 个技能）：可在 `core` 之外按需勾选 `new` / `continue` / `ff` / `verify` / `bulk-archive` / `onboard`，适合需要逐个 artifact 推进或独立合规校验的复杂项目。
- **切换方式**：终端运行 `openspec config profile`，再按提示或运行 `openspec update` 刷新技能。详见 [01](01-初级-先把-openspec-用起来.md) 与 [52](52-实战-如何正确修改-artifacts.md)。

---

## specs 和 changes

### Q8: `specs/` 一开始是空的吗？
**A**: 是的，完全正常。`openspec init` 后 `openspec/specs/` 为空；当你完成第一个 change 并执行 `archive`（或 `sync`）后，正式基线才会从 delta spec 自动生长出来，不需要预先手写全套 `specs/`。greenfield 首版基线建法见 [53 实战·从零开始设计一个较复杂系统](53-实战-从零开始设计一个较复杂系统.md)。

### Q9: 我要手动直接改 `openspec/specs/` 吗？
**A**: 日常迭代通常不直接手改主 `specs/`，而是：
- 在 `changes/<name>/specs/<capability-path>/spec.md` 里写 delta spec；
- 通过 `archive`（或多人并行时的 `/openspec-sync-specs`）合并回 `openspec/specs/`。
- 若本次改动纯属内部重构、工具链或文档调整、无任何外部可观察行为变化，在 change 的 `.openspec.yaml` 中声明 `skip_specs: true`（此时 `specs/` 下不得存在任何文件）。详见 [10 中级·把核心概念真正串起来](10-中级-把核心概念真正串起来.md)。

### Q10: delta spec 和正式 spec 有什么区别？
**A**:
- **delta spec**：位于 `changes/<name>/specs/<capability-path>/spec.md`，只描述“这次改了哪里”（`## ADDED` / `MODIFIED` / `REMOVED` / `RENAMED Requirements`；仅新建 capability 时首段加不少于 50 字符的 `## Purpose`）。
- **正式 spec**：位于 `openspec/specs/<capability-path>/spec.md`，描述“系统当前正式承认的行为合同”（`## Purpose` + `## Requirements`）。
- 正反示例详见 [10 中级·把核心概念真正串起来](10-中级-把核心概念真正串起来.md)。

### Q11: `REMOVED` 标记什么时候用？
**A**: 下线旧功能或废弃行为合同时使用。标题 `### Requirement: <name>` 必须与主 spec 基线里的名称精确一致，并在下方写明 **`**Reason**`**（为何移除）与 **`**Migration**`**（替代方案或迁移路径）。完整案例见 [51 实战·从一个真实 change 走完整条主线](51-实战-从一个真实-change-走完整条主线.md)。

### Q11a: `/openspec-verify-change` 怎么核对 `REMOVED` 的基线？
**A**: 先按**精确规范化名称**在主 spec 里找基线：取 `Requirement:` 后的标题文本、trim，仅当结尾 `#` 串前有空格/tab 时去掉这段 `#`（所以 `C#` 保留 `#`），大小写敏感比较。相似措辞不算匹配；改名属于 `RENAMED`。主 spec 里已不存在该名称（例如已提前 sync）时，去 Git 历史里查（`git -C "<planningHome.root>" log -p -- openspec/specs/<capability-path>/spec.md`）。只有标题重述、没有正文/scenario 的基线不可用；主 spec 与历史都拿不到可用基线时，该条 Spec Coverage 标 **not verified** 并跳过代码搜索，绝不把没查过的移除算通过。治理细节见 [26 高级·治理边界与漂移维护](26-高级-治理边界与漂移维护.md)。

---

## artifacts

### Q12: 为什么要有这么多文件（proposal/specs/design/tasks）？
**A**: 四份文件各自守住一道边界：
- **`proposal.md`**：守立项动机、影响域（`Capabilities`）与不做项（防止 scope 失控）
- **`specs/`**：守外部可观察行为合同与验收场景（防止需求含糊）
- **`design.md`**：守架构选型、权衡与回滚策略（防止实现随意）
- **`tasks.md`**：守带验证标准的实施步骤（防止编码失序）

详见 [10 中级·把核心概念真正串起来](10-中级-把核心概念真正串起来.md)。

### Q13: 怎么判断一句话该放 spec 还是 design？
**A**: 快筛标准：**如果换一种内部实现方式，用户或下游调用方能不能感知到变化？**
- 能感知到（如“点击导出后下载包含当前筛选结果的 CSV”）→ **spec**（What）
- 感知不到（如“后端采用同步流式输出还是异步队列任务”）→ **design**（How & Why）

详见 [10](10-中级-把核心概念真正串起来.md) 与 [51](51-实战-从一个真实-change-走完整条主线.md)。

### Q14: `proposal.md` 里的 `Out of Scope` 有什么用？
**A**: 专门给人和 AI 画停火线。内置模板强制要求的是 `## Why`、`## What Changes`、`## Capabilities`、`## Impact` 四节；在此基础上自加一节具体的 `## Out of Scope`，能有效阻止 AI 顺手多做 XLSX、定时任务、邮件推送等旁支需求。修改示范见 [52 实战·如何正确修改 Artifacts](52-实战-如何正确修改-artifacts.md)。

---

## archive 和冲突

### Q15: archive 是自动的还是手动的？
**A**: 必须由你显式触发（宿主里的 `/openspec-archive-change` 或终端 `openspec archive <name>`）。执行时 CLI 会先做结构与合并预检，通过后将 delta spec 原子化写回 `openspec/specs/`，再把 change 移入 `openspec/changes/archive/YYYY-MM-DD-<name>/`（在 v2.1.1 `#2277` 中，归档工作流会先确定归档目标路径再写主 spec，确保顺序稳健；新建主 spec 时 `#2267` 自动在 `## Purpose` 后补齐空行以兼容 Prettier 与 MD022）。

两个实用细节：
- 交互式确认 `Proceed with spec updates? (Y/n)` **默认是 Yes（回车即更新）**；仅归档不改主 spec 时须显式输 `n` 或传 `--skip-specs`。
- `tasks.md` 全部勾完时 `instructions apply` 返回的 `all_done` 提示是提醒你归档前做最终 review/verify，不是自动替你归档。详见 [01](01-初级-先把-openspec-用起来.md) 与 [26](26-高级-治理边界与漂移维护.md)。

### Q16: archive 时有冲突或告警怎么办？
**A**: OpenSpec 绝不会往主 spec 里写 `<<<<<<<` 冲突标记——一旦合并预检不过，archive 立即中止且保持主 spec 与活跃 change 原封不动。按以下顺序处理：

1. 阅读报错与最新主 spec，确认其他已归档 change 对同一 requirement 做了什么修改。
2. 基于最新主 spec 重写当前 change 的 delta（多人并行流程见 [55 实战·多人协作与 Git 工作流](55-实战-多人协作与Git工作流.md)）。
3. 跑通 `openspec validate <change> --type change --strict` 后重新 archive。

常见四类归档告警/错误边界：
- **归档不会带走的散文（WARNING，`--strict` 下失败）**：delta spec 里写在四类操作段与 `## Purpose` 之外的段落（如 `## Notes`）或首个 requirement 前的散文会提示 `... is not carried into the main spec by archive`，请迁入 requirement、`proposal.md` 或 `design.md`（顶部的 YAML frontmatter 已在 v2.1.1 `#2273` 豁免）。
- **退役清理异常（`archive_retirement_cleanup_failed`）**：change 已移入 `archive/`，但退役主 spec 的备份校验或清理失败。重跑 archive 不会清理这些残留路径，请先按报错列出的路径核查内容后再手动清理。
- **capability 退役三分支**：① 只缺授权时在合法 `.openspec.yaml` 加 `retire_capabilities: true`；② 主 spec 仍有 `## Notes` 等未归属内容（blocking content）时加了 marker 也拒删，须先迁移或人工确认清理主 spec；③ metadata 无效时报错保持文件不变。三步修复见 [52 实战·如何正确修改 Artifacts](52-实战-如何正确修改-artifacts.md#capability-退役marker-不是万能绕过开关)。
- **CI/非交互环境**：stdin 关闭时 archive 不会挂起等输入，而是直接给出带完整参数的重跑命令（如 `openspec archive <name> --yes`）；想在 CI 检查历史归档里有无漏勾 checkbox，使用 `openspec validate --archived`。

### Q17: 代码写完了不 archive 会怎样？
**A**: `openspec/specs/` 停留在旧状态，后续新开的 change 读到过时基线，长期挂在 `changes/` 里的半截工作包也会让团队失去单一事实源。清理积压在途 change 的姿势见 [11 中级·定位节奏与边界](11-中级-定位节奏与边界.md) 与 [26 高级·治理边界与漂移维护](26-高级-治理边界与漂移维护.md)。

---

## config 和 schema

### Q18: `config.yaml` 和 schema 有什么区别？
**A**:
- **`openspec/config.yaml`**：项目级背景（`context`）、按产物分流的写作规则（`rules.<artifact>`）、实施/归档操作提示（`operations.apply/archive.guidance`）以及团队技能作用域（`skillsScope: project`）。
- **schema**：定义 change 包含哪些 artifact、生成路径是什么、彼此依赖关系如何（默认是 `spec-driven`）。

若觉得“写了 config 但 agent 没听”，按此顺序排查：生效 root → `config.yaml` 是否压过同名 `.yml` → `openspec validate --all`（检查 YAML 语法）→ 当前 change 的 `.openspec.yaml` → `openspec instructions <artifact> --change <name> --json` 实际注入输出。详见 [21 高级·config、schema 与项目边界](21-高级-config-schema-与项目边界.md) 与 [23 高级·config.yaml 怎么写到真正好用](23-高级-config-yaml-怎么写到真正好用.md)。

### Q19: profile 和 schema 有什么区别？
**A**:
- **profile**：控制安装哪些工作流技能（`core` 6 个 vs `custom` 自选最多 12 个）。
- **schema**：控制每个 change 内部有哪些规划文件及 DAG 依赖（默认 `spec-driven`；自定义方法见 [25 高级·自定义 schema](25-高级-自定义-schema-创建自己的工作流.md)）。

两者边界详见 [21 高级·config、schema 与项目边界](21-高级-config-schema-与项目边界.md)。

### Q20: `.openspec.yaml` 是什么？
**A**: 每个 `changes/<name>/` 目录下的 change 元数据文件，记录 `schema: spec-driven`、`created: YYYY-MM-DD` 以及可选的 `skip_specs: true`、`retire_capabilities: true` 等受控标记。未知顶层键会触发校验告警（`--strict` 下失败）。详见 [10](10-中级-把核心概念真正串起来.md) 与 [52](52-实战-如何正确修改-artifacts.md)。

### Q20a: 怎样让新项目用中文或其他语言写 artifacts？
**A**: 新项目用 `openspec init --language "简体中文"`；它会在新建 `config.yaml` 的 `context` 中写入语言指令。已有配置文件时该参数会报错拒绝覆盖，手工把语言说明合入 `context` 即可。注意：正文描述可用中文，但 `## ADDED Requirements`、`### Requirement:`、`#### Scenario:` 与规范词 `SHALL` / `MUST` 必须保持英文。详见 [01](01-初级-先把-openspec-用起来.md) 与 [23](23-高级-config-yaml-怎么写到真正好用.md)。

### Q20b: 我能在 `.openspec.yaml` 里放自己的工单号等元数据吗？
**A**: 可以。顶层以**小写 `x-`** 开头且前缀后紧跟非空白字符的扩展键（如 `x-tracker: PROJ-12`、`x-jiraKey: ABC-1`）专为自定义元数据预留，OpenSpec 不干预其值，且 `openspec validate --strict` 完全放行；archive 时会原样随目录归档。详见 [52 实战·如何正确修改 Artifacts](52-实战-如何正确修改-artifacts.md)。

---

## 高级话题

### Q21: 怎么处理 change 之间的依赖？
**A**: OpenSpec 不内置跨 change 自动排程引擎。团队最佳实践是：先在 `main` 上合并并 archive 前置 change，再拉取最新 `main` 开启下游 change，并在下游 `proposal.md` 与 PR 描述中显式注明前置依赖。多分支与 Stacked Changes 流程详见 [55 实战·多人协作与 Git 工作流](55-实战-多人协作与Git工作流.md)。

### Q22: 怎么回滚一个已经归档的 change？
**A**: 已归档记录是历史账本，不要直接手删 `changes/archive/`。正确做法是：对照 `changes/archive/<date>-<name>/` 里的原 delta，新开一个反向回滚 change（用 `REMOVED` / `MODIFIED` 恢复行为基线），连同代码回滚一起评审并 archive。正向完整闭环见 [51 实战·从一个真实 change 走完整条主线](51-实战-从一个真实-change-走完整条主线.md)。

### Q23: 怎么处理 breaking change？
**A**: 在 `proposal.md` 的 `## What Changes` 中用 `**BREAKING**` 显式标出破坏性变更，在 delta spec 的 `MODIFIED` / `REMOVED` 中写清行为合同变化与 `**Migration**`，并在 `design.md` 中给出分步迁移与回滚预案。详见 [52](52-实战-如何正确修改-artifacts.md) 与 [54](54-实战-用-openspec-管理-devops-部署与验证.md)。

### Q24: `specs/` 的目录结构怎么组织？
**A**: 按**可独立解释、独立演进、独立验证的行为合同（capability）**切分，推荐浅层的“一层 domain + 一层 capability”结构（如 `identity/login/spec.md`、`requests/submission/spec.md`），不要按 MVC 代码分层或页面按钮切目录。记住：**capability 的身份就是它在 `specs/` 下的完整相对路径**，domain 只是导航命名空间，不发生父子继承或自动检索。完整切分与重基线原则详见 [26 高级·治理边界与漂移维护](26-高级-治理边界与漂移维护.md)。

### Q25: 一个功能涉及多个域怎么办？
**A**: 先用 `openspec list --specs --json` 和 `openspec show <id> --type spec --json --no-scenarios` 按需筛选候选 capability，在 `proposal.md` 的 `## Capabilities` 中只列出真正发生 spec 级行为改变的 path（其余仅需回归核对的记为 verify only，不造空 delta），再为每个受影响 path 各写一份 delta spec。详见 [26](26-高级-治理边界与漂移维护.md) 与 [53](53-实战-从零开始设计一个较复杂系统.md)。

---

## 工具集成与升级

### Q26: OpenSpec 支持哪些 AI 工具？在 2.1.1 里怎么分类？
**A**: OpenSpec 2.0+ 已全面切为 **skills-only 架构**（不再为任何工具生成 1.x 的斜杠命令文件），底层接入 `skills@1.8.1`，共支持 **87 个工具目标**，分为两类：

- **33 个通用目录工具（universal）**：直接读取 `.agents/skills/openspec-*/SKILL.md`，无需单独工具目录——包括 Codex（`$openspec-*`）、Zed Agent、OpenCode、Cursor、GitHub Copilot、Antigravity、Amp、GSD、DeepSeek Harness（`dsh`）、Warp、Veai，以及给未列名工具兜底的 `agents`（选择器中显示为 `Other / Universal (shared .agents skills)`）。
- **54 个链接目录工具（skill-linked）**：读取各自专属技能目录（如 Claude Code `.claude/skills/`、Kiro `.kiro/skills/`、Cline `.cline/skills/`、Grok Build `.grok/skills/`、Command Code `.commandcode/skills/`、Code Studio `.codestudio/skills/` 等），由 OpenSpec 自动创建指向 `.agents/skills/` 真身的相对符号链接（Windows 项目安装或无法建链接时退化为拷贝）。
- **退役与改名映射**：Amazon Q Developer（`amazon-q`）因不支持加载 skills 已退役，`openspec init --tools amazon-q` 会直接报错并指引改用继任工具 `openspec init --tools kiro`；旧 `--tools windsurf` 保留为指向 `devin`（Devin Desktop）的兼容别名。架构细节见 [90 附录·给机器看的 Agent 协议](90-附录-给机器看的-agent-协议.md)。

### Q27: 怎么把 OpenSpec 安装并同步到我的 AI 工具？
**A**:
1. **新项目默认全局安装（`global` 作用域）**：在项目根目录运行 `openspec init`（或 `openspec init --tools claude,cursor`）。项目内只生成 `openspec/`，技能在本机 `~/.agents/skills/`（及各工具全局目录链接）只装一份，本机所有项目共享。
2. **随仓库共享安装（`--scope project`）**：若团队使用只读仓库文件的云端托管 Copilot coding agent 或希望锁死仓库级技能版本，运行 `openspec init --scope project --tools claude`；交互式 `openspec update` 选择保留在项目内时会在 `openspec/config.yaml` 记入 `skillsScope: project`（Windows 队友需开启 `git config --global core.symlinks true` 与系统开发者模式）。
3. **离线安装与日常更新**：v2.1.1（`#2283`）起 `init` / `update` 直接从本地 npm 包内置模板离线安装技能，无需联网或 Git；此前用 `npx skills add` 装进项目的官方技能也会被 `openspec update` 自动识别刷新（`#2269`）。升级 CLI 后跑 `openspec update`（可先 `--dry-run`）即可。详见 [50](50-实战-claude-code-里的-openspec-到底怎么落地.md) 与 [55](55-实战-多人协作与Git工作流.md)。

### Q27a: 为什么很多工具都指向 `.agents/skills/`？`.openspec-target` 是干什么的？
**A**: 1.x 时代只有 Codex、Zed 等少数工具共用 `.agents/skills/` 并靠 `.openspec-target` 单行仲裁谁来写；**从 2.0 起，`.agents/skills/` 成了所有工具的唯一技能真身目录**——33 个通用工具直接读它，其余 54 个工具（如 Claude Code）从自己的 `skills/` 目录建相对链接指向它。在 `--scope project` 项目级安装下，`.agents/skills/.openspec-target` 升级为**当前项目已配置的工具清单**（每行一个工具 ID，带自有链接的标 `claude own-files`），供 `openspec update` 识别需要维护哪些工具链接，且 OpenSpec 绝不会创建或篡改项目根 `AGENTS.md`。详见 [50](50-实战-claude-code-里的-openspec-到底怎么落地.md) 与 [90](90-附录-给机器看的-agent-协议.md)。

### Q27b: 为什么全局安装后没有立刻弹出 shell completion 提示？
**A**: Tab 补全走的内部 `__complete` 路径完全跳过遥测与首次提示；同时 `--json` 输出、非 TTY 管道、CI 环境、`completion` 子命令本身或设置了 `OPENSPEC_NO_COMPLETIONS=1` 时，首次补全提示都会静默延后（defer），只在你真正交互式使用终端 CLI 且到达 `postAction` 时在 `stderr` 提示一次 `openspec completion install`（zsh 会优先尊重 `$ZDOTDIR/.zshrc`；Windows `cmd.exe` 会明确提示不支持而不会误改 PowerShell 配置）。详见 [01 初级·先把 OpenSpec 用起来](01-初级-先把-openspec-用起来.md)。

### Q27c: custom profile 只选了 `archive`，为什么还自动装上了 `sync`？
**A**: `archive` 与 `bulk-archive` 在工作流内部依赖 `sync` 的合并规格能力，CLI 会在第一个依赖项前自动补入 `sync`（已有则不重复、不打乱顺序），确保归档技能不会缺腿。

### Q27d: 为什么老版本 `openspec validate --all` 在某些 pre-commit 钩子里会挂住？
**A**: 部分钩子包装器（如 lefthook）分配的伪终端报告 `isTTY: true` 但宽度 `columns: 0`，早期 spinner 计算清屏行数时产生 `Infinity` 死循环。v1.14.3+ 已专门拦截“TTY 但 `columns` 为 0”退回纯文本输出，升级 CLI 即彻底解决。

### Q27e: `openspec --help` 和 `--json` 为什么启动很快？
**A**: CLI 将子命令的语法注册（`src/cli/index.ts`）与业务实现解耦，执行具体子命令时才按需 `await import()` 加载实现模块，且 `--json` 模式不加载终端 spinner 库 `ora`。

### Q27f: 不装 Node.js 能用 OpenSpec 吗？有哪些安装和升级通道？
**A**: 能。当前主流有三种安装通道：

1. **Standalone 单文件二进制（无需 Node.js，v1.15.0+）**：覆盖 macOS 13+、Linux glibc 2.17+、Alpine 3.17+（需 `apk add libstdc++ libgcc`）、Windows 10+ 的 x64/arm64 共 8 个平台（归档为 `.tar.gz` / Windows `.zip`，自动校验 `SHA256SUMS`）：
   - macOS / Linux：`curl -fsSL https://openspec.dev/cli/install.sh | sh`
   - Windows PowerShell：`irm https://openspec.dev/cli/install.ps1 | iex`
   - 已安装任一版本时也可运行 `openspec install` 切换到 standalone（默认装在 `~/.local/bin/openspec`，不会自动替你删旧 npm/Homebrew 副本，但会打印卸载命令）。后续升级直接重跑 `openspec install`。
2. **Homebrew（macOS / Linux，自带 Node 依赖）**：`brew install openspec`（位于官方 `homebrew-core`，无需 tap），升级运行 `brew upgrade openspec`。
3. **Node 包管理器（npm / pnpm / bun / volta）与 Nix**：`npm install -g @fission-ai/openspec@latest` 需要 **Node.js `22.20.0+`**（v2.1.1 `package.json` `engines.node` 门槛）；Nix 用户可使用 `nix profile install github:Fission-AI/OpenSpec`。

此外自 v2.1.1（`#2264`）起，`openspec version --check` 与 `openspec update` 会优先识别 Homebrew Cellar 与 `/nix/store` 路径——Homebrew 安装会准确提示 `brew upgrade openspec`，Nix 安装则提示按原 Nix 方式升级，不再误报 `npm install -g`。首次上手见 [01 初级·先把 OpenSpec 用起来](01-初级-先把-openspec-用起来.md)。

### Q27g: 我的项目是从 0.x / 1.x 很旧的版本升上来的，`update` 要分步跑很多次吗？
**A**: 不用。`openspec update` 支持从 **0.12 以来任意旧版本一次升级到位**，且不需要加 `--force`。它使用内置历史版本发布指纹库比对旧命令文件：证明未被修改过的原厂旧文件自动清理；**你手工改过的旧命令文件会完整保留并列出路径**；清理器绝不跨符号链接删除目标（主目录 `~` 下跨项目共用的旧全局 prompt 文件仅在交互确认或 `--force` 时才清理）。注意：`.agents/skills/openspec-*/` 内置技能目录会被整目录刷新，若曾手改过内置 `SKILL.md` 请先备份并迁入 `openspec/config.yaml`。

### Q27h: 提示说"Command files are deprecated and go away in OpenSpec 2.0"，我的 CLI 要没了？
**A**: 不是。**移除的是宿主工具里的 1.x 斜杠命令文件（如 `.claude/commands/opsx/*.md`），终端 `openspec` CLI 一个子命令都没少。**

在 1.x 中，同一套工作流同时生成过两份包装：命令文件（`/opsx:propose`）和技能（`openspec-propose`）。v1.17.0 打印过上述弃用预告，而 **v2.0.0 起命令文件与 `delivery` 配置已正式移除**，只保留功能完全等价的 `openspec-*` skills：
- 终端里的 `openspec validate` / `archive` / `status` / `instructions` / `update` 原样保留；
- AI 工具里改用 `/openspec-propose`（Claude Code、Zed、Cursor 等）、`$openspec-propose`（Codex），或直接用自然语言描述任务。详见 [01](01-初级-先把-openspec-用起来.md) 与 [50](50-实战-claude-code-里的-openspec-到底怎么落地.md)。

### Q27i: 升级后 `validate` 突然报错了，是回归吗？
**A**: 多半不是回归，而是 v1.16–v2.1.1 补齐的校验规则把以前静默漏检的问题显式报了出来。按级别对照下表即可定位：

| 校验规则 | 级别 | 对 `validate` / `--strict` / `archive` 的影响 |
|---|---|---|
| `openspec/config.yaml`（或 `.yml`）不可读或 YAML 语法损坏 | **退出 1**（`unreadable_config` / `unparseable_config`） | `openspec validate` 直接硬失败（其他命令仅打印警告回退） |
| requirement 写在 `## DEPRECATED Requirements`、`## Add Requirements` 等“像 delta 操作但拼错”的标题下 | **ERROR** | 普通 `validate` 报错，`archive` **直接拒绝**（防止整条 requirement 被静默丢弃；写在 `## Notes` 等普通散文段下则仍为 WARNING） |
| `#### Scenario:` 缺少 **WHEN/GIVEN** 触发步，或缺少 **THEN** 结果步 | **WARNING** | 普通 `validate` 与 `archive` 放行；**`validate --strict` 失败** |
| **v2.1.1 `#2265`**：`MODIFIED` requirement 正文总长度 **超过 500 字符，且比主 spec 基线中该条原有正文更长**（`nextText.length > 500 && nextText.length > currentTextLength`） | **WARNING** | 普通 `validate` 放行；**`validate --strict` 在 archive 前提前拦住**（原样保留或缩短历史超长 requirement 不触发警告） |
| **v2.1.1 `#2273`（误报修复）**：delta spec 文件顶部的 YAML frontmatter（`---` 包裹且首项为 `key: value`） | **豁免（无警告）** | 不再被当成“归档不会带走的顶部散文”，带 frontmatter 的 delta spec 可正常通过 **`validate --strict`** |

治理闸门全貌见 [26 高级·治理边界与漂移维护](26-高级-治理边界与漂移维护.md)，具体修法见 [52 实战·如何正确修改 Artifacts](52-实战-如何正确修改-artifacts.md)。

### Q28: 为什么除了 `openspec/`，还会有 `.agents/skills/` 或 `.claude/skills/`？
**A**:
- **`openspec/`**：项目事实层（`specs/`、`changes/`、`config.yaml`），永远随业务仓库提交。
- **`.agents/skills/` 与 `.claude/skills/`**：工具入口层（`openspec-*` skills）。在 v2.1 默认的 `global` 作用域下，它们住在你本机的 `~/.agents/skills/` 与 `~/.claude/skills/`，项目仓库里根本不出现工具目录；只有加 `--scope project` 时才会写入项目根目录。这样设计是为了让项目资产与具体 AI 工具彻底解耦。详见 [50 实战·Claude Code 里的 OpenSpec 到底怎么落地](50-实战-claude-code-里的-openspec-到底怎么落地.md)。

---

## 疑难杂症

### Q29: 我的 change 一直卡在某个 `blocked` 的 artifact 怎么办？
**A**: 先跑 `openspec status --change <name>` 看 `blocked by` 点名缺哪份前置产物（默认 `spec-driven` 下 `tasks` 同时依赖 `specs` 和 `design`），补齐前置产物即可解锁；若开启了 custom profile，也可用 `/openspec-ff-change` 按依赖序一次补齐剩余产物（它同样遵守 schema 依赖图，不会跳过前置产物）。详见 [11](11-中级-定位节奏与边界.md) 与 [25](25-高级-自定义-schema-创建自己的工作流.md)。

### Q30: AI 生成的 artifacts 太泛泛、贴不上项目实际怎么办？
**A**: 90% 是因为 `openspec/config.yaml` 还是空壳。把技术栈、模块边界填进 `context`，把各产物的硬性写作要求填进 `rules.proposal` / `rules.specs` / `rules.design` / `rules.tasks`，生成后配合 `explore` 与 `/openspec-update-change` 打磨一轮。配置写法详见 [23 高级·config.yaml 怎么写到真正好用](23-高级-config-yaml-怎么写到真正好用.md)。

### Q31: 我可以跳过某个 artifact 吗？
**A**: 分两种情况：
- **没有 spec 级行为变化**（纯重构、CI 脚本、文档维护）：在 change 的 `.openspec.yaml` 加 `skip_specs: true`（且删空该 change 的 `specs/`），`specs` 产物即合法变为 `skipped`。
- **团队长期不需要 `design.md` 等某类产物**：不要每次手建空文件应付 DAG，直接 fork 或自定义一套精简 schema。详见 [11](11-中级-定位节奏与边界.md) 与 [25 高级·自定义 schema](25-高级-自定义-schema-创建自己的工作流.md)。

---

## Store 跨仓库协同

### Q32: store 是什么？和仓库里的 `openspec/` 有什么关系？
**A**: Store 是本机注册的一个仓库 checkout，供其他仓库通过 `config.yaml` 的 `references:` 声明跨仓库只读引用，或者通过 config-only 的 `store:` 指针把规划外置到独立规划仓。单仓库项目完全不需要 store。完整模型详见 [24 高级·store 跨仓库协同](24-高级-store-跨仓库协同.md)。

### Q33: 我什么时候才需要 store？
**A**: 只有当前仓库的 change 需要按需查阅**另一个已 checkout 仓库**的正式 `specs/`（或团队明确采用独立规划仓）时才启用。如果只是“单仓库自己的 specs 太多找不到”，应该用浅层 capability 目录与按需 `list --specs` / `show --type spec`（见 [26](26-高级-治理边界与漂移维护.md)），而不是引入 store。详见 [24 高级·store 跨仓库协同](24-高级-store-跨仓库协同.md)。

### Q34: `references:` 会修改我引用的上游仓库吗？
**A**: 绝不会。`references:` 只是只读关系声明：`openspec context` 与 `instructions` 只提供上游 store 的本地路径、摘要索引与 `openspec show --store <id>` 按需读取入口，不会写入被引用仓库。详见 [24 高级·store 跨仓库协同](24-高级-store-跨仓库协同.md)。

### Q35: store、reference、context、workset 四个词有什么区别？
**A**:
- **store**：本机全局注册的仓库 checkout（`openspec store register`）
- **reference**：项目在 `openspec/config.yaml` 声明关注的 store ID（`references:`）
- **context**：当前项目的跨仓库只读工作集查询（`openspec context`）
- **workset**：纯个人本地的多目录编辑器打开视图（`openspec workset create/open/list/remove`），不进 Git、不从 `references:` 自动推导

详见 [24 高级·store 跨仓库协同](24-高级-store-跨仓库协同.md)。

### Q36: 怎么三步开始使用 store？
**A**:
1. 注册上游仓库：`openspec store register /path/to/other-repo --id other-repo`
2. 在当前仓库 `openspec/config.yaml` 声明：`references: [other-repo]`
3. 运行 `openspec context`（及 `openspec doctor`）核对健康状态，照常在当前仓库创建和归档 change。完整排障见 [24 高级·store 跨仓库协同](24-高级-store-跨仓库协同.md)。

---

## 压缩结论

1. **核心资产永远在 `openspec/`**：`specs/` 是当前行为基线，`changes/` 是增量工作包，`config.yaml` 是项目全局输入。
2. **2.0+ 只有 skills、2.1 默认装本机全局**：用 `/openspec-*` 或 `$openspec-*` 触发工作流，升级 CLI 后跑一次 `openspec update` 即可同步。
3. **遇到行为疑问先回看对应主题篇**：新手跑流程看 [01](01-初级-先把-openspec-用起来.md)，概念边界看 [10](10-中级-把核心概念真正串起来.md) / [11](11-中级-定位节奏与边界.md)，机器强弱闸门看 [26](26-高级-治理边界与漂移维护.md)，落地实操看 [50](50-实战-claude-code-里的-openspec-到底怎么落地.md)–[55](55-实战-多人协作与Git工作流.md)。
