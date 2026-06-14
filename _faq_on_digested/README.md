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

## 引用规范

引用 `_digested/` 中的材料时使用相对路径：

```markdown
../_digested/spec_cli/01-human-facing-cli.md
../_spec_full_content/02-中级-把核心概念真正串起来.md
```

引用源码时标注 commit hash，避免链接随时间失效。

## 一个子目录该长什么样

- **问题要明确** — 不是「OpenSpec 是怎么工作的」，而是「`openspec apply` 的 artifact 生成逻辑和 `openspec archive` 的恢复逻辑到底有什么不同？」
- **答案要综合** — 至少引用到 2 份不同的消化材料或 1 份消化材料 + 源码
- **不追求完备** — 回答自己当时的困惑就够了，不全覆盖，不是百科全书
