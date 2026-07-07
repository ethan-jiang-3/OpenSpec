# 计划 1/3：_digested/ 剩余更新（1D 收尾 + 1E + 1F + 1G）

## 当前进度

- ✅ 1A `_coverage/` — 三个覆盖矩阵已刷新
- ✅ 1B `system/` — 整体系统模型已更新（03 重写 + 全目录 workspace→store）
- ✅ 1C `mechanisms/` — store 协调章已重写（01 替换 + 00/README 更新）
- 🔶 1D `spec_cli/` — `04` 和 `07` 已更新，但 `00-map.md`、`01`、`08` 仍有 workspace 引用待改
- ⬜ 1E `schema/` — 待做
- ⬜ 1F `internal-spec-driven/` — 待做
- ⬜ 1G `specs_truth/` — 待做

## 剩余任务

### 1D 收尾：spec_cli/ 轻量修改

| 文件 | 操作 | 内容 |
|------|------|------|
| `00-map.md` | 局部改 | "workspace operator" audience → "store operator" |
| `01-human-facing-cli.md` | 局部改 | workspace 命令引用更新 |
| `08-glossary-and-models.md` | 局部改 | 删除 workspace/context-store/initiative 定义，新增 store/workset/reference/context |
| `02-machine-facing-cli.md` | 局部改 | workspace CLI 接口引用 |
| `05-config-profile-delivery.md` | 局部改 | workspace 投递模式引用 |

### 1E：schema/ 更新

| 文件 | 操作 | 操作描述 |
|------|------|----------|
| `03-内置-workspace-planning-详解.md` | 标记废弃 | 加 v1.5.0 警告 banner：此 schema 已从源码中删除。保留正文作为历史参考 |
| `00-map.md` | 局部改 | 移除或标注 workspace-planning 条目 |
| `04-schema-解析优先级.md` | 局部改 | PlanningHome 默认值可能不再区分 repo/workspace |
| `05-四层注入机制.md` | 局部改 | tangential mention |

### 1F：internal-spec-driven/ 复查

| 文件 | 操作 | 操作描述 |
|------|------|----------|
| `04-archive-归档合并.md` | 重点复查 | 读新版 `src/core/archive.ts`，确认 resolution 收敛后的流程描述是否准确 |
| `02-propose-提案生成.md` | tangetial | workspace mention |
| `03-apply-实施执行.md` | tangetial | workspace mention |
| `05-schema-driven-控制面.md` | tangetial | workspace-planning mention |

### 1G：specs_truth/ 处理

| 文件 | 操作 | 操作描述 |
|------|------|----------|
| `09-平行权威层-initiatives.md` | 重写或标记废弃 | initiatives 已废弃。决定：标记 `> **v1.5.0**: initiatives 概念已废弃，本文仅保留作为历史参考` |
| `06-源码锚点与缺口.md` | 局部改 | archive resolution 相关锚点可能变化 |
| `01`、`02`、`00-map` | 局部复查 | tangetial mentions |

### 工作量估计

约 1 轮对话可完成（大部分是轻量编辑）。
