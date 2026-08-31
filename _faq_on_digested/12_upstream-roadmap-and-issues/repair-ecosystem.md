# `/opsx:repair` 深度探究：从上游 Issue #821 到我们已有的研究

> 这是对 `answer.md` 中 "社区呼声最高的 Feature Request — `/opsx:repair`" 一条的展开。
> 来源：GitHub Issue #821、#684、upstream docs（commands.md, reviewing-changes.md）、`/opsx:verify` 实现细节、
> 以及我们已有的 `_faq_on_digested/11_keep-specs-aligned/` + `_digested/specs_truth/` + `_digested/workflows/08-verify.md` + `_digested/workflows/12-update.md`。

> **历史边界（v1.7.0 已纠偏）。** 本文讨论的是 issue 语境中的 Claude `/opsx:*` 与当时机制；Codex 当前为 `$openspec-*` skills-only（v1.8.0 下装在 `.agents/skills/`）。文中关于 Apply/Archive “不能接收 config”的旧说法应读作“不接收 artifact rules”；project `context` 与 `operations.apply/archive.guidance` 已分别成为当前 operation input。v1.8.0 未推翻这些边界。

---

## 一、Issue #821 到底在说什么

**标题**：Feature Request: Add `/opsx:repair` command to support spec-consistent repair after `/opsx:apply`

**核心痛点**：当前标准工作流 `/opsx:propose` → `/opsx:apply` → test → `/opsx:archive` 中间有一个**手工黑洞**。apply 之后本地测试发现 bug 或不一致，开发者必须**手动**指挥 AI 做四件事：

1. 修代码
2. 如果 spec 写错了 → 更新 `spec.md`
3. 如果架构变了 → 更新 `design.md`
4. 更新 `tasks.md`

每一步都是重复的口头指令（"把 spec 里那条也改一下""tasks 那个 checkbox 还没勾"），而且**四者之间没有自动一致性保证**。修了代码忘了改 spec？下次 apply 读到旧 spec，agent 又被带偏。

**提出的方案**：一个 `/opsx:repair` 命令，由 agent 自动执行：

```
发现问题
  ├── 分析根因：是 implementation 错了，还是 specification 不完整/不正确？
  │
  ├── 如果 implementation 错 → 只修代码，spec 不动
  │
  └── 如果 specification 不完整/不正确 →
       更新 spec.md（如果需要）→ 更新 design.md（如果需要）
       → 更新 tasks.md → 更新 implementation
       → 验证一致性 → change 保持 archive-ready
```

**期望的工作流变化**：

```
Before:  /opsx:propose → /opsx:apply → test → (手工修复循环) → /opsx:archive
After:   /opsx:propose → /opsx:apply → test → /opsx:repair → /opsx:archive
```

**当前状态**：Feature request，open，尚未实现。

---

## 二、但上游维护者和社区指出了什么——这不是孤立的

Issue #821 的讨论中，维护者和社区成员指出 `/opsx:repair` 的需求**已经被三个已有命令部分覆盖**。这不是"应该做一个新命令还是不做"的二元问题，而是**三个现有命令各自覆盖了 repair 的一部分，但拼起来仍然有缝**。

### 2.1 `/opsx:verify` — 发现问题，但不修

v0.20.0 引入，属于 expanded profile。在 apply 之后、archive 之前运行。按三个维度检查：

| 维度 | 检查什么 | 严重度分级 |
|------|---------|-----------|
| **Completeness** | 所有 tasks 是否完成、所有 requirements 是否实现、所有 scenarios 是否覆盖 | CRITICAL / WARNING |
| **Correctness** | 实现是否匹配 spec 意图、边界情况是否处理、错误状态是否匹配 spec 定义 | CRITICAL / WARNING |
| **Coherence** | 设计决策是否反映在代码中、命名约定是否一致、模式是否匹配 design.md | WARNING / SUGGESTION |

技术实现：agent 读取 `tasks.md` 的 `[x]` checkbox 状态、从 delta spec 提取 `### Requirement:` 头、搜索代码库寻找实现证据、检查 `#### Scenario:` 是否有测试覆盖。

**关键限制**：verify 只诊断不治疗。它产出报告（CRITICAL / WARNING / SUGGESTION），但**不修任何东西**。发现 spec 和代码不一致时，它只能说"这里有问题"，不会自动判断是改 spec 还是改代码，更不会执行修复。

