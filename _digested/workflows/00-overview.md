# Workflow Templates · 总览

## 位置

workflow templates 是 OpenSpec 的内核。它们不是 TypeScript 里的硬编码执行流程，而是投递给 coding agent 的**操作手册源码**。

```text
OpenSpec CLI runtime API          ← TS 机械层
  → status/instructions/validate/new change
workflow template                 ← MD 智力层的操作手册
  → 告诉 agent 如何串这些 API
宿主 coding agent                 ← 推理、写文件、跑测试
```

CLI 负责保存和解释状态（确定性的），template 负责告诉 agent 怎么操作（策略性的），agent 负责实际执行（智能的）。三层分离让行为可解释但不完全硬编码。

## 全部 workflow 一览

源码目录：`src/core/templates/workflows/`

| 文件 | workflow id | 类型 | 一句话 |
|---|---|---|---|
| `explore.ts` | `explore` | 发现 | stance，非 workflow；探索想法、调查问题、澄清需求 |
| `propose.ts` | `propose` | 规划 | 快速路径：创建 change + 生成全部 artifact 直到 apply-ready |
| `new-change.ts` | `new` | 规划 | 只创建 change scaffold，不生成 artifact 内容 |
| `continue-change.ts` | `continue` | 规划 | 增量路径：每次只推进一个 ready artifact |
| `ff-change.ts` | `ff` | 规划 | fast-forward：批量生成剩余 artifact |
| `apply-change.ts` | `apply` | 实施 | 按 tasks.md checkbox 逐项实施代码 |
| `sync-specs.ts` | `sync` | 同步 | agent-driven 智能合并 delta specs 到主 specs |
| `verify-change.ts` | `verify` | 验证 | 检查实现与 artifacts 的一致性 |
| `archive-change.ts` | `archive` | 收尾 | agent 层收尾：sync assessment + 移动 change 到 archive |
| `bulk-archive-change.ts` | `bulk-archive` | 收尾 | 批量归档多个 completed changes |
| `onboard.ts` | `onboard` | 引导 | 引导式端到端体验 |
| `update-change.ts` | `update` | 修订 | 修订已有 planning artifacts，保持 artifact 间一致。**不改代码。**（v1.6.0 新增） |

`feedback.ts` 和 `store-selection.ts` 也在 workflows 目录下，但不在 profile selection 里，属于辅助模块。

## 用户可见的调用方式

每个 workflow 有两种投递形态——skill（agent 自动调）和 slash command（用户手动输入）。部分还有独立的 CLI 命令：

| workflow | command adapter 示例 | skill 名 | 独立 CLI？ | profile |
|---|---|---|---|---|
| explore | `/opsx:explore [想法]` | `openspec-explore` | 无 | **core** |
| propose | `/opsx:propose <name>` | `openspec-propose` | 无 | **core** |
| new | `/opsx:new <name>` | `openspec-new-change` | `openspec new change` 存在，但模板围绕其做了更多 | custom |
| continue | `/opsx:continue [name]` | `openspec-continue-change` | 无 | custom |
| ff | `/opsx:ff <name>` | `openspec-ff-change` | 无 | custom |
| apply | `/opsx:apply [name]` | `openspec-apply-change` | 无 | **core** |
| sync | `/opsx:sync [name]` | `openspec-sync-specs` | 无（也被 archive 内部调用） | **core** |
| verify | `/opsx:verify [name]` | `openspec-verify-change` | `openspec validate` 类似但不同 | custom |
| archive | `/opsx:archive [name]` | `openspec-archive-change` | **有**：`openspec archive`（路径不同） | **core** |
| bulk-archive | `/opsx:bulk-archive` | `openspec-bulk-archive-change` | 无 | custom |
| onboard | `/opsx:onboard` | `openspec-onboard` | 无 | custom |
| **update** | `/opsx:update [name]` | `openspec-update-change` | 无 | **core**（v1.6.0 新增；现已进入默认集） |

> 表中 `/opsx:*` 是 command adapter（例如 Claude Code）的示例，不是通用调用语法。Codex 使用 `$openspec-*`；Zed Agent 使用 `/openspec-*` 或 `@openspec-*`。v1.10.0 中 Codex、Zed Agent 与 vendor-neutral `agents` 三方共享 `.agents/skills/`（见 `../mechanisms/02-tool-delivery.md`）；其他 host 应以实际安装的 command/skill 名为准。

> **core profile**（默认）：propose, explore, apply, update, sync, archive —— 6 个。大多数用户只看到这些。
> **custom profile**：需在 `customWorkflows` 中显式启用，才能解锁全部 12 个。
> custom 选择 `archive` 或 `bulk-archive` 时会自动在第一个依赖者前补 `sync`；已有 `sync` 不重复、不重排，profile 仍保持 custom。

