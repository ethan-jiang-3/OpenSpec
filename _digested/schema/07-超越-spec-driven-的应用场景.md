# 07 · 超越 spec-driven 的应用场景

> 回 [导读](00-map.md)

OpenSpec 的 schema 系统本质上不绑定任何特定领域。虽然名字里带 "spec"，但它真正的能力是**定义一个迭代产物的结构和生成规则**——产物可以是代码规格、文章、剧本、Agent 配置，或任何可结构化输出的东西。

---

## 核心洞察

OpenSpec 的 artifact DAG 足够通用，因为它只关心这些问题：

1. 有哪些 artifact？（`id`）
2. 每个生成什么文件？（`generates`）
3. 用什么 markdown 骨架？（`template`）
4. 给 AI 什么专属指令？（`instruction`）
5. 谁依赖谁？（`requires`）

它不关心 artifact **里面写的是什么**——那是 template 和 instruction 决定的。

所以把 proposal/specs/design/tasks 换成 article/research/outline/draft 或者 character/plot/chapter/scene，系统照样工作。

---

## 场景 1：写文章/专栏

### 文章写作 schema

```yaml
name: article-writing
version: 1
description: 结构化文章写作工作流

artifacts:
  - id: research
    generates: research.md
    description: 资料搜集和主题研究
    template: research.md
    instruction: |
      搜集和研究文章主题：
      - 核心论点是什么？
      - 支撑论据有哪些来源？
      - 对立观点和反驳
      - 关键数据和引用
      格式化为结构化的研究笔记。
    requires: []

  - id: outline
    generates: outline.md
    description: 文章大纲
    template: outline.md
    instruction: |
      基于 research.md 创建文章大纲：
      - 引言（钩子 + 论点）
      - 主体段落（每段一个核心观点 + 论据）
      - 结论（总结 + 行动号召）
      每段标注预计字数和引用的研究材料。
    requires:
      - research

  - id: draft
    generates: draft.md
    description: 初稿
    template: draft.md
    instruction: |
      基于 outline.md 和 research.md 写初稿。
      - 自然流畅的中文表达
      - 每个观点都要有具体例证
      - 段落间有清晰的逻辑过渡
      - 目标读者是技术背景的中级从业者
    requires:
      - outline

  - id: polish
    generates: final.md
    description: 润色终稿
    template: final.md
    instruction: |
      润色 draft.md：
      - 检查逻辑一致性和论据支撑
      - 优化句子节奏和可读性
      - 修正语法和用词
      - 添加合适的标题层级
      - 确保 SEO 友好的标题和摘要
    requires:
      - draft

apply:
  requires: [polish]
  tracks: polish.md
  instruction: |
    最终检查：格式、链接、引用完整性。确认后发布。
```

依赖图：`research → outline → draft → polish → 发布`

### 对比 spec-driven

| spec-driven | article-writing | 角色变化 |
|-------------|----------------|---------|
| proposal | research | "为什么做这个 change" → "写什么主题、有什么材料" |
| specs | outline | "系统应该做什么" → "文章结构" |
| design | （无直接对应） | — |
| tasks | draft + polish | "实现步骤" → "写作和润色步骤" |

---

## 场景 2：写剧本/故事

### 故事创作 schema

```yaml
name: story-writing
version: 1
description: 结构化故事创作工作流

artifacts:
  - id: premise
    generates: premise.md
    description: 故事前提和核心冲突
    template: premise.md
    instruction: |
      定义故事的核心要素：
      - 一句话梗概（logline）
      - 主角、目标、障碍、 stakes
      - 核心冲突类型（人vs人/人vs自我/人vs环境等）
      - 故事类型和基调
    requires: []

  - id: characters
    generates: characters.md
    description: 角色设定
    template: characters.md
    instruction: |
      基于 premise.md 创建主要角色设定：
      - 每个角色的外貌、性格、背景故事
      - 角色弧线（起点 → 变化 → 终点）
      - 角色之间的关系网
      - 每个角色在核心冲突中的立场
    requires:
      - premise

  - id: plot
    generates: plot.md
    description: 情节大纲
    template: plot.md
    instruction: |
      基于 premise 和 characters 创建情节大纲：
      - 三幕结构或章节划分
      - 关键转折点
      - 每章的主要事件和角色发展
      - 节奏控制（紧张/释放的交替）
    requires:
      - premise
      - characters

  - id: scenes
    generates: "scenes/**/*.md"
    description: 逐场景写作
    template: scene.md
    instruction: |
      基于 plot 大纲逐场景写作：
      - 每个场景要有明确的目的（推进情节/揭示角色/建立氛围）
      - 包含对话、动作、环境描写
      - 场景间有自然的过渡
    requires:
      - plot

apply:
  requires: [scenes]
  tracks: scenes
  instruction: |
    通读全稿，检查一致性、节奏、角色声音。标记需要修改的场景。
```

