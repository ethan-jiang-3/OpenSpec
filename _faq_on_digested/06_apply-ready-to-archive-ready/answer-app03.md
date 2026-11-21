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

源码主线在 `src/commands/workflow/instructions.ts`（CLI 入口 `applyInstructionsCommand()` 走 store-aware 的 `resolveRootForCommand()` + `toPlanningHome(root)`，见 `src/core/root-selection.ts:576`；`generateApplyInstructions()` 仅在未传入 `options.planningHome` 时才回退到 `src/core/planning-home.ts:74` 的 `resolveCurrentPlanningHomeSync()`）：

```text
applyInstructionsCommand()
  resolveRootForCommand() -> toPlanningHome(root)
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
    "done": false,
    "sourcePath": "…/openspec/changes/add-oauth-login/tasks.md",
    "line": 12
  }
]
```

`sourcePath` + 1-based `line`（v1.14.0 起）定位该 checkbox 在 tracking file 中的确切行，供 apply workflow 勾选时使用；v2.0.0（`#2228`）起 `parseLocatedTaskLines()`（`src/utils/task-progress.ts:126-150`）还会把同一 Markdown 段落内的折行续行（遇到空行、ATX 标题、代码围栏、块引用、`<!`/`<?`、分隔线或下一个列表项前，去掉硬换行尾 `\`）用单空格拼回 `description`，避免折行任务被截成半句，同时 `line` 仍指复选框所在行且不改变任务计数。

解析规则来自共享常量 `TASK_LINE_PATTERN`（`src/utils/task-progress.ts:55`）：

```text
/^\s*(?:[-*+]|\d{1,9}[.)])\s*\[(?:\s*([^\]\s]?)\s*\](?![([])|\s+\])\s*(.*)/
```

也就是说：

- 支持全部 CommonMark 列表标记：`-`、`*`、`+` 以及最多 9 位有序编号 `1.` / `1)`，并允许前导缩进（如 `  - [ ] 1.1.1 子任务`）。
- 只有 `[x]` 或 `[X]`（允许空格如 `- [ x]`）算已完成（`done: true`）。
- **其余所有单字符或空复选框标记都计为未完成（`done: false`）**：包括 `- [ ] Task`、`- [?] Task`、`- [~] Task`、`- [-] Task`、`- [] Task`、`- [1] Task`（防止把 `[~]`/`[?]` 静默漏算成“已完成”）。
- 多字符括号（如 `- [WIP] Task`）以及 `]` 后紧跟 `(` 或 `[` 的 Markdown 链接（如 `- [A](url)`、`- [1][ref]`）不匹配为 checkbox，避免普通链接列表变成幽灵任务。
- 不带复选框的列表项（如 `- Task`，或 `## Workflow follow-up` 下的纯 bullet）不计入进度。

## `state`

`state` 是 apply 的分支控制：

| state | 来源条件 | agent 行为 |
|---|---|---|
| `blocked` | 缺 required artifact、缺 tracks 文件、tracks 文件不可读，或没有带描述的 checkbox tasks。 | 停止实施，按 CLI `instruction` 给出的 `openspec instructions <target> --change <name>` 修复或补建工件。 |
| `ready` | required artifacts 存在，tracking file 有未完成 tasks（或 schema 未配 `tracks`）。 | 读取 contextFiles 并开始 task loop。 |
| `all_done` | tracking file 中所有 checkbox tasks 都完成。 | 不再实施，报告跟踪任务已完成，提示归档前先复核或验证（review/verify）。 |

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
blocked -> 不实施，按 CLI instruction 给出的 openspec instructions <target> 补/修 planning
ready -> 读 contextFiles，执行 tasks（每勾完一条重跑 instructions apply 核对进度）
all_done -> 提示归档前先复核或验证（review/verify），确认后再归档
```

这就是 apply 阶段真正的入口。

## 参考来源

源码引用以 [`../../_digested/README.md`](../../_digested/README.md) 声明的「当前源码基线」（`0c737dc1`）为准：

| 来源 | 用到的结论 |
|---|---|
| `src/utils/task-progress.ts` + `src/commands/workflow/instructions.ts` | `TASK_LINE_PATTERN`、`parseLocatedTaskLines()`（含折行续行拼接）、`generateApplyInstructions()`、state/progress/tasks 输出 |
| `schemas/spec-driven/schema.yaml` | 默认 apply requires/tracks/instruction |
| `src/core/templates/workflows/apply-change.ts` | apply skill 如何消费 apply instructions |
