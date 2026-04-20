# 每个工具的安装路径与副作用

来源：[`src/core/init.ts`](../../src/core/init.ts)、[`docs/supported-tools.md`](../../docs/supported-tools.md)。`<id>` 是 workflow id（`propose` / `apply` / `archive` 等）。

> ⚡ 如果你只想知道"装完了会不会自动跑出来烦人"，直接跳到 [§3 安装的副作用与触发模型](#3-安装的副作用与触发模型)。

---

## 1. 安装的范围：是装一个还是装全部？

**默认是用户主动选择，不会一锅端。**[`src/core/init.ts:340-345`](../../src/core/init.ts) 这段代码用 `searchableMultiSelect` 弹出多选框让你勾。

### 三种触发方式

| 模式 | 命令 | 行为 |
|------|------|------|
| **交互式（默认）** | `openspec init` | 弹出可搜索的多选框，**预勾已检测到的工具**（项目里有 `.claude/` 就预勾 Claude），用户必须手动确认或调整 |
| **批量装全部** | `openspec init --tools all` | 把 [`AI_TOOLS`](../../src/core/config.ts) 里所有 28 个工具的 skill 都铺一遍 |
| **指定子集** | `openspec init --tools claude,cursor,cline` | 只装这几个 |
| **只生成项目结构，不装任何工具** | `openspec init --tools none` | 只创建 `openspec/` 目录，跳过 skill/command 生成 |

源码佐证：

```370:377:src/core/init.ts
    const lowerRaw = raw.toLowerCase();
    if (lowerRaw === 'all') {
      return availableTools;
    }

    if (lowerRaw === 'none') {
      return [];
    }
```

### 检测逻辑

[`src/core/init.ts:329-338`](../../src/core/init.ts) 会扫描项目根目录，发现 `.claude/`、`.cursor/`、`.opencode/` 等目录就**预勾对应工具**。所以一般情况下你跑 `openspec init` 不需要手动选——它会推荐你已经在用的工具。

**结论**：装哪个工具完全你说了算，不会偷偷给你装一堆。

---

## 2. 完整安装路径表

| 工具 | Skills 路径 | Commands 路径 |
|------|-------------|---------------|
| Amazon Q Developer | `.amazonq/skills/openspec-*/SKILL.md` | `.amazonq/prompts/opsx-<id>.md` |
| Antigravity | `.agent/skills/openspec-*/SKILL.md` | `.agent/workflows/opsx-<id>.md` |
| Auggie | `.augment/skills/openspec-*/SKILL.md` | `.augment/commands/opsx-<id>.md` |
| IBM Bob Shell | `.bob/skills/openspec-*/SKILL.md` | `.bob/commands/opsx-<id>.md` |
| Claude Code | `.claude/skills/openspec-*/SKILL.md` | `.claude/commands/opsx/<id>.md` |
| Cline | `.cline/skills/openspec-*/SKILL.md` | `.clinerules/workflows/opsx-<id>.md` |
| CodeBuddy | `.codebuddy/skills/openspec-*/SKILL.md` | `.codebuddy/commands/opsx/<id>.md` |
| Codex | `.codex/skills/openspec-*/SKILL.md` | **`$CODEX_HOME/prompts/opsx-<id>.md`** ⚠️ 全局 |
| ForgeCode | `.forge/skills/openspec-*/SKILL.md` | **无**（只有 skill） |
| Continue | `.continue/skills/openspec-*/SKILL.md` | `.continue/prompts/opsx-<id>.prompt` |
| CoStrict | `.cospec/skills/openspec-*/SKILL.md` | `.cospec/openspec/commands/opsx-<id>.md` |
| Crush | `.crush/skills/openspec-*/SKILL.md` | `.crush/commands/opsx/<id>.md` |
| Cursor | `.cursor/skills/openspec-*/SKILL.md` | `.cursor/commands/opsx-<id>.md` |
| Factory Droid | `.factory/skills/openspec-*/SKILL.md` | `.factory/commands/opsx-<id>.md` |
| Gemini CLI | `.gemini/skills/openspec-*/SKILL.md` | `.gemini/commands/opsx/<id>.toml` |
| GitHub Copilot | `.github/skills/openspec-*/SKILL.md` | `.github/prompts/opsx-<id>.prompt.md` ⚠️ 仅 IDE |
| iFlow | `.iflow/skills/openspec-*/SKILL.md` | `.iflow/commands/opsx-<id>.md` |
| Junie | `.junie/skills/openspec-*/SKILL.md` | `.junie/commands/opsx-<id>.md` |
| Kilo Code | `.kilocode/skills/openspec-*/SKILL.md` | `.kilocode/workflows/opsx-<id>.md` |
| Kiro | `.kiro/skills/openspec-*/SKILL.md` | `.kiro/prompts/opsx-<id>.prompt.md` |
| Lingma | `.lingma/skills/openspec-*/SKILL.md` | （见源码 [adapters/lingma.ts](../../src/core/command-generation/adapters/lingma.ts)）|
| OpenCode | `.opencode/skills/openspec-*/SKILL.md` | `.opencode/commands/opsx-<id>.md` |
| Pi | `.pi/skills/openspec-*/SKILL.md` | `.pi/prompts/opsx-<id>.md` |
| Qoder | `.qoder/skills/openspec-*/SKILL.md` | `.qoder/commands/opsx/<id>.md` |
| Qwen Code | `.qwen/skills/openspec-*/SKILL.md` | `.qwen/commands/opsx-<id>.toml` |
| RooCode | `.roo/skills/openspec-*/SKILL.md` | `.roo/commands/opsx-<id>.md` |
| Trae | `.trae/skills/openspec-*/SKILL.md` | **无**（只有 skill） |
| Windsurf | `.windsurf/skills/openspec-*/SKILL.md` | `.windsurf/workflows/opsx-<id>.md` |

### 四类路径约定

按 commands 放哪里，可以分四类：

1. **`commands/opsx-<id>.md`**（扁平）—— 大多数工具
2. **`commands/opsx/<id>.md`**（命名空间子目录）—— claude / codebuddy / crush / qoder
3. **`workflows/opsx-<id>.md`**—— antigravity / cline / kilocode / windsurf
4. **`prompts/opsx-<id>.md`**—— amazon-q / codex（全局）/ continue（`.prompt`）/ github-copilot / kiro / pi

---

## 3. 安装的副作用与触发模型

**这是你最关心的部分。**

### 3.1 init 干了什么、没干什么

| 项目 | 是否会动 | 备注 |
|------|---------|------|
| 创建 `openspec/` 目录及子目录 | ✅ | `openspec/specs/`、`openspec/changes/`、`openspec/changes/archive/` |
| 创建 `openspec/config.yaml` | ✅ | 默认 `schema: spec-driven`，可空也可不空 |
| 创建被选工具的 `.<tool>/skills/openspec-*/SKILL.md` | ✅ | 仅被选的工具，仅 `delivery=both/skills` |
| 创建被选工具的 `.<tool>/commands/opsx-*.md`（或对应路径） | ✅ | 仅被选的工具，仅 `delivery=both/commands`，且工具有 adapter |
| 写 Codex 的全局 `$CODEX_HOME/prompts/opsx-*.md` | ⚠️ | **唯一会动项目目录之外的东西**，仅当你选了 codex |
| 安装 git hooks（pre-commit / pre-push 等） | ❌ | 全代码 grep `hook` 零结果 |
| 修改 `.gitignore` | ❌ | 全代码 grep `gitignore` 零结果 |
| 修改 `package.json` | ❌ | init 不会读不会写 |
| 装 IDE 插件 | ❌ | OpenSpec 不是插件提供者 |
| 启动后台进程、daemon | ❌ | OpenSpec 是纯 CLI，跑完即退 |
| 注册全局 shell hook（zsh / bash） | ❌ | `openspec completion` 是可选的，要你自己手动加 |
| 清理 legacy 文件 | ⚠️ | 检测到旧版 OpenSpec 文件时**会提示确认**才删（`--force` 或非交互模式才会自动删）|

源码佐证 init 没做奇怪事：[`src/core/init.ts:120-155`](../../src/core/init.ts) 的主流程只有 5 步：detect → select tools → mkdir → 写 skill/command → 写 config。

### 3.2 装完之后的"被动度"——三层模型

OpenSpec 装的所有产物都是**静态文件**，没有任何运行时组件。但**这些文件被 AI agent 读取的时机**，决定了"装上以后是不是会自动跳出来"。分三层：

```text
┌──────────────────────────────────────────────────┐
│  Layer 1: 文件本身                                │
│  100% 被动。只是 .md/.toml 文件。无 daemon、无    │
│  hook、无 IDE 集成。文件躺在磁盘上零开销。         │
└──────────────────────────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────┐
│  Layer 2: Slash command（.commands/）            │
│  100% 用户主动触发。AI agent 仅在用户键入         │
│  /opsx-xxx 时去读对应文件。不打命令永远不加载。   │
│  → 真正的"用才有用"                                │
└──────────────────────────────────────────────────┘
                       ↓
┌──────────────────────────────────────────────────┐
│  Layer 3: Skills（.skills/openspec-*/SKILL.md）  │
│  ⚠️ 视 agent 而定。SKILL.md 的 frontmatter 有：    │
│      description: "Use when the user wants ..."   │
│  支持 skill 自动发现的 agent 会基于这条           │
│  description 在合适的对话上下文中**主动注入**这    │
│  个 skill 到 system prompt。                       │
└──────────────────────────────────────────────────┘
```

源码佐证 Layer 3：[`src/core/shared/skill-generation.ts:127-148`](../../src/core/shared/skill-generation.ts) 写出的 frontmatter：

```136:145:src/core/shared/skill-generation.ts
  return `---
name: ${template.name}
description: ${template.description}
license: ${template.license || 'MIT'}
compatibility: ${template.compatibility || 'Requires openspec CLI.'}
metadata:
  author: ${template.metadata?.author || 'openspec'}
  version: "${template.metadata?.version || '1.0'}"
  generatedBy: "${generatedByVersion}"
---
```

`description` 字段长这样（来自 [`templates/workflows/propose.ts:12`](../../src/core/templates/workflows/propose.ts)）：

> `Propose a new change with all artifacts generated in one step. Use when the user wants to quickly describe what they want to build...`

**"Use when the user wants ..."** 就是 agent 用来判断"现在这个对话该不该把这个 skill 上下文加进去"的钩子。

### 3.3 各 agent 的"自动注入"行为分档

按"装了 SKILL.md 后是不是会主动出现"的维度：

| 类型 | 行为 | 代表工具 | 用户体感 |
|------|------|----------|----------|
| **完全主动型** | 每次对话都把所有 skill 加进上下文 | 几乎没有（成本太高，主流工具不这么做）| — |
| **上下文匹配型** | 看 SKILL.md 的 `description`，判断当前对话相关时**主动注入**到 system prompt | **Claude Code**（skills 系统）| ⚠️ 你可能没打 `/opsx:propose` 也会被 Claude "看到"——比如你说"我想加个新功能"它可能就把 propose skill 拉进来 |
| **斜杠面板型** | skill 出现在斜杠命令面板，**用户必须主动选**才会调用 | **Trae**、**ForgeCode** | ✅ 不点就不跑 |
| **纯 rules 型** | 把 SKILL.md 当成项目规则文件，每次对话**总是**附带 | Cursor 的 `.cursorrules`（注意：OpenSpec 装的是 `.cursor/skills/`，不是 rules）| ✅ OpenSpec 不会触发这个 |
| **静默存档型** | SKILL.md 装了基本不被自动读，需要用户/命令显式 reference | 大多数 CLI 类工具（Codex、Continue、Crush 等）| ✅ 不引用就不跑 |

> **真正会"自动出来"的只有 Claude Code 这一类支持 skill 自动发现的 agent**。
> 其它工具的 SKILL.md 安静地躺着，**等命令触发或显式引用**。

### 3.4 各 commands 文件的副作用

**所有 28 个工具的 commands 文件全部是 Layer 2 — 主动触发型**，零自动加载：

- `.cursor/commands/opsx-*.md` → 你输 `/opsx-propose` 才被 Cursor 加载
- `.claude/commands/opsx/*.md` → 你输 `/opsx:propose` 才被 Claude 加载
- `.clinerules/workflows/opsx-*.md` → 你输 `/opsx-propose` 才被 Cline 加载
- `.opencode/commands/opsx-*.md` → 你输 `/opsx-propose` 才被 OpenCode 加载
- ……

不打命令永远不会跳出来。

---

## 4. 想要"装上不用就完全没存在感"的最干净配置

如果你担心 Layer 3 的自动注入（主要针对 Claude Code），有两种处理：

### 方案 A：把 delivery 改成只装 commands

```bash
openspec config profile
# 选: Change delivery only
# 选: Commands only
```

这样 [`src/core/init.ts:519-522`](../../src/core/init.ts) 里的 `shouldGenerateSkills` 会是 `false`，**不会写 SKILL.md，只写 .commands/**。结果：

- 100% 主动触发
- 缺点：Trae、ForgeCode 这种**没有 command adapter** 的工具就**不能用 OpenSpec 了**（因为它们靠 skill 当命令）

### 方案 B：只装那些 SKILL.md 不会被自动加载的工具

如果你团队里**不用 Claude Code**，可以保持 `delivery=both`，因为 Cursor / Cline / OpenCode / Codex 等大多数工具的 SKILL.md 不会被自动注入到每次对话。

### 方案 C：装了之后手动删 .skills/openspec-* 目录

最暴力但有效。下次 `openspec update` 又会重建。

---

## 5. 卸载/反悔怎么办

OpenSpec 没有 `uninstall` 命令，但因为它**只动文件不动系统**，手动删除即可：

```bash
# 删项目内
rm -rf openspec
rm -rf .claude/skills/openspec-*  .claude/commands/opsx
rm -rf .cursor/skills/openspec-*  .cursor/commands/opsx-*.md
rm -rf .clinerules/workflows/opsx-*.md
# ... 其它工具同理

# Codex 用户记得清全局
rm -f $CODEX_HOME/prompts/opsx-*.md   # 或 ~/.codex/prompts/opsx-*.md
```

**没有 git hook 要解，没有 daemon 要 kill，没有 PATH 要清**——这是 OpenSpec 设计哲学的一部分：纯文件，无 footprint。

---

## 6. 特殊情况速查

| 工具 | 特殊之处 |
|------|---------|
| **Codex** | commands 装到**全局目录**（`$CODEX_HOME/prompts/` 或 `~/.codex/prompts/`），不是项目内。这样同一套命令跨所有项目共享，但**也意味着卸载时要单独清全局** |
| **ForgeCode / Trae** | 没有 command adapter，只装 skill，触发=`/openspec-<skill>`。详见 [tool-specific-syntax.md](../02-commands/tool-specific-syntax.md#2-trae-深挖) |
| **GitHub Copilot** | `.github/prompts/*.prompt.md` **只在 IDE 扩展里**（VS Code / JetBrains / Visual Studio）被识别。Copilot CLI 不支持 |
| **Gemini / Qwen** | 用 TOML 格式（`.toml`），不是 Markdown |
| **Continue** | 扩展名 `.prompt`（不是 `.md`）|
| **Kiro** / **GitHub Copilot** | 扩展名 `.prompt.md` |
| **Claude Code** | ⚠️ **唯一可能让 SKILL.md 被自动注入对话**的 agent。介意的话用方案 A 关掉 skills |

---

## 7. 一句话总结

> **`openspec init` 是纯文件操作**：你选哪个工具就装哪个，不会全装；不动 git hook、不动 .gitignore、不动 package.json；commands 文件 100% 按需触发；只有 Claude Code 这类支持 skill 自动发现的 agent 可能在你不打命令时也悄悄读到 SKILL.md——不放心就用 `openspec config profile` 切到 `commands only` delivery 模式。
