# 答案：Requirement-Driven Schema — 用 OpenSpec 做需求工程

## 直接回答

可以。OpenSpec 的 schema 系统本质是 artifact DAG + 模板 + CLI 解释器的组合，这套抽象不绑定代码实现，也不绑定"单人产出"模式。这里定义的 `requirement-driven` schema 把需求工程的**协作沟通流程**建模进了 DAG——不改一行源码。

## 为什么会想到这个

已有的三个 schema 覆盖了三种产出物：代码（spec-driven）、agent 组件（agent-dev-driven）、文章（article-driven）。但它们有个共同点——**一个人+AI 可以独立完成**。需求工程不一样：需求的原材料在利益相关者脑子里，分析师的工作是把它挖出来、理清楚、写下来、反复确认，直到双方都认为"这就是我要的"。这是个本质上的协作流程。

问题在于：OpenSpec 的 artifact DAG 是有向无环图——天然是顺序的、单向的——而需求沟通是循环的、双向的。这就引出一个设计问题：**怎么在一个不允许循环的 DAG 框架里建模迭代沟通？**

答案是把迭代写在 instruction 里，不在 DAG 层面做循环。DAG 保证最小依赖顺序（你总得先知道背景再获取需求，先有需求再写 spec），instruction 告诉 agent "你可以且应该回到前面的 artifact 去改"。

## 核心设计：6 个 artifact 的 DAG

```text
discovery ──→ needs ──→ spec ──→ review ──→ signoff
    │            │         │
    └────────────┴──→ tasks ←──┘
```

**Apply gate**：`[spec, tasks]`——spec 存在 + 任务清单就位后，apply 驱动审查、迭代、签收、交接。

每个 artifact 的职责：

| artifact | 在 requirement-driven 中做什么 | 对应其他 schema 中的什么 |
|----------|------------------------------|--------------------------|
| `discovery` | 理解问题空间——业务背景、利益相关者、约束、成功标准 | brief（article-driven）/ proposal（spec-driven），但只记录问题域，不提方案 |
| `needs` | 原始需求获取——用户画像、痛点、期望结果、原始用户故事、问答审计追踪 | 没有直接对应。这是需求工程独有的阶段——用利益相关者的语言记录他们说的 |
| `spec` | 正式 PRD——FR-N 功能需求（MoSCoW 优先级）、NFR 非功能需求、验收标准、风险、术语表 | design（spec-driven），但产出的是"要做什么"而非"怎么做" |
| `review` | 批判性审查——完整性、一致性、歧义、可行性、缺口分析 | edit（article-driven）的审查维度，但更结构化（checkbox 驱动的检查清单） |
| `signoff` | 批准记录 + 开发者交接说明——权衡记录、已知未知、建议实现顺序 | publish（article-driven）的"交付包"概念，但内容换成开发团队需要的信息 |
| `tasks` | 5 组 checkbox 追踪清单——Discovery → Needs → Spec → Review → Signoff | tasks（所有 schema 都有，职责一致） |

依赖关系：

- `discovery` 无依赖（起点——理解问题域是第一步）
- `needs` 依赖 discovery（不能做好的需求获取如果不知道背景和利益相关者是谁）
- `spec` 依赖 needs（正式规格化基于原始需求输入）
- `review` 依赖 spec（审的是正式需求文档）
- `signoff` 依赖 review（问题解决了才能签）
- `tasks` 依赖 discovery + needs（知道背景和原始需求后就能规划工作了）

## 关键设计决策

### 1. 迭代在 instruction 中，不在 DAG 中

DAG 是无环的（系统强制校验），但需求工程天然有循环。解决方式：**DAG 负责最小顺序保证，instruction 负责迭代行为**。

apply instruction 明确告诉 agent：

- 审查发现 spec 缺一整节？回去补 spec，然后重新审查
- 写 spec 时发现某个场景在 needs 里完全没覆盖？回去补 needs.md
- 利益相关者在 signoff 时改了主意？回到 spec 修改，重新审查，重新签收

这和 article-driven 一样（edit 发现问题回 draft 改），只是 requirement-driven 的回环更频繁、更深入——因为需求沟通本身就是迭代的。

### 2. review 和 signoff 分成两个 artifact

审查是批判性的（"你的任务是找问题，不是赞扬"），签收是肯定性的（"我确认这就是我们要做的"）。它们分开有实际好处：

- **心理上**：同一个人既要做严格审查又要请求批准，会不自觉地在审查时放水。分成两步制造了一个"角色切换"
- **审计上**：review.md 是"我们发现过哪些问题"，signoff.md 是"我们决定怎么处理这些问题后签的字"——两份文档给六个月后"谁做的这个决定"提供了完整线索
- **流程上**：如果签收被拒（利益相关者不满意），你可以只重做 review→signoff 这一段，不需要从 discovery 重新来

