# 问题

OpenSpec 有一组**审阅/校验**能力：

- `openspec show <change> --diff`、`openspec status --all`、`openspec validate --report findings`
- validate 的 advisory merge preflight 与 `## Purpose` 占位符检测
- delta / spec 解析保真（`[-*+]` 列表标记、重复 section 全应用、scenario 换行 bullet 与 `<` 折行正文放行 `#2266`、闭合 `#` run、无空格 `###Requirement:`、行内三反引号）
- `.openspec.yaml` 未知键告警（含 `x-*` 扩展键豁免）、坏 `config.yaml` 让 `validate` 退出 1（`#2127`）
- delta 丢失文本（`unappliedContent`，含顶部 YAML frontmatter 放宽 `#2273`）、超长 requirement 告警（ADDED `>500` 字符 + MODIFIED `>500` 字符且比主 spec 基线更长 `#2265`）、Scenario 缺 WHEN/GIVEN 或 THEN 告警（`#2079`）、未识别 `## ... Requirements` 段升级为 ERROR（`#2207`）
- `openspec-verify-change` 按 status/instructions 契约与输出路径发现工件、REMOVED 精确规范化基线核对，以及 archive 写前校验与目录预检（`#2267`、`#2277`）

它们各自解决什么？合起来能不能在 archive **之前**发现 specs 失真？和 `validate` 原有的结构检查、`archive` 的一次性合并之间，边界到底在哪？

# 背景

`_digested/specs_truth/` 反复强调一个痛点：**OpenSpec 没有任何工具持续对账**——`validate` 只做结构检查、不做跨文件对账，`archive` 只在合并那一刻匹配一次。于是"delta 写了但没生效""主 spec 和代码对不上"这类问题往往要等到 archive 报 `not found` 才暴露，甚至 archive 报成功却什么都没动。

这一组能力，第一次把"审阅"从人的手工 diff，变成 CLI 的**程序化输出**。本 FAQ 要把它们拆成两条线：一条是**解析保真**（delta 是否被真正读懂），一条是**报告面**（失真是否被真正看见），并回答"它们补上了 specs_truth 里哪些缺口、又没有补上哪些"。

# 答案摘要

见 [`answer.md`](answer.md)。
