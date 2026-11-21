# Agent Contract 与工具投递

## 一句话

OpenSpec 和 coding agent 的契约不是“OpenSpec 直接调用模型”，而是：

```text
OpenSpec 生成 agent 可读的入口文件
agent 触发入口后调用 openspec CLI
CLI 返回结构化状态和执行包
agent 用自己的 LLM 推理并写文件
```

这一层叫工具投递层更准确：OpenSpec 把同一套 workflow 投递成各 coding agent 可自动发现的标准 skills（1.x 曾同时投递工具私有的 command 文件，v2.0.0 起已全面退役）。

## profile 决定装哪些 workflow

当前 profile 逻辑在 `src/core/profiles.ts`：

```text
core   → propose / explore / apply / update / sync / archive
custom → 用户配置的 workflows
```

`getProfileWorkflows()` 只回答“启用哪些 workflow”。它不决定这些 workflow 以什么文件格式交给 agent。

## 投递：v2.x 只剩 skills

**v2.0.0 起 `delivery` 退役**（#2223），配置里不再有这一项，一律投递 skills。下面是 1.x 的形态，保留用于读旧项目：

1.x 时期 `delivery` 从 global config 读（类型定义仍留在 `src/core/global-config.ts` 以兼容旧配置读取，但不再改变安装行为）：

```text
both
skills
commands
```

repo-local `init/update` 曾根据 delivery 分流：

- `skills`：生成 skill 目录。
- `commands`：生成 command 文件。
- `both`：两者都生成。

**现在只有两个问题要回答**：
1. **装到哪一层作用域（`skillsScope`）**：v2.1.0 起新项目 `init` 默认装到本机全局（`~/.agents/skills/` + 各工具全局目录）；传 `--scope project` 或已有项目级技能的项目才装在仓库内（并在 `openspec/config.yaml` 记录 `skillsScope: project`）。仅 `eve`、`promptscript` 两个工具不支持全局技能（外加 `--copilot-cloud` 需要项目作用域）。
2. **工具怎么读 skills**：项目作用域下 `.agents/skills/` 是唯一真身；33 个 `universal` 工具直接读 `.agents/skills/`，其余 54 个工具（`SKILL_LINKED_TOOL_IDS`）在各自目录下放指向真身的相对链接（Windows 或 `eve` 退化为拷贝）。

Codex 从来没有 command surface：它接收 `.agents/skills/openspec-*/SKILL.md`（早期为 `.codex/skills/`），并以 `$openspec-*` skill 调用；旧的托管 Codex prompts 会在有 replacement skill 时由 `update` 清理，`.codex` 旧 skill 树会原地迁移到 `.agents` 并保留用户定制。不要把 `/opsx:*` 当成 Codex 的调用语法。

**v1.x 的共享根**（历史）：`.agents/skills/` 曾由 `agents`（vendor-neutral）、`codex`、`zed`、`antigravity`、`amp`、`gsd` 六方共享，写入权由 `resolveSharedSkillWriters()` 仲裁（skills-native 渲染器优先；已有 `.openspec-target` marker 的 owner 优先；新根默认 Codex）。Command Code 的 skills 在 `.commandcode/skills/`、commands 在 `.commandcode/commands/opsx-<id>.md`。

**v2.0 起不再有「多方共享、互相仲裁」的问题**：`.agents/skills/` 就是唯一真身，任何工具都不再往那里写第二份内容；写入/比对由 `shared-skill-install.ts` 和 `skill-links.ts` 负责，安装动作交给运行时依赖 `skills` 包。详见 `mechanisms/02-tool-delivery.md`。

custom profile 还有 dependency expansion：只要选择 `archive` 或 `bulk-archive` 而列表中没有 `sync`，resolver 会把 `sync` 插在第一个依赖者前；已有 `sync` 不重复、不重排，返回的 profile 仍是 custom，不降级为 core。


## skills 与 commands 的区别（command 已退场）

| 类型 | 本质 | 生成入口 | 状态 |
|------|------|----------|------|
| skill | agent 自动发现的能力说明书 | `getSkillTemplates()`、`generateSkillContent()` | **唯一形态**。真身在 `.agents/skills/openspec-*/SKILL.md` |
| command | 用户可触发的 slash/prompt 入口 | `getCommandContents()`、`generateCommands()` | **v2.0.0 起不再生成**；`generateCommands` 仍存在，但只服务于清理与漂移检测 |

skill 和 command 内容都来自 workflow template。区别在于外壳和触发方式，不在于底层 workflow 语义——所以移除 command 不改变任何 workflow 行为，只是少了一层包装。

## adapter 解决什么（1.x 生成，v2.0+ 仅用于旧文件清理）

1.x 时期，不同 coding agent 对 command 文件的位置、命名、frontmatter、正文格式要求不同，OpenSpec 把这些差异放在 `src/core/command-generation/adapters/` 的 34 个 command adapter 里：

```text
tool-agnostic CommandContent
  → CommandAdapterRegistry.get(toolId)
  → generateCommands() → adapter.getFilePath(id) + adapter.formatFile(content)
```

