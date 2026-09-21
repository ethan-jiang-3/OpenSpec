# Store 模型与仓库协同

## 它解决的不是"多仓库合并"

Store 模型不创建协调视图，不管理 linked repos。它就是两件事：

1. **store**：全局注册仓库 checkout，让 OpenSpec 知道"这些 repo 存在"
2. **reference**：项目声明"我还关心这些 store 的 specs"

agent 通过 `openspec context` 拿到一个 working set（root + referenced stores 的 spec 索引），但它不自动 clone、不自动 sync、不内联 specs 内容、不替 referenced repo 做任何写操作。

还支持机器级 `defaultStore`：它是用户全局配置中的**低优先级 fallback**，只在没有更具体项目 root/选择时参与解析；它不是把某个 store 变成所有项目的 planning home，也不会让 references 自动写入或同步。

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

1. 按 root-selection 解析 root（显式 `--store <id>`、项目/当前目录解析优先；`defaultStore` 仅在低优先级 fallback）
2. 读取项目的 `references:` 列表
3. 对每个 reference，从 registry 找对应 store 的 checkout
4. 如果 checkout 存在且健康，提取其 spec 列表（id + 标题摘要）
5. 组装成 working set

不可解析的 store 会报告 warning（"not available — run: git clone ..."），不会让整个命令失败。

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


## v1.13.x store 行为修正

| 修复 | 行为 |
|------|------|
| `store remove` 拒绝删除包含其他注册 store 的目录（`9f8dec5d`） | 此前会连同嵌套 store（如 submodule 形式的 vendored store）一起递归删除、registry 条目悬空；现在报错并逐个点名要先跑的 `openspec store unregister` |
| 名为 `specs`/`changes` 的 store 不再被误当 root（`208b5b55`） | — |
| `store setup --no-init-git` 可在已有 git 仓库内运行（`5d221456`） | dotfiles 仓库用户可以把 store 放在推荐的 `~/openspec/<id>` 路径；显式/默认 init-git 仍拒绝嵌套仓库 |
