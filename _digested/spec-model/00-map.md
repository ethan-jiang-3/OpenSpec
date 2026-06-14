# Spec Model 地图

## 一句话

OpenSpec 的 repo-local 文档不是任意 Markdown。源码把它解析成结构化对象，再用于 validate、show、archive、JSON 输出和 agent 上下文。

```text
Markdown files
  → parsers
  → Zod schemas
  → validation/report/conversion
  → show/list/view/archive/workflow context
```

## 核心源码

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

## 与已有专题的关系

- archive merge 算法见 `../internal-spec-driven/04-archive-归档合并.md`。
- schema artifact graph 见 `../schema/`。
- CLI command IO 见 `../spec_cli/`。

这里专门讲 Markdown 如何变成 OpenSpec 内部数据对象。
