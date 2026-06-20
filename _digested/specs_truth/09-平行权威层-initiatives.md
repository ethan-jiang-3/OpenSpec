# 平行权威层：`initiatives/` 是什么、怎么管

## 一句话

`openspec/initiatives/` 是和 `specs/` 平行的**协调/方向权威层**，管跨 repo、跨团队、跨周期的工作。它**不是** `specs/` 的替代或上级——两者各管一摊：**`specs/` = 一个 repo 的capability 现状；`initiatives/` = 跨多方的方向协调**。别把它并进 specs，要让 conventions 诚实承认它。

## initiatives/ 是什么

`openspec/initiatives/<name>/` 通常含 `direction.md`、`decisions.md`、`roadmap.md`、`tasks.md`、以及一组 `work-items/<n>-*/`（每个有 `plan.md`/`tasks.md`/`evidence.md`）。多个 active change 会引用某个 initiative 作为"产品权威"。

它解决的是 `changes/` 解决不了的问题：**跨 repo、跨团队、长周期的方向协调**。单个 `change` 是 repo-local 的一个能力切片；当一条方向需要动多个 repo、或跨团队对齐很久才能落地时，就需要一个比 change 更持久的协调对象——这就是 initiative。

## 权威边界（最容易混的一点）

| | `openspec/specs/` | `openspec/initiatives/` |
|---|---|---|
| 管什么 | **一个 repo 的capability 现状**（事实层） | **跨多方的方向协调**（方向层） |
| 时态 | 现在是什么 | 要往哪走 |
| 谁读它当真相 | agent 读它判断"代码现在怎么跑" | 人/agent 读它判断"整体往哪走、各 repo 怎么配合" |
| 改它的方式 | delta + `archive`（`01`） | 直接编辑 direction/work-items（它不是 spec-driven delta 体系） |

**关键：它们是平行层，不是上下级。** initiative 不"覆盖"specs，specs 也不"实现"initiative——而是：一个 initiative 协调的方向，会**分解成多个 repo 各自的 change**，每个 change 最终 archive 进各自 repo 的 `specs/`。

## 何时用 initiative，何时用 change

- **用 change**：工作是一个 repo 内的capability 改动（加/改/删某个 capability 的行为）。走 explore→propose→apply→archive。
- **用 initiative**：工作跨多个 repo / 跨团队 / 周期长，需要一份持久的方向 + 工作项分解来协调。然后把每个 repo 的落地仍写成各自的 change。

判断捷径：**如果这事一个 repo、一次 archive 能收口 → change；如果它要协调多方、分很久、动多个 repo → initiative，再分解成 change。**

本 repo 实例：`openspec/initiatives/context-store-and-initiatives/` 就是这种跨层方向；它把 `workspace-*` 系列 change 标记为 "deferred"（方向已迁到 initiative），让 active `changes/` 不再背这些僵尸（`02` 信号 ④ 的根因之一）。

## 让 conventions 诚实承认这层（信号 ⑤ 的修法）

`02` 信号 ⑤ 的根因：`openspec-conventions` 的 "Project Structure" **没提 `initiatives/`**，所以 agent 看到两棵树不知道边界。**修法不是把 initiatives 并进 specs**（那会压垮有意的分层），是让 conventions 承认它：

```bash
openspec new change document-initiatives-layer-in-conventions
# specs/openspec-conventions/spec.md → ## MODIFIED：Project Structure 加上 initiatives/ 子树，
#   并说明：initiatives/ 是协调/方向层，不是capability 真相；capability 真相仍在 specs/。
openspec archive document-initiatives-layer-in-conventions -y
```

改完后 agent 就知道：`specs/` 读现状、`initiatives/` 读方向，两者不冲突。

## agent 该怎么读这两棵树

给 agent 的规则（值得写进 `AGENTS.md` / conventions）：

- 想知道"代码现在怎么跑" → 读 `specs/`（事实）。
- 想知道"整体往哪走、为什么这样定" → 读 `initiatives/`（方向）。
- 看到 active `change` 引用某个 initiative → 那个 change 是该 initiative 落到**本 repo** 的切片；initiative 是它的方向出处，不是它的实现规范。
- **别**把 initiative 的 direction 文本当成 spec 去断言代码行为——它是方向，不是现状。

## 守住的边界

`initiatives/` 的存在是 OpenSpec 把"capability 现状"和"方向协调"分层的设计：现状层（specs）走 spec-driven 的受控流水线，方向层（initiatives）走更自由的文档协调。守住这条边界：**别让 initiatives 污染 specs 的事实性**（direction 不是现状），也别让 specs 的窄视角吞掉 initiative 的协调职责（一个 repo 的 spec 管不了跨 repo 方向）。让 conventions 说清两者的角色，agent 就不会在两棵树之间迷路。

## 继续阅读

- 信号 ⑤（平行权威层未对齐）的实证：`02-漂移与噪声-为什么主specs会失真.md`
- 修复原语（更新 conventions spec）：`03-手段清单-到底有多少种修法.md`
- 本 repo 的 initiatives 走查：`05-走查-把手段用在自家repo上.md`（项 6）
