# 答案 ITR-05：gap 类型、分类和修复策略

## 一句话

ITR-05 接收 ITR-03（审视摘要）和 ITR-04（代码对照表），把所有偏差分类成六种 gap 类型，每种有对应的修复策略。不是所有 gap 都需要回 Explore——小修直接改文件，大修才需要重新讨论 scope。

## 六种 gap 类型

### 类型 1：scope 偏差

proposal 的 scope/impact 和代码事实不一致。

| 表现 | 例子 | 严重程度 |
|---|---|---|
| Impact 路径错误 | proposal 写 `src/auth/session.ts`，session 逻辑实际分散在 3 个文件 | 中 |
| scope 过大 | proposal 写"重构 auth 系统"，实际只需要加 OAuth | 高 |
| scope 过小 | proposal 只写了 UI 改动，但 specs 暗示需要 API 改动 | 高 |
| 遗漏受影响模块 | proposal 没有提到 permission middleware，但 OAuth 会改权限判断 | 中 |

**修复策略**：

| gap 大小 | 修法 |
|---|---|
| 路径修正（改一两个文件路径） | 直接编辑 proposal.md |
| 影响面补充（多列几个文件） | 直接编辑 proposal.md |
| scope 重新定义（"重构 auth"→ 拆成 3 个 change） | 回到 Explore，重新讨论 scope，可能需要拆 change |
| 根本性的 scope 错误 | 回到 Explore，重新做问题地图 |

### 类型 2：specs 不完整

specs 的 requirement/scenario 不足以指导实施和验证。

| 表现 | 例子 | 严重程度 |
|---|---|---|
| 缺 scenario | `### Requirement: OAuth Login` 只有描述，没有 `#### Scenario:` | 高 |
| scenario 不可测 | "User can login with GitHub"（没有 GIVEN/WHEN/THEN） | 高 |
| 缺边界场景 | 只有正常登录成功，没有 token 过期、callback 错误、账号已绑定 | 中 |
| 缺 requirement | specs 漏了整个 capability（如 token refresh） | 高 |
| Delta 语义错误 | MODIFIED 只写了一个新 scenario，没复制完整 requirement block | 高 |

**修复策略**：

