# Store 模型与仓库协同（v1.5.0）

> **v1.5.0 重写**：替代旧 `01-workspace-coordination.md`。v1.4.0 的 workspace + context-store + initiative → v1.5.0 store + reference + workset。

## 它解决的不是"多仓库合并"

v1.5.0 的 store 模型设计比 v1.4.0 workspace 更克制：它不创建协调视图，不管理 linked repos，不引入 initiative 目录结构。

它就是两件事：
1. **store**：全局注册仓库 checkout，让 OpenSpec 知道"这些 repo 存在"
2. **reference**：项目声明"我还关心这些 store 的 specs"

agent 通过 `openspec context` 拿到一个 working set（root + referenced stores 的 spec 索引），但它不自动 clone、不自动 sync、不内联 specs 内容、不替 referenced repo 做任何写操作。

## 五个新核心对象

| 对象 | 位置 | 本质 |
|------|------|------|
| store registry | `~/.openspec/stores/registry.yaml` | 全局仓库登记表：id → backend(local_path, remote, branch) |
| store metadata | `<checkout>/.openspec-store/store.yaml` | 单个 store 的身份（id, remote） |
| reference | `openspec/config.yaml` 的 `references:` 字段 | 项目声明的 store 依赖列表 |
| working set | `openspec context` 输出 | root + referenced stores 的 spec 索引（纯查询） |
| workset | `~/.openspec/worksets/worksets.yaml` | 个人本地的多仓库打开视图（不共享） |

## store registry 的工作方式

```yaml
# ~/.openspec/stores/registry.yaml
version: 1
stores:
  platform-api:
    backend:
      type: git
      local_path: /Users/alice/workspace/platform-api
      remote: https://github.com/team/platform-api.git
      branch: main
```

registry 是全局的，不属于任何单个项目。一个 store 注册后，可以被多个项目的 `references:` 引用。

CLI 操作：
```bash
openspec store register /path/to/checkout --id platform-api
openspec store list                    # 列出所有注册的 store
openspec store unregister platform-api # 注销
```

## working set 的组装

`openspec context` 的执行流程：

1. 解析 root（`--store <id>` 或 nearest `openspec/` 目录）
2. 读取项目的 `references:` 列表
3. 对每个 reference，从 registry 找对应 store 的 checkout
4. 如果 checkout 存在且健康，提取其 spec 列表（id + 标题摘要）
5. 组装成 working set

不可解析的 store 会报告 warning（"not available — run: git clone ..."），不会让整个命令失败。

## 和 v1.4.0 workspace 的本质区别

| 维度 | v1.4.0 | v1.5.0 |
|------|--------|--------|
| 多仓库入口 | `view.yaml` + managed workspace root | 全局 store registry |
| 仓库关系 | workspace links（路径映射） | `config.yaml` references（名称声明） |
| 协调上下文 | initiative 目录（长期） | 无——working set 是瞬时查询 |
| agent guard | `actionContext.mode = "workspace-planning"` | 无——所有 mode = `repo-local` |
| 个人视图 | 无独立概念 | workset（纯本地，不共享） |
| schema | `workspace-planning` schema | 无——只有 `spec-driven` |
| CLI | `openspec workspace *` | `openspec store` + `context` + `workset` + `doctor` |

## 源码入口

| 主题 | 入口 |
|------|------|
| store 基础类型与路径 | `src/core/store/foundation.ts` |
| store CRUD（1196 行） | `src/core/store/operations.ts` |
| store registry | `src/core/store/registry.ts` |
| git backend | `src/core/store/git.ts` |
| references 索引 | `src/core/references.ts` |
| working set 组装 | `src/core/working-set.ts` |
| workset 管理 | `src/core/worksets.ts` |
| root 选择 | `src/core/root-selection.ts` |
| 关系健康检查 | `src/core/relationship-health.ts` |
| 文件锁/原子写 | `src/core/file-state.ts` |
| openspec root 判定 | `src/core/openspec-root.ts` |
| store CLI | `src/commands/store.ts` |
| context CLI | `src/commands/context.ts` |
| workset CLI | `src/commands/workset.ts`、`workset-input.ts`、`workset-prompts.ts` |
| doctor CLI | `src/commands/doctor.ts` |
| 共享辅助 | `src/commands/shared-gather.ts`、`src/commands/shared-output.ts` |