**和我们的研究对照**：`_digested/workflows/08-verify.md` 已经分析了 verify 的机制，`_digested/specs_truth/06-源码锚点与缺口.md` 明确指出 `validate` 是结构 linter、抓不出 specs↔代码漂移。`/opsx:verify` 比 `openspec validate` 更进一步（agent 驱动的语义检查 vs 纯结构 lint），但它仍然只是**诊断层**。

### 2.2 `/opsx:update` — 修 artifacts，但假设实现是对的

v1.6.0 引入（PR #1278）。当你想修改 planning artifacts（proposal/specs/design/tasks）而**不碰代码**时使用。它修改 artifacts 并自动调和依赖产物之间的不一致。

**场景**：propose 产出的 spec 不够好 → `/opsx:update` 修改 spec → 自动更新 design 和 tasks 里受影响的部分 → change 保持内部一致。

**关键限制**：update 的隐含前提是"修改 artifacts 去更好地描述**已经确定的**需求"，而不是"实现中发现了 spec 的错误并需要双向修复"。它不分析代码实现，也不判断"到底是代码错了还是 spec 错了"——它假设你在调 artifacts。

### 2.3 `/opsx:continue` — 推进 artifact 生成，但不做修复决策

在 `/opsx:new` 创建空 change scaffold 后，逐个生成 artifact。也可以用来重新生成某个 artifact。

**关键限制**：continue 按 DAG 拓扑序推进 artifact 生成，但它不执行"对比 spec 和代码 → 判断谁错了 → 修复"这个决策循环。它只是"按 schema 声明继续生成下一个 artifact"。

### 2.4 三个命令的覆盖矩阵

| 能力 | `/opsx:verify` | `/opsx:update` | `/opsx:continue` | 理想的 `/opsx:repair` |
|------|:---:|:---:|:---:|:---:|
| 发现 spec↔代码不一致 | ✅ 诊断 | ❌ | ❌ | ✅ |
| 判断根因（spec 错还是代码错） | ❌ | ❌ | ❌ | ✅ |
| 修 spec | ❌ | ✅ 但假设 spec 是主动要改的 | ❌ | ✅ 自动判断是否需要 |
| 修代码 | ❌ | ❌ | ❌ | ✅ |
| 更新关联 artifacts（design/tasks） | ❌ | ✅ 自动调和 | ❌ | ✅ |
| 保持 archive-ready | ❌ | ✅ | ❌ | ✅ |

**结论**：三者拼起来覆盖了 repair 的很多子任务，但缺少核心的一块——**根因判断 + 双向修复的自动决策**。这正是 Issue #821 要解决的。

---

## 三、Issue #684：同一个问题的另一个入口

**标题**：How to update specifications during the apply phase?

在 #821 之前，社区已经通过 #684 问过类似问题：apply 中途发现 spec 不够细，怎么办？

**官方回答**：
1. 暂停 apply
2. 手动编辑 change 目录下的 artifact 文件（`proposal.md`、`specs/<capability>/spec.md`、`design.md`、`tasks.md`）
3. 重新运行 `/opsx:apply`（它每次调用都会重新读取所有上下文文件——源码 `src/commands/workflow/instructions.ts:336-353`）
4. 或者用 `/opsx:update`（v1.6.0+）来自动调和关联产物

**核心态度**：OpenSpec 是"fluid, not phase-locked"——没有阶段锁，随时可以编辑 artifacts 再重新 apply。哲学上是灵活的，但**实操上仍然是手工的**。#821 的 `/opsx:repair` 就是要把这个手工循环自动化。

**关联 issues**：#673（dedicated "clarify" command）、#618（fixing mistakes in completed changes）、#264、#119、#141——都在不同角度描述同一个 gap：**apply 之后的修复循环缺少工具支持**。

---

## 四、和我们在 `_digested/` 里独立发现的对照

这是我们自己的研究**超前于社区平均水平**的又一个证据：

### 4.1 `_faq_on_digested/11_keep-specs-aligned/answer.md`

我们自己总结的四招修复法（内容失准→propose 改再 archive、漏能力→ADDED 补、噪声 change→挪走、archive not found→grep 对齐）**本质上就是手工版 `/opsx:repair`**。Issue #821 想做的就是把"招一"（发现 spec 说错了→改 spec→改代码→改关联产物→验证）从**人工编排**变成**一条命令**。

我们的 answer.md 第 54 行写的"修复原语"和 Issue #821 的 automated repair loop 描述的是**同一个工作流，只是自动化程度不同**。

### 4.2 `_digested/specs_truth/README.md` 的核心判断