**v2.0.0 起 `init` 和 `update` 不再写入任何 command 文件**。这 34 个 adapter 之所以保留在源码里，是为了提供“旧版曾经把文件写在哪里、原样内容长什么样”的路径与格式知识，供 `reconcileCommandFiles()`、`released-output-sweep.ts`、`migration.ts`、`tool-detection.ts` 在升级时安全删除未改动的 1.x 命令文件（用户手工改过的会保留并提示），以及供 `resolveCommandInvocation()` 解析旧命令拼写。

## init 做什么

`InitCommand.execute()` 的系统职责可以概括成：

1. 校验目标目录和写权限，拒绝已退役工具（如 `amazon-q` → 指路 `kiro`）。
2. 处理旧版 OpenSpec 管理文件的清理和迁移。
3. 检测或交互式选择 AI 工具（87 个可选工具，支持 `--tools`）。
4. 创建 `openspec/` 基础目录（`specs/`、`changes/`、`config.yaml`）。
5. 确定技能作用域（`--scope`、已有项目技能或全局 `config.json` 的 `skillsScope`，新项目默认 `global`），按当前 `profile` 安装标准 `SKILL.md`（全局写入 `~/.agents/skills/` 及工具全局目录并记入 `.skill-lock.json`；项目写入 `.agents/skills/` + 工具相对链接/拷贝，并在 `openspec/config.yaml` 写入 `skillsScope: project`）。
6. 将项目路径记入 `<globalDataDir>/projects.json`（仅供后续迁移参考，失败静默忽略）。

所以 `init` 不是单纯 mkdir。它同时建立 repo-local OpenSpec 状态根，并把 workflow skills 投递到全局或项目目录。

## update 做什么

`UpdateCommand.execute()` 的系统职责是“把已装 skills 同步到当前版本与 profile，并清扫历史遗留”：

1. **检查全局 skills 与当前目录**：若本机已安装全局 skills，**`openspec update` 不要求当前目录存在 `openspec/`**——在任意目录运行都会刷新全局 skills（在家目录运行也只刷新全局 skills，不把家目录当独立项目）；若本机尚未装全局 skills 且目标目录没有 `openspec/`，才报错提示先 `init`。
2. 在含 `openspec/` 的项目内：若检测到旧项目级 skills 且未声明 `skillsScope: project`，交互模式下询问保留在项目内还是迁移到全局。
3. 读取全局 `profile` / `workflows`（`delivery` 字段即使残留在旧 `config.json` 中也不再分流）。
4. 刷新全局 skills（持 `<globalDataDir>/global-skills.lock` 锁）和/或同步项目 `.agents/skills/` 与各工具链接。
5. 移除当前 profile 未选中的托管 skills，按内容指纹比对清理未修改的 1.x command 文件（`reconcileCommandFiles`）、旧版本残留文件（`findStaleReleasedFiles`）以及退役工具目录（`cleanUpRetiredTools`）。

所以 `update` 是投递层同步与清理命令（支持 `--dry-run [--json]` 预览计划）。它不负责修改 change 内容，也不负责合并 specs。

## agent runtime contract

投递文件只是入口，真正稳定的是 agent 运行时需要调用的 CLI 契约：

| agent 想知道 | 应调用 |
|--------------|--------|
| 当前有哪些 change | `openspec list --json` |
| 某个 change 到哪一步 | `openspec status --change "<name>" --json` |
| 该写某个 artifact 时需要什么 | `openspec instructions <artifact> --change "<name>" --json` |
| apply 阶段该怎么做 | `openspec instructions apply --change "<name>" --json` |
| archive 阶段的项目 context / operation guidance | `openspec instructions archive --change "<name>" --json` |
| 可用 schema/templates | `openspec schemas --json`、`openspec templates --json` |

这组命令比具体 slash command 前缀更稳定。前缀只是工具交互习惯，runtime contract 是 CLI JSON。

## 和其他专题的边界

- 想看每个 CLI JSON 字段：去 `../spec_cli/`。
- 想看 schema 如何影响 instructions：去 `../schema/`。
- 想看默认 spec-driven 下某条 workflow 如何执行：去 `../internal-spec-driven/`。

## 源码入口

| 主题 | 入口 |
|------|------|
| profile | `src/core/profiles.ts` |
| global config | `src/core/global-config.ts`、`src/core/config-schema.ts` |
| init | `InitCommand` in `src/core/init.ts` |
| update | `UpdateCommand` in `src/core/update.ts` |
| skill 安装与作用域 | `src/core/skill-installer.ts`、`src/core/global-skills.ts`、`src/core/project-skills-scope.ts` |
| skill 模板与链接 | `src/core/shared/skill-generation.ts`、`src/core/shared/shared-skill-install.ts`、`src/core/shared/skill-links.ts` |
| workflow templates | `src/core/templates/workflows/` |
| 旧 command adapters（清理用） | `src/core/command-generation/`、`src/core/shared/command-reconcile.ts` |
| tool registry | `AI_TOOLS` in `src/core/config.ts` |
