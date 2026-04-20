# 03 · 高级：Config、Schema 与项目边界

> 这一篇默认你已经理解了 `specs`、`changes`、artifact 和 delta spec。

---

## 这一层为什么容易乱

因为到了这里，你会同时遇到几类“看起来都像约定”的东西：

- `openspec/specs/`
- `openspec/config.yaml`
- `openspec/schemas/<name>/schema.yaml`
- `openspec/changes/<name>/.openspec.yaml`
- `core` / `custom` profile

如果这些边界没分开，就很容易什么都往一个地方理解。

---

## 先一句话钉死 4 个对象

| 对象 | 它真正管什么 |
|------|--------------|
| `openspec/specs/` | 项目当前已经成立的行为合同 |
| `openspec/config.yaml` | 项目级提示背景、规则、默认 schema |
| `openspec/schemas/<name>/schema.yaml` | change 的结构骨架和 artifact 依赖 |
| `openspec/changes/<name>/.openspec.yaml` | 这次 change 最终绑定哪套 schema |

最重要的一句可以再说一遍：

> **`config.yaml` 改的是提示层，`schema` 改的是结构层。**

---

## `config.yaml` 到底应该装什么

最适合放进去的，是“稳定、跨 change、高价值”的项目背景。

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
```

### 不适合往里塞什么

不要把这些东西硬塞进 `config.yaml`：

- 某一次 change 的临时说明
- 项目当前完整能力清单
- artifact 依赖关系
- 模板正文
- 工具入口配置

这些都不是它的职责。

---

## schema 到底是什么

schema 不是数据库 schema，也不只是 template。

它更准确的角色是：

> **一次 change 应该长成什么样的工作流骨架。**

它定义的通常是：

- 有哪些 artifact
- 各自生成什么文件
- 谁依赖谁
- apply 追踪哪份文件

一个典型 schema 看起来像这样：

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

所以 schema 说的不是“这个项目用 React 还是 Vue”。
它说的是“这类 change 应该先有哪些产物，它们怎么关联”。

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

- template 更像“单个文档的写法骨架”
- schema 更像“整套 change 结构的定义”

---

## `.openspec.yaml` 为什么关键

这个文件在 change 目录里，价值在于：

- 它记录“这次 change 实际绑定哪套 schema”
- 它让单次 change 可以偏离项目默认 schema

也就是说：

- 项目默认可以在 `config.yaml` 里写 `schema: spec-driven`
- 但某个特殊 change 可以用另一套 schema

所以 change 的实际解析顺序，通常会优先看 change 自己，再回退到项目默认。

---

## profile 又是什么

profile 和 schema 不是一回事。

### profile 管什么

profile 管的是：

- 你装哪些 workflow 命令
- 默认是 core 4 个，还是更多扩展动作

### schema 管什么

schema 管的是：

- 一次 change 内部有哪些 artifact
- 它们的结构和依赖是什么

一句话区分：

- **profile 管入口多少**
- **schema 管 change 长相**

---

## 这一层最重要的边界意识

到了高级阶段，你最该有的不是“记住所有字段”，而是以下判断力：

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

### 什么时候看工具集成

当你已经知道项目事实层是什么，只是想研究：

- Cline/Claude 到底怎么调用它
- skills 和 commands 各扮演什么角色

这时才该进入下一篇。

---

## 下一步该看什么

如果你关心的是：

- “只装 Cline + OpenSpec 时，项目长什么样？”
- “`.cline/` 和 `openspec/` 到底谁是事实层？”
- “skill / workflow / CLI 在 Cline 里怎么拼起来？”

下一篇看：

- [04-高级-cline-里的-openspec-到底怎么落地.md](04-高级-cline-里的-openspec-到底怎么落地.md)
