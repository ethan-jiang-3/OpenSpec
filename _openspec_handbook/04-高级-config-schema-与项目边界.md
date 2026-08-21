# 04 · 高级：Config、Schema 与项目边界

> 这一篇默认你已经理解了 `specs`、`changes`、artifact 和 delta spec。

---

## 这一层为什么容易乱

因为到了这里，你会同时遇到几类"看起来都像约定"的东西：

- `openspec/specs/`
- `openspec/config.yaml`
- `openspec/schemas/<name>/schema.yaml`
- `openspec/changes/<name>/.openspec.yaml`
- `core` / `custom` profile

如果这些边界没分开，就很容易把所有东西混在一起。

---

## 先一句话钉死 4 个对象

```mermaid
graph TB
    subgraph 项目层
    A["openspec/specs/<br/>（正式 spec 基线）"]
    B["openspec/config.yaml<br/>（项目级提示背景）"]
    C["openspec/schemas/<br/>（工作流骨架定义）"]
    end
    
    subgraph 单次 change 层
    D["openspec/changes/&lt;name&gt;/<br/>（一次 change）"]
    E[".openspec.yaml<br/>（绑定哪套 schema）"]
    end
    
    B -.提供背景.-> D
    C -.定义结构.-> D
    E -.选择.-> C
    D -.archive 后 merge.-> A
    
    style A fill:#e8f5e9,stroke:#4caf50
    style B fill:#fff3e0,stroke:#ff9800
    style C fill:#e1f5fe,stroke:#03a9f4
    style D fill:#f3e5f5,stroke:#9c27b0
```

| 对象 | 它真正管什么 | 类比 |
|------|--------------|------|
| `openspec/specs/` | 项目当前已经成立的行为合同 | 代码库的"当前版本" |
| `openspec/config.yaml` | 项目级提示背景、规则、默认 schema | 项目的"README + 编码规范" |
| `openspec/schemas/<name>/schema.yaml` | change 的结构骨架和 artifact 依赖 | 工作流的"模板定义" |
| `openspec/changes/<name>/.openspec.yaml` | 这次 change 最终绑定哪套 schema | 这次工作的"配置文件" |

最重要的一句，再说一遍：

> **`config.yaml` 改的是提示层，`schema` 改的是结构层。**

---

## `config.yaml` 到底应该装什么

最适合放进去的，是"稳定、跨 change、高价值"的项目背景。

比如：

- 技术栈
- 测试约定
- 发布或兼容性要求
- 对某类 artifact 的统一补充规则

一个典型例子：

```yaml
schema: spec-driven

context: |
  Tech stack: TypeScript, React, Node.js
  Testing: Vitest + Playwright
  Public APIs should remain backward compatible.

rules:
  proposal:
    - Include rollback plan
  specs:
    - Add unhappy-path scenarios
  design:
    - Explain migration risk

operations:
  apply:
    guidance:
      - Run the relevant checks before marking a task complete.
  archive:
    guidance:
      - Review migration/rollback evidence before archive.
```

**注意**：OpenSpec 的 rules 使用**结构化格式**（按 artifact 分类），不支持纯文本格式。v1.8.0（v1.7.0 起）的 Apply/Archive 不是 artifact rule consumers：它们读取 project `context` 以及 `operations.apply/archive.guidance`；`rules.apply` / `rules.archive` 不会成为 operation 指令。

### config.yaml vs schema：对比表

| 维度 | config.yaml | schema |
|------|-------------|--------|
| **改的是什么层** | 提示层（告诉 AI 项目背景） | 结构层（定义 change 骨架） |
| **典型内容** | 技术栈、测试约定、artifact rules、Apply/Archive guidance | artifact 种类、依赖关系、模板路径 |
| **影响范围** | 所有 change 的生成质量 | change 的结构和工作流 |
| **修改频率** | 偶尔（项目技术栈变化时） | 很少（工作流模式变化时） |
| **类比** | 项目的 README | 项目的 Makefile 或 package.json scripts |

### 不适合往里塞什么

不要把这些东西硬塞进 `config.yaml`：

