# 答案：Requirement-Driven Schema — 用 OpenSpec 原生框架做需求工程

## 直接回答

可以。不发明新 artifact 名。`requirement-driven` 和 `spec-driven`、`agent-dev-driven` 是同一个框架——`proposal → specs → tasks → apply`。唯一的变化：去掉了 `design`（需求工程不需要实现方案），proposal 和 specs 的 instruction/template 换成了需求工程的内容。

## 为什么不做成新 artifact

agent-dev-driven 已经证明了一件事：**spec-driven 的 4-artifact 框架是领域无关的**。proposal 就是 proposal（说清楚为什么），specs 就是 specs（规格化要交付的东西），tasks 就是 tasks（拆任务）。不管交付物是代码、agent 还是 PRD，这个心智模型不变。唯一变的是 proposal 和 specs 里面填什么——那改 template 和 instruction 就够了。

`design` 是唯一去掉的 artifact。在 spec-driven 里 design 回答"怎么实现"，在 agent-dev-driven 里 design 回答"skills/commands/tools 怎么设计"。需求工程的交付物就是"要做什么"——"怎么做"留给开发团队。所以不需要 design。

## 核心设计：3 个 artifact + apply

```text
proposal → specs → tasks → apply
```

| artifact | 对应 OpenSpec 原生 | 在 requirement-driven 中的内容 |
|----------|-------------------|-------------------------------|
| `proposal` | proposal | 问题陈述 + 利益相关者 + 范围 + 约束 + 期望结果 + 用户画像 + 原始用户故事 + 问答审计追踪（合并了传统 RE 的 discovery + needs） |
| `specs` | specs | **PRD 本身**——FR-N 功能需求（MoSCoW）、NFR、精炼用户故事、验收标准、风险、术语表、Approval 章节、Developer Handoff Notes |
| `tasks` | tasks | 4 组 checkbox：Proposal → Specification → Review & Validation → Approval & Handoff；每条 task 自带 verification |
| `apply` | apply | 迭代引擎——审查、沟通、修改、签收、交接。所有重沟通的工作在这里 |

### 和 spec-driven 差在哪

| artifact | 和 spec-driven 比 |
|----------|------------------|
| `proposal` | **内容更厚**。spec-driven 的 proposal 是 Why + What Changes + Capabilities + Impact；requirement-driven 的 proposal 在这基础上加了 Stakeholders、User Personas、Raw User Stories、Edge Cases、Clarifying Questions。因为需求工程的前期获取比代码工程重得多 |
| `specs` | **格式不同**。spec-driven 的 specs 是 delta ops（ADDED/MODIFIED/REMOVED）+ Scenario 块；requirement-driven 的 specs 是 PRD 格式——FR-N、NFR、User Stories 表格、Approval 章节。但 `generates: "specs/**/*.md"` 和 `id: specs` 不变 |
| `design` | **去掉**。需求工程不需要实现方案 |
| `tasks` | checklist 内容不同。spec-driven 的 tasks 是代码实现清单；requirement-driven 的 tasks 是需求工程清单（Proposal → Specs → Review → Approval → Handoff）。本示例遵循当前生成契约，每条 checkbox 都声明可观察的 verification，而不是只在末尾笼统“review”。 |
| `apply` | **完全不同**。spec-driven 的 apply 是"读 design，写代码，勾 tasks"；requirement-driven 的 apply 是"读 specs，跟人沟通，迭代修改，推动签收，准备交接" |

## 关键设计决策

### 1. 为什么 proposal 合并了 discovery + needs

传统需求工程会把"理解问题域"和"获取需求"分成两个阶段。但在 OpenSpec 的框架里，proposal 天然就是"为什么做 + 做什么 + 谁受影响"——这已经覆盖了 discovery 和 needs 的大部分内容。把 stakeholder analysis、raw user stories、edge cases 全部塞进 proposal，让 proposal 变厚，但保持 artifact 数量不变。好处是：用户脑子里的模型还是 `proposal → specs → tasks`，不用学新流程。

### 2. 为什么去掉 design

spec-driven 和 agent-dev-driven 都有 design，因为它们的交付物需要"实现方案"——代码架构、skill 设计、tool 接口。需求工程的交付物是 PRD——"要做什么"本身。实现方案是开发团队的事。保留 design 会混淆边界：到底是需求分析师在设计，还是开发在做技术方案？

