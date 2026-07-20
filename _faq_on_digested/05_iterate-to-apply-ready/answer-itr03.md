# 答案 ITR-03：如何批判性阅读 artifacts

## 一句话

ITR-03 不是"把 artifacts 读一遍"。它是从"这些 artifacts 真的能指导实施吗"的角度，逐个 artifact 做结构化审视。和初始 Explore 不同——初始 Explore 是从用户一句话出发做 discovery；ITR-03 是从已存在的 artifacts 出发做 critique。

## 阅读姿态：从 produce 切换到 critique

Propose 阶段 agent 的姿态是"产出"——按 schema DAG 和 template 写内容，满足 apply gate。ITR-03 的姿态是"审视"——假设 artifacts 可能有问题，逐项找。

切换的关键标志：

| 产出姿态（Propose） | 审视姿态（ITR-03） |
|---|---|
| "我需要写一个 proposal" | "这个 proposal 的 scope 说清楚了吗？" |
| "specs 要覆盖 proposal 的 capabilities" | "每个 requirement 的 scenario 真的可测吗？" |
| "tasks 按依赖排序" | "task 3.1 具体到 agent 看到就能执行吗？" |

## proposal：scope 和 impact 是审视重点

读 proposal 时不是看"有没有写"，而是看"写得够不够精确"：

| 审视点 | 具体问题 | 红灯信号 |
|---|---|---|
| Why | 一句话能说清为什么要做吗？ | "improve the system" |
| What Changes | 增量边界清楚吗？是 ADDED/MODIFIED/REMOVED？ | "refactor auth system"（太宽） |
| Capabilities | 列出的 capability 和 specs/ 目录名一致吗？ | proposal 写 `user-auth`，specs 里是 `auth` |
| Impact | 列出的文件路径真实存在吗？ | `src/auth/session.ts`——这个文件存在吗？ |
| Not included | 有没有显式排除？ | 没有 Not included 段——scope 隐式无边 |

proposal 最常见的 gap：**Impact 里列的文件名是猜的**。Propose 阶段 agent 可能没查真实代码就写了 `src/auth/session.ts`，实际 session 逻辑在三个文件里。

## specs：scenario 是审视重点

读 specs 时不是看"requirement 数量够不够"，而是看"每个 requirement 能不能被验证"：

| 审视点 | 具体问题 | 红灯信号 |
|---|---|---|
| Requirement 完整性 | 每个 requirement 至少一个 scenario 吗？ | 只有 `### Requirement: OAuth Login` 描述，没有 scenario |
| Scenario 可测性 | scenario 描述了具体的 GIVEN/WHEN/THEN？ | "User can login with GitHub"（太笼统） |
| 边界覆盖 | 有正常路径 + 至少一个异常路径？ | 只有 happy path，没有 error/empty/permission 场景 |
| Delta 语义 | ADDED/MODIFIED/REMOVED 操作是否清楚？ | MODIFIED 只写了一个新 scenario，没复制完整 block |
| 和 proposal 一致 | specs 覆盖的 capability 和 proposal 一致吗？ | proposal 写要改 auth + billing，specs 只有 auth |

specs 最常见的 gap：**只有 requirement 描述，没有 scenario，或者 scenario 是自然语言而非可验证步骤**。

## design：假设是审视重点

design 不是必选项（spec-driven DAG 允许 proposal→specs→tasks 跳过 design）。但如果存在，审视重点是它的技术假设在真实代码里是否成立：

| 审视点 | 具体问题 | 红灯信号 |
|---|---|---|
| 技术决策 | 每个决策是否说明了 why + alternatives？ | "Use Redis"（没说为什么、没考虑 alternative） |
| 假设成立性 | 提到的 abstraction/interface 在代码里存在吗？ | "使用现有 TokenStore class"——代码里是三个独立函数 |
| 影响面 | 是否说了改动涉及哪些文件/模块？ | "改 auth 模块"（没说哪个文件） |
| 迁移策略 | 如果有数据/配置变化，迁移方案写了吗？ | 新增了 OAuth token 字段但没有 migration plan |
| 风险 | 是否标了 open question 和 known risk？ | 没有任何风险标注 |

design 最常见的 gap：**假设了一个代码里不存在的 abstraction**。这是因为 Propose 阶段 agent 可能是从零设计，没有对照真实代码。

## tasks：可执行性是审视重点

tasks 是 apply 阶段的 checklist。审视重点是"agent 看到每一条就知道改哪个文件、做什么"：

| 审视点 | 具体问题 | 红灯信号 |
|---|---|---|
| 粒度 | 每个 task 是一步操作，还是一个史诗？ | "Implement OAuth login"（其实是 5-10 步） |
| 具体性 | task 描述包含文件名或明确动作吗？ | "Add tests"（没说测什么、在哪） |
| 顺序 | task 顺序反映真实依赖吗？ | task 2 依赖 task 4 的输出 |
| 覆盖 | tasks 是否覆盖了 specs 的所有 requirement？ | specs 有 3 个 requirement，tasks 只覆盖了 2 个 |
| 验证 | 是否包含测试/验证步骤？ | 只有实现步骤，没有验证步骤 |

tasks 最常见的 gap：**太粗**。Propose 阶段 agent 容易写出 "Implement X" 这种一行 task——文件存在、gate 通过、apply instructions 返回 `ready`，但一实施就卡住。

## artifacts 间的一致性

读完四个 artifacts 后，还要看它们之间是否一致：

| 对照 | 检查 |
|---|---|
| proposal ↔ specs | proposal 列出的 capability 是否在 specs 里都有对应？ |
| proposal ↔ tasks | proposal 的 scope 是否和 tasks 覆盖范围一致？ |
| specs ↔ tasks | specs 的每个 requirement 在 tasks 里至少有一个对应 task？ |
| design ↔ proposal | design 的技术决策是否服务于 proposal 的 scope？ |
| design ↔ specs | design 的约束在 specs 的 scenario 里是否有体现？ |

不一致的典型例子：proposal 写只做 GitHub OAuth，tasks 里出现了 "2.3 Add Google OAuth configuration"。

## 输出

ITR-03 的输出不应该是"我看完了"。应该是一份审视摘要：

```text
proposal: ✓ scope 清楚，Impact 文件路径待验证
specs: ⚠ OAuth callback failure 场景缺失；MODIFIED 块需确认是否完整
design: ⚠ TokenStore 假设需验证是否在真实代码中存在
tasks: ⚠ 2.1 太粗（"Implement OAuth login"），建议拆成 3-4 步
一致性: ✓ proposal/specs/tasks scope 一致
```

这份摘要直接喂给 ITR-04（代码校验）和 ITR-05（发现 gap）。

## 参考来源

源码引用基于 commit `970cb44`（Explore stance）、`750a03c`（Propose artifacts）：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore stance 可以审视架构、识别 patterns、发现风险 |
| `schemas/spec-driven/schema.yaml` | proposal/specs/design/tasks 的 template 和 instruction 定义 |
| [`answer.md`](answer.md) | 主流程和 ITR 节点说明 |
| [`../04_propose-to-apply-ready/answer-prp06.md`](../04_propose-to-apply-ready/answer-prp06.md) | instructions JSON 里 template 和 instruction 的区别 |
