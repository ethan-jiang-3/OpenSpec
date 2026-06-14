# 03 — apply：实施执行

apply 是 propose 的自然延续 —— 当所有规划 artifact 就绪，agent 按 tasks.md 中的清单逐一实施，标记 checkbox，直到全部完成。

---

## 1. Apply Gate：为什么需要"准入检查"

apply 不是"用户说 apply 就开始写代码"。它有一个**gate 机制** —— `openspec instructions apply --change X --json` 会根据前提条件是否满足返回不同状态，agent 根据状态决定是否允许实施。

这个设计的意义：**防止 AI 在没有充分规划的情况下写代码**。apply 拒绝在 specs/design/tasks 缺失时执行。

---

## 2. `openspec instructions apply` 的内部逻辑

实现位于 `src/commands/workflow/instructions.ts` 中的 `applyInstructionsCommand`。

### 2.1 执行流程

1. 解析 change name（与 propose 同款 `validateChangeExists`）
2. 调用 `loadChangeContext()` 加载 schema、构建 DAG、检测 completion
3. 从 schema 获取 `apply.requires` 和 `apply.tracks`。对于 spec-driven，`apply.requires: [tasks]`，`apply.tracks: tasks.md`。如果 schema 没有定义 `apply.requires`，代码级回退为 schema 的全部 artifact ID（`src/core/artifact-graph/instruction-loader.ts:386`：`schema.apply?.requires ?? schema.artifacts.map(a => a.id)`）
4. 调用 `generateApplyInstructions()`

### 2.2 generateApplyInstructions 的核心逻辑

1. **检查缺失 artifact**：遍历 `apply.requires`，对每个 artifact 检查其输出文件是否存在。如果任何必需 artifact 缺失 → `state: "blocked"`，并列出 `missingArtifacts`
2. **读取 tracks 文件**（通常是 tasks.md）：如果文件不存在 → `state: "blocked"`
3. **解析 checkbox**：逐行扫描 tasks.md，用正则匹配 checkbox 格式
4. **计算进度**：total / complete / remaining
5. **判断状态**：
   - `blocked`：缺少必需 artifact 或 tasks.md
   - `all_done`：所有 checkbox 已标记
   - `ready`：tasks.md 存在且有未完成任务

### 2.3 返回的 JSON 结构

```json
{
  "state": "ready",
  "contextFiles": {
    "proposal": ["/project/openspec/changes/add-dark-mode/proposal.md"],
    "specs": ["/project/openspec/changes/add-dark-mode/specs/theme/spec.md"],
    "design": ["/project/openspec/changes/add-dark-mode/design.md"],
    "tasks": ["/project/openspec/changes/add-dark-mode/tasks.md"]
  },
  "progress": {
    "total": 7,
    "complete": 0,
    "remaining": 7
  },
  "tasks": [
    { "label": "1.1 Create theme context", "done": false },
    { "label": "1.2 Add CSS variable generation", "done": false }
  ],
  "instruction": "Read context files, work through pending tasks, mark complete as you go..."
}
```

**关键字段**：

- **`state`**：三种状态 —— agent 必须根据状态走不同分支
- **`contextFiles`**：artifact ID → 文件路径数组。**agent 必须在开始实施前读完所有这些文件**。这个列表是 schema 驱动的，不是硬编码的 —— 不同 schema 可能包含不同的 artifact
- **`progress`**：total/complete/remaining 计数
- **`tasks`**：解析后的 checkbox 列表，每个带 label 和 done 状态
- **`missingArtifacts`**（仅 blocked 时）：哪些 artifact 还没创建

---

## 3. Checkbox 解析机制

### 3.1 正则

`src/commands/workflow/instructions.ts:233`：

```typescript
const checkboxMatch = line.match(/^[-*]\s*\[([ xX])\]\s*(.+)\s*$/);
if (checkboxMatch) {
  const done = checkboxMatch[1].toLowerCase() === 'x';
  // ...
}
```

### 3.2 什么算 checkbox

- `- [ ] Task` → 未完成
- `- [x] Task` → 完成
- `- [X] Task` → 完成（大小写不敏感）
- `* [ ] Task` → 也支持 `*` 前缀
- 空格数量灵活（`-  [ ]` 和 `- [ ]` 都可以）

### 3.3 什么不算 checkbox

- 没有方括号的 `- Task` → 不算
- `- [?] Task` → 不算（只认空格和 x/X）
- 非列表项中的 `[ ]` → 不算（必须在 `-` 或 `*` 开头）

### 3.4 编号约定

`X.Y` 格式（如 `1.1`、`2.3`）纯粹是约定，解析器不强求。agent 被鼓励使用它来保持可读性，但 `- [ ] Do the thing` 同样能正常被追踪。

---

## 4. 完整实施流程（7 步）

