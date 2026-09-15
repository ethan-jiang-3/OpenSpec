# Lifecycle 总览

## 先分清两条生命周期

OpenSpec 当前有两条相关但不同的生命周期：

| 生命周期 | 主体 | 典型状态 |
|----------|------|----------|
| repo-local change lifecycle | 一个 repo 里的 `openspec/changes/<name>/` | propose → apply/sync → archive |
| store coordination | store registry + references + working set | register stores → declare references → inspect context → create repo-local plan in owning repo |

两者可以衔接，但不能混成一条自动流水线。store 提供跨仓库的上下文引用；repo-local change 仍然是具体实现和 archive 的主要承载。

## repo-local workflow 地图

当前 workflow ids 在 `src/core/profiles.ts`：

```text
propose
explore
new
continue
apply
ff
sync
archive
bulk-archive
verify
onboard
update
```

可以按职责分成六组：

| 组 | workflow | 作用 |
|----|----------|------|
| 探索 | `explore` | 不急着落盘，先澄清问题和方向 |
| 创建/推进规划 | `propose`、`new`、`continue`、`ff` | 创建 change 和 artifact |
| 实施 | `apply` | 根据 tasks 实施，并更新 task 状态 |
| spec 同步 | `sync` | agent-driven 把 delta specs 同步到主 specs，但不 archive |
| 校验/收尾/引导 | `verify`、`archive`、`bulk-archive`、`onboard` | 验证、归档、批量归档或引导式端到端流程 |
| 修订 | `update` | 修订已有 planning artifacts，保持一致性，不改代码 |

## 快速路径和拆分路径

```text
快速路径：
  explore? → propose → apply → sync? → archive

拆分路径：
  explore → new → continue/ff → apply → verify? → sync? → archive
```

`propose` 倾向一次把进入实施所需的规划 artifact 做齐。`new` 和 `continue` 更适合逐个 artifact 推进。`ff` 是加速生成剩余规划 artifact 的入口。`update` 在任意阶段修订已有 artifacts——Explore 中做了决策 → update artifacts；Apply 中发现 design 问题 → 回修 artifacts——不改代码。

## artifact lifecycle

在默认 repo-local schema 下，planning artifact 大致是：

```text
proposal
  ├── specs
  └── design
       └── tasks   (tasks 同时依赖 specs 和 design)
```

status 判断的核心不是“阶段字段”，而是 artifact output 是否存在、依赖是否完成。具体 completion detection 和 apply gate 细节见 `../internal-spec-driven/`。

## apply / sync / archive 的边界

| workflow | 本质 | 不应该误解成 |
|----------|------|--------------|
| `apply` | 根据 tasks 实施业务代码，并持续更新任务清单 | 自动合并 specs 或自动 archive |
| `sync` | agent-driven 将 delta specs 的意图合并到主 specs | archive 的替代品 |
| `archive` | CLI archive 或 agent archive 模板引导的收尾路径 | 普通实现步骤 |

`sync` 进入 core profile 后，repo-local 生命周期里多了一个重要能力：可以在不 archive change 的情况下更新主 specs。这对长生命周期 change 或需要先同步 specs 再继续实现的场景有用。

## store coordination

store 侧的上下文流：

```text
openspec store register <path> --id <id>
  → openspec/config.yaml 加 references: [<id>]
  → openspec context（查看 working set）
  → openspec doctor（健康检查）
  → 从 owning repo: openspec new/propose ...
```

关键点：

- store 是全局注册的仓库 checkout。
- reference 是项目声明的"我还关心这些仓库的 specs"。
- working set 是本机组装出来的上下文视图（纯查询，不写）。
- durable repo-local change 仍应从 owning repo 创建。
- workset 是个人本地保存的多仓库打开视图，不共享。

## 从这里跳到专题细节

| 想继续看 | 去哪里 |
|----------|--------|
| `status` / `instructions` 的 JSON 和调用链 | `../spec_cli/03-workflow-runtime-api.md` |
| schema 如何定义 artifact DAG | `../schema/01-schema-到底是什么.md` |
| `spec-driven` 的 proposal/specs/design/tasks | `../schema/02-内置-spec-driven-详解.md` |
| explore/propose/apply/archive 精确机制 | `../internal-spec-driven/00-四条命令的共有机制.md` |

## 源码入口

| 主题 | 入口 |
|------|------|
| workflow id 列表 | `src/core/profiles.ts` |
| workflow 模板 | `src/core/templates/workflows/` |
| new/status/instructions CLI | `src/commands/workflow/` |
| apply gate 状态 | `src/core/change-status-policy.ts`、`src/commands/workflow/instructions.ts` |
| sync 模板 | `src/core/templates/workflows/sync-specs.ts` |
| archive CLI | `src/core/archive.ts` |
| store CLI | `src/commands/store.ts`、`src/commands/context.ts` |
| workset CLI | `src/commands/workset.ts` |
| doctor CLI | `src/commands/doctor.ts` |
