---
title: "10 — Deep Research Tool：MD/Agent 控制 Flow 的 config 归位审计"
document_kind: "case-audit"
case_source: "/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml"
applies_to:
  - "Deep Research Tool at case_source"
  - "that project's audited B1 runtime boundary"
read_when:
  - "正在维护或复核 case_source 对应的 Deep Research Tool 配置。"
  - "需要理解该项目中哪些 runtime/playbook 细节被过早注入所有 planning artifacts。"
focus:
  - "把该项目的 Flow/Gate authority profile 留在 context，把条件化 policy、verification 与 registry 路由到正确 artifact 或 deterministic owner。"
  - "在该项目中用 Change Context Card 让下游 artifacts 继承本次分类，而不是从全局 context 反复猜测。"
not_for:
  - "不要把本项目的 B1 判断当作其他 MD/Agent 项目的分类依据或配置模板。"
  - "不要复制此项目的 capability、bundle、实验或验证细节到无关项目。"
next_read:
  - "案例边界与四个项目介绍：README.md"
  - "通用归位规则：../01-design-config-yaml.md"
---

# 10 — Deep Research Tool：MD/Agent 控制 Flow 的 config 归位审计

来源：`/Users/bowhead/ai_tool_deepresearch/openspec/config.yaml`。

## 项目是什么

Deep Research Tool 是一个把宽泛研究问题转化为证据支撑、多波次、带 Gate 研究报告的 Agentic framework。运行时由 Agent 执行搜索、阅读、写作、综合和语义判断；Markdown 提供 Agent-facing flow；JavaScript Engine 负责 schema、状态、receipt 与确定性 Gate。

## 使用边界

本文只审计这个项目在上述来源路径中的 `config.yaml`，不是 B1 项目的通用模板。其他项目最多借鉴“先识别 consumer、再归位信息、把硬约束交给确定性 owner”的审计方法；不能复制这里的 capability、bundle、实验体系、requirement registry、verification routing、目录、命令或行号结论。

## 审计判断

这个项目属于 [`00-initial-config-baselines.md`](../00-initial-config-baselines.md) 的 **B1：MD/Agent 控制 Flow，传统程序做 Gate**。配置中已经准确表达了 Agent 负责搜索、阅读、写作、综合、决策，Engine 负责 schema、状态机、receipt 和 Gate 校验；问题不在这套模型本身，而在过多 runtime/playbook 细节被重复注入每个 planning artifact。

> 目的不是批评配置“写得太长”，而是识别每段信息的正确 owner、消费时机和验证方式。建议去处是设计方向，最终仍应以项目实际文件结构为准。

## Context 归位

| 现有块 | 现有位置 | 判断 | 建议去处 |
|---|---:|---|---|
| 项目一句话、Agent / Engine / 文件的基本分工 | 4-10 | 跨 artifact 的稳定理解，值得保留；当前细节可压缩。 | `context`，保留为 5-8 行 authority profile。 |
| 核心原则与 JS/MD 边界 | 12-21、30-44 | “谁拥有决策”是稳定背景；具体错误处理、env/routing 规则不是所有 artifact 都需要。 | context 留 ownership 摘要；详细边界移至 charter；proposal/design rules 用条件化指针。 |
| 技术栈及允许依赖 | 23-28 | 对 design/tasks 有强影响，对 proposal/specs 价值较低。 | `rules.design` / `rules.tasks`；context 只留一句技术栈摘要。 |
| Evolution Directions | 51-60 | 明确标为 proposal/design 评审顺序，却在所有 artifact 注入，是典型作用域错配。 | `rules.proposal`、`rules.design`；完整正文留在现有 guidelines。 |
| 命名规范 | 62-65 | UI 语言/路径语言可能全局；capability prefix 与 bundle 命名是条件性规则。 | context 只留全局语言约定；capability 命名进 proposal/specs；bundle 命名进 design/tasks 或 runtime playbook。 |
| Requirement Traceability | 67-77 | 每条要求有不同消费者：分配 ID、写 spec header、写实现标记、收尾检查。 | proposal / specs / tasks 各自短 rule；registry 与 checks 保持 canonical；可执行检查继续承担验证。 |
| Governance 工具与 registry 组织细则 | 79-91 | 详细的登记格式不是 proposal、design、tasks 都需要。 | `rules.specs` / `rules.tasks` 的指针；正文只留 registry 文档/validator。 |
| Verification routing | 93-109 | 是 change-level verification policy；“本次计划”应该进入 change 的 `verification-plan.yaml` 和 tasks。 | proposal 触发创建计划；tasks 生成具体动作；分类定义留 policy/checker，不进 context。 |
| 实验体系 | 111-128 | 主要面向 experiment/run 的设计与实施，不是所有 spec artifact 的背景。 | policy/runbook；相关 design/tasks rule 指针；必要硬约束交给 supervisor/engine。 |
| 根目录与 framework/bundle 详细地图 | 130-165 | 有少量全局导向价值，但完整树是静态索引，重复注入性价比低。 | context 保留 3-5 条 root/ownership 摘要；完整地图放 README/charter。 |

