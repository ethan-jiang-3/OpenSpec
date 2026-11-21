# 51 · 实战：从一个真实 change 走完整条主线

> 前面的几篇已经把概念一层层拆开了。这一篇不再单独讲概念，而是用一个完整的 BuildFlow 案例，把 `explore → propose → apply → archive` 整条主线真正走一遍（适用 openspec 2.1.1；下文以 Claude Code 的 `/openspec-*` 作为技能触发示例）。

---

## 开始前的准备：这个案例假设你已经...

**必须先读过的**：
- `01` 初级篇 —— 知道几个基本动作
- `10` 中级篇 —— 理解 `specs/`、`changes/`、artifact 与 delta spec

**如果没读过上面两篇**：
- 你会不理解"为什么要有这么多文件"
- 你会不理解"delta spec 是什么"
- 你会不理解"archive 在干什么"

**建议**：如果你是直接跳到这篇的，先回去读 `01` 和 `10`，会顺很多。

---

## 这一篇解决什么问题

很多人单独看概念时会觉得：

- 我好像知道 `specs` 是什么了
- 我也知道 `changes` 是什么了
- `proposal / specs / design / tasks` 也都认识了

但一旦回到真实项目，脑子里还是会冒出这些问题：

- 一个 change 到底是从哪一步开始"成形"的？
- `proposal`、delta spec、`design`、`tasks` 之间，到底是先后关系，还是互相修订关系？
- `apply` 时，到底是在"执行任务"，还是在"继续完善 change"？
- `archive` 到底只是挪文件，还是一种"正式沉淀"？

**在真实棕地项目里，OpenSpec 管的从来不是“写几份文档”，而是“从正式基线出发、把一次有边界的增量变化安全地落回正式基线”。**

---

## 这次案例选什么

这里不用特别大的系统，就用工程项目管理系统 BuildFlow 里一个非常典型、但又足够真实的增量需求：

> 以 BuildFlow 为例——**给已有 Web 应用新增“导出筛选后施工任务 CSV”能力，并顺手退役没人用的旧单页 PDF 导出。**

为什么选这个例子？

因为它刚好具备 OpenSpec 最典型的几种特征：

- 不是从零做系统，而是在已有系统上增量开发（brownfield）
- 同时涉及新增能力（`ADDED`）、修改已有行为（`MODIFIED`）与淘汰旧能力（`REMOVED`）
- 会同时碰到产品意图、行为 spec、技术方案和实施拆解
- 实现到一半还会撞上“列表分页 vs 全量导出”的真实设计反咬

---

## 先给出项目背景

假设 BuildFlow 当前目录结构是这样：

```text
buildflow/
├── src/
│   ├── tasks/
│   ├── auth/
│   └── ui/
├── tests/
└── openspec/
    ├── specs/
    │   ├── task-tracking/
    │   │   └── spec.md
    │   └── auth/
    │       └── spec.md
    ├── changes/
    └── config.yaml
```

而当前 `openspec/specs/task-tracking/spec.md` 里，已经存在正式基线 spec：

```markdown
# Task Tracking Specification

## Purpose

Tracks construction tasks across BuildFlow projects so site managers and engineers can inspect progress, filter schedules, and export task records.

## Requirements

### Requirement: Task List Visibility
The system SHALL allow authorized project staff to view the construction task list.

#### Scenario: Staff user opens task list
- **WHEN** an authenticated project staff user opens the Construction Tasks page
- **THEN** the system displays recent construction tasks for the project

### Requirement: Task Filtering
The system SHALL allow authorized project staff to filter construction tasks by date range and status.

#### Scenario: Filter tasks by status
- **WHEN** a project staff user on the Construction Tasks page selects status = Completed
- **THEN** only completed construction tasks are shown

### Requirement: Legacy Task PDF Export
The system SHALL allow authorized project staff to download the current task page as a static PDF snapshot.

#### Scenario: Export current page as PDF
- **WHEN** an authorized project staff user clicks Export PDF
- **THEN** the system downloads a static PDF snapshot of the visible page
```

