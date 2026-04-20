# 06 · 案例：从一个真实 change 走完整条主线

> 前面的几篇已经把概念一层层拆开了。
> 这一篇不再单独讲概念，而是用一个完整案例，把 `propose → apply → archive` 整条线真正走一遍。

---

## 开始前的准备：这个案例假设你已经...

**必须先读过的**：
- [01-初级-先把-openspec-用起来.md](01-初级-先把-openspec-用起来.md) - 知道三个基本命令
- [02-中级-把核心概念真正串起来.md](02-中级-把核心概念真正串起来.md) - 理解 specs/changes/artifact/delta spec

**如果没读过上面两篇**：
- 你会不理解"为什么要有这么多文件"
- 你会不理解"delta spec 是什么"
- 你会不理解"archive 在干什么"

**建议**：如果你是直接跳到这篇的，先回去读 01 和 02，会顺很多。

---

## 这一篇解决什么问题

很多人单独看概念时会觉得：

- 我好像知道 `specs` 是什么了
- 我也知道 `changes` 是什么了
- `proposal / specs / design / tasks` 也都认识了

但一旦回到真实项目，脑子里还是会冒出这些问题：

- 一个 change 到底是从哪一步开始“成形”的？
- `proposal`、delta spec、`design`、`tasks` 之间，到底是先后关系，还是互相修订关系？
- `apply` 时，到底是在“执行任务”，还是在“继续完善 change”？
- `archive` 到底只是挪文件，还是一种“正式沉淀”？

这篇就是把这些问题放到一个真实感足够强的案例里，一次讲透。

---

## 这次案例选什么

我们不用特别大的系统，就用一个非常典型、但又足够有现实感的例子：

> **给一个已有 Web 应用新增“导出订单 CSV”能力。**

为什么选这个例子？

因为它刚好具备 OpenSpec 很典型的几种特征：

- 不是从零做系统，而是在已有系统上增量开发
- 会涉及已有行为的修改，而不是纯新增页面
- 会同时碰到产品意图、行为规格、技术方案和实施拆解
- 很适合展示 delta spec 的价值

---

## 先给出项目背景

假设项目目录是这样：

```text
order-hub/
├── src/
│   ├── orders/
│   ├── auth/
│   └── ui/
├── tests/
└── openspec/
    ├── specs/
    │   ├── orders/
    │   │   └── spec.md
    │   └── auth/
    │       └── spec.md
    ├── changes/
    └── config.yaml
```

而当前 `openspec/specs/orders/spec.md` 里，已经存在一些正式规格，比如：

```markdown
# Orders Specification

## Requirements

### Requirement: Order List Visibility
The system SHALL allow authorized staff users to view the order list.

#### Scenario: Staff user opens order list
- GIVEN an authenticated staff user
- WHEN the user opens the Orders page
- THEN the system displays recent orders

### Requirement: Order Filtering
The system SHALL allow filtering by date range and status.

#### Scenario: Filter orders by status
- GIVEN a staff user on the Orders page
- WHEN the user selects status = Paid
- THEN only paid orders are shown
```

注意这里的意思是：

- 这些不是“未来想法”
- 而是当前项目正式承认的行为基线

这就是后面所有 change 的出发点。

---

## 第 0 步：为什么这件事值得开一个 change

产品同学提了一个需求：

> 客服团队希望把筛选后的订单导出成 CSV，方便线下核对和发给财务。

这时最容易犯的错误，是直接让 AI 去改代码：

```text
“帮我给订单页加一个导出按钮，并导出 CSV。” 
```

OpenSpec 的思路不是这样。

它会先把这件事当成一个 **change**：

- 这不是“随手改一行代码”
- 而是一次有边界的能力变更
- 需要能被表达、被讨论、被实现、被沉淀

所以第一步不是改代码，而是发起 change。

---

## 第 1 步：`/opsx:propose`，让 change 成形

你在宿主工具里输入：

```text
/opsx:propose add-order-csv-export
```

这一步的本质，不是“让 AI 瞎写四份文档”。

它的本质是：

