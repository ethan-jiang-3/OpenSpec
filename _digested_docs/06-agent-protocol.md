# 06 · Agent Protocol（CLI 给 AI 用）

> 回 [导读](00-index.md) · [FAQ](FAQ.md)

这四个命令是 **OPSX 的核心骨架**——AI agent 在执行 `/opsx:*` 命令时会调它们拿结构化数据。人类也能用它们检查进度。

实现在 [src/commands/workflow/](../src/commands/workflow/)。

## 目录

- [§0 OpenSpec 怎么"借用"宿主 coding agent 的 LLM](#0-openspec-怎么借用宿主-coding-agent-的-llm)
- [§1 `openspec status`](#1-openspec-status)
- [§2 `openspec instructions`](#2-openspec-instructions)
- [§3 `openspec templates`](#3-openspec-templates)
- [§4 `openspec schemas`](#4-openspec-schemas)

---

## §0 OpenSpec 怎么"借用"宿主 coding agent 的 LLM

> 关键事实：**OpenSpec CLI 自己不带 LLM、不调 OpenAI/Anthropic API、不发任何网络请求**。grep 整个 src/ 目录搜 `openai|anthropic|claude.*api|llm` 零结果。

那它是怎么做"AI 编程"的？答：**它是个 prompt 编排器 + 结构化数据 API**，真正的智能来自宿主 coding agent（Claude Code / Cursor / Cline / ...）里的 LLM。

### 三方角色

```text
┌─────────────────┐   ┌──────────────────────┐   ┌────────────────┐
│  用户            │←─→│  Coding Agent        │←─→│  OpenSpec CLI   │
│  (键入命令)      │   │  (Claude Code/        │   │  (纯文件操作 +  │
│                  │   │   Cursor/...)         │   │   JSON API)     │
│                  │   │  ┌─────────────────┐  │   │                 │
│                  │   │  │   LLM（智能源）  │  │   │   ┌──────────┐ │
│                  │   │  │   Claude/GPT/... │  │   │   │ 文件系统  │ │
│                  │   │  └─────────────────┘  │   │   │ 模板/状态  │ │
└─────────────────┘   └──────────────────────┘   │   └──────────┘ │
                                                  └────────────────┘
```

- **OpenSpec 只做**：读写文件、解析 schema、组装 prompt 上下文（模板 + project context + rules + 依赖 artifact 内容）、计算 artifact 状态
- **Agent 做**：解析用户意图、读 OpenSpec 输出的 JSON、把 JSON 交给自己的 LLM 推理、生成 artifact、再调 OpenSpec CLI 写文件
- **LLM 做**：所有"创造性"的工作——写 proposal、设计 specs、列 tasks、实现代码

### 完整握手流程（以 `/opsx:propose add-dark-mode` 为例）

```text
[1] 用户 → Claude Code: 输入 "/opsx:propose add-dark-mode"

[2] Claude Code → 文件系统: 读 .claude/commands/opsx/propose.md
    （这就是 OpenSpec init 时铺好的 prompt 模板）

[3] Claude Code: 把 propose.md 的内容当成"我接下来要做什么"的指令
    模板告诉它："先调 openspec status --json 看状态，然后调
    openspec instructions <artifact> --json 拿模板和上下文，
    然后用你的 LLM 生成 artifact 内容，再写到指定路径"

[4] Claude Code → Shell: 执行 `openspec status --change add-dark-mode --json`
    OpenSpec 返回:
    {
      "schemaName": "spec-driven",
      "artifacts": [
        {"id":"proposal","status":"ready"},
        {"id":"specs","status":"blocked","missingDeps":["proposal"]},
        ...
      ]
    }

[5] Claude Code → Shell: 执行 `openspec instructions proposal --change add-dark-mode --json`
    OpenSpec 返回:
    {
      "artifactId": "proposal",
      "outputPath": "openspec/changes/add-dark-mode/proposal.md",
      "instruction": "Create a proposal that explains...",  ← schema 定义的 AI 指令
      "template": "## Why\n...\n## What Changes\n...",      ← 模板原文
      "context": "<context>This project uses React + ...</context>",  ← 项目背景
      "rules": "<rules>Use Conventional Commits...</rules>",          ← 规则
      "dependencies": []                                              ← 已有 artifact 的内容
    }

[6] Claude Code → 自己的 LLM: 把上面这些拼成一个大 prompt 喂给 Claude:
    "你是 OpenSpec 助手。任务: <instruction>
     用这个模板: <template>
     项目背景: <context>
     规则: <rules>
     已有依赖: <dependencies>
     用户的需求: add-dark-mode
     生成 proposal.md 的内容。"

[7] LLM 返回生成的 proposal.md 内容

[8] Claude Code → 文件系统: 把内容写到 openspec/changes/add-dark-mode/proposal.md

[9] Claude Code → 用户: 显示成功 + 提示下一步 (/opsx:apply 或 /opsx:continue)
```

**OpenSpec 全程只在 Step 4、5、8 出现**——**纯 IO，零推理**。

### 为什么这种设计聪明

1. **零 API key、零网络依赖**：OpenSpec 装机即用，不要 OPENAI_API_KEY、不要登录
2. **模型无关**：Claude Code 用 Claude、Cursor 用 Cursor 自家 LLM、Codex 用 GPT 都行——OpenSpec 不在意
3. **成本结构清晰**：所有 token 消费走宿主 agent 的账户，OpenSpec 不偷偷烧钱
4. **离线可调试**：你可以手动跑 `openspec instructions proposal --json` 看 agent 会拿到什么 prompt，方便排查
5. **每个 agent 用自己最擅长的方式**：Claude 用 skills 自动加载、Cursor 用斜杠命令、Trae 用 skill 面板——同一套 OpenSpec CLI 适配 28 个 agent

### Skill / Command 文件本质上是什么

它们是 **OpenSpec 出版给 LLM 看的"使用手册"**：
- 用人话告诉 LLM"OpenSpec 是什么、有哪些命令、协议是什么"
- 一步步指导 LLM"调哪个命令、解析哪个字段、什么时候写文件"

源码佐证 ([src/core/templates/workflows/apply-change.ts](../src/core/templates/workflows/apply-change.ts) 节选)：

```text
2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - Which artifact contains the tasks ...

3. **Get apply instructions**
   ```bash
   openspec instructions apply --change "<name>" --json
   ```
   This returns:
   - `contextFiles`: artifact ID -> array of concrete file paths
   - Progress (total, complete, remaining)
   ...
```

**这段就是直接写给 LLM 看的、放在斜杠命令文件里**。LLM 读到后照着做。

### 跟以前 legacy "硬编码 prompt" 的区别

| 维度 | Legacy | OPSX (现在) |
|------|--------|-------------|
| Prompt 来自 | 源码里写死的字符串 | CLI 实时返回（`openspec instructions --json`） |
| 项目特定上下文 | 靠 LLM "自己读 project.md" | CLI 主动注入到 `<context>` 标签 |
| 依赖 artifact 内容 | LLM 自己 grep | CLI 在 JSON 里直接给完整内容 |
| 升级 OpenSpec | 要重新生成所有 prompt 文件 | 升级 CLI 即可，模板/逻辑都在 CLI 里 |

### 一句话总结

> **OpenSpec = 文件 + 模板 + 状态机 + JSON API**。所有 LLM 推理都由宿主 agent 执行；OpenSpec 只负责把"该怎么提示 LLM"这件事**结构化、可重放、可定制**。

### 推论

- 没装 coding agent → OpenSpec **只能**用来手动管理 specs/changes 目录（也能跑 `validate`、`list`、`show` 这些）
- 你完全可以**绕开 agent**，自己手写 artifact 文件然后用 `openspec validate` 校验——OpenSpec 不强求 AI 参与
- 想把 OpenSpec 接到自己的 LLM pipeline？读 `openspec instructions <id> --json` 拿到结构化 prompt → 自己调 OpenAI → 把返回写到 `outputPath` 即可

下面四个命令就是"agent 用来跟 OpenSpec 对话的 RPC 接口"。

---

## §1 `openspec status`

显示某个 change 的 artifact 完成状态。

```
openspec status [--change <id>] [--schema <name>] [--json]
```

### 示例

```bash
# 交互式
openspec status

# 指定 change
openspec status --change add-dark-mode

# JSON 给 agent 用
openspec status --change add-dark-mode --json
```

### JSON 输出

```json
{
  "changeName": "add-dark-mode",
  "schemaName": "spec-driven",
  "isComplete": false,
  "applyRequires": ["tasks"],
  "artifacts": [
    {"id": "proposal", "outputPath": "proposal.md",    "status": "done"},
    {"id": "design",   "outputPath": "design.md",      "status": "ready"},
    {"id": "specs",    "outputPath": "specs/**/*.md",  "status": "done"},
    {"id": "tasks",    "outputPath": "tasks.md",
     "status": "blocked", "missingDeps": ["design"]}
  ]
}
```

状态的三种值来自 [src/core/artifact-graph/state.ts](../src/core/artifact-graph/state.ts)：`done` / `ready` / `blocked`。

---

## §2 `openspec instructions`

拿到创建某个 artifact 或 apply 阶段的**富上下文指令**。agent 主要靠这个命令拼提示词。

```
openspec instructions [artifact] [--change <id>] [--schema <name>] [--json]
```

### artifact 参数

- `proposal`、`specs`、`design`、`tasks`（`spec-driven` schema 的）
- `apply`（特殊值：拿 apply 阶段的指令）

### 示例

```bash
# 下一个可建的 artifact 的指令
openspec instructions --change add-dark-mode

# 指定 artifact
openspec instructions design --change add-dark-mode

# apply 阶段指令
openspec instructions apply --change add-dark-mode

# JSON 给 agent
openspec instructions design --change add-dark-mode --json
```

### 返回内容

- artifact 的模板正文
- 项目 config.yaml 里的 `context`（包在 `<context>` 标签）
- 对应 artifact 的 `rules`（包在 `<rules>` 标签）
- 所有依赖 artifact 的内容（让 AI 生成时有上下文）

这就是 OPSX 打破「硬编码提示」的关键——AI 不再读源码里的字符串，而是实时查询 CLI。

---

## §3 `openspec templates`

查看某个 schema 的模板文件实际解析到哪里。

```
openspec templates [--schema <name>] [--json]
```

### 示例

```bash
# 默认 schema
openspec templates

# 自定义 schema
openspec templates --schema my-workflow

# JSON
openspec templates --json
```

### 输出

```
Schema: spec-driven

Templates:
  proposal  → ~/.openspec/schemas/spec-driven/templates/proposal.md
  specs     → ~/.openspec/schemas/spec-driven/templates/specs.md
  design    → ~/.openspec/schemas/spec-driven/templates/design.md
  tasks     → ~/.openspec/schemas/spec-driven/templates/tasks.md
```

模板解析优先级：**project → user global → package built-in**（见 [07-customization.md §3](07-customization.md#3-schema-解析优先级)）。

---

## §4 `openspec schemas`

列出所有可用 schema 和它们的来源。

```
openspec schemas [--json]
```

### 输出

```
Available schemas:

  spec-driven (package)
    The default spec-driven development workflow
    Flow: proposal → specs → design → tasks

  my-custom (project)
    Custom workflow for this project
    Flow: research → proposal → tasks
```

括号里的来源类型：`package`（内置）/ `user`（`~/.local/share/openspec/schemas/`）/ `project`（`openspec/schemas/`）。
