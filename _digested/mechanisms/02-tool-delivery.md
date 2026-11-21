# Tool Delivery

## 它解决的是 agent 生态差异

OpenSpec 的核心 workflow 语义不应绑定在某个 AI Coding 工具上。Claude、Codex、Cursor、OpenCode、Gemini 等工具对“如何发现指令”的约定不同：有的看 skills，有的看 slash commands，有的只支持 skills，有的把 command 文件放在项目内目录。

Tool delivery 这一层的核心判断是：**稳定资产是 workflow 语义；skills（及 1.x 已退役的 commands）只是投递外壳。**

```text
profile / workflows
  → workflow templates
  → 单一标准 SKILL.md 文本（剥离 generatedBy）
  ├── global 作用域（新项目 init 默认）
  │     → ~/.agents/skills/<name>/SKILL.md + 工具全局目录（skills 包安装，离线 staging）
  └── project 作用域（--scope project 或已有项目级技能）
        → .agents/skills/<name>/SKILL.md（唯一真身）
        ├── 33 个 universal 工具直读 .agents/skills/
        └── 54 个建链工具在各自目录下建相对链接（Windows 或 eve 退化为拷贝）
```

（1.x 时这里还多一条 command 分支：`→ per-tool command adapter path → <tool>/commands/opsx/<id>.md`，v2.0.0 已移除。）

这解释了为什么 OpenSpec 不把“Claude 的 skill 目录”或“Codex 的 skill 文件”当成项目事实。它们是生成物，可以随 profile、版本和工具支持变化而同步——真正稳定的只有 workflow 语义。

## 三层对象与 `AI_TOOLS` 注册表结构

| 层 | 源码 | 作用 |
|----|------|------|
| tool registry | `AI_TOOLS` in `src/core/config.ts` | **87 个工具**（49 个手工维护 `existingTools` + 38 个从 `skills@1.8.1` 自动追加）、`SKILL_LINKED_TOOL_IDS`、`RETIRED_TOOLS`、`TOOL_ID_ALIASES` |
| workflow content | `src/core/templates/workflows/`、`src/core/shared/skill-generation.ts` | 工具无关且与 profile 无关的单一恒定 skill 指令 |
| skill 安装与旧壳清理 | `src/core/skill-installer.ts`、`src/core/global-skills.ts`、`src/core/shared/skill-links.ts` + `src/core/command-generation/adapters/` | `skills` 包离线安装与项目软链；34 个 1.x command adapters 仅留作旧命令文件路径识别与清理 |

`src/core/config.ts` 构造 `AI_TOOLS` 的精确公式值得钉牢：

- **87 个公开 `--tools` 目标 = 49 个 `existingTools` + 38 个从 `skills@1.8.1` `getSupportedAgents()`（共 79 个 agent）自动去重追加的工具**（过滤掉已在 `existingIds` 中的条目及 `windsurf`）。
- **14 个 `installerAliases`**：在 CLI 边界保留 OpenSpec 历史公开 ID，内部映射到 `skills` 包的 `agent.id`（`agents→universal`, `auggie→augment`, `claude→claude-code`, `codeartsagent→codearts-agent`, `factory→droid`, `gemini→gemini-cli`, `hermes→hermes-agent`, `iflow→iflow-cli`, `kilocode→kilo`, `kimi→kimi-code-cli`, `kiro→kiro-cli`, `qwen→qwen-code`, `roocode→roo`, `vibe→mistral-vibe`）。
- **9 个回退到 `'universal'` 的 `existingTools`**：`atomcode`、`costrict`、`dsh`、`easycode`、`gigacode`、`gsd`、`oh-my-pi`、`codeassistant`、`veai` 在 `skills@1.8.1` 中无独立条目，`installerAgent(id)` 回退到 `'universal'`，因此 **v2.1 下它们只写 `.agents/skills/`（不再创建 `.dsh/skills/`、`.veai/skills/` 等目录）**，并在安装后附带 `setupNote` 提示如需专属目录可自行建立链接。
- **别名与退役工具**：`TOOL_ID_ALIASES` 将 `--tools windsurf` 透明解析为 `devin`（Devin Desktop）；`RETIRED_TOOLS`（配合 `src/core/retired-tools.ts`）将 `amazon-q` 标记为已退役并指路 `kiro`（`openspec init --tools kiro`），`update` 会按指纹清理 `.amazonq` 遗留文件。

这几层拆开后：新增 workflow 主要改模板与 `profiles.ts`；新增工具主要由 `skills` 包或 `config.ts` 承接，**不再新增 command adapter**。

