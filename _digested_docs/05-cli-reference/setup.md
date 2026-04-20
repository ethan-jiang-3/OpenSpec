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
