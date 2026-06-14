# 答案 EXP06：问题地图怎么形成

## 一句话

EXP-06 是 Explore 里最像“工程判断”的一步。它把 EXP-04 的 OpenSpec 状态和 EXP-05 的真实代码事实，压缩成一个 pre-proposal boundary map。

这个 map 回答的不是“proposal.md 怎么写”，而是：

```text
我们现在到底知道了什么？
这个想法相对当前系统要改变什么？
变化会影响哪里？
还有哪些未知数？
有没有一个清晰 change 边界？
```

没有问题地图，agent 很容易把用户一句话硬塞进 proposal；有问题地图，propose 才有边界。

## 输入：两类事实源

EXP-06 的输入来自两边。

OpenSpec 侧：

```text
active changes
existing artifacts
openspec/specs/ baseline
artifactPaths
actionContext
```

真实项目侧：

```text
源码入口
API / CLI / UI 表面
数据模型
测试
已有 patterns
风险和耦合
```

这两类事实源可能互相冲突。比如 proposal 说只影响 `src/auth/*`，但代码调查发现 permission middleware 分散在三处 route；这时问题地图必须记录偏差，而不是无条件相信 artifact。

## 问题地图的基本结构

一个足够好的问题地图至少有七块：

| 区块 | 说明 |
|---|---|
| current state | 系统现在实际怎么工作，包括 specs 和代码事实。 |
| target state | 用户真正想要改变到什么状态。 |
| gap | current 和 target 之间差了什么能力、行为或结构。 |
| impact surface | 影响哪些 specs、modules、commands、APIs、data、tests。 |
| risks | 迁移、兼容、安全、性能、跨模块耦合、测试缺口。 |
| unknowns | 还没查清或必须由用户决策的点。 |
| candidate boundaries | 可能的一个或多个 OpenSpec change 边界。 |

这不是模板形式主义。每一块都对应后续 propose 能不能写实。

## current state：当前状态

current state 要同时说清：

```text
OpenSpec 认为现在是什么
代码实际上现在是什么
```

例如：

```text
OpenSpec specs:
- 没有 auth baseline。

代码事实:
- email login 已实现。
- GitHub OAuth 有半成品 provider。
- session 存在 Redis 和 cookie 两条路径。
- tests 只覆盖 email login。
```

如果只写“auth 系统复杂”，不算 current state。那只是感受，不是地图。

## target state：目标状态

target state 不是复述用户原话，而是把用户意图翻译成可观察目标。

用户说：

```text
auth 系统有点乱
```

可能的 target state 有很多：

```text
用户可以用 GitHub 登录
所有 provider 共享同一套 session creation
permission checks 统一由 middleware 处理
现有 auth 能力被 OpenSpec baseline 记录
```

这些目标不同，change 边界也不同。EXP-06 要把它们拆开，不要混成一个“整理 auth”。

## gap：差距

gap 是 current -> target 的桥。

例如：

| current | target | gap |
|---|---|---|
| 只有 email login specs | 支持 OAuth login | 需要新增 provider callback 和 account linking requirement |
| session 创建分散 | provider 共享 session lifecycle | 需要抽出 session service 或统一调用路径 |
| permission check 分散 | middleware 统一鉴权 | 需要 route-level policy 改造 |

gap 会直接决定 proposal 的 `What Changes`，也会决定 tasks 的拆法。

## impact surface：影响面

impact surface 不是“可能改很多文件”的泛泛说法。

它应该尽量具体：

```text
OpenSpec:
- openspec/specs/auth/spec.md 可能新增 OAuth requirements
- 如果 specs 为空，可能先补 auth baseline

Code:
- src/routes/auth.ts
- src/auth/providers/*
- src/core/session.ts
- test/auth/*

User-visible behavior:
- login page exposes OAuth provider
- callback failure returns actionable error
```

影响面越清楚，越容易判断一个 change 是否过大。

## risks：风险

risks 要记录会改变工程方案的风险，而不是泛泛说“有风险”。

例如：

