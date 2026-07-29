# 答案 02：稍微改，低成本稳定借用

## 这是推荐第一步

这条路的目标是：

```text
不改 OpenSpec 源码
不急着重做整套 schema
但让 agent/Markdown/skill apply 明显更稳
```

它适合大多数真实使用：你已经知道要用 OpenSpec 管 agent/MD/skill 产物，但还不确定最终 artifact DAG 长什么样。此时不要先大改 schema；先用轻量配置和任务规范把工作流跑顺。

## 改什么

### 1. 用 `openspec/config.yaml` 写清项目语境

`config.yaml` 可以给 artifact 生成阶段注入 context/rules，也可在 v1.7.0 用 `operations.apply.guidance` / `operations.archive.guidance` 分别给 Apply/Archive 传入项目级短稳定步骤。它们不能直接重写 schema gate，但能让 proposal/design/tasks 从一开始就写对，并让非代码 apply 的操作边界更清楚。

示例：

```yaml
context: |
  This project develops agent skills, command templates, and Markdown workflows.
  Treat SKILL.md, command Markdown, verification notes, and documentation as primary implementation artifacts.
  Do not assume implementation means application source code unless a task explicitly names code files.

rules:
  proposal:
    - State whether the change produces agent behavior, Markdown workflow docs, skill files, commands, or code.
  design:
    - Include trigger conditions, input/output contract, tool boundaries, failure modes, and verification approach.
  tasks:
    - Every task must be a Markdown checkbox.
    - Every implementation task should name the target file or directory when possible.
    - Mark install/publish/verification actions as separate tasks.

operations:
  apply:
    guidance:
      - Treat named Markdown, skill, command, installation, and verification files as valid implementation outputs.
```

这个改法不碰 schema，但会让 `openspec instructions <artifact> --json` 返回的 artifact 操作包带上这些约束。

### 2. 固化 tasks 写法

非代码 apply 最容易失败的地方不是 CLI，而是 tasks 太抽象。建议固定成：

```markdown
## 1. Agent Contract

- [ ] 1.1 Create `skills/<name>/SKILL.md` with trigger rules, workflow steps, and guardrails
- [ ] 1.2 Add `commands/<name>.md` with accepted inputs and expected output format

## 2. Verification

- [ ] 2.1 Add `verification.md` with sample prompts and expected behavior
- [ ] 2.2 Run a Markdown link/path consistency check

## 3. Delivery

- [ ] 3.1 Copy or reference generated files in the target agent runtime location
- [ ] 3.2 Verify the target tool can see the new skill/command
```

这里的关键是：把“实现”翻译成具体文件动作。OpenSpec apply 可以执行 checklist，但不会替你猜 agent runtime 的安装/发布细节。

### 3. 必要时做一个最小项目级 schema shadow

如果只靠 `config.yaml` 还不够，下一步不是重做全部 schema，而是在项目里 shadow 默认 schema，只改 `apply.instruction` 或少量模板。

项目路径：

```text
openspec/schemas/spec-driven/schema.yaml
openspec/schemas/spec-driven/templates/*.md
```

项目级 schema 优先于包内置 schema，所以不需要改 OpenSpec 安装包。可以用：

```bash
openspec schema which spec-driven
```

确认解析来源是 `project`。

最小改动是把 apply instruction 改得更中性：

```yaml
apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, and mark complete as you go.
    Implementation may mean source code, Markdown, SKILL.md, command templates,
    verification notes, installation steps, or other files named by the tasks.
    Do not assume code edits are required unless tasks or design explicitly say so.
    Pause if a task is ambiguous or requires changing OpenSpec core behavior.
```

这已经能解决默认 apply 文案偏代码的问题的大部分影响。

## 为什么这条路成立

证据分两块：

| 机制 | 说明 |
|---|---|
| `config.yaml` context/rules | `generateInstructions()` 会把它们放进 artifact instructions，约束 proposal/design/tasks 的生成。 |
| `operations.apply.guidance` | `instructions apply` 会把它与 project context 提供给 Apply；artifact rules 不会自动转入 Apply。 |
| schema `apply.instruction` | `generateApplyInstructions()` 会把它作为 apply 阶段的 `instruction` 返回给 agent。 |

也就是说，你不需要改 core CLI，就能让 planning artifacts 和 apply 动态指令都更贴近非代码产物。

## 代价是什么

这条路仍保留默认 artifact 概念：

- 还是叫 `proposal/specs/design/tasks`。
- 如果 shadow `spec-driven`，要维护一份项目级 schema 和模板。
- archive 的正式语义仍然偏 spec delta，不会自动发布 skill 或合并 Markdown baseline。

但它的成本远低于重做一套 schema，而且足够验证真实工作流。

## 什么时候升级到大改

出现这些信号时，再升级到 [03 项目级 schema 大改](answer-agent-md-apply-03-project-schema.md)：

- `proposal/specs/design` 的名字持续误导读者。
- 你稳定需要 `agent-brief`、`skill-design`、`command-contract`、`verification` 这类专门 artifacts。
- 不同 agent/skill change 的 planning 文档结构已经高度重复。
- 你希望 `status` 和 `instructions` 直接显示非代码 artifact 名称。
- 团队已经确定这不是临时用途，而是长期生产流程。

## 推荐判断

这是我建议的第一条正式路径。它不要求安装 schema 到 OpenSpec 包，也不要求改源码；先把项目语境、tasks 规范、apply instruction 固化起来。等真实使用证明 artifact 结构稳定，再做项目级 schema。
