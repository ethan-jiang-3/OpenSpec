# 答案：把 flat capability 迁移到嵌套二级目录——完整操作指南

> **本文定位**：这是 FAQ 14（[主 specs 上下文缩放](../../_faq_on_digested/14_main_specs_context_scaling/answer.md)）的**操作伴侣**。FAQ 14 回答了「nested path 能解决什么、不能解决什么、agent 上下文策略应该怎么设计」——先读它建立判断框架。本文只回答一件事：**如果你的项目已经决定从 flat 迁到 nested，具体怎么执行。**

## 一句话结论

**从 flat 迁移到 nested 可行，v1.7.0 起已完整支持（v1.9.0 仍如此）。但这不是一次普通 archive——capability path 就是它的身份，没有 rename 操作。迁移是一次受控 rebaseline：先冻结 active changes，再搬 main specs，再逐一更新所有指向旧 path 的引用（delta、catalog、config、文档），最后验证并恢复。**

---

## 前提：先确认你运行的是什么

### v1.9.0 的行为基线

在开始之前必须确认环境：

```bash
openspec --version  # 应输出 v1.9.0（或更高）
```

v1.9.0（v1.7.0 起）的 `discoverSpecFiles()` 会递归发现任意深度的 `spec.md`，并把**相对于 `specs/` 的目录路径**作为 capability ID。这意味着以下布局是完整生命周期支持的：

```text
openspec/specs/identity/session/spec.md
                 └──────────────┘  ID = identity/session
```

list、show、validate、change parser、apply、archive 全部使用同一条发现路径。delta 与 main spec 使用**同一个相对路径**来配对。这不是"恰好能放进去"，而是从 discovery → proposal → delta → archive 的全链路契约。

### 关键约束（迁移前必须刻在脑子里）

| 事实 | 对迁移的影响 |
|------|-------------|
| capability ID = 相对于 `specs/` 的完整目录路径 | 把 `auth/spec.md` 搬成 `identity/login/spec.md` = 换了 ID。旧 ID `auth` 不存在了 |
| capability **没有 rename 操作** | 没有 `RENAMED` 段来声明"auth 改名为 identity/login"。这只能靠你手动完成 |
| requirement 有 RENAMED（FROM/TO） | 如果你同时要改 requirement 标题，可以在 delta 里走正规手续 |
| delta 与 main spec 必须同路径才命中 | `changes/<id>/specs/auth/spec.md` 只会 archive 到 `specs/auth/spec.md`。不会自动"猜到"新地址 |
| archive 是原子、fail-fast 的 | 一个 delta 找不到目标 → 整批不落地。所以迁移期间绝不能有 active delta 指向已经不存在的旧 path |
| nested path 是命名空间，不含继承或自动聚合 | `identity` 和 `identity/session` 是两个独立 capability。父目录不会自动继承、汇总或加载子 spec |

这些不是设计缺陷——它们是 identity 模型的直接推论。理解这些约束，下面的步骤就都是必然的。

### 如果不按约束来，具体会炸在什么地方

上面那六条约束不是"最好遵守"的软建议。每一条背后都有一个具体的、被真实项目验证过的失败模式。按严重程度排列：

**风险 1：path 就是身份，没有 rename——archive 会原子回滚。** 把 `auth/` 搬到 `identity/login/` 后，OpenSpec 眼里旧 capability 已经死了、新 capability 是新创建的。任何仍指向 `auth` 的 delta，下次 archive 时直接 `not found`。archive 是原子的——一个 delta 找不到目标，整批全部回滚，连本该成功的新 capability 创建也一并丢弃。本 repo 自己的 `simplify-skill-installation` change 就真实遇到过：16 条 requirement 操作全部 `not found`，一个坏全盘不落。更危险的是，搬完目录**没有任何工具会主动告诉你"还有 3 个 active delta 指向旧 path"**——要到下次 archive 炸了才知道。

**风险 2：active delta 是悬空炸弹。** 迁移期间，每个 `changes/<id>/specs/<old-path>/spec.md` 还指向旧 ID。如果你搬了 main specs 但没碰这些 delta，它们立刻变成孤儿。这也是为什么 Phase 2 的 active-change 清册被标为"最关键的一步"——你必须明确知道每个 active delta 的最终命运，不能靠猜。

