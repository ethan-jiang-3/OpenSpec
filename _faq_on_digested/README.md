# FAQ on Digested · 基于消化材料的二次研究

这个目录不是面向学习者的 FAQ（那些已经在 `_digested/` 各子目录的 FAQ 文件里了）。这里的每一个问题是我们在阅读消化材料、翻源码的过程中**自己产生的困惑**，答案需要跨越多个 `_digested/` 条目、甚至结合源码才能综合出来。

简单说：**一子目录 = 一个探究过的问题，答案是自己综合出来的，不是从某一份材料里直接抄的。**

> **当前研究基线**：涉及运行时行为的结论以 OpenSpec `v1.7.0`（upstream tag `4e16790`）为准；旧版本仅用于变更史解释，不能替代当前源码验证。

## 和 `_digested/` 内置 FAQ 的区别

| | `_digested/` 内 FAQ | `_faq_on_digested/` |
|---|---|---|
| 读者 | 学习者 | 我自己（产出者） |
| 答案来源 | 单一消化材料的整理 | 跨多份消化材料 + 源码的综合推断 |
| 本质 | 文档的一部分 | 研究过程的归档 |

## 目录结构

```
_faq_on_digested/
├── README.md              # 你正在看的文件
├── <question-slug>/       # 一个问题 = 一个子目录
│   ├── question.md        # 问题描述 + 背景
│   └── answer.md          # 答案 / 分析 / 结论
```

子目录内自由组织，可以是 `question.md` + `answer.md` 两张，也可以合在一起，也可以带代码示例。关键是**引用来源要标注清楚**。

## 命名约定

子目录用英文 slug，简短描述问题主题，例如：

- `agent-vs-human-workflow/`
- `config-schema-boundary/`
- `openspec-vs-opsx-prefix/`

`NN_` 数字前缀按创建时间排序（01 最早），方便了解问题是按什么次序产生和探究的。

## 已有问题

- [`01_openspec-executable/`](01_openspec-executable/question.md) — `npm install -g @fission-ai/openspec` 之后，`openspec` 命令是怎么变成系统级可执行文件的。
- [`02_schema-article-driven/`](02_schema-article-driven/question.md) — OpenSpec 的 schema 系统能不能脱离代码实现，用来管理文章内容生产流水线？概念验证：定义一个 article-driven schema，不改源码。
- [`03_explore-to-propose-change/`](03_explore-to-propose-change/question.md) — Explore 如何基于用户意图、OpenSpec 状态和真实代码判断是否应该 propose change，以及应该 propose 一个还是多个。
- [`04_propose-to-apply-ready/`](04_propose-to-apply-ready/question.md) — Propose 动作出现后，OpenSpec 如何创建 change、生成 artifacts，并走到 mechanical apply-ready。
- [`05_iterate-to-apply-ready/`](05_iterate-to-apply-ready/question.md) — Propose 产出了 artifacts 但真的能拿来实施吗？最常见的做法：用 Explore 回头审视 artifacts → 拿真实代码校验 → 发现 gap → 更新 → 再审，直到真正可以 apply。
- [`06_apply-ready-to-archive-ready/`](06_apply-ready-to-archive-ready/question.md) — `/opsx:apply` 开始后，agent 如何读取上下文、实施 tasks、更新 checkbox，并走到可以 archive。
- [`07_archive-ready-to-archived/`](07_archive-ready-to-archived/question.md) — Implementation 已完成后，`openspec archive` 如何验证、合并 specs、移动 change，并收束到 archived。
- [`08_config-yaml-growth/`](08_config-yaml-growth/question.md) — 熟悉 SDD 的人能手动调 config.yaml，但普通程序员怎么搞？有没有交互式工具或 agent 辅助——还是现状就是个缺口？
- [`09_schema-agent-dev/`](09_schema-agent-dev/question.md) — OpenSpec 的 schema 能不能用来开发 AI Agent 本身？概念验证：和 spec-driven 同框架（proposal/specs/design/tasks），只改 instruction 内容，不改源码。
- [`10_schema-requirement/`](10_schema-requirement/question.md) — OpenSpec 的 schema 能不能做需求工程？用原生 `proposal → specs → tasks` 承载 PRD 流程，把反复沟通打磨编码进 instruction。
- [`11_keep-specs-aligned/`](11_keep-specs-aligned/question.md) — 怎么别让 main specs 和代码对不上：平时的习惯 / 怎么发现要修 / 最常见的几种修法。
- [`12_upstream-roadmap-and-issues/`](12_upstream-roadmap-and-issues/question.md) — 以 GitHub Issues/Discussions、官方文档、Release Notes 为源，归纳上游项目的 1) roadmap（已交付/近期/workspace 四阶段/context store），2) 最主要问题（结构性限制/高频 bug/迁移痛点），3) 社区最常见问题，并与我们在 `_digested/` 中的研究交叉对照。
- [`13_how_to_design_maintain_config_yaml/`](13_how_to_design_maintain_config_yaml/question.md) — 如何按下游运行时的 Flow owner 选择传统确定性、MD/Agent 控制或程序/Graph 控制的 config 初始基线，让 config.yaml 在正确阶段提供准确指导，并按生效 root、schema、instructions 与 artifacts 诊断“配置没有生效”。
- [`14_main_specs_context_scaling/`](14_main_specs_context_scaling/question.md) — archive 后主 specs 不断增长时，OpenSpec 现有的 capability 分片、按需读取与 external reference index 到底覆盖了什么；本仓库没有的 local spec discovery / retrieval 如何用 catalog、全局 context 内核与显式选择协议补上。
- [`15_nested_capability_migration/`](15_nested_capability_migration/question.md) — 项目 capability 太多（几十个 flat capability），如何从 flat 迁移到嵌套二级目录结构？完整操作指南：taxonomy 设计、受控 rebaseline 流程、active delta 处理、config.yaml 更新、catalog 建设、验证清单、迁移后纪律。

## 引用规范

引用 `_digested/` 中的材料时使用相对路径：

```markdown
../_digested/spec_cli/01-human-facing-cli.md
../_openspec_handbook/02-中级-把核心概念真正串起来.md
```

引用源码时标注 commit hash，避免链接随时间失效。

## 一个子目录该长什么样

- **问题要明确** — 不是「OpenSpec 是怎么工作的」，而是「`openspec apply` 的 artifact 生成逻辑和 `openspec archive` 的恢复逻辑到底有什么不同？」
- **答案要综合** — 至少引用到 2 份不同的消化材料或 1 份消化材料 + 源码
- **不追求完备** — 回答自己当时的困惑就够了，不全覆盖，不是百科全书