## skill 与 command 的生成链

workflow 文本来自 `src/core/templates/workflows/`。每个 workflow 通常同时导出：

- skill template：给 agent 自动发现。
- command template：给 slash/prompt command 文件。

`src/core/shared/skill-generation.ts` 把这些模板映射成：

- `getSkillTemplates(workflowFilter?)`
- `getCommandTemplates(workflowFilter?)`

filter 来自 profile resolved workflow ids。

skill 生成链（**v1.x**：每个工具各写一份）：

```text
SkillTemplate
  → generateSkillContent(template, version, transform?)
  → YAML frontmatter + instructions
  → <tool skillsDir>/skills/<dirName>/SKILL.md
```

skill 生成链（**v2.x：单一恒定文本 + 全局/项目双作用域**）：

```text
SkillTemplate
  → generateSkillContent(template, version, transformToSharedSkillReferences)
  → stripVolatileFrontmatter()（剥离 generatedBy: 行）
  ├── global 作用域：installReleaseSkills() 暂存至 os.tmpdir()/openspec-skills-*
  │     → skills 包离线写入 ~/.agents/skills/ 及各工具全局目录 + recordGlobalSkills() 写 .skill-lock.json
  └── project 作用域：写入 .agents/skills/<dirName>/SKILL.md（唯一真身）
        → SKILL_LINKED_TOOL_IDS（54 个工具）建相对软链（Windows 或 eve 退化为拷贝）
```

- **单一恒定文本**：v2.0.0 删除了 `src/core/templates/optional-workflow.ts`，`skill-generation.ts:57-58` 保证 `workflowFilter` 只决定返回哪些 skill，**绝不改变任何 skill 的正文**；`stripVolatileFrontmatter()` 进一步剥离 `generatedBy:`，使落盘内容与仓库静态 `skills/<name>/SKILL.md` 完全一致。
- **33 个直读 vs 54 个建链**（`src/core/config.ts` + `src/core/shared/skill-paths.ts`）：项目作用域下全部 87 个工具共享 `.agents/skills/` 真身。其中 **33 个** `installerAgent(toolId).universal === true` 的工具（含 `codex`、`cursor`、`gemini`、`github-copilot`、`cline`、`opencode`、`antigravity`、`zed`、`warp`、`amp`、`gsd`、`dsh`、`agents` 等）**直接读取 `.agents/skills/`，不建任何链接**；其余 **54 个**在 `SKILL_LINKED_TOOL_IDS` 中的工具在各自 `projectSkillsDir` 下为每个技能建立相对软链（POSIX），Windows 或 `eve` 退化为文件拷贝（`eve` 拷贝前还会经 `projectSkillText()` 剥离 `allowed-tools` frontmatter）。
- **Global vs Project 作用域（v2.1.0 + v2.1.1）**：
  - 全新项目跑 `openspec init` **默认采用 `global` 作用域**（解析优先级：`--tools none` → `project`；`--scope <global|project>`；项目已有自身技能 → `project`；`OPENSPEC_SKILLS_SCOPE` 环境变量；全局 `config.json` 的 `skillsScope`；传了 `--copilot-cloud` 或选中了**仅有的 2 个不支持全局技能的工具 `eve`、`promptscript`** → `project`；否则默认 `'global'`）。
  - `global` 作用域写入 `~/.agents/skills/` 及需独立全局目录的工具目录，由 `<globalDataDir>/global-skills.lock` 跨进程串行化，通过 `recordGlobalSkills()` 把 Git tree hash 记入 `$XDG_STATE_HOME/skills/.skill-lock.json`（未设时为 `~/.agents/.skill-lock.json`），并将项目路径记入 `<globalDataDir>/projects.json`（`known-projects.ts`）。
  - `project` 作用域写入 `.agents/skills/` 与链接，在 `.agents/skills/.openspec-target` 记录工具列表；当用户在 `openspec update` 中选择将技能留在项目内时，`project-skills-scope.ts` 会在 `openspec/config.yaml` 写入 `skillsScope: project`。
  - **离线安装（v2.1.1 `#2283`）**：`installReleaseSkills()`（`src/core/skill-installer.ts:78-120`）把当前 CLI 内置的 `expectedSkillContents(version)` 先写进本地临时目录 `os.tmpdir()/openspec-skills-*`，再将绝对路径交给 `skills` 包的 `installSkills()`——**完全离线，不需要本机装 `git` 也不访问 GitHub 网络**，且安装的技能文本永远与当前运行的 CLI 版本严格一致。

**技能内容有两个分发口子**（v2.x，二者内容必须一致）：