---

## 场景 3：Agent/Skill 内容开发

这是最贴近 OpenSpec "本行" 但被低估的场景——用同样的 schema 机制来管理 AI agent 的 prompt 和 skill 开发。

### Agent 开发 schema

```yaml
name: agent-development
version: 1
description: AI Agent 的 Skill 和 Prompt 开发工作流

artifacts:
  - id: persona
    generates: persona.md
    description: Agent 角色定义
    template: persona.md
    instruction: |
      定义 Agent 的角色和行为边界：
      - Agent 的名字、身份、专业领域
      - 核心能力范围（能做什么）
      - 行为边界（不能做什么，什么情况下必须拒绝）
      - 沟通风格和语气指南
      - 用户画像（Agent 的服务对象是谁）
    requires: []

  - id: skills
    generates: "skills/**/*.md"
    description: Skill 定义（Markdown 格式）
    template: skill.md
    instruction: |
      基于 persona.md 定义 Agent 的技能：
      - 每个 skill 一个文件
      - skill 名称、触发条件、执行步骤
      - 输入输出格式
      - 错误处理和边界情况
      - 与其他 skill 的协作方式
    requires:
      - persona

  - id: scripts
    generates: "scripts/**/*"
    description: 配套脚本（Python/Shell/JS）
    template: script.py
    instruction: |
      为 skills 编写配套执行脚本。每个脚本对应一个或多个 skill 的自动化部分。
    requires:
      - skills

  - id: tests
    generates: "tests/**/*"
    description: Agent 行为测试用例
    template: test.md
    instruction: |
      为每个 skill 编写行为测试：
      - 正常路径的输入和期望输出
      - 边界情况的输入和期望行为
      - 拒绝场景的输入和期望拒绝理由
    requires:
      - skills

apply:
  requires: [skills, scripts, tests]
  tracks: tests
  instruction: |
    就绪检查：所有 skill 有对应 test，所有脚本可执行。
    集成到 Agent 运行时并验证。
```

---

## 场景 4：TDD 驱动开发

这是社区里实际出现过的案例——有人创建了 `tdd-driven` schema，把 TDD 纪律嵌入每个阶段。

```yaml
name: tdd-driven
version: 1
description: TDD 驱动的开发工作流

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    instruction: |
      创建 proposal，要求：
      - 使用 WHEN/THEN 格式列出可测试的验收标准
      - 每个功能点都要有对应的测试策略
    requires: []

  - id: specs
    generates: "specs/**/*.md"
    template: spec.md
    instruction: |
      写规格，强制 GIVEN/WHEN/THEN 格式。
      每个场景必须可独立测试。
    requires: [proposal]

  - id: plans
    generates: plans.md
    description: TDD 微步骤计划
    template: plans.md
    instruction: |
      拆分为 2-5 分钟的 TDD 微步骤：
      Red（先写失败测试） → Green（最小实现） → Refactor（重构）
    requires: [specs]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    instruction: |
      按 TDD 顺序组织任务：测试先行，实现随后。
    requires:
      - specs
      - plans

apply:
  requires: [tasks, plans]
  tracks: tasks.md
  instruction: |
    严格按 TDD 循环实现。先写测试确认失败，再最小实现通过，
    最后重构。不做超前设计。
```

---

## 这里的关键启示

OpenSpec 的 artifact 系统**不绑定领域语义**。它是一套通用的"迭代产出物管理"框架。你的想象力决定了它的边界：

| 你想产出什么 | 可以定义什么 artifact |
|------------|---------------------|
| 软件变更 | proposal / specs / design / tasks |
| 文章 | research / outline / draft / polish |
| 剧本 | premise / characters / plot / scenes |
| Agent | persona / skills / scripts / tests |
| 课程 | objectives / outline / lessons / exercises |
| 产品规划 | vision / user-research / roadmap / prd |
| 学术论文 | literature-review / hypothesis / experiment / paper |
| 设计系统 | principles / components / patterns / docs |

**唯一的前提是**：你的产出物可以用 Markdown 文件表达，且它们之间有生成顺序的依赖关系。仅此而已。
