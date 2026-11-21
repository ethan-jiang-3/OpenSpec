# 答案：能人借助 agent，让 agent 当作者补 config.yaml

## 一句话

这条是给**能人**的——你懂自己的项目、会指挥 agent，但不是 SDD 专家。你让 **agent 当作者**（它读项目、起草、写 YAML），你给判断信息和拍板。和 [`answer-expert.md`](answer-expert.md) 的区别：那里 agent 是助手、你是作者；这里**反过来**。

为什么这是当下可行的路径：OpenSpec 没有 config 编辑工具（见 [`answer.md`](answer.md)），但 agent 能读项目、能看到 stub 注释和 `customization.md` 的格式、还能在 `openspec instructions` 的输出里看到当前 context/rules。OpenSpec 没引导它做这事，所以**引导它的任务落到你的话术上**。

还应让 agent 单独识别 `operations.apply.guidance` / `operations.archive.guidance`：前者放跨 change 的实施步骤，后者放归档前稳定检查；不要把它们误写成 artifact `rules`。

## 为什么 agent 是当下可行的路径

先把"可行"建立在事实上：

- **agent 能读你的项目来区分“可推断事实”与“需写入约束”**——它是 coding agent，有文件读取工具，能读 `package.json`、源码树、`README`、已有的 `openspec/specs/`。读代码就能看出来的客观事实不用抄进 `context`（`src/core/config-prompts.ts:25-27` 明确提醒把通用项目文档和可从代码库发现的事实留在 `context` 之外），agent 真正帮你的地方是结合项目现状帮你把**读代码推断不出来的硬约束**整理成规范 YAML。
- **agent 能看到 config 的格式**——`openspec init` 写的 stub（`src/core/config-prompts.ts:9-61`）里，`context`、`rules` 和 `operations` 虽是注释，但格式例子就在那；`docs/customization.md:29-46` 也有完整例子。agent 照着填不会跑偏。
- **agent 能看到当前 config 的状态**——它跑 `openspec instructions <artifact> --change <name> --json` 时，返回里带 `context` 和 `rules` 字段（`src/core/artifact-graph/instruction-loader.ts:415-416`）。空的就是 `undefined`，agent 能据此判断"项目还没配背景"。

缺的只有一样：**OpenSpec 没有 skill 提示 agent "context 空就去问用户、然后改 config.yaml"**（`onboard` skill 全文不提 config）。所以这个引导得你给——而且必须注意 **Explore 的只读护栏边界**（见下）。

## 最佳入口：在 Explore 里梳理全局约束，退出 Explore 后再落盘写 config

最顺的做法是分清「思考阶段」与「编辑阶段」：

1. **在 Explore 里梳理与提炼**——Explore 启动时会读取 `<root.path>/openspec/config.yaml` 的 `context` 和 `rules`（`explore.ts:156-160`），因此你可以在讨论中顺带问 agent 哪些约束属于跨所有 change 的全局原则、哪些只是当前 change 的局部事项。
2. **退出 Explore 模式后再让普通 coding agent 写入 `openspec/config.yaml`**——**绝不要在 `/openspec-explore` 会话内直接创建或编辑 `openspec/config.yaml`！** `src/core/templates/workflows/explore.ts:361` 的 Guardrails 明确写死：

   > `Workflow configuration counts too: creating or editing schemas, templates, or openspec/config.yaml is a change, not thinking. Creating or updating OpenSpec change artifacts within the confirmed scope is fine, writing anything else is not.`

```text
1. Explore 阶段（只梳理，不写 config.yaml）：
   问："结合项目现状，有哪些是读代码看不出来的跨 change 全局硬约束（该进 context），
       有哪些是我们反复踩坑的写作/设计要求（该进 rules 或 operations.*.guidance）？"
2. 退出 Explore（回到普通对话轮次，进入 propose 之前）：
   让 agent 按刚才确认的清单修改 openspec/config.yaml，并跑 openspec validate 检查 YAML 语法。
```

**为什么“先梳理、退出 Explore 写入、再进 propose”这条链路通（源码落地）：**