| 口子 | 载体 | 谁消费 | 一致性保障 |
|---|---|---|---|
| 运行时模板 | `src/core/templates/workflows/*.ts` → `expectedSkillContents()` | `openspec init` / `openspec update` 写进全局或项目 | 单元测试覆盖 |
| 静态分发 | 仓库里提交的 `skills/<name>/SKILL.md` | `npx skills add Fission-AI/OpenSpec`、skills.sh 这类从 GitHub 直读 `SKILL.md` 的安装器 | `test/core/templates/skillssh-parity.test.ts` 重新生成并与磁盘比对 |

静态分发由 `scripts/generate-skillssh.mjs` 生成（`pnpm build && pnpm generate:skills`），**不要在 `skills/` 下手工改**——parity 测试会挡住。两者内容不同源但必须同步：改了模板要重跑生成脚本。

command 生成链（**v2.0.0 起已移除，保留仅为读旧项目**）：

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

**v1.x** 的 repo-local init/update 根据 global config 的 `delivery` 分流（下表是历史形态）：

| delivery | 行为 |
|----------|------|
| `skills` | 只生成 skills，并删除 managed commands |
| `commands` | 只生成 commands，并删除 managed skills |
| `both` | 两者都生成 |

**v2.0.0 起 `delivery` 退役**（#2223）：配置里不再有这一项，一律 skills。写入被接受但不再改变任何东西。init/update 现在的分流只剩两个问题——这个工具怎么读 skills、以及旧文件该怎么清。

这张表描述的是投递策略，不是每个工具都必然支持三种形态。v1.8.0 的 Codex 是 **skills-only**：无论全局 `delivery` 设为 `skills`、`commands` 还是 `both`，OpenSpec 都生成 `.agents/skills/openspec-*/SKILL.md`（v1.7.0 时代是 `.codex/skills/`），不生成 command/prompt 文件；`update` 会在有匹配 replacement skill 时清理旧的托管 Codex prompts。

### v1.13.x 投递面补充

- **universal 目标的 picker 呈现**（`7de2404`）：vendor-neutral 目标在 `init` 工具选择器中显示为 **"Other / Universal (shared .agents skills)"**；搜索框可用 `universal`/`other`/`generic`/`custom`/`proprietary`/`unlisted`/`unsupported`/`vendor-neutral`/`agents.md` 命中；`--tools <未知>` 的报错也会指向它。
- **skill description 含自然语短语**（`5f5914e7`）：每个 workflow skill 的 description 写明用户实际会打的短语（"openspec propose"、"opsx apply" 等）；`openspec update` 这个 CLI 命令被刻意不归任何 workflow skill 认领（它不是 update-change workflow）。commands-only 安装不受影响。

### v1.14.0：工具目标大扩容（历史快照，注意 v2.x 路径变化）

v1.14.0 曾一次性新增 10 个 `--tools` 目标，注册在 `src/core/config.ts` 的 `existingTools`（下表记录 v1.14.0 引入时的 1.x 形态；**注意 v2.0+ 已停产所有 command 文件，且 v2.1 接入 `skills` 包后，`dsh`、`veai`、`atomcode`、`easycode`、`gigacode` 均回退到 `'universal'` `.agents/skills/`，不再创建 `.dsh/skills/` 或 `.veai/skills/`**）：

| 工具 | id | skillsDir | 命令形态 |
|------|-----|-----------|----------|
| DeepSeek Harness | `dsh` | `.dsh` | skills-only：无 adapter、无 command 文件；dsh 以项目级 `.dsh/skills/` 为最高优先级 skill root，`SKILL.md` 进入其 catalog，`/openspec-*` 直呼 |
| Code Studio | `codestudio` | `.codestudio` | skills + `.codestudio/prompts/opsx-<id>.prompt.md`；requiresIdeRestart |
| GigaCode | `gigacode` | `.gigacode` | skills + `.gigacode/commands/opsx-<id>.md`（description frontmatter） |
| AtomCode | `atomcode` | `.atomcode` | skills + `.atomcode/commands/opsx-<id>.md`；frontmatter 声明 `args: optional`（workflow 带 `**Input**` 契约，注入 `$ARGUMENTS`）或 `args: none` |
| EasyCode | `easycode` | `.easycode` | skills + `.easycode/commands/opsx/<id>.toml`（TOML 命令，`/opsx:<id>` 调用） |
| GSD | `gsd` | `.agents`（detection `.gsd`） | skills-only，共享 `.agents` 根 |
| Amp | `amp` | `.agents`（detection `.amp`/`.agents/skills`） | skills-only，共享 `.agents` 根 |
| Grok Build | `grok` | `.grok` | skills-only，`/openspec-*` 调用 |
| Warp | `warp` | `.warp`（detection `.warp`/`WARP.md`） | skills，`/openspec-*`；进入 `resolveCommandSurfaceCapability` 的 skills-invocable |
| Veai | `veai` | `.veai` | skills-only |

