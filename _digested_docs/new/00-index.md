# OpenSpec 手册 · 新版总导读

> 这一版不是对 `_digested_docs/` 的微调，而是重新按”人怎么学会它”来组织。
> 核心原则只有两条：**先会用，再懂概念，最后看机制**；**先讲人用的，再讲机器怎么跑**。

---

## OpenSpec 核心哲学：为什么这样设计

在开始学习前，先理解 OpenSpec 的 5 条设计哲学。这些不是口号，而是每个设计决策背后的真实动机：

| 哲学 | 表面意思 | 背后的真实痛点 | OpenSpec 的解法 |
|------|---------|--------------|--------------|
| **fluid not rigid** | 流动不僵化 | 传统 spec 流程有”阶段锁”，需求变了也不能回头改 | 任何 artifact 随时可改，没有阶段门 |
| **iterative not waterfall** | 迭代不瀑布 | 瀑布式要求”先把所有需求想清楚”，但现实中需求是边做边清晰的 | 每个 change 是一个小迭代，允许不完整 |
| **easy not complex** | 简单不复杂 | 重型 spec 工具（如 Spec Kit）需要大量仪式感，团队不愿用 | 最小化摩擦，3 个命令就能完成一个 change |
| **brownfield not just greenfield** | 棕地优先 | 大多数真实项目都是”接手老代码”，不是从零开始 | `specs/` 是对现有系统的描述，change 是增量修改 |
| **scalable** | 可扩展 | 个人项目和企业项目的需求差异巨大 | profile 机制允许选择工作流复杂度 |

**一句话理解**：OpenSpec 不是为”完美的新项目”设计的，而是为”真实世界里的增量改代码”设计的。

---

## 这套手册怎么读

这套目录分成两大块：

### A. 面向人的主线

按认知层级来排：

1. **初级**：先把 OpenSpec 用起来，知道日常怎么走
2. **中级**：把 `specs`、`changes`、artifact、delta spec 这些概念真正连起来
3. **高级**：再理解 `config.yaml`、`schema`、`.openspec.yaml`、profile、工具集成
4. **专题**：最后看 Cline 这种具体宿主里到底发生了什么
5. **生命周期思想**：再把 OpenSpec 对软件开发生命周期的整体理解讲透

### B. 面向机器的附录

这部分讲：

- skill / command / workflow 的关系
- agent 为什么会去调用 `openspec status` / `openspec instructions`
- OpenSpec CLI 如何给宿主 agent 提供结构化上下文

这部分重要，但**不应该先读**。

---

## 推荐阅读顺序

### 路径 1：我只是想先会用

```mermaid
graph LR
    A[01-初级] --> B[02-中级]
```

### 路径 2：我已经能用了，想真正理解它

```mermaid
graph LR
    A[01-初级] --> B[02-中级] --> C[03-高级<br/>config/schema] --> D[04-高级<br/>cline集成]
    D --> E[05-高级<br/>SDLC思想] --> F[06-案例<br/>brownfield]
    F --> G[07-案例<br/>greenfield] --> H[08-高级<br/>全局约束] --> I[09-高级<br/>config实战]
```

### 路径 3：我要研究它背后的机制

在路径 2 的基础上，最后加：

```mermaid
graph LR
    I[09-高级<br/>config实战] --> J[90-附录<br/>机器协议]
```

---

## 核心术语速查

