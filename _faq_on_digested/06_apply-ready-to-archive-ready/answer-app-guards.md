# 答案 APP Guards：Apply 什么时候必须暂停或停止

## 一句话

`/openspec-apply-change` 不是”无论如何把 tasks 全部做完”。它有明确 guardrails：如果 planning 不完整、task 不清楚、设计被代码事实推翻、实施出错或用户中断，agent 应该暂停，而不是猜。

## blocked：不能开始实施

`openspec instructions apply --change <name> --json` 返回 `state: "blocked"` 时，agent 不能写业务代码。

常见原因：

| 原因 | 说明 | 下一步 |
|---|---|---|
| 缺 required artifact | `apply.requires` 中的 artifact 没有输出文件（同时返回按构建顺序排列的 `missingPrerequisites`）。 | 展示缺失项与 CLI `instruction` 给出的恢复命令 `openspec instructions <target> --change <name>`（保留 `--store`），不要自行假定别的工件已 ready。 |
| 缺 tracking file | schema 配了 `tracks: tasks.md`，但文件不存在。 | 按 CLI `instruction` 给出的 `openspec instructions <tasks-id> --change <name>` 生成或修复 tracking file。 |
| tracking file 没有可用 checkbox 任务 | 文件不可读、没有任何复选框，或复选框后没有任务文本。 | 补充带描述的 checkbox 任务或重建 tracking file。 |

注意：只有缺 required artifact 时才一定有 `missingArtifacts`。tracks 文件缺失、不可读或无可用 checkbox 任务也会 blocked，但不一定带 `missingArtifacts`。

## all_done：不需要再实施

如果 `state: "all_done"`，说明 tracking file 里的跟踪任务（checkbox）都完成了。

agent 不应该继续改代码，也不应把 `all_done` 直接等同于立即归档，而应该：

```text
报告全部跟踪任务已完成（All tracked tasks are complete）
建议归档前按需复核或验证（Review or verify the change as appropriate before archiving）
待用户复核确认后再触发归档（openspec archive 或 openspec-archive-change）
```

archive 会合并 specs 并移动 change，这是后续动作。

## task 不清楚

如果 pending task 不足以指导实现，例如：

```text
- [ ] Improve auth
```

agent 不应该自行扩大解释。应该暂停并问清楚，或建议更新 tasks/design/specs。

## 实施暴露设计问题

真实代码可能推翻 proposal/design 中的假设，例如：

```text
design 假设有 session abstraction
代码里实际只有 route-local cookie handling
```

这时继续硬写会造成更大偏差。agent 应该暂停，说明发现，并建议：

```text
回到 explore 讨论
更新 design.md
更新 tasks.md
必要时更新 specs
```

OpenSpec apply 不是 phase lock。回写 planning artifacts 是允许的。

## 测试或验证失败

如果 task 实施后测试失败：

- 原因清楚，且修复属于当前 task：可以修。
- 原因不清或涉及 scope/design 决策：暂停。
- 失败暴露新的 requirement：建议更新 specs/tasks。

agent 不应该把大量无关修复塞进当前 task。

## 用户中断或改变方向

用户中断时，agent 应该停止当前循环，汇报：

```text
已完成哪些 tasks
当前正在做哪个 task
文件改动概况
下一步建议
```

不要继续自动跑完剩余 tasks。

## 暂停输出应该包含什么

一个好的暂停输出应该包含：

```text
Change: <name>
Progress: N/M complete
Completed this session:
- ...
Issue encountered:
<具体阻塞>
Options:
1. 更新 artifact
2. 调整 task scope
3. 用户确认后继续
```

暂停的目的不是把问题丢回给用户，而是保持状态清楚，让下一次继续时不会丢上下文。

## 参考来源

源码引用以 [`../../_digested/README.md`](../../_digested/README.md) 声明的「当前源码基线」（`0c737dc1`）为准：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/apply-change.ts` | blocked/all_done、暂停条件、输出格式 |
| `src/commands/workflow/instructions.ts` | blocked/all_done/ready 判定、missingArtifacts 语义 |
| `src/core/change-status-policy.ts` | actionContext（repo-local）和 allowedEditRoots |
| `_digested/internal-spec-driven/03-apply-实施执行.md` | apply gate 和 fluid workflow 解释 |