注意这里的意思是：

- 这些不是"未来想法"
- 而是当前项目正式承认的行为基线

这就是后面所有 change 的出发点。

---

## 第 0 步：为什么这件事值得开一个 change

产品同学提了一个需求：

> 项目经理和现场监理希望把筛选后的施工任务导出成 CSV，方便线下核对进度并定期发给甲方代表；旧的单页 PDF 截图导出没人用且经常漏掉翻页数据，准备一并下线。

这时最容易犯的错误，是直接让 AI 去改代码：

```text
"帮我给施工任务页加一个导出 CSV 按钮，顺便把旧 PDF 按钮删掉。"
```

OpenSpec 的思路不是这样。

它会先把这件事当成一个 **change**：

- 这不是"随手改一行代码"
- 而是一次有边界的能力变更
- 需要能被表达、被讨论、被实现、被沉淀

所以第一步不是改代码，而是发起 change。

在发起 change 之前，你可以先 `/openspec-explore` 探一下现状——施工任务页现有 spec 写了什么、过滤逻辑在哪、谁有导出权限。这是选做，但能让 `proposal.md` 的 `What Changes` 和 `Capabilities` 写得更准。

---

## 第 0.5 步：先证明该改 `task-tracking`，而不是临时造一个 `export` capability

“CSV 导出”听起来像一个新功能，但 capability 的切分不是按按钮、接口或代码目录决定的。这里先做一次很小的 discovery：

```bash
openspec list --specs --json
openspec show task-tracking --type spec --json --requirements
```

读到 `task-tracking` 已有 `Task List Visibility`、`Task Filtering` 和 `Legacy Task PDF Export` 三个 requirement 后，可以做出可审查的判断：本次导出完全复用当前施工任务的筛选与可见性语义，只是在同一份行为合同上新增 CSV 导出并替换掉旧的单页 PDF 导出。因此它是 **Modified `task-tracking`**，不是新建 `export`、`csv` 或 `ui/export-button` capability。

如果项目维护了 capability catalog，这个判断应该在 catalog 和 proposal 中都留下简短证据：

| candidate path | 判断 | 原因 |
|---|---|---|
| `task-tracking` | Modified | 导出继承现有施工任务筛选、可见性与权限语义，并下线旧 PDF 导出 |
| `auth` | verify only | 需核对导出权限校验，但不改变认证合同本身 |
| `data-export` | excluded | 项目当前没有跨模块通用导出引擎；本次不新建近义 path |

这一步不会由嵌套目录自动完成。它的价值是：后面 delta、archive、未来 agent 的阅读范围都会稳定地落在 `task-tracking`，而不是把同一行为散到近义目录。

---

## 第 1 步：`/openspec-propose`，让 change 成形

你在宿主工具里输入：

```text
/openspec-propose add-task-csv-export
```

这一步的本质，不是"让 AI 瞎写四份文档"。

它的本质是：

> **把原本一句模糊需求，展开成一个可实施的 change 工作包。**

执行后，典型目录会变成：

```text
openspec/
├── specs/
│   └── task-tracking/spec.md
└── changes/
    └── add-task-csv-export/
        ├── .openspec.yaml
        ├── proposal.md
        ├── design.md
        ├── tasks.md
        └── specs/
            └── task-tracking/
                └── spec.md
```

这个时刻非常关键。

因为从现在起，"导出施工任务 CSV"不再只是一个聊天里的念头，而是一个有名字、有目录、有内部结构的正式 change。

而 change 一成形，就该轮到 `explore` 上场了——注意，这和第 0 步探代码库现状不同：这里的 `explore` 探的是 **change 内部四份 artifact 是否自洽**。

AI 首次生成的初稿，几乎一定有内部自洽性问题。最常见的：`proposal.md` 的 `Out of Scope` 明明写了"不做 XLSX"，可 `tasks.md` 里却冒出一个"支持 XLSX 导出"的任务——前后打架。这种裂缝很常见，因为 LLM 多份文件连写时接缝处最容易漂移。

