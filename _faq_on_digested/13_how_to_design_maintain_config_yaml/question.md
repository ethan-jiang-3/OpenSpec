# 问题

当我们设计或更新 `openspec/config.yaml` 时，怎样避免把所有项目知识、流程说明、治理规则和临时决定一股脑塞进全局 `context`？

更具体地说：

1. 不同阶段（Explore、proposal、specs、design、tasks、apply、archive）到底会消费哪些 config 信息？
2. 什么应留在 `context`，什么应写成 `rules.<artifact>`，什么应该进入 change artifacts、schema、playbook 或 checker？
3. 当一个项目有多种 change domain、长政策文档、复杂 gate 或 runtime 时，如何让真正需要它的阶段得到准确指导？
4. 在 Deep Research Tool、Agentic PPT workflow 与 DeerFlow Deep Research 这三个特定本地项目中，哪些内容已经归位正确，哪些是“内容正确但注入位置不对”？这些项目各自的 B1/B2 结论如何由其真实 runtime owner 支撑，而不是被泛化为同类项目模板？
5. 当配置看起来已经写对却没有生效时，如何按真实的 root、schema、instructions 和 change artifacts 诊断问题？

# 背景

已有 [`../08_config-yaml-growth/`](../08_config-yaml-growth/question.md) 主要回答“谁来写 config、怎么让 agent 辅助增长 config”。本问题更进一步：**即使规则本身都正确，怎样避免因作用域错误而让 prompt 失焦、让 apply/explore 等阶段根本收不到指导、或把本该由 deterministic check 承担的事情变成软提示？**

问题还参考了三个具体的本地项目，而不是三种可泛化模板：

| 项目 | 这里指什么 | 本地配置来源 |
|---|---|---|
| Deep Research Tool | 产出证据支撑、多波次、带 Gate 研究报告的 Agentic research framework；Agent/Markdown flow 做研究与语义决策，JavaScript Engine 做确定性 Gate 和状态记录。 | `/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml` |
| Agentic PPT workflow | 由 Agent/Markdown controller 推进内容与视觉生产、由 JavaScript/CLI 提供校验和 Gate 的演示文稿系统，同时包含 framework maintenance 与 run-bundle production。 | `/Users/bowhead/ai_tool_ppt_maker/openspec/config.yaml` |
| DeerFlow Deep Research | 基于 DeerFlow 2.1 的下游深度研究产品；`agent/` 中的 Python `StateGraph`、typed state 和 node contract 拥有主要运行时控制边界。 | `/Users/bowhead/ai_deerflow_deep_research/openspec/config.yaml` |

它们都包含大量高质量的项目知识和工程纪律；难点不是“删掉约束”，而是让每条约束由正确的 owner、在正确时机、通过正确的路径消费。三份审计及其证据边界见 [`project-cases/README.md`](project-cases/README.md)。其他项目最多参考审计方法，不能直接沿用这些项目的路径、policy、Gate、命令、能力边界或 B1/B2 结论。

# 答案摘要

`config.yaml` 的正确定位是**小而稳定的项目 profile + 单 artifact 的长期指导**，不是通用阶段化上下文系统。

```text
所有 artifact 都要知道的稳定事实 -> context
只服务一个 artifact 的长期约束   -> rules.<artifact>
本次 change 的分类/决定/风险      -> proposal / specs / design / tasks
工作流节点和 apply 固定行为       -> schema.yaml / workflow skill
不可绕过的规则                    -> checker / test / CI
跨团队上游 spec                   -> references + 按需读取
运行时状态                         -> state / receipt / run 文件
```

最容易漏掉的事实：当前 `apply` 不会接收 `context`/`rules`；Explore 和 Archive 也不会通过 artifact instructions 自动接收它们。要实现阶段精确指导，首先应利用 artifact DAG 传递 change-local context；若仍不够，再升级 schema 或 workflow，而不是发明未支持的 config 字段。

完整答案见 [`answer.md`](answer.md)。从下游项目类型选择初稿见 [`00-initial-config-baselines.md`](00-initial-config-baselines.md)；信息归位见 [`01-design-config-yaml.md`](01-design-config-yaml.md)；配置诊断与维护见 [`02-diagnose-maintain-config-yaml.md`](02-diagnose-maintain-config-yaml.md)；三个项目特定审计见 [`project-cases/README.md`](project-cases/README.md)。内置 `spec-driven` 的源码边界见 [`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md)，其余机制证据见 [`sources.md`](sources.md)。