**风险 3：拆分丢失 Git 行级追溯。** 如果不仅搬家还拆分（比如一个大 `auth` 拆成 `identity/login` + `identity/authorization`），用的是 `cp` + `git rm`，新 capability 在 Git 眼里是全新文件。`git blame` 断了。这不是 bug——行为合同拆分本身就是一个新起点——但你必须在 migration design 里留下旧→新映射，让未来的人知道去哪里找历史。

**风险 4：并发——迁移期间有人 propose 新 change。** 如果迁移过程中有人基于旧 flat path 写了新 delta，迁移一完成这个新 change 立刻变成需要修的新债务。这也是 Phase 3 Step 1 要冻结的原因——不是仪式感，是防止新债务在你还来不及验证时就产生。

**风险 5：validate 只查结构，查不出语义漂移。** `openspec validate --specs --strict` 全部绿灯，不代表 specs 和代码对齐了。validate 只查文件格式和 requirement block 的结构合法性，从来不打开源码对照。迁移时你动了几十个 capability 的身份，这个盲区被成倍放大。验证通过只是起点，真正的正确性检查靠的是 Phase 4 中逐个 capability 的 `show` 抽查和人工 review。

**风险 6：catalog 变成过期但被信任的第二份真相。** 人和 agent 倾向于先看 catalog 再读 spec。如果某次 archive 后 spec 的 Purpose 或 requirements 变了但 catalog 没更新，catalog 就变成了过期的导航——而 agent 浑然不知。冲突时以 main spec 为准——这条铁律写在文档里，但 agent 不会自动校验。

**风险 7：为了整齐提前拆分。** 树形目录看起来很漂亮，容易诱惑你把还在共同演进的两个 requirement 拆成两个 capability。结果 agent 每次改它们都**必须同时读两份 spec**——上下文浪费反而增加了。拆分的唯一信号是"它们已经独立演进、独立验证了一段时间"，不是"树看起来不对称"。等行为真正分叉了再拆，比提前拆然后每天多读一份 spec 划算得多。

**风险 8：config.context 膨胀。** 迁移完成很有成就感，容易想把整个 taxonomy、catalog、path convention 全塞进 `config.context`，让 agent 每次都"全知道"。但这东西每次 prompt 都注入、受 50KB 硬上限、而且**不会随 archive 自动更新**——很快就会变成一份过期的、无人维护的、却每次都在消耗 token 的第二份 baseline。

---

> **一句话：最大的风险不是技术上行不通（v1.8.0 完整支持 nested path），而是组织上不完整——搬了 main specs 但漏了 active deltas、漏了 catalog、漏了 agent 约定，然后在下一次 archive 时集中爆炸。这也是为什么下面的步骤是一张检查清单，而不是"你就 git mv 一下就好"。**

---

## Phase 1：设计 target taxonomy

### 切分原则：这是行为合同，不是代码文件夹

capability 的最实用定义：

> 一个 capability 是能独立解释用途、独立承受行为变更、并由一组 requirements/scenarios 独立验证的行为合同切片。

**正向信号**（越同时满足，越值得独立）：

| 信号 | 要问的问题 |
|------|-----------|
| 可观察性 | 用户、外部系统或另一份合同能观察到它吗？ |
| 独立演进 | 它常常可以不改邻居就单独修改吗？ |
| 独立验证 | 能否用自己的 scenarios 说明成功和失败？ |
| 独立发现价值 | agent 改它时，读这一份 spec 能显著减少猜测吗？ |

**反向信号**（应该留在同一个 capability 里）：
- 两个 requirement 总是一起改、一起测
- 读者无法分开理解它们

### 推荐 taxonomy 形状

**默认：一层 domain + 一层 capability**。这是经过验证的 sweet spot。

```text
openspec/specs/
├── identity/
│   ├── login/spec.md
│   ├── session/spec.md
│   └── authorization/spec.md
├── billing/
│   ├── invoices/spec.md
│   └── subscriptions/spec.md
├── notifications/spec.md        ← 没有明显 domain 的就留在根一级
└── data-export/spec.md
```

**domain 只承担三件事**：
1. 帮人和 agent 缩小 discovery 范围
2. 让相邻行为的命名保持一致
3. 在跨域 change 中帮助说明影响面

domain 不承担：继承、默认 requirement、自动聚合、自动加载所有子 spec。这些都是不存在的语义。

> **mixed flat+nested 完全合法**：不是每个 capability 都必须属于一个 domain。`data-export/spec.md`（flat）和 `identity/session/spec.md`（nested）可以并存。discovery 对两者一视同仁。不在 domain 下的 capability 不会被隐藏或降级。

