# 不同 Agent 的命令语法差异

同一套 OPSX workflow，在 28 个 coding agent 里的斜杠命令写法**不完全一样**，并且**前缀也不止 `opsx-` 一种**。这一篇把 3 个最常被问到的工具（Trae、Cline、OpenCode）单独深挖。

---

## 0. 先理清一个最容易混的事：`openspec-` vs `opsx-`

OpenSpec 给每个 workflow **生成两份产物**，前缀不一样：

| 产物 | 谁会读它 | 命名前缀 | 完整示例 |
|------|----------|----------|----------|
| **Skill** = `SKILL.md` 文件 | Agent 自动发现，**作为知识/能力被 LLM 读到** | `openspec-` | `openspec-propose`、`openspec-apply-change`、`openspec-archive-change` |
| **Command** = 斜杠命令文件 | 用户**手动键入** `/...` 触发 | `opsx-` 或 `opsx:` | `/opsx:propose`、`/opsx-apply`、`/opsx-archive` |

源码佐证：[`src/core/shared/skill-generation.ts`](../../src/core/shared/skill-generation.ts) 里：

```57:69:src/core/shared/skill-generation.ts
  const all: SkillTemplateEntry[] = [
    { template: getExploreSkillTemplate(), dirName: 'openspec-explore', workflowId: 'explore' },
    { template: getNewChangeSkillTemplate(), dirName: 'openspec-new-change', workflowId: 'new' },
    { template: getContinueChangeSkillTemplate(), dirName: 'openspec-continue-change', workflowId: 'continue' },
    { template: getApplyChangeSkillTemplate(), dirName: 'openspec-apply-change', workflowId: 'apply' },
    { template: getFfChangeSkillTemplate(), dirName: 'openspec-ff-change', workflowId: 'ff' },
    { template: getSyncSpecsSkillTemplate(), dirName: 'openspec-sync-specs', workflowId: 'sync' },
    { template: getArchiveChangeSkillTemplate(), dirName: 'openspec-archive-change', workflowId: 'archive' },
    { template: getBulkArchiveChangeSkillTemplate(), dirName: 'openspec-bulk-archive-change', workflowId: 'bulk-archive' },
    { template: getVerifyChangeSkillTemplate(), dirName: 'openspec-verify-change', workflowId: 'verify' },
    { template: getOnboardSkillTemplate(), dirName: 'openspec-onboard', workflowId: 'onboard' },
    { template: getOpsxProposeSkillTemplate(), dirName: 'openspec-propose', workflowId: 'propose' },
  ];
```

**所以**：
- Skill 文件路径里看到的 `openspec-apply-change`、`openspec-archive-change`、`openspec-new-change` 这些**带 `-change` 后缀的长名字**——是 **skill 目录名**，不是 OPSX 命令。
- 真正的 OPSX 斜杠命令始终是**短名字**：`apply`、`archive`、`new`、`propose`、`continue`、`ff`、`verify`、`sync`、`bulk-archive`、`explore`、`onboard`。前面再加 `opsx:` 或 `opsx-`。

**回答"openspec propose 跟 OPSX 有区别吗"**：
- 没有功能区别，是**同一个 workflow 的两种入口**。
- 在 Claude Code 里你打 `/opsx:propose`，触发的是 `.claude/commands/opsx/propose.md`。
- 在 Trae 里没有 command 文件，你只能召唤 skill：skill 目录叫 `openspec-propose`，所以你打 `/openspec-propose`——Trae 把 skill 名当命令名用。

**起这两个不同前缀的设计意图**（[`add-tool-command-surface-capabilities/proposal.md`](../../openspec/changes/add-tool-command-surface-capabilities/proposal.md) 第 3-13 行明说了）：
- `openspec-` 是稳定的 skill 命名空间，所有 28 个工具都装这套，**用来给 LLM 当上下文/能力**。
- `opsx-` 是为了在斜杠命令面板里**短一点、更像专属命令**而新起的别名。
- 但有的工具（Trae、ForgeCode）**没有独立 command adapter**，于是退化为"skill 名 = 命令名"。

---

## 1. 斜杠命令风格总表（按前缀风格分桶）

