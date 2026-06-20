# 对照常见 SDD 与 AI Coding

## 为什么需要这篇

如果你已经熟悉 SDD、AI Coding、agent workflow，很容易把 OpenSpec 归到一个已有类别里：

- PRD-first 文档流
- task-first 执行流
- prompt-template 工具
- agent memory / context store
- IDE 插件
- monorepo workspace

这些类比都有一点像，但都不完整。OpenSpec 更像一套本地协议：用文件表达状态，用 CLI 解释状态，用 schema 定义产物图，再让 agent 在这个协议上推理和执行。

这篇只做概念对照，帮助你把已有经验迁移过来，同时避免把旧框架的假设投射到 OpenSpec 上。

## 和 PRD-first 的区别

PRD-first 通常从一份大文档开始：先把需求讲完整，再拆设计和任务。OpenSpec 也有 proposal 和 specs，但它不把 PRD 当唯一中心。

OpenSpec 的中心是：

```text
specs/ 当前 capability 基线
changes/<name>/ 本次增量协议
```

proposal 解释为什么改、改什么；delta specs 解释capability 基线怎么变化；design 解释技术方案；tasks 解释实施步骤。它们都是 change 的 artifact，不是彼此的随意附件。

所以 OpenSpec 更适合 brownfield：你不是每次写一份从零开始的 PRD，而是在已有 spec 基线上提交增量 patch。

## 和 task-first 的区别

task-first 工作流容易直接从待办清单开始：把需求拆成任务，agent 逐项实现。它推进快，但风险是任务列表可能没有稳定语义基线。

OpenSpec 里的 `tasks.md` 不是第一事实源。默认 `spec-driven` 里，tasks 依赖 specs 和 design：

```text
proposal
  ├── specs
  └── design
       └── tasks
```

这表示 tasks 应该从行为变化和技术方案推导出来。apply 阶段消费 tasks，但 tasks 不替代 proposal、delta specs 或 design。

工程意义是：实施清单可以被执行和勾选，但它不是系统承认的 capability 合同。真正长期留下的是 archive 后的 `openspec/specs/`。

## 和 prompt-template-first 的区别

很多 AI Coding 工具的核心资产是 prompt template：写好模板，交给 agent 运行。OpenSpec 也有 templates，但模板不是系统的最高层。

OpenSpec 的顺序更像：

```text
schema artifact DAG
  → artifact instruction
  → markdown template
  → CLI 编译 context/rules/dependencies
  → agent 推理生成
```

模板只解决“输出长什么样”。schema 解决“有哪些产物、产物之间怎么依赖、什么条件下能 apply”。CLI 解决“当前实例状态和上下文是什么”。

因此改模板会影响输出风格和结构，但不等于改 workflow 语义。要改 workflow 语义，需要看 schema、profile、workflow template 和 runtime API 的边界。

## 和 agent memory / context store 的区别

很多 agent 系统强调 memory：把历史事实、偏好和项目知识存进一个长期上下文。OpenSpec 对上下文更保守。

repo-local 的长期事实是：

```text
openspec/specs/
```

workspace/context-store/initiative 提供跨 repo 协调上下文，但它也不是“agent 私有记忆”。它是本机或团队可管理的协调数据：

```text
context store
  └── initiatives/<id>/
      ├── requirements.md
      ├── design.md
      ├── decisions.md
      ├── questions.md
      └── tasks.md
```

OpenSpec 的倾向是让关键上下文可读、可版本化、可检查，而不是只存在 agent 的隐式 memory 里。

## 和 IDE/plugin workflow 的区别

IDE 插件通常把工作流绑定到某个宿主：命令入口、UI、状态、执行逻辑都在插件里。OpenSpec 刻意不这么做。

它把宿主工具差异压到 delivery 层：

```text
same workflow semantics
  → skills
  → commands
  → per-tool adapters
```

这意味着 Claude、Codex、Cursor、OpenCode 等工具看到的入口形态可能不同，但核心语义应该来自同一套 workflow templates 和 CLI runtime API。

