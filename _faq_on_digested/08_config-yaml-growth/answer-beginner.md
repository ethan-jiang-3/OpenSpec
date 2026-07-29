# 答案：普通程序员怎么搞定 config.yaml

## 一句话

你是普通程序员（不熟 SDD 细节，也不想精通 config）。先说结论：OpenSpec 给 config.yaml 的辅助几乎为零，但 **config 基本为空也能跑**，而且最省力的路是**抄一个有经验的人的 config.yaml 改改**，不用从零写。撞墙了再升级到 [`answer-intermediate.md`](answer-intermediate.md)。

## 先认清楚这个文件

`openspec/config.yaml` 在三层里属于**项目全局层**——“这个项目长期按什么原则开发”（另两层：`specs/` 是“系统现在会什么”，`changes/` 是“这次改什么”，细节见 [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md)）。对日常作者最重要的字段有：

| 字段 | 作用 |
|---|---|
| `schema` | 用哪个工作流（默认 `spec-driven`） |
| `context` | 项目背景，注入到**所有** artifact 的指令 |
| `rules` | 按 artifact ID 分的约束，只注入给对应 artifact |
| `operations.apply.guidance` | v1.7.0 的 Apply 专属项目指引，和 context 一起进入 apply instructions |
| `operations.archive.guidance` | v1.7.0 的 Archive 专属项目指引，和 context 一起进入 archive instructions |

`rules.apply` / `rules.archive` 不会生效；Explore 会读取 `context` / artifact `rules`，但没有 `operations.explore`。

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

operations:
  apply:
    guidance:
      - Run the relevant tests before marking a task complete.
  archive:
    guidance:
      - Review migration and rollback notes before confirming archive.
```

`context` 分两块（产品语言 + 跨平台要求），`rules` 跨三个 artifact，每条都具体可执行；`operations` 只放 Apply/Archive 真正需要的稳定步骤。**这就是长出来的样子——也是你下面该抄的范本。**

## 普通人的路：现状几乎没有辅助

先认清处境（这样你不会怪自己）。逐条对源码，普通人能用的辅助**几乎为零**：

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

`schema` 那行是唯一真正生效的内容，`context` 和 `rules` **全是注释掉的示例**。init 全程不问你技术栈、不问领域、不问质量优先级。

**2. `openspec config` 是个陷阱。** 它名字看着就是干这个的（`config set / edit / reset / list`），但 `src/commands/config.ts:268-279`：

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

它只管**全局 JSON**（`~/.config/openspec/config.json`），不管项目 `config.yaml`。想加项目级 `context`/`rules`？代码直接 `process.exit(1)` 拒绝。

**3. 没有诊断/建议命令。** `openspec doctor` 检查 store 健康状态，**不读 `config.yaml`**，也没有命令读你的 `package.json`/源码去建议该写什么。

**4. agent 没有被引导到这条路径。** 你会想：让 Claude Code 帮我写不就行了？理论上能，但 **OpenSpec 的 skill 没引导 agent 去做这件事**——所有 workflow 把 `context`/`rules` 当**只读消费**（`propose.ts:64-65` "do NOT include in output"），`onboard` skill 全文不提 config。而且指令里 context/rules 缺失时**静默省略**，没有"你的 context 是空的、建议补上"的提示（`instruction-loader.ts:319`）。

```text
普通人的现实：
  init 给你 stub（context/rules 注释掉）
    + customization.md 一页例子
    + 写错了才有 warning
    - 没有交互式引导
    - 没有项目级 config 命令
    - agent 没被指示帮你建
