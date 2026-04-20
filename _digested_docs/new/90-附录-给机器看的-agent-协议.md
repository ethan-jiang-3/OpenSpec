# 90 · 附录：给机器看的 Agent 协议

> 这一篇不是给第一次上手的人看的，而是给想研究“OpenSpec 怎么喂给宿主 agent”的人看的。

---

## 先明确三方角色

```text
用户  ←→  宿主 Agent（Cline / Claude / Cursor）  ←→  OpenSpec CLI
```

三者分工是：

- **用户**：提需求、选命令、确认方向
- **宿主 Agent**：理解命令、调用 CLI、把上下文喂给自己的模型、生成内容
- **OpenSpec CLI**：读写文件、解析 schema、计算 artifact 状态、返回结构化上下文

最关键的一句：

> **OpenSpec 自己不是 LLM，它是 prompt 编排器和状态引擎。**

---

## 对机器来说，最重要的不是页面文档，而是结构化查询

宿主 agent 并不是靠“读完整本手册”来工作的。

它更依赖几类运行时查询，例如：

- `openspec status --json`
- `openspec instructions <artifact> --json`
- `openspec schemas`
- `openspec templates`

这些命令提供的是机器可消费的上下文，而不是给人看的长篇解释。

---

## 一次典型执行链

以 `propose` 为例：

1. 宿主工具通过 skill 或 command 获得执行模板
2. 它调用 `openspec status --change <name> --json`
3. 它得知当前 schema 和各 artifact 状态
4. 它再调用 `openspec instructions <artifact> --change <name> --json`
5. 它拿到：instruction、template、context、rules、dependencies、outputPath
6. 它把这些材料组装成 prompt 喂给自己的模型
7. 模型输出 markdown
8. Agent 把结果写回 change 目录

所以：

- skill/command 负责“告诉 agent 怎么做”
- CLI 负责“给 agent 真实上下文”
- LLM 负责“真正写内容和做推理”

---

## skill、command、workflow 的关系

这三个词很容易混，但它们不是同一层：

| 名词 | 它是什么 |
|------|----------|
| workflow | 一个动作语义，例如 propose / apply / archive |
| skill | 给宿主 agent 看的能力说明书 |
| command | 给用户触发的命令入口模板 |

所以一个更准确的理解是：

- workflow 是“动作 ID”
- skill/command 是“投递方式”
- CLI 是“运行时事实来源”

---

## 为什么这部分应该放在最后

因为这部分解决的是：

- 机器怎么调用
- prompt 怎么拼
- 哪些信息是 runtime 提供的

它不是人类第一次上手 OpenSpec 时最先需要的认知。

人类第一步应该先会用，第二步应该先理解 `specs` 和 `changes`。
等主线稳了，再来看机器协议，才不会把整套系统看成“几份神秘 prompt 文件”。
