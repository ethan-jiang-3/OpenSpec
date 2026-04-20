# OpenSpec 消化笔记 · 总导读

> 本目录是对 OpenSpec（[`README.md`](../README.md)）项目的中文消化笔记，**不是搬运**。
> 仓库版本 **v1.3.0**（[package.json](../package.json)），运行要求 **Node.js ≥ 20.19.0**。

---

## ⚡ 30 秒画像

**OpenSpec 是给 AI 编程助手用的"协作层"**——人和 AI 在写代码之前先就"要做什么"达成一致。

它本身**不带 LLM**，是个**纯文件 + JSON API** 的 CLI；真正的"智能"借用你装的 Claude / Cursor / Cline 等 28 个 coding agent 之一。一次完整的 `/opsx:propose` 调用是这样的握手：

```text
用户                Coding Agent (含 LLM)         OpenSpec CLI
 │                       │                              │
 │── /opsx:propose ─────▶│                              │
 │                       │── 读 .commands/*.md ─────────│
 │                       │                              │
 │                       │── openspec status --json ───▶│
 │                       │◀──── 状态/schema ────────────│
 │                       │                              │
 │                       │── openspec instructions ────▶│
 │                       │◀── template+context+rules ───│
 │                       │                              │
 │                  [喂给自己的 LLM]                     │
 │                       │                              │
 │                       │── 写文件 ───────────────────▶│ openspec/changes/.../
 │◀── 完成 ──────────────│                              │
```

