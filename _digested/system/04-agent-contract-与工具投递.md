# Agent Contract 与工具投递

## 一句话

OpenSpec 和 coding agent 的契约不是“OpenSpec 直接调用模型”，而是：

```text
OpenSpec 生成 agent 可读的入口文件
agent 触发入口后调用 openspec CLI
CLI 返回结构化状态和执行包
agent 用自己的 LLM 推理并写文件
```

这一层叫工具投递层更准确：OpenSpec 把同一套 workflow 投递成不同工具能识别的 skills 或 commands。

## profile 决定装哪些 workflow

当前 profile 逻辑在 `src/core/profiles.ts`：

```text
core   → propose / explore / apply / sync / archive
custom → 用户配置的 workflows
```

`getProfileWorkflows()` 只回答“启用哪些 workflow”。它不决定这些 workflow 以什么文件格式交给 agent。

## delivery 决定怎么投递

delivery 来自 global config，类型在 `src/core/global-config.ts`：

```text
both
skills
commands
```

repo-local `init/update` 会根据 delivery：

- `skills`：生成 skill 目录。
- `commands`：生成 command 文件。
- `both`：两者都生成。

但 delivery 是意图，工具能力才是上限。v1.8.0 的 Codex 没有 command surface：它始终接收 `.agents/skills/openspec-*/SKILL.md`（v1.7.0 时代是 `.codex/skills/`），并以 `$openspec-*` skill 调用；旧的托管 Codex prompts 会在有 replacement skill 时由 `update` 清理，`.codex` 旧 skill 树会原地迁移到 `.agents` 并保留用户定制。不要把 `/opsx:*` 当成 Codex 的调用语法。

v1.8.0 同时新增 vendor-neutral `agents` 目标（`--tools agents`），与 Codex 共享 `.agents` 根。共享根同一时刻只能有一个 active writer，由 `src/core/shared-skill-target.ts` 的 `.openspec-target` marker 决定归属（详见 `mechanisms/02-tool-delivery.md`）。v1.9.0 把同一规则接到遗留 Codex 升级路径：已有 `agents` 占用时，update 不再凭 `~/.codex/prompts` 劫持该树。另增 Command Code（`--tools command-code`）：skills 在 `.commandcode/skills/`，commands 在 `.commandcode/commands/opsx-<id>.md`。


## skills 与 commands 的区别

| 类型 | 本质 | 生成入口 | 典型落点 |
|------|------|----------|----------|
| skill | agent 自动发现的能力说明书 | `getSkillTemplates()`、`generateSkillContent()` | `.<tool>/skills/openspec-*/SKILL.md` |
| command | 用户可触发的 slash/prompt 入口 | `getCommandContents()`、`generateCommands()` | 各工具 adapter 定义的位置 |

skill 和 command 内容都来自 workflow template。区别在于外壳和触发方式，不在于底层 workflow 语义。

## adapter 解决什么

不同 coding agent 对 command 文件的位置、命名、frontmatter、正文格式要求不同。OpenSpec 把这些差异放在 command adapter 里。

主链路是：

```text
tool-agnostic CommandContent
  → CommandAdapterRegistry.get(toolId)
  → generateCommands()
  → adapter.getFilePath(id)
  → adapter.formatFile(content)
  → 写入具体工具目录
```

这意味着 workflow 模板可以保持工具无关，而每个工具只负责把它包装成自己能识别的格式。

## init 做什么

`InitCommand.execute()` 的系统职责可以概括成：

1. 校验目标目录和写权限。
2. 处理旧版 OpenSpec 管理文件的清理和迁移。
3. 检测或选择 AI 工具。
4. 创建 `openspec/` 基础目录。
5. 根据 profile/delivery 给选中工具生成 skills/commands。
6. 创建或保留 `openspec/config.yaml`。

所以 `init` 不是单纯 mkdir。它同时建立 repo-local OpenSpec 状态根，并把 workflow 投递给工具。

## update 做什么

`UpdateCommand.execute()` 的系统职责是“重放当前期望状态”：

1. 确认 `openspec/` 已存在。
2. 做必要迁移。
3. 读取 global profile/delivery。
4. 检测已配置工具和 drift。
5. 重新生成应有 workflow 的 skills/commands。
6. 删除未选 workflow 或 delivery 已不需要的托管文件。

所以 `update` 是投递层同步命令。它不负责修改 change 内容，也不负责合并 specs。

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
| skill templates | `src/core/shared/skill-generation.ts` |
| workflow templates | `src/core/templates/workflows/` |
| command adapters | `src/core/command-generation/` |
| tool registry | `AI_TOOLS` in `src/core/config.ts` |