**命名规则**：
- path segment 用 kebab-case：`invoice-generation`，不是 `billingPage`
- 用领域概念而非实现名：`session`，不是 `redis-session-store`
- **禁用垃圾桶名**：`common`、`misc`、`utils`、`core`、`other`——这些都是边界没想清楚的信号
- 不要为临时项目阶段、团队名、版本号命名

**第三层**：只有在该层也代表长期稳定、可独立导航的 namespace 时才加深。例如 `platform/observability/audit-events`。不要为了复刻代码目录或组织架构而加深。

### 实操：画一张 old→new 映射表

拿出一页纸（或一个 markdown 表格），列出每一个现有 flat capability 的目标 path：

```markdown
| old path | new path | 理由 |
|----------|----------|------|
| auth | identity/authorization | 和其他 identity/* 一起归属于 identity domain |
| login | identity/login | 同上 |
| session | identity/session | 同上 |
| billing | billing/invoices | 实际只含发票行为，订阅是独立的 |
| subscriptions | billing/subscriptions | 和 invoices 同属 billing domain |
| data-export | data-export | 无相邻 capability，留在根一级 |
```

画映射表时对每个旧 capability 追问三句（来自 [01-切分与taxonomy.md](../../_digested/spec-driven-capability/01-切分与taxonomy.md) 的决策表）：

| 问题 | 如果答案是"是" |
|------|--------------|
| 它和另一个旧 capability 是否共享同一组 requirement，只是被不同的人用了不同名字创建？ | **合并**为一个新 path，不要保留两个近义合同 |
| 它内部是否包含了两组已经独立演进、独立验证的行为（比如 login 和 permission 各自独立变更了很久）？ | **拆分**成两个新 path，各自带自己的 requirements 和 Purpose |
| 它的行为能否被一个已有 capability 的 requirement 自然描述？ | 不要新建 path，直接 **MODIFIED** 已有 capability |

映射表不是一次性画完就冻结的——在找人 review 之前，把上面三问的结论也写进理由列。**在这一步就找人 review，不要等到搬完了再讨论。**

---

## Phase 2：迁移前准备

### Step 1：确认没有正在进行的 archive

```bash
openspec list
```

如果有 change 处于 apply-ready（即已通过 `/opsx:apply` 实施了代码、等待 archive）、或已经走在 archive 流程中，先完成或取消它们。迁移期间不应该有并发的 archive 操作。

### Step 2：清点所有触及旧 path 的 active changes

这是最关键的一步。对每个 active change，检查它的 `specs/` 目录：

```bash
# 列出所有 active changes（--json 输出 change ID 和状态）
openspec list --json

# 对每个 change，看它的 delta 指向哪些 capability
ls openspec/changes/<change-id>/specs/
```

建一张清册：

```markdown
| change-id | 状态 | 触及的旧 path | 处理方式 |
|-----------|------|--------------|----------|
| add-2fa | in-progress | auth | 暂停：等迁移完成后，将 delta 从 specs/auth/ 搬到 specs/identity/authorization/ |
| fix-session-ttl | archived | session | 已完成，不阻塞 |
| refactor-billing | proposed | billing | 取消或完成：涉及 billing→billing/invoices 的拆分，需重写 delta |
```

**处理方式只有四种**：
1. **已完成（archived）的 change**：不阻塞，忽略
2. **完成并 archive 它**：如果快做完了，先 archive 再迁移
3. **取消（删除 change 目录）**：如果已经废弃
4. **暂停并在迁移后重基线**：手动把 delta 从旧 path 搬到新 path（见 Phase 3 Step 3）

**原则：迁移开始前，不能有任何一个 active delta 仍然指向旧 path 却无人知道它应该映射到哪个新 path。**

> **skip_specs 的 change**：声明了 `skip_specs: true` 的 change 没有 delta specs，不受此次迁移影响，正常保留即可。

### Step 3：确认 config.yaml 和 AGENTS.md 中没有硬编码的旧 path

```bash
rg "auth|login|session|billing" openspec/config.yaml AGENTS.md 2>/dev/null || grep -rE "auth|login|session|billing" openspec/config.yaml AGENTS.md 2>/dev/null
```

记录所有引用位置，迁移后需要同步更新。

---

## Phase 3：执行迁移

### Step 1：冻结——停止创建新 change

通知团队：在迁移完成前，不要 propose 新 change。当前 active changes 已在 Phase 2 中清点完毕。

### Step 2：搬迁 main specs

用 `git mv`（不是普通 `mv`），保留 Git 历史。先创建目标父目录，再逐条搬迁：

