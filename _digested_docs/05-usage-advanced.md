# 05 · 进阶使用（Expanded Profile + 工具语法）

> 回 [导读](00-index.md) · [FAQ](FAQ.md)

本文覆盖扩展命令（7 个，需要切到 `custom` profile），以及 28 个 coding agent 的命令语法差异。日常使用在 [04-usage-basic.md](04-usage-basic.md)。

## 目录

- [§1 Expanded 7 个扩展命令](#1-expanded-7-个扩展命令)
- [§2 Expanded 路径典型流程](#2-expanded-路径典型流程)
- [§3 Workflow ↔ Skill ↔ Command 三对映射](#3-workflow--skill--command-三对映射)
- [§4 `openspec-` vs `opsx-` 前缀之辨](#4-openspec--vs-opsx--前缀之辨)
- [§5 Trae 深挖](#5-trae-深挖)
- [§6 Cline 深挖](#6-cline-深挖)
- [§7 OpenCode 深挖](#7-opencode-深挖)
- [§8 GitHub Copilot 的特殊坑](#8-github-copilot-的特殊坑)
- [§9 选工具的速查心法](#9-选工具的速查心法)

---

## §1 Expanded 7 个扩展命令

开启方式：

```bash
openspec config profile   # 交互式勾选要启用的 workflow
openspec update            # 让项目目录生效
```

`ALL_WORKFLOWS` 一共 11 个，除了 core 的 4 个（propose / explore / apply / archive），还有下面这 7 个（见 [src/core/profiles.ts](../src/core/profiles.ts)）：

```
new / continue / ff / verify / sync / bulk-archive / onboard
```

### `/opsx:new`

**一句话**：只搭骨架（scaffold），不生成任何 artifact，等你用 `/opsx:continue` 或 `/opsx:ff` 继续。

**语法**：`/opsx:new [change-name] [--schema <schema-name>]`

**产物**：
```
openspec/changes/<change-name>/
└── .openspec.yaml   # change 元数据（schema + 创建时间）
```

然后 AI 会告诉你「下一个可创建的 artifact 是 proposal」。

**用途**：想对每个 artifact 都做 review，或者想先把空壳 commit 一下。

### `/opsx:continue`

**一句话**：**查依赖图、建下一个 ready 的 artifact**。

**语法**：`/opsx:continue [change-name]`

**做了什么**：
1. 跑 `openspec status --json` 看哪些 artifact 是 ready
2. 读已经完成的依赖 artifact（给 AI 当上下文）
3. 创建**一个** artifact
4. 显示「现在解锁了什么」

**典型输出**：
```text
Artifact status:
✓ proposal    (done)
◆ specs       (ready)
◆ design      (ready)
○ tasks       (blocked - needs: specs)

Creating specs...
✓ Created openspec/changes/add-dark-mode/specs/ui/spec.md

Now available: tasks
```

**用途**：复杂 change，想一步一 review。

### `/opsx:ff`

**一句话**：快进——一次把**所有**规划 artifact 全部建完。

**语法**：`/opsx:ff [change-name]`

**做了什么**：按 DAG 拓扑顺序，一次性生成 proposal → specs → design → tasks，每建一个都读前置的内容再生成。

**和 `/opsx:propose` 的区别**：
- `/opsx:propose` = `/opsx:new` + `/opsx:ff` 的合体，用于 core profile
- `/opsx:ff` 用在 expanded profile，前提是已经用 `/opsx:new` 建好了骨架

### `/opsx:verify`

**一句话**：实现做完后，**从三个维度检查代码是否匹配 artifact**。

**语法**：`/opsx:verify [change-name]`

**三个维度**：

| 维度 | 校验什么 |
|------|----------|
| **Completeness（完整性）** | tasks 都打勾了？specs 里所有 requirement 都有代码？scenario 都覆盖了？ |
| **Correctness（正确性）** | 实现和 spec intent 一致？边界 case 处理了？错误状态符合 spec？ |
| **Coherence（一致性）** | 代码的架构体现了 design 里的决策？命名和 design 一致？ |

**输出**：按 CRITICAL / WARNING / SUGGESTION 分类的问题单，**不阻塞 archive**，只提醒。

**用途**：归档前兜底，尤其是让 AI 帮你检查 AI 自己写的代码。

### `/opsx:sync`

**一句话**：把 change 里的 delta spec 合并到主 `openspec/specs/`，但**不归档 change**。

**语法**：`/opsx:sync [change-name]`

**大多数人不需要用**——`/opsx:archive` 已经会问你要不要 sync。

**需要手动 sync 的场景**（见 [docs/commands.md](../docs/commands.md)）：
- 长周期 change，想让主 specs 先跟进
- 多个并行 change 需要基于最新的主 specs
- 想单独 review merge 结果

### `/opsx:bulk-archive`

**一句话**：一次归档多个 change，并且能**检测和解决 spec 冲突**。

**语法**：`/opsx:bulk-archive [change-names...]`

**做了什么**：
1. 列出所有已完成的 change
2. 检查多个 change 是否 touch 同一个 spec（冲突预警）
3. 按实际代码来 agentic 地解决冲突
4. 按创建时间顺序合并

**用途**：并行工作流、团队协作、批量收尾。

### `/opsx:onboard`

**一句话**：**交互式教程**，用你自己的代码库走一遍完整工作流。

**语法**：`/opsx:onboard`

**11 个阶段**（来自 [docs/commands.md](../docs/commands.md)）：

1. 欢迎 + 代码库分析
2. 找一个真实的改进机会
3. `/opsx:new` 创建 change
4. 写 proposal
5. 写 specs
6. 写 design
7. 写 tasks
8. `/opsx:apply` 真的实现
9. `/opsx:verify` 真的验证
10. `/opsx:archive` 真的归档
11. 总结 + 下一步

**用时**：15–30 分钟，新人上手最快的路。

---

## §2 Expanded 路径典型流程

```
/opsx:explore
      ↓
/opsx:new add-feature
      ↓
/opsx:ff  或  /opsx:continue（反复若干次）
      ↓
/opsx:apply
      ↓
/opsx:verify   ← 可选但推荐
      ↓
/opsx:sync     ← 通常不需要手动
      ↓
/opsx:archive  或  /opsx:bulk-archive
```

决策指南（何时 ff / 何时 continue / 何时开新 change）见 [04-usage-basic.md §4](04-usage-basic.md#4-决策树什么时候用什么)。

---

## §3 Workflow ↔ Skill ↔ Command 三对映射

OpenSpec 装到项目里后，每个 workflow 会落地成**两种产物**：

1. **Skill** —— 放在 `.{tool}/skills/openspec-*/SKILL.md`，agent 自动发现
2. **Command** —— 放在 `.{tool}/commands/opsx-*.md`（路径因工具而异），可以在 AI 聊天里用斜杠命令触发

映射关系的源码在 [src/core/shared/skill-generation.ts](../src/core/shared/skill-generation.ts) 的 `getSkillTemplates` 和 `getCommandTemplates`。模板本体在 [src/core/templates/workflows/](../src/core/templates/workflows/)。

### 完整映射表

| Workflow ID | 斜杠命令（Claude 风格） | Skill 目录名 | 模板文件 | Profile |
|-------------|------------------------|------------|---------|---------|
| `propose` | `/opsx:propose` | `openspec-propose` | [propose.ts](../src/core/templates/workflows/propose.ts) | core |
| `explore` | `/opsx:explore` | `openspec-explore` | [explore.ts](../src/core/templates/workflows/explore.ts) | core |
| `apply` | `/opsx:apply` | `openspec-apply-change` | [apply-change.ts](../src/core/templates/workflows/apply-change.ts) | core |
| `archive` | `/opsx:archive` | `openspec-archive-change` | [archive-change.ts](../src/core/templates/workflows/archive-change.ts) | core |
| `new` | `/opsx:new` | `openspec-new-change` | [new-change.ts](../src/core/templates/workflows/new-change.ts) | expanded |
| `continue` | `/opsx:continue` | `openspec-continue-change` | [continue-change.ts](../src/core/templates/workflows/continue-change.ts) | expanded |
| `ff` | `/opsx:ff` | `openspec-ff-change` | [ff-change.ts](../src/core/templates/workflows/ff-change.ts) | expanded |
| `verify` | `/opsx:verify` | `openspec-verify-change` | [verify-change.ts](../src/core/templates/workflows/verify-change.ts) | expanded |
| `sync` | `/opsx:sync` | `openspec-sync-specs` | [sync-specs.ts](../src/core/templates/workflows/sync-specs.ts) | expanded |
| `bulk-archive` | `/opsx:bulk-archive` | `openspec-bulk-archive-change` | [bulk-archive-change.ts](../src/core/templates/workflows/bulk-archive-change.ts) | expanded |
| `onboard` | `/opsx:onboard` | `openspec-onboard` | [onboard.ts](../src/core/templates/workflows/onboard.ts) | expanded |

### 命名规律

- **Skill 目录**：统一前缀 `openspec-`，后缀是完整动作名（比如 `openspec-archive-change` 而不是 `openspec-archive`）
- **斜杠命令**：前缀 `opsx:`（或 `opsx-`，看工具），后缀是**短 id**（`archive`、`bulk-archive`）
- 两者都由同一个 `workflowId` 驱动，在源码里是字符串 id（见 [src/core/profiles.ts](../src/core/profiles.ts) 的 `ALL_WORKFLOWS`）

### 为什么有 skill 又有 command

| | Skill | Command |
|---|-------|---------|
| **触发方式** | agent 自动识别（比如 Claude Code 看到 skills/ 目录会加载） | 用户手动输入斜杠命令 |
| **存在意义** | 让 agent 在需要时主动发起 workflow | 让用户有显式入口 |
| **是否所有工具都有** | 是（所有 28 个工具都生成 skill） | **否**——`forgecode` 和 `trae` 没有 command adapter，只走 skill |

### Delivery 模式

在 `openspec config` 里可以配 `delivery`，有三种：

- `both`（默认）—— skill + command 都装
- `skills` —— 只装 skill
- `commands` —— 只装 command

---

## §4 `openspec-` vs `opsx-` 前缀之辨

OpenSpec 给每个 workflow **生成两份产物**，前缀不一样：

| 产物 | 谁会读它 | 命名前缀 | 完整示例 |
|------|----------|----------|----------|
| **Skill** = `SKILL.md` 文件 | Agent 自动发现，**作为知识/能力被 LLM 读到** | `openspec-` | `openspec-propose`、`openspec-apply-change`、`openspec-archive-change` |
| **Command** = 斜杠命令文件 | 用户**手动键入** `/...` 触发 | `opsx-` 或 `opsx:` | `/opsx:propose`、`/opsx-apply`、`/opsx-archive` |

**所以**：
- Skill 文件路径里看到的 `openspec-apply-change`、`openspec-archive-change`、`openspec-new-change` 这些**带 `-change` 后缀的长名字**——是 **skill 目录名**，不是 OPSX 命令
- 真正的 OPSX 斜杠命令始终是**短名字**：`apply`、`archive`、`new`、`propose`、`continue`、`ff`、`verify`、`sync`、`bulk-archive`、`explore`、`onboard`。前面再加 `opsx:` 或 `opsx-`

**"openspec-propose 跟 OPSX 的 `/opsx:propose` 有区别吗"**：
- 没有功能区别，是**同一个 workflow 的两种入口**
- 在 Claude Code 里你打 `/opsx:propose`，触发的是 `.claude/commands/opsx/propose.md`
- 在 Trae 里没有 command 文件，你只能召唤 skill：skill 目录叫 `openspec-propose`，所以你打 `/openspec-propose`——Trae 把 skill 名当命令名用

**起这两个不同前缀的设计意图**（[`add-tool-command-surface-capabilities/proposal.md`](../openspec/changes/add-tool-command-surface-capabilities/proposal.md) 明说了）：
- `openspec-` 是稳定的 skill 命名空间，所有 28 个工具都装这套，**用来给 LLM 当上下文/能力**
- `opsx-` 是为了在斜杠命令面板里**短一点、更像专属命令**而新起的别名
- 但有的工具（Trae、ForgeCode）**没有独立 command adapter**，于是退化为"skill 名 = 命令名"

### 斜杠命令风格总表（按前缀风格分桶）

| 风格 | 工具 | 触发示例 | 文件路径模板 |
|------|------|----------|--------------|
| **`opsx:` 冒号 + 子目录** | Claude Code, CodeBuddy, Qoder | `/opsx:propose` | `.claude/commands/opsx/propose.md` |
| **`opsx-` 横杠 + 平铺** | Cursor, Windsurf, Cline, OpenCode, Roo, Kilo, CoStrict, Junie, Crush, IBM Bob, Pi, Lingma, Continue, Codex, Kiro, Antigravity, Auggie, Amazon Q, Factory, iFlow, GitHub Copilot | `/opsx-propose` | `.cursor/commands/opsx-propose.md` 等 |
| **TOML 横杠** | Gemini, Qwen | `/opsx-propose` | `.gemini/commands/opsx/propose.toml` |
| **没有 command 文件，只有 skill** | **Trae**、**ForgeCode** | `/openspec-propose`、`/openspec-apply-change` | 见 §5 |

完整路径表参见 [02-installation.md §6](02-installation.md#6-每个工具的安装路径)。

---

## §5 Trae 深挖

### 它为什么"看上去舒服"

因为 Trae **完全活在 skill 模型里**：你不需要记 `opsx-` 还是 `opsx:`，所有可用的 OpenSpec 能力都能在 skill 列表里看到，**skill 名就是命令名**。

### 安装产物

```text
.trae/
└── skills/
    ├── openspec-propose/SKILL.md
    ├── openspec-explore/SKILL.md
    ├── openspec-new-change/SKILL.md
    ├── openspec-continue-change/SKILL.md
    ├── openspec-apply-change/SKILL.md
    ├── openspec-ff-change/SKILL.md
    ├── openspec-sync-specs/SKILL.md
    ├── openspec-archive-change/SKILL.md
    ├── openspec-bulk-archive-change/SKILL.md
    ├── openspec-verify-change/SKILL.md
    └── openspec-onboard/SKILL.md
```

**没有** `.trae/commands/` 目录——确认方式：[src/core/command-generation/adapters/](../src/core/command-generation/adapters/) 里**没有 trae.ts**。

### 它能用哪些 OPSX 命令

**全部 11 个都能用**，但**调用形式是 skill 名**：

| 你想做的事 | OPSX 短名 | 在 Claude 里 | 在 Trae 里 |
|-----------|-----------|--------------|-----------|
| 新建变更 | `propose` | `/opsx:propose` | `/openspec-propose` |
| 探索代码 | `explore` | `/opsx:explore` | `/openspec-explore` |
| 创建变更脚手架 | `new` | `/opsx:new` | `/openspec-new-change` |
| 继续未完成的 artifact | `continue` | `/opsx:continue` | `/openspec-continue-change` |
| 实施变更 | `apply` | `/opsx:apply` | `/openspec-apply-change` |
| 一气呵成做完 | `ff` | `/opsx:ff` | `/openspec-ff-change` |
| 同步 specs | `sync` | `/opsx:sync` | `/openspec-sync-specs` |
| 验证变更 | `verify` | `/opsx:verify` | `/openspec-verify-change` |
| 归档单个 | `archive` | `/opsx:archive` | `/openspec-archive-change` |
| 批量归档 | `bulk-archive` | `/opsx:bulk-archive` | `/openspec-bulk-archive-change` |
| 项目接入 | `onboard` | `/opsx:onboard` | `/openspec-onboard` |

> **注意大小写转换**：`opsx:apply` ↔ `openspec-apply-change`，**多了 `-change` 后缀**。这是因为 skill 名沿用了 legacy 命名风格，而 `opsx-` 命令是新设计，故意取短名。

### Trae 适合什么场景

- ✅ 喜欢"统一一种召唤方式、不想区分 skill/command"的人
- ✅ 团队既用 Trae 又有 CI 校验时，**`init` 装好后就一种用法**
- ❌ 想要"`/opsx-` 自动补全成命令面板"的体验暂时拿不到

### 进行中的设计提案：把 Trae 这种能力正名为 "skills-invocable"

目前 OpenSpec 代码里把工具分成"有 command adapter 的"和"没 command adapter 的"两类，但 Trae/ForgeCode 这种"skill 就能直接被用户当命令唤"的场景其实是**第三种能力**，没被显式建模。仓库里有一个**进行中的 change** 就是在修这件事：

- 位置：[`openspec/changes/add-tool-command-surface-capabilities/`](../openspec/changes/add-tool-command-surface-capabilities/)
- 核心想法：给每个工具加一个 **`commandSurface`** 枚举字段，可选值包括：
  - `"commands"`：有专用 commands/ 目录（Claude / Cursor / Cline / OpenCode...）
  - `"skills-invocable"`：skill 目录里的 SKILL.md 直接能被用户当命令用（**Trae / ForgeCode** 所在类）
  - `"skills-only"`：只有 skill，没有用户级触发入口（纯 LLM 自动发现）
- 一旦落地，`openspec init` / `update` 的 UI 就能**按能力分类展示**工具，用户选工具时能清楚地知道自己选的是哪种触发模型

**对读者的意义**：如果你把 Trae 归类为"没有命令只有 skill"会误判它的实际体验。正确心智模型是"**它的 skill 本身就是命令**"。

---

## §6 Cline 深挖

### Cline 是个**双产物**工具

不像 Trae，Cline **同时有 skill 和 command adapter**，而且 command adapter 用的是 Cline 自家"workflow"机制，不是普通 prompt。

源码：[src/core/command-generation/adapters/cline.ts](../src/core/command-generation/adapters/cline.ts)

```ts
export const clineAdapter: ToolCommandAdapter = {
  toolId: 'cline',
  getFilePath(commandId: string): string {
    return path.join('.clinerules', 'workflows', `opsx-${commandId}.md`);
  },
  formatFile(content: CommandContent): string {
    return `# ${content.name}\n\n${content.description}\n\n${content.body}\n`;
  },
};
```

### 安装产物

```text
.cline/
└── skills/
    └── openspec-*/SKILL.md          ← skill，给 LLM 当能力

.clinerules/
└── workflows/
    ├── opsx-propose.md              ← Cline workflow，斜杠命令文件
    ├── opsx-apply.md
    ├── opsx-archive.md
    └── ...
```

**注意两个目录不一样**：skill 在 `.cline/`，但 workflow 在 **`.clinerules/`**（这是 Cline rules 系统的官方目录约定）。

### 文件格式差异

Cline 的 workflow 文件**不用 YAML frontmatter**，而是用 markdown header：

```markdown
# /opsx-propose

Create a new OPSX change proposal with intent and scope...

(workflow body...)
```

而 Cursor / Claude / OpenCode 都是 `---` frontmatter。这是 Cline 自身规范决定的。

### 在 Cline 里怎么触发

- **斜杠命令**：在聊天框里输入 `/opsx-propose`、`/opsx-apply` 等——Cline 会扫描 `.clinerules/workflows/` 把它当 workflow 跑
- **Skill 自动发现**：项目中存在 `.cline/skills/openspec-*/SKILL.md` 时，Cline 在合适场景会自动**读取并参考**那些 SKILL（不需要你显式触发）

### Cline 支持的 OPSX 命令

**全部 11 个都支持**，全部走 `opsx-` 横杠 + 平铺命名：

| 命令 | 在 Cline 里 |
|------|------------|
| propose | `/opsx-propose` |
| explore | `/opsx-explore` |
| new | `/opsx-new` |
| continue | `/opsx-continue` |
| apply | `/opsx-apply` |
| ff | `/opsx-ff` |
| sync | `/opsx-sync` |
| verify | `/opsx-verify` |
| archive | `/opsx-archive` |
| bulk-archive | `/opsx-bulk-archive` |
| onboard | `/opsx-onboard` |

> 切到 `core` profile 时只有 4 个命令（propose / explore / apply / archive），其它 7 个不会生成。

### Cline 用的实战提示

- `.clinerules/workflows/` 是 **Cline 的 .clinerules 系统** 的子目录——意味着同一项目里你的 OPSX workflow 跟其它 Cline rules **共享存放位置**，不会冲突
- Cline 的 workflow 文件可以直接被人手编辑——如果你想给团队定制 OPSX 命令的提示词，可以直接改 `.clinerules/workflows/opsx-*.md`，但下次 `openspec update` 会被覆盖
- 想把项目交给只用 Cline 的同事：把 `.cline/` 和 `.clinerules/workflows/opsx-*.md` 一起 commit

---

## §7 OpenCode 深挖

### OpenCode 也是**双产物**，但有个**独有的转换处理**

源码：[src/core/command-generation/adapters/opencode.ts](../src/core/command-generation/adapters/opencode.ts)

```ts
export const opencodeAdapter: ToolCommandAdapter = {
  toolId: 'opencode',
  getFilePath(commandId: string): string {
    return path.join('.opencode', 'commands', `opsx-${commandId}.md`);
  },
  formatFile(content: CommandContent): string {
    const transformedBody = transformToHyphenCommands(content.body);
    return `---\ndescription: ${content.description}\n---\n\n${transformedBody}\n`;
  },
};
```

注意 `transformToHyphenCommands` 这个调用——OpenCode adapter 是 **唯一**会做这个变换的：

```ts
export function transformToHyphenCommands(text: string): string {
  return text.replace(/\/opsx:/g, '/opsx-');
}
```

### 这个转换在干什么

OpenSpec 的 command 模板**正文里**会写"接下来用 `/opsx:apply` 把 proposal 实施掉"这种引用。Claude 用 `/opsx:apply` 没问题，但 OpenCode **只认 `/opsx-apply`**，所以 adapter 在写文件前把所有 `/opsx:` 全替换成 `/opsx-`。

**结果**：在 OpenCode 装出来的 workflow 文件里，**所有内部交叉引用都被规范化成横杠形式**。

### 安装产物

```text
.opencode/
├── skills/
│   └── openspec-*/SKILL.md          ← skill
└── commands/
    ├── opsx-propose.md              ← command，YAML frontmatter
    ├── opsx-apply.md
    ├── opsx-archive.md
    └── ...
```

### 文件格式

OpenCode 用**最简洁的 frontmatter**，只有一个 `description` 字段：

```markdown
---
description: Create a new OPSX change proposal with intent and scope
---

(workflow body, 内部所有 /opsx: 都已被转成 /opsx-)
```

对比一下其它工具的 frontmatter 字段量：

| 工具 | frontmatter 字段 |
|------|----------------|
| **OpenCode** | `description`（1 个） |
| **Cursor** | `name`, `id`, `category`, `description`（4 个） |
| **Claude** | `name`, `description`, `category`, `tags`（4 个） |
| **Cline** | 无 frontmatter，用 markdown `#` 标题 |

### OpenCode 用的实战提示

- OpenCode 的 `.opencode/commands/` 里**不支持子目录**——所以文件名必须是 `opsx-<id>.md`，不能 `opsx/<id>.md`
- 如果你**手动改**了 `.opencode/commands/opsx-*.md` 想加自己的引用，记得**用 `/opsx-xxx` 不要用 `/opsx:xxx`**——否则 OpenCode 不认；下次 `openspec update` 也会按这个规则覆盖

---

## §8 GitHub Copilot 的特殊坑

`.github/prompts/opsx-*.prompt.md` **只在 IDE 扩展**（VS Code / JetBrains / Visual Studio）里被识别为斜杠命令。

**Copilot CLI 当前不支持这种 prompt 文件**——见 [docs/supported-tools.md](../docs/supported-tools.md) 脚注。

---

## §9 选工具的速查心法

| 你在意的事 | 推荐风格 | 代表工具 |
|-----------|----------|----------|
| 不想记两套前缀，用 skill 就够 | skills-invocable | **Trae**, ForgeCode |
| 想要标准 markdown + frontmatter 命令，跟其它 rules 共存 | `.clinerules/workflows/` | **Cline** |
| 想要最简洁的 frontmatter，干净的 commands 目录 | `.opencode/commands/` | **OpenCode** |
| 想要带子目录的命名空间 + 完整元数据 | `.claude/commands/opsx/` | **Claude Code** |
| 想要平铺的 commands 目录 + 4 字段 frontmatter | `.cursor/commands/` | **Cursor** |

### 实战提示

- **跨工具协作时，文档别写死前缀**。建议这样写：
  > "运行 `/opsx-apply`（Trae 用户用 `/openspec-apply-change`）"
- 不知道当前装的是哪个？看项目里有没有：
  - `.claude/commands/opsx/` → Claude
  - `.cursor/commands/opsx-*.md` → Cursor
  - `.clinerules/workflows/opsx-*.md` → Cline
  - `.opencode/commands/opsx-*.md` → OpenCode
  - **只有** `.trae/skills/openspec-*/` → Trae（没 command 文件）
- 本系列消化笔记其余地方为简洁起见，**统一用 Claude 风格 `/opsx:xxx`**，看到时自己根据上面表格换算
