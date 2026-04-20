# 09 · 高级：`config.yaml` 怎么写到真正好用

> 到了这一步，问题已经不是“全局约束该放哪”，而是更现实的一层：
> **就算我知道它们该放进 `config.yaml`，那我到底该怎么写，才不会写成一堆正确但无用的话？**

---

## 这一篇解决什么问题

很多团队第一次写 `openspec/config.yaml` 时，都会落入两种极端：

### 极端 1：写得太少

比如只写：

```yaml
schema: spec-driven
```

这当然不算错。

但它几乎没有给项目提供任何真正的工程约束。

### 极端 2：写得太空

比如写一堆看起来很高级的话：

```yaml
rules: |
  - Keep code clean
  - Follow best practices
  - Write good tests
  - Maintain code quality
```

这种写法的问题是：

- 谁都不会反对
- 但谁也不知道它具体意味着什么
- AI 看了也很难据此做更稳定的判断

所以真正难的不是“有没有 `config.yaml`”，而是：

> **怎样把它写成一份对项目真的有约束力、对 AI 真的有帮助的配置。**

---

## 先钉住一个总原则

好的 `config.yaml` 不是产品需求文档，也不是团队口号板。

它更像：

- 项目级长期背景
- 项目级工程宪法
- 默认 change 写作与实施的稳定前提

所以写它时最该问的不是：

- “还有什么能往里塞？”

而是：

- “哪些信息一旦长期稳定地写在这里，会显著提高后续所有 change 的质量？”

---

## 一份真正好用的 `config.yaml`，通常有 3 个特征

### 1. 它写的是“高杠杆信息”

也就是一条规则一旦写进去，会影响很多 change。

比如：

- 目录按能力域组织
- 审批相关改动必须守住授权回归
- 用户可见行为变更需要 unhappy path

这些都属于高杠杆信息。

---

### 2. 它写的是“可判断的信息”

好的规则会让人和 AI 在面对具体 change 时，知道该怎么判断。

比如：

- “审批相关改动必须保住授权 regression”

就比：

- “要有完善测试”

强得多。

因为前者有对象、有范围、有判断方向。

---

### 3. 它写的是“长期稳定的信息”

如果一条内容只对当前 change 有意义，就不该上升为项目全局配置。

比如：

- “这次加一个异步 worker”
- “这次补 3 个集成测试”

这些都不该进 `config.yaml`。

---

## 一个最实用的写法框架

我建议大多数项目都用下面这种最朴素也最稳的结构：

```yaml
schema: spec-driven

context: |
  ...

rules: |
  ...
```

这里的重点不在字段多少，而在于分工清晰：

- `schema`：默认 change 结构选择
- `context`：项目长期背景
- `rules`：项目长期工程纪律

只要这三层不混，`config.yaml` 就比较容易保持质量。

---

## `context` 到底该怎么写

`context` 最常见的问题不是少，而是乱。

很多人会把 `context` 写成：

- 产品 PRD 摘要
- 当前这个 sprint 的临时目标
- 一堆不稳定的细节

这都不太好。

### `context` 更适合写什么

- 项目是什么
- 核心领域是什么
- 技术栈是什么
- 哪些质量属性特别重要
- 有没有兼容性、审计性、可靠性等长期背景

### 一个较弱的 `context`

```yaml
context: |
  This project is a web app.
```

这太空了。

### 一个更强的 `context`

```yaml
context: |
  Project: ProcureFlow
  Domain: Internal procurement request and approval platform
  Stack: TypeScript, React, Node.js, PostgreSQL
  Quality priorities:
  - correctness of approval decisions
  - auditability of critical actions
  - maintainable domain boundaries
  Compatibility:
  - avoid breaking existing public APIs once published
```

这段的价值在于，它给了 AI 和人一套长期稳定的判断背景：

- 这是审批型系统，不是娱乐型产品
- 审批正确性和审计是重点
- 模块边界很重要

这种背景会直接影响：

- spec 怎么写
- design 怎么取舍
- regression 怎么想

---

## `rules` 到底该怎么写

`rules` 是最容易沦为口号区的地方。

想写好它，最重要的是把“抽象正确”写成“可执行约束”。

### 一个很弱的规则

```yaml
rules: |
  - Write clean code
  - Test carefully
  - Avoid bugs
```

它的问题是：

- 太空
- 没有作用对象
- 没有触发条件
- 没有判断方向

### 一个更强的规则