| 风格 | 工具 | 触发示例 | 文件路径模板 |
|------|------|----------|--------------|
| **`opsx:` 冒号 + 子目录** | Claude Code, CodeBuddy, Qoder | `/opsx:propose` | `.claude/commands/opsx/propose.md` |
| **`opsx-` 横杠 + 平铺** | Cursor, Windsurf, Cline, OpenCode, Roo, Kilo, CoStrict, Junie, Crush, IBM Bob, Pi, Lingma, Continue, Codex, Kiro, Antigravity, Auggie, Amazon Q, Factory, iFlow, GitHub Copilot | `/opsx-propose` | `.cursor/commands/opsx-propose.md` 等 |
| **TOML 横杠** | Gemini, Qwen | `/opsx-propose` | `.gemini/commands/opsx/propose.toml` |
| **没有 command 文件，只有 skill** | **Trae**、**ForgeCode** | `/openspec-propose`、`/openspec-apply-change` | 见下文 |

完整路径表参见 [04-supported-tools/installation-paths.md](../04-supported-tools/installation-paths.md)。

---

## 2. Trae 深挖

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

**没有** `.trae/commands/` 目录——确认方式：[`src/core/command-generation/adapters/`](../../src/core/command-generation/adapters/) 里**没有 trae.ts**。

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

### 一个进行中的设计提案

[`openspec/changes/add-tool-command-surface-capabilities/`](../../openspec/changes/add-tool-command-surface-capabilities/) 正在为这种"skill 即命令"的工具补一类官方能力分类：

```text
adapter            -> 用 command adapter 生成命令文件（多数工具）
skills-invocable   -> 没有 adapter，skill 直接当命令用（Trae、ForgeCode）
none               -> 既没 adapter 也没 skill 入口
```

落地后会有这些行为变化（与 `delivery=commands` 模式相关）：
- `delivery=commands` 不再粗暴删 Trae 的 skill（因为那就是它的命令）
- `init` 时会做兼容性预检，给清晰错误而不是默默装出空目录

### Trae 适合什么场景

✅ 喜欢"统一一种召唤方式、不想区分 skill/command"的人  
✅ 团队既用 Trae 又有 CI 校验时，**`init` 装好后就一种用法**  
❌ 想要"`/opsx-` 自动补全成命令面板"的体验暂时拿不到（要等 `skills-invocable` 落地后界面层处理）

---

## 3. Cline 深挖

### Cline 是个**双产物**工具

不像 Trae，Cline **同时有 skill 和 command adapter**，而且 command adapter 用的是 Cline 自家"workflow"机制，不是普通 prompt。

源码：[`src/core/command-generation/adapters/cline.ts`](../../src/core/command-generation/adapters/cline.ts)

```16:31:src/core/command-generation/adapters/cline.ts
export const clineAdapter: ToolCommandAdapter = {
  toolId: 'cline',

  getFilePath(commandId: string): string {
    return path.join('.clinerules', 'workflows', `opsx-${commandId}.md`);
  },

  formatFile(content: CommandContent): string {
    return `# ${content.name}

${content.description}