这时不要急着 `/openspec-apply-change`，而是对这个 change **反复 `explore`**：在 change 约定的上下文里（proposal + delta spec + design + tasks 这一圈）核对一致性、查矛盾、补漏掉的 scenario。change 把探索框在了一个有限空间里，所以探得比漫无边际地翻代码库准得多。（后面第 2 到第 5 步展示的是已经对齐的初稿；真实场景里这一步往往要反复几轮，第 8 步会集中演示一次。）

---

## 第 2 步：先看 `proposal.md`，这一步在钉边界与影响域

内置 `spec-driven` schema 要求 `proposal.md` 具备 `## Why`、`## What Changes`、`## Capabilities` 和 `## Impact` 四个核心段落（`ChangeParser` 会直接校验 `## Why` 与 `## What Changes` 是否存在）；需要防膨胀时，可以再补一节 `## Out of Scope`：

```markdown
# Proposal: Add Construction Task CSV Export

## Why
Project managers and site supervisors need to export filtered construction task records as CSV for offline reconciliation and client weekly progress reviews.

## What Changes
- Add an Export CSV action on the Construction Tasks page
- Export all construction tasks matching the active filter criteria
- Restrict CSV export to authorized project staff
- **BREAKING**: Remove deprecated single-page PDF snapshot export

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `task-tracking`: Add filtered construction task CSV export, expose export actions on the task list, and remove legacy single-page PDF export

## Impact
- Frontend: `src/tasks/TaskListPage.tsx`, `src/tasks/api/exportTasksCsv.ts`
- Backend: `src/tasks/server/exportTasksCsvHandler.ts`

## Out of Scope
- XLSX export
- Scheduled exports
- Background export jobs
```

这一步最重要的，不是文笔，而是边界和契约：

- `## Why` / `## What Changes` 把立项动机与变更清单钉死
- `## Capabilities` 明确声明这次只改 `task-tracking` 一份 spec（后续生成 specs 时就严格写 `specs/task-tracking/spec.md`）
- `## Out of Scope` 挡住 XLSX、邮件发送、定时生成、大表异步任务这些范围蔓延

如果没有这层边界，一个半天能做完的 CSV 导出，很容易一路膨胀成整套报表中心。

---

## 第 3 步：看 delta spec，这一步在钉"行为变化"

接着看 change 里的：

```text
openspec/changes/add-task-csv-export/specs/task-tracking/spec.md
```

一份能直接通过 `openspec validate --strict` 与 `openspec archive` 的 delta spec 长这样：

```markdown
# Spec Delta: Task Tracking

## ADDED Requirements

### Requirement: Filtered Task CSV Export
The system SHALL allow authorized project staff to export all construction tasks matching the active filter criteria as a CSV file.

#### Scenario: Export filtered tasks
- **WHEN** an authorized project staff user filters the Construction Tasks page by status = Completed and clicks Export CSV
- **THEN** the system downloads a CSV file containing all completed tasks matching that filter

#### Scenario: Export reflects combined filters
- **WHEN** an authorized project staff user applies both date range and status filters and clicks Export CSV
- **THEN** the exported CSV reflects the exact same filter criteria shown in the UI across all matching rows

## MODIFIED Requirements

### Requirement: Task List Visibility
The system SHALL allow authorized project staff to view and export the construction task list.

#### Scenario: Staff user opens task list
- **WHEN** an authenticated project staff user opens the Construction Tasks page
- **THEN** the system displays recent construction tasks for the project
- **AND** CSV export actions are available when the user holds export permission

## REMOVED Requirements

### Requirement: Legacy Task PDF Export
**Reason**: Legacy PDF snapshot only exported the first paginated screen (used twice in the past quarter) and cannot support client spreadsheet reconciliation.
**Migration**: Use Export CSV on the Construction Tasks page, which exports all filtered records.
```

这一步有三个非常关键的格式细节：

