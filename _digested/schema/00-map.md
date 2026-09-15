# Schema · 导读地图

> 这一系列把 OpenSpec 的 schema 系统从头拆到尾——从它到底是什么、内置的 spec-driven schema、到你怎么在项目里定义自己的一套。

## 文章列表

- [01-schema-到底是什么.md](01-schema-到底是什么.md) — 把 schema 这个概念钉死：它不是什么（不是 database schema、不是 template、不是 config），以及 artifact 依赖图
- [02-内置-spec-driven-详解.md](02-内置-spec-driven-详解.md) — 逐字段拆解默认 schema：4 个 artifact 的 instruction、依赖关系、apply 阶段
- [04-schema-解析优先级.md](04-schema-解析优先级.md) — 两层优先级：用哪个名字（CLI > .openspec.yaml > config.yaml > 默认）、从哪加载（project > user > package）
- [05-四层注入机制.md](05-四层注入机制.md) — context → rules → instruction → template 如何叠加控制 AI 行为
- [06-自定义-schema-实战.md](06-自定义-schema-实战.md) — 从 fork、init、手写三种方式创建自定义 schema，包括 CLI 命令和文件结构
- [07-超越-spec-driven-的应用场景.md](07-超越-spec-driven-的应用场景.md) — schema 不仅限于写代码：写文章、写剧本、生成 Agent 配置、TDD 工作流等
- [08-用户实例化-schema-完整流程.md](08-用户实例化-schema-完整流程.md) — 一个用户从零开始在落地项目里定义自己 schema 的完整步骤

## 关键结论

OpenSpec 的 schema 本质是 **artifact DAG 定义文件**：它不描述业务事实（那是 specs 的事），也不只是模板（那是 template 的事），而是定义"一次 change 应该长成什么骨架"。核心价值在于：**你不需要改一行 OpenSpec 源码，纯靠 YAML + Markdown 就能定制出一套完全不同形状的工作流。**

> **内置 schema 足迹**：上游删除了长期未维护的内置 `agent-dev-driven` 与 `requirement-driven`，现在随包分发的内置 schema 只有 `spec-driven`。这两个工作流的可运行副本保留在 `_faq_on_digested/09_schema-agent-dev/` 与 `10_schema-requirement/`，以项目级自定义 schema 形式安装，不再是 OpenSpec 内置项。
