# OpenSpec CLI Digest

这组文档不是官方命令参考的重写版，而是对 `openspec` CLI 的一次“消化”。目标不是把命令再列一遍，而是回答四个更核心的问题：

1. `openspec` CLI 在整个项目里扮演什么角色。
2. 哪些命令主要服务人类用户，哪些命令主要服务 OPSX/AI 工作流。
3. 每个关键命令本质上在处理什么对象，读进来什么，产出去什么，产出后会影响谁。
4. `init` / `update` / profiles / delivery / schemas / templates 这些机制怎样共同组成 OpenSpec 的工作流系统。

## 阅读顺序

建议按下面顺序读：

1. `00-map.md`
2. `03-workflow-runtime-api.md`
3. `06-opsx-call-chains.md`
4. `01-human-facing-cli.md`
5. `02-machine-facing-cli.md`
6. `05-config-profile-delivery.md`
7. `07-command-io-matrix.md`
8. `08-glossary-and-models.md`

## 这套文档的立场

这里把 CLI 看成三层：

- 产品层：人类开发者在终端里直接使用的命令。
- 协议层：OPSX/skills/commands 模板会调用的结构化接口。
- 投递层：`init` / `update` 把 OpenSpec 工作流投放到不同 AI 工具里的机制。

如果只从“命令帮助文本”看，很容易把 `openspec` 理解成普通开发工具。如果顺着源码看，会发现它其实更像一个工作流内核：

- 一部分命令直接操作项目里的 OpenSpec 状态。
- 一部分命令对这些状态做解释、验证、编译和暴露。
- 一部分命令把这些能力包装成外部 AI 工具可消费的技能与 slash commands。

## 文档索引

- `00-map.md`: 总览图，说明 CLI 的三层结构、两类受众和推荐阅读路径。
- `01-human-facing-cli.md`: 面向人类用户的命令理解，按任务流组织。
- `02-machine-facing-cli.md`: 面向 OPSX/AI 的 CLI 接口，强调 JSON、结构化输出和被谁消费。
- `03-workflow-runtime-api.md`: 最关键的一篇，深挖 `status`、`instructions`、`new change`、`templates`、`schemas`。
- `04-command-deep-dive.md`: 全量命令族的消化版说明，不追求 API reference 的细枝末节，而强调边界和本质。
- `05-config-profile-delivery.md`: 解释 `profile`、`delivery`、`init`、`update` 如何把工作流投放到具体 AI 工具。
- `06-opsx-call-chains.md`: 从 `/opsx:*` 模板反向梳理 CLI 调用链。
- `07-command-io-matrix.md`: 每个命令的输入、输出、影响和典型受众总表。
- `08-glossary-and-models.md`: 统一术语，避免把 change、artifact、schema、workflow 混在一起。

