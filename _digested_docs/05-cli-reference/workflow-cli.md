# CLI · Workflow 相关（给 Agent 用）

这四个命令是 **OPSX 的核心骨架**——AI agent 在执行 `/opsx:*` 命令时会调它们拿结构化数据。人类也能用它们检查进度。

实现在 [src/commands/workflow/](../../src/commands/workflow/)。

---

## `openspec status`

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

状态的三种值来自 [src/core/artifact-graph/state.ts](../../src/core/artifact-graph/state.ts)：`done` / `ready` / `blocked`。

---

## `openspec instructions`

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

## `openspec templates`

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

模板解析优先级：**project → user global → package built-in**（见 [07-customization/schema-resolution-order.md](../07-customization/schema-resolution-order.md)）。

---

## `openspec schemas`

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
