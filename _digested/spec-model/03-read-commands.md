# Read Commands 数据流

## list

`ListCommand` 读取 `openspec/changes` 和 `openspec/specs`，输出索引视图。它还会读取 task progress 和 mtime，用于排序和展示。

它回答“有什么”，不回答“下一步怎么做”。workflow 决策要用 `status`。

## show

`ShowCommand` 把 change/spec 内容解析后展示：

- human mode 输出 Markdown/摘要。
- JSON mode 输出结构化对象。
- spec 可以按 requirement 过滤。
- change 可以输出 deltas-only。

show 的价值是调试 parser 结果和审阅内容，不推进 workflow。

## view

`ViewCommand` 是人类交互 dashboard，聚合 active changes 和 specs。它和 `list` 相似，但偏浏览体验，不是 agent runtime API。

## validate command

`ValidateCommand` 包装 `Validator`：

- 可验证单个 change/spec。
- 可验证全部 changes/specs。
- 支持 interactive selection。
- 支持 JSON validation output。
- 支持 concurrency。

它把 validator 的 report 转成 CLI 退出码和可读输出。

## JsonConverter

`JsonConverter` 是轻量转换器：

- spec Markdown → JSON spec object。
- change Markdown → JSON change object。
- 给 metadata 加 `sourcePath`。

它复用 parser，不定义新语义。