- session migration 会影响已登录用户。
- provider callback 需要防 CSRF。
- permission middleware 改造可能影响所有 routes。
- tests 没有覆盖当前 OAuth half-implementation。
- workspace 模式下没有 allowed edit root。

风险类型不同，可能意味着要拆 change。

例如：

```text
add-oauth-login
centralize-permission-middleware
```

一个是新增能力，一个是 cross-cutting refactor。强行合在一个 change 里，会让 proposal 和 validation 路径变浑。

## unknowns：未知数

unknowns 是决定“继续 Explore 还是 propose”的关键。

未知数分两类：

| 类型 | 处理方式 |
|---|---|
| 可通过代码调查解决 | 继续 Explore，读文件、跑只读检查、找测试。 |
| 需要产品/架构决策 | 问用户，或列出方案让用户选。 |

例如：

```text
可调查：
- 当前 session token 是否持久化在 Redis？

需决策：
- OAuth account linking 是否允许同邮箱自动绑定？
```

如果关键未知数未解决，直接 propose 会把未知数伪装成假设。

## candidate boundaries：候选边界

问题地图最后要形成候选边界。

候选边界不是最终文件名，而是可讨论的 scope：

```text
候选 A：add-oauth-login
- 新增 OAuth provider callback 和 login behavior。
- 不处理 permission middleware 重构。

候选 B：document-auth-baseline
- 先把 email login/session 当前行为规格化。
- 不新增 OAuth。

候选 C：centralize-permission-checks
- 只处理 route permission check 分散问题。
- 与 OAuth 登录无直接依赖。
```

这样用户才能看懂 agent 为什么建议一个、多个或暂时不 propose。

## 什么时候地图足够进入 propose

可以进入 propose 的最低条件：

- 有一个清晰 change name 候选。
- 能说清 why 和 user-visible what。
- 能指出涉及的 capability 或承认需要先建立 baseline。
- 能列出主要 impact surface。
- 能说清哪些内容不纳入本 change。
- 没有阻塞级 unknowns。
- 能预期后续 artifacts：proposal、specs、design、tasks 会写什么。

如果这些条件不满足，应该继续 Explore。

## 什么时候地图还不够

这些情况通常不能急着 propose：

- 只有用户情绪，没有可观察目标。
- 只知道一个文件名，不知道能力影响。
- 只知道要新增功能，不知道当前 baseline。
- 影响面可能跨多个独立能力，但还没拆清。
- 关键风险会改变方案，例如 migration、安全模型、兼容策略。
- 用户还没在几个候选方向里做选择。

这时 Explore 应该继续读代码、提问、画方案对比，或者建议 spike。

## 输出示例

一个好的 EXP-06 输出可以像这样：

```text
我现在看到的问题地图是：

Current:
- OpenSpec 没有 auth baseline。
- 代码已有 email login，GitHub OAuth 有半成品 provider。
- session 创建分散在 routes/auth.ts 和 core/session.ts。

Target:
- 用户想先支持 GitHub OAuth 登录，而不是全面重构 auth。

Gap:
- 缺 OAuth callback requirement。
- 缺 account linking 行为定义。
- 缺 callback failure handling。

Impact:
- specs/auth/spec.md
- src/routes/oauth.ts
- src/auth/providers/*
- test/auth/*

Not included:
- permission middleware 重构。
- 登录页视觉调整。

Open questions:
- 同邮箱是否自动绑定已有账号？

如果确认 account linking 策略，我建议 propose add-github-oauth-login。
```

这不是 proposal；它是进入 proposal 之前的边界确认。

## 参考来源

源码引用基于 commit `970cb44`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore 允许 map architecture、identify patterns、surface risks and unknowns，但没有 mandatory output |
| `src/core/templates/workflows/propose.ts` | Propose 需要从 crystallized goal 进入 artifact generation |
| `schemas/spec-driven/schema.yaml` | proposal/specs/design/tasks 需要 why、capabilities、impact、technical decisions、task checklist |
| [`answer-exp04.md`](answer-exp04.md) | OpenSpec planning context |
| [`answer-exp05.md`](answer-exp05.md) | 真实项目 implementation context |