## Rules 归位

现有规则已经比 context 更接近正确的注入位置。目标是压缩重复内容，并加强“触发 -> 动作 -> 留痕”，不是把它们再次全部搬走。

| Rules 组 | 现有优势 | 需要调整的风险 |
|---|---|---|
| `proposal`（168-177） | 能明确语言、source、capability、版本等长期约束。 | 多条与 context 的 Evolution Directions 重复；不同 change 类型适用性不同。保留摘要和明确路径，详细政策转为短指针。 |
| `design`（178-183） | 技术栈、状态机、source-of-record 非常适合 design。 | “只能用依赖”应是项目硬约束的同时有 package/test 支撑；不要只靠 rule。 |
| `tasks`（184-200） | done condition、依赖排序、requirement ID、收尾验证都能转化为可读任务。 | Apply 本身不重新注入 config；必须让生成出的 `tasks.md` 写出收尾验证，且由 CI/checker 复核。 |
| `specs`（201-227） | Capability / requirement 的约束有明确 artifact owner。 | 主 spec 结构与 ID 格式最好由现有 governance checker 保障；长的边界测试可从 inline rule 移为 policy 指针。 |

## 可行的渐进收缩目标

1. 将 `context` 缩成“项目 profile + Flow/Gate authority + 最高优先级”摘要，不复制流程、目录树、检查器细节。
2. 每个 artifact 保留 3-6 条真正稳定的 rule；一条 rule 应能回答“何时触发、做什么、在哪留下证据”。
3. 用 proposal 的 Change Context Card 记录是否涉及 framework、version、experiment、verification plan；下游 artifacts 从 proposal 读这一结论。
4. 将不可协商的 registry / spec / verification 规则继续放入 checker；真正的 Agent-flow 顺序留在 Markdown controller/playbook，而非 config。

## 对本文 Evolution Directions 建议的复核

这里的建议**方向正确，但还不够精确**。把三条 Evolution Directions 从全局 `context` 的长正文，迁到 `rules.proposal` 与 `rules.design`，能解决真正的问题：它们不是所有 planning artifact 都要反复携带的项目事实，而是一套在设计相关 change 上被触发的思考顺序。

这也正好服务本项目想要的效果：每个有实质设计内容的 change，在形成方案时先想清楚三件事——新概念是否让某个读者能更精确地推理；控制形状是否仍是最短合法闭环；以及用户、Agent、Engine 的决定/执行/verdict 边界是否诚实。三者的 canonical source 已经是 `guidelines/evolution-*.md`；`config.yaml` 的职责只是把正确的人在正确的 artifact 阶段路由过去，并要求留下简短、可审查的结论。

### 原建议哪里还差一步

