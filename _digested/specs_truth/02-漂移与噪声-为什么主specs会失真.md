# 漂移与噪声：为什么主 specs 会失真

## 主轴（接 `01` 的引擎）

> **确定性 archive 与 agent sync 都可能更新 main specs；requirement 无 ID（身份=标题），且没有工具持续做 code↔spec 语义对账 ⇒ 漂移仍是默认状态，长期对齐靠人 + 纪律 + 巡检。**

`01` 讲了前两个支柱（specs 怎么产生、身份是什么）。本章讲**第三个支柱——为什么"没有工具持续对账"**，以及这种失真长期下来长什么样（噪声）。

## 为什么 OpenSpec 故意不给你一个 `reconcile`（先讲设计视角）

读到这里你大概会想：那为什么没有个 `openspec reconcile` / `openspec audit` 自动把 specs 对齐？

**这是有意的，不是疏漏。** "这条 spec 还真不真"本质要**读代码 + 判断意图**——这是人/agent 的活，没有唯一确定答案。要是工具硬编码一个判断标准去自动改你的 specs，等于让它在背后偷偷改写你的"事实层"，那比漂移更危险。OpenSpec 的取舍是：**确定的事（解析、结构校验、archive 合并）交给代码；需要判断的事（spec 是否如实反映代码、要不要删个废弃方向）交还给人。**

代价就是一道**常态巡检义务**：specs 的长期质量不是某个命令的责任，是你的。下面三道缺口就是这道义务的具体来源。

## 三道结构性缺口（漂移为什么是默认）

### 缺口一：`validate` 不做跨文件对账——它是 CLI 结构 linter，不是 slash，也抓不出漂移

先把 `validate` 的身份钉死（很多人这里就误会了）：

- **它是 `openspec` CLI 命令**（和 `archive` 同列），**不是 `/opsx:` slash 技能**（没有 `/opsx:validate`）。
- 它是**结构 linter**：`Validator.validateChangeDeltaSpecs()` 只读 `changeDir/specs/` 下的 delta 文件，检查它们**自身**的结构（段头齐不齐、有没有 SHALL/MUST、有没有 scenario、段内重不重名）。默认（normal）模式下，缺失 SHALL/MUST 只是 guidance（WARNING），`--strict` 才强制（v1.8.0）。它**从不打开 `openspec/specs/<cap>/spec.md`**。

后果：一个 `MODIFIED` 指向一个根本不存在于主 spec 的 requirement、一个 `REMOVED` 删一个早已不在的东西、一个 `RENAMED` 改一个不存在的标题——**依旧能通过 `validate`**。这些只有等到 `archive` 时撞上，用一句 `not found` 暴露（见 `04`）。

v1.8.0 补了其中一个缺口：当 `validate <change>` 能拿到 main specs 时，会前置检测 **MODIFIED 省略了主 spec 仍有的 scenario**——这正是 archive 拒绝的那种 loss，现在在 authoring 阶段就失败，错误信息会指名要抄回的 scenarios。其余匹配类缺口（指向不存在的 requirement、改名不存在标题等）仍是 archive 时发现。（`validate` 的完整选项/CI 用途/与 archive 的冗余关系，见 `06` 的 validate 命令参考。）

### 缺口二：匹配只在 archive 那一刻、且只看这一次

delta 和主 spec 的匹配发生在 `buildUpdatedSpec` 里，**只在 `archive` 这个 change 的瞬间**。它不会回头审计"历史上所有 archive 加在一起，和当前 specs 是否自洽"。一次 archive 成功了，就写入真相，从此被盲信。

### 缺口三：没有回溯 / 修复 / 审计命令

`openspec` 不提供 `log`/`blame`/`history`/`trace`（回溯）、`reconcile`/`repair`/`regenerate`（修复）、`prune`/`clean`（裁剪）、或全局一致性审计。`apply`/`drift` 类命令也不存在（`/opsx:sync`、`/opsx:verify` 是 LLM skill，不是确定命令）。所以"specs 是否还对得上代码"是**人的巡检责任**，不是工具责任（巡检怎么做见 `03` 的巡检元实践）。

> 三道缺口合起来一句：**OpenSpec 用 archive 把"写 specs"这一刻管住了，但写下去之后，再没有任何东西盯着它对不对。**

## 噪声长什么样（六类，附本 repo 实证）

> 先说清结构关系：OpenSpec 是**两层「以名字为身份」模型**（见 `01`）——**①（capability path 失配）和 ⑥（requirement 标题失配）是同一个 name-as-identity 脆弱在两层的表现**；⑥ 是它最纯的形态（ur-cause，机理层），①③⑤ 是可观察的症状。

下面每类都给本 repo 里能直接指认的真实例子（写作时快照，用来对号入座，不是说必须处理）。

### ① 悬空 delta 目标：active change 指向不存在的 capability

一个 change 的 `specs/<capability-path>/spec.md` 指向一个 `openspec/specs/` 里**根本没有**的 capability path——也就是 **capability 身份（=相对路径）对不上**：设计了没建、path 被改名（capability 无 rename 操作，改名=裸搬目录）、或早删了。

本 repo 实例（目标在 `specs/` 中均不存在）：

| change | delta 指向 |
|--------|-----------|
| `add-change-stacking-awareness` | `change-stacking-workflow/` |
| `add-global-install-scope` | `installation-scope/` |
| `add-qa-smoke-harness` | `developer-qa-workflow/` |
| `unify-template-generation-pipeline` | `template-artifact-pipeline/` |

