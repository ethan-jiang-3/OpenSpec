# 答案 APP06：task 实施循环和 checkbox 更新

## 一句话

apply 的核心不是一次性“实现整个 change”，而是围绕 pending tasks 的小循环：

```text
选一个未完成 task
  -> 读相关上下文和代码
  -> 做最小实现
  -> 验证
  -> tasks.md checkbox 改成 done
  -> 继续下一个 task
```

checkbox 更新不是形式主义，它是 OpenSpec 追踪实施进度的事实源。

## pending task 从哪里来

pending tasks 来自：

```bash
openspec instructions apply --change "<name>" --json
```

返回的 `tasks` 数组中：

```json
{ "description": "1.1 Add OAuth callback route", "done": false }
```

`done: false` 的就是 pending task。

任务顺序来自 `tasks.md` 文件中的顺序。apply 不再对 tasks 做 DAG 排序；排序责任在 propose 创建 `tasks.md` 时已经完成。

## 实施一个 task 前要做什么

agent 不应该只看 task 描述。它应先读取：

```text
proposal -> why / scope
specs    -> behavior / scenarios
design   -> technical decisions
tasks    -> implementation checklist
```

然后再结合真实代码调查：

```text
rg 搜索相关符号
读入口文件和测试
检查现有 patterns
确认最小修改面
```

task 描述告诉 agent 做哪一小步；context files 告诉 agent 这一步为什么存在、应该满足什么行为。

## 最小化代码修改

apply skill 要求：

```text
Keep changes minimal and focused
```

这意味着每个 task 应该尽量：

- 只改完成该 task 必需的文件。
- 沿用项目既有 patterns。
- 不夹带无关重构。
- 不提前实现后续 task 的大块内容。
- 执行该 task 声明的 verification；失败或无法执行时不勾选。

如果一个 task 实施时发现必须大幅改变 design，说明 planning artifact 可能需要更新，而不是硬继续。

## checkbox 怎么更新

未完成：

```markdown
- [ ] 2.1 Add OAuth callback route — verify: run the focused callback tests
```

完成后：

```markdown
- [x] 2.1 Add OAuth callback route — verify: run the focused callback tests
```

解析器也接受：

```markdown
- [X] 2.1 Add OAuth callback route — verify: run the focused callback tests
```

但建议统一用小写 `x`。

完成 task 并通过其 verification 后应立即更新 checkbox。不要等一批任务都做完再统一改，因为中途暂停时进度会丢失。

## progress 如何变化

下一次运行：

```bash
openspec instructions apply --change "<name>" --json
```

CLI 会重新解析 `tasks.md`，计算：

```text
total
complete
remaining
```

例如：

```text
修改前：1/5 complete
完成一个 task 并勾选后：2/5 complete
```

这说明进度不是存在隐藏数据库里，而是由 `tasks.md` 的 checkbox 实时解释出来。

## 什么时候继续，什么时候停

agent 可以继续下一个 pending task，直到：

- 所有 tasks 完成。
- 某个 task 不清楚。
- 实施暴露设计问题。
- 测试失败且需要决策。
- 用户中断。

停下来不是失败。OpenSpec 的 apply 模板明确允许 fluid workflow：实施中发现问题，可以更新 artifacts 后继续。

## 完成后的状态

所有 checkbox 都完成时：

```text
progress.complete == progress.total
progress.remaining == 0
```

再次获取 apply instructions 会得到：

```text
state: "all_done"
```

这时 agent 应该建议：

```text
run tests / review changes
then /opsx:archive
```

archive 仍然需要用户显式触发。

## 参考来源

源码引用：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/apply-change.ts` | task loop、最小化修改、完成后更新 checkbox、暂停条件 |
| `src/commands/workflow/instructions.ts` | checkbox 解析、progress 计算、all_done 判定 |
| `schemas/spec-driven/schema.yaml` | `tracks: tasks.md` 和默认 apply instruction |