- 某一次 change 的临时说明
- 项目当前完整能力清单、完整 taxonomy 或 main spec 正文
- artifact 依赖关系
- 模板正文
- 工具入口配置

这些都不是它的职责。

### capability catalog 放哪里，AGENTS 和 config 又各做什么？

当 main specs 开始变多时，常见的错误是把所有 capability path、完整 Purpose 和 requirement 摘要塞进 `context`。这样每次生成都会带一份会过期的“第二基线”，既浪费上下文，也会和真正的 `specs/` 争夺权威。

正确分层如下：

| 内容 | 推荐位置 | 谁消费 | 不能替代什么 |
|---|---|---|---|
| 当前行为合同与 scenarios | `openspec/specs/<path>/spec.md` | 人、agent、archive | catalog 或 config 不是行为真相 |
| path、Purpose、关键词、边界的薄索引 | `openspec/specs/README.md` 或专门 catalog | Explore/Propose 的 discovery | 不复制完整 requirements |
| 如何命名 path、先查 catalog、何时可迁移 | `AGENTS.md` | 项目中的 agent 与 reviewer | 不替代 schema/validator |
| 跨全部 change 的短原则 | `config.yaml` 的 `context` / artifact `rules` | artifact 生成；operation guidance 另给 Apply/Archive | 不放全量 capability 列表 |

一个团队真正需要写进 config 的不是“我们的所有 capabilities 是 A、B、C”，而是类似“capability path 遵循 AGENTS 中的约定；main spec 是行为真相，catalog 只用于导航；结构迁移必须单独 rebaseline”这样的稳定原则。有关 catalog 的最小格式和 discovery 流程，看 [09](09-高级-能力身份与specs漂移维护.md)。

### 写一条配置前，先说出“谁会消费它”

`config.yaml` 不是所有阶段共享的万能 prompt。把正确内容放进错误 consumer，效果仍等于没有配置。内置 `spec-driven` 在 v1.8.0（v1.7.0 起）的路由是：

| 阶段 | 自动拿到什么 | 这意味着什么 |
|---|---|---|
| Explore | project `context` + artifact `rules` | 没有 `operations.explore`；复杂探索步骤放 workflow skill、AGENTS 或 playbook |
| proposal / specs / design / tasks | `context` + 当前 artifact ID 的 `rules` + schema 依赖 artifacts | rule key 必须是当前 schema 的真实 artifact ID |
| Apply | `context` + `operations.apply.guidance` + 当前落盘 artifacts | 不会收到 `rules.tasks` 等 artifact rules；结构 gate 仍由 schema / task / check 负责 |
| Archive | `context` + `operations.archive.guidance` + tasks/delta/status | 不会收到 artifact rules；prompt 不能改变确定性 merge |

因此，写配置时可用这条归位顺序：

```text
所有 planning artifact 都需要的短稳定事实  -> context
一个 artifact 的长期写作/审查约束          -> rules.<artifact-id>
Apply / Archive 的短稳定步骤                 -> operations.<operation>.guidance
本次分类、范围、决定、证据                   -> change artifacts
新的 artifact、依赖、gate、输出结构          -> schema / template / workflow skill
必须不可绕过的事实                            -> validator / test / lint / CI
```

别发明 `operations.explore`、`apply_rules` 或通用顶层 `guidance`：当前 parser 不会把这些字段变成新的运行时能力。

### “我改了 config，为什么没生效？”的最短排查

在继续加规则前，按固定顺序查：**生效 root → 生效 config 文件 → 当前 change schema → 目标 consumer → rendered instructions → artifacts / 确定性检查**。

```bash
openspec instructions proposal --change <change> --json
openspec instructions apply --change <change> --json
openspec instructions archive --change <change> --json
openspec status --change <change> --json
```

前三条分别用来确认 artifact `rules`、apply guidance、archive guidance 是否出现在正确位置；最后一条确认实际 schema 和 artifact 状态。还要记住：同根同时有 `config.yaml` 与 `config.yml` 时前者优先；已有 change 的 `.openspec.yaml` 中 schema 名称优先于后来改掉的项目默认 schema。完整诊断表见 FAQ 13 的 [`02-diagnose-maintain-config-yaml.md`](../_faq_on_digested/13_how_to_design_maintain_config_yaml/02-diagnose-maintain-config-yaml.md)。