> **把原本一句模糊需求，展开成一个可实施的 change 工作包。**

执行后，典型目录会变成：

```text
openspec/
├── specs/
│   └── orders/spec.md
└── changes/
    └── add-order-csv-export/
        ├── proposal.md
        ├── design.md
        ├── tasks.md
        └── specs/
            └── orders/
                └── spec.md
```

这个时刻非常关键。

因为从现在起，“导出 CSV”不再只是一个聊天里的念头，而是一个有名字、有目录、有内部结构的正式 change。

---

## 第 2 步：先看 `proposal.md`，这一步在钉边界

一个合理的 `proposal.md` 可能会长这样：

```markdown
# Proposal: Add Order CSV Export

## Intent
Support customer service and finance workflows by allowing staff users
to export filtered order data as CSV.

## Scope
- Add an Export CSV action on the Orders page
- Export only the currently filtered result set
- Restrict export to authorized staff users

## Out of Scope
- XLSX export
- Scheduled exports
- Background export jobs

## Approach
Generate CSV on demand from the filtered order query and return it as a file download.
```

这一步最重要的，不是文笔，而是边界。

### `proposal` 在这里做了什么

- 把“为什么要做”讲清楚
- 把“做到哪儿为止”讲清楚
- 把“这次不做什么”讲清楚

这会直接影响后面所有东西。

### 一个特别典型的价值

如果没有 `Out of Scope`，后面很容易一路膨胀成：

- CSV 导出
- XLSX 导出
- 邮件发送
- 定时生成
- 大数据量异步导出

而这已经不是同一个 change 了。

所以 `proposal` 的真正价值，是控制 change 的身份和边界。

---

## 第 3 步：看 delta spec，这一步在钉“行为变化”

接着看 change 里的：

```text
openspec/changes/add-order-csv-export/specs/orders/spec.md
```

一个合理的 delta spec 可能是：

```markdown
# Delta for Orders

## ADDED Requirements

### Requirement: Order CSV Export
The system SHALL allow authorized staff users to export the currently filtered order list as a CSV file.

#### Scenario: Export filtered orders
- GIVEN an authenticated staff user viewing the Orders page
- AND a filter is applied for status = Paid
- WHEN the user clicks Export CSV
- THEN the system downloads a CSV file containing only the filtered orders

#### Scenario: Export uses current filters
- GIVEN an authenticated staff user viewing the Orders page
- AND filters are applied for date range and status
- WHEN the user exports orders
- THEN the exported CSV reflects the same filter criteria shown in the UI

## MODIFIED Requirements

### Requirement: Order List Visibility
The system SHALL allow authorized staff users to view and export the order list.

#### Scenario: Staff user opens order list
- GIVEN an authenticated staff user
- WHEN the user opens the Orders page
- THEN the system displays recent orders
- AND export actions are available when the user has export permission
```

这一步的关键是：

- `proposal` 讲的是变更意图
- delta spec 讲的是行为合同

### 为什么这里不用只改代码

因为“导出按钮出现”只是界面现象。

真正的行为承诺其实是：

- 哪些人能导出
- 导出的数据范围是什么
- 是否必须和当前过滤条件一致
- UI 上何时可见、何时不可见

这些才是系统行为变化。

所以 OpenSpec 要求这一步先落到 delta spec 上。

---

## 第 4 步：看 `design.md`，这一步在钉技术方案

接下来，一个典型的 `design.md` 可能是：

```markdown
# Design: Add Order CSV Export

## Technical Approach
Add an Export CSV action to the Orders page.
Reuse the existing order filter parameters and call a new backend export endpoint.

## Decisions

### Decision: Reuse current filter query
Export should use the same filter object already used by the order list API
to avoid divergence between UI results and exported content.

### Decision: Generate CSV on demand
Initial implementation will generate CSV synchronously because expected export
size is small for the current staff workflow.

## Risks
- If the result set becomes too large, synchronous export may become slow
- Column formatting must remain stable for finance workflows

## File Changes
- `src/orders/OrdersPage.tsx`
- `src/orders/api/exportOrdersCsv.ts`
- `src/orders/server/exportOrdersCsvHandler.ts`
```

