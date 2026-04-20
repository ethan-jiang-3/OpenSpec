# OpenSpec 消化笔记 · 总索引

> 这是对 OpenSpec（[README.md](../README.md)）项目整体消化后的中文笔记，分 8 个子目录归档。
> 对应仓库版本：**v1.3.0**（见 [package.json](../package.json)）；运行要求：**Node.js ≥ 20.19.0**。

## 一句话画像

**OpenSpec 是给 AI 编程助手用的 spec-driven 协作层**——人类和 AI 在写代码之前先就「要做什么」达成一致，用一套轻量的 Markdown artifacts（proposal / specs / design / tasks）+ 斜杠命令驱动整个流程。**OPSX 是它 v1 的新指令集**，把旧的「阶段锁死」工作流换成了「流体动作」工作流。

## 本目录里有什么

| 序号 | 目录 | 讲什么 |
|------|------|--------|
| 01 | [01-opsx-overview/](01-opsx-overview/README.md) | OPSX 是什么、为什么造它、和 legacy 的根本差异 |
| 02 | [02-commands/](02-commands/core-commands.md) | 11 个 `/opsx:*` 斜杠命令详解 + 跨工具语法差异 |
| 03 | [03-workflow-sequence/](03-workflow-sequence/README.md) | 命令次序、两档 profile（core vs custom）、流程图 |
| 04 | [04-supported-tools/](04-supported-tools/README.md) | 28 个可安装的 coding agent 清单与差异 |
| 05 | [05-cli-reference/](05-cli-reference/setup.md) | `openspec` 终端 CLI 手册浓缩版 |
| 06 | [06-schemas-and-artifacts/](06-schemas-and-artifacts/artifact-graph.md) | Schema 模型、artifact DAG、delta spec 格式 |
| 07 | [07-customization/](07-customization/project-config.md) | 项目配置、自定义 schema、context/rules 注入 |
| 08 | [08-architecture/](08-architecture/source-map.md) | 源码地图、关键模块职责、扩展点 |

## 每个子目录的文件列表

**01-opsx-overview/**
- [README.md](01-opsx-overview/README.md) — OPSX 四条哲学 + legacy 痛点
- [opsx-vs-legacy.md](01-opsx-overview/opsx-vs-legacy.md) — 新旧对比表 + 流程图

**02-commands/**
- [core-commands.md](02-commands/core-commands.md) — `propose` / `explore` / `apply` / `archive`
- [expanded-commands.md](02-commands/expanded-commands.md) — `new` / `continue` / `ff` / `verify` / `sync` / `bulk-archive` / `onboard`
- [command-to-skill-map.md](02-commands/command-to-skill-map.md) — 命令 ↔ skill ↔ 模板三对映射
- [tool-specific-syntax.md](02-commands/tool-specific-syntax.md) — Claude vs Cursor vs Trae 的语法差异

**03-workflow-sequence/**
- [README.md](03-workflow-sequence/README.md) — 两档 profile 介绍
- [sequence-diagrams.md](03-workflow-sequence/sequence-diagrams.md) — 5 张 mermaid 流程图
- [when-to-use-what.md](03-workflow-sequence/when-to-use-what.md) — ff vs continue、update vs new 决策树

**04-supported-tools/**
- [README.md](04-supported-tools/README.md) — 28 个 agent 总表
- [installation-paths.md](04-supported-tools/installation-paths.md) — 每个工具的路径模板 + 4 个特例
- [tool-ids.md](04-supported-tools/tool-ids.md) — `--tools` 可用 ID（CI 用）

**05-cli-reference/**
- [setup.md](05-cli-reference/setup.md) — `init` / `update`
- [browsing-and-validation.md](05-cli-reference/browsing-and-validation.md) — `list` / `view` / `show` / `validate`
- [workflow-cli.md](05-cli-reference/workflow-cli.md) — `status` / `instructions` / `templates` / `schemas`（agent 用）
- [schema-cli.md](05-cli-reference/schema-cli.md) — `schema init/fork/validate/which`
- [config-cli.md](05-cli-reference/config-cli.md) — `config ...` 尤其 `profile`
- [misc.md](05-cli-reference/misc.md) — `archive` / `feedback` / `completion` + 环境变量

**06-schemas-and-artifacts/**
- [artifact-graph.md](06-schemas-and-artifacts/artifact-graph.md) — DAG 模型 + 状态机
- [delta-spec-format.md](06-schemas-and-artifacts/delta-spec-format.md) — ADDED/MODIFIED/REMOVED/RENAMED 语法
- [spec-driven-schema.md](06-schemas-and-artifacts/spec-driven-schema.md) — 内置 schema 全貌
- [change-folder-layout.md](06-schemas-and-artifacts/change-folder-layout.md) — change 目录约定

**07-customization/**
- [project-config.md](07-customization/project-config.md) — `openspec/config.yaml`
- [custom-schemas.md](07-customization/custom-schemas.md) — 自定义 schema 三种模板例子
- [schema-resolution-order.md](07-customization/schema-resolution-order.md) — 两级四档解析优先级

**08-architecture/**
- [source-map.md](08-architecture/source-map.md) — 源码目录到职责映射
- [extension-points.md](08-architecture/extension-points.md) — 加新 agent / workflow / schema 怎么动手

## 推荐阅读顺序

想快速上手：**01 → 03 → 02 → 05**
想做定制开发：**01 → 06 → 07 → 08**
想集成到 CI：**04 → 05（setup 和 workflow-cli 两篇）**

## 最关键的几个数字

- **28** 个 coding agent 适配器（[src/core/config.ts](../src/core/config.ts) 里 `AI_TOOLS` 数组）
- **11** 个 `/opsx:*` 斜杠命令（4 个 core + 7 个 expanded）
- **4** 种内置 artifact（proposal / specs / design / tasks，见 [schemas/spec-driven/schema.yaml](../schemas/spec-driven/schema.yaml)）
- **1** 个内置 schema（`spec-driven`），其它都靠用户自己 fork / init 生成

## 与官方文档的关系

本目录是**消化版中文笔记**，不是原文搬运。官方原文在 [docs/](../docs/)，重点文档：

- [docs/opsx.md](../docs/opsx.md) — OPSX 的完整定义
- [docs/supported-tools.md](../docs/supported-tools.md) — 工具清单
- [docs/commands.md](../docs/commands.md) — 命令参考
- [docs/cli.md](../docs/cli.md) — CLI 参考
- [docs/concepts.md](../docs/concepts.md) — 核心概念
- [docs/customization.md](../docs/customization.md) — 定制指南
