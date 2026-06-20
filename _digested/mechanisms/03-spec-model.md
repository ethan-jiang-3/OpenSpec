# Spec Model

## Markdown 不是随便写的笔记

OpenSpec 选择 Markdown 作为 specs/changes 的存储格式，是为了让人类能读、能 review、能进 Git。但如果 Markdown 只是一堆自由文本，agent 和 CLI 就无法可靠判断：

- 当前项目承认了哪些 requirement？
- 一个 change 修改了哪些 requirement？
- delta spec 是否能安全 archive？
- `show --json` 和 `validate --json` 应该输出什么？

Spec model 这一层的作用，就是把 Markdown 变成可验证、可查询、可 archive的结构化对象。

```text
Markdown files
  → parsers
  → Zod schemas
  → validation/report/conversion
  → show/list/view/archive/workflow context
```

这也是 OpenSpec 和“让 agent 随便读文档”的区别：文件是人类格式，解释结果是机器格式。

## parser 和 schema 的分工

`MarkdownParser` 是 spec 文档的基础解析器。它把 Markdown section 解析成 title、Purpose、Requirements、requirement list、scenario list。解析结果进入 `SpecSchema.safeParse()`。

这个分工很关键：

- parser 负责从 Markdown 抽取结构。
- Zod schema 负责结构合法性。
- validator 负责 OpenSpec-specific 规则。

不要把这三者混在一起。parser 不应该决定 workflow 顺序；schema 不应该处理文件系统 archive；validator 不应该替 agent 判断代码是否实现正确。

## ChangeParser

`ChangeParser` 继承 `MarkdownParser`，用于 proposal/change 文档。它会解析：

- Why
- What Changes
- Impact
- delta specs

`parseChangeWithDeltas()` 会读取 change directory 下的 delta spec 文件，把 proposal 和 specs delta 组合成 `Change` 对象。

这使得一个 change 不是“一个目录里有几个 Markdown 文件”这么简单，而是 CLI 和 agent 可作为结构化 change 来审阅、验证、输出 JSON。

## requirement-blocks 是 archive 的关键

`requirement-blocks.ts` 是 archive 和 validation 的关键 parser。它提供两套能力：

1. `extractRequirementsSection()`：从主 spec 中抽出 `## Requirements` section，并按 `### Requirement:` 切 block。
2. `parseDeltaSpec()`：从 delta spec 中解析 `ADDED/MODIFIED/REMOVED/RENAMED` 四类变更。

重要细节：

- requirement header 匹配大小写不敏感。
- `normalizeRequirementName()` 当前只 trim，不 lower-case。
- REMOVED 支持 `### Requirement:` header，也支持 bullet list header。
- RENAMED 用 FROM/TO pair。

这些细节看起来小，但会直接影响 archive merge 是否能找到正确 requirement，以及同名/改名冲突如何处理。

## fenced code block 的边界

`spec-structure.ts` 做主 spec 结构检查，包含 fenced code block 处理。它解决的问题是：不能把代码块里的示例 header 当成真实 requirement。

源码用 `stripFencedCodeBlocksPreservingLines()` 保留行号结构，同时屏蔽 fenced block 内容。这是典型的“人类友好格式”和“机器稳定解析”之间的折中：允许 spec 里放示例，但不能让示例破坏结构判断。

## validation 的两层规则

`Validator` 在 `src/core/validation/validator.ts`，主要入口：

- `validateSpec(filePath)`
- `validateSpecContent(specName, content)`
- `validateChange(filePath)`
- `validateChangeDeltaSpecs(changeDir)`

校验分两层：

```text
parser output
  → Zod schema safeParse
  → OpenSpec-specific rules
```

Zod 负责基础结构；规则校验负责 OpenSpec 语义，比如 Purpose 长度、SHALL/MUST、scenario 数量、delta 冲突。

`validateChangeDeltaSpecs()` 会扫描 change 的 `specs/` 目录，检查 ADDED/MODIFIED/REMOVED/RENAMED 的结构、重复、冲突和 scenario 要求。这套校验是 archive 前的重要守门器。

## warnings 与 errors

`ValidationIssue` 有 `level`。strict mode 会影响 report 是否通过：

- ERROR 一定失败。
- WARNING 在 strict mode 下也会导致失败。

因此 `validate --strict` 和普通 validate 的语义不同。这个设计允许 OpenSpec 同时支持“宽松审阅”和“严格 CI/archive 前检查”。

## read commands 是模型的外部视图

| 命令 | 本质 |
|------|------|
| `list` | 读取 active changes/specs，输出索引视图 |
| `show` | 把 change/spec 内容解析后展示，human/JSON 两种形态 |
| `view` | 人类交互 dashboard，偏浏览体验 |
| `validate` | 包装 Validator，转换成 CLI report、JSON 和退出码 |
| `JsonConverter` | spec/change Markdown 到 JSON object 的轻量转换 |

它们回答的是“现有状态是什么、是否结构有效”，不回答“下一步应该写什么”。workflow 决策要看 `status` / `instructions`。

## 工程洞察

- OpenSpec 不是把 Markdown 当纯文档，而是把它当 local protocol file。
- parser/validator 让 Git-friendly 文本具备机器可检查语义。
- archive 可靠性依赖 requirement block 解析，而不是 LLM 自由合并。
- enriched validation messages 是产品能力的一部分，因为错误修复路径要给人和 agent 都看得懂。

## 源码锚点

| 机制 | 路径 |
|------|------|
| spec/change Zod schema | `src/core/schemas/` |
| Markdown parser | `src/core/parsers/markdown-parser.ts` |
| change parser | `src/core/parsers/change-parser.ts` |
| requirement blocks | `src/core/parsers/requirement-blocks.ts` |
| main spec structure | `src/core/parsers/spec-structure.ts` |
| validator | `src/core/validation/validator.ts` |
| JSON converter | `src/core/converters/json-converter.ts` |
| read commands | `src/core/list.ts`、`src/core/view.ts`、`src/commands/show.ts`、`src/commands/validate.ts` |

## 继续阅读

- archive merge 算法见 `../internal-spec-driven/04-archive-归档合并.md`。
- schema artifact graph 见 `../schema/`。
- CLI command IO 见 `../spec_cli/`。
