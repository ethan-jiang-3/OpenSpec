# mechanisms — 主干之外的补充机制库

`mechanisms/` 不是第五条主线，也不是源码目录清单。它收拢的是理解 OpenSpec 时会继续冒出来的工程追问：

- 多仓库和团队上下文到底怎么协调？
- OpenSpec 的 workflow 怎么进入不同 coding agent？
- Markdown 文档为什么能被当成可靠状态？
- 为什么有这么多 `/opsx:*` workflow 模板？
- completion、telemetry、feedback 这些周边设施和核心系统是什么关系？

这些问题都很重要，但它们不是第一次理解 OpenSpec 的入口。更合适的读法是：先读 `../system/` 建立整体模型，再读 `../schema/`、`../spec_cli/`、`../internal-spec-driven/` 掌握主干机制；当你开始追问“这套系统如何扩展、如何落到不同工具、如何保证文件状态可解释”时，再回到这里。

## 读者定位

这里默认读者已经熟悉 SDD、AI Coding、agent workflow 和本地 CLI 工具链。文档不会从“什么是 Markdown”或“什么是 CLI”讲起，而是解释 OpenSpec 对这些常见组件做了哪些工程化取舍。

## 文件导航

| # | 文件 | 回答的问题 |
|---|------|------------|
| 0 | `00-map.md` | 这些机制为什么被收拢在一起，读的时候怎么选 |
| 1 | `01-store-模型与仓库协同.md` | v1.5.0 的 store/reference/workset 如何替代旧 workspace/context-store/initiative |
| 2 | `02-tool-delivery.md` | 同一套 workflow 语义如何投递到不同 coding agent |
| 3 | `03-spec-model.md` | Markdown 如何成为可验证、可查询、可归档的协议状态 |
| 4 | `04-workflow-templates.md` | workflow 模板为什么是 agent 操作手册源码，而不是 CLI 硬编码流程 |
| 5 | `05-cli-infra.md` | completion、telemetry、feedback、prompts、utils 为什么属于全局支撑层 |

## 和主干专题的关系

| 主干专题 | 这里补什么 |
|----------|------------|
| `../system/` | system 讲整体分层；这里补每个补充机制的工程动机和实现边界 |
| `../spec_cli/` | spec_cli 讲 CLI 作为 runtime API；这里补 read model、completion、feedback 等支撑设施 |
| `../schema/` | schema 讲 artifact DAG；这里补 Markdown parser/validator 如何让文件状态可计算 |
| `../internal-spec-driven/` | internal-spec-driven 深挖默认核心命令；这里补 expanded workflows 和 agent 模板层 |

## 不该怎么读

不要把这里当成源码逐文件索引。源码覆盖索引在 `../_coverage/`，这里关心的是机制意义：为什么 OpenSpec 需要这些层，它们各自保护了什么边界，以及改动这些层时会牵动哪些系统假设。
