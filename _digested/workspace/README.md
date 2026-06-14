# workspace — workspace/context-store/initiative 内核专题

这个专题补 `_digested/` 里 workspace 相关机制的深挖。`system/` 和 `spec_cli/` 已经解释了 workspace 在总体架构和命令边界中的位置；这里专门看源码里的状态对象、迁移兼容、open surface、opener、workspace skills、context store、initiative collection。

## 文件导航

| # | 文件 | 内容 |
|---|------|------|
| 0 | `00-map.md` | workspace/context-store/initiative 的总图和源码入口 |
| 1 | `01-workspace-state.md` | `.openspec-workspace/view.yaml`、legacy state、managed registry、link 状态 |
| 2 | `02-open-surface-and-opener.md` | `AGENTS.md` guidance block、`.code-workspace`、opener launch command |
| 3 | `03-context-store-and-initiative.md` | context-store registry、metadata、initiative collection/resolution |

## 边界

- 不重复 `../schema/03-内置-workspace-planning-详解.md` 对 schema 字段的拆解。
- 不重复 `../spec_cli/04-command-deep-dive.md` 的命令百科。
- 只讲 workspace 内核如何保存、解析、生成和打开状态。