1. **改已有 capability 时不写 `## Purpose`**：`task-tracking` 主 spec 已经有 `## Purpose`，delta spec 里只写四类操作段（`ADDED` / `MODIFIED` / `REMOVED` / `RENAMED`）。
2. **`MODIFIED` 必须带完整 requirement 块（含原有 scenario）**：archive 用整块替换语义更新主 spec；漏掉原有 `Staff user opens task list` scenario 会被 `validate` 和 `archive` 的 scenario-loss 闸门直接拦下。
3. **`REMOVED` 的标题必须精确匹配主 spec 基线**：主 spec 里叫 `### Requirement: Legacy Task PDF Export`，delta 里也必须写一模一样的规范化名称，并附上 `**Reason**` 与 `**Migration**`。

### 为什么这里不能只改代码

因为"导出按钮出现"只是界面现象。真正的行为承诺是：

- 哪些角色能导出
- 导出的数据范围是否覆盖筛选后的全部记录
- 旧的单页 PDF 导出是否正式退场

这些外部可观察行为，必须先落到 delta spec 上。

---

## 第 4 步：看 `design.md`，这一步在钉技术方案

接下来，一个典型的 `design.md` 可能是：

```markdown
# Design: Add Construction Task CSV Export

## Context
The Construction Tasks page (`src/tasks/TaskListPage.tsx`) already filters tasks by status and date range via a shared query parameter object.

## Decisions

### Decision: Share the task filter query model
Export will reuse the same filter schema used by the task list API so UI filter state and exported CSV criteria never drift apart.

### Decision: Generate CSV on demand
Initial implementation generates CSV synchronously on demand because project task volume per filter window stays under a few thousand rows.

## Risks / Trade-offs
- [Large project datasets may slow synchronous generation] -> Stream rows from PostgreSQL query cursor and cap initial synchronous path if needed
- [Client progress templates depend on column stability] -> Lock column order with a snapshot test

## File Changes
- `src/tasks/TaskListPage.tsx`
- `src/tasks/api/exportTasksCsv.ts`
- `src/tasks/server/exportTasksCsvHandler.ts`
```

这一步和 spec 的差别一定要抓住：

- **spec** 关心"用户和系统行为怎么变"
- **design** 关心"实现方式怎么选，为什么这么选"

例如“同步流式返回还是投递异步后台任务”不属于用户行为合同，而是技术实现决策，应该放在 `design.md`。

---

## 第 5 步：看 `tasks.md`，这一步在钉实施顺序

内置 `spec-driven` 的 tasks 生成契约要求**每条任务在同一行 checkbox 内写明验证方式（verify）**；只有跨多个实现任务的端到端检查才单独放进末尾的 `Integration Verification`：

```markdown
# Tasks

## 1. Backend export support
- [ ] 1.1 Add export endpoint for filtered construction tasks — verify: endpoint integration test returns a CSV response
- [ ] 1.2 Reuse existing task filter parsing — verify: filter parity test covers status and date range
- [ ] 1.3 Generate CSV response with stable column ordering — verify: snapshot asserts the client report column order

## 2. Frontend integration
- [ ] 2.1 Add Export CSV button on the Construction Tasks page and remove legacy Export PDF button — verify: component test finds Export CSV for authorized staff and confirms Export PDF is absent
- [ ] 2.2 Send current filter state to export endpoint — verify: UI test asserts the request query equals visible filters
- [ ] 2.3 Handle loading and error states — verify: component tests observe disabled/loading and error feedback states

## 3. Integration Verification
- [ ] 3.1 Exercise the complete authorized export flow — verify: `pnpm test:e2e -- --grep "filtered CSV export"` passes
- [ ] 3.2 Exercise the unauthorized flow — verify: e2e request returns 403 and no file downloads
```

如果说 `proposal` 是立项边界、`specs` 是行为边界、`design` 是方案边界，那么 `tasks` 就是施工边界。

> **checkbox 计数规则**：无论是顶层 `- [ ] 1.1` 还是缩进子任务 `  - [ ] 1.1.1`，都会被同一个进度解析器计入任务总数（`list` / `view` / `instructions apply` / `archive` 口径完全一致）。注意这种 `— verify: ...` 是 schema instruction 层面的质量约定，`openspec validate` 只检查 checkbox 格式与编号，不强制硬检 `verify:` 字样。