噪声在哪：这些 change 永远 archive 不干净，却长期挂 active，对 agent 释放"这里有个进行中方向"的假信号。

### ② 有代码无 spec：发运了 capability，但 specs 沉默（反向漂移）

代码里已有一等公民 capability，`openspec/specs/` 里却没有对应 spec——specs 漏报现状。

本 repo 实例：`src/commands/context-store.ts`、`src/commands/initiative.ts` 都有 CLI 表面 + JSON 契约，却**没有**对应 capability spec。（`src/core/profile-sync-drift.ts` 是内部引擎，按 conventions 属 design/tasks、本就不该单独成 spec——区分"该补"和"不该有"是这类的判断难点。）

噪声在哪：agent 在 specs 里找不到这些capability 的契约，要么瞎猜要么读源码。

### ③ 冻结 spec：spec 停在旧代码上

主 spec 描述的行为和当前代码不一致；archive 之后没人维护，spec 冻结在写入那一刻。

本 repo 实例：`openspec/specs/cli-view/spec.md` 写错误串是 `"✗ No openspec directory found"`，但 `src/core/view.ts` 实际是 `'No openspec directory found'`（没有 `✗`）。差一个字符，足够让"照 spec 写的断言"失败。

噪声在哪：spec 自称事实却和代码相悖，agent 拿它当现状就基于错误前提做 proposed change。

### ④ 废弃但仍 active 的 change：噪音文件夹

change 已废弃/被 supersede/纯 proposal 没动，却还待在 active `changes/`。未声明 marker 的共同特征是 `openspec validate` 报 `No deltas found`（只有 `proposal.md`，没 `specs/` delta）。v1.7.0 的例外是有意没有 spec-level 行为变化的工作：`.openspec.yaml` 写 `skip_specs: true` 后，validate 接受它、status 显示 specs skipped；它不能与任何 delta spec 文件共存。

本 repo 实例：`add-artifact-regeneration-support`、`schema-alias-support`（纯 proposal、代码无实现）；`workspace-agent-guidance` / `workspace-apply-repo-slice` / `workspace-verify-and-archive` / `workspace-reimplementation-roadmap`（proposal 自带 "deferred" 说明，实质已搁置）。

噪声在哪：让 `openspec list` / `validate --all` 充满失败项，agent 以为有一堆"进行中但有问题"的工作，其实是早放弃的方向。

### ⑤ 平行权威层未对齐：specs 之外另有一套真相

`openspec/initiatives/` 是和 `specs/` 平行的结构（`direction.md`、`work-items/` 等），多个 active change 把它当"产品权威"；但 `openspec-conventions` spec 的 "Project Structure" **根本没提 `initiatives/`**。

噪声在哪：两棵树各说各话，没人告诉 agent 这俩的边界；conventions spec 自己也过时了。

> 这一类**不一定要消除**：`initiatives/` 可能是有意的协调层。真正的修法是让 conventions 承认并说清这层角色，而不是把 initiatives 并进 specs。（initiatives 概念已废弃。）

### ⑥ 身份脆弱性：标题改动，delta 默默失配（①③⑤ 的 ur-cause）

这是 `01` 身份模型（无 ID、身份=标题、仅 trim、大小写敏感）的直接后果，最阴险——**它不报错，只在下一次 archive 时以一句 `not found` 爆雷**。

本 repo 实例：`simplify-skill-installation` 的 delta 用 `## MODIFIED Requirements` 指向 `cli-init`，但 16 条目标标题都和当前 spec 对不上（delta 写 `Skill generation per tool (REPLACES ...)`，spec 现在是 `Skill Generation`）。`archive` 输出：

```text
cli-init MODIFIED failed for header "### Requirement: Skill generation per tool (REPLACES fixed 9-skill mandate)" - not found
Aborted. No files were changed.
```

成因：`cli-init`/`cli-update` spec 之后被别的 archive 重写过、标题变了，而 delta 还停在旧标题——**两者漂移了，且没工具监控**。（完整诊断与修法见 `04`。）

## 信号 → 修法 速查表

| 噪声信号 | 根因 | 主治（详见 `03`） |
|----------|------|-------------------|
| ① 悬空 delta 目标 | 设计了没建 / 目录改名 | 清除原语（DELETE/SHELVE）或修复原语（AUTHOR-NEW） |
| ② 有代码无 spec | 漏报现状 | 修复原语（AUTHOR-NEW） |
| ③ 冻结 spec | archive 后无人维护 | 修复原语（纠正型 delta）或核选项（再基线） |
| ④ 废弃仍 active change | 放弃了没清 | 清除原语（DELETE/SHELVE） |
| ⑤ 平行权威层未对齐 | conventions 没承认新层 | 修复原语（更新 conventions spec）；详见 `09` |
| ⑥ 身份脆弱性（ur-cause） | 标题被改、delta 停在旧标题 | 修复原语（RENAMED）或核选项（再基线） |

## 守住的边界

工具管"写 specs"这一刻的可靠，不管"specs 持续对不对"——后者是工程纪律的责任。把这条想清楚，才不会指望一个不存在的 `openspec reconcile` 来救场。

## 继续阅读

- 这些噪声各自怎么修（真实结构是什么）：`03-手段清单-到底有多少种修法.md`
- 现场看到 `not found` 怎么诊断：`04-问题到方法-决策矩阵与排错.md`
- 用本 repo 的真实项一步步走：`05-走查-把手段用在自家repo上.md`
- `validate` 命令的完整选项 / CI 用途：`06-源码锚点与缺口.md`（validate 命令参考）
- 机理基础：`01-机理-主specs如何被delta构造.md`