```yaml
rules: |
  - Keep code organized by domain capability first, not by technical layer only
  - Reflect new user-visible behavior in OpenSpec artifacts before or during implementation
  - Core approval logic should be developed test-first when feasible
  - Approval-related changes must preserve authorization regression coverage
  - Do not bypass published domain interfaces with cross-module internal imports
```

这组规则更强，是因为它们更像真实项目里的判断器。

它们告诉你：

- 什么是好的目录演化方向
- 什么类型的改动必须先补工件
- 哪些逻辑最好 test-first
- 哪类 regression 绝不能掉
- 哪种实现方式属于架构违规

---

## 把“空规则”改写成“强规则”

这一步最值钱。

下面给几组常见改写。

### 从弱到强 1

弱：

```text
Write good tests
```

强：

```text
Changes affecting approval decisions must preserve authorization regression coverage.
```

为什么更好：

- 有明确作用对象：approval decisions
- 有明确要求：preserve regression coverage

---

### 从弱到强 2

弱：

```text
Keep code clean
```

强：

```text
Keep code grouped by domain capability first, and avoid cross-module imports that bypass published interfaces.
```

为什么更好：

- “clean” 被具体化成结构和边界约束

---

### 从弱到强 3

弱：

```text
Document changes properly
```

强：

```text
New user-visible behavior should be reflected in OpenSpec artifacts before or during implementation.
```

为什么更好：

- 明确了“document”不是随便写点说明
- 明确了什么时候要反映到工件里

---

### 从弱到强 4

弱：

```text
Avoid breaking things
```

强：

```text
Public API behavior must remain backward compatible unless the change explicitly documents and approves a breaking contract update.
```

为什么更好：

- 指明了对象：public API behavior
- 指明了例外条件：明确记录并批准 breaking change

---

## 一个简单的“强规则公式”

如果你不知道一条规则怎么写强，可以套这个公式：

> **当某类改动发生时，必须满足某个明确约束。**

模板长这样：

```text
Changes affecting <对象> must <约束>.
```

或者：

```text
Do not <危险行为> unless <例外条件>.
```

或者：

```text
Keep <结构对象> organized by <组织原则>.
```

这三类句式，通常都比空泛口号更有用。

---

## 推荐把 `rules` 分成 4 个小簇

这不是必须，但很实用。

### 1. 结构类规则

比如：

- 目录结构
- 模块边界
- import 纪律

### 2. 工件类规则

比如：

- 用户可见行为变化要进 OpenSpec artifacts
- spec 要补 unhappy path
- design 要说明迁移风险

### 3. 测试类规则

比如：

- 哪类逻辑 test-first
- 哪类改动必须保住哪种 regression

### 4. 风险类规则

比如：

- 不允许静默改行为
- 不允许绕过授权
- 审计记录 append-only

把这 4 类分开，`rules` 会更像工程规则，而不是一团散句。

---

## 一个“弱配置”和“强配置”的对照

这一组对照最能看出差别。

### 弱配置

```yaml
schema: spec-driven

context: |
  TypeScript project

rules: |
  - Keep code clean
  - Write tests
  - Follow best practices
```

### 为什么弱

- `context` 太空
- `rules` 全是口号
- 没有项目类型感
- 没有风险重点
- 没有结构约束

---

### 强配置

```yaml
schema: spec-driven

context: |
  Project: ProcureFlow
  Domain: Internal procurement request and approval platform
  Stack: TypeScript, React, Node.js, PostgreSQL
  Quality priorities:
  - correctness of approval decisions
  - auditability of critical actions
  - maintainable domain boundaries

rules: |
  Structure:
  - Keep code organized by domain capability first
  - Shared UI belongs in src/ui/
  - Avoid cross-module imports that bypass published interfaces

  Artifacts:
  - New user-visible behavior should be reflected in OpenSpec artifacts before or during implementation
  - Changes affecting role-sensitive behavior should include explicit scenarios in specs
  - Design documents should explain migration or rollout risks when behavior changes existing flows

  Testing:
  - Core approval logic should be developed test-first when feasible
  - Approval-related changes must preserve authorization regression coverage
  - Notification-related changes must verify decision-triggered notification flow

  Risk:
  - Do not merge changes with incomplete authorization checks
  - Keep audit records append-only
  - Avoid silent behavioral rewrites of existing user-visible flows
```

### 为什么强

- 有项目类型
- 有质量重心
- 有结构约束
- 有工件要求
- 有测试重点
- 有风险红线

---

## `context` 和 `rules` 最常见的 6 个坏味道