```bash
# 0. 先创建所有需要的父目录
mkdir -p openspec/specs/identity
mkdir -p openspec/specs/billing

# 1. 按映射表逐条执行
git mv openspec/specs/auth openspec/specs/identity/authorization
git mv openspec/specs/login openspec/specs/identity/login
git mv openspec/specs/session openspec/specs/identity/session
git mv openspec/specs/billing openspec/specs/billing/invoices
git mv openspec/specs/subscriptions openspec/specs/billing/subscriptions
# data-export 不动——留在根一级
```

**重要**：如果某个旧 capability 要**拆分**成两个新 capability（比如 `auth` 里的 login 和 permission 行为已经独立演进很久），不能靠 `git mv`。你需要：
1. 复制旧 spec.md 的内容到两个新位置
2. 在每个新位置只保留属于它的 requirements
3. 为每个新 capability 写清 `## Purpose`
4. `git rm` 旧 capability
5. 在 migration change 的 design 或 proposal 中记录拆分映射

> **注意**：拆分用 `cp` + `git rm`，不用 `git mv`，因此新 capability 的 Git 历史不会延续旧文件的行级追溯。这是可接受的权衡——行为合同的拆分本身就是一个新的起点。旧文件的历史仍可通过 `git log -- openspec/specs/auth/`（旧 path）查看。

### Step 3：更新 active deltas

对 Phase 2 中标记为"暂停"的每个 active change：

```bash
# delta 原来在 changes/<change>/specs/auth/spec.md
# 现在需要搬到 changes/<change>/specs/identity/authorization/spec.md

mkdir -p openspec/changes/<change>/specs/identity/authorization
git mv openspec/changes/<change>/specs/auth/spec.md \
       openspec/changes/<change>/specs/identity/authorization/spec.md 2>/dev/null \
  || mv openspec/changes/<change>/specs/auth/spec.md \
        openspec/changes/<change>/specs/identity/authorization/spec.md
# 删除空的旧目录
rmdir openspec/changes/<change>/specs/auth 2>/dev/null
```

> `git mv` 对未跟踪文件会失败；失败时回退到普通 `mv`。change 下的 delta 经常是还没 commit 的新文件，这种情况很正常。

**如果旧 capability 被拆分了**（比如 `auth`→`identity/login`+`identity/authorization`），delta 不能简单搬运——你需要：
1. 读 delta 中的每个 requirement 操作
2. 判断它属于哪个新 capability
3. 在新 capability 的 delta 中重写对应的 requirement 操作
4. 使用新的完整 requirement 标题（如果需要改名，用 `RENAMED`）
5. 删除旧的 delta 目录

### Step 4：更新 catalog

如果你已经有 catalog（`openspec/specs/README.md` 或 `docs/spec-catalog.md`），逐条更新 path 列。如果还没有，现在是建它的最佳时机。

catalog 的最小形状：

```markdown
# Capability Catalog

| path | Purpose | keywords | boundary |
|------|---------|----------|----------|
| identity/login | 用户登录、凭证验证、MFA | login, MFA, credentials | 不负责会话管理；相邻 identity/session |
| identity/session | 会话建立、刷新、失效 | JWT, refresh, expiry | 不负责授权策略；相邻 identity/authorization |
| identity/authorization | 角色、权限、访问控制 | RBAC, permission, policy | 不负责身份验证 |
| billing/invoices | 创建、投递、查询发票 | invoice, tax, PDF | 不负责订阅扣款 |
| billing/subscriptions | 订阅生命周期、扣款周期 | subscription, renewal, payment | 不负责发票生成 |
| data-export | 按筛选条件导出数据为 CSV/JSON | export, CSV, JSON | 不负责报表呈现 |
```

**catalog 的两条铁律**：
1. catalog 只导航，不复述完整 requirements/scenarios。冲突以 main spec 为准
2. path 列必须与文件系统中的实际相对路径完全一致

### Step 5：更新 config.yaml

`config.yaml` 不需要列出所有 capability path。它只需要做两件事：

**1. 声明 path convention（可选但强烈推荐）**，放在 `context` 中：

```yaml
context: |
  Capability paths follow <domain>/<capability> convention (see AGENTS.md).
  Treat a capability path as stable identity; structural migrations require an explicit rebaseline, not a normal archive.
  Main specs are the behavior source of truth. The catalog in specs/README.md is navigation only.
```

**2. 加入 proposal/specs 的 artifact rules**，防止 agent 无意中创建 flat 同义 capability：

