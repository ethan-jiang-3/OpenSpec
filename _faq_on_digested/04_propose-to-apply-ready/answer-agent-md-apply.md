# 答案：非代码 / Agent Markdown Apply 的三条路径

## 一眼结论

OpenSpec 的 apply runtime 可以借给 agent、Markdown、skill、command 这类非传统代码产物，但不要把所有问题塞进一个方案里。更清楚的看法是三条路径：

| 路径 | 改动成本 | 适用场景 | 主要风险 | 推荐度 |
|---|---:|---|---|---|
| [01 不大改](answer-agent-md-apply-01-no-change.md) | 最低 | 想马上试，用默认 `spec-driven` 跑 agent/MD 任务 | 概念名和默认 `/opsx:apply` 文案偏代码/spec | 可试，但不适合长期沉淀 |
| [02 稍微改](answer-agent-md-apply-02-light-touch.md) | 中低 | 想低成本稳定使用，不想碰 OpenSpec 源码 | 仍受默认 artifact 名称约束 | **推荐第一步** |
| [03 项目级 schema 大改](answer-agent-md-apply-03-project-schema.md) | 中等 | agent/skill/Markdown 已是长期主流程，需要自己的 artifact DAG | 需要维护 schema/templates | 推荐作为第二阶段 |

我的建议顺序是：

```text
先走 02 稍微改
  -> 跑过几轮，确认 agent/MD/skill 工作流确实稳定
  -> 再升级到 03 项目级 schema
```

不建议第一步就把 schema 装进 OpenSpec package 或用户全局 schema。项目级 schema 放在 `openspec/schemas/<name>/`，优先级最高、随项目版本化、调试最方便，也不污染别的项目。

## 为什么这三条路都成立

证据在 `src/commands/workflow/instructions.ts` 的 `generateApplyInstructions()`：apply runtime 从 schema 读取 `apply.requires`、`apply.tracks`、`apply.instruction`，再把已有 artifact 输出整理成 `contextFiles`。也就是说，CLI 不硬编码“只能改程序代码”。

限制在 `src/core/templates/workflows/apply-change.ts`：默认 `/opsx:apply` / `openspec-apply-change` 模板仍带有代码实现措辞，例如 “Make the code changes required”。这属于 tool delivery 文案偏置，不是 runtime 硬限制。

所以问题不是“能不能用”，而是“你愿意在哪一层做多少适配”：

| 你改哪层 | 能解决什么 |
|---|---|
| 不改 schema，只写好 artifacts/tasks | 最快借用现有 OpenSpec loop。 |
| 改 `config.yaml`、任务写法、少量 schema instruction | 让默认 loop 更稳地服务 agent/MD 产物。 |
| 建项目级 schema | 让概念、artifact、apply gate 都贴合 agent/skill/Markdown 工作流。 |

## 三个答案怎么读

如果你只是想知道“今天能不能先用起来”，读 [01 不大改](answer-agent-md-apply-01-no-change.md)。

如果你想知道“最现实、最少折腾的推荐方案是什么”，读 [02 稍微改](answer-agent-md-apply-02-light-touch.md)。

如果你已经确定要长期把 OpenSpec 用在 agent/Markdown/skill 生产上，读 [03 项目级 schema 大改](answer-agent-md-apply-03-project-schema.md)。

## 底线判断

OpenSpec 可以低改造地借给非代码工作流，因为它的核心是：

```text
文件保存状态
schema 定义 artifact DAG
CLI 解释状态并投递 context
agent 按 tasks 执行并更新 checkbox
```

但它不会自动替你解决：

- skill/command 是否真的安装到目标 agent runtime。
- Markdown 是否满足某个发布系统格式。
- 非 spec 产物如何“合并回正式 baseline”。
- 非代码领域的专门 validation。

这些可以先写进 tasks，让 agent 执行；等流程稳定后，再决定是否做专门 adapter、validator 或 archive 扩展。

## 参考来源

| 来源 | 用到的结论 |
|---|---|
| `src/commands/workflow/instructions.ts` | apply runtime 从 schema 读取 `apply.requires`、`apply.tracks`、`apply.instruction`，并生成 `contextFiles/progress/tasks/state`。 |
| `src/core/templates/workflows/apply-change.ts` | 默认 apply skill/command 的 agent loop 和代码偏置文案。 |
| `_digested/schema/04-schema-解析优先级.md` | 项目级 schema 优先于用户级和包内置 schema。 |
