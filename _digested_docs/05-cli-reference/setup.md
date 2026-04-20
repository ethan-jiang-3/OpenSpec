# CLI · Setup 类命令

`openspec init` / `openspec update` 两个命令负责把 OpenSpec 落地到项目里，并把 AI 工具的 skill/command 生成出来。

---

## `openspec init`

**一句话**：在项目里初始化 OpenSpec——创建 `openspec/` 目录结构 + 生成配置的 AI 工具集成文件。

### 语法

```
openspec init [path] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--tools <list>` | 非交互配置工具。可用 `all`、`none` 或逗号分隔的 ID 列表 |
| `--force` | 自动清理 legacy 文件，不问确认 |
| `--profile <profile>` | 覆盖全局 profile（`core` 或 `custom`）|

可用的 `--tools` ID 清单见 [04-supported-tools/tool-ids.md](../04-supported-tools/tool-ids.md)。

### 默认行为

不带任何参数时，用全局 config 的默认值：
- profile = `core`（4 个 workflow）
- delivery = `both`（skill + command 都装）
- workflows = `propose, explore, apply, archive`

并会进入交互菜单选择要配哪些工具。

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

# 临时用 core profile 跑一次 init
openspec init --profile core
```

---

## `openspec update`

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
- `openspec config profile` 的结果让 profile-sync-drift 报 warning 时（代码见 [src/core/profile-sync-drift.ts](../../src/core/profile-sync-drift.ts)）

---

## §3 单项目隔离 —— 只让 OpenSpec 影响一个项目，其它项目完全不动

> 答：**完全可以**，OpenSpec 设计上就是项目级隔离的。下面把所有可能的"漏出"路径列清楚，让你心里有底。

### 3.1 安装 CLI 本身有几种姿势

`npm install -g @fission-ai/openspec` 只是把 `openspec` 这个二进制放进全局 PATH，**不会**自动接管任何项目。CLI 在哪都能跑，但**你不主动在某个项目里执行 `openspec init`，那个项目就跟 OpenSpec 完全无关**。

如果你连"全局 PATH 多个 binary"都觉得多余，三种避免方案：

| 安装方式 | 命令 | 适用场景 |
|---------|------|---------|
| **全局装**（推荐） | `npm install -g @fission-ai/openspec@latest` | 你经常用 OpenSpec |
| **不装，按需用** | `npx @fission-ai/openspec init` | 只想试试 / 只用一次 |
| **项目级 devDep** | `npm install -D @fission-ai/openspec` 然后 `npx openspec init` | 想把 OpenSpec 版本锁在 `package.json` 里，团队成员各自用各自版本 |

> postinstall 脚本（[scripts/postinstall.js](../../scripts/postinstall.js)）只打一行 tip 提示你可以装 shell 自动补全，**不写任何文件、不开 daemon、不改 PATH**——`npm install` 本身是无副作用的。

### 3.2 `openspec init` 写的东西全部在 cwd 内

`openspec init [path]` 只在 **`path`（默认当前目录）** 内写文件。具体写哪些前面在 [§"会创建什么"](#会创建什么) 已列出，本质上就两类：

```text
<你的项目>/
├── openspec/                           ← OpenSpec 项目数据
│   ├── specs/  changes/  config.yaml
└── .<tool>/                            ← 你选的 AI 工具的 skill/command
    ├── skills/openspec-*/SKILL.md
    └── commands/opsx-*.md
