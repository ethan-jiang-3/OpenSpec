# 07 · 高级：Workspace 跨仓库规划（v1.4.0）

> **Workspace 是 OpenSpec 唯一的「跨仓库规划层」：它只管 What/Why，把 How 留给各 repo 已有的 spec-driven 流程。** 本章对应 v1.4.0 引入、v1.4.1 修补的 workspace 机制；如果你只维护单仓库，可跳过，但想理解 OpenSpec 的演进方向，这是必读。

---

## 一、为什么需要 workspace

产品需求同时砸在 API、Web、Mobile 三个 repo 上——每个 repo 各自的 spec-driven 流程就接不住了。你需要一个跨 repo 的规划层。v1.3.0 之前，OpenSpec 的所有操作都是 repo-local 的：

```text
my-project/
  openspec/
    specs/        ← 这个 repo 的正式规范
    changes/      ← 这个 repo 的进行中变更
    config.yaml   ← 这个 repo 的项目约束
```

这套模型在单仓库下工作得很好。但现实中有大量场景需要跨仓库协调：

- 你同时维护 API、Web 前端、Mobile 三个 repo，一个产品需求可能涉及全部三个
- 一个架构升级（如认证方式变更）需要同时改多个服务
- 团队想在一个地方看到跨仓库的变更全局视图

这些问题不是「某个 repo 的 spec」能解决的，因为它们跨越了 repo 边界。Workspace 就是为此而生的。

## 二、workspace 不是什么

在讲 workspace 是什么之前，先明确它不是什么：

- **不是 monorepo 替代品** — workspace 不合并代码，不统一构建
- **不是 Git 操作工具** — workspace 不管分支、不 merge 代码
- **不是 CI/CD 系统** — workspace 不做自动化、不跑 pipeline
- **不是项目管理工具** — workspace 不管 issue、不跟踪工时

它的定位非常精准：**跨仓库 change的规划层**。它只做「规划」这件事，实现留给你已有的 repo。

## 三、workspace 的物理结构

一个典型的 workspace 目录长这样：

```text
~/workspaces/platform/          ← workspace 根目录（v1.4.0）
  .openspec-workspace/
    view.yaml                   ← 视图状态（名称、links、opener、tools、profile drift）
  changes/                      ← workspace 级 change
    add-task-tracking-provider/
      .openspec.yaml            ← 绑定 workspace-planning schema
      proposal.md
      specs/
        auth/spec.md            ← delta spec（描述跨仓库 change）
      design.md
      tasks.md
```

Workspace 通过 `.openspec-workspace/view.yaml` 中的 `links` 字段关联外部仓库：

```yaml
# view.yaml（简化示例）
name: platform
links:
  api: /Users/alice/projects/platform-api
  web: /Users/alice/projects/platform-web
  mobile: ~/projects/platform-mobile
tools: [claude, cursor]
context:
  store: team-context
  initiative: task-tracking-migration
```

**关键设计**：link 只记录路径关系。Workspace 不会往任何 linked repo 里写文件、改配置、或执行 Git 操作。

## 四、workspace 的数据流

```text
团队共享层
  Context Store（/shared/team-context/）
    └── initiatives/task-tracking-migration/
          ├── requirements.md    ← 跨仓库使命的整体需求
          ├── design.md          ← 架构决策
          └── decisions.md       ← 关键决策记录

本地规划层（每台机器独立）
  Workspace（~/workspaces/platform/）
    ├── view.yaml                ← 本地视图状态
    ├── AGENTS.md                ← workspace 级 agent 指导（workspace open 生成/刷新）
    ├── .code-workspace          ← VS Code 多根工作区（workspace open 生成）
    └── changes/add-task-tracking/      ← workspace 级 change
          ├── proposal.md        ← 跨仓库 change提案
          ├── specs/auth/spec.md ← delta spec
          ├── design.md          ← 跨仓库技术方案
          └── tasks.md           ← 实施任务清单

实现层（linked repos）
  /projects/platform-api/        ← API 仓库
    openspec/
      changes/implement-task-tracking/  ← 仓库级 change（具体实现）
  /projects/platform-web/        ← Web 仓库
    openspec/
      changes/implement-task-tracking/  ← 仓库级 change（具体实现）
```

**关键数据流规则**：

1. **自上而下**：workspace change 定义「要做什么」（What & Why）→ 各 repo change 定义「怎么做」（How）
2. **自下而上**：各 repo archive 后 spec 更新 → workspace 层可感知变化
3. **隔离性**：workspace change 和 repo change 使用不同的 schema（`workspace-planning` vs `spec-driven`），互不干扰

## 五、核心命令工作流

### 5.1 创建 workspace

```bash
# 交互式
openspec workspace setup
# 会引导你：命名 → link 仓库 → 选 opener → 选工具

# 非交互式
openspec workspace setup \
  --no-interactive \
  --name platform \
  --link /path/to/api \
  --link web=/path/to/web \
  --link mobile=/path/to/mobile
```

### 5.2 打开 workspace 上下文

```bash
# 用 Claude Code 打开
openspec workspace open --agent claude

# 用 VS Code 打开（生成 .code-workspace 多根文件）
openspec workspace open --editor

# 绑定 initiative
openspec workspace open --initiative team-context/task-tracking-migration
```

打开时 CLI 会做两件事：
1. 生成/刷新 `AGENTS.md`（workspace 根目录，包含 linked repo 路径、initiative 绑定、编辑边界指导）
2. 生成/刷新 `.code-workspace`（VS Code 多根工作区文件）