1. **Explore 擅长暴露跨模块边界与反复踩的坑，但它严守只读配置护栏。** `explore.ts:92-96, 125-128` 让 agent 梳理既有架构、集成点与潜在风险，并在 `:156-160` 读取当前 `config.yaml`；但 `:361` 禁止在 Explore 内改 `config.yaml`，capture 表（`:197-205`）和收尾（`:330-355`）也只针对 change 级 artifacts。因此 Explore 负责“想清楚要补哪几条”，不负责动配置文件。
2. **退出 Explore 写完即刻对后续 propose 生效。** `config.yaml` 在 `propose` 的 `openspec context --json` 预检后（`propose.ts:60-65`）以及每次 `openspec instructions` 调用时（`instruction-loader.ts:369-402`）都会实时重读，不用重启、不用 re-init。

## 通用补录循环（在普通 coding agent 对话中执行，不在 Explore 内）

谈清楚"该改什么"并退出 Explore 之后，让普通 agent 落地写进 config 就是这几步（不管补哪一部分）：

```text
1. 让 agent 读当前 openspec/config.yaml   → 看哪些字段是空的
2. 让 agent 读项目事实                      → package.json / 源码 / README / 已有 specs
3. 你补判断性信息                           → 领域、质量优先级、上次哪里出错
4. agent 起草 YAML 片段（不是替你决定）
5. 你确认 → agent 写入
```

关键在第 3、5 步：**判断性的东西你给，执行（写 YAML）agent 干，拍板你做。** 别让 agent 静默重写整个文件。

## 补 `schema`

一行：默认就是 `spec-driven`，绝大多数项目不用动。只有当你 fork/建了自定义 schema 才需要改（那走 `openspec schema` 那条路，见 [`../../_openspec_handbook/21-高级-config-schema-与项目边界.md`](../../_openspec_handbook/21-高级-config-schema-与项目边界.md)）。

## 补 `context`（项目背景）

`context` 是注入**所有** artifact 的不变背景。补它的分工：

如果项目尚未有 `openspec/config.yaml`，且当前只需要固定 artifact prose 的语言，可先运行：

```bash
openspec init --language "Japanese (ja-JP)"
```

这是 greenfield seed。已有 config 的 brownfield 项目会被拒绝覆盖，应让 agent 在现有 `context` 中手工加入同类 guidance。无论哪条路径，本地化的是 prose；Markdown 结构 heading、`SHALL`/`MUST` 规范关键词保持英文。

`src/core/config-prompts.ts:25-27` 对 `context` 给出了非常关键的官方边界：

```yaml
# Add only constraints that should guide OpenSpec artifacts and workflows.
# Include constraints an agent cannot infer by reading the code.
# Keep general project documentation and discoverable codebase facts out.
```

因此补 `context` 的分工不是让 agent 把 `package.json` 依赖表抄进去，而是过滤掉可发现事实、只留下**读代码看不出来的全局硬约束**：

| 谁负责 | 做什么 |
|---|---|
| **agent 先读代码做减法** | 先看清仓库里已经能直接读到的目录结构、框架、脚本——**这些可推断事实不要重复塞进 `context`**（最多一行点明目标运行门槛，如跨平台支持或最低运行时版本） |
| **你必须告诉它（真正该进 `context` 的内容）** | 读代码推断不出来的约束：业务领域边界、质量优先级（如鉴权正确性优先于吞吐）、向后兼容红线、产物语言与产品表达要求 |

话术示例：

```text
你：先读一下 openspec/config.yaml 注释和项目结构，把读代码就能发现的常规事实排除掉。
    只把下面这些读代码推断不出来的硬约束整理成不超过 8 行的 context：
    - 这是内部采购审批平台，最优先保证 authorization 正确性和审计可追溯；
    - 所有 public API 必须保持向后兼容；
    - 涉及路径的设计与测试必须同时覆盖 macOS、Linux 和 Windows。
    起草给我确认后再写进 openspec/config.yaml。
```

