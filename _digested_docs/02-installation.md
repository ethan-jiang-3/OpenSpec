# 02 · 安装

> 回 [导读](00-index.md) · [FAQ](FAQ.md)

## 目录

- [§1 `openspec init`](#1-openspec-init)
- [§2 `openspec update`](#2-openspec-update)
- [§3 单项目隔离](#3-单项目隔离)
- [§4 28 个支持的工具总表](#4-28-个支持的工具总表)
- [§5 `--tools` ID 清单（CI 用）](#5---tools-id-清单ci-用)
- [§6 每个工具的安装路径](#6-每个工具的安装路径)
- [§7 安装的副作用与触发模型](#7-安装的副作用与触发模型)
- [§8 想"装上没存在感"的最干净配置](#8-想装上没存在感的最干净配置)
- [§9 卸载/反悔](#9-卸载反悔)

---

## §1 `openspec init`

**一句话**：在项目里初始化 OpenSpec——创建 `openspec/` 目录结构 + 生成选定 AI 工具的集成文件。

### 语法

```
openspec init [path] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--tools <list>` | 非交互配置工具。可用 `all`、`none` 或逗号分隔的 ID 列表 |
| `--force` | 自动清理 legacy 文件，不问确认 |
| `--profile <profile>` | 覆盖全局 profile（`core` 或 `custom`） |

### 默认行为

不带任何参数时，用全局 config 的默认值：
- profile = `core`（4 个 workflow）
- delivery = `both`（skill + command 都装）
- workflows = `propose, explore, apply, archive`

并会进入**交互式可搜索多选菜单**选择要配哪些工具——**预勾已检测到的工具**（项目里有 `.claude/` 就预勾 Claude）。

### 会创建什么

```
openspec/
├── specs/              # 真实规格（source of truth）
├── changes/            # change 提案
└── config.yaml         # 项目配置（可选）

.claude/skills/         # Claude skill（若选了 claude）
.cursor/skills/         # Cursor skill
.cursor/commands/       # Cursor 命令（若 delivery 含 commands）
...
```

### 示例

```bash
# 交互式
openspec init

# 在指定目录初始化
openspec init ./my-project

# CI：只配 Claude + Cursor
openspec init --tools claude,cursor --force

# 全装
openspec init --tools all

# 一个都不装（只要 openspec/ 目录结构）
openspec init --tools none

# 临时用 core profile 跑一次 init
openspec init --profile core
```

---

## §2 `openspec update`

**一句话**：升级 OpenSpec CLI 后，在已有项目里**重生成 AI 工具配置文件**，保证 skill/command 是最新版本。

### 语法

```
openspec update [path] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--force` | 强制更新，即使文件已是最新 |

### 典型流程

```bash
# 升级 CLI
npm install -g @fission-ai/openspec@latest

# 在每个项目里刷新
cd my-project
openspec update
```

### 什么时候需要跑

- 升级了 `@fission-ai/openspec` npm 包之后
- 通过 `openspec config profile` 改了 profile / workflow / delivery 之后
- skill/command 文件被误删或手动改坏
- `openspec config profile` 的结果让 profile-sync-drift 报 warning 时（代码见 [src/core/profile-sync-drift.ts](../src/core/profile-sync-drift.ts)）

---

## §3 单项目隔离

> **完全可以只影响一个项目**。OpenSpec 设计上就是项目级隔离的。下面把所有可能的"漏出"路径列清楚。

### 3.1 安装 CLI 本身有几种姿势

`npm install -g @fission-ai/openspec` 只是把 `openspec` 二进制放进全局 PATH，**不会**自动接管任何项目。CLI 在哪都能跑，但**你不主动在某个项目里执行 `openspec init`，那个项目就跟 OpenSpec 完全无关**。

如果你连"全局 PATH 多个 binary"都觉得多余：

| 安装方式 | 命令 | 适用场景 |
|---------|------|---------|
| **全局装**（推荐） | `npm install -g @fission-ai/openspec@latest` | 经常用 OpenSpec |
| **不装，按需用** | `npx @fission-ai/openspec init` | 只想试试 / 只用一次 |
| **项目级 devDep** | `npm install -D @fission-ai/openspec` 然后 `npx openspec init` | 想把 OpenSpec 版本锁在 `package.json` |

> postinstall 脚本（[scripts/postinstall.js](../scripts/postinstall.js)）只打一行 tip 提示 shell 自动补全，**不写任何文件、不开 daemon、不改 PATH**。

### 3.2 `openspec init` 写的东西全部在 cwd 内

```text
<你的项目>/
├── openspec/                           ← OpenSpec 项目数据
│   ├── specs/  changes/  config.yaml
└── .<tool>/                            ← 你选的 AI 工具的 skill/command
    ├── skills/openspec-*/SKILL.md
    └── commands/opsx-*.md
```

**别的项目目录不会被碰**——OpenSpec 是纯被动 CLI，不扫盘、不监听文件改动、不跑 daemon。

### 3.3 唯一的 3 个"全局"漏出点

#### ① Codex 的全局 prompts（**最容易踩**）

```text
$CODEX_HOME/prompts/opsx-*.md
（默认 ~/.codex/prompts/）
```

**触发条件**：`openspec init` 时选了 `codex` 这个工具。

**影响**：所有用 Codex CLI 的项目都会看到 `/opsx-*` 命令——即使那些项目没有 `openspec/` 目录。

**规避**：`init` 时**别勾 codex**，或者用 `--tools claude,cursor` 显式指定。

#### ② 全局 CLI 配置文件

```text
~/.config/openspec/config.json    # macOS/Linux
%APPDATA%/openspec/config.json    # Windows
```

存的是 `openspec config` 设置（profile、delivery、workflows、featureFlags）。**只在 `openspec init / update` 跑的时候被读**。

**规避**：每次 init 时用 `--profile` / `--tools` **显式指定**。

#### ③ 用户级自定义 schema

```text
~/.local/share/openspec/schemas/<name>/    # macOS/Linux
%LOCALAPPDATA%/openspec/schemas/<name>/    # Windows
```

只有手动跑 `openspec schema fork ... --location user` 才会出现，**默认安装下这个目录是空的**。

### 3.4 没 `openspec/` 目录的项目，OpenSpec 完全不存在

| 行为 | 是否发生 |
|------|---------|
| 你打开这个项目时 OpenSpec 自动启动 | ❌ |
| OpenSpec 写任何文件到这个项目 | ❌ |
| OpenSpec 修改这个项目的 git/config/package.json | ❌ |
| 这个项目的 AI agent 看到任何 OpenSpec skill/command | ❌（除了 Codex 全局例外） |
| OpenSpec 跑后台进程占资源 | ❌ |

### 3.5 推荐的多项目隔离实践

```bash
# ──── 项目 A：要 OpenSpec ────
cd ~/code/project-a
openspec init --tools claude,cursor      # 只装这俩，避开 codex 全局

# ──── 项目 B：不要 OpenSpec ────
cd ~/code/project-b
# 啥也不干 → OpenSpec 在这个项目不存在

# ──── 项目 C：临时试，不想留痕 ────
cd ~/code/project-c
npx @fission-ai/openspec init --tools claude
# 用完清掉：
rm -rf openspec .claude/skills/openspec-* .claude/commands/opsx
```

### 3.6 一句话结论

> **OpenSpec 是项目级隔离的。** 全局装的只是 CLI binary，没在哪个项目跑过 `init`，那个项目就跟 OpenSpec 没有任何关系。**唯一例外是 Codex**：选了 codex 工具会写全局 `$CODEX_HOME/prompts/`。

---

## §4 28 个支持的工具总表

OpenSpec 在 [`src/core/config.ts`](../src/core/config.ts) 的 `AI_TOOLS` 数组里声明了 **28 个可安装的 coding agent**，每个在 [`src/core/command-generation/adapters/`](../src/core/command-generation/adapters/) 有独立适配器。

按字母排序：

| # | 显示名 | ID（`--tools` 用） | skillsDir | 有 Command Adapter? |
|---|--------|---------------------|-----------|---------------------|
| 1 | Amazon Q Developer | `amazon-q` | `.amazonq` | ✔ |
| 2 | Antigravity | `antigravity` | `.agent` | ✔ |
| 3 | Auggie（Augment CLI） | `auggie` | `.augment` | ✔ |
| 4 | Bob Shell（IBM） | `bob` | `.bob` | ✔ |
| 5 | Claude Code | `claude` | `.claude` | ✔ |
| 6 | Cline | `cline` | `.cline` | ✔ |
| 7 | Codex | `codex` | `.codex` | ✔（装到全局） |
| 8 | CodeBuddy Code（CLI） | `codebuddy` | `.codebuddy` | ✔ |
| 9 | Continue | `continue` | `.continue` | ✔ |
| 10 | CoStrict | `costrict` | `.cospec` | ✔ |
| 11 | Crush | `crush` | `.crush` | ✔ |
| 12 | Cursor | `cursor` | `.cursor` | ✔ |
| 13 | Factory Droid | `factory` | `.factory` | ✔ |
| 14 | ForgeCode | `forgecode` | `.forge` | ✘（只有 skill） |
| 15 | Gemini CLI | `gemini` | `.gemini` | ✔（TOML 格式） |
| 16 | GitHub Copilot | `github-copilot` | `.github` | ✔（仅 IDE 扩展） |
| 17 | iFlow | `iflow` | `.iflow` | ✔ |
| 18 | Junie | `junie` | `.junie` | ✔ |
| 19 | Kilo Code | `kilocode` | `.kilocode` | ✔ |
| 20 | Kiro | `kiro` | `.kiro` | ✔ |
| 21 | Lingma | `lingma` | `.lingma` | ✔（源码有，docs 未列） |
| 22 | OpenCode | `opencode` | `.opencode` | ✔ |
| 23 | Pi | `pi` | `.pi` | ✔ |
| 24 | Qoder | `qoder` | `.qoder` | ✔ |
| 25 | Qwen Code | `qwen` | `.qwen` | ✔（TOML 格式） |
| 26 | RooCode | `roocode` | `.roo` | ✔ |
| 27 | Trae | `trae` | `.trae` | ✘（只有 skill） |
| 28 | Windsurf | `windsurf` | `.windsurf` | ✔ |
| — | **AGENTS.md（兜底）** | `agents` | — | `available: false`，不在安装菜单里 |

> **Lingma 注意**：源码里有（包括 [adapters/lingma.ts](../src/core/command-generation/adapters/lingma.ts)），但官方 [docs/supported-tools.md](../docs/supported-tools.md) 暂未列出。以源码为准。

### 三类安装差异

1. **只有 skill 没有 command**（2 个）：`forgecode`、`trae` —— agent 通过 skill 机制自己发现
2. **装到全局目录**（1 个）：`codex` 的 commands 装到 `$CODEX_HOME/prompts/`（默认 `~/.codex/prompts/`）
3. **只在 IDE 扩展生效**（1 个）：`github-copilot` 的 `.github/prompts/*.prompt.md` 只被 VS Code / JetBrains / Visual Studio 扩展读取，**Copilot CLI 不认**

---

## §5 `--tools` ID 清单（CI 用）

`openspec init --tools <list>` 可用下列 ID，逗号分隔，或用 `all` / `none` 两个特殊值。

### 完整 ID 清单

```
amazon-q
antigravity
auggie
bob
claude
cline
codebuddy
codex
continue
costrict
crush
cursor
factory
forgecode
gemini
github-copilot
iflow
junie
kilocode
kiro
lingma
opencode
pi
qoder
qwen
roocode
trae
windsurf
```

### 实用命令示例

```bash
# 只装 Claude + Cursor
openspec init --tools claude,cursor

# 全部装
openspec init --tools all

# 一个都不装
openspec init --tools none

# 用 core profile
openspec init --tools claude --profile core

# 用 custom profile
openspec init --tools claude --profile custom

# 刷新已有项目
openspec update
openspec update --force
```

### 官方文档暂缺的 ID

[docs/supported-tools.md](../docs/supported-tools.md) 最底的 `--tools` 可选值清单**少列了 `bob` 和 `lingma`**。以源码 [`src/core/config.ts`](../src/core/config.ts) 的 `AI_TOOLS` 为准。

### 动态发现

```bash
openspec init   # 不带 --tools 进入交互菜单，自动扫描项目里已存在的 tool 目录
```

内部实现 [`src/core/available-tools.ts`](../src/core/available-tools.ts)：遍历 `AI_TOOLS`，对每个工具检查 `detectionPaths`（如果有）或 `skillsDir` 目录是否存在。

---

## §6 每个工具的安装路径

来源：[`src/core/init.ts`](../src/core/init.ts)、[`docs/supported-tools.md`](../docs/supported-tools.md)。`<id>` 是 workflow id（`propose` / `apply` / `archive` 等）。

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
| Lingma | `.lingma/skills/openspec-*/SKILL.md` | （见 [adapters/lingma.ts](../src/core/command-generation/adapters/lingma.ts)） |
| OpenCode | `.opencode/skills/openspec-*/SKILL.md` | `.opencode/commands/opsx-<id>.md` |
| Pi | `.pi/skills/openspec-*/SKILL.md` | `.pi/prompts/opsx-<id>.md` |
| Qoder | `.qoder/skills/openspec-*/SKILL.md` | `.qoder/commands/opsx/<id>.md` |
| Qwen Code | `.qwen/skills/openspec-*/SKILL.md` | `.qwen/commands/opsx-<id>.toml` |
| RooCode | `.roo/skills/openspec-*/SKILL.md` | `.roo/commands/opsx-<id>.md` |
| Trae | `.trae/skills/openspec-*/SKILL.md` | **无**（只有 skill） |
| Windsurf | `.windsurf/skills/openspec-*/SKILL.md` | `.windsurf/workflows/opsx-<id>.md` |

### 四类路径约定

1. **`commands/opsx-<id>.md`**（扁平）—— 大多数工具
2. **`commands/opsx/<id>.md>`**（命名空间子目录）—— claude / codebuddy / crush / qoder
3. **`workflows/opsx-<id>.md`**—— antigravity / cline / kilocode / windsurf
4. **`prompts/opsx-<id>.md`**—— amazon-q / codex（全局）/ continue（`.prompt`）/ github-copilot / kiro / pi

---

## §7 安装的副作用与触发模型

### 7.1 init 干了什么、没干什么

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
| 清理 legacy 文件 | ⚠️ | 检测到旧版 OpenSpec 文件时**会提示确认**才删（`--force` 或非交互模式才会自动删） |

### 7.2 装完之后的"被动度"——三层模型

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

`description` 字段长这样（来自 [`templates/workflows/propose.ts`](../src/core/templates/workflows/propose.ts)）：

> `Propose a new change with all artifacts generated in one step. Use when the user wants to quickly describe what they want to build...`

**"Use when the user wants ..."** 就是 agent 用来判断"现在这个对话该不该把这个 skill 上下文加进去"的钩子。

### 7.3 各 agent 的"自动注入"行为分档

| 类型 | 行为 | 代表工具 | 用户体感 |
|------|------|----------|----------|
| **完全主动型** | 每次对话都把所有 skill 加进上下文 | 几乎没有（成本太高） | — |
| **上下文匹配型** | 看 SKILL.md 的 `description`，判断当前对话相关时**主动注入** | **Claude Code**（skills 系统） | ⚠️ 你可能没打 `/opsx:propose` 也会被 Claude "看到" |
| **斜杠面板型** | skill 出现在斜杠命令面板，用户必须**主动选** | **Trae**、**ForgeCode** | ✅ 不点就不跑 |
| **纯 rules 型** | 把 SKILL.md 当成项目规则文件，每次对话**总是**附带 | Cursor 的 `.cursorrules`（OpenSpec 不触发这个） | ✅ 不会 |
| **静默存档型** | SKILL.md 装了基本不被自动读 | 大多数 CLI 类工具（Codex、Continue、Crush 等） | ✅ 不引用就不跑 |

> **真正会"自动出来"的只有 Claude Code 这一类支持 skill 自动发现的 agent**。其它工具的 SKILL.md 安静地躺着，**等命令触发或显式引用**。

### 7.4 各 commands 文件的副作用

**所有 28 个工具的 commands 文件全部是 Layer 2 — 主动触发型**，零自动加载：

- `.cursor/commands/opsx-*.md` → 你输 `/opsx-propose` 才被 Cursor 加载
- `.claude/commands/opsx/*.md` → 你输 `/opsx:propose` 才被 Claude 加载
- `.clinerules/workflows/opsx-*.md` → 你输 `/opsx-propose` 才被 Cline 加载
- `.opencode/commands/opsx-*.md` → 你输 `/opsx-propose` 才被 OpenCode 加载

**不打命令永远不会跳出来。**

---

## §8 想"装上没存在感"的最干净配置

如果你担心 Layer 3 的自动注入（主要针对 Claude Code）：

### 方案 A：把 delivery 改成只装 commands

```bash
openspec config profile
# 选: Change delivery only
# 选: Commands only
```

结果：
- 100% 主动触发
- **缺点**：Trae、ForgeCode 这种**没有 command adapter** 的工具就**不能用 OpenSpec 了**（因为它们靠 skill 当命令）

### 方案 B：只装那些 SKILL.md 不会被自动加载的工具

如果你团队里**不用 Claude Code**，可以保持 `delivery=both`，因为 Cursor / Cline / OpenCode / Codex 等大多数工具的 SKILL.md 不会被自动注入到每次对话。

### 方案 C：装了之后手动删 `.skills/openspec-*` 目录

最暴力但有效。下次 `openspec update` 又会重建。

---

## §9 卸载/反悔

OpenSpec 没有 `uninstall` 命令，但因为它**只动文件不动系统**，手动删除即可：

```bash
# 删项目内
rm -rf openspec
rm -rf .claude/skills/openspec-*  .claude/commands/opsx
rm -rf .cursor/skills/openspec-*  .cursor/commands/opsx-*.md
rm -rf .clinerules/workflows/opsx-*.md
# ... 其它工具同理（看 §6 路径表）

# Codex 用户记得清全局
rm -f $CODEX_HOME/prompts/opsx-*.md   # 或 ~/.codex/prompts/opsx-*.md

# 完全卸载 CLI 本身
npm uninstall -g @fission-ai/openspec
rm -rf ~/.config/openspec       # 全局配置
rm -rf ~/.local/share/openspec  # 用户级 schema（如果有）
```

**没有 git hook 要解，没有 daemon 要 kill，没有 PATH 要清**——这是 OpenSpec 设计哲学的一部分：纯文件，无 footprint。
