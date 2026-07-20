# 答案 PRP-10：完成判定和 apply-ready 到底是什么

## 一句话

PRP-10 是 propose 阶段的 gate。它不问“agent 觉得写完了吗”，只问：

```text
schema.apply.requires 中要求的 artifacts
在 change 目录下是否都有真实输出文件
```

对默认 `spec-driven` 来说：

```yaml
apply:
  requires: [tasks]
  tracks: tasks.md
```

所以 `tasks` artifact done 后，propose 就可以交棒给 apply。

## artifact done 怎么判断

完成判定来自 `src/core/artifact-graph/outputs.ts`。

核心函数：

```text
resolveArtifactOutputs(changeDir, generates)
artifactOutputExists(changeDir, generates)
```

规则：

| `generates` 类型 | done 条件 |
|---|---|
| 普通路径，例如 `proposal.md` | `statSync(fullPath).isFile()` 为 true |
| glob，例如 `specs/**/*.md` | `fast-glob` 在 changeDir 下 `onlyFiles: true` 匹配到至少一个文件 |

因此：

```text
proposal.md 是目录 -> 不算 done
proposal.md 是文件 -> proposal done
specs/ 目录存在但没有 .md -> specs 不 done
specs/auth/spec.md 存在 -> specs done
```

## applyRequires 怎么用

`status --json` 返回：

```json
{
  "applyRequires": ["tasks"],
  "artifacts": [
    { "id": "tasks", "status": "done" }
  ]
}
```

propose skill 的循环终止条件是：

```text
每个 applyRequires 里的 artifact
在最新 status JSON 中都是 status: "done"
```

这就是 apply-ready 的第一层定义。

## apply-ready 不等于所有事情都正确

apply-ready 表示 planning artifacts 已经足够让 apply skill 开始工作，不表示：

```text
代码已经实现
测试已经通过
tasks 已经完成
artifact 内容一定高质量
```

它只表示：

```text
apply 阶段需要的 artifact 输出文件存在
```

对 spec-driven，通常是 `tasks.md` 存在。

## `instructions apply` 会再做一层 apply 检查

当用户运行 `/opsx:apply`，apply skill 会调用：

```bash
openspec instructions apply --change "<name>" --json
```

`generateApplyInstructions()` 会做这些检查：

1. 读取 schema 的 `apply.requires`。
2. 检查 required artifacts 是否缺失。
3. 收集所有已存在 artifacts，生成 `contextFiles`。
4. 如果 schema 配置了 `tracks`，读取 tracking file。
5. 解析 checkbox tasks。
6. 返回 `state`。

可能的 state：

| state | 含义 |
|---|---|
| `blocked` | 缺 required artifact，或 tracking file 缺失，或 tracking file 没有任何 checkbox task。 |
| `ready` | required artifacts 存在，并且有待执行任务。 |
| `all_done` | tracking file 中所有 task 都已完成。 |

## 一个容易踩的边界：`tasks.md` 存在但没有 checkbox

`tasks.md` 是文件，所以从 artifact DAG 看：

```text
tasks artifact = done
applyRequires = satisfied
```

但 apply instructions 会解析 checkbox：

```text
- [ ] task
- [x] task
```

如果 `tasks.md` 存在但没有任何 checkbox task：

```text
state: "blocked"
instruction: "The tasks.md file exists but contains no tasks..."
```

所以真正可实施的 apply-ready 应该更严格地看：

```text
apply.requires satisfied
并且
openspec instructions apply --json 返回 state: "ready"
```

## contextFiles 是怎么来的

`instructions apply` 会扫描 schema 中所有 artifacts：

```text
proposal
specs
design
tasks
```

每个 artifact 如果有输出文件，就加入：

```json
{
  "contextFiles": {
    "proposal": ["/repo/openspec/changes/add-auth/proposal.md"],
    "specs": ["/repo/openspec/changes/add-auth/specs/auth/spec.md"],
    "design": ["/repo/openspec/changes/add-auth/design.md"],
    "tasks": ["/repo/openspec/changes/add-auth/tasks.md"]
  }
}
```

apply skill 随后要求 agent：

```text
Read every file path listed under contextFiles before starting.
```

这就是 propose 到 apply 的实际交接包。

## 小结

PRP-10 有两层：

```text
Propose 层：
  applyRequires 中的 artifacts 都 done

Apply 层：
  instructions apply 返回 state: ready
  并提供 contextFiles + tasks + progress
```

第一层让 propose 结束；第二层让 implementation 真正可以开始。

## 参考来源

源码引用基于 commit `750a03c`：

| 来源 | 用到的结论 |
|---|---|
| `src/core/artifact-graph/outputs.ts` | `resolveArtifactOutputs()` 和普通路径/glob 完成判定 |
| `src/core/artifact-graph/instruction-loader.ts` | `formatChangeStatus()` 输出 `applyRequires` 和 artifact status |
| `src/commands/workflow/instructions.ts` | `generateApplyInstructions()` 的 blocked/ready/all_done 判定和 `contextFiles` |
| `schemas/spec-driven/schema.yaml` | 默认 `apply.requires: [tasks]` 和 `tracks: tasks.md` |
| `src/core/templates/workflows/apply-change.ts` | apply skill 如何消费 `instructions apply` 输出 |