| 术语 | 一句话定义 | 具体例子 |
|------|-----------|---------|
| **change** | 一次完整的增量变更工作包 | `openspec/changes/add-dark-mode/` |
| **artifact** | change 内部的文档产物类型 | proposal.md、specs/*.md、design.md、tasks.md |
| **delta spec** | 描述"这次改了哪里"的增量规格 | `## ADDED Requirements` / `## MODIFIED Requirements` |
| **specs/** | 项目当前正式规格基线 | `openspec/specs/auth/spec.md` |
| **archive** | 把 change 的 delta spec 合并回 specs/，并归档 change | `/opsx:archive add-dark-mode` |
| **schema** | 定义 change 结构骨架的工作流定义 | artifact 种类、依赖关系 |
| **profile** | 选择安装哪些工作流命令 | core（4个命令）vs expanded（更多命令） |
| **brownfield** | 已有代码库，在上面继续改 | 接手一个跑了 3 年的系统 |
| **greenfield** | 从零开始的新项目 | 白纸一张，全新设计 |

---

## 命令速查

### 日常最常用（core profile）

| 命令 | 作用 | 典型场景 |
|------|------|---------|
| `/opsx:propose <name>` | 发起一个 change，生成 artifacts | 开始一个新功能或修复 |
| `/opsx:apply [name]` | 按 tasks.md 实现代码 | 开始写代码 |
| `/opsx:archive [name]` | 收尾，合并 delta spec 回基线 | 功能完成后归档 |

### 扩展工作流（expanded profile）

| 命令 | 作用 |
|------|------|
| `/opsx:new <name>` | 创建新 change（更细粒度） |
| `/opsx:continue` | 继续当前 change |
| `/opsx:ff` | 快进到下一个 artifact |
| `/opsx:verify` | 验证实现与 specs 一致性 |
| `/opsx:sync` | 同步 specs 状态 |
| `/opsx:explore` | 探索现有代码库，生成初始 specs |
| `/opsx:onboard` | 新成员快速了解项目 |

### CLI 命令（终端直接运行）

| 命令 | 作用 |
|------|------|
| `openspec init` | 初始化项目 |
| `openspec list` | 列出所有 changes |
| `openspec show <name>` | 查看某个 change 详情 |
| `openspec validate` | 验证 artifacts 结构 |
| `openspec archive <name>` | 归档 change |
| `openspec config profile` | 切换工作流 profile |
| `openspec update` | 更新 AI 工具的 skills/commands |

---

## 文件地图

| 文件 | 角色 | 适合谁 |
|------|------|--------|
| [01-初级-先把-openspec-用起来.md](01-初级-先把-openspec-用起来.md) | 先会用 | 第一次接触 OpenSpec 的人 |
| [02-中级-把核心概念真正串起来.md](02-中级-把核心概念真正串起来.md) | 建立正确心智模型 | 已经知道命令，但理解还发散的人 |
| [03-高级-config-schema-与项目边界.md](03-高级-config-schema-与项目边界.md) | 看清配置和结构边界 | 想定制或深入理解的人 |
| [04-高级-cline-里的-openspec-到底怎么落地.md](04-高级-cline-里的-openspec-到底怎么落地.md) | 看工具落地 | 想把 OpenSpec 放进 Cline 工作流的人 |
| [05-高级-openspec-的软件开发生命周期思想.md](05-高级-openspec-的软件开发生命周期思想.md) | 理解 OpenSpec 怎样看待软件开发生命周期 | 想真正吃透这套方法论的人 |
| [06-案例-从一个真实-change-走完整条主线.md](06-案例-从一个真实-change-走完整条主线.md) | 用一个完整案例把整条主线走通 | 想把抽象概念全部落地的人 |
| [07-案例-从零开始设计一个较复杂系统.md](07-案例-从零开始设计一个较复杂系统.md) | 看 greenfield 复杂系统怎样建立第一版正式基线 | 想理解从零构建时 OpenSpec 怎么切系统的人 |
| [08-高级-项目级全局约束到底放哪.md](08-高级-项目级全局约束到底放哪.md) | 专门判断目录/TDD/style/regression 等全局约束该落在哪层 | 想把项目级原则和能力规格彻底分开的人 |
| [09-高级-config-yaml-怎么写到真正好用.md](09-高级-config-yaml-怎么写到真正好用.md) | 专门讲 `config.yaml` 怎样从空配置写成强配置 | 想把项目级配置写出真实约束力的人 |
| [90-附录-给机器看的-agent-协议.md](90-附录-给机器看的-agent-协议.md) | 看机器执行机制 | 想研究底层 protocol 的人 |

---

## 这一版的组织原则

### 1. 先回答“我怎么用”

所以最前面先讲：

- OpenSpec 解决什么问题
- 平时只需要记哪几个命令
- 一个 change 是怎么从开始到结束的

### 2. 再回答“它到底在管理什么”

所以第二层才讲：

- `openspec/specs/` 是什么
- `openspec/changes/` 是什么
- artifact 和 delta spec 在整个系统里扮演什么角色

### 3. 最后才讲“为什么会这样设计”

所以 `schema`、`config.yaml`、Cline 集成、生命周期思想、agent protocol，都被压到后面。

这是故意的，不是遗漏。
