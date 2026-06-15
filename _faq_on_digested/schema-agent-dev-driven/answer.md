# 答案：Agent-Dev-Driven Schema — 和 spec-driven 同框架，交付物从代码换成 agent

## 一句话

`agent-dev-driven` 和 `spec-driven` 使用**完全相同的 4-artifact 框架**（proposal → specs → design → tasks → apply），不改 OpenSpec 源码。区别只在每个 artifact 的 **instruction 内容**——把「写代码」换成「开发 agent」。spec-driven 的框架是领域无关的：它对软件研发和 agent 开发同样适用。

```text
spec-driven       框架 = proposal → specs → design → tasks → apply  交付 = 代码
agent-dev-driven  框架 = proposal → specs → design → tasks → apply  交付 = agent 组件
```

## 为什么会想到这个

已有过一个 4-artifact 雏形（persona → skills → {scripts, tests}），证明了 OpenSpec 可以管理 agent 开发。但它的问题是**自建了一套 artifact 名和 DAG**，和 spec-driven 不通用——每个用过 spec-driven 的人都要重新学。

真正的洞察是：spec-driven 的 4 个 artifact 对 agent 开发**完全够用**——不需要发明新的。proposal 定义"为什么建这个 agent、它能做什么、不能做什么"；specs 用 delta ops 规格化每个 capability；design 规划实现方案（skills/commands/tools/evals/CLI）；tasks 跟踪构建进度；apply 执行并接入 harness。这和软件研发的流程是同构的——proposal 说"为什么改"，specs 说"改成什么样"，design 说"怎么实现"，tasks 跟踪进度，apply 执行。

差异只在内容的"风味"：proposal 多了安全护栏（Constraints）和 system-prompt 等价物（Baseline Prompt），design 重了（agent 的完整实现方案 vs 可选技术文档），tasks 跟踪的是 MD 文件编写和 harness 接入而不是代码实现。

## 核心设计：和 spec-driven 同构

```
proposal → specs → design → tasks → apply
```

**对比 spec-driven**：

| artifact | spec-driven | agent-dev-driven | 差异 |
|----------|------------|-----------------|------|
| `proposal` | Why / What Changes / Capabilities / Impact | 保留全部 + **Constraints**（硬约束+拒绝话术表）+ **Baseline Prompt**（system-prompt 等价物） | agent 需要安全护栏和可注入的 system prompt |
| `specs` | delta ops（ADDED/MODIFIED/REMOVED/RENAMED），Requirement+Scenario | **不改**——完全相同的 delta-ops 格式和 archive 合并机制 | 描述对象从「软件系统」换成「AI agent」，但格式通用 |
| `design` | Context / Goals·Non-Goals / Decisions / Risks·Trade-offs / Migration Plan（可选：仅跨模块变更时需要） | 保留全部 + **Skills**（每个 capability 的 skill 实现）/ **Commands**（slash-command 编排）/ **Tools**（工具设计+适配）/ **Evals**（测试计划）/ **CLI**（CLI 表面设计）。**必写**——agent 的实现方案 | agent 组件需要比代码更完整的蓝图 |
| `tasks` | checkbox checklist（Setup / Core Implementation / …） | checkbox checklist——跟踪的从「代码实现」换成「skill MD 编写 / command 注册 / tool 脚本 / eval 用例 / CLI 入口 / harness 集成」 | checklist 格式通用，内容更丰富 |
| `apply` | Read context → work through tasks → mark complete | 就绪检查 → 构建 agent 组件 → 渲染/拷贝进 harness 目录 → 跑 evals → 端到端验证 | 交付步骤多一步：harness 集成 |

**requires 关系——和 spec-driven 完全一致**：

```text
proposal  requires: []
specs     requires: [proposal]
design    requires: [proposal]
tasks     requires: [specs, design]
apply     requires: [tasks]      tracks: tasks.md
```

这和 `schemas/spec-driven/schema.yaml` 完全同构。artifact 名一样、DAG 一样、apply.tracks 一样。fork 一份，改 instruction 内容即可。

## 关键设计决策

### 决策 1：为什么不自建 artifact 名