---

## 第 6 步：到这里，change 其实已经进入"可执行状态"

很多人会误以为：

- `propose` 只是准备工作
- 真正的 change 要到写代码才开始

从 OpenSpec 视角看，当 `proposal / specs / design / tasks` 都成形并通过 `openspec validate add-task-csv-export --strict` 时，这个 change 已经是一个边界清晰的工作单元了。这时才进入：

```text
/openspec-apply-change add-task-csv-export
```

---

## 第 7 步：`/openspec-apply-change`，不是机械执行，而是带反馈的实施

`apply` 最容易被误解成"照着 tasks 机械打勾"。更准确地说，`apply` 是：

> **在已有 change artifact 约束下推进实现，并在代码现实与原方案冲突时修正前面的理解。**

### 一次理想的推进

比如先完成 `1.1` 和 `1.2`，`tasks.md` 同步勾掉：

```markdown
- [x] 1.1 Add export endpoint for filtered construction tasks — verify: endpoint integration test returns a CSV response
- [x] 1.2 Reuse existing task filter parsing — verify: filter parity test covers status and date range
- [ ] 1.3 Generate CSV response with stable column ordering — verify: snapshot asserts the client report column order
```

此时 `tasks.md` 本身就是这次 change 实时可查的实施进度账本。

---

## 第 8 步：现实会反咬设计，这正是 OpenSpec 想处理的事

现在出现一个非常现实的问题——工程师实现到一半时发现：

- 当前施工任务列表接口默认强制带 `LIMIT 20` 分页
- 项目经理给甲方导出的周报必须包含**当前筛选条件下的全部施工任务**
- 如果直接调列表查询函数，只会导出第一页 20 条，严重漏数据

传统做法很容易变成"先偷偷改代码，文档以后再说"。OpenSpec 更鼓励你当场修正 change。

修正前，可以先对这个 change 再跑一轮 `/openspec-explore` 或直接运行 `/openspec-update-change`：确认"分页 vs 全量"在 delta spec、`design.md` 和 `tasks.md` 里分别怎么写的，避免只改一处、另一处还留着旧假设。

### 这时需要改哪些 artifact

1. **改 `design.md`**：明确复用筛选条件解析模型，但后端导出走独立的不分页流式查询路径。
2. **核对 delta spec**：确认 `Filtered Task CSV Export` 已经写明导出 `all construction tasks matching the active filter criteria`；若原先写得含糊，一并澄清。
3. **补 `tasks.md`**：新增一条可验证任务：

```markdown
- [ ] 1.4 Add non-paginated export query path — verify: integration test exports rows beyond the first UI page
```

这就是前面讲过的核心节奏：**Actions, not phases**——规划产物不是写完锁死的历史审批单，而是随实现认知同步演进的活契约。

---

## 第 9 步：实现完成以后，change 现在处于什么状态

当所有实现与集成验证都跑通后，`tasks.md` 全部打勾：

```markdown
## 1. Backend export support
- [x] 1.1 Add export endpoint for filtered construction tasks — verify: endpoint integration test returns a CSV response
- [x] 1.2 Reuse existing task filter parsing — verify: filter parity test covers status and date range
- [x] 1.3 Generate CSV response with stable column ordering — verify: snapshot asserts the client report column order
- [x] 1.4 Add non-paginated export query path — verify: integration test exports rows beyond the first UI page

## 2. Frontend integration
- [x] 2.1 Add Export CSV button on the Construction Tasks page and remove legacy Export PDF button — verify: component test finds Export CSV for authorized staff and confirms Export PDF is absent
- [x] 2.2 Send current filter state to export endpoint — verify: UI test asserts the request query equals visible filters
- [x] 2.3 Handle loading and error states — verify: component tests observe disabled/loading and error feedback states

## 3. Integration Verification
- [x] 3.1 Exercise the complete authorized export flow — verify: `pnpm test:e2e -- --grep "filtered CSV export"` passes
- [x] 3.2 Exercise the unauthorized flow — verify: e2e request returns 403 and no file downloads
```

