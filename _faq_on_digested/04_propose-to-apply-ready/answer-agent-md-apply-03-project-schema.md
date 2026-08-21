# 答案 03：大改，但放在项目级 schema 里

## 什么时候值得大改

大改不是指改 OpenSpec core。这里的大改是：

```text
在项目里定义一套 agent/Markdown/skill 专用 schema
```

它适合这种情况：

- agent/skill/command/Markdown 已经是主要产物，不是偶尔借用。
- 默认 `proposal/specs/design/tasks` 概念持续不贴合。
- 你希望 status/instructions 直接显示自己的 artifact，例如 `agent-brief`、`skill-design`、`command-contract`。
- 你已经从几轮实践中看出稳定的 artifact DAG。

## 为什么应该先放项目里

不要第一步就装到 OpenSpec package 或用户全局 schema。项目级 schema 更合适：

| 位置 | 优点 | 风险 |
|---|---|---|
| `openspec/schemas/<name>/` | 项目内可快速迭代；随 git 版本化；优先级最高；不需要重装 OpenSpec；不影响别的项目 | 只在该项目生效 |
| 用户级 schema | 可跨项目复用 | 容易污染多个项目，调试“为什么生效”更麻烦 |
| OpenSpec package 内置 schema | 可作为官方能力分发 | 迭代慢，需要发布/安装，第一版不适合放这里 |

项目级 schema 的解析优先级最高。源码 `getSchemaDir()` 和 `_digested/schema/04-schema-解析优先级.md` 都说明顺序是：

```text
project openspec/schemas/<name>/
  -> user global schemas
  -> package built-in schemas
```

验证命令：

```bash
openspec schema which agent-workflow
```

目标输出应显示来源是 `project`。

## 怎么设计 schema

一个 agent/MD workflow 可以从这类 artifact 起步：

```yaml
name: agent-workflow
version: 1
description: Agent and Markdown workflow - brief -> design -> contract -> tasks -> verification

artifacts:
  - id: agent-brief
    generates: agent-brief.md
    template: agent-brief.md
    description: Goal, audience, target agent behavior, and non-goals
    requires: []

  - id: skill-design
    generates: skill-design.md
    template: skill-design.md
    description: Skill behavior, trigger rules, workflow steps, guardrails, and failure modes
    requires:
      - agent-brief

  - id: command-contract
    generates: command-contract.md
    template: command-contract.md
    description: Slash command or tool-facing contract, inputs, outputs, and examples
    requires:
      - agent-brief

  - id: tasks
    generates: tasks.md
    template: tasks.md
    description: Executable checklist for writing, installing, and verifying artifacts
    requires:
      - skill-design
      - command-contract

  - id: verification
    generates: verification.md
    template: verification.md
    description: Test prompts, expected behavior, and delivery checks
    requires:
      - tasks
```

第一版不要做太复杂。先让 DAG 反映一个基本事实：

```text
先确定 agent 要解决什么
再设计行为和命令契约
再拆任务
再验证
```

## apply 怎么定义

建议第一版仍然用 `tasks.md`：

```yaml
apply:
  requires:
    - tasks
  tracks: tasks.md
  instruction: |
    This change implements agent workflow artifacts, not application code by default.
    Read all contextFiles before editing.
    Execute pending tasks by creating or updating Markdown, SKILL.md, command templates,
    verification notes, installation notes, and supporting docs named by the tasks.
    Mark a checkbox complete only after the referenced artifact exists and has been checked.
    Pause if a task requires changing OpenSpec core behavior or target runtime installation rules are unclear.
```

这里的关键点：

- `apply.requires` 控制什么时候可以进入 apply。
- `apply.tracks` 控制哪个文件提供 checkbox progress。
- `apply.instruction` 把默认 apply 文案拉回非代码语境。
- `contextFiles` 会自动包含已存在的 schema artifacts。

`tracks` 文件名虽然可配置，但第一版建议仍用 `tasks.md`，因为默认模板、读者习惯和 archive warning 都更容易理解。

## 这能带来什么

项目级 schema 大改后，OpenSpec 的状态语言会变得贴合你的真实工作：

```text
agent-brief ready
skill-design blocked until agent-brief
command-contract blocked until agent-brief
tasks blocked until skill-design and command-contract
verification blocked until tasks
```

这比把所有东西塞进 `proposal/specs/design/tasks` 更容易读，也更适合高专业读者快速理解工程意图。

## 仍然不能承诺什么

即使做了项目级 schema，也不要误解成 OpenSpec 自动拥有完整 agent delivery system。

它仍然不会自动做这些事：

- 安装 generated skill 到 Codex、Claude Code、OpenCode 或其他 runtime。
- 重新加载目标工具。
- 验证 `SKILL.md` 是否符合某个平台全部规则。
- 把 Markdown 发布到 CMS。
- 把非 spec artifact merge 成某个正式 baseline。

## OpenCode command 参数

若把 workflow 同时投递为 OpenCode command，v1.10.0 adapter 会注入 `$ARGUMENTS`，让用户输入传进生成命令。只在正文还没有该占位符时添加；自定义模板已经显式使用 `$ARGUMENTS` 时不会重复。这个占位符是 OpenCode 的 adapter 语法，不应机械复制到 Claude `/opsx:*` 或 Codex `$openspec-*` 入口。

第一版应把这些写成 tasks：

```markdown
- [ ] 3.1 Copy generated skill into the target runtime directory — verify: list the installed file at the expected path
- [ ] 3.2 Run or document the target tool refresh step — verify: capture the refresh result or documented command
- [ ] 3.3 Check runtime discovery — verify: the skill appears in the available skills list
- [ ] 3.4 Record unresolved runtime assumptions in `verification.md` — verify: inspect the file for every known assumption
```

等这些动作稳定后，再考虑专门 delivery adapter 或 validator。

## 和 archive 的关系

对项目级 agent schema，`archive` 最稳妥的理解是：

```text
active change 生命周期结束
```

不要默认理解成：

```text
agent/skill/Markdown 产物已经自动发布或合并到正式 baseline
```

真实发布、安装、复制、验证动作应该在 apply tasks 中完成。archive 只负责把 change 从 active 区移走并保留记录；如果你需要新的 archive 语义，那是下一阶段扩展，不是第一版 schema 必须解决的问题。

## 推荐判断

项目级 schema 是长期正确方向，但不一定是第一天就做。推荐路径是：

```text
先用 02 稍微改沉淀真实 tasks 和 artifact 结构
  -> 发现结构稳定
  -> 抽成 openspec/schemas/agent-workflow/
  -> 用 openspec schema which agent-workflow 验证项目级解析
```

这样既不污染 OpenSpec package/global schema，也不会在概念还没稳定时过早固化。
