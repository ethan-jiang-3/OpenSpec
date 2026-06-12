# 06 · 自定义 Schema 实战

> 回 [导读](00-map.md)

这一篇给你在落地项目里创建自定义 schema 的完整操作手册。

---

## 三种创建方式

### 方式 1：Fork（推荐新手）

从一个已有 schema 复制，然后修改：

```bash
# 从内置 spec-driven 复制一份到你的项目里
openspec schema fork spec-driven my-workflow
```

产物：
```
openspec/schemas/my-workflow/
├── schema.yaml          # 复制自 spec-driven，你可自由修改
└── templates/
    ├── proposal.md
    ├── spec.md
    ├── design.md
    └── tasks.md
```

然后直接编辑 `schema.yaml` 和 `templates/` 下的文件即可。

如果不指定新名字，默认为 `<source>-custom`：
```bash
openspec schema fork spec-driven
# → 产物：openspec/schemas/spec-driven-custom/
```

### 方式 2：Init（从零建）

```bash
# 交互式
openspec schema init research-first

# 非交互式
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default

# 设为项目默认 + JSON 输出
openspec schema init my-flow --description "Custom" --artifacts "proposal,specs,tasks" --default --json
```

交互式流程会问你：
1. Schema 描述
2. 要包含哪些 artifact（多选：proposal / specs / design / tasks）
3. 是否设为项目默认

### 方式 3：纯手写

直接在 `openspec/schemas/<name>/` 下创建目录和文件：

```bash
mkdir -p openspec/schemas/my-flow/templates
```

然后手写 `schema.yaml` 和模板。

---

## `schema.yaml` 字段完整参考

```yaml
name: my-workflow          # 必需：kebab-case，用于 CLI 引用
version: 1                 # 必需：版本号
description: ...           # 可选：一句话描述

artifacts:                 # 必需：至少一个 artifact
  - id: proposal           # 必需：唯一标识，用于依赖引用和 rules 匹配
    generates: proposal.md # 必需：输出文件名，支持 glob（如 specs/**/*.md）
    description: ...       # 可选：artifact 的简短描述
    template: proposal.md  # 必需：templates/ 下的文件名
    instruction: |         # 必需（建议）：给 AI 的生成指令
      ...
    requires:              # 可选：依赖的 artifact id 列表
      - research

apply:                     # 可选：实现阶段的配置
  requires: [tasks]        # 实现阶段的前置 artifact
  tracks: tasks.md         # 追踪哪个文件判断进度
  instruction: |           # 可选：实现阶段的专属指令
    ...
```

---

## 三个典型自定义 schema 示例

### 例 1：Rapid（极简工作流）

只有 proposal → tasks，跳过 specs 和 design：

```yaml
name: rapid
version: 1
description: 快速迭代——跳过规格和设计，直接从提案到任务

artifacts:
  - id: proposal
    generates: proposal.md
    description: 变更提案
    template: proposal.md
    instruction: |
      写一份简洁的提案：为什么做、做什么、影响什么。
      保持在一页以内。
    requires: []

  - id: tasks
    generates: tasks.md
    description: 实现任务清单
    template: tasks.md
    instruction: |
      基于 proposal 拆分实现任务。每个任务 2 小时内可完成。
      使用 checkbox 格式。
    requires:
      - proposal

apply:
  requires: [tasks]
  tracks: tasks.md
```

依赖图：`proposal → tasks → apply`

### 例 2：Research-first（先调研）

在提案之前加一个调研阶段：

```yaml
name: research-first
version: 1
description: 先调研再提案——适合探索性变更

artifacts:
  - id: research
    generates: research.md
    description: 调研与发现
    template: research.md
    instruction: |
      对问题进行调研分析：
      - 当前状态和痛点
      - 已有方案或类似实现的参考
      - 技术可行性和风险评估
      - 推荐的解决方向（不一定是最终方案）
    requires: []

  - id: proposal
    generates: proposal.md
    description: 基于调研的变更提案
    template: proposal.md
    instruction: |
      基于 research.md 的调研结果，写一份变更提案。
      必须引用调研中的关键发现。
    requires:
      - research

  - id: tasks
    generates: tasks.md
    description: 实现任务
    template: tasks.md
    instruction: |
      基于 proposal 拆分实现任务。
    requires:
      - proposal

apply:
  requires: [tasks]
  tracks: tasks.md
```

依赖图：`research → proposal → tasks → apply`

### 例 3：With-review（加审核关卡）

基于 spec-driven，在 design 之后加一个 review artifact：

```yaml
name: with-review
version: 1
description: spec-driven + 审核步骤

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    instruction: |
      创建提案文档。
    requires: []

  - id: specs
    generates: "specs/**/*.md"
    template: spec.md
    instruction: |
      创建规格文件。
    requires: [proposal]

  - id: design
    generates: design.md
    template: design.md
    instruction: |
      创建技术设计文档。
    requires: [proposal]

  - id: review
    generates: review.md
    description: 实现前审核清单
    template: review.md
    instruction: |
      基于 design 创建审核清单：
      - 安全考虑
      - 性能影响
      - 测试覆盖
      - 回滚方案
    requires:
      - design

  - id: tasks
    generates: tasks.md
    template: tasks.md
    instruction: |
      基于 specs、design 和 review 创建任务清单。
      每个任务需要引用对应的 review 检查项。
    requires:
      - specs
      - design
      - review

apply:
  requires: [tasks, review]
  tracks: tasks.md
  instruction: |
    实现前先确认 review 检查项已全部通过。
```

依赖图：
```text
proposal ──→ specs ──┐
    │                 │
    └──→ design → review ──┐
                     │      │
                     └──→ tasks → apply
```

---

## 校验和调试

### 校验 schema 结构

```bash
# 校验指定 schema
openspec schema validate my-workflow

# 校验所有项目 schema
openspec schema validate

# 详细输出
openspec schema validate my-workflow --verbose

# JSON 格式
openspec schema validate my-workflow --json
```

会检查：
- `schema.yaml` YAML 语法
- 所有必需字段（name, version, artifacts）
- 所有 `template` 引用的文件是否存在
- 依赖图是否有循环依赖
- artifact id 是否合法

### 查看解析来源

```bash
# 这个 schema 从哪加载的？
openspec schema which my-workflow

# 列出所有可用 schema
openspec schema which --all
```

### 查看 AI 实际收到的指令

```bash
# 看某个 artifact 的完整 prompt
openspec instructions proposal --json | jq '.'
```

---

## 两种存放位置

| 位置 | 路径 | 适用场景 |
|------|------|---------|
| 项目级 | `openspec/schemas/<name>/` | 团队共享、需要版本控制（推荐） |
| 用户级 | `~/.local/share/openspec/schemas/<name>/` | 个人跨项目复用 |

---

## 使用自定义 schema

```bash
# 方法 1：CLI flag（优先级最高）
openspec new change feature --schema my-workflow

# 方法 2：在 config.yaml 设为项目默认
# schema: my-workflow

# 方法 3：在 workspace 中显式指定
```

创建 change 后，子目录里会自动写 `.openspec.yaml` 绑定这个 schema：

```yaml
schema: my-workflow
created: 2026-04-20
```

之后这个 change 就永远走 `my-workflow`，不受项目默认值变更影响。