这时代码与测试都到位了，但还有一个关键收口问题：**这些行为变化什么时候才算正式进入项目基线？**

答案就是：archive。

---

## 第 10 步：`/openspec-archive-change`，不是"收起来"，而是"正式沉淀"

现在执行：

```text
/openspec-archive-change add-task-csv-export
```

宿主 archive 技能在真正执行归档前，会先拉取项目归档输入并核对磁盘与校验状态：

```bash
openspec instructions archive --change add-task-csv-export --json
openspec status --change add-task-csv-export --json
openspec validate add-task-csv-export --type change --strict
```

第一条返回项目的 `context` 与 `operations.archive.guidance`；第三条通过后，CLI 才会把 `task-tracking` 的 delta 合并进主基线。如果团队此前已经用 `/openspec-sync-specs` 把**完全一致**的 delta 提前写进了主 spec，archive 会将其识别为幂等 no-op；只要标题、正文或 scenario 仍有差异，archive 都会先拦住要求核对，绝不静默吞掉差异。

archive 核心做两件事：

1. 按 `ADDED` / `MODIFIED` / `REMOVED` 把 delta spec 合并回 `openspec/specs/task-tracking/spec.md`
2. 把整个 change 目录移入 `openspec/changes/archive/YYYY-MM-DD-add-task-csv-export/`

所以 archive 的真正含义是：**这次 change 结案了，它交付的行为变化已经正式成为系统当前基线的一部分。**

---

## 第 11 步：archive 前后，项目到底发生了什么变化

### archive 之前

```text
openspec/
├── specs/
│   └── task-tracking/spec.md             ← 旧基线（含旧 PDF 导出，无 CSV 导出）
└── changes/
    └── add-task-csv-export/
        └── specs/task-tracking/spec.md   ← 本次 change 的增量 delta
```

### archive 之后

```text
openspec/
├── specs/
│   └── task-tracking/spec.md             ← 新基线（已含 CSV 导出，已移除旧 PDF 导出）
└── changes/
    └── archive/
        └── 2026-11-21-add-task-csv-export/
            ├── .openspec.yaml
            ├── proposal.md
            ├── design.md
            ├── tasks.md
            └── specs/task-tracking/spec.md
```

这里最容易忽略的一点是：**change 没消失，它被完整保存成了工程历史**。半年后接手的同事既能看 `openspec/specs/task-tracking/spec.md` 了解“系统现在承诺什么”，也能翻 `changes/archive/` 查清“当初为什么下线 PDF、为什么后端单独开了不分页查询路径”。

---

## 第 12 步：这个案例里，前面几篇的概念分别落在哪

回看整条流水线，前面各篇的概念都在这里严丝合缝地咬合在了一起：

- **对应 `01` 初级篇**：`/openspec-propose → /openspec-apply-change → /openspec-archive-change` 三步主干跑通闭环。
- **对应 `10` / `11` 中级篇**：`openspec/specs/` 守住当前基线，`changes/` 承载增量工作包，实施中遇到分页陷阱时随时回改 `design.md` 与 `tasks.md`（Actions, not phases）。
- **对应 `20` / `26` 高级篇**：先按行为合同锁定 `task-tracking` capability path，避免新建近义 `export` 目录；`MODIFIED` 完整保留原有 scenario，`REMOVED` 精确对齐基线标题，顺利通过归档机器闸门。
- **对应 `50` Claude Code 实战篇**：`/openspec-*` 只是宿主里的技能触发入口，所有长期资产全部沉淀在仓库的 `openspec/` 目录中。

---

## 这个场景最容易踩的 5 个坑

