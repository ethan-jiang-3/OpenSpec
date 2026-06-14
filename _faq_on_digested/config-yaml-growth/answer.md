# 答案：普通程序员怎么搞定 config.yaml

## 一句话

`config.yaml` 是目标项目里 `openspec/config.yaml` 这一个文件，定义项目 `context` 和各 artifact 的 `rules`。熟 SDD 的人直接手写它；但 **OpenSpec 给普通人的辅助几乎为零**——没有交互式引导、没有诊断命令、也没有指示 agent 帮你建。这是个真实的缺口，代码里那个写着 "Project-local config is not yet implemented" 的钩子已经在等它。

```text
三条路（专业度 ↑，对 agent 依赖 ↓）
  专家        人主笔，agent 只当 spot 助手   → answer-by-hand.md
  能人(半专业) agent 主笔，人给判断拍板        → answer-with-agent.md
  普通人      先读本文搞清现状（没辅助是真实缺口）
```

## 三条路：你是哪种读者？

先读本文搞清现状和缺口，再按你的情况挑一条路：

| 你是 | 谁写 config | agent 角色 | 去哪 |
|---|---|---|---|
| 普通 / 想先搞懂现状 | — | — | 本文（现状 + 缺口） |
| 能人（懂项目、会指挥 agent，非 SDD 专家） | **agent** | 作者 | [`answer-with-agent.md`](answer-with-agent.md) |
| 专家（SDD 熟手，要完全掌控） | **你** | spot 助手 | [`answer-by-hand.md`](answer-by-hand.md) |

## 先认清楚这个文件

`openspec/config.yaml` 在三层里属于**项目全局层**——"这个项目长期按什么原则开发"（另两层：`specs/` 是"系统现在会什么"，`changes/` 是"这次改什么"，细节见 [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md)）。它只有三个字段：

| 字段 | 作用 |
|---|---|
| `schema` | 用哪个工作流（默认 `spec-driven`） |
| `context` | 项目背景，注入到**所有** artifact 的指令 |
| `rules` | 按 artifact ID 分的约束，只注入给对应 artifact |

真实"长出来"的样子——这个 repo 自己 dogfood 的 [`openspec/config.yaml`](../../openspec/config.yaml)（OpenSpec 团队自己的成品）：

```yaml
schema: spec-driven

context: |
  Tech stack: TypeScript, Node.js (≥20.19.0), ESM modules
  Package manager: pnpm
  CLI framework: Commander.js

  Product language:
  - Write OpenSpec proposals and specs in user-facing product behavior language
  - Avoid implementation-negative SHALL statements when a positive outcome can express the same rule

  Cross-platform requirements:
  - This tool runs on macOS, Linux, AND Windows
  - Always use path.join() or path.resolve() for file paths - never hardcode slashes

rules:
  specs:
    - Requirements involving paths must specify cross-platform behavior
    - If we generate artifacts, specify deletion/modification by explicit list lookup, not pattern matching
  design:
    - Prefer explicit lookups over pattern matching or regex
    - If we generate it, we track it by name in a constant
```

`context` 分两块（产品语言 + 跨平台要求），`rules` 跨三个 artifact，每条都具体可执行。**这就是长出来的样子——但下面会讲，OpenSpec 没给你把它长出来的工具。**

## 普通人的路：现状几乎没有辅助

这才是问题核心。逐条对源码，普通人能用的辅助**几乎为零**：

**1. `openspec init` 不交互式问你。** 它只写一个 stub（`src/core/config-prompts.ts:9-39`，由 `src/core/init.ts:614` 的 `serializeConfig({ schema: DEFAULT_SCHEMA })` 生成）：

```yaml
schema: spec-driven

# Project context (optional)
# This is shown to AI when creating artifacts.
# Add your tech stack, conventions, style guides, domain knowledge, etc.
# Example:
#   context: |
#     Tech stack: TypeScript, React, Node.js
#     ...

# Per-artifact rules (optional)
# ...（同样是注释例子）
```

`schema` 那行是唯一真正生效的内容，`context` 和 `rules` **全是注释掉的示例**。init 全程不问你技术栈、不问领域、不问质量优先级。你被交给一个"两段都注释掉了"的文件。

**2. 还有个 doc bug 值得知道。** [`../../docs/customization.md`](../../docs/customization.md) 的 Quick Setup（`:22-27`）写着：

```text
### Quick Setup
openspec init
This walks you through creating a config interactively. Or create one manually:
```

但 init **根本不交互式创建 config**（见上条）。文档比代码超前了——它描述的是一个还不存在的功能。

**3. `openspec config` 是个陷阱。** 它名字看着就是干这个的（`config set / edit / reset / list`），但 `src/commands/config.ts:268-279`：

```text
.command('config')
.description('View and modify global OpenSpec configuration')   ← "global"
.hook('preAction', (cmd) => {
  if (opts.scope && opts.scope !== 'global') {
    console.error('Error: Project-local config is not yet implemented');
    process.exit(1);
  }
})
```

