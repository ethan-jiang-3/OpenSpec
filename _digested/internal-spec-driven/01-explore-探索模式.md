# 01 — explore：探索模式

explore 是四条命令中最特殊的一个 —— 它不是工作流，默认不产生 artifact；写文件（包括创建 OpenSpec artifact）只在用户明确要求且经确认后发生。它是一种**姿态（stance）**。

> **v1.11.0–v1.13.1 写入语义演进**：v1.11.0 起写入需「命名 artifacts + 直接问 + 单独等确认」；v1.13.1（`b9281652`）上游修正了模板中「explore 绝不写文件」的过度承诺措辞；v1.13.1（`4c369e02`）起**用户明确要求 capture 一个 change 即视为该次写入的确认**，不再额外要一轮 yes/no，且每次 handoff 都点名 `/opsx:propose`、`/opsx:apply`。

---

## 1. 定位："姿态，而非工作流"

explore 的关键设计理念，来自其 skill 模板 `src/core/templates/workflows/explore.ts`：

> "This is a stance, not a workflow. There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore."

这意味着：
- **没有必须走的流程** —— 不像 propose 那样必须按 DAG 顺序创建 artifact
- **没有必须产出的输出** —— 不像 apply 那样必须完成所有 tasks
- **agent 的角色是"思考伙伴"**，不是执行器

explore 的核心约束只有一个：**不许写代码**（可以创建 OpenSpec artifact 如果用户要求，但那算"捕捉想法"不算"实施"）。

---

## 2. CLI 调用链

explore 的模板直接教了三条只读命令（`explore.ts:167-185` 的 "Check for context" 段）：

1. `openspec list --json` —— **change 列表**（"work in flight"）
2. `openspec list --specs`（可加 `--json` 取 id 与 requirement 计数）—— **durable capability 清单**。模板特意点明：「change 列表不包含项目长期沉淀的能力，所以还要列一次 specs」，避免把 in-flight changes 误当成 specs
3. 对相关 spec 再**完整读一遍**——模板说 `--json` 的过滤读只是 overview，判断「是否已覆盖」之前必须读全文

`--store "<id>"` 只在读已注册的 standalone store 时才追加。v1.13.0 起（`3915db76`）这套 store-aware 定位才成立。

### 启动时：`openspec list --json`

```
openspec list --json
```

返回活跃的 change 列表，让 agent 知道当前项目的 OpenSpec 上下文：

```json
{
  "changes": [
    {
      "name": "add-dark-mode",
      "completedTasks": 3,
      "totalTasks": 7,
      "lastModified": "2026-01-01T00:00:00.000Z",
      "status": "in-progress"
    }
  ],
  "root": { "...": "解析到的 OpenSpec 根" }
}
```

注意字段形状（`src/core/list.ts:198-223`）：是**外层对象** `{changes, warnings?, root?}` 而非裸数组；条目用扁平的 `completedTasks`/`totalTasks`，**没有 `schema` 字段**，也没有嵌套的 `tasks` 对象。还有可选的 `warnings`（`nested_change_directory`）和条目的 `nested`/`archived`（后者只在 `--archived` 时出现）。

agent 不需要对每个 change 都做处理 —— 它只是"感知"到项目中有哪些活跃 change，如果用户提到某个 change 或讨论自然地关联到它，agent 才会进一步探查。

### 当关联到某个 change 时：`openspec status --change X --json`

只有用户提到具体 change，或者 agent 通过 `list` 发现只存在一个活跃 change 且上下文相关时，才会调用 status。这完全是**按需**的，不是强制步骤。

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

### 2.1 三方架构实例化：explore 的四方交互

explore 是四条命令中最轻量的——CLI 只做信息输出，agent 只读不写（除非用户要求"捕捉"）：

```
User（人类）
  │  "我想做实时协作"  /  "/opsx:explore add-auth-system"
  ▼
Host Agent（Claude Code / Cursor / Cline）
  │  openspec list --json                       → 感知项目中有哪些活跃 change
  │  openspec status --change X --json          →（可选）获取某个 change 的 artifact DAG 状态
  │  Read: <changeDir>/proposal.md              → 了解 scope
  │  Read: <changeDir>/design.md                → 了解技术决策
  │  Read: <changeDir>/specs/**/spec.md         → 了解已有 spec
  │  讨论、画 ASCII 图、探索方案                  → 对话
  │  （可选）写 artifact 文件                     → "捕捉而非实施"
  ▼
OpenSpec CLI（只读信息源）
  │  openspec list     → 扫描 openspec/changes/ → 返回活跃 change 列表
  │  openspec status   → 读 schema.yaml → 构建 DAG → 返回 artifact 状态 / 路径
  │  CLI 不写任何文件，不生成任何内容
  ▼
文件系统（探索的上下文）
  openspec/changes/<name>/  — 已有 change 的 artifact 文件
  openspec/specs/           — 主 spec 基线（了解现有能力）
  src/                      — 应用代码（agent 必须基于真实代码讨论）
```

