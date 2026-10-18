# 答案：怎么在 OpenSpec 下扩展 schema——实操指南

## 一句话

OpenSpec 的 schema 系统允许你定义自己的 artifact 种类、依赖关系和生成规则——不改一行源码。三种方式：**fork 内置 schema 改**（推荐）、**从零 init**、**手写 YAML + 模板**。本指南以 `agent-dev-driven` 为例走通全流程。

## 前置：三种扩法

| 方式 | 命令 | 适合 |
|------|------|------|
| **fork** | `openspec schema fork spec-driven my-name` | 内置 schema 基础上改（改 instruction、改 template）。落到 `openspec/schemas/my-name/`，跟代码一起版本控制。 |
| **init** | `openspec schema init my-name` | 从零建。脚手架自带 templates stub。 |
| **手写** | 直接创建 `openspec/schemas/my-name/schema.yaml` + `templates/*.md` | 完全掌控。 |

**fork 优先**——`agent-dev-driven` 就是 spec-driven 的 instruction 级 fork：artifact 名和 DAG 完全一样，改的只是 design 和 tasks 的 instruction 与 template（proposal 和 specs 几乎不动）。

> **fork 的对象是内置 `spec-driven`。** `agent-dev-driven` / `requirement-driven` 从来不是 OpenSpec 内置 schema（内置 `schemas/` 只有 `spec-driven`），所以对它们没有 "fork 内置" 一说——直接用本目录的 `schema-package/` 安装即可。

## 装在哪里——两个位置

| 位置 | 可见范围 | 什么时候用 |
|------|---------|-----------|
| `openspec/schemas/<name>/` | 当前项目 | 团队共享、跟代码版本控制——**推荐** |
| `~/.local/share/openspec/schemas/<name>/` | 当前用户所有项目 | 个人用、跨项目复用 |

## 装 agent-dev-driven

直接复制 schema-package：

```bash
cp -r schema-package/ openspec/schemas/agent-dev-driven/
```

校验：

```bash
openspec schema validate agent-dev-driven --verbose
# ✓ Schema 'agent-dev-driven' is valid
```

## 创建第一个 change 并走通 DAG

```bash
openspec new change build-my-agent --schema agent-dev-driven
```

DAG 和 spec-driven 完全一样：

```text
1. 写 proposal.md           → specs 和 design 同时解锁（两者并行）
2. 写 specs/*.md + design.md → 两个都就绪后 tasks 解锁
3. 写 tasks.md（勾 checkbox）→ apply 解锁
4. apply（构建 agent 组件 + 接入 harness + 端到端验证）
```

看每个 artifact 的完整 instruction：

```bash
openspec instructions proposal --change build-my-agent --json
openspec instructions specs --change build-my-agent --json
openspec instructions design --change build-my-agent --json
openspec instructions tasks --change build-my-agent --json
```

## 校验和调试

改 schema.yaml 后重校验：`openspec schema validate agent-dev-driven --verbose`

常见报错：

| 报错 | 原因 | 修法 |
|------|------|------|
| `Duplicate artifact ID: <id>` | 两个 artifact 同名 | 改其中一个 |
| `Invalid dependency reference in artifact '<id>': '<req>' does not exist` | requires 引用不存在 | 检查 id 拼写 |
| `Cyclic dependency detected` | requires 成环 | 画 DAG，砍一条边 |
| `Template file '<tpl>' not found for artifact '<id>'` | template 文件不存在 | 创建文件或改 template 字段 |

agent 实际收到的 prompt 用 `openspec instructions <artifact> --change <name> --json` 看——instruction + template + context + dependencies 全部拼在一起。

## 设为项目默认 vs per-change

项目默认——在 `openspec/config.yaml` 设 `schema: agent-dev-driven`。
per-change——`openspec new change <topic> --schema agent-dev-driven`。

解析优先级分两种场景，**不要混用**：

- **创建新 change**（`openspec new change`）：CLI `--schema` → `config.yaml` 的 `schema` 字段 → 硬编码 `spec-driven`。
- **解析已存在的 change**（`status` / `instructions` 等）：CLI `--schema` → change 的 `.openspec.yaml` → `config.yaml` 的 `schema` 字段 → 硬编码 `spec-driven`。

关键在于**创建时会把这个选择写进 `.openspec.yaml`**，实测：

```text
$ openspec new change zz --schema spec-driven
$ cat openspec/changes/zz/.openspec.yaml
schema: spec-driven
created: 2026-10-18
```

所以 `--schema my-driven` 建出来的 change 会**长期钉住** `my-driven`——之后即使改 `config.yaml` 的项目默认值，也不会迁移正在进行的 change。这也解释了为什么第二条阶梯里 `.openspec.yaml` 排在 `config.yaml` 前面。

## 迭代改 schema 后要做什么

改 schema.yaml 或 templates 后，已创建的 change **不需要重建**——每次 `openspec status` 或 `openspec instructions` 即时重读 schema.yaml，改完即生效。

## 守则

- **fork 优先、不改内置**。直接改 `node_modules` 里的 schema 会被覆盖。
- **每次改完先 `validate`**。schema.yaml 写错不像 config.yaml 那样 fail-open——硬错误会阻止指令生成。
- **`apply.tracks` 要精确等于某个 artifact 的 `generates`**。进度计数不认文件名，认的是这个映射：`task-progress.ts:106-112` 先取 `schema.apply.tracks`，再找 `generates` 等于它的 artifact（没设 tracks 时才回退到 id === `tasks`）。所以改名完全可行——只要 `apply.tracks` 同步改成新值。真正的坑是 **`tracks` 必须与 `generates` 字符串完全相等**，写成 glob 或目录永远匹配不上，那时才会退回按 `tasks.md` 计数并给 warning（`schema.ts:122-133`）。
- **artifact 名和 DAG 尽量对齐 spec-driven**。除非你的领域确实需要不同的 artifact 结构——否则只改 instruction 内容就够了。

---

> 本指南是 [`answer.md`](answer.md) 的实操伴侣——那里解释 agent-dev-driven **和 spec-driven 差在哪、为什么这样就够了**；这里是**怎么装上用起来**。
