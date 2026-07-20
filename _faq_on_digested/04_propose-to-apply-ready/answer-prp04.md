# 答案 PRP-04：`status --json` 如何构建 artifact DAG 状态

## 一句话

`openspec status --change "<name>" --json` 是 propose 循环的状态解释器。它不生成内容，只把 change 目录、schema 和文件系统解释成：

```text
哪些 artifacts done
哪些 artifacts ready
哪些 artifacts blocked
每个 artifact 的输出路径在哪里
apply gate 需要哪些 artifacts
agent 接下来应该怎么行动
```

## 调用链

源码主线：

```text
src/commands/workflow/status.ts
  statusCommand()
    resolveCurrentPlanningHomeSync()
    validateChangeExists()
    loadChangeContext()
    formatChangeStatus()
```

`loadChangeContext()` 做三件事：

1. 解析 change 使用的 schema。
2. 用 schema 创建 `ArtifactGraph`。
3. 扫描 changeDir，得到 completed set。

`formatChangeStatus()` 再把这些信息整理成 agent 可读 JSON。

## schema 如何变成 DAG

默认 `spec-driven` schema 声明：

```yaml
artifacts:
  - id: proposal
    requires: []
  - id: specs
    requires: [proposal]
  - id: design
    requires: [proposal]
  - id: tasks
    requires: [specs, design]
```

`ArtifactGraph.fromSchema(schema)` 把这些 artifact 变成图：

```text
proposal
  -> specs
  -> tasks

proposal
  -> design
  -> tasks
```

`getNextArtifacts(completed)` 判断 ready：

```text
artifact 不在 completed 中
并且 requires 里的每个依赖都已经 completed
```

`getBlocked(completed)` 判断 blocked：

```text
artifact 不在 completed 中
并且 requires 里还有未完成依赖
```

## done 如何判断

done 来自文件系统，不来自 agent 声明。

每个 artifact 有一个 `generates`：

```yaml
proposal -> proposal.md
specs    -> specs/**/*.md
design   -> design.md
tasks    -> tasks.md
```

`resolveArtifactOutputs(changeDir, generates)` 会检查：

- 普通路径：`statSync(fullPath).isFile()` 才算输出存在。
- glob：`fast-glob` 在 changeDir 下匹配 `onlyFiles: true`，至少一个文件匹配才算输出存在。

所以：

```text
proposal.md 是目录 -> 不算 done
specs/ 目录存在但没有 .md -> 不算 done
specs/auth/spec.md 存在 -> specs done
```

## `artifactPaths` 为什么重要

status JSON 里的 `artifactPaths` 把 schema 的抽象输出路径变成当前 change 下的具体路径：

```json
{
  "artifactPaths": {
    "proposal": {
      "outputPath": "proposal.md",
      "resolvedOutputPath": "/repo/openspec/changes/add-auth/proposal.md",
      "existingOutputPaths": []
    },
    "specs": {
      "outputPath": "specs/**/*.md",
      "resolvedOutputPath": "/repo/openspec/changes/add-auth/specs/**/*.md",
      "existingOutputPaths": []
    }
  }
}
```

这让 agent 不需要猜：

```text
这个 change 在哪里？
specs glob 应该落在哪个目录？
哪些 artifact 已经有文件？
```

## `nextSteps` 和 `actionContext`

`nextSteps` 是面向人和 agent 的轻量提示。例如当有 ready artifact 时：

```text
Run openspec instructions proposal --change "add-auth" --json before writing that artifact.
```

`actionContext` 是更硬的范围语义：

```text
repo-local:
  sourceOfTruth = repo
  allowedEditRoots = [projectRoot]
```

v1.5.0 中 `actionContext.mode` 始终为 `repo-local`。跨仓库上下文通过 store reference 获取，但不进入 change 生命周期。

## PRP-04 的输出对 agent 的意义

agent 从 status JSON 得到：

```text
当前 change 根目录
当前 schema
每个 artifact 的状态
当前 ready artifact
artifact 输出路径
applyRequires
actionContext 约束
```

然后 agent 才能进入 PRP-05/PRP-06：选择 ready artifact，调用 `openspec instructions <artifact> --json`。

## 参考来源

源码引用基于 commit `750a03c`：

| 来源 | 用到的结论 |
|---|---|
| `src/commands/workflow/status.ts` | status 命令入口 |
| `src/core/artifact-graph/instruction-loader.ts` | `loadChangeContext()`、`formatChangeStatus()`、`artifactPaths` |
| `src/core/artifact-graph/graph.ts` | ready/blocked/build order 判定 |
| `src/core/artifact-graph/outputs.ts` | 普通路径和 glob 输出完成判定 |
| `src/core/change-status-policy.ts` | `nextSteps` 和 `actionContext` |