配套事实（源码核实）：

- 共享 `.agents` 根的成员扩大为 **Codex、Zed、Antigravity、Amp、GSD**（+ vendor-neutral `agents` 目标）。1.x 时代靠 `resolveSharedSkillWriters` 仲裁写入权；**2.0 起这套仲裁整个删掉了**——`.agents/skills/` 是唯一真身，不再有「谁写」的问题。
- Warp 是继 Codex 之后第二个 **skills-invocable** 工具（`src/core/command-surface.ts`）：没有 command adapter，但用户可以自然语言或 `/openspec-*` 调用 skill，所以 `delivery: commands` 下它仍保留 skills 生成，不会被当作 commands-only 清掉。
- EasyCode 的 TOML 字符串转义抽成共享模块 `src/core/command-generation/toml.ts`（`escapeTomlBasicString` / `escapeTomlMultilineBasicString`）：描述与 prompt 正文里的反斜杠、双引号、换行、控制字符都安全转义。gemini adapter 顺带重构。
- **IBM Bob 改名**：显示名 "Bob Shell" → "IBM Bob"，tool id `bob` 与 `.bob` 路径不变，纯改名不迁移。
- **Kilo Code 命令目录修正**（v1.13.2）：命令写到 `.kilo/command/opsx-<id>.md`（原误写 `.kilocode/workflows/`）；legacy cleanup 按已知文件名清走旧文件。

### v1.10.0→v1.11.0：共享 `.agents` 根与通用写入权仲裁（1.x 机制，2.0 已删除）

`agents`、`codex`、`zed` 三方共享 `.agents/skills/` 的格局起于 **v1.10.0**（v1.8.0/v1.9.0 没有 `zed` 工具条目，v1.10.0 起才是 `skillsDir: '.agents'`）。v1.11.0 将共享根仲裁从硬编码三元组升级为通用 `resolveSharedSkillWriters()` 机制：

1. **Antigravity 迁入 `.agents/` 共享根**（v1.11.0）：`antigravity` 的 `skillsDir` 从 `.agent` 改为 `.agents`（`.agent` 变成 `legacySkillsDirs`），旧 `.agent/workflows/openspec-*.md` 在 update 时被迁移或保留用户定制。检测键现在是 `.agent` 或 `.agents/workflows`（而非裸 `.agents/` 根）。

2. **通用写入权仲裁**（v1.11.0 新增 `src/core/shared-skill-target.ts` 的 `resolveSharedSkillWriters`；**该函数在 v2.0.0 被删除**）：不再硬编码 Codex/Zed/agents 三方的排序规则。该函数遍历所有选中工具的 `skillsDir`，对每个共享物理根（如 `.agents/skills/`）选出一个 active writer：
   - **已有 compatible owner**（通过 `.openspec-target` marker 或推断）胜出。
   - **skills-native 渲染器优先于 adapter-backed**，因为其引用可被共享树的所有消费者使用。
   - **1.x 时期新根默认指向 `agents` 还是 Codex 取决于当时现状**：当时优先级是"已有 marker 的 > 推断出的 > （已有 `.agents/skills` 树则 `agents`）> `codex` > 池中第一个"（1.x 的 `resolveSharedSkillWriters`，v2.0.0 已删除）。
   - 1.x 时只有 active writer 生成 skill 文件；其他共享同一根的选中工具仍能独立写入 command surface（如 Antigravity 在 1.x 可安装 `.agents/workflows/` command 文件）。

3. **`openspec init` 和 `openspec update` 均使用同一仲裁**（1.x）：`init.ts` 和 `update.ts` 曾调用 `resolveSharedSkillWriters`。2.0 起两者改用同一份**工具清单**（见下）。

4. **遗留检测改进**（`src/core/shared/tool-detection.ts`）：`getConfiguredTools` 也检测有 legacy skills 的 adapter-backed 工具，避免 `openspec update` 因未检测到旧 `.agent/` 树而遗漏 Antigravity。

### v2.0.0：仲裁删除，`.openspec-target` 改成工具清单

**同一份内容不再有第二个写者**，所以「选一个 active writer」这件事本身消失了。`resolveSharedSkillWriters` / `reconcileSharedSkillTargets` 已从代码中删除，`shared-skill-target.ts` 现在只做三件事：

