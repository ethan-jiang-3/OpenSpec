# 答案 PRP-06：`instructions <artifact> --json` 如何变成 agent 操作包

## 一句话

`openspec instructions <artifact> --change "<name>" --json` 把“现在要写哪个 artifact”编译成 agent 可执行的操作包：

```text
写到哪里
写之前读哪些依赖
用什么模板
遵守哪些 schema instruction
应用哪些 project context / rules
完成后会解锁什么
```

它不是普通帮助文本，而是 agent 写 artifact 的运行时输入。

## 调用链

源码主线：

```text
src/commands/workflow/instructions.ts
  instructionsCommand()
    resolveCurrentPlanningHomeSync()
    validateChangeExists()
    loadChangeContext()
    generateInstructions()
```

`generateInstructions()` 位于 `src/core/artifact-graph/instruction-loader.ts`，它负责组装最终 JSON。

## 输出字段

典型字段：

```text
changeName
artifactId
schemaName
changeDir
planningHome
outputPath
resolvedOutputPath
existingOutputPaths
description
instruction
context
rules
template
dependencies
unlocks
```

agent 的使用方式：

| 字段 | agent 怎么用 |
|---|---|
| `resolvedOutputPath` | 目标写入路径；普通文件是绝对路径，glob artifact 需要按 instruction 选择具体文件。 |
| `existingOutputPaths` | 判断该 artifact 是否已有输出，避免覆盖或重复生成。 |
| `dependencies` | 写当前 artifact 前必须读取的已完成依赖。 |
| `template` | artifact 文件结构，不是背景说明。 |
| `instruction` | schema 对当前 artifact 的具体写作/生成规则。 |
| `context` | project config 背景，只约束 agent，不写进 artifact。 |
| `rules` | artifact-specific 项目规则，只约束 agent，不写进 artifact。 |
| `unlocks` | 完成当前 artifact 后下一轮可能 ready 的 artifacts。 |

## dependencies 怎么来

schema 中每个 artifact 有 `requires`：

```yaml
tasks:
  requires:
    - specs
    - design
```

`getDependencyInfo()` 会把这些依赖转成：

```json
[
  {
    "id": "specs",
    "done": true,
    "path": "specs/**/*.md",
    "description": "Detailed specifications for the change"
  },
  {
    "id": "design",
    "done": true,
    "path": "design.md",
    "description": "Technical design document with implementation details"
  }
]
```

人类文本模式下，CLI 会直接打印：

```text
Read these files for context before creating this artifact:
```

JSON 模式下，agent 解析 `dependencies`，再结合 `changeDir` 或 `artifactPaths` 去读取实际文件。

## template 和 instruction 的区别

`template` 是文件形状。例如 `tasks.md` 模板告诉 agent 用：

```markdown
## 1. Group
- [ ] 1.1 Task
```

`instruction` 是语义规则。例如 `tasks` instruction 告诉 agent：

```text
checkbox format is required
tasks should be small enough
order tasks by dependency
```

对于 `specs`，instruction 还会强调：

```text
Scenario 必须是 #### Scenario:
MODIFIED 要复制完整 requirement block
每个 requirement 至少一个 scenario
```

agent 应该同时遵守二者：template 控制结构，instruction 控制语义。

## context/rules 为什么不能复制进 artifact

`context` 和 `rules` 来自项目 config。它们是给 agent 的背景和约束：

```text
Project context injected into all artifact instructions
Artifact-specific rules from config
```

propose skill 明确要求：

```text
context and rules are constraints for YOU, not content for the file
Do NOT copy them into the file
```

所以 agent 应该让它们影响写作，但不能把 `<context>`、`<rules>`、`<project_context>` 这类标签写进 proposal/specs/design/tasks。

## glob artifact 怎么处理

`specs` 的输出是：

```text
specs/**/*.md
```

这不是一个具体文件名。agent 要根据 proposal 的 capabilities 和 schema instruction 选择具体路径：

```text
specs/<capability>/spec.md
```

例如 proposal 里写了：

```text
New Capabilities:
- user-auth
```

agent 就应该写：

```text
<changeRoot>/specs/user-auth/spec.md
```

## PRP-06 的本质

PRP-06 把 schema 和项目配置变成一次具体写作任务：

```text
abstract artifact definition
  -> concrete output path
  -> dependency reading list
  -> writing template
  -> semantic rules
  -> next unlocked artifacts
```

agent 不是靠猜测写 artifacts，而是每轮都从 CLI 获取当前 artifact 的操作包。

## 参考来源

源码引用基于 commit `750a03c`：

| 来源 | 用到的结论 |
|---|---|
| `src/commands/workflow/instructions.ts` | instructions 命令入口和文本输出结构 |
| `src/core/artifact-graph/instruction-loader.ts` | `generateInstructions()`、`getDependencyInfo()`、template/context/rules 组装 |
| `schemas/spec-driven/schema.yaml` | proposal/specs/design/tasks 的 template、instruction、requires |
| `src/core/templates/workflows/propose.ts` | propose skill 如何消费 instructions JSON |
