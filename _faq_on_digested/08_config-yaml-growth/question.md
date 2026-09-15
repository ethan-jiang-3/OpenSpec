# 问题

`openspec/config.yaml` 这个文件定义了项目背景（`context`）和各 artifact 的规则（`rules`）。熟悉 SDD 的人可以直接手动编辑它——他懂细节，知道该写什么、`rules` 的 key 该用哪个 artifact ID、`context` 该放什么不该放什么。

但**普通程序员不熟这些细节**。他怎么调整这个 config.yaml？是靠自然语言跟 agent 说一声让 agent 帮忙，还是 openspec 自己有什么辅助的工具？

更具体地说：

- `openspec init` 会不会交互式地引导我把 `context` 和 `rules` 填进去？`--language` 能替代到什么程度？
- 有没有 `openspec config` 之类的命令能加规则、改背景？
- 如果都没有，我让 AI agent（比如 Claude Code）帮我写行不行——openspec 有没有引导 agent 去做这件事？
- 一句话：对不懂细节的普通用户，config.yaml 到底怎么"自然地"长出来？

# 背景

已有的材料都偏"给愿意手写的人看"：

- [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) 讲三层模型（config / specs / changes 各放什么）。
- [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) 是一份完整的"怎么把 config.yaml 写好"指南（强规则公式、4 类规则、bad smell、4 种项目 sample）。
- [`../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md`](../../_digested/internal-spec-driven/06-config-yaml-机制与约束.md) 讲透了机制（Zod、读取时机、注入格式、50KB、fail-open）。

但这些都没回答：**不熟细节的普通程序员，第一步该怎么把 config.yaml 弄出来、之后怎么一点点长——有没有工具或 agent 帮他？**

这篇 FAQ 补这一层：现状到底有没有辅助（交互式命令？诊断命令？agent 引导？），如果没有，缺口在哪、最小改进是什么。

边界：不讲机制细节（digested 06 已有），不重复"怎么写好"（handbook 06 已有）。