```yaml
rules:
  proposal:
    - Classify every affected capability as New or Modified and record discovery evidence (which catalog/search was used).
    - Use the project's nested path convention; do not create flat capability paths.
  specs:
    - Use the exact capability path declared in the proposal.
    - Do not create a near-duplicate capability without checking the catalog and existing main specs.
```

**不要做的事**：
- 不要把整个 catalog 或完整 capability 列表塞进 `config.context`——它会每次都注入、受 50KB 上限、而且很快变成过时的第二份 registry
- 不要发明 `nested_layout: true` 这样的字段——OpenSpec 没有消费它

### Step 6：更新 AGENTS.md

把 path convention 和 discovery 协议写进项目的 `AGENTS.md`（或等价的 agent instruction 文件）。可直接采用 [`capability-governance-template.md`](../../_digested/spec-driven-capability/capability-governance-template.md) 中 Section 1 的模板。核心内容：

```markdown
## Capability 约定

### Path convention
- 使用 <domain>/<capability>，例如 identity/session
- path segment 使用 kebab-case；禁用 common、misc、utils、core
- capability path 是稳定 identity，未经受控迁移不得重命名

### Discovery before proposal
1. 先读 openspec/specs/README.md（catalog），或运行 openspec list --specs --json
2. 搜索已有 capability 的 Purpose 和关键词，避免创建近义 path
3. 在 proposal 中将受影响 path 标为 New 或 Modified，记录理由
4. 只有确定要 MODIFIED/REMOVED/RENAMED 时，才读完整 requirement block
5. 没有 spec-level 行为变化时用 skip_specs

### Delta and archive
- delta 必须放在 specs/<capability-path>/spec.md，与 main spec 同路径
- 新 capability 的 delta 写明可读 Purpose
- 不要把 capability path 变更混进普通 archive
```

---

## Phase 4：验证

### 验证清单（按顺序执行）

```bash
# 1. 新 capability 全部被发现
openspec list --specs --json | jq '.[].id'          # 若未安装 jq，直接看未过滤的 JSON 输出
# 预期输出包含 identity/login、identity/session、billing/invoices 等
# 预期输出不含 auth、login、session、billing（旧 path）

# 2. 所有 main specs 结构合法
openspec validate --specs --strict
# 应全部通过；若有失败，先修复再继续

# 3. 每个受影响 active change 的 delta 能对应到新 path
openspec validate <change-id> --type change --strict
# delta 的 capability path 已更新，应能通过

# 4. 抽查一个 capability 的内容完整可读
openspec show identity/session --type spec --json --requirements
# 确认 requirements 和 Purpose 符合预期

# 5. Git diff 干净审阅
git diff --staged
git status
# 确认没有遗漏的旧 path 文件或空目录
```

### 确认无误后提交

