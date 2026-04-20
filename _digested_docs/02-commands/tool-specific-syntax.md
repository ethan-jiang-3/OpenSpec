# 不同 Agent 的命令语法差异

同一套 OPSX workflow，在不同 coding agent 里的斜杠命令写法**不完全一样**。来源：[docs/commands.md](../../docs/commands.md) 的 "Command Syntax by AI Tool" 小节。

## 总表

| AI 工具 | 斜杠命令风格 | 示例 |
|---------|------------|------|
| **Claude Code** | 冒号分隔 | `/opsx:propose`、`/opsx:apply` |
| **Cursor** | 横杠分隔 | `/opsx-propose`、`/opsx-apply` |
| **Windsurf** | 横杠分隔 | `/opsx-propose`、`/opsx-apply` |
| **GitHub Copilot（IDE 扩展）** | 横杠分隔 | `/opsx-propose`、`/opsx-apply` |
| **Trae** | **没有 command 文件**，用 skill 触发 | `/openspec-propose`、`/openspec-apply-change` |
| **ForgeCode** | 同 Trae，只走 skill | `/openspec-propose`、`/openspec-apply-change` |

> 其它工具默认都是 `opsx-<id>` 或 `opsx:<id>`，具体看 [04-supported-tools/installation-paths.md](../04-supported-tools/installation-paths.md)。

## 为什么会有差异

**命令文件格式不同**。每个 coding agent 有自己的目录约定和文件格式：

- Claude Code 支持 `.claude/commands/opsx/<id>.md` 这种 **带子目录的命名空间** → 所以用 `/opsx:<id>`
- Cursor 的 `.cursor/commands/` **不支持子目录**，所以文件名是 `opsx-<id>.md` → 命令是 `/opsx-<id>`
- Gemini / Qwen 用 TOML 格式（`.gemini/commands/opsx/<id>.toml`）
- Continue 用 `.continue/prompts/opsx-<id>.prompt`
- Codex 装到**全局**（`$CODEX_HOME/prompts/` 或 `~/.codex/prompts/`）

详细路径见 [04-supported-tools/installation-paths.md](../04-supported-tools/installation-paths.md)。

## 没有 command adapter 的工具（Trae / ForgeCode）

这两个工具的命令 adapter 在 [src/core/command-generation/adapters/](../../src/core/command-generation/adapters/) **里没有对应文件**。OpenSpec 只给它们装 skill，于是 agent 通过 skill 机制被触发，用 `/openspec-<skill-dir-name>` 这种形式召唤（skill 目录名见 [command-to-skill-map.md](command-to-skill-map.md)）。

## GitHub Copilot 的特殊坑

`.github/prompts/*.prompt.md` **只在 IDE 扩展**（VS Code / JetBrains / Visual Studio）里被识别为斜杠命令。

**Copilot CLI 当前不支持这种 prompt 文件**——见 [docs/supported-tools.md](../../docs/supported-tools.md) 脚注。

## 实战提示

- 跨团队用多种工具时，**文档里别写死某一种语法**，写 `/opsx:xxx`（或 `/opsx-xxx`）都标注清楚
- 本消化笔记统一用 Claude 风格 `/opsx:xxx`
- 不确定的话：在项目根目录找对应工具的 `commands/` 或 `prompts/` 看一眼文件名就知道了