| 函数 | 作用 |
|---|---|
| `readSkillToolList` | 读 `.agents/skills/.openspec-target`，返回**工具 id 列表** |
| `formatSkillToolList` / `hasSkillToolList` | 写与判存 |
| `readListedToolsWithOwnFiles` | 哪些列出的工具在自己目录里已有文件（行尾标 `own-files`） |

**文件语义变了**：1.x 的 `.openspec-target` 只写**一个** id（渲染共享目录的那个工具）；2.0 起写**每行一个工具 id**，表示「这个项目里配置了哪些工具」。单行文件按同样方式读，所以旧项目不需要迁移就能被识别。

`update` 靠这份清单知道要照顾哪些工具——这也是它敢在不问你的情况下清理旧文件的前提。

`profile` 决定安装哪些 workflow，`skillsScope` 决定装在本机全局还是项目仓库内（1.x 由 `delivery` 决定投递形态，v2.0.0 起已退役）。两者组合起来回答两个不同问题：

- 这套 OpenSpec 要给 agent 哪些动作？
- 这些动作是本机全局共享，还是随当前仓库提交？

**没有 `openspec workspace` 命令**，也没有 "workspace update"。`workspace` 在 CLI 里唯一的存在形式是 `openspec context --code-workspace [file]`——它只是把 root + referenced stores 的 spec 索引写成一个 `.code-workspace` 文件（本机协调视图），**不投递任何 command 或 skill**。`src/core/update.ts` 里 `workspace` 出现 0 次，所以 `update` 不区分 workspace 场景；投递形态与 workspace 无关。（1.x 由 global `delivery` 的 `both`/`skills`/`commands` 三态决定；2.0 起 `delivery` 退役，只剩 skills。）

## init/update 的系统职责

`InitCommand.execute()` 做的不是单纯 mkdir，而是一次状态根建立 + 技能投递初始化：

1. 校验目标路径（拒绝把家目录当项目；pointer repo 仅装集成）。
2. 解析技能作用域（`--scope`、项目既有技能、`OPENSPEC_SKILLS_SCOPE`、全局 `config.json` `skillsScope`、或默认 `global`）。
3. 检测 available tools、选择并校验工具（解析 `windsurf → devin` 别名，拒绝 `amazon-q` 等已退役工具并指路替代品）。
4. 清理或迁移旧目录（如 `.agent`、`.codex`、`.windsurf`），处理 GitHub Copilot cloud opt-in/out。
5. 创建 `openspec/` 基础结构与 `openspec/config.yaml`。
6. 按有效 `profile` 安装标准 skills（`global` 装入 `~/.agents/skills/` 及工具全局目录并记入 `.skill-lock.json`；`project` 装入 `.agents/skills/` + 工具相对链接/拷贝），并将项目路径记入 `<globalDataDir>/projects.json`。

`UpdateCommand.execute()` 是声明式技能同步与历史清扫器（支持 `--dry-run [--json]`）：

1. 检查全局 skills 与当前目录：**当本机已安装全局 skills 时，`openspec update` 可在没有 `openspec/` 的任意目录运行**（刷新全局 skills）；仅当未装全局 skills 且目录无 `openspec/` 时报错。
2. 在有项目级 skills 且未声明 `skillsScope: project` 的交互运行中，询问保留在项目内（写入 `openspec/config.yaml` 的 `skillsScope: project`）还是迁移到全局。
3. 读取全局 `profile` / `workflows`，刷新全局 skills（持 `global-skills.lock`）和/或同步项目 `.agents/skills/` 与各工具链接。
4. 移除取消选择的托管 skills，并按内容指纹清理未编辑的 1.x command 文件（`reconcileCommandFiles`）、旧发布版遗留文件（`findStaleReleasedFiles`）和退役工具目录（`cleanUpRetiredTools`）。

所以 `update` 会清理 OpenSpec 写过的未修改历史投递文件，但绝不删除用户业务文件或用户编辑过的命令/技能文件。

## drift 为什么重要

`src/core/profile-sync-drift.ts` 负责判断工具侧安装状态是否和当前配置一致。drift 来源包括：

- global profile 从 `core` 改成 `custom`。
- custom workflows 列表变化。
- delivery 从 `both` 改成 `skills` 或 `commands`。（**1.x 形态**；2.0 起 `delivery` 退役，只剩 skills。）
- 某个工具目录里还留有不再选择的 workflow。

这解释了为什么版本没变时也可能需要 update。OpenSpec 管理的是声明式投递状态，不只是“当前 CLI 版本是否更新”。

