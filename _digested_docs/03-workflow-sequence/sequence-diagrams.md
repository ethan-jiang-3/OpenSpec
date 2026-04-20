# 命令次序流程图

## 1. Core 路径（默认）

```mermaid
flowchart LR
    explore["/opsx:explore<br/>(可选前置思考)"]
    propose["/opsx:propose<br/>一次性生成 proposal/specs/design/tasks"]
    apply["/opsx:apply<br/>读 tasks.md，写代码"]
    archive["/opsx:archive<br/>合并 delta + 归档"]

    explore -.可选.-> propose
    propose --> apply
    apply --> archive
```

**典型会话**：
```text
/opsx:explore                → 先想清楚（不产文件）
/opsx:propose add-dark-mode  → 自动生成四件套
/opsx:apply                  → 写代码
/opsx:archive                → 搬到 changes/archive/
```

## 2. Expanded 路径（完整 11 个命令）

```mermaid
flowchart LR
    explore["/opsx:explore"]
    new["/opsx:new<br/>只搭骨架"]
    ff["/opsx:ff<br/>一次生成全部"]
    cont["/opsx:continue<br/>一次生成一个"]
    apply["/opsx:apply"]
    verify["/opsx:verify<br/>三维度验证"]
    sync["/opsx:sync<br/>(通常不需要)"]
    archive["/opsx:archive"]
    bulkArchive["/opsx:bulk-archive<br/>批量归档多个"]
    onboard["/opsx:onboard<br/>新手引导，串联整条链"]

    explore -.-> new
    new --> ff
    new --> cont
    ff --> apply
    cont --> apply
    cont -.迭代.-> cont
    apply --> verify
    verify --> archive
    verify -.可选.-> sync
    sync --> archive
    archive -.-> bulkArchive

    onboard -.教学模式.-> new
```

## 3. Artifact 依赖 DAG（`spec-driven` schema）

这是 artifact 之间的 **依赖**，不是命令执行顺序。依赖是 enabler，不是 gate——解锁后你想什么时候建都行。

```mermaid
flowchart TB
    proposal[proposal.md<br/>requires: 无]
    specs["specs/**/*.md<br/>requires: [proposal]"]
    design[design.md<br/>requires: proposal]
    tasks["tasks.md<br/>requires: [specs, design]"]
    implement[implement<br/>requires: tasks]

    proposal --> specs
    proposal --> design
    specs --> tasks
    design --> tasks
    tasks --> implement
```

**特性**：
- `specs` 和 `design` 可以**并行**建（都只依赖 proposal）
- `tasks` 必须等 specs 和 design 都 done 才 ready
- 整个 apply 阶段需要 `tasks` 存在

## 4. Artifact 状态机

```mermaid
stateDiagram-v2
    [*] --> BLOCKED: 依赖未完成
    BLOCKED --> READY: 所有依赖 done
    READY --> DONE: 文件已在磁盘
    DONE --> READY: 用户删了文件
```

状态判定源码在 [src/core/artifact-graph/state.ts](../../src/core/artifact-graph/state.ts)，核心逻辑是**看文件系统里有没有对应产物**（`generates` 字段指定的 glob），而不是依靠某种阶段标记。

## 5. 归档生命周期

```mermaid
flowchart LR
    active["openspec/changes/add-auth/"]
    synced["delta spec<br/>merge 到 openspec/specs/"]
    archived["openspec/changes/archive/<br/>2026-04-20-add-auth/"]

    active --> synced
    synced --> archived
```

- `/opsx:sync` 只做左边这步（合并 delta 但不搬目录）
- `/opsx:archive` 默认做两步（会问你是否先 sync）
- `/opsx:bulk-archive` 同时对多个 change 做这个事，会检测冲突