> **机制 vs 行为**：下面描述的 7 步流程来自 skill 模板（`src/core/templates/workflows/apply-change.ts:13-160`）——它告诉 AI agent "应该怎么做"，而非 CLI 硬编码的执行逻辑。CLI 负责的是第 2 节的 apply gate（状态判定、checkbox 解析），agent 负责的是执行这些步骤。agent 理论上可以不按这 7 步走，但模板的设计意图就是引导 agent 遵循这个流程。

来自 skill 模板 `apply-change.ts`（`instructions` 字段；编号步骤实际位于 `:19 / :28 / :37 / :56 / :63 / :71 / :86`）。

### Step 1：选定 change

优先级：
1. 用户提供的 change name（如 `/opsx:apply add-dark-mode`）
2. 从对话上下文推断
3. 如果只有一个活跃 change，自动选中
4. 如果有多个，运行 `openspec list --json` 并用 AskUserQuestion 让用户选

### Step 2：获取 schema 信息

```bash
openspec status --change "<name>" --json
```

目的：了解 schemaName、planningHome、actionContext。

**Workspace guard**：如果 `actionContext.mode === "workspace-planning"` 且 `allowedEditRoots` 为空，停止 —— 不能在 workspace 模式下跨仓库编辑文件。

### Step 3：获取 apply 指令

```bash
openspec instructions apply --change "<name>" --json
```

解析返回的 JSON，**根据 `state` 走不同分支**：

| state | agent 行为 |
|-------|----------|
| `"blocked"` | 显示哪些 artifact 缺失，建议用 `/opsx:propose` 回去补全缺失的 artifact（`/opsx:continue` 是另一类辅助 workflow，用于"继续上次未完成的 change"，不负责补全 artifact） |
| `"all_done"` | 祝贺，建议 `/opsx:archive` |
| `"ready"` | 继续到 Step 4 |

### Step 4：读 context files

读取 `contextFiles` 中的每一个文件。对于 spec-driven schema 这意味着 proposal、specs、design、tasks。

**不要假设文件名** —— 始终跟 `contextFiles` 走。不同 schema 的文件列表不同。

### Step 5：展示进度

```
## Implementing: add-dark-mode (schema: spec-driven)
Progress: 0/7 tasks complete
```

### Step 6：实施循环

```
for each pending task:
    显示 "Working on task N/M: <description>"
    写代码（最小化、聚焦于该 task）
    标记完成：- [ ] → - [x]
    继续下一个
```

**暂停条件**（任一触发即停）：
- task 描述不清楚 → 请求澄清
- 实施中暴露出设计问题 → 建议更新 artifact
- 遇到错误或阻塞 → 报告并等待指导
- 用户中断

### Step 7：完成或暂停

- **全部完成**：展示汇总，建议 `/opsx:archive`
- **暂停了**：解释为什么停，等待指导

---

## 5. 实施中的流体工作流理念

apply 的 skill 模板 (`apply-change.ts:155-160`) 末尾有一段关键声明：

> "This skill supports the 'actions on a change' model:
> - Can be invoked anytime: Before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
> - Allows artifact updates: If implementation reveals design issues, suggest updating artifacts - not phase-locked, work fluidly"

这体现了 OpenSpec 的核心理念：**不是 phase-locked（阶段锁定）**。即使在 apply 阶段，agent 也可以回头修改 proposal/design/specs —— 因为实施过程中发现的问题可能颠覆之前的假设。apply → 发现设计问题 → 回到 propose 更新 design → 继续 apply，这是一个自然的循环，不是错误。

---

## 6. Apply Phase 的 schema 配置

`schemas/spec-driven/schema.yaml:148-153`：

```yaml
apply:
  requires: [tasks]
  tracks: tasks.md
  instruction: |
    Read context files, work through pending tasks, mark complete as you go.
    Pause if you hit blockers or need clarification.
```

`apply.requires` 决定了哪些 artifact 全部完成才算"可以实施"。对于 spec-driven，只有一个：tasks。但你可以定义自定义 schema 要求更多 —— 比如 `apply.requires: [specs, design, tasks, review]`。

`apply.tracks` 指定用哪个文件追踪进度。它总是指向一个有 checkbox 的文件。

`apply.instruction` 是 agent 在实施时收到的动态指导文字。

---

## 7. 与另外三条命令的关系

```
explore ──(洞察结晶)──→ propose ──(全部 artifact 完成)──→ apply ──(全部 task 完成)──→ archive
    ↑                       ↑                               │                            │
    │                       │                               │                            │
    └─── 任何阶段都可以 invoke explore ──────────────────────┘                            │
                            └─── 实施中发现问题可以回到 propose 更新 artifact ─────────────┘
```

apply 是唯一**真正修改应用代码**的阶段。explore 只读，propose 只写规划 artifact，archive 只合并和移动 —— 只有 apply 会动 `src/` 下的业务代码。