它只管**全局 JSON**（`~/.config/openspec/config.json`），不管项目 `config.yaml`。想加项目级 `context`/`rules`？代码直接 `process.exit(1)` 拒绝。**注意那句错误信息——代码自己预告了这是个"还没实现"的缺口。**

**4. 没有诊断/建议命令。** 仓库里有三个 `doctor`/`diagnostic`：`openspec workspace doctor`（查 workspace 链接）、`openspec context-store doctor`（查 context-store 注册）、`openspec initiative diagnostic`（查 initiative 查找）——**没有一个读 `config.yaml`**，也没有任何命令会读你的 `package.json`/源码去建议该写什么 context/rules。

**5. agent 不是被引导的路径。** 这是最反直觉的一条。你会想：让 Claude Code 帮我写不就行了？理论上能，但 **OpenSpec 的 skill 没有引导 agent 去做这件事**。证据：

- 所有 workflow 把 `context`/`rules` 当**只读消费**——`src/core/templates/workflows/propose.ts:64-65` 明确写 "`context`: Project background (constraints for you - **do NOT include in output**)"，`:103-105` 再强调 "do NOT copy `<context>`, `<rules>` blocks into the artifact"。agent 被告知的是"照着遵守"，不是"评估它够不够、帮你补"。
- `onboard` skill（`src/core/templates/workflows/onboard.ts`，573 行，11 个阶段）是引导新人的地方——但它**完全不提 `config.yaml`/`context`/`rules`**（grep 全文零匹配）。它教 change 生命周期，不教怎么配项目背景。
- 指令 JSON 里 `context`/`rules` 缺失时**静默省略**：`src/core/artifact-graph/instruction-loader.ts:319` 是 `const configContext = projectConfig?.context?.trim() || undefined;`——没配就是 `undefined`，agent 收到的指令里**没有任何"你的 context 是空的、建议补上"的提示**。

**6. 唯一的辅助：stub 注释 + 被动 warning + 一页文档。** warning 只在**你已经写坏**时触发：`rules` 的 key 写成不存在的 artifact ID（`src/core/project-config.ts:173-191` 的 `validateConfigRules` → `Unknown artifact ID in rules: "..."`），或 `context` 超 50KB（`:103-107`）。配置完全为空？不报警，系统认为那是正常状态。

```text
普通人的现实：
  init 给你 stub（context/rules 注释掉）
    + customization.md 一页例子（还含个 doc bug）
    + 写错了才有 warning
    - 没有交互式引导
    - 没有项目级 config 命令
    - agent 没被指示帮你建
```

## 那 agent 能不能帮上忙？

直接回答"是靠语言指令还是什么"——**现状两者都不算 OpenSpec 正式支持的功能**，但 agent 是当下唯一可行的"辅助"：它能读项目、看 stub 注释、照 `customization.md` 格式帮你补 config.yaml。不过这靠 agent 自己的聪明，**OpenSpec 没有 skill 引导它做这事**（`onboard` 全文不提 config）。

**怎么把这件"可行但没引导"的事做扎实**——按 config 的每个部分（`context` / 各 artifact 的 `rules`），用对的话术让 agent 逐块补录——展开在 [`answer-with-agent.md`](answer-with-agent.md)（能人路径，agent 当作者）。如果你是 SDD 专家、想自己掌控每一条，看 [`answer-by-hand.md`](answer-by-hand.md)（人主笔，agent 只当助手）。下面先把现状和缺口讲完。

## 真实缺口与最小改进

所以现状是个**真实缺口**：专家能用手写纪律补上，普通人没有结构化的辅助。两个改进方向，都建立在已有源码基础上，代价不大：

**方向 A：让 agent 帮——给 workflow 加一句引导。** 在 `onboard` 或 `explore` skill 里加一条："如果 `openspec/config.yaml` 的 `context` 为空，用 AskUserQuestion 问用户技术栈、领域、质量优先级，然后提议（不是替用户决定）一份 `context` 和初始 `rules`，让用户确认后写入。" 这复用了已有的 `readProjectConfig()` 读 + 文件写入，不改 CLI。

**方向 B：给 CLI 加项目级命令。** 实现 `config.ts:273-279` 那个 preAction 钩子已经在等的 `--scope project`：

```bash
openspec config context set "Tech stack: ..."
openspec config rule add proposal "Include rollback plan"
```

复用已有的 `readProjectConfig()`（`src/core/project-config.ts`，目前纯只读，需加一个 write）+ `stringifyYaml`（`schema.ts:878` 已有先例：parse-modify-restringify）。门槛低，且正好堵上那个 "not yet implemented"。

方向 A 让普通人**不用碰 YAML**（靠对话），方向 B 给愿意用命令行的人**结构化入口**。两者互补。

## 怎么写好 context 和 rules