这一步和 spec 的差别一定要抓住：

- spec 关心“用户和系统行为怎么变”
- design 关心“实现方式怎么选，为什么这么选”

### 一个很容易混淆的例子

“导出使用同步方式还是异步 job” 不应该先写进 spec。

因为这不是用户行为合同，而是技术实现决策。

它应该在 `design.md` 里出现。

---

## 第 5 步：看 `tasks.md`，这一步在钉实施顺序

然后一个合理的 `tasks.md` 可能是：

```markdown
# Tasks

## 1. Backend export support
- [ ] 1.1 Add export endpoint for filtered orders
- [ ] 1.2 Reuse existing order filter parsing
- [ ] 1.3 Generate CSV response with stable column ordering

## 2. Frontend integration
- [ ] 2.1 Add Export CSV button on the Orders page
- [ ] 2.2 Send current filter state to export endpoint
- [ ] 2.3 Handle loading and error states

## 3. Verification
- [ ] 3.1 Add tests for exported filter correctness
- [ ] 3.2 Verify unauthorized users cannot export
- [ ] 3.3 Verify CSV columns match finance expectations
```

这一步的作用非常实际：

- 让 change 从“说得清楚”变成“做得下去”
- 让 `/opsx:apply` 有东西可以跟着推进

如果说：

- `proposal` 是立项边界
- `specs` 是行为边界
- `design` 是方案边界

那么：

- `tasks` 就是施工边界

---

## 第 6 步：到这里，change 其实已经进入“可执行状态”

很多人会误以为：

- `propose` 只是准备工作
- 真正的 change 要到写代码才开始

这其实不对。

从 OpenSpec 视角看，到 `proposal/specs/design/tasks` 都基本成形时，这个 change 已经是一个正式工作单元了。

它已经具备：

- 明确目标
- 明确行为变化
- 明确技术方案
- 明确实施步骤

这时才进入：

```text
/opsx:apply add-order-csv-export
```

---

## 第 7 步：`/opsx:apply`，不是机械执行，而是带反馈的实施

`apply` 最容易被误解成：

- “照着 tasks 打勾”

它当然有这一面，但不止这一面。

更准确地说，`apply` 是：

> **在已有 change 工件约束下，推进实现，并在必要时修正前面的理解。**

### 一次理想的推进

比如先完成：

- `1.1 Add export endpoint`
- `1.2 Reuse existing order filter parsing`

然后把 task 勾掉：

```markdown
- [x] 1.1 Add export endpoint for filtered orders
- [x] 1.2 Reuse existing order filter parsing
- [ ] 1.3 Generate CSV response with stable column ordering
```

这时 `tasks.md` 本身就成了 change 的实施状态记录。

---

## 第 8 步：现实会反咬设计，这正是 OpenSpec 想处理的事

现在出现一个非常现实的问题：

工程师实现到一半时发现：

- 当前订单列表接口只返回分页结果
- 财务要求导出“当前过滤条件下的全部结果”
- 如果直接复用现有列表接口，会只导出当前页，不符合预期

这时怎么办？

传统做法很容易变成：

- 先偷偷改代码
- 文档以后再说

OpenSpec 更鼓励你当场修正 change。

### 这时需要改哪些工件

#### 1. 改 `design.md`

把原来“复用当前列表接口”的设计，修正成：

- 复用过滤模型
- 但后端单独提供完整结果导出逻辑

#### 2. 如果行为承诺受影响，改 delta spec

比如你发现：

- 导出不再是“当前页结果”
- 而是“当前过滤条件下的全部结果”

那么 spec 必须跟着澄清。

#### 3. 改 `tasks.md`

新增一个任务，比如：

```markdown
- [ ] 1.4 Add non-paginated export query path
```

### 这一步非常能体现 OpenSpec 的设计思想

因为它在承认：

- 你一开始不会把所有东西都想对
- 代码现实会反过来修正规划
- 规划工件不是一次性写完的 PPT，而是活文档

