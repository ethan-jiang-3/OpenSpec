# 答案 EX04：OpenSpec 状态调查怎么让 agent 知道要读哪些文件

## 一句话

EXP-04 不是“CLI 自动帮 agent 读文件”。它是一段协作协议：

```text
skill / command prompt
  告诉 agent 先运行哪些 CLI 命令
    ↓
OpenSpec CLI
  读取文件系统和 schema，返回结构化 JSON
    ↓
JSON 里的路径字段
  把“应该读哪里”变成明确文件路径
    ↓
coding agent
  用自己的文件读取工具去读这些路径
```

OpenSpec CLI 不直接驱动 LLM，也不直接调用 agent 的 Read 工具。它做的是把文件状态解释成 prompt 里可消费的结构化上下文。

## EX04 在总流程里的位置

主回答里的 `EXP-04 OpenSpec 状态调查` 指的是这一步：

```text
用户意图
  -> Explore stance
  -> 不直接 propose
  -> EXP-04 OpenSpec 状态调查
  -> EXP-05 真实项目调查
  -> EXP-06 合成问题地图
```

它解决的问题是：

```text
如果项目里已经有 OpenSpec change，
agent 怎么知道应该先读哪个 change？
又怎么知道 proposal / design / specs / tasks 文件在哪里？
```

它不解决的问题是：

```text
业务源码里具体该读 src/auth/session.ts 还是 src/routes/oauth.ts？
```

后者主要属于 EXP-05：真实项目调查。

## 第一层：skill prompt 先把动作写给 agent

`src/core/templates/workflows/explore.ts` 里的 explore skill 是 agent 看到的操作手册。里面有一段关键提示词：

```text
At the start, quickly check what exists:

openspec list --json

This tells you:
- If there are active changes
- Their names, schemas, and status
- What the user might be working on
```

这段不是给 CLI 的，是给 coding agent 的。agent 读到 skill 后，会把它当作任务指令，于是先在终端运行：

```bash
openspec list --json
```

同一个 skill 还规定了已有 change 场景：

```text
If the user mentions a change or you detect one is relevant:

1. Resolve and read existing artifacts for context
   - Run openspec status --change "<name>" --json.
   - Use changeRoot, artifactPaths, and actionContext from the status JSON.
   - Read existing files from artifactPaths.<artifact>.existingOutputPaths.
```

这就是“它怎么意识到要读什么文件”的第一半：不是模型凭空知道，而是 skill 明确告诉它：

- 先用 `list` 找 active changes。
- 如果某个 change 相关，再用 `status --json`。
- 从 status JSON 的 `artifactPaths.<artifact>.existingOutputPaths` 取文件路径。
- 然后读这些文件。

## 第二层：`openspec list --json` 只告诉 agent 有没有 active change

`openspec list --json` 的作用很窄：让 agent 知道当前项目是否已经有 planning context。

它回答的是：

```text
现在有没有 active changes？
这些 changes 叫什么？
它们大概是什么 schema / 状态？
用户当前话题是否可能命中其中一个？
```

它不回答：

```text
应该 propose 什么？
应该读哪个源码文件？
这个需求应该拆几个 changes？
```

所以 `list` 只是第一道门。它让 agent 不会在已有相关 change 时盲目新建，也不会在没有 change 时假装有上下文。

## 第三层：`status --json` 把 artifact 文件路径暴露出来

一旦 agent 判断某个 change 可能相关，就运行：

```bash
openspec status --change "<name>" --json
```

源码里对应的是 `src/commands/workflow/status.ts`：

```text
statusCommand()
  resolveCurrentPlanningHomeSync()
  validateChangeExists()
  loadChangeContext()
  formatChangeStatus()
  print JSON
```

`formatChangeStatus()` 在 `src/core/artifact-graph/instruction-loader.ts` 里组装关键字段：

```text
changeRoot
artifactPaths
actionContext
artifacts
nextSteps
```

其中最重要的是 `artifactPaths`。它的形状大致是：

```json
{
  "artifactPaths": {
    "proposal": {
      "outputPath": "proposal.md",
      "resolvedOutputPath": "/repo/openspec/changes/add-auth/proposal.md",
      "existingOutputPaths": [
        "/repo/openspec/changes/add-auth/proposal.md"
      ]
    },
    "specs": {
      "outputPath": "specs/**/*.md",
      "resolvedOutputPath": "/repo/openspec/changes/add-auth/specs/**/*.md",
      "existingOutputPaths": [
        "/repo/openspec/changes/add-auth/specs/auth/spec.md"
      ]
    }
  }
}
```

这里有一个关键设计：CLI 没有返回“请你想办法去找 proposal”。它直接返回 resolved path 和 existing output paths。agent 不需要猜目录，也不需要硬编码 `openspec/changes/<name>/...`。

这就是 EXP-04 的核心：**把 schema 里的 artifact 定义，变成当前 change 下的具体文件路径。**

## 第四层：agent 不是被强制读文件，而是被 prompt + JSON 引导读文件

大型语言模型本身不能“自动读文件”。coding agent 之所以会读，是因为宿主工具给它提供了文件读取能力，而 skill prompt 明确要求它执行：

```text
Read existing files from artifactPaths.<artifact>.existingOutputPaths.
```

于是 agent 的动作会变成：

```text
1. 解析 status JSON。
2. 取 artifactPaths.proposal.existingOutputPaths。
3. 调用宿主环境的 Read / cat / sed / rg 等工具读取这些路径。
4. 把读到的 proposal/design/specs/tasks 纳入上下文。
5. 再继续和用户讨论。
```