${content.body}
`;
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

**全部 11 个都支持**，全部走 `opsx-` 横杠 + 平铺命名。命令对照表：

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

> 切到 `core` profile 时只有 4 个命令（propose / explore / apply / archive），其它 7 个不会生成。详见 [03-workflow-sequence/README.md](../03-workflow-sequence/README.md)。

### Cline 用的实战提示

- `.clinerules/workflows/` 是 **Cline 的 .clinerules 系统** 的子目录——意味着同一项目里你的 OPSX workflow 跟其它 Cline rules **共享存放位置**，不会冲突
- Cline 的 workflow 文件可以直接被人手编辑——如果你想给团队定制 OPSX 命令的提示词，可以直接改 `.clinerules/workflows/opsx-*.md`，但下次 `openspec update` 会被覆盖
- 想把项目交给只用 Cline 的同事：把 `.cline/` 和 `.clinerules/workflows/opsx-*.md` 一起 commit

---

## 4. OpenCode 深挖

### OpenCode 也是**双产物**，但有个**独有的转换处理**

源码：[`src/core/command-generation/adapters/opencode.ts`](../../src/core/command-generation/adapters/opencode.ts)

```16:34:src/core/command-generation/adapters/opencode.ts
export const opencodeAdapter: ToolCommandAdapter = {
  toolId: 'opencode',

  getFilePath(commandId: string): string {
    return path.join('.opencode', 'commands', `opsx-${commandId}.md`);
  },

  formatFile(content: CommandContent): string {
    // Transform command references from colon to hyphen format for OpenCode
    const transformedBody = transformToHyphenCommands(content.body);

    return `---
description: ${content.description}
---

${transformedBody}
`;
  },
};
```

注意 `transformToHyphenCommands` 这个调用——OpenCode adapter 是 **唯一**会做这个变换的：

```18:20:src/utils/command-references.ts
export function transformToHyphenCommands(text: string): string {
  return text.replace(/\/opsx:/g, '/opsx-');
}
```

### 这个转换在干什么

OpenSpec 的 command 模板**正文里**会写"接下来用 `/opsx:apply` 把 proposal 实施掉"这种引用。Claude 用 `/opsx:apply` 没问题，但 OpenCode **只认 `/opsx-apply`**，所以 adapter 在写文件前把所有 `/opsx:` 全替换成 `/opsx-`。

**结果**：在 OpenCode 装出来的 workflow 文件里，**所有内部交叉引用都被规范化成横杠形式**。这是其它 adapter 没做的——其它工具要么本身就用横杠（不用替换），要么允许冒号（不替换也能用）。

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
| **OpenCode** | `description`（1 个）|
| **Cursor** | `name`, `id`, `category`, `description`（4 个）|
| **Claude** | `name`, `description`, `category`, `tags`（4 个）|
| **Cline** | 无 frontmatter，用 markdown `#` 标题 |

### OpenCode 支持的 OPSX 命令

跟 Cline 一样，**全部 11 个都支持**，全用 `opsx-` 横杠风格：

| 命令 | 在 OpenCode 里 |
|------|---------------|
| propose | `/opsx-propose` |
| apply | `/opsx-apply` |
| archive | `/opsx-archive` |
| ...（其余 8 个同理）|

### OpenCode 用的实战提示

- OpenCode 的 `.opencode/commands/` 里**不支持子目录**——所以文件名必须是 `opsx-<id>.md`，不能 `opsx/<id>.md`（这点跟 Cursor 一样，跟 Claude 不一样）
- 如果你**手动改**了 `.opencode/commands/opsx-*.md` 想加自己的引用，记得**用 `/opsx-xxx` 不要用 `/opsx:xxx`**——否则 OpenCode 不认；下次 `openspec update` 也会按这个规则覆盖
- OpenCode 适合喜欢"frontmatter 越简洁越好"的项目

---

## 5. GitHub Copilot 的特殊坑（顺手提一句）

`.github/prompts/opsx-*.prompt.md` **只在 IDE 扩展**（VS Code / JetBrains / Visual Studio）里被识别为斜杠命令。

**Copilot CLI 当前不支持这种 prompt 文件**——见 [docs/supported-tools.md](../../docs/supported-tools.md) 脚注。

---

## 6. 选工具的速查心法

| 你在意的事 | 推荐风格 | 代表工具 |
|-----------|----------|----------|
| 不想记两套前缀，用 skill 就够 | skills-invocable | **Trae**, ForgeCode |
| 想要标准 markdown + frontmatter 命令，跟其它 rules 共存 | `.clinerules/workflows/` | **Cline** |
| 想要最简洁的 frontmatter，干净的 commands 目录 | `.opencode/commands/` | **OpenCode** |
| 想要带子目录的命名空间 + 完整元数据 | `.claude/commands/opsx/` | **Claude Code** |
| 想要平铺的 commands 目录 + 4 字段 frontmatter | `.cursor/commands/` | **Cursor** |

---

## 7. 实战提示（更新版）

- **跨工具协作时，文档别写死前缀**。建议这样写：
  > "运行 `/opsx-apply`（Trae 用户用 `/openspec-apply-change`）"
- 不知道当前装的是哪个？看项目里有没有：
  - `.claude/commands/opsx/` → Claude
  - `.cursor/commands/opsx-*.md` → Cursor
  - `.clinerules/workflows/opsx-*.md` → Cline
  - `.opencode/commands/opsx-*.md` → OpenCode
  - **只有** `.trae/skills/openspec-*/` → Trae（没 command 文件）
- 本系列消化笔记其余地方为简洁起见，**统一用 Claude 风格 `/opsx:xxx`**，看到时自己根据上面表格换算