```

**别的项目目录不会被碰**——OpenSpec 是纯被动 CLI，不扫盘、不监听文件改动、不跑 daemon。

### 3.3 唯一的 3 个"全局"漏出点（要心里有数）

虽然 `init` 写的是项目内文件，但有三处**理论上**会跨项目共享。绝大多数人**不会触发**，列出来防误踩：

#### ① Codex 的全局 prompts（**最容易踩**）

```text
$CODEX_HOME/prompts/opsx-*.md
（默认 ~/.codex/prompts/）
```

**触发条件**：你 `openspec init` 时选了 `codex` 这个工具。

**影响**：你**所有用 Codex CLI 的项目**都会看到 `/opsx-*` 命令——即使那些项目没有 `openspec/` 目录。

**这是 Codex 自己的设计决定**，不是 OpenSpec 的 bug——Codex 把 prompts 放在 `$CODEX_HOME` 是它的官方约定。

**规避**：`init` 时**别勾 codex**，或者用 `--tools claude,cursor`（只选其它项目级工具）。

#### ② 全局 CLI 配置文件

```text
~/.config/openspec/config.json    # macOS/Linux
%APPDATA%/openspec/config.json    # Windows
```

存的是 `openspec config` 设置（profile、delivery、workflows、featureFlags）。

**它只在 `openspec init / update` 跑的时候被读**，作为默认值的来源。**不会影响没有 `openspec/` 目录的项目**——因为 OpenSpec CLI 在那些项目里压根不会被触发。

但如果你在两个项目都用 OpenSpec，**改了全局 config 会影响下次在任意项目跑 `init/update` 时的默认值**。

**规避**：每次 init 时用 `--profile` / `--tools` **显式指定**，绕开全局默认。

#### ③ 用户级自定义 schema

```text
~/.local/share/openspec/schemas/<name>/    # macOS/Linux
%LOCALAPPDATA%/openspec/schemas/<name>/    # Windows
```

只有你**手动跑** `openspec schema fork ... --location user` 之类才会出现，**默认安装下这个目录是空的**。

如果存在，会被所有项目**作为 schema 解析的中间层**（项目 > 用户 > 包内置）。

**规避**：默认就不存在，不主动建就没事。

### 3.4 没装 OpenSpec / 没 `openspec/` 目录的项目，OpenSpec 完全不存在

具体来说，对一个**没有 `openspec/` 目录**的项目：

| 行为 | 是否发生 |
|------|---------|
| 你打开这个项目时 OpenSpec 自动启动 | ❌ |
| OpenSpec 写任何文件到这个项目 | ❌ |
| OpenSpec 修改这个项目的 git/config/package.json | ❌ |
| 这个项目的 AI agent 看到任何 OpenSpec skill/command | ❌（除了 Codex 全局例外）|
| OpenSpec 跑后台进程占资源 | ❌ |

OpenSpec 是**纯按需 CLI**——你不键入 `openspec ...` 它就不存在。

### 3.5 推荐的多项目隔离实践

按你的"有的项目要、有的项目不要"场景：

```bash
# ──── 项目 A：要 OpenSpec ────
cd ~/code/project-a
openspec init --tools claude,cursor      # 只装这俩，避开 codex 全局
# 结果：~/code/project-a/openspec/、.claude/、.cursor/ 都建好

# ──── 项目 B：不要 OpenSpec ────
cd ~/code/project-b
# 啥也不干 → OpenSpec 在这个项目不存在

# ──── 项目 C：临时试一次，不想留痕 ────
cd ~/code/project-c
npx @fission-ai/openspec init --tools claude
# 用完想清掉:
rm -rf openspec .claude/skills/openspec-* .claude/commands/opsx
```

### 3.6 已经踩坑了怎么救

**情况 A**：之前不小心选了 codex，现在 Codex 在所有项目都看到 `/opsx-*` 命令

```bash
rm -f ~/.codex/prompts/opsx-*.md
# 或 $CODEX_HOME/prompts/opsx-*.md
```

**情况 B**：想清掉某个项目的 OpenSpec 痕迹

```bash
cd <project>
rm -rf openspec
rm -rf .claude/skills/openspec-* .claude/commands/opsx
rm -rf .cursor/skills/openspec-* .cursor/commands/opsx-*.md
rm -rf .clinerules/workflows/opsx-*.md
# ... 其它工具同理（看 04-supported-tools/installation-paths.md）
```

**情况 C**：想完全卸载 OpenSpec CLI 本身

```bash
npm uninstall -g @fission-ai/openspec
rm -rf ~/.config/openspec       # 全局配置
rm -rf ~/.local/share/openspec  # 用户级 schema（如果有）
```

### 3.7 一句话结论

> **OpenSpec 是项目级隔离的。** 全局装的只是 CLI binary，没在哪个项目跑过 `init`，那个项目就跟 OpenSpec 没有任何关系。**唯一例外是 Codex**：选了 codex 工具会写全局 `$CODEX_HOME/prompts/`，要规避就别在 init 时勾 codex。

详见 [04-supported-tools/installation-paths.md §3 安装的副作用与触发模型](../04-supported-tools/installation-paths.md#3-安装的副作用与触发模型)。
