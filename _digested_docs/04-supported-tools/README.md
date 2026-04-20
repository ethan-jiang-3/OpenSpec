# 04 · 支持的 Coding Agent

## 一句话

OpenSpec 在 [src/core/config.ts](../../src/core/config.ts) 的 `AI_TOOLS` 数组里声明了 **28 个可安装的 coding agent**，每个在 [src/core/command-generation/adapters/](../../src/core/command-generation/adapters/) 有独立适配器。此外有一个 `agents`（AGENTS.md）的**兜底选项**，不属于直接支持但可以作为「我的工具不在列表里」的后备方案。

## 28 个支持的工具总表

来源：[src/core/config.ts](../../src/core/config.ts) 第 21–50 行。按字母排序：

| # | 显示名 | ID（`--tools` 用） | skillsDir | 有 Command Adapter? |
|---|--------|---------------------|-----------|---------------------|
| 1 | Amazon Q Developer | `amazon-q` | `.amazonq` | ✔ |
| 2 | Antigravity | `antigravity` | `.agent` | ✔ |
| 3 | Auggie（Augment CLI） | `auggie` | `.augment` | ✔ |
| 4 | Bob Shell（IBM） | `bob` | `.bob` | ✔ |
| 5 | Claude Code | `claude` | `.claude` | ✔ |
| 6 | Cline | `cline` | `.cline` | ✔ |
| 7 | Codex | `codex` | `.codex` | ✔（装到全局）|
| 8 | CodeBuddy Code（CLI） | `codebuddy` | `.codebuddy` | ✔ |
| 9 | Continue | `continue` | `.continue` | ✔ |
| 10 | CoStrict | `costrict` | `.cospec` | ✔ |
| 11 | Crush | `crush` | `.crush` | ✔ |
| 12 | Cursor | `cursor` | `.cursor` | ✔ |
| 13 | Factory Droid | `factory` | `.factory` | ✔ |
| 14 | ForgeCode | `forgecode` | `.forge` | ✘（只有 skill） |
| 15 | Gemini CLI | `gemini` | `.gemini` | ✔（TOML 格式）|
| 16 | GitHub Copilot | `github-copilot` | `.github` | ✔（仅 IDE 扩展）|
| 17 | iFlow | `iflow` | `.iflow` | ✔ |
| 18 | Junie | `junie` | `.junie` | ✔ |
| 19 | Kilo Code | `kilocode` | `.kilocode` | ✔ |
| 20 | Kiro | `kiro` | `.kiro` | ✔ |
| 21 | Lingma | `lingma` | `.lingma` | ✔（源码有，docs 未列）|
| 22 | OpenCode | `opencode` | `.opencode` | ✔ |
| 23 | Pi | `pi` | `.pi` | ✔ |
| 24 | Qoder | `qoder` | `.qoder` | ✔ |
| 25 | Qwen Code | `qwen` | `.qwen` | ✔（TOML 格式）|
| 26 | RooCode | `roocode` | `.roo` | ✔ |
| 27 | Trae | `trae` | `.trae` | ✘（只有 skill） |
| 28 | Windsurf | `windsurf` | `.windsurf` | ✔ |
| — | **AGENTS.md（兜底）** | `agents` | — | `available: false`，不在安装菜单里 |

> **Lingma 注意**：源码里有（包括 [adapters/lingma.ts](../../src/core/command-generation/adapters/lingma.ts)），但官方 [docs/supported-tools.md](../../docs/supported-tools.md) 暂未列出。这是 docs 滞后于代码。

## 三类安装差异

1. **只有 skill 没有 command**（2 个）：`forgecode`、`trae` —— agent 通过 skill 机制自己发现，用户用 `/openspec-<skill-name>` 触发
2. **装到全局目录**（1 个）：`codex` 的 commands 装到 `$CODEX_HOME/prompts/`（默认 `~/.codex/prompts/`）
3. **只在 IDE 扩展生效**（1 个）：`github-copilot` 的 `.github/prompts/*.prompt.md` 只被 VS Code / JetBrains / Visual Studio 扩展读取，**Copilot CLI 不认**

## 两种产物：Skills 和 Commands

每个工具根据 `openspec config` 里的 `delivery` 配置安装：

- **Skills**：`.{skillsDir}/skills/openspec-*/SKILL.md`，agent 自动发现（27 个工具格式一致）
- **Commands**：路径因工具而异，触发语法也不同（见 [installation-paths.md](installation-paths.md)）

## 本目录其它文档

- [installation-paths.md](installation-paths.md) — 每个工具的完整路径模板
- [tool-ids.md](tool-ids.md) — `--tools` flag 可以用的 id 清单（CI 用）
