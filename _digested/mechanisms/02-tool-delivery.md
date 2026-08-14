# Tool Delivery

## 它解决的是 agent 生态差异

OpenSpec 的核心 workflow 语义不应绑定在某个 AI Coding 工具上。Claude、Codex、Cursor、OpenCode、Gemini 等工具对“如何发现指令”的约定不同：有的看 skills，有的看 slash commands，有的只支持 skills，有的把 command 文件放在项目内目录。

Tool delivery 这一层的核心判断是：**稳定资产是 workflow 语义；skills 和 commands 只是投递外壳。**

```text
profile/workflows
  → workflow templates
  → skill / command content
  → per-tool skillsDir / command adapter path
  → agent 可发现的入口文件
```

这解释了为什么 OpenSpec 不把“Claude command 文件”或“Codex skill 文件”当成项目事实。它们是生成物，可以随 profile、delivery、版本和工具支持变化而同步。

## 三层对象

| 层 | 源码 | 作用 |
|----|------|------|
| tool registry | `AI_TOOLS` in `src/core/config.ts` | 工具 id、skillsDir、检测路径 |
| workflow content | `src/core/templates/workflows/`、`src/core/shared/skill-generation.ts` | 工具无关的 workflow 指令 |
| tool-specific shell | `src/core/command-generation/adapters/` | command 文件路径和 frontmatter 格式 |

这三层分开后，新增 workflow 和新增 agent 工具就不是同一个问题。新增 workflow 主要改模板和 profile；新增工具主要改 registry、adapter 和测试。

## skill 与 command 的生成链

workflow 文本来自 `src/core/templates/workflows/`。每个 workflow 通常同时导出：

- skill template：给 agent 自动发现。
- command template：给 slash/prompt command 文件。

`src/core/shared/skill-generation.ts` 把这些模板映射成：

- `getSkillTemplates(workflowFilter?)`
- `getCommandTemplates(workflowFilter?)`

filter 来自 profile resolved workflow ids。

skill 生成链：

```text
SkillTemplate
  → generateSkillContent(template, version, transform?)
  → YAML frontmatter + instructions
  → <tool skillsDir>/skills/<dirName>/SKILL.md
```

command 生成链：

```text
CommandTemplate
  → CommandContent
  → CommandAdapterRegistry.get(toolId)
  → generateCommands()
  → adapter.getFilePath(id)
  → adapter.formatFile(content)
```

`CommandContent` 是工具无关结构：`id`、`name`、`description`、`category`、`tags`、`body`。adapter 只处理“放在哪里”和“外壳怎么写”，不改 workflow 语义。

## profile 与 delivery

repo-local init/update 根据 global config 的 `delivery` 分流：

| delivery | 行为 |
|----------|------|
| `skills` | 只生成 skills，并删除 managed commands |
| `commands` | 只生成 commands，并删除 managed skills |
| `both` | 两者都生成 |

这张表描述的是投递策略，不是每个工具都必然支持三种形态。v1.8.0 的 Codex 是 **skills-only**：无论全局 `delivery` 设为 `skills`、`commands` 还是 `both`，OpenSpec 都生成 `.agents/skills/openspec-*/SKILL.md`（v1.7.0 时代是 `.codex/skills/`），不生成 command/prompt 文件；`update` 会在有匹配 replacement skill 时清理旧的托管 Codex prompts。

### v1.8.0：共享 `.agents` 根与 vendor-neutral `agents` 目标

v1.8.0 引入两个相关变化：

1. **新增 vendor-neutral `agents` 目标**（`--tools agents`）：把 skills 装进 `.agents/skills/openspec-*/SKILL.md`，这是 AGENTS.md 兼容 assistant 的共享落点，不属于任何单一工具。`--tools all` 会包含它并创建 `.agents/skills/`。检测键是 `.agents/skills` 而非 `.agents` 根（框架常为别的东西用 `.agents/`）。
2. **Codex 迁入同一个 `.agents` 根**：`codex` 的 `skillsDir` 从 `.codex` 改为 `.agents`（`.codex` 变成 `legacySkillsDirs`），update 会原地迁移旧 `.codex` 树并保留用户定制文件。

因此 `.agents/skills/` 现在可能同时被 `agents` 与 `codex` 两个目标使用。共享根同一时刻只能有一个 active writer：`src/core/shared-skill-target.ts` 用 `.openspec-target` marker 文件记录谁在写这个根；没有 marker 时按已生成文件的 invocation 语法推断（`$openspec-` → codex，`/openspec-` → agents），找不到归属且已有 canonical 树时保留既有的 `agents` 含义。`--tools codex` 与 `--tools agents` 并发选择时由该逻辑收敛到单个 writer。

profile 决定安装哪些 workflow，delivery 决定以什么形态投递。两者组合起来回答两个不同问题：

- 这套 OpenSpec 要给 agent 哪些动作？
- 这些动作在当前工具里以什么入口出现？

workspace update 是例外：当前只生成 skills，即使 global delivery 是 `both` 或 `commands`，也会给出 skills-only notice。这是 workspace 作为本机协调视图的限制，不应误读成所有投递路径都支持 workspace command。

## init/update 的系统职责

`InitCommand.execute()` 做的不是单纯 mkdir，而是一次投递初始化：

1. 校验目标路径。
2. 检测 legacy artifacts。
3. 检测 available tools。
4. 必要时迁移旧安装。
5. 选择工具。
6. 创建 `openspec/` 基础结构。
7. 根据 profile/delivery 生成 skills/commands。
8. 创建或保留 `openspec/config.yaml`。