要让 agent **避开**：通用项目文档、读源码就能发现的目录/依赖清单、PRD 级的详细功能、本次 change 的目标、容易变的东西——这些塞进 `context` 只会浪费并稀释每个 artifact 的指令。详细需求放 `openspec/specs/`。

长度红线：`context` 有 **50KB 硬上限**，超了整段被忽略并 warning（`src/core/project-config.ts:256` `MAX_CONTEXT_SIZE`，超限 warn 并丢弃在 `:357-363`）。实践上保持在半屏以内。

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

**按 artifact 角色给方向**（让 agent 知道每个 artifact 该约束什么，细节见 [`../../_openspec_handbook/23-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/23-高级-config-yaml-怎么写到真正好用.md)）：

| artifact | 该约束什么 | 强规则示例 |
|---|---|---|
| `proposal` | scope（影响范围） | `Changes affecting authorization must reference existing auth spec requirements.` |
| `specs` | 行为完整性 | `Every requirement must include at least one unhappy-path scenario.` |
| `design` | 技术决策质量 | `Design decisions must note the rejected alternative and why.` |
| `tasks` | 可追踪性 | `Each task group must reference the spec requirement it implements.` |

**key 必须是合法 artifact ID。** 让 agent 补完 `rules` 后，对照 schema 检查 key——写成 `all` / `general` 这类，每次生成指令会 warning 且规则永不注入（`src/core/project-config.ts:514-531` 的 `validateConfigRules`，由 `instruction-loader.ts:381-394` 用**所有已安装 schema 的 artifact ID 并集**校对）。

## 让 agent 用 schema 的术语

agent 写 config 时容易发明新词或用泛义词（把 `capability` 写成 "feature"、把 `requirement` 写成 "need"）。这会让 config 和 schema 的 instruction 信号分裂。给 agent 一条明确指示：**用 `spec-driven` schema 自己的词**——`capability` / `requirement` / `scenario` / `SHALL` / `observable behavior` / `BREAKING` / `Non-Goals` 等。话术：

```text
你：写 context 和 rules 时，用 openspec spec-driven schema 里的术语
    （capability、requirement、scenario、SHALL、observable behavior、BREAKING、Non-Goals），
    别用 feature/need 这种泛义词。先读 schemas/spec-driven/schema.yaml 确认措辞。
```

完整术语表（哪些该进 `context`、哪些该进各 artifact 的 `rules`）见 [`answer-expert.md`](answer-expert.md) 的"回响 schema 的术语"。

## 补录的节奏：什么时候做

绑在 change 生命周期之间，**不要一次写满**，并且严格遵守“Explore 内只梳理、退出 Explore 再写文件”：

```text
openspec init                    → 不动 config（schema 一行或 --language 够用）
Explore 阶段（只读 config.yaml） → 顺带梳理："有哪些读代码看不出的全局约束或反复踩的坑？"
退出 Explore / 每轮归档复盘后     → 在普通 agent 对话里把确认过的约束补进 context / rules / operations，
                                   并跑 openspec validate 确认 YAML 未写坏
```

为什么这样可行：`config.yaml` 每次 `openspec instructions` 都重读、即时生效；字段级类型问题在 `status` / `instructions` 侧会逐字段 warn 降级，而文件不可读或非法 YAML 语法会被 `openspec validate`（v1.16.0 `#2127`，`readConfigParseError()`）以退出码 1 及时拦住。所以你能靠真实使用一点点收敛，不用开局就写满。这和专家手写的纪律是同一条（见 [`answer-expert.md`](answer-expert.md)），只是这里把"起草 YAML"这步交给了 agent。

## 守则

- **agent 提议，你拍板。** 别让它静默重写整个 `config.yaml`；让它起草片段、你确认。
- **保持强规则。** 有对象、有约束方向；砍掉 `clean` / `proper` / `best practice` 这类口号。
- **`context` 不超 50KB**，且只放不变背景。
- **`rules` 的 key 对齐 schema**（`proposal` / `specs` / `design` / `tasks`）。
- **reactive 优先于 proactive**——用真实犯错的反馈补，不凭空规划。

> 全部源码与文档引用集中在一个文件：[`sources.md`](sources.md)。