所以评估 OpenSpec 时，不要只看某个工具里的 slash command 长什么样。那只是外壳。更稳定的是 `status`、`instructions`、schema、templates 和文件状态。

## 和 monorepo / multi-root workspace 的区别

multi-root workspace 常被理解为”把很多 repo 放进一个开发窗口”。OpenSpec workspace 也能打开多个 repo/folder，但它的边界更窄。

OpenSpec workspace 是 local coordination view：

- `view.yaml` 记录本机 links、context、opener、workspace skills。
- `AGENTS.md` 和 `.code-workspace` 是 open surface。
- context store / initiative 保存协调上下文。
- linked repo/folder 仍然保留自己的归属。

它不把多个 repo 合成一个新的 source of truth，也不自动决定哪个 repo 应该创建可归档 change。实现和规格归属仍要回到 owning repo，除非具体 workflow 明确支持 workspace 级规划。

## 和传统阶段式 SDD 的区别

传统 SDD 容易被理解为阶段式：

```text
requirements → design → implementation → verification
```

OpenSpec 表面也有类似 artifact，但源码机制不是阶段锁。artifact 是 DAG 节点，workflow 是动作入口。

```text
status 告诉 agent 哪些节点 ready / blocked / done
instructions 告诉 agent 当前节点怎么写
apply gate 告诉 agent 是否能进入实施
archive 把 delta specs 合并回主 specs
```

阶段式流程常把“进入下一阶段”当状态。OpenSpec 更倾向用文件状态和依赖图表达“现在能做什么”。这让它允许回写：实施中发现设计问题，可以更新 design/tasks/specs 后继续。

## OpenSpec 概念迁移表

| 你熟悉的概念 | 在 OpenSpec 中更准确的对应 |
|--------------|----------------------------|
| Product baseline | `openspec/specs/` 当前capability 基线 |
| Change request | `openspec/changes/<name>/` |
| PRD / proposal | `proposal.md`，解释 why 和 scope |
| Spec patch | change 下的 `specs/**/*.md` delta spec |
| Architecture note | `design.md` |
| Implementation checklist | `tasks.md`，同时是 apply tracking file |
| Workflow definition | schema artifact DAG，不只是 prompt |
| Agent prompt | workflow template + CLI instructions 输出 |
| Tool integration | skill/command delivery |
| Runtime state API | `openspec status --json` |
| Action instruction API | `openspec instructions ... --json` |
| Multi-repo context | workspace + context store + initiative |

## 什么时候 OpenSpec 的设计特别有价值

OpenSpec 的优势在这些场景里最明显：

- brownfield 项目：已有行为不能靠一次性 PRD 重写。
- 多次迭代的 change：规划和实施会互相修正。
- 需要 agent 可重复执行：不能只靠聊天上下文记住状态。
- 需要跨工具复用 workflow：不想绑定某个 agent 平台。
- 需要审计规格变化：希望 delta 和 archive 留在 Git 历史里。
- 需要自定义工作流：默认 proposal/specs/design/tasks 不够用，需要 schema 化。

它不一定适合所有情况。如果只是一次很小的临时代码修改，完整 OpenSpec change 可能显得重。但只要你关心“AI 生成的规划和实施是否能被长期检查”，OpenSpec 的协议化设计就开始有意义。

## 接下来怎么读

读完这篇后，可以按问题进入：

| 问题 | 下一篇 |
|------|--------|
| OpenSpec 自己的系统主轴是什么 | `01-系统心智模型.md` |
| 文件分别在哪里，哪些是事实源 | `02-目录与状态边界.md` |
| schema 为什么不是模板别名 | `../schema/01-schema-到底是什么.md` |
| CLI 为什么像 runtime API | `../spec_cli/03-workflow-runtime-api.md` |
| 默认 spec-driven 到底怎么跑 | `../internal-spec-driven/00-四条命令的共有机制.md` |
| workspace/context-store 的边界 | `../mechanisms/01-workspace-coordination.md` |