这就是前面讲过的：

> **Actions, not phases**

---

## 第 9 步：实现完成以后，change 现在处于什么状态

假设最后代码和任务都做完了，目录和状态大概是这样：

```text
openspec/changes/add-order-csv-export/
├── proposal.md
├── design.md
├── tasks.md
└── specs/
    └── orders/spec.md
```

而 `tasks.md` 已经变成：

```markdown
## 1. Backend export support
- [x] 1.1 Add export endpoint for filtered orders
- [x] 1.2 Reuse existing order filter parsing
- [x] 1.3 Generate CSV response with stable column ordering
- [x] 1.4 Add non-paginated export query path

## 2. Frontend integration
- [x] 2.1 Add Export CSV button on the Orders page
- [x] 2.2 Send current filter state to export endpoint
- [x] 2.3 Handle loading and error states

## 3. Verification
- [x] 3.1 Add tests for exported filter correctness
- [x] 3.2 Verify unauthorized users cannot export
- [x] 3.3 Verify CSV columns match finance expectations
```

这时从 change 管理角度说，它已经准备进入 closing 阶段。

但这里还有最后一个极其关键的问题：

- 这些变化什么时候才算正式进入项目基线？

答案就是：archive。

---

## 第 10 步：`/opsx:archive`，不是“收起来”，而是“正式沉淀”

现在执行：

```text
/opsx:archive add-order-csv-export
```

这一步最核心的事，不是挪目录，而是两件事：

1. 把 delta spec merge 回主 `openspec/specs/orders/spec.md`
2. 把 change 文件夹移入 `openspec/changes/archive/`

所以 archive 的真正含义是：

> **这次变更结束了，而且其结果现在已经成为正式基线的一部分。**

---

## 第 11 步：archive 前后，项目到底发生了什么变化

### archive 之前

```text
openspec/
├── specs/
│   └── orders/spec.md              ← 旧基线
└── changes/
    └── add-order-csv-export/
        └── specs/orders/spec.md    ← 本次 change 的 delta
```

### archive 之后

```text
openspec/
├── specs/
│   └── orders/spec.md              ← 已包含 CSV 导出能力
└── changes/
    └── archive/
        └── 2026-04-20-add-order-csv-export/
            ├── proposal.md
            ├── design.md
            ├── tasks.md
            └── specs/orders/spec.md
```

这里最容易忽略的一点是：

- change 没消失
- 它被保存成历史

所以以后你不仅能看到“系统现在怎么工作”，还能回看：

- 当时为什么加这个功能
- 当时怎么做的技术取舍
- 当时分了哪些任务

这就是 OpenSpec 把“过程”也保留下来的价值。

---

## 第 12 步：这个案例里，前面几篇的概念分别落在哪

为了帮助你把前面几篇串起来，我们现在回看这次案例。

### 对应 `01` 初级篇

你已经看到了最小主线：

```text
/opsx:propose → /opsx:apply → /opsx:archive
```

### 对应 `02` 中级篇

你已经看到了：

- `openspec/specs/` 是当前正式基线
- `changes/` 是变更工作区
- `artifact` 是 change 内部的四类工件
- delta spec 是“增量变化”表达层

### 对应 `03` 高级边界篇

虽然这次案例没重点展开，但它背后默认已经在工作：

- `config.yaml` 可能在注入项目 context
- schema 在决定这次 change 的 artifact 结构
- `.openspec.yaml` 可能记录 change 绑定的 schema

### 对应 `04` Cline 专章

如果你是在 Cline 中敲命令，那么：

- `.cline/` 和 `.clinerules/` 是入口层
- 真正的项目事实仍然沉淀在 `openspec/`

### 对应 `05` 生命周期思想篇

这整个案例本身就在体现那套思想：

- 先围绕 change 组织工作
- 在正式基线上做增量变化
- 用多层工件拆开不同类型的信息
- 在实现过程中允许回改前面的工件
- 最后通过 archive 把变化沉淀回正式基线

---

## 一个“反例”会更能看出 OpenSpec 的价值

