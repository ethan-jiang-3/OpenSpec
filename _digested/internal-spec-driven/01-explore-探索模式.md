# 01 — explore：探索模式

explore 是四条命令中最特殊的一个 —— 它不是工作流，不产生 artifact，不修改任何文件。它是一种**姿态（stance）**。

---

## 1. 定位："姿态，而非工作流"

explore 的关键设计理念，来自其 skill 模板 (`src/core/templates/workflows/explore.ts:17`)：

> "This is a stance, not a workflow. There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore."

这意味着：
- **没有必须走的流程** —— 不像 propose 那样必须按 DAG 顺序创建 artifact
- **没有必须产出的输出** —— 不像 apply 那样必须完成所有 tasks
- **agent 的角色是"思考伙伴"**，不是执行器

explore 的核心约束只有一个：**不许写代码**（可以创建 OpenSpec artifact 如果用户要求，但那算"捕捉想法"不算"实施"）。

---

## 2. CLI 调用链

explore 只用到两个 CLI 命令，而且第二个是可选的：

### 启动时：`openspec list --json`

```
openspec list --json
```

返回活跃的 change 列表，让 agent 知道当前项目的 OpenSpec 上下文：

```json
[
  {
    "name": "add-dark-mode",
    "schema": "spec-driven",
    "tasks": { "total": 7, "completed": 3 }
  }
]
```

agent 不需要对每个 change 都做处理 —— 它只是"感知"到项目中有哪些活跃 change，如果用户提到某个 change 或讨论自然地关联到它，agent 才会进一步探查。

### 当关联到某个 change 时：`openspec status --change X --json`

只有当用户提到具体 change，或者 agent 通过 `list` 发现只存在一个活跃 change 且上下文相关时，才会调用 status。这完全是**按需**的，不是强制步骤。

通过 status 的 JSON 返回，agent 获取：
- `changeRoot` — change 目录路径
- `artifactPaths` — 每个 artifact 的文件路径和已有输出
- `actionContext` — 编辑范围约束

然后 agent 读取已有的 artifact 文件来理解当前上下文：
```
Read: <changeRoot>/proposal.md  → 了解 scope
Read: <changeRoot>/design.md    → 了解技术决策
Read: <changeRoot>/specs/*/spec.md → 了解已有 spec
```

---

## 3. 零活跃 change 场景

当 `openspec list --json` 返回 `[]`（项目中没有活跃 change）时，explore 不需要任何 OpenSpec 上下文就能工作。agent 直接从用户的问题出发，读代码、画图、讨论方案——这和 classic 模式下的通用代码讨论没有本质区别，但 explore 的 guardrails（第 8 节）仍然适用。

只有在用户明确表示"值得做一个 change"时，agent 才会建议 `/opsx:propose`，从而进入有状态的工作流轨道。

## 4. 四种入口场景（有活跃 change 时）

explore 的 skill 模板 (`explore.ts`) 为四种典型场景分别提供了行为范例：

### 场景 A：模糊想法

```
User: I'm thinking about adding real-time collaboration

Agent: 画出协作光谱图（awareness → coordination → sync），
      标注复杂度差异，问"你的想法在哪一头？"
```

### 场景 B：具体问题

```
User: The auth system is a mess

Agent: [读代码] 画出当前 auth 流程的数据/控制流图，
      找到三个纠缠点，问"哪一个最痛？"
```

### 场景 C：实施卡住

```
User: /opsx:explore add-auth-system
      The OAuth integration is more complex than expected

Agent: [读 change 的 artifact] 你在 task 4 "Implement OAuth flow"。
      让我追踪一下涉及的组件... [画图，探索方案]
      要不要更新 design 或加一个 spike task？
```

### 场景 D：方案比较

```
User: Should we use Postgres or SQLite?

Agent: 这是通用答案没意义。什么场景？

User: A CLI tool that tracks local dev environments

Agent: 那就不一样了。
      约束：没 daemon、必须离线、单用户
      → SQLite，不假思索。
      除非……有 sync 需求？
```

---

## 5. 不生成 artifact —— 但可以"捕捉"

explore 明确禁止写应用代码（"Never write code or implement features"），但**可以创建 OpenSpec artifact** —— 如果用户要求。

这种"捕捉"被视为记录思考结果，不算实施。skill 模板中的原话：

> "You MAY create OpenSpec artifacts (proposals, designs, specs) if the user asks — that's capturing thinking, not implementing."

**关键设计点**：agent 不应该自动捕捉。模板反复强调：

> "Offer to capture when decisions are made... The user decides. Offer and move on. Don't pressure. Don't auto-capture."

有一个对照表告诉 agent 哪种洞察应该捕捉到哪里：

| 洞察类型 | 捕捉位置 |
|----------|---------|
| 发现了新的 requirement | `specs/<capability>/spec.md` |
| 某个 requirement 改了 | `specs/<capability>/spec.md` |
| 做了设计决策 | `design.md` |
| scope 变了 | `proposal.md` |
| 发现新的工作项 | `tasks.md` |
| 之前的假设不成立了 | 相关内容所在的 artifact |

---

## 6. 与 propose 的衔接

explore 结束时没有强制要求。可能的出路：

1. **流向 propose**："This feels solid enough to start a change. Want me to create a proposal?"
2. **更新已有 artifact**："Updated design.md with these decisions"
3. **只是提供 clarity**：用户获得了足够的信息，结束对话
4. **留到以后**："We can pick this up anytime"

---

## 7. 与另外三条命令的本质差异

| | explore | propose | apply | archive |
|------|------|------|------|------|
| **有状态流转** | 否 | 是（artifact 从 blocked→ready→done） | 是（tasks 从未完成→完成） | 是（change 从活跃→归档） |
| **修改文件系统** | 否（除非用户要求捕捉） | 是（创建 artifact 文件） | 是（改代码+更新 checkbox） | 是（合并 spec+移动目录） |
| **有"完成"概念** | 否 | 是（applyRequires 全部 done） | 是（所有 checkbox 标记） | 是（归档完成） |
| **schema 管控** | 极弱（只读 status） | 极强（控制整个创建流程） | 中（apply phase 定义） | 强（控制合并规则） |

---

## 8. Guardrails

来自 `explore.ts` 的 8 条护栏：

1. **Don't implement** — 不写代码。创建 artifact 可以，写应用代码不行。
2. **Don't fake understanding** — 不清楚就承认，深挖。
3. **Don't rush** — 探索是思考时间，不是任务时间。
4. **Don't force structure** — 让模式自然浮现。
5. **Don't auto-capture** — 提议捕捉，但不由 agent 自己决定。
6. **Do visualize** — 用 ASCII 图。一张好图顶好几段话。
7. **Do explore the codebase** — 基于真实代码讨论，不要飘在空中。
8. **Do question assumptions** — 包括用户的和你自己的。
