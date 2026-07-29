# 答案：专家手写 config.yaml，agent 只当 spot 助手

## 一句话

专家自己写 `config.yaml`——完全掌控 spec-driven schema **之内**的提示层（context / rules）。agent 在这条路上**不当作者，只当 spot 助手**：review 弱规则、按需起草一条、校验 key、扫覆盖度。要改工作流结构本身（artifact / 依赖 / 模板）见 [`answer-guru.md`](answer-guru.md)。

v1.7.0 的例外是现成的 operation input：Apply/Archive 的项目级短稳定步骤可写 `operations.apply/archive.guidance`，无需把它们伪装成 `rules.apply/archive` 或为了这一件事 fork schema。

```text
config 提示层（context/rules）最深；不动 schema 结构层
  人 = 作者（你写每一条 context / rules）
  agent = 助手（你点一下，它出意见 / 草稿 / 校验，你拍板）
  ↑ 和 answer-intermediate.md 的区别：那里 agent 是作者，这里你是作者
  ↑ 和 answer-guru.md 的区别：这里在 spec-driven schema 内调提示层，那里改 schema 结构本身
```

## 为什么专家选择手写

不是因为排斥 agent，是因为 **config.yaml 是项目的"宪法"**——它注入到每一个 artifact 的每一次生成。这个位置值得亲手精确命中真正的约束。agent 写 config 容易偏弱偏泛（"write clean code"那种），或者把你某个一次性需求当成全局规则。专家知道每条规则该卡在哪个 artifact、该用多强的措辞，这个判断不该外包。

但专家也不该白干体力活。**把 agent 用在它能放大你判断的地方**——review、起草、校验、扫覆盖度——而不是让它代替你的判断。下面就是这个用法。

## 手写的节奏

和 [`answer-intermediate.md`](answer-intermediate.md) 是同一个节奏，区别在**谁来写**：

```text
openspec init                → 不动 config（schema: spec-driven 一行够跑）
第一个 change 之前            → 你手写 context（4 行不变背景）
每 archive 一个 change 之后   → 你 review：这次反复纠正了什么？
                              手补最痛的 1 条 rule 进对应 artifact
```

为什么能这样边用边补：`config.yaml` 每次 `openspec instructions` 都重读、即时生效、写错不崩（fail-open，逐字段降级，`src/core/artifact-graph/instruction-loader.ts` + `src/core/project-config.ts`）。所以你不需要开局就写对——靠真实使用收敛。

## context 怎么手写好

只放**不变的背景**，且要高信息密度：

- 放：技术栈、领域、质量优先级、兼容性约束。
- 不放：PRD、本次 change 的目标、容易变的东西（它注入所有 artifact，临时内容会反复干扰）。

`context` 有 **50KB 硬上限**，超了整段被忽略并 warning（`src/core/project-config.ts:103-107`）。实践上控制在半屏以内。

写得好不好，套 handbook 06 的三个特质（见 [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md)）：**高杠杆**（一条影响很多 change）、**可判断**（有对象和方向）、**长期稳定**（不是一次性的）。6 个 bad smell（太 PRD / 太口号 / 太一次性 / 太像能力清单 / 太像 schema 定义 / 又长又稀）也都在那。

范例：这个 repo 自己的 [`../../openspec/config.yaml`](../../openspec/config.yaml)——context 分两块（产品语言 + 跨平台要求），每行都密。

## rules 怎么手写好

`rules` 按 artifact ID 分别注入。`spec-driven` 下合法 key：`proposal` / `specs` / `design` / `tasks`。

**强规则公式**：

```text
Changes affecting <对象> must <约束>.
Do not <危险行为> unless <例外>.
```

**按 artifact 角色给方向**：

| artifact | 该约束什么 | 强规则示例 |
|---|---|---|
| `proposal` | scope（影响范围） | `Changes affecting authorization must reference existing auth spec requirements.` |
| `specs` | 行为完整性 | `Every requirement must include at least one unhappy-path scenario.` |
| `design` | 技术决策质量 | `Design decisions must note the rejected alternative and why.` |
| `tasks` | 可追踪性 | `Each task group must reference the spec requirement it implements.` |

砍掉一切口号（`clean` / `proper` / `best practice`）——它们没判断力，白占每个 artifact 的 token。4 类规则（结构 / artifact / 测试 / 风险）的完整展开见 handbook 06。

**key 必须合法**。写成 `all` / `general` → 每次生成指令 warning 且规则永不注入（`src/core/project-config.ts:173-191` 的 `validateConfigRules`）。

## 回响 schema 的术语

专家手写 config 的最后一个维度：**用 schema 自己的词**。你的 `context`/`rules` 是给那个已经按 `spec-driven` schema instruction 工作的 agent 看的——说它听得懂的话，config 和 schema 互相强化；用另一套词，agent 收到的信号就分裂。完整 instruction 在 [`../../schemas/spec-driven/schema.yaml`](../../schemas/spec-driven/schema.yaml)。

**`context` 该 echo 的 cross-cutting 术语**（context 注入所有 artifact，所以用这些跨 artifact 的词）：

