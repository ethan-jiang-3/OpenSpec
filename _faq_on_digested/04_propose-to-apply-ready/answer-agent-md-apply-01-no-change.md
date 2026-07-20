# 答案 01：不大改，直接借默认 spec-driven

## 适合什么时候

这条路适合你现在只想验证一件事：

```text
OpenSpec 的 propose -> apply loop 能不能帮我把 agent/Markdown/skill 任务跑起来？
```

做法是不改 schema、不改 OpenSpec 源码、不新增 workflow。继续用默认 `spec-driven`，只是把 proposal、design、tasks 写成 agent/Markdown/skill 语义。

## 怎么用

默认 schema 仍然是：

```text
proposal -> specs/design -> tasks -> apply
```

你把这些 artifact 重新解释成：

| 默认 artifact | 在 agent/MD 工作流里怎么写 |
|---|---|
| `proposal.md` | 说明为什么要做这个 agent/skill/command，目标用户、触发场景、交付物。 |
| `design.md` | 说明 agent 行为、输入输出、工具边界、失败模式、验证方法。 |
| `specs/**/*.md` | 如果确实有”capability 基线”要维护，就写 behavior requirements；如果只是一次性内容产物，可以写得很轻。 |
| `tasks.md` | 明确列出要创建/修改的 Markdown、`SKILL.md`、command 模板、验证文件。 |

最关键的是 `tasks.md`。默认 `/opsx:apply` 会根据 checkbox 执行任务，所以 task 必须把目标文件说清楚：

```markdown
- [ ] 1.1 Create `skills/research-agent/SKILL.md` with trigger rules, workflow steps, and guardrails
- [ ] 1.2 Add `commands/research-collect.md` with input contract and output format
- [ ] 1.3 Add `verification.md` with three sample prompts and expected behavior
- [ ] 1.4 Check links and paths across generated Markdown files
```

这样即使默认 apply 文案说 “Make the code changes required”，agent 也能从 task 和 contextFiles 看出实际要改的是 Markdown/skill/command 文件。

## 为什么这条路成立

`openspec instructions apply --json` 返回的是：

```text
contextFiles
progress
tasks
state
instruction
```

对默认 `spec-driven` 来说，`contextFiles` 会包含 proposal、specs、design、tasks。agent 在 apply 前会读这些文件。只要这些文件把非代码实现讲清楚，runtime 并不会阻止 agent 去写 Markdown 或 skill 文件。

## 代价是什么

这条路的代价是“概念不贴脸”：

- `proposal/specs/design/tasks` 这套命名仍然偏软件 change。
- 默认 `/opsx:apply` 文案仍然偏代码。
- `archive` 仍然主要围绕 spec delta merge 和 move change dir。
- `config.yaml` 和 schema 都没给非代码 apply 提供更强约束。

所以它适合快速试验，不适合长期作为团队标准。

## 什么时候升级

出现这些信号时，应该升级到 [02 稍微改](answer-agent-md-apply-02-light-touch.md)：

- agent 经常把任务误解成要改业务代码。
- 每次都要在 prompt 里重复“这是 agent/Markdown 工作流”。
- tasks 写法开始固定下来，值得沉淀成规则。
- 你希望团队默认知道这些产物不是普通代码 feature。

## 推荐判断

不大改可以用，但它本质是在默认 `spec-driven` 上“借道”。如果只是验证 OpenSpec 能不能管理 agent/MD 产物，这条路够用；如果要认真长期使用，应该尽快进入 02。