### 3. tasks 依赖 discovery + needs，不依赖 spec

这和 agent-dev-driven 不同（tasks 依赖 specs + design），和 article-driven 也不同（tasks 依赖 outline + research）。

原因是：tasks 是**工作计划**，需要在你开始执行之前就存在——tasks 告诉你"现在要做 spec、然后 review、然后 signoff"。如果 tasks 依赖 spec，那就意味着你得先把 spec 写完了才能列"写 spec"这个任务——先有产出再有计划，顺序不对。

实际上 agent 会这样用：
1. discovery + needs 完成 → tasks.md 创建，列出 spec 阶段的任务
2. spec 开始写 → tasks.md 中的 spec 任务逐步勾掉
3. spec 完成 → tasks.md 可能新增 review 阶段才发现的任务
4. 以此类推

### 4. apply gate 设在 spec + tasks，不是 signoff 后面

镜像 article-driven 的 `[draft, tasks]` gate。含义是：主体产出物（spec）和施工清单（tasks）都就位上，apply 阶段驱动剩下的重沟通工作——审查、迭代、签收、交接。

这也是需求工程和代码工程的关键差异：代码工程的 apply 是"按 design 实现"，需求工程的 apply 是"跟人沟通、迭代、达成一致"。apply 阶段是工作最密集的地方，不是在收尾。

### 5. 六 artifact 的规模选择

agent-dev-driven 是 4 个（mirror spec-driven），article-driven 是 7 个（brief → outline → research → draft → edit → publish + tasks），requirement-driven 取了 6 个。

不是随意取的。需求工程的核心转折点比代码工程多（多了 discovery→needs→spec 的两次语言转换：问题空间→利益相关者语言→规格语言），但不需要 article-driven 的 publish 分发维度（signoff 已经包含了交接，不需要单独的"分发到 CMS"这一步）。

## 这验证了什么

从 `_digested/` 对 OpenSpec 整体架构的解读来看，requirement-driven schema 验证了几个东西：

- **协作流程可以建模进 DAG**：不是只有单人产出才能用 OpenSpec。"反复沟通"这种看似非结构化的行为，可以通过 instruction 编码为 agent 的主动行为（"提问 → 记录 → 复述确认 → 追问边界 → 知道何时推动签收"）
- **"交付物"可以是纯文档**：spec.md 是 PRD，signoff.md 是交接说明——没有一行代码。OpenSpec 的 artifact 概念不绑定文件类型
- **和已有 schema 正交**：spec-driven 管实现，agent-dev-driven 管 agent 组件，article-driven 管文章生产，requirement-driven 管需求定义——它们可以串联使用（requirement-driven 出 spec → spec-driven 出实现）
- **分层协议模型的边界没有被突破**：和 article-driven 一样，只改 schema.yaml + templates，不改源码。文件系统存状态、schema 定义产物图、CLI 解释状态、template 编译指令、agent 负责执行——五层都复用

## 使用方式

```bash
cp -r schema-package/ openspec/schemas/requirement-driven/
openspec schema validate requirement-driven
openspec new change define-<feature> --schema requirement-driven
# 按 discovery → needs → spec → review → signoff 走，和 spec-driven 一样的流程
```

agent 会像处理代码 change 一样走完 discovery → needs → spec → tasks → review → signoff 的全流程，在 apply 阶段跟利益相关者反复沟通打磨需求。

## 已知限制

- **archive 的 tasks.md 硬编码**：和所有社区 schema 一样的限制。需求工程场景下，tasks.md 这个命名其实挺自然的（需求工程也是工程），不需要改
- **利益相关者不在线时流程会阻塞**：apply 阶段高度依赖利益相关者反馈。如果利益相关者不回复，agent 只能把问题记录下来、标记 blocked、等下一次会话。这是需求工程本身的属性，不是 schema 的问题
- **不替代专业需求管理工具**：这个 schema 适合小团队或早期项目的需求定义，不适合需要审批流、基线管理、需求矩阵追踪等重型 RE 流程。它验证的是"OpenSpec 协议可以泛化到需求工程"这个命题
- **review 的质量上限是 agent 的能力**：agent 可以检查一致性和完整性，但不能替代有经验的工程师对可行性的判断。review 阶段的 feasibility assessment 应该被当作"初筛"而非"终判"

---

> 完整 schema-package（`schema.yaml` + 6 个 `templates/*.md`）在 [`schema-package/`](schema-package/)。