→ 完整解释：[06-agent-protocol.md §0](06-agent-protocol.md#0-openspec-怎么借用宿主-coding-agent-的-llm)

---

## 🚀 3 分钟跑通一次

```bash
# 1. 装 CLI
npm install -g @fission-ai/openspec@latest      # 或 npx @fission-ai/openspec init

# 2. 在项目里初始化（会弹多选框选你用的 AI 工具）
cd my-project
openspec init

# 3. 在你的 AI agent 里键入（以 Claude 为例）
/opsx:propose add-dark-mode

# 4. 跟 agent 来回几轮，直到 proposal/specs/design/tasks 都创建好

# 5. 实施
/opsx:apply add-dark-mode

# 6. 完成后归档（merge delta specs 到主 specs）
/opsx:archive add-dark-mode
```

**不同 agent 命令前缀不同**：Claude 用 `/opsx:`，Cursor/Cline/OpenCode 用 `/opsx-`，Trae 用 `/openspec-`。
→ 详见 [05-usage-advanced.md §4](05-usage-advanced.md#4-openspec--vs-opsx--前缀之辨)

---

## 🗺️ 我想... 按意图导航

不必从头读到尾。按你**当前最想解决的问题**直接跳：

### 入门 / 评估阶段

| 我想... | 去看 |
|---------|------|
| 用 5 分钟搞清楚 OpenSpec 是什么 | [01-overview.md](01-overview.md)（3 分钟） |
| 知道它跟以前那套有什么不同 | [01-overview.md §5](01-overview.md#5-opsx-vs-legacy-对比)（5 分钟） |
| 看核心几个命令是干啥的 | [04-usage-basic.md §2](04-usage-basic.md#2-core-四个斜杠命令)（5 分钟） |
| 看一张总流程图 | [04-usage-basic.md §3](04-usage-basic.md#3-命令次序流程图)（3 分钟） |

### 安装 / 配置阶段（**新手常卡这里**）

| 我想... | 去看 |
|---------|------|
| 知道支持我哪个 AI 工具 | [02-installation.md §4](02-installation.md#4-28-个支持的工具总表) |
| 担心装了会不会污染 / 自动跑出来 | [FAQ Q3](FAQ.md#q3-装上-openspec-之后ai-会不会平时就主动跳出来烦我) + [02 §7](02-installation.md#7-安装的副作用与触发模型) |
| 只想给一个项目装，别影响其它项目 | [FAQ Q4](FAQ.md#q4-我有些项目要-openspec有些不要能完全隔离吗) + [02 §3](02-installation.md#3-单项目隔离) |
| 在 CI 里自动 init | [02-installation.md §5](02-installation.md#5---tools-id-清单ci-用) |
| 不想要全部命令，只装核心 4 个 | [04-usage-basic.md §1](04-usage-basic.md#1-profile-简介)（profile 切换） |

### 日常使用阶段

| 我想... | 去看 |
|---------|------|
| 知道每个 `/opsx:*` 命令做什么 | [04-usage-basic.md §2](04-usage-basic.md#2-core-四个斜杠命令) + [05-usage-advanced.md §1](05-usage-advanced.md#1-expanded-7-个扩展命令) |
| `ff` 和 `continue` 该用哪个 | [04-usage-basic.md §4](04-usage-basic.md#4-决策树什么时候用什么) |
| 写 delta spec（修改已有规格）的语法 | [03-concepts.md §2](03-concepts.md#2-delta-spec-格式) |
| 看进度 / 状态 | [04-usage-basic.md §5](04-usage-basic.md#5-浏览-cli-list--view--show) |
| AI 生成的不对怎么调 | [FAQ Q12](FAQ.md#q12-opsxpropose-之后-ai-卡住或生成的不对怎么办) |

### 定制 / 集成阶段

| 我想... | 去看 |
|---------|------|
| 搞懂 schema 到底是什么 | [FAQ Q6](FAQ.md#q6-schema-是什么为啥-openspec-要引入这个词) + [03-concepts.md §3](03-concepts.md#3-schema-是什么为什么这么叫) |
| 自己写一份工作流 schema | [07-customization.md §2](07-customization.md#2-自定义-schema) |
| 给团队定制项目级配置（context / rules） | [07-customization.md §1](07-customization.md#1-项目-config-openspecconfigyaml) |
| 把 OpenSpec 接入自己的 LLM pipeline | [06-agent-protocol.md §0](06-agent-protocol.md#0-openspec-怎么借用宿主-coding-agent-的-llm) |
| 加一个新 agent 适配器 | [08-architecture.md §2](08-architecture.md#2-扩展点想改加东西时看哪里) |
| 看源码地图 | [08-architecture.md §1](08-architecture.md#1-源码地图) |

### 排查 / 卸载阶段

| 我想... | 去看 |
|---------|------|
| 某个命令在我这工具叫啥 | [05-usage-advanced.md](05-usage-advanced.md) |
| 调试 schema 解析优先级 | [07-customization.md §3](07-customization.md#3-schema-解析优先级) |
| 完全卸载 OpenSpec | [FAQ Q13](FAQ.md#q13-我能不能完全卸载-openspec) |
| 验证我的 change 文件夹合不合法 | `openspec validate` → [04-usage-basic.md §6](04-usage-basic.md#6-校验-cli-validate) |

---

## 📚 完整文件地图（平铺结构，10 个文件）

⭐ = 强烈推荐先读。阅读时长按 ~60 行/分钟估算。

| 文件 | 内容摘要 | 时长 |
|------|---------|------|
| ⭐ **[00-index.md](00-index.md)** | 本文件，总导读 | 3 min |
| ⭐ **[FAQ.md](FAQ.md)** | 13 个最常困惑的 Q&A——新人必读 | 8 min |
| ⭐ **[01-overview.md](01-overview.md)** | OPSX 是什么 + 四条哲学 + vs legacy 对比 | 5 min |
| ⭐ **[02-installation.md](02-installation.md)** | `init` / `update` + 28 工具总表 + 路径 + 副作用 + 项目隔离 | 15 min |
| **[03-concepts.md](03-concepts.md)** | artifact DAG + delta spec 格式 + schema 概念 + spec-driven + change 目录 | 12 min |
| ⭐ **[04-usage-basic.md](04-usage-basic.md)** | core 4 命令 + 流程图 + 决策树 + 浏览/校验/archive CLI | 14 min |
| **[05-usage-advanced.md](05-usage-advanced.md)** | expanded 7 命令 + openspec- vs opsx- + Trae/Cline/OpenCode 深挖 | 12 min |
| ⭐ **[06-agent-protocol.md](06-agent-protocol.md)** | **§0 OpenSpec 如何借用 LLM** + agent 用的 4 个 CLI | 10 min |
| **[07-customization.md](07-customization.md)** | project config + 自定义 schema + 解析优先级 + schema/config CLI | 15 min |
| **[08-architecture.md](08-architecture.md)** | 源码地图 + 7 个扩展点 | 8 min |

**总计**：~100 分钟。**全部读完不必要**。按上面的"按意图导航"挑着读才合理。

---

## 🎯 三条推荐路径

### 路径 A：纯使用者（25 分钟）

只想用，不想知道内部：

```
FAQ.md  →  01-overview.md  →  04-usage-basic.md
        ↓
   遇到问题再回 FAQ 查
```

### 路径 B：评估 + 决策装不装（25 分钟）

要给团队/项目决策的人：

```
FAQ.md
  ↓
01-overview.md
  ↓
02-installation.md §7 (副作用)
  ↓
02-installation.md §3 (单项目隔离)
```

### 路径 C：定制 / 集成开发者（80 分钟）

要做 schema 定制 / 加 agent / 接 LLM pipeline：

```
01-overview.md → FAQ Q1+Q6+Q10
  ↓
06-agent-protocol.md §0 (协议)
03-concepts.md §3 (schema 概念)
  ↓
03-concepts.md（artifact / delta / schema）
07-customization.md（全文）
  ↓
08-architecture.md（源码地图 + 扩展点）
```

---

## 🔑 关键数字（吹牛聊天用）

- **28** 个 coding agent 适配器（[`src/core/config.ts`](../src/core/config.ts) 的 `AI_TOOLS`）
- **11** 个 `/opsx:*` 斜杠命令（4 core + 7 expanded）
- **4** 种内置 artifact（proposal / specs / design / tasks）
- **1** 个内置 schema（`spec-driven`），其余靠 fork / init
- **0** 个 LLM API 调用（OpenSpec 自己不带模型）
- **0** 个 git hook / daemon / IDE 插件（纯文件 CLI）

---

## 🆚 与官方文档的关系

本目录是**消化版中文笔记**，按"困惑驱动"组织、补了大量本地源码佐证。
官方原文在 [`docs/`](../docs/)，重点：

- [docs/opsx.md](../docs/opsx.md) — OPSX 完整定义
- [docs/supported-tools.md](../docs/supported-tools.md) — 工具清单
- [docs/commands.md](../docs/commands.md) — 命令参考
- [docs/cli.md](../docs/cli.md) — CLI 参考
- [docs/concepts.md](../docs/concepts.md) — 核心概念
- [docs/customization.md](../docs/customization.md) — 定制指南

> 笔记跟官方文档可能有微小出入（笔记会指出，并以源码为准）。看不懂笔记的地方，回查官方原文 + 给出的源码行号链接是最快的。
