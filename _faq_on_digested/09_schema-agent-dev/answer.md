# 答案：agent-dev-driven——用 spec-driven 写 agent 太唠叨，这份帮你翻译好了

## 一句话

用 `spec-driven` 写 agent 不是不行——proposal 写 "Why"、specs 写 delta ops、design 写实现方案、tasks 拆任务，流程完全走得通。但每次都要把 instruction 里的「代码」「API」「系统」脑补成「skills」「commands」「harness」——写多了烦。**agent-dev-driven 和 spec-driven 是同一个框架**，只是把 instruction 和 template 里那些软件味儿的东西提前换成了 agent 味儿。proposal 和 specs 基本没动，动的就是 design 和 tasks——因为这两步想的东西确实不一样。

```text
spec-driven        写 agent 也能写，但得自己翻译软件术语 → agent 术语
agent-dev-driven   同一套框架，翻译提前做好了，直接用
```

## 为什么不做成全新的 schema

已有雏形自建了 persona / skills / scripts / tests 一套新 artifact 名，其实没必要。spec-driven 那套 proposal → specs → design → tasks 的心智模型是现成的——proposal 就是 proposal（说清楚为什么改），specs 就是 specs（用 delta ops 规格化），design 就是 design（实现方案），tasks 就是 tasks（拆任务）。不管交付物是代码还是 agent，这个流程不变。唯一变的是 design 和 tasks 里面填什么——那改 template 和 instruction 就够了，不需要发明新 artifact。

## 和 spec-driven 差在哪

四个 artifact，两个不改，两个微调。requires 关系完全一样（`proposal → specs → design → tasks → apply`）：

| artifact | 和 spec-driven 比 |
|----------|------------------|
| `proposal` | 基本不改。Why / What Changes / Capabilities / Impact 照写。Impact 里把「code, APIs」换成「skills, commands, tools, harnesses」就行——模板已经替你换好了 |
| `specs` | 不改。delta ops + Requirement + Scenario，agent capability 和软件 capability 规格化方式一模一样 |
| `design` | **动得最多**。spec-driven 的 design 想的是代码架构和技术选型，agent-dev-driven 的 design 想的是 skills / commands / tools / evals / CLI。模板预先搭好了这些段，不用每次自己加。另外 spec-driven 的 design 是可选的——agent 开发每次都得出完整实现方案，所以设了必写 |
| `tasks` | checklist 格式一样。模板里预先填好了推荐的 task 分组（Skills → Commands → Tools → Evals → CLI → Harness Integration → End-to-End），不用每次从空白 checklist 开始 |

## config.yaml 怎么配

和 spec-driven 一样，项目全局的东西放 config.yaml。agent 的身份、硬约束、system prompt 是项目级的——第一次写好，后面 proposal 不用重复唠叨：

```yaml
schema: agent-dev-driven

context: |
  Agent: <name>——<角色>
  Target harness: <Claude Code / Cursor / 自建>

  ## Constraints（硬边界）
  - 拒绝：<输入类型> → "<话术>"

  ## Baseline System Prompt
  You are <Agent Name>, a <role>. …
```

## 使用方式

```bash
cp -r schema-package/ openspec/schemas/agent-dev-driven/
openspec schema validate agent-dev-driven
openspec new change build-my-agent --schema agent-dev-driven
# 按 proposal → specs → design → tasks 写，和 spec-driven 一样的流程
```

> 完整的安装、校验、调试指南见 [`answer-add-schema.md`](answer-add-schema.md)。

## 已知限制

- OpenSpec 没有模型 eval——evals 只能断言产物形状（grep、文件存在），不能判断 agent 输出质量。
- `openspec change --long` 的进度计数硬编码了 `tasks.md` 文件名——和 spec-driven 一样的限制。
- **fork 不会自动继承上游 instruction 更新。** 本示例已手工追随 v1.10.0：每条 checkbox task 自带 verification，MODIFIED 主 spec 从 `planningHome.root` 解析。以后升级 OpenSpec 仍需把内置 `schemas/spec-driven/schema.yaml` 与这个 fork 做语义 diff；`openspec update` 不会重写项目 schema。

---

> 完整 schema-package（`schema.yaml` + 4 个 `templates/*.md`）在 [`schema-package/`](schema-package/)。
