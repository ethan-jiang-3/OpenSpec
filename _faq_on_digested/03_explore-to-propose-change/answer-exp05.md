# 答案 EXP05：真实项目调查怎么发生

## 一句话

EXP-05 解决的是：OpenSpec 已经把 planning context 交给 agent 之后，agent 怎么继续找到真实项目里的 implementation context。

这一步没有一个固定 CLI 能直接返回“应该读哪些源码文件”。它靠的是：

```text
用户词汇
  + OpenSpec artifacts 里的线索
  + 项目入口和文档
  + rg 搜索
  + 测试和数据模型
  + agent 工程判断
  = 和这个问题相关的真实代码事实
```

Explore skill 的源码只规定 agent 要 grounded：可以读文件、搜索代码、调查 codebase，但不能写业务实现。具体读哪些源码，是 agent 在项目结构里逐步发现出来的。

## EXP-05 和 EXP-04 的边界

EXP-04 解决的是 OpenSpec planning 文件：

```text
proposal.md
design.md
specs/**/*.md
tasks.md
```

它通过 `openspec list --json`、`openspec status --change X --json` 和 `artifactPaths` 告诉 agent：当前有哪些 change、artifact 文件在哪里、planning scope 是什么。

EXP-05 解决的是真实项目事实：

```text
源码入口
命令/API/UI 表面
配置和数据模型
测试
现有 patterns
隐含耦合和风险
```

两者不是替代关系：

| 层 | 给 agent 什么 | 不能给什么 |
|---|---|---|
| EXP-04 | OpenSpec 状态和 artifact 文件路径 | 业务源码的完整影响面 |
| EXP-05 | 真实代码事实和实现约束 | OpenSpec artifact DAG 的状态 |

真正的 Explore 判断来自两者互相校正。

## 第一类入口：用户词汇

用户说的话通常带有第一批搜索线索：

```text
"auth 系统有点乱"
"想加跨仓库 store 支持"
"apply 和 archive 好像不一致"
"schema 机制是不是能扩展"
```

agent 会先把这些词转成候选搜索：

```bash
rg -n "auth|session|oauth|permission" .
rg -n "store|references|registry.yaml" src test docs
rg -n "archive|apply|tasks.md|checkbox" src test _digested
rg -n "schema|artifact|requires|generates" src schemas test
```

搜索不是为了马上得出 change name，而是找到：

- 相关模块。
- 相关测试。
- 相关配置。
- 现有术语。
- 用户说法和代码术语之间的映射。

例如用户说“auth 很乱”，代码里可能根本没有 `auth` 目录，而是 `identity`、`sessions`、`permissions`、`providers`。EXP-05 要先建立这个词汇映射。

## 第二类入口：OpenSpec artifacts 里的 impact 线索

如果 EXP-04 发现已有 change，agent 应先读 artifacts。它们经常会告诉 agent 下一步读哪些源码。

例如 `proposal.md` 里可能写：

```markdown
## Impact
- Affected code: src/auth/session.ts, src/routes/oauth.ts
- Tests: test/auth/oauth.test.ts
```

`design.md` 里可能写：

```markdown
Use the existing token store in src/security/tokens.ts.
```

`tasks.md` 里可能写：

```markdown
- [ ] 2.1 Add OAuth callback route
- [ ] 2.2 Extend session lookup
```

这些不是 OpenSpec CLI 自动发现的源码路径，而是 planning artifact 中留下的工程线索。agent 应该沿着它们读真实代码，然后反过来检查 artifacts 是否仍然准确。

## 第三类入口：项目表面

当没有既有 artifact，或 artifact 太粗时，agent 要从项目表面入手。

常见读取顺序：

| 项目表面 | 读它是为了什么 |
|---|---|
| README / docs | 了解项目公开能力、术语、启动方式、使用场景。 |
| package / manifest / config | 了解技术栈、命令、入口、依赖和工具链。 |
| CLI command registry | 找用户可调用命令和命令边界。 |
| API routes / UI routes | 找用户可观察行为。 |
| schemas / migrations / models | 找数据事实和兼容风险。 |
| tests | 找现有行为被怎样断言。 |

这里的策略是从“系统对外怎么表现”往内收，而不是一上来随机读内部 helper。

OpenSpec change 的边界通常对应用户可观察行为、能力协议或 workflow，而不是某个内部函数名。

## 第四类入口：代码结构和 import 关系

找到第一批相关文件后，agent 会沿代码结构继续读：