## 四类 workflow

### 发现类（1 个）

**explore** — 和其他所有 workflow 不同，它是 stance 不是 workflow。没有固定步骤、没有强制输出。agent 被要求好奇、可视化、扎根代码。

### 规划类（4 个）

**propose / new / continue / ff** — 四个模板共享同一套 artifact DAG（来自 schema），区别在于**操作粒度**：

| workflow | 创建 change | 生成 artifact | 粒度 |
|---|---|---|---|
| `propose` | 会 | 会，直到 apply-ready | 快速完整 |
| `new` | 会 | 不会 | scaffold |
| `continue` | 不创建 | 一次一个 | 增量 |
| `ff` | 可用于已有 change | 多个 | 批量推进 |

这就是 OPSX "动作而非阶段" 的体验基础：用户可以从不同粒度切入同一条 artifact DAG。

### 修订类（1 个，v1.6.0 新增）

**update** — 修订已有 planning artifacts，保持 artifact 间一致。**绝不改代码。** 和 continue 的区别：continue 按 DAG 推进 build frontier（创建新 artifact），update 在已有 frontier 内修订（编辑已有 artifact）。

### 实施类（1 个）

**apply** — 唯一真正修改业务代码的 workflow。消费 `openspec instructions apply --json`，逐项执行 tasks.md 的 checkbox。

### 收尾与同步类（3 个）

**sync / archive / bulk-archive** — 处理 delta specs → main specs 的合并和 change 目录的归档。

## 每个 template 的统一结构

读任何 workflow template 源码时，关注这六个区域：

| 区域 | 内容 |
|---|---|
| **Input** | 接受什么参数（change name、描述、空） |
| **Steps** | 按顺序做的动作（CLI 命令 + agent 行为） |
| **Output** | 成功/暂停/失败时输出什么格式 |
| **Guardrails** | 绝对不能做的事 |
| **Artifact Creation Guidelines** | （仅规划类）怎么写 artifact |
| **Fluid Workflow Integration** | （仅 apply）和其他 workflow 怎么交织 |

## 和 CLI runtime API 的关系

每个 template 调用的 CLI 命令是有限的、固定的集合：

| CLI 命令 | 被哪些 workflow 调用 |
|---|---|
| `openspec list --json` | explore, continue, apply, archive, sync, verify, update |
| `openspec status --change X --json` | **全部**（除 onboard） |
| `openspec new change "<name>"` | propose, new, ff |
| `openspec instructions <artifact> --json` | propose, continue, ff, update（仅大改时） |
| `openspec instructions apply --json` | apply |
| `openspec instructions archive --json` | archive、bulk-archive（读取 operation inputs） |
| `openspec schemas --json` | new（可选） |
| `openspec validate` | verify |

## v1.8.0 运行时要点

- `skip_specs: true` 让没有 spec-level 行为变化的 change 将 specs artifact 标为 `skipped`；规划/apply/归档 workflow 应把它当已满足，而不能创建任何 delta file。（v1.7.0 引入）
- `specs` 与 `design` 在 proposal 后并行 ready；同级推荐顺序按 schema 声明，内置 schema 先推荐 specs 再 design。（v1.7.0）
- 除 bulk archive 外，workflow 选择 change 的默认顺序是：显式名称 → 对话推断 → 唯一 active change 自动选择 → 仅在歧义时列出并询问。（v1.7.0）
- Apply/Archive 通过各自的 instructions API 获得当前 config `context` 和 operation guidance；artifact `rules.*` 仍只约束对应 artifact 的生成。（v1.7.0）
- status 的 JSON 含 `isPlanningComplete`（与兼容别名 `isComplete`）；planning artifact 的完成与实现进度分开表达。（v1.8.0）

template 不直接操作文件系统——它通过 CLI 命令获取路径，再由 agent 用自己的文件工具去读写。

## 和 `_faq_on_digested/` 的关系

FAQ 里的四条核心命令（explore→propose→apply→archive）是从**问题驱动**的视角分析的。本目录是从**模板源码**的视角分析的。两者互补：

- FAQ 回答 "这个阶段发生了什么，MD 和 TS 怎么交替"
- 本目录回答 "template 里写了什么指令，agent 看到后会做什么"

## 源码锚点

| 机制 | 路径 |
|---|---|
| workflow 模板源码 | `src/core/templates/workflows/*.ts` |
| skill/command 外壳 | `src/core/templates/skill-templates.ts` |
| 类型定义 | `src/core/templates/types.ts` |
| skill generation | `src/core/shared/skill-generation.ts` |
| profile 选择 | `src/core/profiles.ts` |
| runtime API | `src/commands/workflow/` |