四条要点（完整指南见 [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md)，机制见 [`../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md`](../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md)）：`context` 只放不变背景、不放 PRD；`rules` 用强公式 `Changes affecting <对象> must <约束>.`；`rules` 的 key 必须是合法 artifact ID（`spec-driven` 下是 `proposal`/`specs`/`design`/`tasks`，写成 `all`/`general` 会报警告且永不注入）；**用 schema 的术语**——`context`/`rules` 措辞对齐 `spec-driven` schema 的关键词（`capability`/`requirement`/`scenario`/`SHALL`/`BREAKING` 等），术语表见 [`answer-by-hand.md`](answer-by-hand.md) 的"回响 schema 的术语"。**具体怎么落到 config**——让 agent 当作者见 [`answer-with-agent.md`](answer-with-agent.md)，自己当作者见 [`answer-by-hand.md`](answer-by-hand.md)。

## 常见误区

### 误区 1：用 `openspec config set` 改项目 config.yaml

不行。`openspec config` 只管全局 JSON，对项目 yaml 是硬编码拒绝（`src/commands/config.ts:276`）。这个名字是最大的误导。

### 误区 2：以为 `openspec init` 会交互式引导你填 config

不会。init 全程不问 context/rules，只写 stub（`config-prompts.ts:9-39`）。`docs/customization.md:22-27` 说它 "walks you through creating a config interactively" 是个 doc bug——代码没这个功能。

### 误区 3：rules 的 key 写成 `all` / `general` / `common`

不行。`rules` 按 artifact ID 注入，`all` 不是合法 ID，规则永不生效还每次报警告（`project-config.ts:173-191`）。key 必须是你 schema 里真实的 artifact。

### 误区 4：把 PRD 塞进 context

不够。`context` 给所有 artifact 共享，PRD 细节会反复干扰。PRD 级需求放 `openspec/specs/`，proposal 里引用它。

### 误区 5：指望 agent 自动帮你建 config

不完全对。agent 理论上能写，但 OpenSpec 的 skill 没引导它这么做（`propose.ts` 只让它消费、`onboard.ts` 压根不提 config）。能不能成，取决于那个 agent 够不够主动——别假设它一定会。

## 结论

```text
1. config.yaml 是项目全局层：定义 context（所有 artifact 共享）+ rules（按 artifact）。
2. 三条路都用"边用边补"纪律（init 后不动 → 加 context → 每个 change 补 rules）：专家手写（[`answer-by-hand.md`](answer-by-hand.md)）、能人让 agent 写（[`answer-with-agent.md`](answer-with-agent.md)）。
3. 普通人现状几乎没有辅助：init 只写 stub、openspec config 只管全局、没有诊断、agent 没被引导。
4. agent 能帮，但靠它自己的本事，不是 OpenSpec 的功能——能人让它当作者，专家让它当 spot 助手。
5. 缺口真实存在，最小改进两条路：给 skill 加引导（方向 A）或实现 project-scope config 命令（方向 B，代码钩子已在等）。
```

## 参考来源

源码引用基于 commit `b1523ea`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/config-prompts.ts:9-39` | init 写的 stub 实际内容（`schema: spec-driven` + context/rules 注释示例） |
| `src/core/init.ts:598-620` | `createConfig()`：只在文件不存在时写 stub，不交互式收集 |
| `src/commands/config.ts:268-279` | `openspec config` 只管全局 JSON；preAction 钩子拒绝 project scope（*"Project-local config is not yet implemented"*） |
| `src/commands/schema.ts:870-887` | `schema init --default` 写 `defaultSchema`——init 外唯一写 config.yaml 的地方（不碰 context/rules） |
| `src/core/templates/workflows/propose.ts:64-65,103-105` | agent 把 context/rules 当只读约束（"do NOT include in output"） |
| `src/core/templates/workflows/onboard.ts` | onboard skill 全文不提 config.yaml/context/rules（grep 零匹配） |
| `src/core/artifact-graph/instruction-loader.ts:319-321` | context/rules 缺失时 `|| undefined` 静默省略，无"config 缺口"提示 |
| `src/core/project-config.ts:103-107,173-191` | 被动 warning：context 超 50KB / rules 用了未知 artifact ID（仅在已写坏时触发） |
| `openspec/config.yaml` | 真实范例：OpenSpec 团队 dogfood 自己工具长出来的成品 config |
| [`../../docs/customization.md`](../../docs/customization.md) | 官方手动写 config 的例子；`:22-27` 含 doc bug（虚假声称 init 交互式） |
| [`../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md`](../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md) | config.yaml 完整机制（Zod、注入、50KB、fail-open、误用） |
| [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) | 三层模型：config（项目全局）/ specs（当前能力）/ changes（本次变更） |
| [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) | 怎么写好：强规则公式、4 类规则、6 bad smell、4 种项目 sample |
| [`../../_openspec_handbook/04-高级-config-schema-与项目边界.md`](../../_openspec_handbook/04-高级-config-schema-与项目边界.md) | config（提示层）vs schema（结构层）的边界 |
