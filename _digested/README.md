# _digested — OpenSpec 源码消化

这个目录是对 OpenSpec 源码的**消化分析**：从 TypeScript 源码出发，理解机制、架构和设计意图。它不是用户指南——想学怎么用 OpenSpec 去 `_openspec_handbook/`。

> **当前源码基线**：本文档集以 OpenSpec `v1.8.0`（upstream `e50bd09`；release tag `v1.8.0` = `d578896`）为准。版本演进和旧行为只记录在 [`_change_log/`](./_change_log/README.md)；正文中的机制结论描述当前 release。

更准确地说，`_digested/` 面向已熟悉 SDD、AI Coding、CLI/agent 工程，但尚未建立 OpenSpec 概念体系的读者。这里先带你抓住 OpenSpec 的思想主轴，再进入源码机制——而不是把源码目录平铺成分类货架。

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
| `system/` | 总体系统专题 | repo-local planning、store coordination、tool delivery、agent runtime API 的整体模型 |
| `spec_cli/` | CLI 架构解读 | CLI 作为"本地运行时 API"的设计意图和命令 IO 模型 |
| `schema/` | schema 系统专题 | schema 概念、内置 schema 详解、自定义实战 |
| `spec-driven-capability/` | capability 规划与治理 | 把系统组织成可独立演化的行为合同切片，并解释 nested path、catalog 与长期演进 |
| `internal-spec-driven/` | 核心命令源码剖析 | spec-driven 下 explore/propose/apply/archive 的精确机制 |
| `mechanisms/` | 补充机制库 | store、tool delivery、spec model、workflow templates、CLI infra 等工程追问 |
| `specs_truth/` | 主 specs 源真相治理 | specs 怎么被 delta 构造、为什么会和代码失真、七种修法与问题→方法决策矩阵 |
| `_coverage/` | 覆盖矩阵 | 维护用索引，按源码、OpenSpec 自身 specs、测试目录追踪 digest 覆盖状态 |
| `_change_log/` | 上游同步记录 | 每次 upstream 版本同步的变更摘要 |

## 阅读路径

- **熟悉 SDD/AI Coding，但不熟 OpenSpec** → `system/00-map.md` → `system/07-OpenSpec-工程思想.md` → `system/08-对照常见-SDD-与-AI-Coding.md`
- **想先建立整体系统模型** → `system/`，从 `00-map.md` 开始
- **只想理解 CLI 设计** → `spec_cli/`，从 `00-map.md` 开始
- **想自定义工作流** → `schema/`，从 `00-map.md` 开始
- **想规划 capability、采用 nested path 或治理增长中的 specs** → `spec-driven-capability/`，从 `00-map.md` 开始
- **想彻底搞懂每条命令** → `internal-spec-driven/`，从 `00-四条命令的共有机制.md` 开始
- **读完主干后还有工程追问** → `mechanisms/`，从 `00-map.md` 开始
- **想搞清楚 specs 为什么和代码对不上、怎么修** → `specs_truth/`，从 `00-map.md` 开始
- **想检查源码覆盖缺口** → `_coverage/`。这是维护索引，不是新人阅读入口
- **想跟踪上游变更** → `_change_log/`

推荐主干顺序：

```text
system/
  → system/07 + system/08（概念桥梁）
  → schema/ 或 spec_cli/
  → internal-spec-driven/
  → mechanisms/（按问题跳读）
```

`_digested_v1.3/` 只作为历史覆盖清单和旧版思路参考；当前机制结论以 `_digested/` 内这些专题和当前源码为准。