| 坑 | 表现 | 为什么错 | 正确做法 |
|---|---|---|---|
| **边界不清，标题缺失** | `proposal.md` 只写 `## Intent` / `## Scope`，漏掉 `## Why`、`## What Changes`、`## Capabilities` | 既破坏 `ChangeParser` 与 `spec-driven` 契约，又容易一路膨胀出 XLSX、邮件、定时任务 | 保留 `Why` / `What Changes` / `Capabilities` / `Impact` 四大标准段，并用 `Out of Scope` 钉死不做项 |
| **`REMOVED` 标题与主 spec 对不上** | 主 spec 叫 `Legacy Task PDF Export`，delta 里随手写成 `PDF Export (deprecated)` | `archive` 按精确规范化名称匹配待删 requirement，名字对不上会直接拒绝归档 | 先用 `openspec show <spec> --type spec` 查准原名，原样写入 `### Requirement:` |
| **delta spec 写成全量或乱加 `## Purpose`** | 把整份 `task-tracking` 重抄一遍，或在已有 capability 的 delta 里加 `## Purpose` | 审查者看不出增量变化，且修改既有 spec 时的 `## Purpose` 会被报未应用内容警告 | 只写 `ADDED` / `MODIFIED` / `REMOVED` / `RENAMED`（仅新建 capability 才写 `## Purpose`） |
| **发现问题只改代码不改 artifact** | 实现时发现分页漏数据，改了后端接口却不更新 `design.md` 和 `tasks.md` | 代码与设计记录脱节，后人复盘时被旧文档误导 | 用 `/openspec-update-change` 或手改同步修正 `design.md` / `tasks.md` |
| **代码合入后忘记 archive** | 功能上线了，change 一直挂在 `changes/` 里不归档 | `openspec/specs/` 基线停留在旧状态，下一个改 `task-tracking` 的人拿到过时基线 | 验证通过后立即执行 `/openspec-archive-change` 闭环 |

### 典型正反对照：立项边界失控 vs 受控收敛

**失控做法**：

```text
用户：给施工任务页加个导出功能
AI：好的，我来做 CSV、XLSX、PDF 三种格式，再顺手加上邮件发送和每周定时导出
→ 第一周纠结排版，第二周卡在邮件服务配置，第三周异步任务撞上权限模型，一个月还没上线
```

**OpenSpec 受控做法**：

```markdown
# Proposal: Add Construction Task CSV Export

## Why
Project managers need filtered construction task CSV exports for weekly client progress reviews.

## What Changes
- Add on-demand CSV export for currently filtered construction tasks
- Restrict export to authorized project staff

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `task-tracking`: Add on-demand filtered CSV export for authorized project staff

## Impact
- `src/tasks/TaskListPage.tsx`, `src/tasks/server/exportTasksCsvHandler.ts`

## Out of Scope
- XLSX formats (future change)
- Email delivery (future change)
- Scheduled background exports (future change)
```

先把 CSV 导出在几天内做完并 archive 成正式基线，后续格式或异步能力再各自开独立的小 change 推进。

---

## 最该带走的 9 句话

1. 一个 change 的起点不是写代码，而是先把模糊需求收束成边界清晰的工作包。
2. `proposal.md` 守住 `Why`、`What Changes`、`Capabilities`、`Impact` 四段骨架，并用 `Out of Scope` 挡住范围蔓延。
3. 动手写 delta 前先核对已有 capability path，能复用 `task-tracking` 就绝不随手新建近义 `export` 目录。
4. delta spec 只表达行为合同的增量变化，`MODIFIED` 带全量块、`REMOVED` 精确对齐主 spec 标题。
5. `design.md` 承载同步/异步、分页/流式等技术选型，不要把实现手段塞进 spec。
6. `tasks.md` 让每条任务自带验证标准，把“说得清楚”真正变成“做得下去”。
7. 初稿接缝处最容易出幻觉——进入 `apply` 前先用 `explore` 核对四份 artifact 的内部自洽。
8. `apply` 不是盲目打勾，代码现实反咬原方案时要当场回修 `design` / `specs` / `tasks`。
9. `archive` 不是把旧文档塞进抽屉，而是通过机器校验闸门把本次增量正式合入系统基线。
