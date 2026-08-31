# 答案 ITR-04：如何拿真实代码校验 artifacts

## 一句话

ITR-04 把 ITR-03 的审视摘要变成具体验证动作：从 artifacts 里提取可验证的声称（"文件 X 存在""接口 Y 长这样"），然后去真实代码里逐一核对。

它和初始 Explore 的 EXP-05 共享同一套方法（rg 搜索、读源码、看测试），但起点不同：EXP-05 从用户意图出发做 discovery，ITR-04 从 artifact 声称出发做 verification。

## 从 artifact 里提取可验证声称

不是 artifact 里每句话都能直接验证。先要提取出**可证伪的声称**：

| artifact 里的表述 | 可验证声称 | 验证方法 |
|---|---|---|
| "Impact: src/auth/session.ts" | `src/auth/session.ts` 存在 | `ls` 或读文件 |
| "使用现有 token store" | 存在一个叫 token store 的东西 | rg `token.*store\|TokenStore` |
| "session 生命周期在 core/session.ts" | session 创建/销毁逻辑在这个文件里 | 读文件，确认逻辑集中在此 |
| "OAuth callback 在 routes/oauth.ts" | 这个 route 文件存在且包含 callback handler | 读文件，rg `callback` |
| "现有测试覆盖 email login" | `test/` 下存在 email login 相关测试 | rg `email.*login\|login.*email` test/ |
| "permission check 在 middleware 层" | permission 相关逻辑在 middleware 目录 | rg `permission\|authz\|canAccess` |

关键是：只验证那些**如果错了会影响实施的声称**。artifact 里的背景描述（"用户现在只能 email 登录"）通常不需要逐字验证。

## 校验顺序：从粗到细

推荐的校验顺序：

```text
1. 文件存在性    → artifact 里列的文件路径真实存在吗？
2. 符号存在性    → artifact 里提到的 class/function/interface 存在吗？
3. 行为一致性    → artifact 里描述的系统行为是否和代码事实匹配？
4. 结构一致性    → artifact 里假设的架构/模块划分是否和代码一致？
5. 测试覆盖      → artifact 里声称的测试是否存在、是否通过？
```

这个顺序是有意的：先做便宜检查（文件存在），再做贵检查（行为一致性）。如果第一步就发现文件不存在，后面的就不用做了。

## 具体操作

### 1. 文件存在性

```bash
# 从 proposal Impact 和 design 的技术决策里提取文件路径
ls src/auth/session.ts          # 存在？
ls src/routes/oauth.ts          # 存在？
```

如果文件不存在，不一定是 artifact 错了——可能是文件名写错、路径写错、或者文件还没创建（本次 change 要新增的）。需要区分：

| 情况 | 判断 |
|---|---|
| artifact 声称"修改 X"但文件不存在 | gap：artifact 路径错误 |
| artifact 声称"新增 X"且文件不存在 | 正常：还没创建 |

### 2. 符号存在性

```bash
# 从 design 的技术决策里提取 class/function/interface 名
rg "class TokenStore|export.*TokenStore" src/
rg "function createSession|export.*createSession" src/
```

如果 design 里假设的 abstraction 在代码里不存在或形态不同，这是个重要 gap。

### 3. 行为一致性

这是最贵但最有价值的检查。读 artifact 里描述的行为，再去代码里找实现：

```text
specs 声称："用户登录失败 3 次后账号锁定 15 分钟"
代码里查：rg "lock|locked|failed.*attempt|maxAttempt" src/
结果：代码里没有任何 lock 逻辑 → gap
```

```text
proposal 声称："session 创建集中在 core/session.ts"
代码里查：rg "createSession|new Session|session.*create" src/
结果：createSession 在 routes/auth.ts 和 middleware/session.ts 都出现了 → gap
```

### 4. 结构一致性

```text
design 假设架构是：
  routes/ → controllers/ → services/ → models/

代码实际结构：
  routes/ → handlers/ → db/（没有 services/ 层）

→ design 的架构假设和代码不一致
```

### 5. 测试覆盖

```bash
# artifact 声称有某类测试
rg "oauth|OAuth" test/          # 是否有 OAuth 相关测试？
rg "email.*login" test/         # email login 测试是否存在？
```

如果 specs 新增了 behavior 但现有测试结构不支持新增测试类型（如没有 integration test 基础设施），这应标记为 risk。

## 校验输出

ITR-04 的输出应该是一份对照表：

```text
✓ proposal Impact "src/routes/auth.ts" — 文件存在
✓ proposal Impact "test/auth/*" — 测试目录存在
⚠ design 假设 "TokenStore class" — 代码里是 createToken/validateToken/revokeToken 三个独立函数
⚠ specs "session 超时 30 分钟" — 代码里 session 配置在 config/default.ts，不是 30 分钟
✗ specs "错误响应格式 {error, message}" — 代码里错误处理不统一，存在三种格式
```

每一行标注 ✓（验证通过）、⚠（有偏差但可修）、✗（明显 gap，阻塞实施）。

## 和 ITR-03 的关系

```text
ITR-03：从 artifacts 内容本身找问题（scope 清楚吗？scenario 可测吗？）
ITR-04：从 artifacts 和代码之间找偏差（声称和事实对得上吗？）

ITR-03 不碰代码，ITR-04 密集碰代码。
ITR-03 的审视摘要告诉 ITR-04 "去验证这些点"。
ITR-04 的对照表喂给 ITR-05 "这里有 N 个 gap"。
```

## 参考来源

源码引用基于 commit `970cb44`（Explore stance）、`ff4576f`（Apply guards）：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore 可以读文件、搜索代码、调查 codebase、识别 patterns |
| [`../03_explore-to-propose-change/answer-exp05.md`](../03_explore-to-propose-change/answer-exp05.md) | EXP-05 的真实项目调查方法（rg、读入口、看测试、查数据模型） |
| [`../03_explore-to-propose-change/answer-sequence.md`](../03_explore-to-propose-change/answer-sequence.md) | MD/TS 交替中的代码调查模式 |
| [`answer-itr03.md`](answer-itr03.md) | 上游：ITR-03 的审视摘要 |
| [`answer-itr05.md`](answer-itr05.md) | 下游：ITR-05 的 gap 分类和修复 |
