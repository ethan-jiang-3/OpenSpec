# 答案：能人借助 agent，让 agent 当作者补 config.yaml

## 一句话

这条是给**能人**的——你懂自己的项目、会指挥 agent，但不是 SDD 专家。你让 **agent 当作者**（它读项目、起草、写 YAML），你给判断信息和拍板。和 [`answer-by-hand.md`](answer-by-hand.md) 的区别：那里 agent 是助手、你是作者；这里**反过来**。

为什么这是当下可行的路径：OpenSpec 没有 config 编辑工具（见 [`answer.md`](answer.md)），但 agent 能读项目、能看到 stub 注释和 `customization.md` 的格式、还能在 `openspec instructions` 的输出里看到当前 context/rules。OpenSpec 没引导它做这事，所以**引导它的任务落到你的话术上**。

## 为什么 agent 是当下可行的路径

先把"可行"建立在事实上：

- **agent 能读你的项目**——它是 coding agent，有文件读取工具，能读 `package.json`、源码树、`README`、已有的 `openspec/specs/`。技术栈这类事实它能自己推断。
- **agent 能看到 config 的格式**——`openspec init` 写的 stub（`src/core/config-prompts.ts:9-39`）里，`context` 和 `rules` 虽是注释，但格式例子就在那；`docs/customization.md:29-46` 也有完整例子。agent 照着填不会跑偏。
- **agent 能看到当前 config 的状态**——它跑 `openspec instructions <artifact> --json` 时，返回里带 `context` 和 `rules` 字段（`src/core/artifact-graph/instruction-loader.ts:335-336`）。空的就是 `undefined`，agent 能据此判断"项目还没配背景"。

缺的只有一样：**OpenSpec 没有 skill 提示 agent "context 空就去问用户、然后改 config.yaml"**（`onboard` skill 全文不提 config）。所以这个引导得你给。

## 通用补录循环

不管补哪一部分，都是这五步：

```text
1. 让 agent 读当前 openspec/config.yaml   → 看哪些字段是空的
2. 让 agent 读项目事实                      → package.json / 源码 / README / 已有 specs
3. 你补判断性信息                           → 领域、质量优先级、上次哪里出错
4. agent 起草 YAML 片段（不是替你决定）
5. 你确认 → agent 写入
```

关键在第 3、5 步：**判断性的东西你给，执行（写 YAML）agent 干，拍板你做。** 别让 agent 静默重写整个文件。

## 补 `schema`

一行：默认就是 `spec-driven`，绝大多数项目不用动。只有当你 fork/建了自定义 schema 才需要改（那走 `openspec schema` 那条路，见 [`../../_openspec_handbook/04-高级-config-schema-与项目边界.md`](../../_openspec_handbook/04-高级-config-schema-与项目边界.md)）。

## 补 `context`（项目背景）

`context` 是注入**所有** artifact 的不变背景。补它的分工：

| 谁负责 | 补什么 |
|---|---|
| **agent 自己推断** | 技术栈、语言、框架、包管理器（读 `package.json` 就有） |
| **你必须告诉它** | 领域（产品到底是什么）、质量优先级（你优先保证什么）、兼容性约束 |

话术示例：

```text
你：读一下 package.json 和 src/ 的结构，然后我告诉你这个产品的领域。
    我这是个内部采购审批平台；我们最优先保证的是 authorization 正确性和审计可追溯；
    所有 public API 必须向后兼容。
    照 openspec/config.yaml 里注释的 context 格式，起草一份不超过 8 行的 context，
    给我确认后写进去。
```

要让 agent **避开**：PRD 级的详细功能、本次 change 的目标、容易变的东西——这些塞进 `context` 会污染每个 artifact 的指令。详细需求放 `openspec/specs/`。

长度红线：`context` 有 **50KB 硬上限**，超了整段被忽略并 warning（`src/core/project-config.ts:103-107`）。实践上保持在半屏以内。

## 补 `rules`（按 artifact）

这是补录的主战场，也是最容易写废的部分。`rules` 按 artifact ID 分别注入——`spec-driven` 下合法的 key 是 `proposal` / `specs` / `design` / `tasks`。

**两种时机：**

```text
reactive（推荐）：每做完一个 change，看 agent 在哪反复犯错
                  → "上次 proposal 你漏了 auth 影响、没写 rollback，加进 rules"
proactive（可选）：初始时让 agent 基于项目提议一组
                  → "基于这个项目，给每个 artifact 提 1-2 条防常见错误的 rules"
```

reactive 比 proactive 靠谱——因为它是真实使用反馈沉淀的，不是凭空规划。

