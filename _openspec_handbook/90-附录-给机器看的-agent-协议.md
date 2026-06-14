# 90 · 附录：给机器看的 Agent 协议

> 这一篇不是给第一次上手的人看的，而是给想研究"OpenSpec 怎么喂给宿主 agent"的人看的。

---

## 先明确三方角色

```text
用户  ←→  宿主 Agent（Claude Code / Cursor / Codex 等）  ←→  OpenSpec CLI
```

三者分工是：

- **用户**：提需求、选命令、确认方向
- **宿主 Agent**：理解命令、调用 CLI、把上下文喂给自己的模型、生成内容
- **OpenSpec CLI**：读写文件、解析 schema、计算 artifact 状态、返回结构化上下文

最关键的一句：

> **OpenSpec 自己不是 LLM，它是 prompt 编排器和状态引擎。**

---

## 对机器来说，最重要的不是页面文档，而是结构化查询

宿主 agent 并不是靠"读完整本手册"来工作的。

它更依赖几类运行时查询，例如：

- `openspec status --json`
- `openspec instructions <artifact> --json`
- `openspec schemas`
- `openspec templates`

这些命令提供的是机器可消费的上下文，而不是给人看的长篇解释。

### 这些查询分别在干什么

| 命令 | 机器拿来做什么 | 人类可理解成 |
|------|---------------|-------------|
| `openspec status --json` | 判断当前 change 到哪一步了、哪些 artifact 已完成 | 看项目仪表盘 |
| `openspec instructions <artifact> --json` | 生成某个 artifact 时拿到模板、规则、上下文、输出路径 | 拿到一份"写作任务单" |
| `openspec schemas` | 获取可用的 change 结构定义 | 看有哪几种工作流骨架 |
| `openspec templates` | 获取每类 artifact 的文本模板 | 看每种文档的推荐写法 |

---

## 一次典型执行链

以 `propose` 为例：

```mermaid
sequenceDiagram
    participant User as 用户
    participant Host as 宿主Agent
    participant CLI as OpenSpec CLI
    participant LLM as 宿主模型
    participant FS as 文件系统

    User->>Host: /opsx:propose add-feature
    Host->>CLI: openspec status --change add-feature --json
    CLI->>FS: 读取 openspec/ 状态
    FS-->>CLI: change/schema/artifact 状态
    CLI-->>Host: status JSON

    Host->>CLI: openspec instructions proposal --change add-feature --json
    CLI->>FS: 读取 schema + template + config
    FS-->>CLI: instruction 材料
    CLI-->>Host: instructions JSON

    Host->>LLM: 组装 prompt（status + instructions）
    LLM-->>Host: proposal markdown
    Host->>FS: 写入 changes/add-feature/proposal.md
    Host-->>User: proposal 已生成
```

所以：

- skill/command 负责"告诉 agent 怎么做"
- CLI 负责"给 agent 真实上下文"
- LLM 负责"真正写内容和做推理"

### `openspec status --json` 示例（简化）

```json
{
  "change": "add-order-csv-export",           // 当前 change 名称
  "schema": "spec-driven",                    // 使用的 schema
  "artifacts": {
    "proposal": { 
      "status": "done",                       // 已完成
      "path": "changes/add-order-csv-export/proposal.md" 
    },
    "specs": { 
      "status": "done",                       // 已完成
      "path": "changes/add-order-csv-export/specs/" 
    },
    "design": { 
      "status": "in_progress",                // 进行中
      "path": "changes/add-order-csv-export/design.md" 
    },
    "tasks": { 
      "status": "todo",                       // 待开始
      "path": "changes/add-order-csv-export/tasks.md" 
    }
  },
  "nextRecommended": "design"                 // 建议下一步做什么
}
```

**字段说明**：
- `status`：可能的值是 `todo`（待做）、`in_progress`（进行中）、`done`（完成）
- `nextRecommended`：CLI 根据依赖关系推荐下一步应该生成哪个 artifact

### `openspec instructions design --json` 示例（简化）

```json
{
  "artifact": "design",                       // 要生成的 artifact 类型
  "change": "add-order-csv-export",           // 所属 change
  "outputPath": "openspec/changes/add-order-csv-export/design.md",  // 输出路径
  "template": "# Design\n\n## Approach\n## Decisions\n## Risks\n",  // 文本模板
  "instruction": "Describe technical approach and key tradeoffs.",   // 生成指令
  "context": "Stack: TypeScript, React, Node.js",                    // 项目背景（来自 config.yaml）
  "rules": [                                                          // 写作规则（来自 config.yaml）
    "Explain migration risk when behavior changes existing flow",
    "Do not bypass domain module boundaries"
  ],
  "dependencies": ["proposal", "specs"]       // 依赖哪些 artifact（应该先读它们）
}
```

**字段说明**：
- `template`：文档的骨架结构
- `instruction`：告诉 AI 这个 artifact 应该写什么
- `context`：项目级背景信息，帮助 AI 生成更符合项目的内容
- `rules`：项目级约束，确保生成的内容符合团队规范
- `dependencies`：生成前应该先读哪些 artifact，确保内容一致

机器真正依赖的是这些结构化字段，而不是人类阅读版文档。

**v1.3.1 重要修复**：此前 `--json` 模式下 spinner 的进度文本会泄漏到 stderr，agent 合并 stdout+stderr 时 JSON 解析被污染。v1.3.1 修复了此问题——`--json` 时 spinner 完全静默，agent 可安全合并两个输出流。

**v1.4.0 补充**：在 workspace 上下文中，`status` 和 `instructions` 会使用 `workspace-planning` schema 而非 `spec-driven`。agent 不需要感知上下文切换——`PlanningHome` 抽象自动路由到正确的 schema。Workspace 生成的 skill 模板内置 guardrail，阻止 agent 在 workspace 上下文中执行 repo-local 操作（如 sync specs、archive）。

---

## skill、command、workflow 的关系

这三个词很容易混，但它们不是同一层：

| 名词 | 它是什么 |
|------|----------|
| workflow | 一个动作语义，例如 propose / apply / archive |
| skill | 给宿主 agent 看的能力说明书 |
| command | 给用户触发的命令入口模板 |

所以一个更准确的理解是：

- workflow 是"动作 ID"
- skill/command 是"投递方式"
- CLI 是"运行时事实来源"

---

## 给人的翻译：机器协议到底在服务什么

如果你不是在写宿主集成代码，可以把这篇浓缩成三句话：

1. 机器并不是"自己想写什么就写什么"，而是先问 CLI 拿结构化上下文
2. CLI 给的是"当前状态 + 本artifact任务单 + 项目规则"，不是随便一段提示词
3. 这就是为什么 OpenSpec 的输出更稳定：它把 AI 放进了一个有状态、有边界的运行时框架

---

## 为什么这部分应该放在最后

因为这部分解决的是：

- 机器怎么调用
- prompt 怎么拼
- 哪些信息是 runtime 提供的

它不是人类第一次上手 OpenSpec 时最先需要的认知。

人类第一步应该先会用，第二步应该先理解 `specs` 和 `changes`。
等主线稳了，再来看机器协议，才不会把整套系统看成"几份神秘 prompt 文件"。
