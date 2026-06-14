# Implementation 与 Closeout Templates

## apply

`apply` 模板消费 `openspec instructions apply` 的结果。它关注：

- apply gate 是否 blocked。
- tasks 是否存在、是否有 checkbox。
- 未完成 tasks 列表。
- implementation 时是否需要更新 artifacts。
- workspace actionContext 是否允许编辑。

具体 apply gate 源码机制见 `../internal-spec-driven/03-apply-实施执行.md`。

## sync

`sync` 是 agent-driven spec merge，不是 CLI archive。

模板要求 agent：

1. 选择 change。
2. 用 `status` 获取 delta spec path。
3. 读取 delta spec 和主 spec。
4. 智能应用 ADDED/MODIFIED/REMOVED/RENAMED。
5. 保留 change active。

重要 guardrail：如果 `actionContext.mode` 是 `workspace-planning`，当前 sync 不支持 workspace spec sync，必须停止。

## verify

`verify` 用来检查实现是否与 proposal/specs/design/tasks 一致。

它不是 `validate` 的替代：

- `validate` 检查 OpenSpec 文档结构。
- `verify` 让 agent 审查代码实现、测试、任务完成度和 artifact coherence。

## archive

`archive` 模板是 agent 层的收尾操作手册。它会引导 agent 检查是否需要 sync、是否完成 tasks、是否适合调用 CLI archive。

CLI archive 源码机制见 `../internal-spec-driven/04-archive-归档合并.md`。

## bulk-archive

`bulk-archive` 面向多个 completed changes。它的风险不在单个 merge 算法，而在选择和确认：

- 哪些 changes 完成。
- 哪些需要跳过。
- 是否逐个验证。
- 失败时如何报告 partial results。

因此它比 archive 更强调清单化和用户确认。
