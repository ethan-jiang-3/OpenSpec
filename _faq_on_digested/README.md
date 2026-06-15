# FAQ on Digested · 基于消化材料的二次研究

这个目录不是面向学习者的 FAQ（那些已经在 `_digested/` 各子目录的 FAQ 文件里了）。这里的每一个问题是我们在阅读消化材料、翻源码的过程中**自己产生的困惑**，答案需要跨越多个 `_digested/` 条目、甚至结合源码才能综合出来。

简单说：**一子目录 = 一个探究过的问题，答案是自己综合出来的，不是从某一份材料里直接抄的。**

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

不建议加数字前缀（没有固定阅读顺序）。

## 已有问题

- [`explore-to-propose-change/`](explore-to-propose-change/question.md) — Explore 如何基于用户意图、OpenSpec 状态和真实代码判断是否应该 propose change，以及应该 propose 一个还是多个。
- [`propose-to-apply-ready/`](propose-to-apply-ready/question.md) — Propose 动作出现后，OpenSpec 如何创建 change、生成 artifacts，并走到 `/opsx:apply` 可以开始。
- [`apply-ready-to-archive-ready/`](apply-ready-to-archive-ready/question.md) — `/opsx:apply` 开始后，agent 如何读取上下文、实施 tasks、更新 checkbox，并走到可以 archive。
- [`archive-ready-to-archived/`](archive-ready-to-archived/question.md) — Implementation 已完成后，`openspec archive` 如何验证、合并 specs、移动 change，并收束到 archived。
- [`schema-article-driven/`](schema-article-driven/question.md) — OpenSpec 的 schema 系统能不能脱离代码实现，用来管理文章内容生产流水线？概念验证：定义一个 article-driven schema，不改源码。
- [`schema-agent-dev-driven/`](schema-agent-dev-driven/question.md) — OpenSpec 的 schema 能不能用来开发 AI Agent 本身（charter/skills/commands/tools/evals/cli）？概念验证：定义一个 agent-dev-driven schema，不改源码。
- [`openspec-executable/`](openspec-executable/question.md) — `npm install -g @fission-ai/openspec` 之后，`openspec` 命令是怎么变成系统级可执行文件的。
- [`config-yaml-growth/`](config-yaml-growth/question.md) — 熟悉 SDD 的人能手动调 config.yaml，但普通程序员怎么搞？有没有交互式工具或 agent 辅助——还是现状就是个缺口？

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
