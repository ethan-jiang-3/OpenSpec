# 答案 EXP07-11：最终分流怎么判断

## 一句话

EXP-07 到 EXP-11 是 Explore 的出口判断。它回答：

```text
继续探索？
更新已有 change？
propose 一个？
propose 多个？
不创建 change？
```

这一步不能由 OpenSpec CLI 自动算出。CLI 提供状态，agent 提供工程判断，用户确认方向。

## 总体判断顺序

推荐顺序是：

```text
1. 事实够不够？
2. 是否已有相关 active change？
3. 是否真的需要 formalize 成 OpenSpec change？
4. 如果需要，是一个边界还是多个边界？
5. 输出候选 scope，让用户确认。
```

不要一开始就问“change name 叫什么”。change name 是边界稳定后的结果。

## EXP-07：继续 Explore

继续 Explore 成立于：

- 用户目标还只是感受或方向，没有可观察目标。
- 当前代码事实不足以判断影响面。
- OpenSpec baseline 和代码事实冲突，尚未解释清。
- 关键未知数会改变方案。
- 存在多个候选方向，用户还没选择。
- 风险类型不清，比如迁移、安全、兼容、跨 repo ownership。

典型输出：

```text
我还不建议 propose。现在缺两个关键事实：
1. session token 是否在 Redis 中持久化。
2. OAuth account linking 的产品策略。

我建议继续 Explore：先读 session store 和现有 auth tests，再决定是 add-oauth-login 还是先 document-auth-baseline。
```

继续 Explore 不是拖延，而是避免把未知数写进 proposal 里伪装成决定。

## EXP-08：更新已有 change

如果已有 active change 覆盖同一 scope，应优先更新它。

判断标准：

- 用户提到的方向和已有 proposal 的 why/what 一致。
- 新发现只是补充 design、specs 或 tasks。
- 新事实推翻了已有 artifact 的假设，但目标仍是同一个 change。
- 新需求是原 change 的必要组成，而不是独立能力。

这时不应该新开 change。

更好的输出：

```text
这看起来属于现有 change add-oauth-login，而不是新 change。

原因：
- proposal 已经把 OAuth login 作为目标。
- 新发现是 callback failure handling，属于同一用户可观察能力。
- 应该更新 specs/auth/spec.md 和 tasks.md。

下一步建议用 /opsx:continue add-oauth-login 补 artifacts。
```

更新已有 change 的价值是避免 planning 分叉。

## EXP-09：propose 一个

propose 一个新 change 成立于：

- 有一个清晰、可命名的增量目标。
- 变化服务同一个用户可观察结果。
- 主要 capability 边界清楚。
- impact surface 虽然可能跨多个文件，但服务同一目标。
- 风险和验证路径可以放进一套 proposal/design/tasks。
- 没有明显相关 active change。

例子：

```text
add-github-oauth-login
```

它可能改 routes、provider、session、tests，但用户可观察目标是一件事：用户能用 GitHub 登录。

推荐输出：

```text
我建议 propose 一个 change：add-github-oauth-login

Scope:
- 新增 GitHub OAuth callback。
- 定义 account linking 行为。
- 增加 callback error handling。

Not included:
- permission middleware 重构。
- 登录页视觉调整。

Impact:
- openspec/specs/auth/spec.md
- src/routes/oauth.ts
- src/auth/providers/*
- test/auth/*

Open questions:
- 同邮箱是否自动绑定已有账号？
```

如果 open question 是阻塞性的，先问清；如果不是阻塞，可以在 proposal/design 中标为 open question。

## EXP-10：propose 多个

propose 多个 changes 成立于：

- 用户话题包含多个独立能力。
- 每个能力可以独立交付、验证、archive。
- 不同部分属于不同 risk class。
- 不同部分由不同 repo/module owner 负责。
- 一个部分是前置 baseline/infrastructure，另一个是用户功能。
- 强行合并会让 proposal 变成大杂烩。

