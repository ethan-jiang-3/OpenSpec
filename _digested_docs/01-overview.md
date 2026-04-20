# 01 · OPSX 总览

> 回 [导读](00-index.md) · [FAQ](FAQ.md)

## 目录

- [§1 OPSX 是什么](#1-opsx-是什么)
- [§2 四条核心哲学](#2-四条核心哲学)
- [§3 为什么要造 OPSX（legacy 的痛点）](#3-为什么要造-opsx-legacy-的痛点)
- [§4 关键转变：从「phase」到「action」](#4-关键转变从-phase-到-action)
- [§5 OPSX vs Legacy 对比](#5-opsx-vs-legacy-对比)
- [§6 Agent 获取上下文的差异](#6-agent-获取上下文的差异)
- [§7 Legacy 还能不能用](#7-legacy-还能不能用)

---

## §1 OPSX 是什么

**OPSX 是 OpenSpec v1 的新一代指令集和工作流模型**，从 2025 年起取代了旧的 `/openspec:*` 指令（legacy）。名字含义：**OPS（OpenSpec）+ X**（eXtended/eXperimental）。

它解决的是一个具体问题：让「人类 + AI 编程助手」能在**任何时刻**就任一个 artifact（提案、规格、设计、任务）达成一致，而不必走死板的「先全部规划 → 再全部实现 → 再归档」流水线。

---

## §2 四条核心哲学

来自 [README.md](../README.md) 和 [docs/concepts.md](../docs/concepts.md)：

```
→ fluid not rigid          （流动，不僵化）
→ iterative not waterfall   （迭代，非瀑布）
→ easy not complex          （简单，不复杂）
→ brownfield-first          （为老代码库设计，而非只为 greenfield）
```

落地表达：

- **fluid**——命令是「动作」，不是「阶段」；任何时候都能回头改 proposal、加 scenario、调 design
- **iterative**——在实现中发现设计错了？直接改 `design.md`，然后 `/opsx:apply` 继续跑
- **easy**——`npm i -g @fission-ai/openspec && openspec init`，秒级就绪；不写 YAML 也能跑
- **brownfield-first**——用 **delta spec**（ADDED / MODIFIED / REMOVED / RENAMED）描述改动，而不是每次重写整份规格

---

## §3 为什么要造 OPSX（legacy 的痛点）

[docs/opsx.md](../docs/opsx.md) 里说得很直白，legacy 有四个问题：

1. **Instructions are hardcoded** —— 模板写死在 TypeScript 源码里，用户改不了
2. **All-or-nothing** —— 一个命令把 proposal / specs / design / tasks 全部一次性生成
3. **Fixed structure** —— 所有项目同一套工作流，不能按团队习惯定制
4. **Black box** —— AI 输出不好时，没法调提示词（因为提示词是源码）

OPSX 的解决方案是把三样东西**外置化**：

| 外置的东西 | 放在哪 | 带来什么 |
|-----------|--------|----------|
| 工作流定义 | `schema.yaml`（DAG） | 用户能自定义 artifact 和依赖 |
| 模板内容 | `templates/*.md` | 用户能直接改模板、立即生效 |
| 工具适配 | `src/core/command-generation/adapters/` | 每个 coding agent 一个独立 adapter |

---

## §4 关键转变：从「phase」到「action」

```
legacy（阶段锁）：
  PLANNING → IMPLEMENTING → ARCHIVING   （反向回不去）

OPSX（动作流）：
  proposal ⇄ specs ⇄ design ⇄ tasks ⇄ implement
             任何顺序、任何时刻、反复迭代
```

**关键洞察**：依赖是 **enabler**（使能者），不是 **gate**（阀门）——DAG 里的 `requires` 字段告诉你「可以做什么了」，而不是「必须先做什么才能继续」。

---

## §5 OPSX vs Legacy 对比

### 总对比表

| 维度 | Legacy（`/openspec:*`） | OPSX（`/opsx:*`） |
|------|------------------------|-------------------|
| **工作流模型** | 阶段锁（planning → implementing → archiving） | 动作流（任意顺序、任意时刻） |
| **生成粒度** | 一次性生成所有 artifact | 按依赖图增量生成，单个 artifact 也可 |
| **模板** | 硬编码在 TypeScript 源码 | 外部 YAML + Markdown（用户可编辑） |
| **依赖建模** | 无（靠阶段隐式表达） | 显式 DAG（`requires` 字段） |
| **状态判定** | 凭「阶段」记号 | 凭文件系统是否存在对应产物 |
| **编辑器支持** | 每个工具一个配置器 | 统一 skill 目录 + 可选 command 适配 |
| **可迭代性** | 回头修改很尴尬 | 改文件即可，命令自然续上 |
| **自定义 schema** | 不支持 | `openspec schema init` / `schema fork` |
| **AI 获取上下文方式** | 静态指令文本 | `openspec status --json` + `openspec instructions --json` 查询 CLI |

### Legacy 流程

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│  PLANNING  │ ──► │IMPLEMENTING│ ──► │ ARCHIVING  │
└────────────┘     └────────────┘     └────────────┘
       │                 │                  │
       ▼                 ▼                  ▼
 /openspec:    /openspec:apply      /openspec:archive
   proposal

• Creates ALL artifacts at once
• 发现设计错了？没有官方的回退路径
• 只能手动改文件（会断上下文）、放弃重来、或硬着头皮改
```

### OPSX 流程

```
  /opsx:new ──► /opsx:continue ──► /opsx:apply ──► /opsx:archive
      │               │                 │
      │               │                 ├── 「设计不对？」直接改 design.md
      │               │                 │
      │               │                 └── /opsx:apply 自动接着跑
      │               │
      │               └── 一次只建一个 artifact，显示「下一步解锁了什么」
      │
      └── 只搭骨架（scaffold），等你决定方向
```

---

## §6 Agent 获取上下文的差异

### Legacy：静态指令

agent 收到的是写死的字符串：「请创建 proposal.md、tasks.md、design.md、specs/<capability>/spec.md」。agent 不知道当前有什么文件、artifact 之间如何依赖。

### OPSX：查询 CLI 拿到结构化上下文

agent 先调 `openspec status --change <name> --json` 拿到：

```json
{
  "artifacts": [
    {"id": "proposal", "status": "done"},
    {"id": "specs",    "status": "ready"},
    {"id": "design",   "status": "ready"},
    {"id": "tasks",    "status": "blocked", "missingDeps": ["specs"]}
  ]
}
```

再调 `openspec instructions specs --change <name> --json` 拿到对应 artifact 的模板、项目 context、前置依赖文件内容、规则——全部打包好给 AI。

详细的 agent ↔ CLI 协议见 [06-agent-protocol.md](06-agent-protocol.md)。

---

## §7 Legacy 还能不能用

可以。`/openspec:proposal` / `/openspec:apply` / `/openspec:archive` 都保留着，适用场景（来自 [docs/commands.md](../docs/commands.md)）：

- 既有项目还在用旧工作流
- 简单改动不需要逐个 artifact 生成
- 偏好一次性生成

**但新项目一律推荐 OPSX**，README 首推的命令就是 `/opsx:propose`。
