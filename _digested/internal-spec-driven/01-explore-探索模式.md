# 01 — explore：探索模式

explore 是四条命令中最特殊的一个 —— 它不是工作流，默认不产生 artifact；写文件（包括创建 OpenSpec artifact）只在用户明确要求且经确认后发生。它是一种**姿态（stance）**。

> **写入与交接语义演进**：v1.11.0 起写入需「命名 artifacts + 直接问 + 单独等确认」；v1.13.1（`b9281652`）上游修正了模板中「explore 绝不写文件」的过度承诺措辞；v1.13.1（`4c369e02`）起**用户主动明确要求把探索捕获为新 change 即视为该次写入的确认**，不再额外要一轮 yes/no。当前模板中的所有 handoff 常量（`explore.ts:33-50`）均采用工作流无关的自然语言表述（如 `offer to capture the discussion as a change`、`To implement, start from the tasks after leaving explore mode`），不再绑定 1.x 已移除的 `/opsx:*` 命令。

---

## 1. 定位："姿态，而非工作流"

explore 的关键设计理念，来自其 skill 模板 `src/core/templates/workflows/explore.ts`：

> "This is a stance, not a workflow. There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore."

这意味着：
- **没有必须走的流程** —— 不像 propose 那样必须按 DAG 顺序创建 artifact
- **没有必须产出的输出** —— 不像 apply 那样必须完成所有 tasks
- **agent 的角色是"思考伙伴"**，不是执行器

explore 的核心约束只有一个：**不许写业务代码，也不许改工作流配置（schemas、templates、`openspec/config.yaml`）**；在已确认范围内创建或更新 OpenSpec change artifact 是允许的，因为那算"捕捉想法"而非"实施"。此外，模板要求画图**只能使用纯 ASCII 字符**（`+ - | --> <-- ^ v * x`，`explore.ts:122-123`），避免 Unicode 框线字符在不同终端、字体或 locale 下宽度漂移。

---

## 2. 前置守卫与 CLI 调用链

进入正文前，模板先注入两条全工作流共享守卫（`explore.ts:61-63`）：
- **`STORE_SELECTION_GUIDANCE`**（`store-selection.ts`）：若用户点名或工作位于独立 store，先跑 `openspec store list --json` 查注册表，并在后续支持 `--store <id>` 的命令上全程保持该参数粘滞。
- **`PROJECT_ROOT_GUARD`**（`project-root.ts`）：任何写操作前先以 `openspec list --json` 校验 `root`；若 `"root": null` 且报 `Declared in` / `Invalid store declaration in` 错误（`config.yaml`/`.yml` 的 `store:` 无法解析或格式错误），立即停止并原样展示 `message` 与 `fix`；若是普通无根目录，agent 自发选技能时直接静默退回普通回答，用户显式点名 OpenSpec 时才询问如何处理，绝不擅自创建 `openspec/`。

随后，"Check for context" 段（`explore.ts:136-160`）按四步做只读上下文发现：

1. `openspec list --json` —— **change 列表**（"work in flight"）
2. `openspec list --specs`（可加 `--json` 取 id 与 requirement 计数）—— **durable capability 清单**。模板特意点明：「change 列表不包含项目长期沉淀的能力，所以还要列一次 specs」，避免把 in-flight changes 误当成 specs
3. **两步渐进式读取相关 spec**（`explore.ts:152-154`）：先跑 `openspec show "<spec-id>" --type spec --json --no-scenarios` 只拉取 capability 的 `Purpose` 与 requirement 正文作轻量概览（带 `--type spec` 防止与同名 change 产生歧义）；在决定「哪些行为已覆盖、哪些要改」之前，再跑 `openspec show "<spec-id>" --type spec` 完整读取含 scenarios 的全文
4. **读取项目配置约束**（`explore.ts:156-160`）：从上一步返回的 `root.path` 读取 `<root.path>/openspec/config.yaml`（不存在时回退 `config.yml`，两者皆无则跳过），将 `context`（技术栈、约定、约束）和 `rules`（仅在写对应 artifact 时生效）作为内部思考约束，严禁原样复制到对话或任何产物中

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
  │  "我想做实时协作"  /  "/openspec-explore add-auth-system"
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

只有在想法结晶时，agent 才会主动提议（如 `"This feels solid enough to start a change. Want me to create a proposal?"`）；一旦用户确认或主动要求捕获，agent 可直接在当前 explore 会话内通过 `openspec new change` + `status` + `instructions` 完成捕获，无需再让用户手动调用另一条技能。

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
User: /openspec-explore add-auth-system
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

这种"捕捉"算记录思考结果，不算实施。skill 模板中的原话（`explore.ts:57`，注意那个 **"within a confirmed scope"** 限定不能省）：

> "You MAY create or update OpenSpec change artifacts (proposals, designs, specs) **within a confirmed scope**—that's capturing thinking, not implementing."

模板紧接着还要求：第一次写操作前必须先说明会改哪些文件、问一个是/否问题，并在**下一条独立消息**里等用户确认；确认只覆盖你描述过的范围，回答澄清问题绝不等于同意写入。

**关键设计点**：agent 不应该自动捕捉。模板反复强调：

> "Offer to capture when decisions are made... The user decides. Offer and move on. Don't pressure. Don't auto-capture."

默认 `spec-driven` schema 下有一个对照表告诉 agent 哪种洞察捕捉到哪里（`explore.ts:193-205`）：

| 洞察类型 | 捕捉位置（默认 `spec-driven`） |
|----------|---------|
| 发现了新的 requirement | `specs/<capability-path>/spec.md` |
| 某个 requirement 改了 | `specs/<capability-path>/spec.md` |
| 做了设计决策 | `design.md` |
| scope 变了 | `proposal.md` |
| 发现新的工作项 | `tasks.md` |
| 之前的假设不成立了 | 相关内容所在的 artifact |

