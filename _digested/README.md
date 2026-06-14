# _digested — OpenSpec 源码消化

这个目录是对 OpenSpec 源码的**消化分析**：从 TypeScript 源码出发，精确理解机制、架构和设计意图。它不是用户指南——想学怎么用 OpenSpec 去 `_openspec_handbook/`。

## 与同级目录的关系

| 目录 | 本质 | 受众 |
|------|------|------|
| **`_digested/`** | 源码消化，机制剖析 | 想彻底搞懂背后发生了什么的人 |
| `_openspec_handbook/` | 按认知层次组织的学习手册 | 想用好 OpenSpec 的开发者 |
| `_faq_on_digested/` | 跨消化材料的二次研究 | 我自己（产出者） |
| `_digested_v1.3/` | v1.3.0 时代的初代消化材料（已归档） | 历史参考 |

## 子目录

| 目录 | 聚焦 | 一句话 |
|------|------|--------|
| `system/` | 总体系统专题 | repo-local planning、workspace、context store、tool delivery、agent runtime API 的整体模型 |
| `spec_cli/` | CLI 架构解读 | CLI 作为"本地运行时 API"的设计意图和命令 IO 模型 |
| `schema/` | schema 系统专题 | schema 概念、内置 schema 详解、自定义实战 |
| `internal-spec-driven/` | 核心命令源码剖析 | spec-driven 下 explore/propose/apply/archive 的精确机制 |
| `workspace/` | workspace 内核专题 | workspace/context-store/initiative 的状态、open surface、opener、skills 与解析机制 |
| `tool-delivery/` | 工具投递专题 | AI 工具 registry、skill/command 生成、adapter、init/update、drift 与迁移 |
| `spec-model/` | 文档数据模型专题 | Markdown parser、change/spec schema、validator、show/list/view/validate 数据流 |
| `workflow-templates/` | workflow 模板专题 | new/continue/ff/sync/verify/bulk-archive/onboard/feedback 等 agent 操作手册源码 |
| `cli-infra/` | CLI 支撑设施专题 | completion、telemetry、feedback、prompts、utils、converter |
| `_coverage/` | 覆盖矩阵 | 按源码、OpenSpec 自身 specs、测试目录追踪 digest 覆盖状态 |
| `_change_log/` | 上游同步记录 | 每次 upstream 版本同步的变更摘要 |

## 阅读路径

- **想先建立整体系统模型** → `system/`，从 `00-map.md` 开始
- **只想理解 CLI 设计** → `spec_cli/`，从 `00-map.md` 开始
- **想自定义工作流** → `schema/`，从 `00-map.md` 开始
- **想彻底搞懂每条命令** → `internal-spec-driven/`，从 `00-四条命令的共有机制.md` 开始
- **想看多仓库/协调上下文内核** → `workspace/`，从 `00-map.md` 开始
- **想看 OpenSpec 怎么装进不同 AI 工具** → `tool-delivery/`，从 `00-map.md` 开始
- **想看 Markdown 如何变成结构化 spec/change** → `spec-model/`，从 `00-map.md` 开始
- **想看 agent workflow 模板源码** → `workflow-templates/`，从 `00-map.md` 开始
- **想看 shell completion / telemetry / 支撑设施** → `cli-infra/`
- **想看源码覆盖缺口** → `_coverage/`
- **想跟踪上游变更** → `_change_log/`

`_digested_v1.3/` 只作为历史覆盖清单和旧版思路参考；当前机制结论以 `_digested/` 内这些专题和当前源码为准。
