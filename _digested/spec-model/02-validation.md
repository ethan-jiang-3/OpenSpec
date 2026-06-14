# Validation

## Validator 的入口

`Validator` 在 `src/core/validation/validator.ts`，主要入口：

- `validateSpec(filePath)`
- `validateSpecContent(specName, content)`
- `validateChange(filePath)`
- `validateChangeDeltaSpecs(changeDir)`

`validateSpecContent()` 很关键：archive 在写入 rebuilt spec 前可以先验证内存中的新内容。

## Zod schema + 规则校验

校验分两层：

```text
parser output
  → Zod schema safeParse
  → OpenSpec-specific rules
```

Zod 负责基础结构；规则校验负责 OpenSpec 语义，比如 Purpose 长度、SHALL/MUST、scenario 数量、delta 冲突。

## delta validation

`validateChangeDeltaSpecs()` 会扫描 change 的 `specs/` 目录：

- 至少要能解析到 delta entries。
- ADDED/MODIFIED 要有 requirement text。
- ADDED/MODIFIED 要包含 SHALL/MUST。
- ADDED/MODIFIED 至少一个 scenario。
- REMOVED 只要求名字。
- RENAMED 要 FROM/TO pair。
- 同一 section 内不能重复。
- 同一 spec 文件内不能跨 section 冲突。

这套校验是 archive 前的重要守门器。

## warnings 与 errors

`ValidationIssue` 有 `level`。strict mode 会影响 report 是否通过：

- ERROR 一定失败。
- WARNING 在 strict mode 下也会导致失败。

因此 `validate --strict` 和普通 validate 的语义不同。

## enriched messages

validator 会把一些顶层 parser error 转成更可执行的提示。测试里有 `validate.enriched-output` 和 `validation.enriched-messages`，说明错误消息本身是用户体验的一部分，不只是内部异常。

## 边界

validate 不运行测试、不编译代码、不判断实现是否符合 spec。它只判断 OpenSpec 文档结构和 delta 语义是否满足规则。