### 坏味道 1：太像 PRD

如果你开始在 `context` 里写：

- 用户画像
- 本季度目标
- 详细功能列表

那通常已经偏了。

这些东西更适合：

- 单次 change 的 `proposal`
- 或正式能力 spec

---

### 坏味道 2：太像标语

比如：

- be professional
- write maintainable code
- focus on quality

这类话几乎没有判断力。

---

### 坏味道 3：太像一次性任务

比如：

- add three tests for export
- implement queue worker

这不该进 `config.yaml`。

它们属于某次 change 的任务和方案。

---

### 坏味道 4：太像系统能力清单

比如：

- system supports approval
- system supports notifications

这属于 `specs/`，不是全局配置。

---

### 坏味道 5：太像 schema 说明

比如：

- every change must include proposal/specs/design/tasks

这已经不是普通规则，而更像 change 结构定义。

应该去看 schema。

---

### 坏味道 6：太长但信息密度太低

有些 `rules` 写了 80 行，但全是：

- 尽量
- 注意
- 保持
- 认真
- 合理

这种长度没有价值。

`config.yaml` 不是越长越强，而是越能帮助判断越强。

---

## 一个很实用的写作流程

如果你从零开始写一份 `config.yaml`，我建议按下面 5 步来。

### 第 1 步：先写 4 行 `context`

先只写：

- 项目名
- 领域
- 技术栈
- 质量重点

不要一开始就想写满。

---

### 第 2 步：列出 5 条“跨很多 change 都成立”的规则

比如：

- 目录结构
- 模块边界
- 工件反映要求
- 测试重点
- 风险底线

如果一条规则你觉得只对当前 change 有意义，就先别放进去。

---

### 第 3 步：把每条规则改写成“强规则”

把：

- clean
- proper
- enough
- best practice

这种词尽量去掉。

改成：

- 对象
- 条件
- 约束

明确的句子。

---

### 第 4 步：删掉低价值重复项

比如这些往往可以删：

- write good code
- maintain quality
- keep things clean

因为它们已经被更具体的规则覆盖了。

---

### 第 5 步：用 3 个真实 change 反推它是否有用

拿 3 个典型 change 试问：

1. 这份配置能帮我写出更稳的 proposal/spec/design/tasks 吗
2. 它能帮 AI 避免一些常见跑偏吗
3. 它能帮 reviewer 更一致地判断质量吗

如果这三问都答不上来，说明这份配置还太空。

---

## 给 4 类项目各来一份“好用版”配置

这一节我不追求面面俱到，而是追求“有手感”。

---

## 样例 A：企业内部审批系统

```yaml
schema: spec-driven

context: |
  Domain: internal approvals and workflow operations
  Stack: TypeScript, React, Node.js, PostgreSQL
  Priority:
  - authorization correctness
  - auditability
  - stable domain boundaries

rules: |
  Structure:
  - Organize code by domain capability
  - Avoid cross-module imports that bypass published interfaces

  Artifacts:
  - Role-sensitive behavior changes should include explicit scenarios in specs
  - Existing workflow changes should document rollout or migration risk in design

  Testing:
  - Approval logic should be developed test-first when feasible
  - Approval-related changes must preserve authorization regression coverage
  - Audit-related changes must verify lifecycle events are still recorded

  Risk:
  - Do not merge changes with incomplete authorization checks
  - Keep audit records append-only
```

### 适合什么项目

- 审批
- 采购
- 报销
- 风控

---

## 样例 B：外部 API 平台

```yaml
schema: spec-driven

context: |
  Domain: external partner API platform
  Stack: TypeScript, Node.js, PostgreSQL
  Priority:
  - backward compatibility
  - observability
  - safe schema evolution

rules: |
  Artifacts:
  - Public API behavior changes should include happy-path and error-path scenarios in specs
  - Breaking API updates must be explicitly documented and approved
  - Database migration risk should be explained in design

  Testing:
  - Published endpoints must preserve integration coverage
  - Authorization and rate-limit behavior must remain covered for public APIs

  Risk:
  - Avoid silent contract changes
  - Keep logging and metrics available for critical endpoints
```

### 适合什么项目

- 开放平台
- B2B 接口服务
- 平台型后端

---

## 样例 C：前端 SaaS 控制台

