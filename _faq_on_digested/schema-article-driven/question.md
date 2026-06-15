# 问题

OpenSpec 的 schema 系统能不能脱离代码实现，用来管理内容/文章生产流水线？如果可以，一个 article-driven schema 长什么样？需要避开哪些坑？

# 背景

阅读 `_digested/` 中关于 schema、change/apply/archive 的材料时产生的疑问 —— OpenSpec 的 artifact 管线看起来很通用（定义 artifact → 声明依赖 → apply 按序生成），但它到底是为代码实现设计的还是可以泛化到其他生产流程？

# 答案摘要

可以。本目录就是一个概念验证：定义了一套 `article-driven` schema，把 OpenSpec 的流水线套用在文章生产上：

- **7 个 artifact**：brief → outline → research → tasks → draft → edit → publish
- **兼容策略**：保留 `tasks.md` 文件名（因为 OpenSpec 的 archive 逻辑对它有硬编码检查），不做源码改动

详见 `answer.md`（综合回答）和 `schema-package/`（schema 定义 + 各阶段模板）。
