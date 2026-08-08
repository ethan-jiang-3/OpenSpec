# 答案 APP03：`instructions apply --json` 返回了什么

## 一句话

`openspec instructions apply --change "<name>" --json` 是 apply 阶段的 runtime API。它把 planning artifacts 和 schema apply 配置解释成 agent 可执行的实施包：

```text
state
contextFiles
progress
tasks
missingArtifacts
instruction
```

agent 不是靠猜测进入实施，而是先消费这个 JSON。

## 调用链

源码主线在 `src/commands/workflow/instructions.ts`：

```text
applyInstructionsCommand()
  resolveCurrentPlanningHomeSync()
  validateChangeExists()
  generateApplyInstructions()
```

`generateApplyInstructions()` 做这些事：

1. `loadChangeContext()`，自动从 change metadata 解析 schema。
2. `resolveSchema()`，读取 schema 的 `apply` 配置。
3. 检查 `apply.requires` 中的 required artifacts 是否存在。
4. 收集所有已有 artifact 输出文件，生成 `contextFiles`。
5. 如果 schema 配置了 `tracks`，读取并解析 tracking file。
6. 计算 progress。
7. 返回 state 和 instruction。

## `contextFiles`

`contextFiles` 是：

```text
artifact id -> concrete file paths
```

例如：

```json
{
  "contextFiles": {
    "proposal": ["/repo/openspec/changes/add-auth/proposal.md"],
    "specs": ["/repo/openspec/changes/add-auth/specs/auth/spec.md"],
    "design": ["/repo/openspec/changes/add-auth/design.md"],
    "tasks": ["/repo/openspec/changes/add-auth/tasks.md"]
  }
}
```

它来自 schema 中所有 artifacts 的 `generates`。只要某个 artifact 有实际输出文件，就会被加入 context files。

apply skill 明确要求：

```text
Read every file path listed under contextFiles before starting.
```

所以 agent 不能硬编码 `proposal.md`、`design.md`、`tasks.md`；它应该跟 CLI 返回的 `contextFiles` 走。

## `progress`

`progress` 形如：

```json
{
  "total": 7,
  "complete": 2,
  "remaining": 5
}
```

它来自 tracking file 中的 checkbox tasks。

如果没有任何 checkbox task：

```text
total = 0
complete = 0
remaining = 0
```

并且如果 schema 配置了 `tracks`，这会导致 `state: "blocked"`。

## `tasks`

`tasks` 是从 tracking file 解析出来的数组：

```json
[
  {
    "id": "1",
    "description": "1.1 Add OAuth callback route",
    "done": false
  }
]
```

解析规则来自共享 parser `parseTaskLines()`（`src/utils/task-progress.ts`）：

```text
^\s*[-*]\s*\[([\sxX])\]\s*(.*)
```

也就是说：

- `- [ ] Task` 是未完成。
- `- [x] Task` 是完成。
- `- [X] Task` 也是完成。
- `* [ ] Task` 也支持。
- `  - [ ] 1.1.1 子任务` 也算（v1.8.0 起允许前导缩进，子任务计入进度）。
- `- Task` 不算。
- `- [?] Task` 不算。

## `state`

`state` 是 apply 的分支控制：

| state | 来源条件 | agent 行为 |
|---|---|---|
| `blocked` | 缺 required artifact、缺 tracks 文件、或 tracks 文件没有 checkbox tasks。 | 停止实施，修 planning artifact。 |
| `ready` | required artifacts 存在，tracking file 有未完成 tasks。 | 读取 contextFiles 并开始 task loop。 |
| `all_done` | tracking file 中所有 checkbox tasks 都完成。 | 不再实施，建议 archive。 |

`missingArtifacts` 只在缺 required artifact 时出现。缺 `tasks.md` 或 `tasks.md` 没有 checkbox 也会 blocked，但不一定有 `missingArtifacts`。

## `instruction`

`instruction` 来自 schema 的 apply 配置：

```yaml
apply:
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
    Pause if you hit blockers or need clarification.
```

如果 schema 没有配置，代码会给默认 instruction。

agent 应该把它当作当前 apply 阶段的动态指导，而不是 artifact 内容。

## 小结

`instructions apply --json` 把“可以开始实施吗”变成明确状态：

```text
blocked -> 不实施，补 planning
ready -> 读 contextFiles，执行 tasks
all_done -> 建议 archive
```

这就是 apply 阶段真正的入口。

## 参考来源

源码引用基于 commit `ff4576f`：

| 来源 | 用到的结论 |
|---|---|
| `src/utils/task-progress.ts` + `src/commands/workflow/instructions.ts` | `parseTaskLines()`（共享 parser）、`generateApplyInstructions()`、state/progress/tasks 输出 |
| `schemas/spec-driven/schema.yaml` | 默认 apply requires/tracks/instruction |
| `src/core/templates/workflows/apply-change.ts` | apply skill 如何消费 apply instructions |
