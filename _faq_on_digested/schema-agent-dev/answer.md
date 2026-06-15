# 答案：agent-dev-driven 就是 spec-driven，只是 design 考虑的东西不一样

## 一句话

`agent-dev-driven` 和 `spec-driven` **几乎一样**——同一个 proposal → specs → design → tasks → apply 框架，不改 OpenSpec 源码。差异只在 **design 和 tasks 的内容**：design 考虑的是 agent 组件（skills、commands、tools、evals、CLI）而不是代码架构，tasks 安排的是 agent 构建和 harness 接入而不是代码实现。proposal 和 specs **不改**。apply 基本不改。

## 为什么会想到这个

已有雏形自建了 persona/skills 等 artifact 名，但其实不需要。spec-driven 的 proposal/specs/design/tasks 四个 artifact 对 agent 开发完全够用——proposal 说"为什么改"，specs 说"改成什么样"，design 说"怎么实现"，tasks 跟踪进度。差异只在 design 这一步**想的是什么**：

```text
spec-driven 的 design 想的是：      代码架构 / 技术选型 / 数据模型 / 迁移方案
agent-dev-driven 的 design 想的是：  skills / commands / tools / evals / CLI / harness 适配
```

其他三步——proposal、specs、apply——和 spec-driven 基本一致。tasks 的 checklist 格式通用，只是跟踪的东西从"写代码"变成"写 agent 组件"。

## 对比 spec-driven

| artifact | 改了什么 |
|----------|---------|
| `proposal` | **不改**——Why / What Changes / Capabilities / Impact。和 spec-driven proposal 一模一样 |
| `specs` | **不改**——delta ops（ADDED/MODIFIED/REMOVED/RENAMED）+ Requirement+Scenario。agent capability 和软件 capability 规格化方式完全相同 |
| `design` | **这是唯一真正的差异**——考虑的是 agent 组件而非代码架构。模板加了 Skills / Commands / Tools / Evals / CLI 段。必写（agent 的实现方案总是需要的，不像 spec-driven 可选） |
| `tasks` | checkbox 格式通用。跟踪的东西从「代码实现（Setup / Core Implementation / …）」换成「agent 组件构建（Skills / Commands / Tools / Evals / CLI / Harness Integration / End-to-End）」 |
| `apply` | 基本不改——就绪检查 + 按 tasks 执行。多一步：把 skills/commands 拷贝到 target harness 目录 |

**requires 关系——和 spec-driven 完全一致**：

```text
proposal → specs → design → tasks → apply
```

## 推荐 config.yaml setup

和 spec-driven 一样，项目全局信息放 config.yaml。agent 的身份、硬约束、system prompt 是项目级的——第一次配好，后续 proposal 不用重复：

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

如果某个 change 需要改约束，在 proposal 的 Impact 提一句，改 config.yaml 即可。

## 关键设计决策

**1. 为什么不自建 artifact 名。** spec-driven 的 proposal/specs/design/tasks 是 OpenSpec 用户的心智模型——换名字增加无意义的认知负担。proposal 就是 proposal，不管交付物是代码还是 agent。

**2. 为什么差异只在 design。** 写代码和写 agent 的流程本质一样——都是"想清楚为什么（proposal）→ 规格化做什么（specs）→ 设计怎么做（design）→ 拆任务跟踪（tasks）→ 执行（apply）"。唯一的不同是 design 这一步的思考对象：代码架构 vs agent 组件。其他三步完全通用。

**3. 为什么 agent 身份和约束放 config.yaml，不放 proposal。** 和 spec-driven 的项目全局信息（技术栈/编码规范）放 config.yaml context 一样——agent 的 identity 和护栏是项目级的，不是 per-change 的。

## 这验证了什么

spec-driven 的框架是领域无关的——换 design 的思考对象，不改 artifact 结构，就能从软件研发切到 agent 开发。4 个模板对 4 个 artifact，和 spec-driven 同数。

## 使用方式

```bash
cp -r schema-package/ openspec/schemas/agent-dev-driven/
openspec schema validate agent-dev-driven
openspec new change build-my-agent --schema agent-dev-driven
# 然后按 proposal → specs → design → tasks 顺序写——和 spec-driven 完全一样
```

> 完整的 schema 扩展实操指南见 [`answer-add-schema.md`](answer-add-schema.md)。

## 已知限制

- OpenSpec 无模型 eval——evals 只能断言产物形状。
- `openspec change --long` 的进度计数硬编码了 `tasks.md` 文件名——和 spec-driven 一样。

---

> 完整 schema-package（`schema.yaml` + 4 个 `templates/*.md`）在 [`schema-package/`](schema-package/)。
> spec-driven 原版在 `schemas/spec-driven/schema.yaml`——本 schema 是其 instruction 级 fork。