拆分不是按文件数，而是按工程语义。

### 常见拆分模式

| 模式 | 拆法 |
|---|---|
| baseline + new capability | 先 document current behavior，再新增能力。 |
| infrastructure + feature | 先建底层机制，再做用户可见功能。 |
| behavior + refactor | 用户行为变化和内部整理分开。 |
| cross-repo ownership | 不同 repo/area 分别成 change。 |
| risky migration + UI/API | 迁移先独立，表层能力后做。 |

例子：

```text
用户说：auth 系统有点乱，还想加 OAuth。

拆成：
1. document-auth-baseline
2. add-github-oauth-login
3. centralize-permission-checks
```

这三个都碰 auth，但它们的价值、风险和验证路径不同。

推荐输出：

```text
我不建议放进一个 change。这里至少有两个边界：

Change A: document-auth-baseline
- 记录当前 email login/session 行为。
- 价值是建立 specs baseline。

Change B: add-github-oauth-login
- 新增用户可见 OAuth login。
- 依赖 A 之后更好写 delta。

Change C 暂缓: centralize-permission-checks
- 这是 cross-cutting refactor，风险独立。
```

## EXP-11：不创建 change

不创建 change 也可能是正确结论。

成立于：

- 用户只是想理解系统现状。
- 这是一次临时调查，不形成持久能力变化。
- 变化太小，不值得进入 OpenSpec artifact DAG。
- 只是回答问题、画架构图、解释 tradeoff。
- 发现用户意图其实已经被当前系统满足。
- 问题属于普通代码维护，不改变 specs 或行为协议。

典型输出：

```text
我不建议创建 OpenSpec change。

原因：
- 这次只是确认 archive CLI 和 /opsx:archive 的执行路径差异。
- 没有要改变用户可观察行为或 OpenSpec 文件协议。
- 结论可以记录在 FAQ，不需要 proposal/specs/tasks。
```

不创建 change 不是失败。OpenSpec 的价值之一就是不把所有思考都强行 formalize。

## 判断表

| 分流 | 核心问题 | 结果 |
|---|---|---|
| 继续 Explore | 事实或决策还不足吗？ | 继续调查、提问、比较方案。 |
| 更新已有 change | 已有 active change 覆盖同一 scope 吗？ | 用 `/opsx:continue` 或更新 artifacts。 |
| propose 一个 | 是否有一个清晰、可验证的增量目标？ | 建议一个 change name 和 scope。 |
| propose 多个 | 是否存在多个独立交付/风险/能力边界？ | 先给拆分方案，再逐个 formalize。 |
| 不创建 change | 是否只是理解、调查或无需规格化？ | 输出结论，不制造 change。 |

## 推荐的 Explore 收束输出

无论最后选择哪条分流，agent 都应该把判断讲清楚。

推荐格式：

```text
结论：
  propose 一个 / propose 多个 / 更新已有 / 继续探索 / 不创建

依据：
  从 OpenSpec 状态看到什么
  从真实代码看到什么
  用户目标被怎样解释

Scope:
  纳入什么
  不纳入什么

Impact:
  specs / code / tests / docs / data

Open questions:
  还需要用户确认什么

Next:
  /opsx:propose <name>
  或 /opsx:continue <name>
  或继续 Explore
```

这段输出是 Explore 到 Propose 的桥。它让用户在文件被创建之前确认边界。

## 参考来源

源码引用基于 commit `970cb44`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore 没有固定 ending；可能流向 proposal、artifact updates、clarity 或 later continuation |
| `src/core/templates/workflows/propose.ts` | Propose 从已明确的 change name/description 开始 |
| `src/core/templates/workflows/continue-change.ts` | 已有 change 的 artifact 补充应走 continue/update 语义 |
| [`answer-exp04.md`](answer-exp04.md) | active changes 和 artifacts 的读取机制 |
| [`answer-exp06.md`](answer-exp06.md) | 问题地图如何形成分流判断 |
