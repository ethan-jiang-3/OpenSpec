# 01 · OPSX 概览

## OPSX 是什么

**OPSX 是 OpenSpec v1 的新一代指令集和工作流模型**，从 2025 年起取代了旧的 `/openspec:*` 指令（legacy）。名字含义：**OPS（OpenSpec）+ X**（eXtended/eXperimental）。

它解决的是一个具体问题：让「人类 + AI 编程助手」能在**任何时刻**就任一个 artifact（提案、规格、设计、任务）达成一致，而不必走死板的「先全部规划 → 再全部实现 → 再归档」流水线。

## 四条核心哲学

来自 [README.md](../../README.md) 和 [docs/concepts.md](../../docs/concepts.md)：

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

## 为什么要造 OPSX（legacy 的痛点）

[docs/opsx.md](../../docs/opsx.md) 里说得很直白，legacy 有四个问题：

1. **Instructions are hardcoded** —— 模板写死在 TypeScript 源码里，用户改不了
2. **All-or-nothing** —— 一个命令把 proposal / specs / design / tasks 全部一次性生成
3. **Fixed structure** —— 所有项目同一套工作流，不能按团队习惯定制
4. **Black box** —— AI 输出不好时，没法调提示词（因为提示词是源码）

OPSX 的解决方案是把三样东西外置化：

| 外置的东西 | 放在哪 | 带来什么 |
|-----------|--------|----------|
| 工作流定义 | `schema.yaml`（DAG） | 用户能自定义 artifact 和依赖 |
| 模板内容 | `templates/*.md` | 用户能直接改模板、立即生效 |
| 工具适配 | `src/core/command-generation/adapters/` | 每个 coding agent 一个独立 adapter |

## 关键转变：从「phase」到「action」

```
legacy（阶段锁）：
  PLANNING → IMPLEMENTING → ARCHIVING   （反向回不去）

OPSX（动作流）：
  proposal ⇄ specs ⇄ design ⇄ tasks ⇄ implement
             任何顺序、任何时刻、反复迭代
```

**关键洞察**：依赖是 **enabler**（使能者），不是 **gate**（阀门）——DAG 里的 `requires` 字段告诉你「可以做什么了」，而不是「必须先做什么才能继续」。

## 本目录还有什么

- [opsx-vs-legacy.md](opsx-vs-legacy.md) — 新旧对比详表 + 两个流程图