我们再看同一个需求，如果不用 OpenSpec，常见会怎么发生。

### 常见无结构做法

```text
1. 产品说：加个导出吧
2. 工程师说：好，我先写
3. AI/工程师直接开始改代码
4. 做到一半发现过滤条件语义没想清
5. 又补需求，又改代码
6. 最后代码能跑，但没人说得清行为边界
7. 三周后另一个人再加 XLSX，完全不知道之前的设计考虑
```

### OpenSpec 做法

```text
1. 先开 change
2. 先把 intent / scope / behavior / design / tasks 分层写出来
3. 再开始实现
4. 发现理解有误时，回改工件
5. 完成后 merge 回正式规格
6. 把整次 change 保留为历史
```

两者最大的差别，不是“文档多不多”。

而是：

- 前者只有代码结果
- 后者同时留下行为结果、设计理由和变更轨迹

---

## 这个场景最容易踩的 5 个坑

| 坑 | 表现 | 为什么错 | 正确做法 |
|-----|------|---------|---------|
| **边界不清** | proposal 里写”优化导出功能”，但没说清楚做到哪里 | 后面会不断膨胀，从 CSV 变成 XLSX、邮件、定时任务 | 明确写 Out of Scope |
| **delta spec 写成全量** | 把整个订单系统的所有能力都重写一遍 | 审查者看不出这次改了什么，并行开发容易冲突 | 只写 ADDED/MODIFIED/REMOVED |
| **design 和 spec 混淆** | 把”用同步方式导出”写进 spec | 这是实现决策，不是用户行为合同 | 实现方式放 design，行为承诺放 spec |
| **发现问题不回改** | 实现时发现设计有误，但只改代码不改文档 | 文档和代码脱节，后人看不懂当时的真实决策 | 回头修正 design/spec，保持一致 |
| **忘记 archive** | 代码写完就算完成，不执行 archive | specs/ 基线没更新，下一个 change 没有正确的参考基线 | 必须 archive 才算闭环 |

### 典型踩坑案例：边界失控

**错误做法**：
```text
用户：给订单页加个导出功能
AI：好的，我来做 CSV、XLSX、PDF 三种格式，还加上邮件发送和定时导出
```

结果：
- 第一周还在纠结 PDF 格式
- 第二周发现邮件服务没配置
- 第三周定时任务和现有架构冲突
- 一个月后还没上线

**OpenSpec 做法**：
```markdown
# Proposal: Add Order CSV Export

## Scope
- CSV export only
- On-demand download
- Current filter results

## Out of Scope
- XLSX/PDF formats (future change)
- Email delivery (future change)
- Scheduled exports (future change)
```

结果：
- 第一周完成 CSV 导出
- archive 后立即可用
- 后续再开新 change 加其他格式

---

## 这篇案例最该带走的 8 句话

1. 一个 change 的起点不是代码，而是让变更先成形
2. `proposal` 的核心价值是控制边界
3. delta spec 的核心价值是表达行为变化
4. `design` 讲的是技术选型，不是行为合同
5. `tasks` 让 change 从”说得清楚”进入”做得下去”
6. `apply` 不是机械执行，而是带反馈的实施
7. `archive` 不是收纳动作，而是正式沉淀动作
8. OpenSpec 真正管理的是”基线 + 增量变化 + 历史闭环”

---

## 下一步怎么读

如果你读完这篇之后，感觉整条主线终于立住了，那么接下来有两种方向：

### 方向 A：回去补厚理解

回看这些篇章会顺很多：

- [02-中级-把核心概念真正串起来.md](02-中级-把核心概念真正串起来.md)
- [05-高级-openspec-的软件开发生命周期思想.md](05-高级-openspec-的软件开发生命周期思想.md)

### 方向 B：继续往机器层走

如果你已经想研究：

- 宿主 agent 到底怎么知道该生成哪个 artifact
- `openspec instructions --json` 究竟提供什么
- Cline/Claude 为什么既有 skill 又有 command

再看：

- [90-附录-给机器看的-agent-协议.md](90-附录-给机器看的-agent-协议.md)
