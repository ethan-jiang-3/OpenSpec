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

→ 完整解释：[05-cli-reference/workflow-cli.md §0](05-cli-reference/workflow-cli.md#§0-openspec-怎么借用宿主-coding-agent-的-llm)

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
→ 详见 [02-commands/tool-specific-syntax.md](02-commands/tool-specific-syntax.md)

---

## 🗺️ 我想... 按意图导航

不必从头读到尾。按你**当前最想解决的问题**直接跳：

### 入门 / 评估阶段

| 我想... | 去看 |
|---------|------|
| 用 5 分钟搞清楚 OpenSpec 是什么 | [01-opsx-overview/README.md](01-opsx-overview/README.md)（3 分钟）|
| 知道它跟以前那套有什么不同 | [01-opsx-overview/opsx-vs-legacy.md](01-opsx-overview/opsx-vs-legacy.md)（5 分钟）|
| 看核心几个命令是干啥的 | [02-commands/core-commands.md](02-commands/core-commands.md)（5 分钟）|
| 看一张总流程图 | [03-workflow-sequence/sequence-diagrams.md](03-workflow-sequence/sequence-diagrams.md)（3 分钟）|

### 安装 / 配置阶段（**新手常卡这里**）

| 我想... | 去看 |
|---------|------|
| 知道支持我哪个 AI 工具 | [04-supported-tools/README.md](04-supported-tools/README.md) |
| 担心装了会不会污染 / 自动跑出来 | [FAQ Q3](FAQ.md#q3-装上-openspec-之后ai-会不会平时就主动跳出来烦我) + [04 §3](04-supported-tools/installation-paths.md#3-安装的副作用与触发模型) |
| 只想给一个项目装，别影响其它项目 | [FAQ Q4](FAQ.md#q4-我有些项目要-openspec有些不要能完全隔离吗) + [05 setup §3](05-cli-reference/setup.md#3-单项目隔离--只让-openspec-影响一个项目其它项目完全不动) |
| 在 CI 里自动 init | [05-cli-reference/setup.md](05-cli-reference/setup.md) |
| 不想要全部命令，只装核心 4 个 | [03-workflow-sequence/README.md](03-workflow-sequence/README.md)（profile 切换）|

### 日常使用阶段

| 我想... | 去看 |
|---------|------|
| 知道每个 `/opsx:*` 命令做什么 | [02-commands/core-commands.md](02-commands/core-commands.md) + [expanded-commands.md](02-commands/expanded-commands.md) |
| `ff` 和 `continue` 该用哪个 | [03-workflow-sequence/when-to-use-what.md](03-workflow-sequence/when-to-use-what.md) |
| 写 delta spec（修改已有规格）的语法 | [06-schemas-and-artifacts/delta-spec-format.md](06-schemas-and-artifacts/delta-spec-format.md) |
| 看进度 / 状态 | [05-cli-reference/browsing-and-validation.md](05-cli-reference/browsing-and-validation.md) |
| AI 生成的不对怎么调 | [FAQ Q12](FAQ.md#q12-opsxpropose-之后-ai-卡住或生成的不对怎么办) |

### 定制 / 集成阶段

| 我想... | 去看 |
|---------|------|
| 搞懂 schema 到底是什么 | [FAQ Q6](FAQ.md#q6-schema-是什么为啥-openspec-要引入这个词) + [05 schema-cli §0](05-cli-reference/schema-cli.md#§0-openspec-里的-schema-到底是什么) |
| 自己写一份工作流 schema | [07-customization/custom-schemas.md](07-customization/custom-schemas.md) |
| 给团队定制项目级配置（context / rules）| [07-customization/project-config.md](07-customization/project-config.md) |
| 把 OpenSpec 接入自己的 LLM pipeline | [05 workflow-cli §0](05-cli-reference/workflow-cli.md#§0-openspec-怎么借用宿主-coding-agent-的-llm) |
| 加一个新 agent 适配器 | [08-architecture/extension-points.md](08-architecture/extension-points.md) |
| 看源码地图 | [08-architecture/source-map.md](08-architecture/source-map.md) |

### 排查 / 卸载阶段

| 我想... | 去看 |
|---------|------|
| 某个命令在我这工具叫啥 | [02-commands/tool-specific-syntax.md](02-commands/tool-specific-syntax.md) |
| 调试 schema 解析优先级 | [07-customization/schema-resolution-order.md](07-customization/schema-resolution-order.md) |
| 完全卸载 OpenSpec | [FAQ Q13](FAQ.md#q13-我能不能完全卸载-openspec) |
| 验证我的 change 文件夹合不合法 | `openspec validate` → [05 browsing-and-validation](05-cli-reference/browsing-and-validation.md) |

---

## 📚 完整文件地图（带阅读时长）

阅读时长按 ~30 行/分钟估算。⭐ = 强烈推荐先读。

### 🟢 入门必读（共 ~12 分钟）

| 文件 | 行数 | 时长 | 内容 |
|------|------|------|------|
| ⭐ [FAQ.md](FAQ.md) | 250 | 8 min | **13 个最常困惑的 Q&A**——新人必读 |
| ⭐ [01-opsx-overview/README.md](01-opsx-overview/README.md) | 60 | 2 min | OPSX 是什么 + 四条哲学 |
| [01-opsx-overview/opsx-vs-legacy.md](01-opsx-overview/opsx-vs-legacy.md) | 80 | 3 min | 新旧对比 + 流程图 |

### 🟢 命令与工作流（共 ~25 分钟）

| 文件 | 行数 | 时长 | 内容 |
|------|------|------|------|
| ⭐ [02-commands/core-commands.md](02-commands/core-commands.md) | 110 | 4 min | 4 个核心命令 |
| [02-commands/expanded-commands.md](02-commands/expanded-commands.md) | 170 | 6 min | 7 个扩展命令 |
| [02-commands/tool-specific-syntax.md](02-commands/tool-specific-syntax.md) | 350 | 12 min | 跨工具语法差异（**含 Trae/Cline/OpenCode 深挖**）|
| [02-commands/command-to-skill-map.md](02-commands/command-to-skill-map.md) | 60 | 2 min | command ↔ skill 映射表 |
| [03-workflow-sequence/README.md](03-workflow-sequence/README.md) | 50 | 2 min | core / custom profile |
| [03-workflow-sequence/sequence-diagrams.md](03-workflow-sequence/sequence-diagrams.md) | 110 | 4 min | 5 张 mermaid 流程图 |
| [03-workflow-sequence/when-to-use-what.md](03-workflow-sequence/when-to-use-what.md) | 100 | 3 min | 决策树 |

### 🟡 工具适配（按需）

| 文件 | 行数 | 时长 | 内容 |
|------|------|------|------|
| [04-supported-tools/README.md](04-supported-tools/README.md) | 60 | 2 min | 28 个 agent 总表 |
| ⭐ [04-supported-tools/installation-paths.md](04-supported-tools/installation-paths.md) | 250 | 8 min | 路径表 + **§3 副作用与触发模型** |
| [04-supported-tools/tool-ids.md](04-supported-tools/tool-ids.md) | 80 | 3 min | `--tools` 可用 ID（CI 用）|

### 🟡 CLI 手册（查阅型）

| 文件 | 行数 | 时长 | 内容 |
|------|------|------|------|
| ⭐ [05-cli-reference/setup.md](05-cli-reference/setup.md) | 250 | 8 min | `init` / `update` + **§3 单项目隔离** |
| [05-cli-reference/browsing-and-validation.md](05-cli-reference/browsing-and-validation.md) | 140 | 5 min | `list` / `view` / `show` / `validate` |
| ⭐ [05-cli-reference/workflow-cli.md](05-cli-reference/workflow-cli.md) | 290 | 10 min | **§0 OpenSpec 如何借用 LLM** + agent 用的 4 个命令 |
| ⭐ [05-cli-reference/schema-cli.md](05-cli-reference/schema-cli.md) | 330 | 11 min | **§0 schema 是什么** + `schema init/fork/validate/which` |
| [05-cli-reference/config-cli.md](05-cli-reference/config-cli.md) | 90 | 3 min | `config profile` 等全局配置 |
| [05-cli-reference/misc.md](05-cli-reference/misc.md) | 100 | 4 min | `archive` / `feedback` / `completion` + 环境变量 |

### 🔵 概念深入（定制开发用）

| 文件 | 行数 | 时长 | 内容 |
|------|------|------|------|
| [06-schemas-and-artifacts/artifact-graph.md](06-schemas-and-artifacts/artifact-graph.md) | 110 | 4 min | DAG + 状态机（done / ready / blocked）|
| [06-schemas-and-artifacts/delta-spec-format.md](06-schemas-and-artifacts/delta-spec-format.md) | 100 | 4 min | ADDED / MODIFIED / REMOVED / RENAMED 语法 |
| [06-schemas-and-artifacts/spec-driven-schema.md](06-schemas-and-artifacts/spec-driven-schema.md) | 90 | 3 min | 内置 schema 全貌 |
| [06-schemas-and-artifacts/change-folder-layout.md](06-schemas-and-artifacts/change-folder-layout.md) | 90 | 3 min | change/ 目录约定 |
| [07-customization/project-config.md](07-customization/project-config.md) | 110 | 4 min | `openspec/config.yaml` 三个字段 |
| [07-customization/custom-schemas.md](07-customization/custom-schemas.md) | 220 | 7 min | 写自定义 schema 的三种模板 |
| [07-customization/schema-resolution-order.md](07-customization/schema-resolution-order.md) | 90 | 3 min | 两级四档解析优先级 |

### 🔵 架构与扩展

| 文件 | 行数 | 时长 | 内容 |
|------|------|------|------|
| [08-architecture/source-map.md](08-architecture/source-map.md) | 115 | 4 min | src/ 目录到职责映射 |
| [08-architecture/extension-points.md](08-architecture/extension-points.md) | 145 | 5 min | 加新 agent / workflow / schema 的方法 |

**总计**：~3800 行 / ~130 分钟。**全部读完不必要**。按上面的"按意图导航"挑着读才合理。

---

## 🎯 三条推荐路径

### 路径 A：纯使用者（30 分钟）

只想用，不想知道内部：

```
FAQ.md  →  01 README  →  02 core-commands  →  03 sequence-diagrams
        ↓
   遇到问题再回 FAQ 查
```

### 路径 B：评估 + 决策装不装（25 分钟）

要给团队/项目决策的人：

```
FAQ.md
  ↓
01 README + opsx-vs-legacy
  ↓
04 installation-paths §3 (副作用)
  ↓
05 setup §3 (单项目隔离)
```

### 路径 C：定制 / 集成开发者（90 分钟）

要做 schema 定制 / 加 agent / 接 LLM pipeline：

```
01 README → FAQ Q1+Q6+Q10
  ↓
05 workflow-cli §0 (协议)
05 schema-cli §0 (schema 概念)
  ↓
06 整个目录
07 整个目录
  ↓
08 source-map + extension-points
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