### 常见配置错误示例

**❌ 太空（没有实质内容）：**
```yaml
schema: spec-driven
context: "This is a web project."
```
问题：AI 无法从中获得有用信息。

**❌ 太少（该写的没写）：**
```yaml
schema: spec-driven
```
问题：AI 不知道技术栈、测试约定、兼容性要求。

**✅ 恰到好处：**
```yaml
schema: spec-driven
context: |
  Tech: TypeScript + React + tRPC
  Testing: Vitest (unit) + Playwright (e2e)
  DB: Prisma + PostgreSQL
  Deployment: Vercel
  Compatibility: Support last 2 major versions
rules:
  specs:
    - Include error scenarios
  design:
    - Explain DB migration strategy if schema changes
```

---

## schema 到底是什么

schema 不是数据库 schema，也不只是 template。

更准确地说，它是：

> **一次 change 应该长成什么样的工作流骨架。**

它定义的通常是：

- 有哪些 artifact
- 各自生成什么文件
- 谁依赖谁
- apply 追踪哪份文件

默认的 **`spec-driven`** schema 看起来像这样。它就是 `config.yaml` 里 `schema: spec-driven` 指向的那个——定义 artifact DAG、delta 操作、以及 proposal↔specs 的能力契约，是背后的 driver。capability 身份是 `specs/` 下的相对 path（可嵌套），见 [`09-高级-能力身份与specs漂移维护`](09-高级-能力身份与specs漂移维护.md)：

```yaml
artifacts:
  - id: proposal
    generates: proposal.md
    requires: []

  - id: specs
    generates: specs/**/*.md
    requires: [proposal]

  - id: design
    generates: design.md
    requires: [proposal]

  - id: tasks
    generates: tasks.md
    requires: [specs, design]
```

所以 schema 说的不是"这个项目用 React 还是 Vue"。
它说的是"这类 change 应该先有哪些产物，它们怎么关联"。

---

## template 和 schema 的关系

这两个词也特别容易混。

### template 是什么

template 是某个 artifact 的文本骨架。

比如 proposal 模板可能只是：

```markdown
## Why
## What Changes
## Impact
```

### schema 是什么

schema 决定：

- 有没有 `proposal` 这个 artifact
- 它依赖谁
- 生成到哪里
- 用哪个 template
- 配什么 instruction

所以：

- template 更像"单个文档的写法骨架"
- schema 更像"整套 change 结构的定义"

---

## `.openspec.yaml` 为什么关键

这个文件在 change 目录里，是每次 change 的元数据。完整字段：

| 字段 | 必填 | 用途 |
|------|------|------|
| `schema` | 是 | 绑定到哪套工作流 schema |
| `created` | 否 | 创建日期（`YYYY-MM-DD`） |
| `goal` | 否 | 一句话描述这次 change 的目标 |
| `affected_areas` | 否 | 涉及的代码区域列表 |
| `initiative` | 否 | 关联的 initiative（`{store, id}`） |
| `skip_specs` | 否 | 声明本次无 spec 级行为变更（纯重构/工具/文档），设为 `true` 时 validator 接受零 delta |

其中最核心的是 `schema`：

- 它让单次 change 可以偏离项目默认 schema
- 项目默认可以在 `config.yaml` 里写 `schema: spec-driven`，但某个特殊 change 可以用另一套

所以 change 的实际解析顺序，通常会优先看 change 自己，再回退到项目默认。

v1.10.0 还会在**当前 schema 根本不产生 specs artifact**时，由 `openspec new change` 自动写入：

```yaml
schema: docs-only
skip_specs: true
```

CLI 会把 `./specs/`、`specs/` 与 Windows separator 等价归一后再判断，因此 schema 作者不必为了“让 spec-driven validator 满意”伪造一个 specs artifact，也不必手工补 marker。反过来，schema 有 specs 输出但某个 change 恰好没有行为变化时，仍由作者明确声明；有真实行为变化时不能借 marker 绕过 delta。

