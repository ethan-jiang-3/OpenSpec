# 计划 3/3：_openspec_handbook/ → v1.5.0 更新

## 当前状态

Handbook v1.1，对齐 OpenSpec 1.4.1。19 个文件中，6 个完全不受影响，3 个需完全重写/大幅修改，其余需局部修改。

## 3A. 🔴 完全重写

### `07-高级-workspace-跨仓库规划.md` → `07-高级-store-跨仓库协同.md`

**重写原因**：整篇文章基于已删除的 `workspace` 命令体系。

**新内容大纲**：
1. v1.5.0 的跨仓库思路变了——从"workspace 协调视图"到"store 声明式引用"
2. Store 概念：注册全局 checkout（`openspec store register`）
3. Reference：项目声明"我还依赖这些仓库的 specs"（`config.yaml` 的 `references:`）
4. Context：查看 working set（`openspec context`）
5. Workset：个人多仓库视图（`openspec workset`）
6. Doctor：健康检查（`openspec doctor`）
7. 与 v1.4.0 workspace 的差异对照表
8. 当前限制（beta 状态）

### `00-index.md`

更新内容：
- 版本号：1.4.1 → 1.5.0
- CLI 命令表：删除 `workspace` 行，新增 `store`/`context`/`workset`/`doctor`
- 术语表：删除 workspace/context-store/initiative，新增 store/workset/reference/context
- 文件地图：07 文件名更新
- 阅读路径 5：更新描述

## 3B. 🟠 大幅修改

### `99-FAQ-常见问题.md`

Q32-Q36 "Workspace (v1.4.0 新增)" 章节全部改写：
- Q32: workspace 概念 → store 概念
- Q33-Q34: 相应改写
- Q35: context-store vs workspace vs initiative 三者区别 → store/context/workset 三者区别
- Q36: 实操步骤全部重写（旧步骤基于 `openspec context-store setup` + `workspace setup` + `workspace open`）

### `04-高级-config-schema-与项目边界.md`

L324-351 "v1.4.0 补充：第四层 — workspace 层" → 改写为 v1.5.0 store 层或标注此层概念已变化

### `15-实战-多人协作与Git工作流.md`

L684-704 "跨仓库协作（workspace 场景）" → 改为 "跨仓库协作（store 场景）"

## 3C. 🟡 局部修改（6 个文件）

| 文件 | 修改内容 |
|------|----------|
| `README.md` | 版本号 + TOC 中 07 文件名 |
| `05-高级-项目级全局约束到底放哪.md` | L60 workspace 层 → store 层 |
| `90-附录-给机器看的-agent-协议.md` | L5 workspace 上下文路由 → store |
| `03-高级-openspec-的软件开发生命周期思想.md` | L4 workspace 引用 |
| `06-高级-config-yaml-怎么写到真正好用.md` | L947-949 workspace 章引用 → store 章 |
| `09-高级-能力身份与specs漂移维护.md` | L139 workspace 交叉引用 |
| `14-实战-用-openspec-管理-devops-部署与验证.md` | L238 workspace 级规划 → store |

## 3D. ✅ 不改（6 个文件）

`01`、`02`、`08`、`10`、`11`、`12`、`13` — 聚焦核心概念，不涉及 workspace。

## 依赖关系

Handbook 更新依赖两个条件：
1. **_digested/_ 的 store 消化文章已完成** — 否则 07 新章缺乏技术准确性
2. **上游新文档已可参考** — `docs/stores-beta/user-guide.md` 提供了官方视角的 store 使用指南

## 工作量估计

约 2-3 轮对话。07 重写是最重的一项（需新建一章），其余是局部替换。