`design` 在 requirement-driven 里的自然对应物是"需求验证方案"或"需求架构"——但这些太重型了。审查清单嵌入 apply instruction 就够了。

### 3. review 和 signoff 去哪了

它们不是独立 artifact，而是 apply 阶段的活动：

- **审查**：apply instruction 内置了完整的 review checklist（完整度、一致性、歧义、可行性、缺口）。agent 在 apply 循环中逐项执行，发现的问题更新回 specs 或 proposal，在 tasks.md 中跟踪
- **签收**：specs.md 末尾有 Approval 章节（Approver、Date、Status、Conditions、Trade-offs）。当 tasks.md 中所有 Review 和 Approval 任务勾完，Approval 章节填写完毕，签收就完成了
- **交接**：specs.md 末尾有 Developer Handoff Notes（复杂度、集成点、建议顺序、已知未知、联系人）。当 Handoff 任务勾完，需求工程阶段正式结束

### 4. 迭代在 instruction 中，不在 DAG 中

DAG 是无环的（系统强制），但需求沟通是循环的。解决方式：**DAG 负责最小顺序，instruction 负责迭代行为**。

apply instruction 明确告诉 agent：
- 审查发现 specs 缺一整节？回去补，然后重新审查
- 写 specs 时发现 proposal 漏了场景？回去补 proposal
- 利益相关者在签收时改了主意？回 specs 修改，重新审查，重新签收
- 每次迭代问自己"这次修改让需求多清晰了 10% 以上吗？"

### 5. 为什么 generates 保持 `specs/**/*.md`

和 spec-driven 一致。虽然 requirement-driven 的 specs 内容是 PRD 而非 delta ops，但文件组织方式不变——每个 capability 一个 spec 文件。这保留了 OpenSpec 的多 spec 文件惯例，也让大型需求可以拆分。

## 使用方式

```bash
cp -r schema-package/ openspec/schemas/requirement-driven/
openspec schema validate requirement-driven
openspec new change define-<feature> --schema requirement-driven
# 按 proposal → specs → tasks 走，和 spec-driven 一样的流程
```

agent 走完 proposal → specs → tasks 的 artifact 生成后，在 apply 阶段跟利益相关者反复沟通打磨需求，直到 specs 里的 Approval 章节签收、Handoff Notes 补齐。

## 和已有 schema 的关系

| | spec-driven | agent-dev-driven | article-driven | requirement-driven |
|---|---|---|---|---|
| Artifacts | 4 | 4 | 7 | 3 |
| DAG | proposal→specs/design→tasks | proposal→specs/design→tasks | brief→outline/research→draft→edit→publish | proposal→specs→tasks |
| 产出物 | 代码 | agent 组件 | 文章 | PRD |
| 核心动态 | 按设计实现 | 按设计构建 | 按大纲写作 | 跟人沟通打磨 |
| 新 artifact 名 | — | 0 | 7 | 0 |

## 已知限制

- **上游已删除同名内置 schema**：`openspec/schemas/requirement-driven/` 不再是 OpenSpec 内置 schema；本目录的 [`schema-package/`](schema-package/) 是唯一维护源，安装后作为项目级自定义 schema 与上游解耦。
- **archive 的 tasks.md 硬编码**：和所有社区 schema 一样的限制。需求场景下 tasks.md 命名自然，不需要改
- **利益相关者不在线时流程阻塞**：apply 依赖利益相关者反馈。如果利益相关者不回复，agent 只能记录问题、标记 blocked、等下次会话。这是需求工程本身的属性
- **不替代专业 RE 工具**：适合小团队或早期项目的需求定义，不适合审批流、基线管理、需求矩阵追踪等重型 RE 流程
- **review 质量上限是 agent 能力**：agent 可以检查一致性和完整性，但不能替代有经验的工程师对可行性的判断
- **verification 是 schema instruction/示例质量，不是 CLI 硬校验**：`openspec validate` 不会替你判断 stakeholder confirmation 是否真实。

---

> 完整 schema-package（`schema.yaml` + 3 个 `templates/*.md`）在 [`schema-package/`](schema-package/)。
