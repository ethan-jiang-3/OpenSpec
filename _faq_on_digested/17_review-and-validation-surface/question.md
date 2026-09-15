# 问题

OpenSpec 有一组**审阅/校验**能力：

- `openspec show <change> --diff`
- `openspec status --all`
- `openspec validate --report findings`
- validate 的 advisory merge preflight
- validate 的 Purpose 占位符检测
- delta parser 三修复

它们各自解决什么？合起来能不能在 archive **之前**发现 specs 失真？和 `validate` 原有的结构检查、`archive` 的一次性合并之间，边界到底在哪？

# 背景

`_digested/specs_truth/` 反复强调一个痛点：**OpenSpec 没有任何工具持续对账**——`validate` 只做结构检查、不做跨文件对账，`archive` 只在合并那一刻匹配一次。于是"delta 写了但没生效""主 spec 和代码对不上"这类问题往往要等到 archive 报 `not found` 才暴露，甚至 archive 报成功却什么都没动。

这一组能力，第一次把"审阅"从人的手工 diff，变成 CLI 的**程序化输出**。本 FAQ 要把它们拆成两条线：一条是**解析保真**（delta 是否被真正读懂），一条是**报告面**（失真是否被真正看见），并回答"它们补上了 specs_truth 里哪些缺口、又没有补上哪些"。

# 答案摘要

见 [`answer.md`](answer.md)。
