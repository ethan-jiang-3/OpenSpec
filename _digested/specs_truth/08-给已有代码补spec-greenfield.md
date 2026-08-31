# 给已有代码补 spec（greenfield 采用流程）

## 一句话

**specs 不是手写出来的，是 archive 出来的**——哪怕是从零开始。给一个已经在跑的代码库补 spec，本质就是 `03` 修复原语的**加法情形（AUTHOR-NEW）批量做**：按 capability切分、逐个写 ADDED delta、逐个 archive。这是"采用 OpenSpec"，不是"修漂移"。

## 先破一个误解：specs 怎么从无到有

没有"`openspec new spec` 创建 spec"这种动作。specs 进入 `openspec/specs/` 的**唯一**路径，和日常改 spec 一样——**archive 一个带 `## ADDED Requirements` 的 delta**：

```text
openspec new change add-<capability>          # = propose，脚手架
# 写 changes/add-<capability>/specs/<capability-path>/spec.md（## Purpose + ## ADDED Requirements ...）
openspec archive add-<capability> -y          # archive 发现目标 spec 不存在 → buildSpecSkeleton 建第一个 spec
```

`archive` 在 `findSpecUpdates` 时发现 `openspec/specs/<capability-path>/` 不存在，就用 `buildSpecSkeleton` 生成一个带 `## Purpose` + 你 ADDED requirements 的全新 spec（机理见 `01`）。v1.7.0 会优先复制 delta 的 `## Purpose`；只有 delta 没有可用 Purpose 时才写 TBD placeholder。**所以"建 spec"就是"写一个全 ADDED、带 Purpose 的 change 再 archive"。**

## greenfield 采用：给已有代码库补 spec

一个已经在跑的代码库（几万行代码、一堆功能）现在要采用 OpenSpec。这是 `02` 信号 ②（有代码无 spec）的**规模化版本**。流程：

1. **按 capability切分**：把代码库切成若干"能力"——通常是用户可感知的功能单元或一组命令（如 `context-store`、`initiative`、`cli-view`）。**别按文件/目录切，按 capability切**（一个能力可能跨多个文件）。
2. **逐个、增量地补**：每个 capability一个 change（`add-<capability>-spec`），写 `## ADDED Requirements`，如实描述**已发运**的行为，然后 archive。**别想一次把全库写成 spec**——那是注定失败的瀑布。
3. **按优先级排**：先补最常被 agent 误读、最活跃的能力；边缘的、内部机制的后补或不补。
4. **在每个新 capability 的 delta 中先写 `## Purpose`**；archive 会带入 main spec。若历史 delta 已生成 TBD placeholder，再补 main spec 的 Purpose。

模板（archive 自校验，不必单跑 validate）：

```bash
openspec new change add-<capability>-spec
# changes/add-<capability>-spec/specs/<capability-path>/spec.md：
#   ## Purpose（描述这个 capability 的用途）
#   ## ADDED Requirements
#   ### Requirement: <行为>   ← SHALL/MUST + ≥1 个 #### Scenario:，描述 src/ 里已发运的行为
openspec archive add-<capability>-spec -y
# 若没写 delta Purpose，补 openspec/specs/<capability-path>/spec.md 的 fallback ## Purpose
```

## 关键判断：哪些该有 spec，哪些不该

不是所有代码都该有 spec（`02` 的判断难点）：

- **该有 spec**：一等公民 capability——有用户可感知行为 / CLI 表面 / JSON 契约 / 跨模块的功能单元。例：`context-store`、`initiative`、`archive`。
- **不该单独有 spec**：内部引擎、纯实现机制（被别的命令调用的模块）。按 conventions，这些属 `design.md`/`tasks.md` 范畴，其可观测行为应由**调用它的那个capability 的 spec** 覆盖。例：`profile-sync-drift.ts`（内部引擎，靠 `cli-update`/`global-config` spec 覆盖，不自立 spec）。
- **灰色地带**：拿不准就问"agent 会不会需要读它来判断行为"——会，就补；不会，就归内部。

## 和"修漂移"的区别（别混）

- **修漂移**（`02`/`03`/`05`）：specs **已存在**但和代码对不上 → 用 MODIFIED/REMOVED/RENAMED 纠正。
- **greenfield 采用**（本篇）：specs **从不存在**，给已有代码**新建** → 全用 ADDED。

两者都用 archive，但操作不同：修漂移多在 MODIFIED/REMOVED/RENAMED；greenfield 全是 ADDED。

## 守住的边界

greenfield 的陷阱是**野心太大**（想一次写全）和**写成愿望**（描述想要的行为而非已发运的）。对策就是"按 capability切、增量补、如实描述已发运"。把每个 capability的 spec 当一次小型的 propose→archive，跑顺了，代码库就能从"零 spec"稳步走到"specs 覆盖所有已发运 capability"——这才是 `05` 里"specs 配得上 source of truth"的前提。

## 继续阅读

- 修复原语（ADDED/AUTHOR-NEW 是它的加法情形）：`03-手段清单-到底有多少种修法.md`
- 信号 ②（有代码无 spec）的实证：`02-漂移与噪声-为什么主specs会失真.md`
- 本 repo 给 context-store/initiative 补 spec 的走查：`05-走查-把手段用在自家repo上.md`（项 5）
- archive 怎么建第一个 spec（机理）：`01-机理-主specs如何被delta构造.md`
