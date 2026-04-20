# 每个工具的安装路径

来源：[docs/supported-tools.md](../../docs/supported-tools.md)。`<id>` 是具体的 workflow id（`propose` / `apply` / `archive` 等）。

## 完整路径表

| 工具 | Skills 路径 | Commands 路径 |
|------|-------------|---------------|
| Amazon Q Developer | `.amazonq/skills/openspec-*/SKILL.md` | `.amazonq/prompts/opsx-<id>.md` |
| Antigravity | `.agent/skills/openspec-*/SKILL.md` | `.agent/workflows/opsx-<id>.md` |
| Auggie | `.augment/skills/openspec-*/SKILL.md` | `.augment/commands/opsx-<id>.md` |
| IBM Bob Shell | `.bob/skills/openspec-*/SKILL.md` | `.bob/commands/opsx-<id>.md` |
| Claude Code | `.claude/skills/openspec-*/SKILL.md` | `.claude/commands/opsx/<id>.md` |
| Cline | `.cline/skills/openspec-*/SKILL.md` | `.clinerules/workflows/opsx-<id>.md` |
| CodeBuddy | `.codebuddy/skills/openspec-*/SKILL.md` | `.codebuddy/commands/opsx/<id>.md` |
| Codex | `.codex/skills/openspec-*/SKILL.md` | **`$CODEX_HOME/prompts/opsx-<id>.md`** ⚠️ |
| ForgeCode | `.forge/skills/openspec-*/SKILL.md` | **无**（只有 skill） |
| Continue | `.continue/skills/openspec-*/SKILL.md` | `.continue/prompts/opsx-<id>.prompt` |
| CoStrict | `.cospec/skills/openspec-*/SKILL.md` | `.cospec/openspec/commands/opsx-<id>.md` |
| Crush | `.crush/skills/openspec-*/SKILL.md` | `.crush/commands/opsx/<id>.md` |
| Cursor | `.cursor/skills/openspec-*/SKILL.md` | `.cursor/commands/opsx-<id>.md` |
| Factory Droid | `.factory/skills/openspec-*/SKILL.md` | `.factory/commands/opsx-<id>.md` |
| Gemini CLI | `.gemini/skills/openspec-*/SKILL.md` | `.gemini/commands/opsx/<id>.toml` |
| GitHub Copilot | `.github/skills/openspec-*/SKILL.md` | `.github/prompts/opsx-<id>.prompt.md` ⚠️ |
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

## 四类路径约定

按 commands 放哪里，可以分成四类：

1. **`commands/opsx-<id>.md`**（扁平）——大多数工具用这种：auggie / bob / codebuddy(x) / cursor / factory / iflow / junie / opencode / roocode 等
2. **`commands/opsx/<id>.md`**（命名空间子目录）——claude / codebuddy / crush / qoder
3. **`workflows/opsx-<id>.md`**（workflows 目录）——antigravity / cline / kilocode / windsurf
4. **`prompts/opsx-<id>.md`**（prompts 目录）——amazon-q / codex(全局) / continue(.prompt) / github-copilot / kiro / pi

## 特殊情况总结

| 工具 | 特殊之处 |
|------|---------|
| **Codex** | commands 装到 **全局目录**（`$CODEX_HOME/prompts/` 或 `~/.codex/prompts/`），不是项目内。这样同一套命令跨所有项目共享 |
| **ForgeCode / Trae** | **没有 command adapter**，只装 skill，用 `/openspec-<skill>` 触发 |
| **GitHub Copilot** | `.github/prompts/*.prompt.md` **只有 IDE 扩展认**（VS Code、JetBrains、Visual Studio）。**Copilot CLI 不支持**自定义 prompt 文件 |
| **Gemini / Qwen** | 用 TOML 格式（`.toml`），不是 Markdown |
| **Continue** | 扩展名 `.prompt`（不是 `.md`）|
| **Kiro** / **GitHub Copilot** | 扩展名 `.prompt.md` |
| **GitHub Copilot 检测** | 不是靠 `.github/skills/` 目录判断是否要装，而是看 `.github/copilot-instructions.md`、`.github/prompts/`、`.github/agents/` 等**多种路径**（见 [config.ts:37](../../src/core/config.ts)）|

## 把整个规律记住一句话

> 绝大多数工具是 `.<dir>/skills/openspec-*/SKILL.md` + `.<dir>/commands/opsx-<id>.md`。剩下的记住四个特例（Codex 全局、Forge/Trae 无 command、Copilot 仅 IDE、Gemini/Qwen 用 TOML）就够了。