```

这不是你的错，是 OpenSpec 当前的产品缺口。

## 普通人现实能干啥

现状是"几乎没辅助"，但别慌——你能跑起来，而且有一条最省力的路：**别从零写，去抄一个有经验的人的 config.yaml**。

1. **接受 config 基本为空也能跑。** stub 里 `schema: spec-driven` 一行够用，spec-driven 默认工作流就能起步，第一个 change 不需要任何 context/rules。
2. **抄一个有经验的人的 config.yaml，改成你的项目。** 这是最现实的路——让别人踩过的坑、沉淀的 context/rules 给你打底，你只改技术栈/领域。去哪找：
   - 这个 repo 自己的 [`../../openspec/config.yaml`](../../openspec/config.yaml)——OpenSpec 团队 dogfood 的成品，最现成的范本（就是上面那段）。
   - 你团队里已经在用 openspec 的项目，或同事的 config。
   - [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) 末尾有 4 种项目类型（审批系统 / API 平台 / SaaS 控制台 / 数据编排）的完整 sample config，挑最像你项目的抄。

   抄来后只改 `context` 里的技术栈/领域/质量优先级；`rules` 先原样保留，等你用一阵、看懂每条在卡什么，再动。
3. **rules 先别自己发明。** 抄来的先用着；真要加新规则，照着抄来的格式写——key 用真实的 artifact ID（`proposal`/`specs`/`design`/`tasks`），别发明 `all`/`general`/`apply`/`archive` 这种（不会作为 artifact rule 生效）。Apply/Archive 的稳定步骤放到上面的 `operations.*.guidance`。
4. **撞墙了再升级。** 当你想精确控制产出，或 agent 老犯同类错而你又不会改 rules——升级到 [`answer-intermediate.md`](answer-intermediate.md)（让 agent 帮你建/改 config）。熟 SDD 的话直接 [`answer-expert.md`](answer-expert.md)。

为什么这样 OK：config 每次 `openspec instructions` 都重读、即时生效、写错不崩（fail-open）。所以抄一份先用着、慢慢改，比从零写靠谱得多，也**不必提前焦虑**。

## 那 agent 能不能帮上忙？

直接回答"是靠语言指令还是什么"——**现状两者都不算 OpenSpec 正式支持的功能**，但 agent 是当下唯一可行的"辅助"：它能读项目、看 stub 注释、照 `customization.md` 格式帮你补 config.yaml。不过这靠 agent 自己的聪明，**OpenSpec 没有 skill 引导它做这事**。

**怎么把这件"可行但没引导"的事做扎实**——按 config 的每个部分用对的话术让 agent 逐块补录——展开在 [`answer-intermediate.md`](answer-intermediate.md)（能人路径，agent 当作者）。如果你是 SDD 专家、想自己掌控每一条，看 [`answer-expert.md`](answer-expert.md)。

## 想自己写或大改？

抄来的 config 用一阵后，如果你想自己写 context/rules 或大改——那就是 intermediate/expert 的活了。强规则公式（`Changes affecting <对象> must <约束>.`）、回响 schema 术语、6 个 bad smell 这些 craft 见 [`answer-intermediate.md`](answer-intermediate.md) 和 [`answer-expert.md`](answer-expert.md)。普通人阶段不用纠结这些。

## 常见误区

### 误区 1：用 `openspec config set` 改项目 config.yaml

不行。`openspec config` 只管全局 JSON，对项目 yaml 是硬编码拒绝（`src/commands/config.ts:276`）。这个名字是最大的误导。

### 误区 2：以为 `openspec init` 会交互式引导你填 config

不会。init 全程不问 context/rules，只写 stub（`config-prompts.ts:9-39`）。`docs/customization.md:22-27` 说它 "walks you through creating a config interactively" 是个 doc bug——代码没这个功能。

## 结论

```text
1. config.yaml 是项目全局层：定义 context（所有 artifact 共享，也给 Apply/Archive）+ rules（按 artifact）+ operations guidance（仅 Apply/Archive）。
2. 普通人现状几乎没有辅助（init stub / config 陷阱 / agent 没引导）——这是 OpenSpec 的产品缺口，不是你的错。
3. 最省力的路：别从零写，抄一个有经验的人的 config.yaml（dogfood 范本 / 同事的 / handbook 06 的 sample），改改技术栈和领域先用着。
4. config 基本为空也能跑；撞墙了（要精确控制 / agent 老犯同类错）再升级 intermediate（agent 帮你建）或 expert（自己写）。
5. 怎么从产品源头补这个缺口（给 skill 加引导 / 加 CLI 命令）是 contributor 级的事，见 answer-expert.md。
```

> 全部源码与文档引用集中在一个文件：[`sources.md`](sources.md)。