- **嵌套路径保持**：`<capability-path>` 是相对 `specs/` 的能力路径（如 `user-auth` 或 `identity/user-auth`），必须完整保留既有 capability 的嵌套路径并遵循项目的既有目录组织。
- **自定义 schema 适配（#2086，`explore.ts:195`）**：上表文件名仅针对默认 `spec-driven`。若 change 使用其他自定义 schema，必须从 `status --json` 返回的 **`artifactPaths`** 中挑选语义匹配的 artifact 并在提议里点名该 artifact，**绝不创建当前 schema 未定义的 artifact 文件**。

**用户主动请求即确认（v1.13.1）**：若用户自己主动要求把探索捕获为新 change，该请求本身即构成对「脚手架该 change + 创建请求点名的 artifacts」的确认，无需重问一轮 yes/no（但若是用户对 agent 提议回复 "yes"，则只确认提议中点名的范围；超出范围仍需再次确认）。

**直接捕获四步闭环（`explore.ts:169-176`）**：

1. 先跑 `openspec new change "<name>"`（有 store 时带 `--store <id>`），严禁手建 `openspec/changes/<name>/` 目录，确保 `.openspec.yaml` 由 CLI 生成。
2. 跑 `openspec status --change "<name>" --json`，按依赖序处理用户点名的 artifacts：对 `ready` 的目标跑 `openspec instructions "<artifact-id>" --change "<name>" --json`；若该 artifact 自身的 `instruction` 声明了启用条件（如 `design` 的 "create only if..."）且当前探索不满足条件，记录一次**有意识的条件跳过（deliberate skip）**而非强写文件；若目标被用户未点名的前置 artifact 阻塞，先读前置的 `instructions` 评估其是否为不适用条件项——可条件跳过则记录跳过，否则必须向用户解释依赖并征得同意后才能扩写前置。
3. 按返回的 `template` 与 `instruction` 起草内容（将 `context` / `rules` 作为约束而非正文）；当 `resolvedOutputPath` 是 glob 时，在 `changeRoot` 内选具体路径并在解析符号链接后确认父目录与目标文件均未逃逸 `changeRoot`。
4. 每写完一个重跑 `status --json`，直到所求 artifacts 全部为 `done`、`skipped` 或已记录条件跳过（仅因已记录的条件跳过而显示 `blocked` 的下游项允许直接拉 `instructions` 创建）。完成后**停在规划边界内**，告知后续规划与实施交接句（`To finish planning, complete the remaining planning artifacts from the change. To implement, start from the tasks after leaving explore mode.`），绝不在 explore 中直接开始写业务代码。

---

## 6. 探索收尾与后续衔接

explore 结束时没有强制要求。模板列出的四种自然收尾（`explore.ts:330-338`）：

1. **流向新 change 捕获**：`"Would you like me to capture this as a change?"`
2. **更新已有 change 的产物**：`"Updated the design with these decisions"`（schema 无关表述，不写死 `design.md`）
3. **只是提供 clarity**：用户获得了足够的信息，结束对话
4. **留到以后**：`"We can pick this up anytime"`

---

## 7. 与另外三条命令的本质差异

| | explore | propose | apply | archive |
|------|------|------|------|------|
| **有状态流转** | 否（默认）；确认捕获时走 `ready → done/skipped` | 是（artifact 从 blocked→ready→done） | 是（tasks 从未完成→完成） | 是（change 从活跃→archive） |
| **修改文件系统** | 默认否；确认后可创建 change 并写受确认的 artifacts | 是（创建传递依赖闭包内的 artifact 文件） | 是（改代码+更新 checkbox） | 是（合并/退役 spec + 移动目录） |
| **有"完成"概念** | 否（捕获分支以所求 artifacts 落盘为界） | 是（required set 全部 done/skipped） | 是（所有 checkbox 标记） | 是（archive 完成） |
| **schema 管控** | 中（读 `artifactPaths`；捕获时受 `instructions` 与条件规则约束） | 极强（控制整个创建流程） | 中（apply phase 定义） | 强（控制合并规则） |

---

## 8. Guardrails

来自 `explore.ts:359-369` 的 9 条护栏（6 条 "Don't" + 3 条 "Do"）：

1. **Don't implement** — 绝不写业务代码或实现功能；**工作流配置同样算实施改动而非思考**——禁止创建或编辑 schemas、templates 或 `openspec/config.yaml`。只允许在已确认范围内创建/更新 change artifacts；用户准备动手构建时，只提示先捕获为 change（`offer to capture the discussion as a change first`），绝不在 explore 内开工。
2. **Don't fake understanding** — 不清楚就承认，深挖。
3. **Don't rush** — 探索是思考时间，不是任务时间。
4. **Don't force structure** — 让模式自然浮现。
5. **Don't auto-capture** — 提议捕捉，但不由 agent 自己决定；首次写操作（含 agent 主动提议时的 `openspec new change`）前必须点名拟改文件/产物、给出直接的 yes/no 问题并在下一条用户消息中等明确确认。
6. **Don't manually scaffold changes** — 绝不手建 `openspec/changes/<name>/` 目录，一律走 `openspec new change "<name>"`（必要时带 `--store <id>`）生成 `.openspec.yaml` 等必需 metadata。
7. **Do visualize** — 用纯 ASCII 图。一张好图顶好几段话。
8. **Do explore the codebase** — 基于真实代码讨论，不要飘在空中。
9. **Do question assumptions** — 包括用户的和你自己的。