## command adapters 的边界（1.x 生成形态，v2.0+ 仅作旧文件清理路径表）

`ToolCommandAdapter` 只有两个核心方法：

```ts
getFilePath(commandId: string): string
formatFile(content: CommandContent): string
```

这说明 adapter 不参与 workflow 推理，也不参与 artifact 状态判断。1.x 时期它负责把 `CommandContent` 格式化写入各工具目录；**v2.0.0 起 `init`/`update` 不再写入任何 command 文件**，下表记录的旧路径仅由 `reconcileCommandFiles` / `released-output-sweep` 用于识别并清理 1.x 遗留产物：

| 工具 | 1.x 旧路径 / v2.x 技能归宿 | 说明 |
|------|----------------------------|------|
| Claude | 1.x `.claude/commands/opsx/<id>.md`；v2.x 项目 `.claude/skills/` 软链指向 `.agents/skills/`（或全局 `~/.claude/skills/`） | 1.x 带 frontmatter 的 command 文件由 `update` 按指纹清理 |
| Codex | `.agents/skills/openspec-*/SKILL.md` | v1.8.0 起即为 skills-only（`universal: true`，直读 `.agents/skills/`）；以 `$openspec-*` 调用，`.codex` 是 legacy 迁移源 |
| agents（通用） | `.agents/skills/openspec-*/SKILL.md` | vendor-neutral 目标；v2.1 下共有 33 个 `universal` 工具直读 `.agents/skills/`（1.x 曾是六方共享并由已删除的 `resolveSharedSkillWriters` 仲裁） |
| GitHub Copilot | v2.x 项目 `.agents/skills/`（`universal: true` 直读；1.x 曾写 `.github/skills/` 与 `.github/prompts/`） | 本地/全局 skills + opt-in cloud coding-agent 文件（见下） |
| Antigravity | `.agents/skills/`（1.x 曾另写 `.agents/workflows/opsx-<id>.md`） | v1.11.0 从 `.agent` 迁入 `.agents`（`universal: true`；全局作用域另有独立全局目录） |
| Command Code | 1.x `.commandcode/commands/opsx-<id>.md`；v2.x `.commandcode/skills/` 链接 | v1.9.0 引入 |
| Zed Agent | `.agents/skills/openspec-*/SKILL.md` | v1.10.0 起 skills-only（`universal: true`）；Zed v1.4.2+ 用 `/openspec-*` 或 `@openspec-*` |
| OpenCode | 1.x `.opencode/commands/opsx-<id>.md`；v2.x 直读 `.agents/skills/`（`universal: true`） | 1.x adapter 在完整 `**Input**` block 后注入一次 `**Provided arguments**: $ARGUMENTS` |
| SourceCraft（codeassistant） | 1.x `.codeassistant/`；v2.1 回退 `'universal'` `.agents/skills/` | v1.12.0 新增 tool id `codeassistant` |
| Kilo Code | 1.x `.kilo/command/opsx-<id>.md`；v2.x 直读 `.agents/skills/`（`universal: true`） | v1.13.2 修正 1.x 命令目录（原误写 `.kilocode/workflows/`） |
| Code Studio | 1.x `.codestudio/prompts/opsx-<id>.prompt.md`；v2.x `.codestudio/skills/` 链接 | v1.14.0 新增 |
| GigaCode / AtomCode / EasyCode | 1.x 各自 `commands/`（EasyCode 为 TOML）；v2.1 均回退 `'universal'` `.agents/skills/` | v1.14.0 新增；`command-generation/toml.ts` 保留用于旧 TOML 命令清理比对 |

1.x 补充历史细节：OpenCode 的 command adapter 只有在正文没有 `$ARGUMENTS`/位置参数占位符、且 Input 不是 `None required` 时才注入；v1.9.0–v1.17.0 的遗留迁移曾遵守 `resolveSharedSkillWriters` 的 one-writer 规则（v2.0.0 合并为单一 `.agents/skills/` 真身后该规则已随函数删除）。

## command 面的终点：v1.17.0 的弃用预告与 v2.0.0 移除

**先钉死一件事：弃用的是 command 文件，不是 CLI。** `/opsx:propose` 是 AI 工具里的斜杠命令（由 `.claude/commands/opsx/propose.md` 这类文件定义），不是 `openspec propose` 子命令——OpenSpec CLI 根本没有 `propose` 这个子命令。CLI 子命令表在 v1.15.0→v1.17.0 之间**一个都没增删**。

三层要分清：

