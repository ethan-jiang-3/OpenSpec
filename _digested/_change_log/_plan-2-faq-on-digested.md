# 计划 2/3：_faq_on_digested/ → v1.5.0 更新

## 影响范围

从探查结果来看，_faq_on_digested/ 有 10 个子目录、63 个文件。v1.5.0 的影响集中在约 20 个文件，主要是 **`actionContext.mode` 从 `"workspace-planning"` 变为只存在 `"repo-local"`** 导致的 guard 描述过时。

## 关键前置结论

Phase 0 研究已确认：

- `actionContext.mode` 在 v1.5.0 中**只有 `"repo-local"`**——旧的 `"workspace-planning"` 模式彻底删除
- `schemas/workspace-planning/` 已被删除，只剩 `spec-driven`
- `PlanningHome` 只有 `kind: 'repo'`，不再有 workspace 分支
- `--initiative` CLI flag 已隐藏，提示 "No longer supported"
- Initiative 概念被标记为 legacy（id.ts: "legacy initiative ids"）

## 任务清单

### 2A. `apply-ready-to-archive-ready/` — Apply guard 更新

这些文件引用了 `actionContext.mode = "workspace-planning"` 作为 apply 的停止条件。v1.5.0 中所有 mode 都是 `repo-local`，不再需要这个 guard。

| 文件 | 操作 | 位置 |
|------|------|------|
| `answer.md` | 改 | L91-95: `actionContext.mode = "workspace-planning"` → 标注为 v1.4.0 历史行为；v1.5.0 中此模式不再存在，apply 不再被 workspace guard 阻止 |
| `answer-app-guards.md` | 改 | L35-58 "workspace guard" 章节 → 标注历史（v1.5.0 已删除此 guard） |
| `answer-app06.md` | 改 | L134 "workspace guard 不允许编辑" → 标注变更 |
| `figures/apply-ready-to-archive-ready.svg` | 改 | 标签文本 "workspace" → 标注为历史 |

### 2B. `archive-ready-to-archived/` — Archive guard 更新

同样的 workspace guard 问题。

| 文件 | 操作 | 位置 |
|------|------|------|
| `answer-arc-opsx.md` | 改 | L88-99 "workspace archive guard" → 标注历史 |
| `answer-arc-guards.md` | 改 | L139-147 "OPSX workspace guard" → 标注历史 |
| `answer.md` | 改 | L368 "workspace archive guard" → 标注历史 |
| `figures/archive-ready-to-archived.svg` | 改 | 标签文本 |

### 2C. `explore-to-propose-change/` — Explore 上下文描述更新

| 文件 | 操作 | 位置 |
|------|------|------|
| `answer-exp04.md` | 改 | L263-265: workspace planning 模式描述 → "v1.5.0 中 workspace planning 模式已删除" |
| `answer-exp05.md` | 改 | L60/69/152: "想加 workspace 支持" 示例 → 可保留（作为历史场景示例）或改为 "想加 store 支持" |
| `answer.md` | 改 | L224-229: 示例调整 |

### 2D. `propose-to-apply-ready/` — Propose 上下文

| 文件 | 操作 | 位置 |
|------|------|------|
| `answer-prp04.md` | 改 | L149-155: `actionContext` 示例中的 `workspace-planning` → `repo-local`，删 linked repos 字段（不再存在） |

### 2E. `config-yaml-growth/` — 配置生长引用

| 文件 | 操作 | 位置 |
|------|------|------|
| `answer-beginner.md` | 改 | L84: `workspace doctor`、`context-store doctor`、`initiative diagnostic` → 标注这些命令已在 v1.5.0 中删除 |
| `answer-guru.md` | 改 | L28: `workspace-planning/schema.yaml` → 标注此 schema 已在 v1.5.0 中删除，可换用 `spec-driven/schema.yaml` 的 apply 块作为结构护栏示例 |
| `sources.md` | 改 | L30: workspace-planning/schema.yaml 引用 → 标注已删除 |

### 2F. `schema-article-driven/` — 验证待定项解决

| 文件 | 操作 | 位置 |
|------|------|------|
| `answer.md` | 改 | L87: "v1.4.0 workspace schema 变化需要后续验证" → 更新结论：workspace schema 已在 v1.5.0 删除，此限制不适用 |

### 2G. 不受影响的子目录

`keep-specs-aligned/`、`openspec-executable/`、`schema-agent-dev/`、`schema-requirement/` — 这些不引用 workspace/initiative/context-store 概念，不需要修改。

## 工作量估计

约 1 轮对话。大部分是加 v1.5.0 标注而非重写内容。
