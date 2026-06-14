# 答案：config.yaml 怎么搞——先看你是谁

## 一句话

`openspec/config.yaml` 定义项目 `context`（注入所有 artifact 的背景）和 `rules`（按 artifact 分的约束），只有 `schema` / `context` / `rules` 三个字段。OpenSpec 给它的编辑工具几乎没有（`openspec init` 只写一行 stub），所以**怎么搞取决于你是谁**——下面按读者类型分三条路。

## 三条路：你是哪种读者？

先读对应的那条，不用都看。专业度从上到下递增，对 agent 的依赖递减。

| 你是 | 去哪 |
|---|---|
| 普通人（不熟 SDD，想最小干预、撞墙再升级） | [`answer-beginner.md`](answer-beginner.md) |
| 能人（懂项目、会指挥 agent，非 SDD 专家） | [`answer-intermediate.md`](answer-intermediate.md) |
| 专家（SDD 熟手，要完全掌控） | [`answer-expert.md`](answer-expert.md) |

> 全部源码与文档引用集中在一个文件：[`sources.md`](sources.md)。
