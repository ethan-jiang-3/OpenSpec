# Parsers

## MarkdownParser

`MarkdownParser` 是 spec 文档的基础解析器。它把 Markdown section 解析成：

- title
- Purpose
- Requirements
- requirement list
- scenario list

解析结果会进入 `SpecSchema.safeParse()`。所以 parser 负责抽取结构，Zod schema 负责结构校验。

## ChangeParser

`ChangeParser` 继承 `MarkdownParser`，用于 proposal/change 文档。

它会解析：

- Why
- What Changes
- Impact
- delta specs

`parseChangeWithDeltas()` 会读取 change directory 下的 delta spec 文件，把 proposal 和 specs delta 组合成 `Change` 对象。

## requirement-blocks

`requirement-blocks.ts` 是 archive 和 validation 的关键 parser。

它提供两套能力：

1. `extractRequirementsSection()`：从主 spec 中抽出 `## Requirements` section，并按 `### Requirement:` 切 block。
2. `parseDeltaSpec()`：从 delta spec 中解析 `ADDED/MODIFIED/REMOVED/RENAMED` 四类变更。

重要细节：

- requirement header 匹配大小写不敏感。
- `normalizeRequirementName()` 当前只 trim，不 lower-case。
- REMOVED 支持 `### Requirement:` header，也支持 bullet list header。
- RENAMED 用 FROM/TO pair。

## spec-structure

`spec-structure.ts` 做主 spec 结构检查，包含 fenced code block 处理。

它解决的问题是：不能把代码块里的示例 header 当成真实 requirement。源码用 `stripFencedCodeBlocksPreservingLines()` 保留行号结构，同时屏蔽 fenced block 内容。

## parser 的边界

parser 不决定 workflow 顺序，不知道 schema DAG，也不负责写文件。它只把 Markdown 内容变成结构化语义，供 validate/show/archive 使用。