| 层 | 是什么 | 2.0+ |
|---|---|---|
| CLI 本体 | `openspec validate` / `archive` / `update` / `instructions` … | 保留，继续演进 |
| command 文件 | markdown 提示词，`.claude/commands/opsx/<id>.md` | 移除（不再生成，按指纹清理） |
| skill 文件 | 标准 `SKILL.md` | 保留，默认装入本机 `~/.agents/skills/`，项目级合成 `.agents/skills/` 一份共享真身 + 链接 |

**两层 markdown 几乎同源**：`src/core/templates/workflows/propose.ts` 里 `getOpsxProposeSkillTemplate()`（注：12 个模板里唯独 `propose.ts` 保留了 `Opsx` 前缀，其余 11 个均为 `get<X>SkillTemplate()`）与 `getOpsxProposeCommandTemplate()` 共享同一份 instructions 正文，差异只有 packaging 与 handoff 措辞（#258：command-only 工具没有对话代理可问，不能邀请“让我来实施”）。两者内部都是**指挥 CLI 的调度脚本**——`src/core/templates/workflows/*.ts` 里 `openspec instructions` 出现 **47** 次、`openspec status` **44** 次、`openspec archive` **25** 次。精确性在 CLI 里，不在 markdown 里。

**为什么要砍 command 面**（issue #2022）：1.x 把每个 workflow 写两遍（默认 `delivery = 'both'`），几十个工具 × 12 个 workflow 的重复文件；command 格式每家不同，要维护几十个 adapter；skills 是 [agentskills.io](https://agentskills.io) 标准且能靠 frontmatter `description` 自动触发，斜杠命令必须人先记住名字。v2.0 起将项目级技能收成 `.agents/skills/` 一份真身，v2.1 接入 `skills` 包后覆盖 **87 个工具**（33 个直读 `.agents/skills/` + 54 个软链/拷贝），并默认安装到本机全局。

**能力模型**（`src/core/command-surface.ts`，v1.17.0 引入，v2.0.0 收缩）：

| 能力 | 含义 | 例子 |
|---|---|---|
| `adapter-backed` | 有 1.x command adapter，`update` 需扫描清理其旧命令文件 | Claude Code 等 34 个有适配器的工具 |
| `skills-invocable` | 从未有过 command adapter，一直只用 skills 调用 | `codex`、`warp` |
| `none` | 无历史 command adapter | 其余仅走 skills 的工具 |

v1.17.0 曾有四条由 `delivery` × 能力矩阵驱动的判定（`shouldGenerateSkillsForTool` / `shouldRemoveSkillsForTool` / `shouldGenerateCommandsForTool` / `shouldReconcileCommandFilesForTool`）及 `formatCommandDeprecationNotice`。v2.0.0 起 `delivery` 退役，前三条判定与 `formatCommandDeprecationNotice` **全部删除**，文件只剩 `resolveCommandInvocation`、`resolveCommandSurfaceCapability` 与 `shouldReconcileCommandFilesForTool` 三项导出。

**v1.17.0 弃用提示的历史触发条件**：当时已删除的 `formatCommandDeprecationNotice` 只在“某个已配置工具在 1.17 会得到 command 文件、且切到 `skills` 后不再得到”时于 `update` 中打印，为 2.0 删除做过渡。

**配套的保命改动**（#2087 折叠进 #2213）：清理旧 command 文件时**绝不删用户编辑过的文件**。`classifyCommandFiles` 用同一套指纹判断，结果分三类——`removed`（OpenSpec 原样生成、删）、`kept`（内容对不上，用户改过，保留并列出）、`unchecked`（读不了、删不了、symlink 无法证明在项目内）。

**当前行为**：command 文件**已停止生成**，`/opsx:*` 不再由 OpenSpec 提供；`delivery` 配置项退役，一律装 skills（#2223）。旧项目里由早期版本生成的 command 文件，在 `openspec update` 时按指纹清理：没人改过的删掉，改过的保留并列出。

**适配器层没有删除**。`src/core/command-generation/adapters/` 下 34 个适配器仍在，但职责从「生成」变成「知道旧文件曾经写在哪里」，调用方只剩 `command-surface.ts`、`migration.ts`、`command-reconcile.ts`、`tool-detection.ts`、`profile-sync-drift.ts`、`released-output-sweep.ts`。**能力删了，路径知识留着**——这正是 2.0 能安全做大规模删除的前提。

## GitHub Copilot：标准 skills 与 opt-in cloud coding-agent

GitHub Copilot 自 v1.8.0 起是一等工具目标，拆成两层，其中 cloud 层默认不生成：