`UpdateCommand.execute()` 是声明式同步器：

1. 确认 `openspec/` 存在。
2. 根据现有工具目录迁移。
3. 读取 global profile/delivery。
4. 处理 legacy cleanup。
5. 检测 configured tools。
6. 比较 version drift 和 profile/delivery drift。
7. 只更新需要同步的工具，或在 `--force` 下全量更新。
8. 删除取消选择的 skill/command 产物。

所以 update 可能删除 OpenSpec 管理的工具侧文件，但不应删除用户业务文件。

## drift 为什么重要

`src/core/profile-sync-drift.ts` 负责判断工具侧安装状态是否和当前配置一致。drift 来源包括：

- global profile 从 `core` 改成 `custom`。
- custom workflows 列表变化。
- delivery 从 `both` 改成 `skills` 或 `commands`。
- 某个工具目录里还留有不再选择的 workflow。

这解释了为什么版本没变时也可能需要 update。OpenSpec 管理的是声明式投递状态，不只是“当前 CLI 版本是否更新”。

## command adapters 的边界

`ToolCommandAdapter` 只有两个核心方法：

```ts
getFilePath(commandId: string): string
formatFile(content: CommandContent): string
```

这说明 adapter 不参与 workflow 推理，也不参与 artifact 状态判断。它只负责 tool-specific command surface。

典型差异：

| 工具 | command 位置 | 说明 |
|------|--------------|------|
| Claude | `.claude/commands/opsx/<id>.md` | 项目内 command 文件，带 frontmatter |
| Codex | `.agents/skills/openspec-*/SKILL.md` | v1.8.0 skills-only；以 `$openspec-*` 调用，`.codex` 是 legacy 迁移源 |
| agents（通用） | `.agents/skills/openspec-*/SKILL.md` | v1.8.0 vendor-neutral 目标，与 Codex 共享 `.agents` 根 |
| GitHub Copilot | `.github/skills/` 等 | v1.8.0 本地 skill + opt-in cloud coding-agent 文件（见下） |
| Command Code | `.commandcode/skills/` + `.commandcode/commands/opsx-<id>.md` | v1.9.0 adapter-backed：skills 调用 `/openspec-*`，slash command 为 `/opsx-<id>` |

这个差异很重要：不是所有 command artifacts 都在 repo root 下。delivery 层要尊重每个工具的发现机制。

v1.9.0 起，遗留 Codex 升级路径也遵守同一条 one-writer 规则：若 `.agents` 已被 `agents` 目标占用（marker 或已有树），`openspec update` **不会**凭全局 `~/.codex/prompts` 把 skills 改写成 Codex 语法、也不会翻 ownership；跳过时该工具的 repo-local legacy 文件（如 `.codex/prompts/openspec-*.md`）一并保留。真正的首次 Codex 升级（还没有 `.agents` 树）不受影响。

## GitHub Copilot：本地 skill 与 opt-in cloud coding-agent

GitHub Copilot 是 v1.8.0 的一等工具目标，但被拆成两层，其中 cloud 层默认不生成：

| 层 | 产物 | 默认 |
|----|------|------|
| 本地 skill | `.github/skills/` 下的 OpenSpec skills | `--tools github-copilot` 时生成 |
| cloud coding-agent 文件 | `.github/workflows/copilot-setup-steps.yml`（预装 CLI）+ `.github/agents/openspec.agent.md`（定制 agent 说明） | **opt-in**，默认 No |

cloud 文件写入 `.github/` 是有侵入性的动作，所以由 `openspec init` 交互询问（非交互用 `--copilot-cloud` / `--no-copilot-cloud`），选择记入 `openspec/config.yaml` 的 `githubCopilot.cloudAgent`。`openspec update` 从不提示：只刷新已 opt-in、或已存在 managed cloud 文件的旧项目（视为隐含 opt-in）；用户自己改过的文件永不覆盖/删除；opt-out 只删除 managed 文件，保留用户定制。逻辑见 `src/core/github-copilot/cloud-agent.ts`。

## 工程洞察

- OpenSpec 把 workflow 语义和工具外壳解耦，避免核心机制被某个 agent 平台锁死。
- profile/delivery 是投递声明，init/update 是把声明同步到工具侧文件系统。
- adapter 是格式化边界，不应该承载 workflow 判断。
- legacy cleanup 只应清理 OpenSpec 管理过的投递 artifacts 和 marker，不能成为任意文件删除器。

## 源码锚点

| 机制 | 路径 |
|------|------|
| tool registry | `AI_TOOLS` in `src/core/config.ts` |
| tool detection | `src/core/available-tools.ts`、`src/core/shared/tool-detection.ts` |
| skill/command content | `src/core/shared/skill-generation.ts` |
| shared skill root ownership | `src/core/shared-skill-target.ts`（`.openspec-target` marker） |
| GitHub Copilot cloud agent | `src/core/github-copilot/cloud-agent.ts` |
| workflow templates | `src/core/templates/workflows/` |
| command adapters | `src/core/command-generation/`（含 `adapters/command-code.ts`） |
| init/update | `src/core/init.ts`、`src/core/update.ts` |
| profile drift | `src/core/profile-sync-drift.ts` |
| migration / cleanup | `src/core/migration.ts`、`src/core/legacy-cleanup.ts` |

## 测试锚点

- `test/core/init.test.ts`
- `test/core/update.test.ts`
- `test/core/command-generation/`
- `test/core/shared/`
- `test/core/profile-sync-drift.test.ts`
- `test/core/migration.test.ts`
- `test/core/legacy-cleanup.test.ts`
