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

这张表描述的是投递策略，不是每个工具都必然支持三种形态。Codex 是 **skills-only**：无论全局 `delivery` 设为 `skills`、`commands` 还是 `both`，OpenSpec 都生成 `.agents/skills/openspec-*/SKILL.md`（此前是 `.codex/skills/`），不生成 command/prompt 文件；`update` 会在有匹配 replacement skill 时清理旧的托管 Codex prompts。

### 共享 `.agents` 根与通用写入权仲裁

`.agents/skills/` 由 `agents`、`codex`、`zed` 三方共享。将共享根仲裁从硬编码三元组升级为通用 `resolveSharedSkillWriters()` 机制：

1. **Antigravity 迁入 `.agents/` 共享根**：`antigravity` 的 `skillsDir` 从 `.agent` 改为 `.agents`（`.agent` 变成 `legacySkillsDirs`），旧 `.agent/workflows/openspec-*.md` 在 update 时被迁移或保留用户定制。检测键现在是 `.agent` 或 `.agents/workflows`（而非裸 `.agents/` 根）。

2. **通用写入权仲裁**（新增 `src/core/shared-skill-target.ts` 的 `resolveSharedSkillWriters`）：不再硬编码 Codex/Zed/agents 三方的排序规则。该函数遍历所有选中工具的 `skillsDir`，对每个共享物理根（如 `.agents/skills/`）选出一个 active writer：
   - **已有 compatible owner**（通过 `.openspec-target` marker 或推断）胜出。
   - **skills-native 渲染器优先于 adapter-backed**，因为其引用可被共享树的所有消费者使用。
   - **新根默认指向 Codex**，因为其渲染器同时包含 Codex 和通用 skill 调用形式。
   - 只有 active writer 生成 skill 文件；其他共享同一根的选中工具仍能独立写入 command surface（如 Antigravity 在 Codex 拥有 `.agents/skills/` 写入权时仍可安装 `.agents/workflows/` command 文件）。

3. **`openspec init` 和 `openspec update` 均使用同一仲裁**：`init.ts` 和 `update.ts` 都调用 `resolveSharedSkillWriters`，确保初始化和增量更新使用相同的写入权判定。

4. **遗留检测改进**（`src/core/shared/tool-detection.ts`）：`getConfiguredTools` 现在也检测有 legacy skills 的 adapter-backed 工具，避免 `openspec update` 因未检测到旧 `.agent/` 树而重置 Antigravity。

因此 `.agents/skills/` 的写入权规则不再是三方协议，而是一个可扩展的通用仲裁策略：任一新工具只要共享 `skillsDir` 都能自动参与，无需修改仲裁代码。

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

### init/update 的行为补强

- **`.gitkeep`**：`init` 为空目录写 `.gitkeep` 占位——空目录不进 Git，初始化骨架一旦 commit 就丢空目录结构。重跑 init 恢复缺失的目录 marker，不覆盖已有文件、不跟随 marker symlink。
- **共享 IDE restart 提示**：`src/core/shared/ide-restart.ts` 提供 `"Restart your IDE to refresh commands."` / `"Restart your IDE to refresh skills."`，`init.ts` 与 `update.ts` 共用同一来源；message 覆盖「移除 workflow」场景，不再声称生成了新文件。措辞和条件单一来源，不再漂移。
- **命名 profile 遗漏的工作流**：`src/core/onboarding-commands.ts` 新增 `formatOptionalWorkflowsNote(installedWorkflows)`——返回 profile 没装的 workflow 名单（`new`、`continue`、`ff`、`bulk-archive`、`verify`、`onboard`），全装齐返回 null。`init`/`update` 输出里显式列出这些可加项和 `openspec config profile` 命令，没装的命令不再读起来像「setup 坏了」。
- **update 检测损坏的 command 文件**：之前只比对 skill 文件的 `generatedBy` 版本戳——skill 是新版本就报「All up to date」，但旁边手改/截断的 command 文件完全没被检查。现在 update 也比对 command 文件内容（只针对 skills+commands 都配置的工具；commands-only 路径不变），`--force` 之外多了一条修复路径。

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
| Codex | `.agents/skills/openspec-*/SKILL.md` | skills-only；以 `$openspec-*` 调用，`.codex` 是 legacy 迁移源 |
| agents（通用） | `.agents/skills/openspec-*/SKILL.md` | vendor-neutral 目标，与 Codex、Zed、Antigravity 共享 `.agents` 根 |
| GitHub Copilot | `.github/skills/` 等 | 本地 skill + opt-in cloud coding-agent 文件（见下） |
| Antigravity | `.agents/skills/` + `.agents/workflows/opsx-<id>.md` | 从 `.agent` 迁入 `.agents`；共享技能根通过 `resolveSharedSkillWriters` 仲裁。`.agent` 是 legacy 迁移源 |
| Command Code | `.commandcode/skills/` + `.commandcode/commands/opsx-<id>.md` | adapter-backed：skills 调用 `/openspec-*`，slash command 为 `/opsx-<id>` |
| Code Assistant | `.codeassistant/commands/opsx-<id>.md` | adapter-backed：SourceCraft Code Assistant（VS Code 扩展）的 slash command 面，YAML frontmatter（description），`/opsx-*` 形式 |
| Zed Agent | `.agents/skills/openspec-*/SKILL.md` | skills-only；Zed 1.4.2+ 用 `/openspec-*` 或 `@openspec-*`，不生成 `/opsx` command |
| OpenCode | `.opencode/commands/opsx-<id>.md` | 接受输入的 command 在完整 `**Input**` block 后注入一次 `**Provided arguments**: $ARGUMENTS` |

这个差异很重要：不是所有 command artifacts 都在 repo root 下。delivery 层要尊重每个工具的发现机制。

OpenCode 只有在正文没有 `$ARGUMENTS`/位置参数占位符、且 Input 不是 `None required` 时才注入；已有占位符绝不重复。这是 adapter 的参数传递修复，不应套到 Zed 的 skill invocation 上。

遗留迁移路径遵守同一条 one-writer 规则：若 `.agents` 已被某个工具占用（marker 或已有树），`openspec update` **不会**凭全局信号把 skills 改写成另一工具语法、也不会翻 ownership。`resolveSharedSkillWriters` 决定哪个工具是 active writer，其他共享同一物理根的工具跳过 skill 生成但保留 command surface。跳过时该工具的 repo-local legacy 文件（如 `.agent/workflows/` 或 `.codex/prompts/openspec-*.md`）一并保留。真正的首次安装（还没有 `.agents` 树）不受影响。

## GitHub Copilot：本地 skill 与 opt-in cloud coding-agent

GitHub Copilot 是一等工具目标，但被拆成两层，其中 cloud 层默认不生成：

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
| command adapters | `src/core/command-generation/`（含 `adapters/command-code.ts`、`adapters/opencode.ts`、`adapters/codeassistant.ts`） |
| init/update | `src/core/init.ts`、`src/core/update.ts`、`src/core/shared/ide-restart.ts`、`src/core/onboarding-commands.ts` |
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