```text
入口文件
  -> 调用的 service / core 模块
  -> 数据读写层
  -> validation / parser / policy
  -> tests
```

它要确认：

- 变化是不是只影响一个入口，还是贯穿多个模块。
- 有没有共享 helper，改它会不会扩大 blast radius。
- 现有 pattern 是集中式、插件式、schema-driven，还是 ad hoc。
- 测试是单元测试、集成测试，还是没有覆盖。
- 哪些文件只是实现细节，哪些文件代表行为边界。

这一步会直接影响是否拆 change。

如果一个目标要同时改 parser、schema、command runtime、adapter、，它可能不是一个简单 feature，而是跨层机制变化，需要 design 或拆分。

## 第五类入口：测试

测试是 Explore 里判断“现有行为”的强事实源。

agent 应该看：

```text
test/<domain>/*
test/commands/*
test/core/*
integration tests
fixtures
snapshots
```

测试能回答：

- 现在系统承诺了什么。
- 哪些行为是 accidental，哪些是 contract。
- 改动后应该怎样验证。
- 一个 change 的 tasks 是否能形成可执行 checklist。

如果没有测试，Explore 应该把这标为 risk，而不是假装验证路径清楚。

## 第六类入口：数据模型和持久化

当用户目标涉及状态、配置、历史记录、权限、同步或迁移，agent 必须看数据模型：

```text
schema files
types
database migrations
YAML / JSON config shape
state file readers/writers
serialization/deserialization
```

因为这些会决定：

- 是否有 backward compatibility 问题。
- 是否需要 migration plan。
- 是否影响 archive/sync/onboard 等后续 workflow。
- 是否应该把需求拆成“数据模型基础设施”和“用户功能”两个 changes。

如果 Explore 只读业务入口，不读数据模型，很容易把一个高风险 change 误判成普通 feature。

## 第七类入口：既有 patterns

OpenSpec 的目标不是让 agent 发明一个孤立方案。EXP-05 要看项目已有做法：

```text
同类命令怎么注册
同类 schema 怎么解析
同类状态文件怎么迁移
同类 adapter 怎么输出
同类测试怎么搭 fixture
```

真实项目调查不是“读越多越好”，而是找足够的相似 precedent。

如果已有 pattern 很清楚，propose 可以更聚焦。如果没有 precedent，Explore 要标出 open question 或建议 design/spike。

## 空 OpenSpec 场景下的 EXP-05

当 `openspec/specs/` 为空时，EXP-05 更重要。

此时 OpenSpec 没有 formalized spec baseline，agent 要从真实项目反推出事实 baseline：

```text
系统现在有哪些对外能力？
这些能力在哪里体现？
哪些行为被测试覆盖？
哪些只是 README 声称但代码未实现？
哪些能力完全没有文档？
```

然后才能判断：

- 只是给用户解释现状。
- 先 propose 一个 baseline documentation change。
- 直接 propose 一个具体增量。
- 拆成 baseline + new capability 两个阶段。

空 OpenSpec 不是“无事实”，只是“事实还没有被 OpenSpec 规格化”。

## EXP-05 的输出不应该是什么

EXP-05 不应该输出：

```text
我已经看了代码，所以直接开始改。
```

也不应该输出：

```text
我搜到了 auth，所以 propose refactor-auth-system。
```

它应该输出可判断的事实摘要：

```text
我查到：
- 当前 login flow 在 routes/auth.ts 进入，session 创建在 core/session.ts。
- OAuth provider 只有 GitHub，Google 是 TODO，没有测试。
- specs 里没有 auth baseline，README 只描述 email login。
- permission check 分散在三个 route middleware。

这说明用户说的“auth 乱”至少包含三个问题：
1. OAuth provider 接入重复。
2. session 生命周期不清。
3. permission check 分散。
```

这个输出还不是 proposal，而是给 EXP-06 合成问题地图的事实材料。

## 参考来源

源码引用基于 commit `970cb44`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore 是 thinking stance；可以读文件、搜索代码、调查 codebase，但不能实现功能 |
| `src/core/templates/workflows/propose.ts` | Propose 才进入 change 创建和 artifact generation |
| `src/core/templates/workflows/apply-change.ts` | 真实实现属于 apply 阶段，不属于 Explore |
| [`../../_digested/system/07-OpenSpec-工程思想.md`](../../_digested/system/07-OpenSpec-工程思想.md) | CLI 解释状态，agent 负责推理和工程判断 |
| [`answer-exp04.md`](answer-exp04.md) | EXP-04 提供 planning context，EXP-05 接续读取 implementation context |