| gap 大小 | 修法 |
|---|---|
| 补一两个 scenario | 直接编辑 specs/*.md，按 spec format 补充 |
| 补整个 requirement | 直接编辑 specs/*.md，新增 `### Requirement:` + scenarios |
| MODIFIED 不完整 | 从 main spec 复制完整 requirement block，加入新 scenario |
| specs 结构性问题（多个 requirement 缺失） | 用 `/opsx:continue` 重新生成 specs artifact |
| capability 边界不清 | 回到 Explore，重新讨论 capability 划分 |

specs 的 MODIFIED 是最容易出错的地方。CLI archive 做的是完整替换，不是智能 patch。所以 MODIFIED 必须包含完整 requirement block，包括所有已有 scenario。ITR-03 审视时要特别检查这一点。

### 类型 3：design 假设被代码推翻

design 里的技术决策、架构假设、abstraction 引用和真实代码对不上。

| 表现 | 例子 | 严重程度 |
|---|---|---|
| abstraction 不存在 | design 写"使用 TokenStore class"，代码里是 3 个独立函数 | 高 |
| 接口形态不同 | design 假设 `createSession(user, provider)`，代码里是 `createSession(req, res)` | 高 |
| 架构假设错误 | design 假设 routes→controllers→services 三层，代码没有 services 层 | 高 |
| 技术栈不匹配 | design 写"用 Redis 做 session store"，项目用 PostgreSQL | 中 |
| 约束矛盾 | design 写"保持向后兼容"，但 specs 要求改 API response 格式 | 中 |

**修复策略**：

| gap 大小 | 修法 |
|---|---|
| 修正技术细节（改名、改接口签名） | 直接编辑 design.md |
| 补充缺失的 abstraction 说明 | 直接编辑 design.md |
| 架构假设根本性错误 | 回到 Explore，重新讨论技术方案 |
| design 需要推翻重来 | 回到 Explore → 更新 design.md（可能通过 /opsx:continue） |

### 类型 4：tasks 不可执行

tasks 太粗、太模糊、或和实际代码结构不匹配。

| 表现 | 例子 | 严重程度 |
|---|---|---|
| 太粗 | "Implement OAuth login" | 高 |
| 太模糊 | "Add tests"（没说什么测试、在哪、测什么） | 高 |
| 顺序错误 | task 2 依赖 task 4 的输出 | 中 |
| 遗漏步骤 | specs 要求 migration，tasks 没写 migration task | 高 |
| 和代码结构不匹配 | tasks 按 feature 拆，但代码按 layer 组织 | 中 |
| 没有验证步骤 | 只有实现 tasks，没有测试/验证 tasks | 中 |

**修复策略**：

| gap 大小 | 修法 |
|---|---|
| 拆粗 task | 直接编辑 tasks.md，把一行拆成 3-5 行 |
| 补充验证步骤 | 直接编辑 tasks.md，在实现 task 后加验证 task |
| 调整顺序 | 直接编辑 tasks.md |
| tasks 结构性问题（大量 task 需要重写） | 用 `/opsx:continue` 重新生成 tasks artifact |
| task 粒度原则不清楚 | 参考 codebase 的 commit 粒度或 PR 大小来决定 task 粒度 |

好的 task 标准：agent 看到 task 描述就知道去改哪个文件、改成什么样。例如 `- [ ] 1.1 Create src/routes/oauth.ts with GET/POST /auth/oauth/callback route`。

### 类型 5：artifacts 间不一致

proposal、specs、design、tasks 之间的内容互相矛盾。

| 表现 | 例子 | 严重程度 |
|---|---|---|
| proposal vs specs | proposal 列了 auth + billing，specs 只写了 auth | 高 |
| proposal vs tasks | proposal scope 是"GitHub OAuth"，tasks 出现了 Google OAuth | 高 |
| specs vs tasks | specs 有 3 个 requirement，tasks 只覆盖了 2 个 | 高 |
| design vs proposal | design 的方案服务于一个比 proposal 更大的 scope | 中 |
| design vs specs | design 的技术约束在 specs scenario 里没有体现 | 中 |

**修复策略**：

不一致时，需要确定"谁是对的"。通常是 specs > proposal > design > tasks 的优先级（因为 specs 是最接近"系统应该怎样"的定义）：

1. 确定哪一方是正确的
2. 修改错误的一方使其一致
3. 如果无法确定，回到 Explore 和用户确认

### 类型 6：遗漏 artifact

DAG 允许某 artifact 缺失，但实际上这个 change 需要它。

| 表现 | 例子 | 严重程度 |
|---|---|---|
| 缺 design | change 涉及跨模块重构、新数据模型，但没有 design.md | 中 |
| 缺 proposal 细节 | proposal 存在但缺少 Not included 段 | 低 |

**修复策略**：

| gap | 修法 |
|---|---|
| 缺 design（change 复杂需要） | `/opsx:continue` 生成 design artifact |
| 缺 proposal 细节 | 直接编辑 proposal.md |

## gap 严重程度和行动指南

| 严重程度 | 典型 gap | 是否阻塞 apply |
|---|---|---|
| 高 | scope 错误、specs 缺 requirement、design 假设被推翻、tasks 太粗、artifacts 矛盾 | **阻塞**，必须先修 |
| 中 | Impact 路径不全、缺边界 scenario、tasks 顺序小问题、文件路径偏差 | 建议修，可标记为 risk 后 continue |
| 低 | 拼写、格式、缺 Not included | 可在 apply 过程中顺手修 |

## 修复后的回环

ITR-05 的修复只是"改了文件"。改完之后必须回到 ITR-03 再审一轮：

```text
ITR-03 审视 → ITR-04 校验 → ITR-05 发现 gap
  → 修 gap
  → 回到 ITR-03 再审
```

因为修一个 gap 可能引入新 gap（改了 proposal scope 之后 specs 可能需要调整，拆了 tasks 之后顺序可能需要重排）。

通常 1-3 轮就够了。复杂 change 可能需要更多。

## 输出

ITR-05 的输出应该是一份 gap 清单 + 修复计划：

```text
发现 3 个 gap：

[高] specs 缺 OAuth callback 失败场景
  → 直接编辑 specs/auth/spec.md，补充 #### Scenario: GitHub API returns error

[高] design 假设的 TokenStore class 在代码里不存在
  → 更新 design.md：将 "TokenStore class" 改成
    "createToken/validateToken/revokeToken 三个函数在 src/auth/tokens.ts"

[中] task 2.1 "Implement OAuth login" 太粗
  → 拆成：
    2.1 创建 src/routes/oauth.ts + GET/POST callback route
    2.2 实现 GitHub OAuth provider 在 src/auth/providers/github.ts
    2.3 扩展 session 创建逻辑在 src/core/session.ts

修复后回到 ITR-03 再审一轮。
```

## 参考来源

| 来源 | 用到的结论 |
|---|---|
| `schemas/spec-driven/schema.yaml` | proposal/specs/design/tasks 的定义和 DAG 关系 |
| `src/core/artifact-graph/graph.ts` | artifact DAG 的 requires/generates 约束 |
| `src/core/templates/workflows/continue-change.ts` | `/opsx:continue` 的 artifact 补充机制 |
| [`../03_explore-to-propose-change/answer-exp07-11.md`](../03_explore-to-propose-change/answer-exp07-11.md) | 分流判断的标准（何时回 Explore、何时拆 change） |
| [`answer-itr03.md`](answer-itr03.md) | 上游：批判性阅读 artifacts |
| [`answer-itr04.md`](answer-itr04.md) | 上游：代码校验对照表 |
