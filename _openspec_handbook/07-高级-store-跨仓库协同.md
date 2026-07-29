# 07 · 高级：Store 跨仓库协同

> **Store 是 OpenSpec 的跨仓库上下文引用机制：声明哪些仓库的 specs 与当前项目相关，让 agent 知道「还有哪些 specs 可以看」。** 单仓库项目不需要 store；当你维护多个关联仓库时才用得上。

> **v1.7.0 root 边界。** `defaultStore` 是机器级、低优先级 fallback，不会覆盖已解析的项目 root，也不会让 referenced specs 自动内联或同步。`openspec view` 同样按 resolved root 展示，支持 `--store`。

---

## 一、为什么需要 store

产品需求同时砸在 API、Web、Mobile 三个 repo 上——每个 repo 各自的 spec-driven 流程管好自己的代码没问题，但 agent 在做 API 的 change 时，如果能看一眼 Web 和 Mobile 的 specs，方案会考虑得更周全。

v1.3.0 之前，OpenSpec 的所有操作都是 repo-local 的：

```text
my-project/
  openspec/
    specs/        ← 这个 repo 的正式规范
    changes/      ← 这个 repo 的进行中变更
    config.yaml   ← 这个 repo 的项目约束
```

store 模型给这套体系加了一层可选的能力：**让当前项目的 agent 知道还有哪些仓库的 specs 可以引用。**

## 二、store 不是什么

- **不是 monorepo** — store 不合并代码、不统一构建
- **不是 workspace 协调视图** — store 不创建新的规划 home，不管理 initiative
- **不是自动同步** — store 不 clone、不 pull、不自动更新 checkout
- **不是写操作** — store reference 只读，不会往 referenced repo 写任何东西

## 三、store 的物理结构

```text
~/.openspec/stores/
  registry.yaml                 ← 全局 store 注册表

<store-checkout>/
  .openspec-store/
    store.yaml                  ← store 身份（id, remote）
  openspec/
    specs/                      ← store 自身的 specs（供其他项目 reference）

~/.openspec/worksets/
  worksets.yaml                 ← 个人保存的多仓库打开视图
```

项目通过 `openspec/config.yaml` 声明依赖：

```yaml
# openspec/config.yaml
references:
  - platform-api
  - shared-schemas
```

agent 通过 `openspec context` 获取引用 store 的 spec 索引（id + 一行摘要 + clone recipe），不内联内容。

## 四、核心命令

### store：注册仓库

```bash
openspec store register /path/to/checkout --id platform-api
openspec store list
openspec store unregister platform-api
```

只记录已有目录，不 clone、不 init。

### context：查看工作上下文

```bash
openspec context              # human
openspec context --json       # JSON
openspec context --code-workspace  # VS Code 多根文件
```

输出 working set：当前 root + `references:` 中声明的 store 的 spec 索引。纯查询，不写。

### workset：个人工作视图

```bash
openspec workset save my-session --root . --store platform-api
openspec workset open my-session
openspec workset list
```

纯本地、不共享、不提交。数据在 `~/.openspec/worksets/worksets.yaml`。

### doctor：健康检查

```bash
openspec doctor
```

检查引用的 store 是否已注册、checkout 是否存在且可读。

## 五、设计原则

### 5.1 上下文引用，不创建新规划层

| 做什么 | 不做什么 |
|--------|---------|
| 让 agent 看到 referenced store 的 spec 索引 | 不内联 specs、不自动 merge |
| 通过 `references:` 声明依赖 | 不创建跨仓库的 change |

store 不引入新的 schema、不改变 change 的生命周期。所有 change 仍在具体 repo 下，使用 `spec-driven`。

### 5.2 单仓库不需要 store

```text
单仓库项目：
  openspec/specs/ + openspec/changes/ → 完全够用

多仓库项目：
  openspec/specs/ + openspec/changes/ + references: [other-store] → 多一层上下文
```

store 是可选扩展，不是必选项。

### 5.3 个人视图 vs 共享声明

| 类型 | 位置 | 例子 |
|------|------|------|
| 全局注册 | `~/.openspec/stores/registry.yaml` | store 注册（每台机器独立） |
| 项目声明 | `openspec/config.yaml` `references:` | 项目依赖哪些 store（可提交到 Git） |
| 个人视图 | `~/.openspec/worksets/worksets.yaml` | 多仓库打开视图（纯本地，不共享） |

## 六、与单仓库 OpenSpec 的对比

| | 单仓库 | 多仓库（store） |
|---|---|---|
| Schema | `spec-driven` | `spec-driven`（不变） |
| Change 位置 | `openspec/changes/` | 同左 |
| Specs 位置 | `openspec/specs/`（正式基线） | 同左 |
| Archive | 有 | 有（不变） |
| 跨仓库上下文 | 无 | `references:` + `openspec context` |

store 不改变核心流程——它只是在 agent 探索时多了一个「可以去看看其他仓库的 specs」的渠道。

## 七、当前限制（beta）

- Workset 是纯本地的，不支持团队共享
- Store remote 是可选字段，不保证 clone 可用性
- 不提供 store 间的依赖解析

## 八、什么时候该用 store

| 场景 | 建议 |
|------|------|
| 单个仓库 | 不需要 store |
| 2-3 个关联仓库 | 可以注册 store + 加 references，给 agent 更多上下文 |
| 3+ 仓库且 specs 互有引用 | store 是推荐的上下文引用方式 |

## 压缩结论

1. Store 是 OpenSpec 的跨仓库上下文引用——让 agent 知道「还有哪些 specs 可以看」
2. 单仓库不需要；多仓库有价值但非必须
3. Store 不改 change 生命周期——所有 change 仍在具体 repo 下，用 `spec-driven`
4. Store 不创建 coordination view，不管理 initiative——它就是「注册 + 引用 + 查询」
5. Workset 是个人本地视图，不共享

## 下一步

- 想知道 store 的配置层和 repo-local config.yaml 怎么共存 → [04 高级·config-schema-与项目边界](04-高级-config-schema-与项目边界.md)
- 想自定义工作流 → [08 高级·自定义 schema](08-高级-自定义-schema-创建自己的工作流.md)
- 多人 + 多 repo 时 store 协作怎么落地 → [15 实战·多人协作与 Git 工作流](15-实战-多人协作与Git工作流.md)
