# 07 · 定制化（Customization）

> 回 [导读](00-index.md) · [FAQ](FAQ.md)

从最轻量（项目 `config.yaml`）到最重度（自定义 schema）的定制方式，以及管理它们的 CLI 命令。

## 目录

- [§1 项目 config：`openspec/config.yaml`](#1-项目-config-openspecconfigyaml)
- [§2 自定义 Schema](#2-自定义-schema)
- [§3 Schema 解析优先级](#3-schema-解析优先级)
- [§4 Schema 管理 CLI：`openspec schema`](#4-schema-管理-cli-openspec-schema)
- [§5 全局 Config CLI：`openspec config`](#5-全局-config-cli-openspec-config)

---

## §1 项目 config：`openspec/config.yaml`

这是最轻量的定制方式——不用自己写 schema，只通过配置文件往 AI 的提示里注入**项目上下文**和**per-artifact 规则**。

文件位置：`<your-project>/openspec/config.yaml`（`.yml` 不行，必须 `.yaml`）。

### 三个字段

```yaml
# openspec/config.yaml
schema: spec-driven           # 默认 schema

context: |
  Tech stack: TypeScript, React, Node.js
  API conventions: RESTful, JSON responses
  Testing: Vitest for unit tests, Playwright for e2e
  Style: ESLint with Prettier, strict TypeScript

rules:
  proposal:
    - Include rollback plan
    - Identify affected teams
  specs:
    - Use Given/When/Then format for scenarios
  design:
    - Include sequence diagrams for complex flows
```

| 字段 | 类型 | 作用 |
|------|------|------|
| `schema` | string | 新 change 默认用哪个 schema |
| `context` | string | 所有 artifact 共用的项目上下文 |
| `rules` | object | 按 artifact id 分组的额外规则 |

### 注入机制

当 agent 调 `openspec instructions <artifact>` 拿提示时，返回内容按这个结构拼：

```xml
<context>
Tech stack: TypeScript, React, Node.js
...（来自 config.yaml 的 context）
</context>

<rules>
- Include rollback plan
- Identify affected teams
...（只注入匹配当前 artifact id 的 rules）
</rules>

<template>
[schema 的 built-in 模板]
</template>
```

- **`context` 对所有 artifact 都注入**
- **`rules` 只对匹配 artifact id 的注入**（`rules.proposal` 只给 proposal 用）

### 限制和校验

| 规则 | 说明 |
|------|------|
| `context` 最大 50KB | 超了要摘要或拆到外部文档 |
| 未知的 artifact id 在 `rules` | 产生 warning（不报错） |
| schema 名字 | 会按 schema resolution 顺序查，找不到报错 |
| YAML 语法错误 | 会带行号 |

### 支持的 artifact id（`spec-driven` schema）

- `proposal`
- `specs`
- `design`
- `tasks`

用 `openspec schemas --json` 看其它 schema 的 artifact id。

### 怎么创建

```bash
# 方法 1：init 时交互创建
openspec init
# 会问要不要建 config，按提示填

# 方法 2：手动写
cat > openspec/config.yaml <<EOF
schema: spec-driven
context: |
  Tech stack: ...
rules:
  proposal:
    - ...
EOF
```

**改动立即生效**，不需要重启 agent 或 `openspec update`。

### 排查

| 症状 | 原因 |
|------|------|
| `Unknown artifact ID in rules: X` | 检查 artifact id 是否匹配 schema；用 `openspec schemas --json` 看 |
| config 没生效 | 确认文件叫 `config.yaml` 不是 `.yml` |
| context 太大 | 压到 50KB 以内 |

### 和**全局**（`openspec config`）配置的区别

| 层级 | 存哪里 | 控制什么 |
|------|--------|---------|
| **项目 config** | `openspec/config.yaml` | schema / context / rules（注入到提示） |
| **全局 config** | 用户目录（`openspec config path` 看） | profile / delivery / 选哪些 workflow / 遥测 |

两者**正交**，都要掌握。

---

## §2 自定义 Schema

想要一套**完全不一样的工作流**（比如先 research 再 propose、加一个 review artifact、删掉 design），就得自己写 schema。

### 两种创建方式

#### 1. Fork 现有的（推荐新手）

```bash
openspec schema fork spec-driven my-workflow
```

产物：

```
openspec/schemas/my-workflow/
├── schema.yaml               # 复制自 spec-driven
└── templates/
    ├── proposal.md
    ├── spec.md
    ├── design.md
    └── tasks.md
```

直接改 YAML 和模板就行。

#### 2. 从零建

```bash
# 交互式
openspec schema init research-first

# 非交互
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

### `schema.yaml` 字段

```yaml
name: my-workflow
version: 1
description: My team's custom workflow

artifacts:
  - id: proposal
    generates: proposal.md
    description: Initial proposal document
    template: proposal.md
    instruction: |
      Create a proposal that explains WHY this change is needed.
      Focus on the problem, not the solution.
    requires: []

  - id: design
    generates: design.md
    description: Technical design
    template: design.md
    instruction: |
      Create a design document explaining HOW to implement.
    requires:
      - proposal

  - id: tasks
    generates: tasks.md
    description: Implementation checklist
    template: tasks.md
    requires:
      - design

apply:
  requires: [tasks]
  tracks: tasks.md
```

### 字段说明

| 字段 | 作用 |
|------|------|
| `id` | 唯一标识，用于命令和 rules |
| `generates` | 产物文件名，支持 glob（`specs/**/*.md`） |
| `template` | `templates/` 下的文件名 |
| `instruction` | 注入到 agent 提示里的写作指令 |
| `requires` | 依赖列表（必须都 done 才能进入 ready） |

### 模板文件

`templates/<name>.md`，可以包含：
- 节标题（AI 来填内容）
- HTML 注释作为给 AI 的提示
- 示例格式

例：

```markdown
<!-- templates/proposal.md -->
## Why

<!-- Explain the motivation for this change. What problem does this solve? -->

## What Changes

<!-- Describe what will change. Be specific about new capabilities or modifications. -->

## Impact

<!-- Affected code, APIs, dependencies, systems -->
```

### 校验

写完了就跑一下：

```bash
openspec schema validate my-workflow
```

会检查：
- `schema.yaml` 语法
- 所有 `template:` 引用的文件都存在
- 没有循环依赖
- artifact id 合法

### 使用

```bash
# 方法 1：CLI flag（优先级最高）
openspec new change feature --schema my-workflow

# 方法 2：在 openspec/config.yaml 设为默认
# schema: my-workflow
```

新建 change 后，子目录里会自动写 `.openspec.yaml` 绑定这个 schema：

```yaml
schema: my-workflow
created: 2025-04-20
```

### 三个典型例子

#### 例 1：Rapid（最小工作流）

适合快速迭代，跳过 specs 和 design：

```yaml
name: rapid
artifacts:
  - id: proposal
    generates: proposal.md
    requires: []
  - id: tasks
    generates: tasks.md
    requires: [proposal]

apply:
  requires: [tasks]
  tracks: tasks.md
```

依赖图：`proposal → tasks`

#### 例 2：Research-first（先调研再提案）

```yaml
name: research-first
artifacts:
  - id: research
    generates: research.md
    requires: []

  - id: proposal
    generates: proposal.md
    requires: [research]

  - id: tasks
    generates: tasks.md
    requires: [proposal]
```

依赖图：`research → proposal → tasks`

#### 例 3：With-review（加审核步骤）

基于 `spec-driven` fork，加一个 review artifact：

```yaml
artifacts:
  # ... spec-driven 原有的 proposal / specs / design ...

  - id: review
    generates: review.md
    description: Pre-implementation review checklist
    template: review.md
    instruction: |
      Create a review checklist based on the design.
      Include security, performance, and testing considerations.
    requires:
      - design

  - id: tasks
    generates: tasks.md
    template: tasks.md
    requires:
      - specs
      - design
      - review    # 多了一个依赖
```

### 两种存放位置

- **项目级**：`openspec/schemas/<name>/`（推荐，随代码版本化）
- **用户级**：`~/.local/share/openspec/schemas/<name>/`（跨项目复用）

项目级优先级更高（见下一节 [§3](#3-schema-解析优先级)）。

---

## §3 Schema 解析优先级

OpenSpec 需要一个 schema 时，按优先级从高到低查。

### 优先级 1：决定用哪个 schema 名字

当用户执行命令（比如 `/opsx:new`），选哪个 schema 名字按下面顺序找（高到低）：

```
1. CLI flag            --schema <name>
2. Change 元数据       openspec/changes/<name>/.openspec.yaml 的 schema 字段
3. 项目 config         openspec/config.yaml 的 schema 字段
4. 默认                spec-driven
```

**例子**：

```bash
# 强制用 rapid（第 1 级）
openspec new change my-feature --schema rapid

# 没 flag 就查 change 自己的 .openspec.yaml（第 2 级）
openspec continue my-feature
# → 读 openspec/changes/my-feature/.openspec.yaml

# 都没的话，读项目 config（第 3 级）
# → 读 openspec/config.yaml 的 schema:
```

### 优先级 2：决定 schema 名字从哪里加载

确定了 schema 名字后（比如 `my-workflow`），按下面顺序找实际文件：

```
1. 项目            openspec/schemas/my-workflow/
2. 用户            ~/.local/share/openspec/schemas/my-workflow/
3. 包内置          <npm-install>/schemas/my-workflow/
```

可以用 `openspec schema which` 看：

```bash
openspec schema which spec-driven
# 输出：
# spec-driven resolves from: package
#   Source: /usr/local/lib/node_modules/@fission-ai/openspec/schemas/spec-driven

openspec schema which my-workflow
# 输出：
# my-workflow resolves from: project
#   Source: /path/to/project/openspec/schemas/my-workflow

openspec schema which --all
# 列出所有 schema 和各自来源
```

### 为什么是这个顺序

- **项目** 最高——同名 schema 可以覆盖用户级 / 包内置，让团队对仓库内的工作流有完全控制
- **用户** 其次——跨项目共享（比如个人偏好的 schema）
- **包** 最后——给一个保底的 `spec-driven`

### 实战建议

| 场景 | 推荐位置 |
|------|---------|
| 团队共享、需要版本控制 | 项目级（`openspec/schemas/`） |
| 个人跨项目复用 | 用户级（`~/.local/share/openspec/schemas/`） |
| 公共贡献回 npm | 发 PR 到 [schemas/](../schemas/) 目录 |

---

## §4 Schema 管理 CLI：`openspec schema`

管理**自定义 workflow schema** 的四个子命令。源码在 [src/commands/schema.ts](../src/commands/schema.ts)。

Schema 是什么、为什么这么叫，见 [03-concepts.md §3](03-concepts.md#3-schema-是什么为什么这么叫)。

### `openspec schema init`

从零创建一个项目 schema。

```
openspec schema init <name> [options]
```

#### 选项

| 选项 | 说明 |
|------|------|
| `--description <text>` | schema 描述 |
| `--artifacts <list>` | 逗号分隔的 artifact ID（默认 `proposal,specs,design,tasks`） |
| `--default` | 设为项目默认 schema |
| `--no-default` | 不问设为默认 |
| `--force` | 覆盖已存在的 schema |
| `--json` | JSON 输出 |

#### 示例

```bash
# 交互式
openspec schema init research-first

# 非交互 + 指定 artifact + 设为默认
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

#### 产物

```
openspec/schemas/<name>/
├── schema.yaml
└── templates/
    ├── proposal.md
    ├── specs.md
    ├── design.md
    └── tasks.md
```

### `openspec schema fork`

复制一份已有 schema 做定制。

```
openspec schema fork <source> [name] [options]
```

#### 选项

| 选项 | 说明 |
|------|------|
| `--force` | 覆盖目标 |
| `--json` | JSON 输出 |

#### 示例

```bash
# fork 内置 spec-driven 到项目里
openspec schema fork spec-driven my-workflow

# 不指定新名字时默认 <source>-custom
openspec schema fork spec-driven
# → 产出 spec-driven-custom
```

### `openspec schema validate`

校验 schema 的 YAML 结构 + 模板引用是否齐全。

```
openspec schema validate [name] [options]
```

#### 选项

| 选项 | 说明 |
|------|------|
| `--verbose` | 打印详细校验步骤 |
| `--json` | JSON 输出 |

#### 示例

```bash
# 校验指定 schema
openspec schema validate my-workflow

# 不带名字 = 校验所有 schema
openspec schema validate
```

校验内容：
- `schema.yaml` 语法对不对
- 每个 `template` 字段指向的文件是否存在
- 有没有循环依赖
- artifact ID 合法

### `openspec schema which`

看某个 schema 从哪个来源解析出来的，用来调试优先级问题。

```
openspec schema which [name] [--all] [--json]
```

#### 示例

```bash
# 看单个
openspec schema which spec-driven

# 列出全部 schema 和它们的来源
openspec schema which --all
```

#### 输出

```
spec-driven resolves from: package
  Source: /usr/local/lib/node_modules/@fission-ai/openspec/schemas/spec-driven
```

来源三种：
1. **project** — `openspec/schemas/<name>/`（最高优先级）
2. **user** — `~/.local/share/openspec/schemas/<name>/`
3. **package** — npm 包内置

---

## §5 全局 Config CLI：`openspec config`

`openspec config` 及其子命令管理**全局**（用户级）OpenSpec 配置。源码 [src/commands/config.ts](../src/commands/config.ts)。

> 全局 config 和**项目 config**（`openspec/config.yaml`）不是一回事。项目 config 见 [§1](#1-项目-config-openspecconfigyaml)。

### 子命令总表

| 子命令 | 作用 |
|--------|------|
| `path` | 显示 config 文件位置 |
| `list` | 列出所有当前设置 |
| `get <key>` | 获取单个值 |
| `set <key> <value>` | 设置值 |
| `unset <key>` | 删除 key |
| `reset` | 重置默认 |
| `edit` | 用 `$EDITOR` 打开编辑 |
| `profile [preset]` | 交互式或预设配置 profile |

### 常用示例

```bash
# 查看 config 文件路径
openspec config path

# 列出所有设置
openspec config list

# 读取某个值
openspec config get telemetry.enabled

# 关掉遥测
openspec config set telemetry.enabled false

# 字符串值要显式
openspec config set user.name "My Name" --string

# 删自定义值
openspec config unset user.name

# 重置全部
openspec config reset --all --yes

# 编辑器打开
openspec config edit
```

### 重点：`openspec config profile`

这是配置 **workflow 选择** + **delivery 模式** 的入口。

#### 交互式

```bash
openspec config profile
```

进入后按菜单：
1. **Change delivery + workflows** — 都改
2. **Change delivery only** — 只改 delivery 模式（both / skills / commands）
3. **Change workflows only** — 只勾选要启用哪些 workflow
4. **Keep current settings** — 退出不改

`Ctrl+C` 可以干净退出（exit code 130，无 stack trace）。

#### 预设快捷

```bash
# 直接切到 core（4 个 workflow，不动 delivery）
openspec config profile core
```

#### 工作流勾选 UI

进入 workflow checklist 时，`[x]` 表示**已在全局 config 里启用**。切换后要真正生效，还得 `openspec update` 去项目里重生成文件，否则会 drift（drift 检测代码在 [src/core/profile-sync-drift.ts](../src/core/profile-sync-drift.ts)）。

#### 三种 delivery 模式

| delivery 值 | 装什么 |
|-------------|--------|
| `both`（默认） | skills + commands 都装 |
| `skills` | 只装 skills |
| `commands` | 只装 commands |

### ALL_WORKFLOWS 的 11 个可勾选值

- `propose`、`explore`、`apply`、`archive`（core 默认含）
- `new`、`continue`、`ff`、`sync`、`bulk-archive`、`verify`、`onboard`（扩展）

定义在 [src/core/profiles.ts](../src/core/profiles.ts)。