| 问题 | 为什么是问题 | 应怎样调整 |
|---|---|---|
| 只写“移到 `rules.proposal`、`rules.design`”，没有区分两者职责。 | proposal 负责说明要改什么与为什么；design 才负责选语义层、控制形状和责任边界。两处都要求完整 review，会造成两份近似反思；只留 proposal 又会让真正的技术取舍没有稳定落点。 | 把 `design` 定为三条 Directions 的**主审查与证据 owner**；proposal 只记录本 change 是否触发、哪些 surface 可能受影响，以及 design 必须完成 review 的承诺。 |
| 说“proposal/design 必须按顺序 review”容易被实现成：每个微小 change 都重新通读三份长指南。 | 这样既浪费注意力，也会把严肃审查变成机械打勾；但完全只靠条件判断，又会让作者跳过本该考虑的层。 | 每份 design 都先经过同一个轻量路由：`semantic precision → simple reliable control → helper responsibility`。只有对应 surface 被新增或实质改变时，才读取并应用该条 canonical guideline，写出实质结论；不适用时可简短说明“本 change 不改变此层”。 |
| 现有 `rules.design` 要“按顺序阅读”并在 `apply target manifest` 标 control surface，但没有指定结论写到哪里、下游如何消费。 | 这不满足“触发 → 动作 → canonical source → evidence 落点”。而且 `apply target manifest` 虽然在历史 `design.md` 中已有惯例，却不是 config 中定义的独立文件，容易被误写成一个临时、无人读取的文件。 | 在 `design.md` 固定一个简短的 `## Evolution review`，并把 control-surface 的增删并入同一份 `## Apply target manifest`。`tasks.md` 只把其中已经决定的实现/验证动作具体化，不再重新猜或重做三条 review。若希望每个 change 都稳定拥有这些小节，应更新 proposal/design template，而不是只依赖 config prompt。 |
| 本文提出 Change Context Card，但没有把它与三条 Directions 的职责接上。 | Card 若只登记 framework、version、experiment、verification，会遗漏最重要的“这次设计为什么要进行这套 review”。 | Card 应有一行 `Evolution review`：列出触发的 surface、适用的三层 review，以及结论将落在 `design.md`。它是下游路由信息，不复制三条 guideline 的正文，也不替代 design 的论证。 |

### 建议采用的归位形状

```text
guidelines/evolution-*.md
  = 三条方向的唯一完整正文与判断标准

proposal.md / Change Context Card
  = 本 change 是否触发、影响哪些 surface、design 必须完成什么 review
       ↓
design.md / Evolution review + Apply target manifest
  = 按 semantic → control → responsibility 的顺序写出实际取舍和增删的 control surface
       ↓
tasks.md
  = 将已确定的删除、实现、测试与收尾证据拆成可执行任务
```

因此，`context` 不必保留目前 51–60 行那样的三段摘要；即使缩短后仍会被 specs、tasks 等不需要完整设计审查的 artifact 重复注入。项目 profile 中保留 Agent / Markdown / Engine 的稳定 authority split 即可。Directions 的“何时读、读完留下什么”应由 artifact rule 表达。

### 对 `config.yaml` 的具体改写建议

下面不是要求把 guideline 正文复制进 config，而是建议把现有宽泛 rule 改成带触发条件与留痕位置的短路由。字段名和模板标题可按项目现有格式微调。

```yaml
rules:
  proposal:
    - >
      当 change 可能新增或实质改变具名概念/state/projection/status/view、
      control/recovery/mutation，或 user/Agent/Engine 责任边界时，在 Change Context Card
      写明受影响 surface 与 `Evolution review: required`；design.md 必须按
      semantic precision → simple reliable control → helper-oriented responsibility
      留下结论。完整判断标准只读对应的 guidelines/evolution-*.md。

  design:
    - >
      每份 design 先用 `## Evolution review` 按 semantic precision → simple reliable control
      → helper-oriented responsibility 检查本 change；对被新增或实质改变的层，阅读对应
      guidelines/evolution-*.md 并记录简短结论：读者/有界问题与必要区别；direct Source of
      Record、最短合法闭环和净简化；以及 user decision、authorized Agent execution、Engine verdict
      的边界。未改变的层可明确标为不适用。
    - >
      在 design.md 的 `## Apply target manifest` 列出新增、删除或合并的 control surface，
      各自的 Source of Record 与验证证据；tasks 依据此处生成实现和验证动作，不重新创造
      第二份 review 或 authority。
```

这比“每次都完整读三份文件”更能达到你要的前置思考：三层顺序对每个设计都可见，真正相关的原则才被深入加载，且结论会沿 proposal → design → tasks 传下去。它也保留三条 guideline 明确反对的做法：不把反思硬化为固定表格或 Engine verdict，不用“更可靠”作为叠加控制层的理由，也不把 `human-directed` 误写成新的 permission 或 runtime capability。