已有雏形用了 persona/skills/scripts/tests 四个自建名。但 spec-driven 的 proposal/specs/design/tasks 四个词已经是 OpenSpec 用户的心智模型——换一套名字无意义地增加认知负担。proposal 就是 proposal（定义 scope 和 motivation），不管 deliverable 是代码还是 agent。specs 就是 specs（delta ops 规格），不管规格对象是软件系统还是 AI agent。design 就是 design（实现方案），不管方案内容是代码架构还是 agent 组件。

唯一真正的差异是内容——proposal 要多写 Constraints 和 Baseline Prompt，design 要多写 Skills/Commands/Tools/Evals/CLI 段。这些通过 instruction 和 template 表达，不需要新 artifact。

### 决策 2：为什么 design 从可选变成必写

spec-driven 的 design 是条件性的——简单的 change 可以跳过。但 agent 的 design 是 agent 本身——skills、commands、tools、evals、CLI 的完整定义就是 agent 的实现方案。没有 design，tasks 无法派生，apply 不知道该产出什么。所以 agent-dev-driven 的 design 不加"create only if any apply"——它总是需要的。

### 决策 3：为什么 specs 完全不改

delta ops（ADDED/MODIFIED/REMOVED/RENAMED）+ Requirement（SHALL/MUST）+ Scenario（WHEN/THEN，恰好 4 个 `#`）这套格式对 agent capability 完全适用——"WHEN 用户说 X，THEN agent 做 Y"和"WHEN 系统收到 X，THEN 系统返回 Y"是同构的。archive 合并机制（delta specs 合并进 `openspec/specs/`）也完全复用——agent capabilities 和软件 capabilities 一样值得持久化积累。

### 决策 4：为什么 tasks.md 仍然叫 tasks.md

和 spec-driven 同名——而且 `openspec change --long` 的进度计数硬编码了这个文件名。不改名比改名更实用。

## 这验证了什么

1. **spec-driven 的框架是领域无关的**。proposal/specs/design/tasks/apply 这套 artifact DAG 对代码开发和 agent 开发同样适用——换 instruction 内容即可，不需要换 artifact 结构。`openspec status` 和 `openspec instructions` 对两个 schema 执行完全相同的逻辑。
2. **delta ops 格式是通用的**。agent capability 的 specs 和软件 capability 的 specs 使用完全相同的 Requirement+Scenario 语法——WHEN/THEN 对两者都适用。archive 合并机制零成本复用。
3. **design 的"加重"是自然的**。spec-driven 的 design 已经是完整的实现方案模板——加 Skills/Commands/Tools/Evals/CLI 段只是扩展了章节，不是改变了 artifact 的角色。
4. **4 模板 vs 9 模板**。精简到和 spec-driven 同数——认知负担最小，fork 成本最低。

## 使用方式

1. fork spec-driven 改 instruction：
   ```bash
   openspec schema fork spec-driven agent-dev-driven
   # 然后用 schema-package/ 里的 schema.yaml + templates 覆盖
   ```
   或直接复制：
   ```bash
   cp -r schema-package/ openspec/schemas/agent-dev-driven/
   ```

2. `openspec schema validate agent-dev-driven`

3. `openspec new change build-my-agent --schema agent-dev-driven`

4. 按 DAG 顺序写 artifact（和 spec-driven 完全一样的流程）

> 完整的 schema 扩展实操指南见 [`answer-add-schema.md`](answer-add-schema.md)。

## 已知限制

1. **OpenSpec 无模型 eval**。evals 只能断言产物形状（grep、jq、文件存在），不能判断 agent 输出质量。
2. **design 的加重依赖 agent**。Skills/Commands/Tools/Evals/CLI 段的内容质量取决于 agent 对 harness 机制的理解——instruction 写得好坏直接影响产出。
3. **change 列表 tasks.md 硬编码**。和 spec-driven 一样——`openspec change --long` 只看文件名叫 `tasks.md` 的。

---

> 完整 schema-package（`schema.yaml` + 4 个 `templates/*.md`）在 [`schema-package/`](schema-package/)。
> spec-driven 原版在 `schemas/spec-driven/schema.yaml`——本 schema 是其 instruction 级 fork。
