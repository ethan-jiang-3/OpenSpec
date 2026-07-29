# 答案：config.yaml 怎么搞——先看你是谁

## 一句话

`openspec/config.yaml` 定义项目 `context`（所有 artifact 的背景，也进入 v1.7.0 Apply/Archive）、`rules`（按 artifact 的约束）、`operations`（Apply/Archive 的专属 guidance）和 schema/references 等项目配置。OpenSpec 给它的编辑工具几乎没有（`openspec init` 只写最小 stub），所以**怎么搞取决于你是谁**——下面按读者类型分四条路。从“用别人的 config”到“借 agent 长 config”到“自己精通 config（提示层）”再到“重塑 schema（结构层）”，操作对象一层比一层深。

## 四条路：你是哪种读者？

先读对应的那条，不用都看。四条路是**操作对象的递进**——从拿来用，到借力生成，到亲手精修提示层，到改工作流结构层本身。

| 你是 | 去哪 |
|---|---|
| 普通人（不熟 SDD，想最小干预、撞墙再升级） | [`answer-beginner.md`](answer-beginner.md) |
| 能人（懂项目、会指挥 agent，非 SDD 专家） | [`answer-intermediate.md`](answer-intermediate.md) |
| 专家（SDD 熟手，spec-driven 内精通 config） | [`answer-expert.md`](answer-expert.md) |
| guru（spec-driven 不够用，要改 artifact / 依赖 / 模板） | [`answer-guru.md`](answer-guru.md) |

> 全部源码与文档引用集中在一个文件：[`sources.md`](sources.md)。
