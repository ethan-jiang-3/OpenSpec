# 计划 1/3：_digested/ → v1.5.0 更新

## 状态：✅ 基本完成，等质检确认

Phase 1 的所有子阶段已执行。以下是实际完成情况（和原计划的差异）：

## 实际完成

### ✅ 1A `_coverage/`
- `src-coverage.md` — 重写：删除旧模块行，新增 store/references/worksets 等
- `specs-coverage.md` — 重写：删除 workspace-* spec 条目
- `tests-coverage.md` — 重写：删除旧测试目录，新增 store 测试
- 所有 "v1.5.0 刷新" banner 和 "已删除" 表已移除

### ✅ 1B `system/`
- `03-planning-home-与-workspace.md` — **完全删除**，由 `03-planning-home-与-store-模型.md` 替代
- `00-map.md` — 第五层 "Workspace coordination" → "Store coordination"，移除 "当前版本最重要的变化" 对比节
- `02-目录与状态边界.md` — workspace/context-store/initiative 状态全部移除
- `06-源码地图与扩展点.md` — 旧模块路径删除，store 新模块路径新增
- `01/04/05/07/08/README` — 局部修改

### ✅ 1C `mechanisms/`
- `01-workspace-coordination.md` — **删除**，由 `01-store-模型与仓库协同.md` 替代
- `00-map.md` / `README.md` — 导航更新
- 新 store 文件中的 v1.4.0 对比表已移除，banner 已移除

### ✅ 1D `spec_cli/`
- `04-command-deep-dive.md` — 第六节 workspace 命令族重写为 store/context/workset/doctor
- `07-command-io-matrix.md` — workspace 行删除，store/context/workset/doctor 行新增
- `00/01/02/05/08` — 局部修改

### ✅ 1E `schema/`
- `03-内置-workspace-planning-详解.md` — **已删除**（schema 不存在了，不留历史文件）
- `00-map.md` — 03 条目移除，intro 更新
- `04-schema-解析优先级.md` — workspace-planning 引用和示例移除

### ✅ 1F `internal-spec-driven/`
- `03-apply` — workspace guard 行已删除
- `02-propose` — annotation 已清洁

### ✅ 1G `specs_truth/`
- `09-平行权威层-initiatives.md` — **已删除**
- `00-map.md` — 09 条目和引用移除，01/02/03/05/08 相关引用更新

## 执行中的策略变化

原计划是"标注废弃、保留历史参考"，实际执行改为 **彻底删除旧概念**：
- schema/03 和 specs_truth/09 直接删除（不留历史文件）
- 所有 "v1.5.0 已删除" 标注移除
- v1.4.0 对比表、banner、"替代了旧" 叙述移除
- 保持当前状态叙述，不讲历史

## 已知残余

约 30 处旧概念引用仍在 `specs_truth/` 和 `mechanisms/04` 中，主要是：
- specs_truth 的历史走查实例（具体的 change 名称和源码文件名）
- mechanisms/04 的模板内容描述

这些嵌入在较大段落的解释中，需要逐段改写。

## 下一步

等待质检 agent 完成，修掉发现的问题，然后可以进入 Phase 2（_faq_on_digested/）。
