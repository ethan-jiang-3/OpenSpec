# _digested — OpenSpec 源码消化

这个目录是对 OpenSpec 源码的**消化分析**：从 TypeScript 源码出发，精确理解机制、架构和设计意图。它不是用户指南——想学怎么用 OpenSpec 去 `_spec_full_content/`。

## 与同级目录的关系

| 目录 | 本质 | 受众 |
|------|------|------|
| **`_digested/`** | 源码消化，机制剖析 | 想彻底搞懂背后发生了什么的人 |
| `_spec_full_content/` | 应用指南，按认知层次教你怎么用 | 想用好 OpenSpec 的开发者 |
| `_faq_on_digested/` | 跨消化材料的二次研究 | 我自己（产出者） |
| `_digested_v1.3/` | v1.3.0 时代的初代消化材料（已归档） | 历史参考 |

## 子目录

| 目录 | 聚焦 | 一句话 |
|------|------|--------|
| `spec_cli/` | CLI 架构解读 | CLI 作为"本地运行时 API"的设计意图和命令 IO 模型 |
| `schema/` | schema 系统专题 | schema 概念、内置 schema 详解、自定义实战 |
| `internal-spec-driven/` | 核心命令源码剖析 | spec-driven 下 explore/propose/apply/archive 的精确机制 |
| `_change_log/` | 上游同步记录 | 每次 upstream 版本同步的变更摘要 |

## 阅读路径

- **只想理解 CLI 设计** → `spec_cli/`，从 `00-map.md` 开始
- **想自定义工作流** → `schema/`，从 `00-map.md` 开始
- **想彻底搞懂每条命令** → `internal-spec-driven/`，从 `00-四条命令的共有机制.md` 开始
- **想跟踪上游变更** → `_change_log/`