---

## profile 又是什么

profile 和 schema 不是一回事。

### profile 管什么

profile 管的是：

- 你装哪些 workflow 命令
- 默认是 core 6 个，还是更多扩展动作

### schema 管什么

schema 管的是：

- 一次 change 内部有哪些 artifact
- 它们的结构和依赖是什么

一句话区分：

- **profile 管入口多少**
- **schema 管 change 长相**

### 新手最常问：profile 和 schema 到底什么关系？

用一个具体例子理解：

**场景**：你想用 OpenSpec，但只想要最简单的工作流。

1. **选 profile**：`openspec config profile` 选 `core` 或 `custom`
   - core：你只有 6 个命令（propose/explore/apply/update/sync/archive）
   - custom：自选命令（可以额外启用 new/continue/ff/verify/bulk-archive/onboard 等）
   - 这是"入口层"的选择

   v1.10.0 会展开 custom profile 的依赖：若选择 `archive` 或 `bulk-archive` 却漏了 `sync`，CLI 会在第一个依赖它的 workflow 前自动插入 `sync`；已有 `sync` 时不重复、不重排。例如 `[verify, archive]` 解析为 `[verify, sync, archive]`。这不会把 custom 降级成 core，也不会自动加入其他 core workflows。

**⚠️ 警告**：
- 切换 profile 可能会删除或添加 workflow 文件
- 从 custom 切换回 core 会删除额外的 workflow 文件
- 切换前确保你理解影响，建议先提交当前更改

2. **选 schema**：在 `config.yaml` 里写 `schema: spec-driven`
   - 结果：每个 change 都有 proposal/specs/design/tasks 四个 artifact
   - 这是"结构层"的选择

**关系**：
- profile 决定"你能用哪些命令"
- schema 决定"每个 change 长什么样"
- 它们是独立的两个维度

**类比**：
- profile 像"你的工具箱有哪些工具"
- schema 像"你用这些工具做出来的东西是什么形状"

---

## 这一层最重要的边界意识

到了高级阶段，你最需要的不是"记住所有字段"，而是以下判断力：

### 什么时候改 `config.yaml`

当你想补的是：

- 项目统一背景
- 项目统一写作约束
- 默认 schema 选择

### 什么时候改 schema

当你想改的是：

- artifact 种类
- artifact 依赖关系
- apply 的前置条件
- 模板和 instruction 的组织方式

### 什么时候看 store

当你遇到的是：

- 当前 repo 的 change 需要发现另一个**已 checkout**仓库的正式 specs
- 项目希望以 `references:` 声明这个跨 repo 的只读引用
- 你需要确认 root/store 解析到哪里，而不是把外部 spec 复制进本地 `context`

这时才需要看 store。它不创建系统级 planning home、不会管理跨 repo change，也不是本地 specs 变多后的默认答案；后者先看 [09](09-高级-能力身份与specs漂移维护.md)。

---

## 补充：跨仓库 — store 层

多仓库场景下，项目可以通过 store 机制引用其他仓库的 specs：

- `openspec store register` 全局注册仓库 checkout
- `openspec/config.yaml` 的 `references:` 声明依赖
- `openspec context` 查看 working set（默认纯查询；只有显式传 `--code-workspace` 才写 workspace 文件）

store 不创建新的 schema、不改变 change 生命周期。所有 change 仍在具体 repo 下，使用 `spec-driven`。跨仓库场景参考 [07](07-高级-store-跨仓库协同.md)。

---

## 压缩结论

1. `config.yaml` 管提示背景，`schema` 管结构骨架——改前者是补项目常识，改后者是改工作流形态
2. `.openspec.yaml` 是 change 级绑定点，让单次 change 可以偏离项目默认 schema
3. profile 管命令入口多少，schema 管 change 长什么样——两个独立维度
4. store 是多仓库场景的上下文引用机制，单仓库用不着
5. 判断力比记住所有字段重要：什么时候改 config、什么时候改 schema、什么时候看 store

---