| 层 | 产物 | 默认 |
|----|------|------|
| 标准 skills | `github-copilot` 为 `universal: true`：全局作用域装入全局 skills，项目作用域**直接读取 `.agents/skills/`**（1.x 曾写 `.github/skills/`，升级时自动迁移/清理） | `--tools github-copilot` 时启用 |
| cloud coding-agent 文件 | `.github/workflows/copilot-setup-steps.yml`（预装 CLI）+ `.github/agents/openspec.agent.md`（定制 agent 说明） | **opt-in**，默认 No；**要求项目作用域**（`--copilot-cloud` 自动切 `project`，与显式 `--scope global` 同传会报错，因云端容器看不到本机家目录） |

cloud 文件写入 `.github/` 是有侵入性的动作，所以由 `openspec init` 交互询问（非交互用 `--copilot-cloud` / `--no-copilot-cloud`），选择记入 `openspec/config.yaml` 的 `githubCopilot.cloudAgent`。`openspec update` 从不提示：只刷新已 opt-in、或已存在 managed cloud 文件的旧项目（视为隐含 opt-in）；用户自己改过的文件永不覆盖/删除；opt-out 只删除 managed 文件，保留用户定制。逻辑见 `src/core/github-copilot/cloud-agent.ts`。

## 工程洞察

- OpenSpec 把 workflow 语义和工具外壳解耦，避免核心机制被某个 agent 平台锁死。
- `profile` + `skillsScope` 是投递声明，`init` / `update` 把声明同步到全局或项目侧文件系统。
- 运行时依赖 `skills` 包承接各工具目录映射，34 个旧 command adapter 只留作清理边界，不承载 workflow 判断。
- legacy cleanup 与指纹清扫只清理 OpenSpec 原样生成过的投递产物和 marker，绝不成为任意文件删除器。

## 源码锚点

| 机制 | 路径 |
|------|------|
| tool registry（87 工具 + 别名/退役表） | `AI_TOOLS`、`SKILL_LINKED_TOOL_IDS`、`RETIRED_TOOLS`、`TOOL_ID_ALIASES` in `src/core/config.ts` |
| 离线技能安装与 `.skill-lock.json` | `src/core/skill-installer.ts` |
| 全局技能作用域与互斥锁 | `src/core/global-skills.ts` |
| 项目级技能作用域持久化 | `src/core/project-skills-scope.ts` |
| 本机已知项目记录 | `src/core/known-projects.ts` |
| 共享 `.agents/skills/` 安装与软链 | `src/core/shared/shared-skill-install.ts`、`src/core/shared/skill-links.ts`、`src/core/shared/skill-paths.ts` |
| 项目已配置工具清单 | `src/core/shared-skill-target.ts`（`.agents/skills/.openspec-target`） |
| skill 恒定内容生成 | `src/core/shared/skill-generation.ts`、`src/core/shared/skill-content-equivalence.ts`、`src/core/shared/allowed-tools.ts` |
| tool detection | `src/core/available-tools.ts`、`src/core/shared/tool-detection.ts` |
| 退役工具拒绝与清理 | `src/core/retired-tools.ts` |
| 生成物指纹与清扫 | `src/core/shared/generated-fingerprint.ts`、`src/core/shared/released-generated-fingerprints.ts`、`src/core/released-output-sweep.ts`、`src/core/shared/command-reconcile.ts` |
| GitHub Copilot cloud agent | `src/core/github-copilot/cloud-agent.ts` |
| workflow templates | `src/core/templates/workflows/` |
| 旧 command adapters（清理用） | `src/core/command-generation/`、`src/core/command-surface.ts` |
| init/update 与 dry-run 计划 | `src/core/init.ts`、`src/core/update.ts`、`src/core/update-plan.ts` |
| profile drift | `src/core/profile-sync-drift.ts` |
| migration / legacy cleanup | `src/core/migration.ts`、`src/core/legacy-cleanup.ts` |

## 测试锚点

- `test/core/init.test.ts`
- `test/core/update.test.ts`、`test/core/update-dry-run.test.ts`
- `test/core/global-skills.test.ts`、`test/core/project-skills-scope.test.ts`、`test/core/project-skills-vercel.test.ts`、`test/core/known-projects.test.ts`
- `test/core/skills-2-0-hardening.test.ts`、`test/core/retired-tools.test.ts`、`test/core/released-output-sweep.test.ts`
- `test/core/command-reconcile.test.ts`、`test/core/command-generation/`
- `test/core/shared/`
- `test/core/profile-sync-drift.test.ts`
- `test/core/migration.test.ts`、`test/core/legacy-cleanup.test.ts`
