# 01 · Schema 到底是什么

> 回 [导读](00-map.md)

这篇文章解决最根本的问题：OpenSpec 里反复出现的 "schema" 这个词，到底指什么。

---

## 它不是什么

先把常见误解排除掉：

| 误解 | 实际情况 |
|------|---------|
| Database schema（数据库表结构） | 完全无关。OpenSpec 的 schema 不定义数据模型 |
| Template（模板） | template 只是 schema 的一个**部件**，不是同义词 |
| Config（项目配置） | config.yaml 是"提示注入层"，schema 是"工作流结构层" |
| JSON Schema / Zod Schema | OpenSpec 内部用 Zod 校验 schema.yaml 的**格式**，但 schema 本身是工作流定义 |

---

## 它是什么

用一句话定义：

> **Schema 是一次 change 的工作流骨架定义文件。**

更具体地说，它定义：

| 维度 | 它回答什么 |
|------|-----------|
| artifact 种类 | 这次 change 需要哪些产物？（proposal？specs？design？review？） |
| 产出文件 | 每个产物生成什么文件？写到哪里？ |
| 模板绑定 | 每个产物用哪个 Markdown 模板作为起点？ |
| AI 指令 | 生成每个产物时，给 AI 什么专属写作指令？ |
| 依赖关系 | 哪些产物必须在哪些产物之后生成？ |
| apply 条件 | 实现阶段什么时候可以开始？追踪哪个文件？ |

---

## 一张图看懂

```
schema.yaml 定义的 artifact 依赖图（spec-driven 为例）：

  proposal ──→ specs
     │            │
     └──→ design  │
            │     │
            └──→ tasks
                   │
                   └──→ apply (实现阶段)
```

这不是业务图，不是架构图，是 **artifact 依赖图**。它描述的是"一个 change 的产物之间怎么关联"。

---

## schema 和其他概念的边界

这是最容易混的地方，专门列一张表：

| 概念 | 位置 | 它管什么 | 类比 |
|------|------|---------|------|
| `specs` | `openspec/specs/` | 项目当前**已成立的行为合同** | 代码库的"当前版本" |
| `config.yaml` | `openspec/config.yaml` | 项目级**提示背景 + 默认 schema** | 项目的"README + 编码规范" |
| `schema.yaml` | `openspec/schemas/<name>/schema.yaml` | change 的**工作流骨架** | 工作流的"模板定义" |
| `.openspec.yaml` | `openspec/changes/<name>/.openspec.yaml` | 这次 change **实际绑定的 schema** | 这次工作的"配置文件" |
| `template` | `schemas/<name>/templates/*.md` | 单个 artifact 的 **Markdown 骨架** | "文档模板" |

---

## 一个最小 schema 长什么样

```yaml
name: my-minimal
version: 1
description: 最简单的工作流——只有 proposal 和 tasks

artifacts:
  - id: proposal
    generates: proposal.md
    description: 初始提案
    template: proposal.md
    instruction: |
      写一份提案，说清楚为什么做、做什么、影响什么。
    requires: []

  - id: tasks
    generates: tasks.md
    description: 实现清单
    template: tasks.md
    instruction: |
      把实现工作拆成可验证的任务清单。
    requires:
      - proposal

apply:
  requires: [tasks]
  tracks: tasks.md
```

这个 schema 定义了：
- 2 个 artifact（proposal 和 tasks）
- proposal 先生成，tasks 依赖 proposal
- apply 在 tasks 完成后可用
- 每个 artifact 有自己的模板和 AI 指令

**你不需要任何代码**——这个 YAML 文件本身就是一个完整的工作流定义。

---

## 核心设计哲学

1. **Artifact 图而非工作流引擎**：`requires` 意味着前置 artifact 的内容会作为上下文传入，而非强制线性执行。依赖关系是"赋能者"而非"门控"。
2. **文件系统即数据库**：完成状态通过文件是否存在判断，不存储额外状态。
3. **流体而非僵化**：无阶段门控，可以随时更新任何 artifact。
4. **渐进式严谨**：大多数变更保持轻量模式，高风险场景才启用完整 spec。

---

## 为什么叫 schema 而不叫 workflow

OpenSpec 刻意避免叫 "workflow"，因为：

- "workflow" 暗示流程引擎、状态机、阶段门控
- "schema" 更准确：它定义的是**结构**（有哪些产物、它们怎么关联），不是**流程**（先做A再做B）

但实际使用中，你可以把它当 workflow 理解——只是需要记住它比传统 workflow 更灵活。