| 术语 | schema 里的含义 |
|---|---|
| `capability` | 一个 spec'd 的产品行为单元，kebab-case 命名，落地为 `specs/<name>/spec.md`。proposal 列出、specs 一对一物化（`schema.yaml:15-17`） |
| `requirement` | 规范、可测的语句，`### Requirement:` 下，用 SHALL/MUST，每个至少 1 个 scenario（`:48-52`） |
| `scenario` | requirement 下的 WHEN/THEN 测试用例，恰好 4 个 `#`（`:50-51`） |
| observable behavior | 用户能看到的对外行为——specs 描述的对象，区别于实现 |
| implementation details | "how"——明确不属于 proposal/specs，归 design/tasks（`:24-25`） |
| why / what / how | 海拔分工：proposal=why，specs=what，design=how（`:10,35,90`） |
| `BREAKING` | proposal 里标记破坏性变更的字面 token（`:14`） |
| testable / verifiable | 每个 scenario 是潜在测试；每个 task 完成时可判断（`:81,143`） |

**各 artifact `rules` 该 echo 的 signature 术语**：

| artifact | 该 echo 的词 |
|---|---|
| `proposal` | Why / What Changes / **BREAKING** / New·Modified **Capabilities** / kebab-case |
| `specs` | **delta ops**（ADDED/MODIFIED/REMOVED/RENAMED）/ `### Requirement:` / **SHALL/MUST**（避免 should/may）/ `#### Scenario:` WHEN/THEN |
| `design` | **Goals / Non-Goals** / Decisions（"why X over Y"）/ **Risk → Mitigation** / Migration Plan + rollback |
| `tasks` | checkbox `- [ ]` / `##` numbered headings / task group / dependency ordering |

**echo 要精确——这些词在 schema 里有定义含义，用俗义会坏**：

- `capability` 不是"feature"的同义词——它是 kebab-case 文件契约，proposal 和 specs 靠它一对一对接（`:20-22`）。
- `requirement` 要 SHALL/MUST + scenario；schema 明确 "avoid should/may"（`:49`）。
- `scenario` 必须**恰好 4 个 `#`**——用 3 个或 bullet 会**静默失败**（`:51`，schema 自己标了 CRITICAL）。
- `MODIFIED` 要**复制整个 requirement 块**，写部分会在 archive 时丢细节（`:60`）。
- `BREAKING` 是要往 proposal 里**注入的字面 token**，不是形容词（`:14`）。
- tasks 的 checkbox `- [ ]` 是 **apply 阶段解析的格式**——不这么写任务 "won't be tracked"（`:120-121`）。

**范例 + gap**：repo 自己的 [`../../openspec/config.yaml`](../../openspec/config.yaml) 已经 echo 了一部分——`context` 里 "user-facing product behavior language"（observable behavior）、"avoid implementation-negative SHALL statements"（SHALL）、"Put internal mechanisms in design.md"（implementation details，L9-12）。但它**漏了** delta ops、4-hashtag scenario、checkbox 格式、Non-Goals、Migration Plan——正好是机械性最强、写错静默失败的那些。专家手写时可以比 dogfood 更全。

## agent 作为 spot 助手

这是本文件的核心。专家把 agent 用在这四个点上，**没有一个让它当作者**：

### 1. review

让 agent 读你的 `config.yaml`，挑出毛病。专家自己看不出盲区时，让 agent 当冷眼读者。

```text
你：读 openspec/config.yaml。挑出：
    - 弱规则（像 "write clean code" 这种没对象的口号）
    - 太像 PRD 的 context（塞了具体功能而不是背景）
    - 不合法的 rules key（不在 proposal/specs/design/tasks 里）
    给我清单，我自己改。
```

### 2. 按需起草

你已经有方向，让 agent 出草稿，你精修后采纳。省掉从零写的体力，但**措辞你定**。

```text
你：给 specs 起草一条强规则，要求每个涉及授权的需求都带至少一个
    unauthorized 场景。用 "Changes affecting X must Y" 的格式。
    出 2 个候选，我挑一个改。
```

### 3. 校验

config 没有 `validate` 命令（`openspec schema validate` 只管 schema.yaml，不管 config）。专家的校验靠两样：让 agent 对照 schema 查 key，以及**跑 `openspec instructions` 看 warning**——那是 OpenSpec 唯一的被动反馈。

```text
你：对照 spec-driven schema，检查我 config.yaml 里 rules 的 key 是否都合法。
    然后跑 openspec instructions proposal --change <name> --json，
    看有没有 Unknown artifact ID 之类的 warning。
```

### 4. 覆盖度扫描

让 agent 读你最近的 `changes/` 和 `specs/`，找**反复出错**的地方——那些就该沉淀成 rule。这是把 agent 的"读代码"能力用在发现补录机会上，而不是写 rule 本身。

```text
你：扫 openspec/changes/ 最近 5 个 archived change 和它们的 specs。
    找出我在 review 时反复纠正 agent 的点（比如老漏 auth 影响、老不写 rollback）。
    提议哪些该补进 config.yaml 的 rules，按 artifact 分好。
    我看完决定加哪几条。
```

## 守则

- **你拍板每一条。** agent 提议 ≠ 采纳；review 出的毛病、起草的草稿、扫描的提议，都过你的判断。
- **保持强规则。** 有对象、有约束方向；砍掉口号。
- **`rules` 的 key 对齐 schema**（`proposal`/`specs`/`design`/`tasks`）。
- **`context` < 50KB**，只放不变背景。
- **reactive 优先**——用真实犯错的反馈补，不凭空规划一组。

## 更进一步：config 磨透了还不够？

config.yaml（context + rules）是**提示层**——它只能在 spec-driven schema 给定的 artifact 集合里收紧内容。当你的需求是**改工作流结构本身**（加 / 改名 / 删 artifact、重画依赖 DAG、改 apply 门、换 template 骨架），config 永远表达不了。那是结构层的事——见 [`answer-guru.md`](answer-guru.md)。

> 全部源码与文档引用集中在一个文件：[`sources.md`](sources.md)。