OpenSpec 在这里不是“遥控 agent”，而是提供一个稳定协议：

| 层 | 做什么 |
|---|---|
| skill prompt | 指示 agent 必须运行哪些 CLI 命令、读哪些 JSON 字段 |
| CLI | 根据当前 planning home、schema、change 文件状态生成 JSON |
| JSON 字段 | 把抽象 artifact 映射到具体路径 |
| coding agent | 调用自己的文件读取工具，把路径内容读入上下文 |

## 第五层：`instructions` 命令在 artifact 创建阶段会进一步列出依赖文件

Explore 读已有 artifact 时主要靠 `status --json` 的 `artifactPaths`。但在 propose/continue/ff 这类 artifact 创建阶段，还会多一层：

```bash
openspec instructions <artifact-id> --change "<name>" --json
```

`src/commands/workflow/instructions.ts` 会调用：

```text
loadChangeContext()
generateInstructions()
```

`generateInstructions()` 会返回：

```text
resolvedOutputPath
existingOutputPaths
dependencies
instruction
context
rules
template
unlocks
```

其中 `dependencies` 是另一个“告诉 agent 读什么”的机制。人类模式下打印出来甚至直接写成：

```text
Read these files for context before creating this artifact:

<dependency id="proposal" status="done">
  <path>/repo/openspec/changes/add-auth/proposal.md</path>
  <description>...</description>
</dependency>
```

JSON 模式下同样有 `dependencies` 字段。agent 就能知道：写 `tasks.md` 前要读 `specs` 和 `design`，写 `design.md` 前要读 `proposal`。

所以有两种“读文件提示”：

| 场景 | 命令 | agent 读文件依据 |
|---|---|---|
| Explore 既有 change | `openspec status --change X --json` | `artifactPaths.<artifact>.existingOutputPaths` |
| 创建/继续 artifact | `openspec instructions <artifact> --change X --json` | `dependencies` + `resolvedOutputPath` + `template` |

## 第六层：`actionContext` 告诉 agent 能把这些路径当成什么范围

`status --json` 还返回 `actionContext`。它不是文件列表，而是 scope/权限语义：

```json
{
  "mode": "repo-local",
  "sourceOfTruth": "repo",
  "planningArtifacts": ["proposal", "specs", "design", "tasks"],
  "linkedContext": [],
  "allowedEditRoots": ["/repo"],
  "requiresAffectedAreaSelection": false,
  "constraints": [
    "Repo-local change artifacts and implementation edits are scoped to this project."
  ]
}
```

`actionContext.mode` 始终为 `repo-local`。跨仓库上下文通过 store reference 获取——agent 可以读取 referenced store 的 specs 索引，但不内联内容、不自动写入。

## 第七层：EXP-04 不会告诉 agent 读业务源码的具体文件

这里要把边界说清楚：EXP-04 能稳定告诉 agent 读 OpenSpec 文件，例如 proposal、design、specs、tasks。它不负责精确列出业务源码：

```text
src/auth/session.ts
src/routes/oauth.ts
test/auth/oauth.test.ts
```

这些业务源码路径通常来自 EXP-05，也就是 agent 对真实项目的调查：

- 用户提到的模块名、命令名、报错、文件名。
- proposal/design/specs/tasks 里提到的影响面。
- `rg` 搜索相关关键词。
- 代码入口、测试目录、import graph、命令注册等项目结构线索。
- agent 自己的工程判断。

也就是说：

```text
EXP-04 负责把 OpenSpec planning context 交给 agent。
EXP-05 负责让 agent 从真实代码里找 implementation context。
```

这两个动作会互相影响。已有 `proposal.md` 的 Impact 里可能提到 `src/auth/*`，于是 agent 会去读这些源码；源码调查又可能反过来发现 proposal scope 不准，需要回到 Explore 里建议更新 artifact。

## 小结

EXP-04 不是一个“自动读文件系统”的黑盒，而是一段协作协议：

```text
skill prompt 规定动作
  -> agent 调 openspec list/status/instructions
  -> CLI 读取 schema + change 文件状态
  -> CLI 返回 artifactPaths/dependencies/actionContext
  -> agent 解析 JSON
  -> agent 调宿主读文件工具
  -> 读到的文件进入 LLM 上下文
```

这个设计的好处是：OpenSpec 不需要嵌入某个特定 LLM 或 IDE。只要 coding agent 能读 skill/command、能运行 CLI、能读取本地文件，就能按同一套协议把 OpenSpec 状态转成自己的工作上下文。

## 参考来源

源码引用基于 commit `2fd20d8`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore skill 明确要求 `openspec list --json`、相关 change 用 `status --json`，并读取 `artifactPaths.<artifact>.existingOutputPaths` |
| `src/commands/workflow/status.ts` | `status --json` 解析 planning home、change、schema 后输出结构化 status JSON |
| `src/commands/workflow/instructions.ts` | `instructions <artifact> --json` 输出依赖文件、输出路径、template、rules、instruction 等 agent 操作包 |
| `src/core/artifact-graph/instruction-loader.ts` | `formatChangeStatus()` 组装 `artifactPaths`、`actionContext`、`nextSteps`；`generateInstructions()` 组装 artifact instructions |
| `src/core/change-status-policy.ts` | `actionContext` 和 `nextSteps` 的语义 |