```yaml
schema: spec-driven

context: |
  Domain: admin console for SaaS product operations
  Stack: TypeScript, React, Vite
  Priority:
  - predictable interaction behavior
  - accessible UI flows
  - maintainable feature boundaries

rules: |
  Structure:
  - Shared UI belongs in src/ui/
  - Feature screens belong in src/features/<feature>/

  Artifacts:
  - New user-visible flows should include happy-path and unhappy-path scenarios in specs
  - Changes to critical UI flows should explain state and error handling in design

  Testing:
  - Critical admin flows should preserve regression coverage
  - Accessibility-impacting changes should verify keyboard and focus behavior

  Risk:
  - Avoid hidden coupling across features
  - Avoid silent changes to established interaction patterns
```

### 适合什么项目

- 中后台
- SaaS 控制台
- 管理平台

---

## 样例 D：数据处理或任务编排系统

```yaml
schema: spec-driven

context: |
  Domain: data processing and workflow orchestration
  Stack: Python, PostgreSQL, background workers
  Priority:
  - correctness of job execution
  - retry safety
  - operational observability

rules: |
  Artifacts:
  - Changes to job behavior should document failure and retry scenarios in specs
  - Design should explain retry strategy and idempotency considerations

  Testing:
  - Job state transitions should be verified with focused tests
  - Changes affecting scheduling or retries must preserve regression coverage for duplicate execution risks

  Risk:
  - Avoid non-idempotent side effects without explicit safeguards
  - Critical background workflows should remain observable through logs or metrics
```

### 适合什么项目

- 任务队列
- 调度系统
- 数据管道

---

## 什么时候应该收紧配置，什么时候应该保持轻量

不是所有项目都要写得一样重。

### 适合写得更重的项目

- 审批和权限敏感系统
- API 契约稳定性要求高的系统
- 审计和合规要求高的系统
- 多人并行、大量 change 的中大型项目

### 适合保持更轻的项目

- 早期探索性原型
- 单人快速迭代工具
- 生命周期很短的内部脚本产品

但即便是轻量项目，也不意味着写空话。

轻量不等于空洞。

---

## 一个“轻配置”示例

如果项目很轻，可以这样写：

```yaml
schema: spec-driven

context: |
  Stack: TypeScript, React, Node.js
  Priority:
  - fast iteration
  - predictable user-visible behavior

rules: |
  - New user-visible behavior should be reflected in OpenSpec artifacts
  - Shared UI belongs in src/ui/
  - Critical user flows should keep regression coverage green
```

这已经比“Write good code”强很多了。

---

## 一个“强配置”示例

如果项目风险高，可以这样写：

```yaml
schema: spec-driven

context: |
  Domain: internal approval and audit workflow
  Stack: TypeScript, React, Node.js, PostgreSQL
  Priority:
  - authorization correctness
  - auditability
  - safe rollout of workflow changes

rules: |
  Structure:
  - Organize code by domain capability first
  - Avoid cross-module imports that bypass published interfaces

  Artifacts:
  - Role-sensitive behavior changes should include explicit scenarios in specs
  - Design should explain rollout or migration risk for existing workflow changes

  Testing:
  - Approval logic should be developed test-first when feasible
  - Approval-related changes must preserve authorization regression coverage
  - Audit-related changes must verify lifecycle events are still recorded

  Risk:
  - Do not merge changes with incomplete authorization checks
  - Keep audit records append-only
  - Avoid silent behavior changes in established workflows
```

重点不是字多，而是：

- 每一条都能帮助判断

---

## 最后的压缩结论

如果把整篇压成 7 句话，大概就是：

1. `config.yaml` 不该只存在，它还必须写得有判断力
2. 好的 `context` 提供长期稳定背景，不提供临时需求碎片
3. 好的 `rules` 不是口号，而是可作用于真实 change 的工程约束
4. “对象 + 条件 + 约束”通常比“best practices”更有用
5. 写完配置后，最好用几个真实 change 反推它是否真有帮助
6. 轻配置可以短，但不能空
7. 强配置可以更重，但不能变成垃圾桶

---

## 下一步怎么读

如果你想继续看：

- 全局层到底放哪
- 从零起步时第一版系统怎么切

回看：

- [08-高级-项目级全局约束到底放哪.md](08-高级-项目级全局约束到底放哪.md)
- [07-案例-从零开始设计一个较复杂系统.md](07-案例-从零开始设计一个较复杂系统.md)

如果你准备继续往机器层走，看：

- 宿主 agent 怎么读取这些规则
- CLI 返回的结构化上下文如何参与流程

再看：

- [90-附录-给机器看的-agent-协议.md](90-附录-给机器看的-agent-协议.md)