```bash
git add -A
git commit -m "rebaseline: migrate capability layout from flat to nested

Old path -> New path:
  auth -> identity/authorization
  login -> identity/login
  session -> identity/session
  billing -> billing/invoices
  subscriptions -> billing/subscriptions

Active deltas, catalog, config.yaml, and AGENTS.md updated to match.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Phase 5：迁移后的日常纪律

迁移完成不代表故事结束。以下习惯守住成果：

### agent 的 discovery 协议

下面这份协议应写入项目的 AGENTS.md（见 Phase 3 Step 6）。它在每次 `/opsx:propose` 和 `/opsx:explore` 的 discovery 阶段执行——不是在 propose 之前单独跑一遍，而是 propose workflow 内部的前几步：

```text
1. 读 openspec/config.yaml → 知道全局不能破坏什么
2. 读 openspec/specs/README.md（catalog）或 openspec list --specs --json → 列出候选 capability path
3. 用关键词和用户意图过滤候选 → 标记每个为 New / Modified / verify only / excluded
4. openspec show <path> --type spec --json --requirements → 先看 requirement 标题
5. 只对要修改的 requirement → 读完整 block + scenarios
6. 在 proposal.md 记录选择证据
```

### 日常维护节奏

| 时机 | 检查点 |
|------|--------|
| 每个 proposal | 查过 catalog 了吗？New/Modified 有理由吗？有没有创建近义 path？ |
| 每个 archive 后 | delta path 与 main path 一致吗？新 capability 的 Purpose 可读吗？ |
| 跨 domain change | proposal 里有没有 impact matrix？ |
| 定期（每月） | 有没有过粗 spec 需要拆分？有没有同义 path 需要合并？catalog 条目是否过期？ |

### 什么时候应该再次改变 taxonomy

- **拆分**：一个 spec 里两组 requirement 已经各自独立演进、独立验证了很长时间
- **合并**：两个 spec 几乎永远同改、同测，分开反而增加阅读成本
- **改名**：path 名称持续误导 discovery（比如 `auth` 实际已经只做 authorization）
- **退役**：代码和外部调用方都已迁移完毕，确认没有 active delta 指向该 path

**再次强调**：以上任何一种都走同样的 rebaseline 流程（Phase 2→3→4），不要混在功能 change 里顺手做了。

---

## 不推荐的做法

- **直接 `git mv` 然后假装什么都没发生**：active delta 会变成悬空引用。下次 archive 时 `not found`，整批回滚
- **把迁移伪装成一次普通 archive**：写一个 change 的 delta 是 `RENAMED`（capability 层没有这个操作）。archive 只会看到旧 path 不存在、新 path 是 ADDED——这丢掉了所有历史 requirement 的连续性
- **把旧 path 留在原地当"转发"**：比如 `specs/auth/spec.md` 里只写"see identity/authorization"——discovery 会把它当成一个合法 capability，agent 会被两份 spec 搞混
- **把完整 catalog 塞进 `config.context`**：这会把导航数据变成每次 prompt 都注入、很快过时、且受 50KB 上限的第二份 baseline
- **为了视觉整齐提前拆分**：如果两个 requirement 现在还总是一起改、一起测、一起理解，拆开只会增加 agent 必须同时阅读的 spec 数量。等它们真正独立演进时再拆分
- **迁移期间继续 propose 新 change**：新 change 可能基于旧 path 写 delta，一落地就变成立即要修的债务

---

## 如果项目同时有几十个 active changes

这种情况需要分层处理：

1. **先归档能快速完成的**：减少 active change 数量
2. **按 domain 分批迁移**：这周迁 identity、下周迁 billing。每批之间，agent 必须知道哪些 domain 已经是 nested、哪些还是 flat——把当前状态写进 AGENTS.md 的明显位置
3. **维护一个"path 别名表"**：在 catalog 中临时标注 `auth（已迁移 → identity/authorization）`，给还没更新的引用留一条线索
4. **考虑写一个脚本**：自动扫描 `changes/*/specs/` 下的旧 path，输出"哪些 change 的哪些 delta 还需要更新"

这不是理想情况，但分层处理至少把风险控制在每个 domain 内部。

---

## 一句话总结

**nested capability 是已实现的、适合大项目的组织能力。迁移的实质是一次受控 rebaseline：先冻结、再映射、再搬迁、再逐层更新引用、再验证。path 是稳定身份——这次把 taxonomy 做对。以后要改（拆分、合并、改名、退役），必须走同样的受控 rebaseline 流程（Phase 2→3→4），绝不能混在功能 change 里顺手操作。**

---

## 参考来源

### 本仓库一手研究
- [`../../_digested/specs_truth/_research-nested-capability-paths.md`](../../_digested/specs_truth/_research-nested-capability-paths.md) — v1.7.0 源码核验：discovery、生命周期、同路径映射
- [`../../_digested/spec-driven-capability/`](../../_digested/spec-driven-capability/00-map.md) — capability 切分、taxonomy、catalog 协议、演进治理（全 4 章 + governance template）
- [`../../_digested/specs_truth/01-机理-主specs如何被delta构造.md`](../../_digested/specs_truth/01-机理-主specs如何被delta构造.md) — 两层 name-as-identity、archive 原子性、fail-fast
- [`../../_digested/mechanisms/03-spec-model.md`](../../_digested/mechanisms/03-spec-model.md) — parser/schema/validator 分工、recursive discovery

### Handbook
- [`../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md`](../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md) — capability 身份、catalog、rebaseline
- [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) — config/specs/changes 三层分工
- [`../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md`](../../_openspec_handbook/06-高级-config-yaml-怎么写到真正好用.md) — config 字段路由、强规则写法

### 上游
- [Issue #1459](https://github.com/Fission-AI/OpenSpec/issues/1459) — nested path 的 agent-facing guidance 仍为 open
- [`discoverSpecFiles()` 源码](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/utils/spec-discovery.ts) — 递归发现、ID 规范化、边界处理
- [`spec-discovery.test.ts`](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/test/utils/spec-discovery.test.ts) — flat、nested、正斜杠 ID、root-file exclusion、symlink 测试覆盖