> specs 只在 archive 那一刻被写入；requirement 没有稳定 ID；而且没有任何工具持续对账。⇒ 漂移是默认状态

Issue #821 可以被理解为：**社区终于意识到"手工对账"的负担太重了，要求工具化**。而我们的 `specs_truth/` 专题比这个 issue 更早、更系统地论证了**为什么漂移是默认状态**——不只是因为缺一个命令，而是因为 requirement 身份模型（标题=ID）、archive 是唯一写入点、没有任何对账基础设施，三者叠加导致了结构性漂移。

### 4.3 `_digested/specs_truth/03-手段清单-到底有多少种修法.md`

我们列举的修法（纠正型 delta、AUTHOR-NEW、DELETE/SHELVE、手改再基线）都是**操作原语**。Issue #821 的 `/opsx:repair` 想做的是把这些原语封装成一个 **agent 可执行的决策树**——agent 自动选择该用哪种原语，而不是让开发者自己判断"这是 MODIFIED 还是 AUTHOR-NEW"。

---

## 五、关键判断：`/opsx:repair` 为什么还没做

综合上游讨论和我们的研究，可以推断几个原因：

1. **设计难度高**：不像 verify（只读诊断）或 update（假设 artifacts 是主动要改的），repair 需要 agent 做出**根因判断**——代码错了还是 spec 错了？这个判断在不理解业务语义的情况下容易出错。修错了方向（spec 本来对的但 agent 把它改成匹配错误代码）比不修更糟糕。

2. **三个现有命令已经降低了痛点**：verify 能发现问题、update 能修 artifacts、continue 能重新生成——虽然拼起来有缝，但缝已经比 v1.0 时代小得多。维护者可能认为优先级不如 initiative/workspace 等架构级工作。

3. **和 OpenSpec 的哲学张力**：OpenSpec 的核心哲学是"specs 是人 + 纪律 + 巡检的责任"（`specs_truth/README.md` 的结论）。做一个自动判断"spec 对还是代码对"的工具，某种程度上是把人类的决策责任外包给 agent——和 OpenSpec "spec 是人类意图的表达"的定位有张力。

4. **`/opsx:verify` + `/opsx:update` 的组合已经覆盖了 80% 的场景**：verify 告诉你哪里不对，update 让你改 artifacts——剩下 20% 是"我不确定该改 spec 还是改代码"的场景。对很多用户来说，这 20% 可以靠 `/opsx:explore`（和 agent 讨论）来解决。

---

## 六、对我们自己的启示

1. **`_faq_on_digested/11_keep-specs-aligned/` 的价值被上游验证了**：Issue #821 描述的问题和我们"怎么别让 main specs 和代码对不上"回答的是同一件事。我们的四招修复法可以直接映射到 `/opsx:repair` 期望的自动化流程。

2. **`_digested/specs_truth/` 专题的深度超前于社区**：我们在上游 issue 提出之前就已经系统分析了漂移机理（身份模型脆弱性、archive 是唯一写入点、无对账基础设施）。Issue #821 是一个具体 feature request，而 `specs_truth/` 是系统性论证——两者互补。

3. **修复自动化是 SDD 工具的必答题**：如果 OpenSpec 不做 `/opsx:repair`，竞品（SpecKit 的 clarify/review phase、Kiro 的 Spec Check）会在这个维度拉开差距。我们跟踪这个问题可以作为判断 OpenSpec 竞争力的一个指标。

---

## 参考来源

- [Issue #821 — `/opsx:repair` feature request](https://github.com/Fission-AI/OpenSpec/issues/821)
- [Issue #684 — How to update specifications during apply](https://github.com/Fission-AI/OpenSpec/issues/684)
- [upstream `docs/commands.md` — `/opsx:verify` 定义](https://github.com/Fission-AI/OpenSpec/blob/main/docs/commands.md)
- [upstream `docs/reviewing-changes.md`](https://github.com/Fission-AI/OpenSpec/blob/main/docs/reviewing-changes.md)
- [`../../_faq_on_digested/11_keep-specs-aligned/answer.md`](../11_keep-specs-aligned/answer.md) — 我们自己的手工修复四招
- [`../../_digested/specs_truth/`](../../_digested/specs_truth/) — spec 漂移机理的系统分析
- [`../../_digested/workflows/08-verify.md`](../../_digested/workflows/08-verify.md) — verify 工作流分析
- [`../../_digested/workflows/12-update.md`](../../_digested/workflows/12-update.md) — update 工作流分析