### 5.3 创建 workspace 级 change

```bash
# 在 workspace 目录内
cd ~/workspaces/platform
openspec new change add-task-tracking --areas api,web
# --areas 标识哪些 linked repo 受影响
```

这个 change 使用 `workspace-planning` schema，产物落在 workspace 的 `changes/` 目录。

### 5.4 维护 workspace

```bash
# 查看状态
openspec workspace list        # 列出所有 workspace
openspec workspace doctor      # 诊断：哪些 link 路径不对

# 调整链接（比如在新机器上 clone 到了不同位置）
openspec workspace relink api /new/path/to/api

# 同步 skills
openspec workspace update      # 刷新 workspace 级 skill 文件
```

## 六、设计原则

### 6.1 规划与实现分离

| 层面 | 负责什么 | 不负责什么 |
|------|---------|-----------|
| **Workspace** | 跨仓库的变更意图、范围、架构方案 | 不写代码、不改单个仓库的 spec |
| **Linked Repo** | 具体的 spec 变更、代码实现 | 不关心其他仓库在做什么 |

这是 workspace 最核心的设计原则。Workspace 不试图取代 repo 级 OpenSpec，而是在其之上增加一个协调层。

### 6.2 持久存在的协调 home

Workspace 不是为一次跨仓库 change创建的临时目录。它设计为持久存在：

- 一个 workspace 可以容纳多个 change（按时间顺序）
- 一个 workspace 可以绑定不同的 initiative（按需切换 context）
- `view.yaml` 中的 profile drift 状态保持与全局 config 的同步跟踪

### 6.3 本地状态 vs 共享状态

| 类型 | 存储位置 | 例子 |
|------|---------|------|
| **本地状态** | workspace 目录内 | `view.yaml`（link 路径、preferred opener）|
| **本地注册** | `~/.local/share/openspec/workspaces/` | `registry.yaml`（workspace 索引）|
| **共享状态** | context store | initiative（requirements、design、decisions）|

Link 路径是每台机器不同的（`/Users/alice/...` vs `/home/bob/...`），所以不能放 context store。但 link name（`api`、`web`）是全局的，可以作为共享引用。

### 6.4 Workspace guardrail

Workspace 生成的 skill 模板中内置了 guardrail：

```text
当 actionContext.mode === "workspace-planning" 时：
  - 禁止 agent 执行 sync specs（workspace 没有主 spec）
  - 禁止 agent 执行 archive（workspace change 不走 repo archive 流程）
  - 提示 agent：当前在 workspace 上下文中，规划完成后在各 linked repo 中分别落地
```

这确保 AI agent 不会在 workspace 上下文里误用 repo-local 语义。

## 七、与 repo-local OpenSpec 的对比

| | Repo-local OpenSpec | Workspace OpenSpec |
|---|---|---|
| **粒度** | 单个 Git 仓库 | 多个关联仓库 |
| **Schema** | `spec-driven` | `workspace-planning` |
| **Change 位置** | `openspec/changes/` | `changes/`（workspace root） |
| **Specs 位置** | `openspec/specs/`（正式基线） | 无主 spec（spec 在各 repo 中） |
| **Archive** | 有（merge delta → specs） | 无（实现落在各 repo 各自的 archive 中） |
| **Skills 投递** | skills + commands | skills-only（此版本限制） |
| **配置源** | repo 内 config.yaml + global config | global config（profile/delivery/tools） |

## 八、当前限制（v1.4.1）

这不是 workspace 的最终形态。以下是当前明确不支持的：

- Workspace command 生成（skills-only）
- Workspace 级 archive（每个 repo 各自 archive）
- Workspace 间依赖声明
- Workspace 级 CI 集成

这些是设计上预留的空间，但不是 v1.4.x 的目标。

## 九、什么时候该用 workspace

| 场景 | 建议 |
|------|------|
| 单个仓库 | 不需要 workspace，repo-local OpenSpec 足够 |
| 2-3 个关联仓库且偶有跨仓库 change | workspace 有价值，但不是必须 |
| 3+ 仓库且频繁跨仓库协调 | workspace 是推荐的协调层 |
| 团队需要在统一视图下看到跨仓库的变更全景 | workspace + context store 组合 |

## 压缩结论

1. Workspace 是 OpenSpec 唯一的跨仓库规划层——它只管 What/Why，把 How 留给各 repo 的 spec-driven 流程
2. 单仓库不需要 workspace；2-3 个仓库看情况；3+ 仓库且频繁跨仓库协调时才推荐
3. Workspace 没有主 `specs/` 基线——spec 在各 linked repo 中，workspace 只做协调
4. Workspace change 用 `workspace-planning` schema，不走 repo-local 的 archive/sync 流程
5. 这就是 v1.4.0 给 OpenSpec 带来的最大变化——在 repo-local 之外提供了一层跨仓库的规划视图

## 下一步

- 想知道 workspace 的配置层和 repo-local config.yaml 怎么共存 → [04 高级·config-schema-与项目边界](04-高级-config-schema-与项目边界.md)
- 想自定义 workspace 工作流 → [08 高级·自定义 schema](08-高级-自定义-schema-创建自己的工作流.md)
- 多人 + 多 repo 时 workspace 协作怎么落地 → [15 实战·多人协作与 Git 工作流](15-实战-多人协作与Git工作流.md)