**explore 的核心约束**：CLI 不做推理，agent 不写代码。CLI 只是"信息开关"，agent 在 guardrails 框架内自由探索。

---

## 2.1 聚焦式 discovery（v1.12.0 #1017）

explore 的提问方式在 v1.12.0 系统化：

- **依赖优先**：先解决阻塞性决策（先定 outcome/scope，再谈 API/数据模型），上游答案变化时回访下游假设
- **一次一问**：每个问题说明它解锁哪个决策；用户要求批量时才批量
- **有依据的推荐**：证据支持时给出首选方案与理由、备选与代价；不替用户发明意图、优先级或外部约束
- **对话即记录**：决策记在对话里（区分「已确认/建议默认/未决」），**不写文件**；沉默不是接受，回答问题也不是写入授权
- **先查仓库再问**：事实能从 artifacts/源码/测试/文档/配置核实的，不问用户

---
## 3. 零活跃 change 场景

`openspec list --json` 返回 `{"changes": []}`（项目中没有活跃 change，`src/core/list.ts:153`）时，explore 不需要任何 OpenSpec 上下文就能工作。agent 直接从用户的问题出发，读代码、画图、讨论方案——这和 classic 模式下的通用代码讨论没有本质区别，但 explore 的 guardrails（第 8 节）仍然适用。

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

这种"捕捉"算记录思考结果，不算实施。skill 模板中的原话（`explore.ts:82`，注意那个 **"within a confirmed scope"** 限定不能省）：

> "You MAY create or update OpenSpec change artifacts (proposals, designs, specs) **within a confirmed scope**—that's capturing thinking, not implementing."

模板紧接着还要求：第一次写操作前必须先说明会改哪些文件、问一个是/否问题，并在**下一条消息**里等用户确认；确认只覆盖你描述过的范围。

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

**v1.13.1 确认语义**：用户明确要求捕捉成 change，即视为该次写入的确认——不再要求 agent 额外问一轮 yes/no；扩范围（超出已描述内容）仍需再确认。

**v1.8.0 捕获规则（scaffold-first）**：若用户要求把探索**捕捉成新 change**，agent 必须先 `openspec new change "<name>"`（要 `--store` 时带上）再写任何 artifact——CLI 的 scaffold 会生成 `.openspec.yaml` 等必需 metadata，绝不能手搓 `openspec/changes/<name>/` 目录。之后按 `status` → `instructions` 顺序建 artifact，且**不需要再让用户跑别的 workflow 命令**；若用户只要开 change，scaffold 后停下并展示状态即可。（改已有 change 的 artifact 不在此列，仍是直接编辑。）

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
| **有状态流转** | 否（capture 时走 ready→done/skipped） | 是（artifact 从 blocked→ready→done） | 是（tasks 从未完成→完成） | 是（change 从活跃→archive） |
| **修改文件系统** | 默认否；确认后可捕捉 artifact（v1.13.1：用户明确要求 capture 即确认） | 是（创建 artifact 文件） | 是（改代码+更新 checkbox） | 是（合并 spec+移动目录） |
| **有"完成"概念** | 否 | 是（applyRequires 全部 done） | 是（所有 checkbox 标记） | 是（archive完成） |
| **schema 管控** | 极弱（只读 status） | 极强（控制整个创建流程） | 中（apply phase 定义） | 强（控制合并规则） |

---

## 8. Guardrails

来自 `explore.ts:386-394` 的 9 条护栏（6 条 "Don't" + 3 条 "Do"）：

1. **Don't implement** — 不写代码。创建 artifact 可以，写应用代码不行。
2. **Don't fake understanding** — 不清楚就承认，深挖。
3. **Don't rush** — 探索是思考时间，不是任务时间。
4. **Don't force structure** — 让模式自然浮现。
5. **Don't auto-capture** — 提议捕捉，但不由 agent 自己决定。
6. **Don't manually scaffold changes** — 绝不手建 `openspec/changes/<name>/` 目录，一律走 `openspec new change` 生成 `.openspec.yaml` 等必需 metadata。
7. **Do visualize** — 用 ASCII 图。一张好图顶好几段话。
8. **Do explore the codebase** — 基于真实代码讨论，不要飘在空中。
9. **Do question assumptions** — 包括用户的和你自己的。

另外表格里把 explore 的「有状态流转」标成「否」是就默认姿态而言；一旦进入 capture 分支，它会沿 `status` 的 `ready`→`done`/`skipped` 走一遍（见第 5 节），所以准确说法是「**否（默认）；capture 时是**」。