**让 agent 写强规则，不写口号。** 直接告诉 agent 公式：

```text
强规则 = "Changes affecting <对象> must <约束>."
        或 "Do not <危险行为> unless <例外>."

弱规则（禁止）= "Write clean code" / "Follow best practices"
              ↑ 没对象、没约束方向，agent 本来就会做，白占每个 artifact 的 token。
```

**按 artifact 角色给方向**（让 agent 知道每个 artifact 该约束什么，细节见 [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md)）：

| artifact | 该约束什么 | 强规则示例 |
|---|---|---|
| `proposal` | scope（影响范围） | `Changes affecting authorization must reference existing auth spec requirements.` |
| `specs` | 行为完整性 | `Every requirement must include at least one unhappy-path scenario.` |
| `design` | 技术决策质量 | `Design decisions must note the rejected alternative and why.` |
| `tasks` | 可追踪性 | `Each task group must reference the spec requirement it implements.` |

**key 必须是合法 artifact ID。** 让 agent 补完 `rules` 后，对照 schema 检查 key——写成 `all` / `general` 这类，每次生成指令会 warning 且规则永不注入（`src/core/project-config.ts:173-191` 的 `validateConfigRules`）。

## 让 agent 用 schema 的术语

agent 写 config 时容易发明新词或用泛义词（把 `capability` 写成 "feature"、把 `requirement` 写成 "need"）。这会让 config 和 schema 的 instruction 信号分裂。给 agent 一条明确指示：**用 `spec-driven` schema 自己的词**——`capability` / `requirement` / `scenario` / `SHALL` / `observable behavior` / `BREAKING` / `Non-Goals` 等。话术：

```text
你：写 context 和 rules 时，用 openspec spec-driven schema 里的术语
    （capability、requirement、scenario、SHALL、observable behavior、BREAKING、Non-Goals），
    别用 feature/need 这种泛义词。先读 schemas/spec-driven/schema.yaml 确认措辞。
```

完整术语表（哪些该进 `context`、哪些该进各 artifact 的 `rules`）见 [`answer-by-hand.md`](answer-by-hand.md) 的"回响 schema 的术语"。

## 补录的节奏：什么时候做

绑在 change 生命周期上，**不要一次写满**：

```text
openspec init                → 不动 config（schema 一行够用）
第一个 change 之前            → 补 context（4 行背景）
每 archive 一个 change 之后   → review：我这次反复纠正了 agent 什么？
                              把最痛的 1 条补进对应 artifact 的 rules
```

为什么这样可行：`config.yaml` 每次 `openspec instructions` 都重读、即时生效、写错不崩（fail-open）。所以你能靠真实使用一点点收敛，不用开局就写对。这和专家手写的纪律是同一条（见 [`answer-by-hand.md`](answer-by-hand.md)），只是这里把"写"这步交给了 agent。

## 守则

- **agent 提议，你拍板。** 别让它静默重写整个 `config.yaml`；让它起草片段、你确认。
- **保持强规则。** 有对象、有约束方向；砍掉 `clean` / `proper` / `best practice` 这类口号。
- **`context` 不超 50KB**，且只放不变背景。
- **`rules` 的 key 对齐 schema**（`proposal` / `specs` / `design` / `tasks`）。
- **reactive 优先于 proactive**——用真实犯错的反馈补，不凭空规划。

## 参考来源

源码引用基于 commit `b1523ea`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/config-prompts.ts:9-39` | init stub 里 context/rules 的注释格式——agent 照此填 |
| `src/core/artifact-graph/instruction-loader.ts:335-336` | `openspec instructions` 返回带 context/rules 字段——agent 能看到当前状态 |
| `src/core/project-config.ts:103-107` | context 50KB 硬上限，超了忽略 + warning |
| `src/core/project-config.ts:173-191` | `validateConfigRules`：rules 用未知 artifact ID 会 warning 且不注入 |
| [`../../docs/customization.md`](../../docs/customization.md) | context/rules 的完整格式例子（`:29-46`） |
| [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) | 强规则公式、4 类规则、各 artifact 该约束什么 |
| [`../../_openspec_handbook/04-高级-config-schema-与项目边界.md`](../../_openspec_handbook/04-高级-config-schema-与项目边界.md) | config（提示层）vs schema（结构层） |
| [`answer.md`](answer.md) | 现状盘点与缺口（为什么需要这条 agent 路径） |
| [`answer-by-hand.md`](answer-by-hand.md) | 另一条路：专家自己写，agent 只当 spot 助手 |
