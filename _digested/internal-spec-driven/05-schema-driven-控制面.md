# 05 — schema-driven 控制面

前面四篇分别讲了每条命令怎么运作。这篇从"元"的视角看整个 spec-driven 的控制面 —— 也就是 schema 本身如何成为工作流的"源码"。

---

## 1. schema.yaml 即源码

`schemas/spec-driven/schema.yaml` —— 约 153 行 —— 定义了 spec-driven 工作流的全部行为。它是 OpenSpec "meta" 本质的集中体现：

- **artifact 是什么、先后顺序谁说了算** → schema
- **每个 artifact 应该包含什么内容** → schema 的 `instruction` 字段
- **输出文件的结构骨架** → schema 引用的 `templates/*.md`
- **什么时候允许实施** → schema 的 `apply.requires`
- **实施进度怎么跟踪** → schema 的 `apply.tracks`

改变这约 153 行 YAML（以及 4 个模板文件），就能改变整套工作流的行为。

这就是 schema 系统的设计目标 —— 其定位是 "artifact DAG definition file"（`_digested/schema/01-schema-到底是什么.md`）。它不定义"怎么实现"（那是 AI agent 的事），只定义"什么的什么东西在什么条件下产生"。

---

## 2. Artifact DAG 的图算法

### 2.1 数据结构

`src/core/artifact-graph/types.ts` 用 Zod 定义：

```typescript
const ArtifactSchema = z.object({
  id: z.string(),
  generates: z.string(),          // 输出文件路径（支持 glob）
  description: z.string(),
  template: z.string(),           // 模板文件相对路径
  instruction: z.string().optional(),
  requires: z.array(z.string()).default([]),
});

const SchemaYamlSchema = z.object({
  name: z.string(),
  version: z.number().positive(),
  description: z.string().optional(),
  artifacts: z.array(ArtifactSchema).min(1),
  apply: z.object({
    requires: z.array(z.string()).min(1),
    tracks: z.string().nullable().optional(),
    instruction: z.string().optional(),
  }).optional(),
});
```

### 2.2 图构建

`ArtifactGraph.fromSchema()` (`src/core/artifact-graph/graph.ts`)：

1. 从解析后的 SchemaYaml 创建 `Map<id, Artifact>`
2. 验证所有 `requires` 引用指向存在的 artifact ID
3. DFS 检测循环依赖（`schema.ts`）

### 2.3 拓扑排序 —— Kahn's Algorithm

`graph.ts:72-113`：

```
1. 计算每个节点的 in-degree = requires 数组长度
2. 所有 in-degree = 0 的节点进入 ready 队列
3. 排序 ready 队列（确保确定性输出）
4. 弹出第一个节点，加入 buildOrder
5. 遍历该节点的所有后继（requires 中包含该节点的 artifact）
   → 后继 in-degree 减 1
   → 如果变为 0，加入 ready 队列
6. 重复直到 ready 队列为空
```

对于 spec-driven DAG：
```
proposal     in-degree=0  →  第一轮
specs        in-degree=1  →  等 proposal 完成
design       in-degree=1  →  等 proposal 完成
tasks        in-degree=2  →  等 specs 和 design 完成

buildOrder: [proposal, design, specs, tasks]
             (design 和 specs 的先后是确定性排序，和依赖顺序无关)
```

### 2.4 Ready/Blocked 检测

```typescript
// graph.ts:118-134
getNextArtifacts(completed: CompletedSet): string[] {
  // 所有不在 completed 中、且所有 requires 都在 completed 中的 artifact
}

// graph.ts:151-166
getBlocked(completed: CompletedSet): Record<string, string[]> {
  // 返回 { artifactId: [unmetDep1, unmetDep2] }
  // 只包含未完成且有未满足依赖的 artifact
}
```

---

## 3. Completion Detection 的精确机制

`detectCompleted()`（`src/core/artifact-graph/state.ts`）：

```typescript
export function detectCompleted(graph: ArtifactGraph, changeDir: string): CompletedSet {
  const completed = new Set<string>();
  for (const artifact of graph.getAllArtifacts()) {
    if (artifactOutputExists(changeDir, artifact.generates)) {
      completed.add(artifact.id);
    }
  }
  return completed;
}
```

`artifactOutputExists()`（`src/core/artifact-graph/outputs.ts`）本身只是委托 `resolveArtifactOutputs()`：

```typescript
export function artifactOutputExists(changeDir: string, generates: string): boolean {
  return resolveArtifactOutputs(changeDir, generates).length > 0;
}
```

`resolveArtifactOutputs()` 的关键语义：

- 非 glob 输出：拼出 `changeDir + generates`，要求目标存在且 `statSync(...).isFile()` 为真；目录不会让 artifact 变成 done。
- glob 输出：把 pattern 转为 POSIX 路径后交给 `fast-glob`，以 `cwd: changeDir`、`onlyFiles: true` 匹配现有文件；匹配结果 canonicalize 后去重排序。
- `artifactOutputExists()` 只关心是否有至少一个 resolved output。

**这意味着**：
- `proposal` done = `proposal.md` 文件存在
- `specs` done = `specs/` 下至少有一个 `.md` 文件
- `design` done = `design.md` 文件存在
- `tasks` done = `tasks.md` 文件存在

没有内容检验 —— 空文件也算"done"。内容质量由 validation 阶段（archive 时）保证。

---

## 4. 四层注入的精确代码路径

### 4.1 loadChangeContext (`src/core/artifact-graph/instruction-loader.ts`)

```
1. 计算 changeDir
2. 读 .openspec.yaml → ChangeMetadata（schema, created, goal, etc.）
3. resolveSchemaForChange()：
   优先级：显式参数 > .openspec.yaml > config.yaml > 'spec-driven'
4. resolveSchema()：
   优先级：project/ > user/ > package/
5. ArtifactGraph.fromSchema(schema) → 构建 DAG
6. detectCompleted(graph, changeDir) → 扫描文件系统
7. 返回 ChangeContext { graph, completed, schemaName, changeDir, ... }
```

### 4.2 generateInstructions (`src/core/artifact-graph/instruction-loader.ts`)

```
1. graph.getArtifact(artifactId)
2. loadTemplate(schemaName, artifact.template) → 读模板文件
3. getDependencyInfo() → 依赖项状态列表
4. getUnlockedArtifacts() → 完成后解锁哪些
5. readProjectConfig() → 读 config.yaml（失败则跳过）
6. validateConfigRules() → 检查 config 的 rules key 是否有效
7. 组装 ArtifactInstructions：
     context = config.context
     rules = config.rules[artifactId]
     instruction = artifact.instruction
     template = 模板文件内容
```

### 4.3 printInstructionsText (`src/commands/workflow/instructions.ts`)

将 `ArtifactInstructions` 格式化为人类可读（和 agent 可解析）的 XML-tagged 文本。

---

## 5. 三级解析优先级

### 5.1 Schema 目录解析（哪里找 schema 文件）

`src/core/artifact-graph/resolver.ts`：

```
1. <projectRoot>/openspec/schemas/<name>/schema.yaml   ← 项目本地
2. $XDG_DATA_HOME/openspec/schemas/<name>/schema.yaml  ← 用户全局覆盖
3. <package>/schemas/<name>/schema.yaml                 ← 包内置
```

**先找到的先用**。project 覆盖 user 覆盖 package。

### 5.2 Change 的 Schema 名称解析（用哪个 schema）

`src/utils/change-metadata.ts`：

```
1. 显式 --schema <name> CLI 参数
2. .openspec.yaml 中的 schema 字段
3. openspec/config.yaml 中的 schema 字段
4. 硬编码 'spec-driven'
```

### 5.3 两级解析的区别

- **"用哪个 schema"**：先确定 schema 名，然后去三个位置找同名 schema 目录
- **"从哪里加载"**：一个 schema 名可能存在于三个位置，按优先级选

这意味着用户可以：
1. 在项目级 fork 一个 schema：`openspec schema fork spec-driven my-workflow`
2. 在用户级全局覆盖：在 `~/.local/share/openspec/schemas/spec-driven/` 放自己的版本
3. 或者在 config.yaml 里切换项目默认 schema

---

## 6. config.yaml 与 schema 的交互

`openspec/config.yaml` 是 schema 的"项目级配置补丁"：

```yaml
schema: spec-driven         # 选择用哪个 schema

context: |                 # 注入到所有 artifact 指令中
  Tech stack: TypeScript, React
  We use conventional commits.

rules:                     # 按 artifact ID 注入特定约束
  proposal:
    - Keep proposals under 500 words
    - Always include a "Non-goals" section
  tasks:
    - Each task should be completable in under 2 hours
```

**关键交互**：

1. `config.schema` 决定了加载哪个 schema 的 artifact DAG
2. `config.context` 注入到**所有** artifact 指令中（50KB 上限，见 `src/core/project-config.ts`）
3. CLI 会检查 `config.rules` 的 key 是否对应 schema 中真实存在的 artifact ID（未知 ID 产生 warning，每个 session 只警告一次，见 `validateConfigRules()` / `generateInstructions()` in `src/core/artifact-graph/instruction-loader.ts`）
4. config 读取失败不会阻止指令生成 —— resilient 设计

---

## 7. 超越 spec-driven：Schema 的领域无关性

spec-driven 只是内置的默认 schema。同一套基础设施可以驱动完全不同领域的工作流。

`_digested/schema/07-超越-spec-driven-的应用场景.md` 展示了四种可能：

1. **文章写作 pipeline**：outline → draft → review → publish
2. **故事/剧本创作**：characters → plot → scenes → script
3. **Agent/Skill 开发**：requirements → tool-design → implementation → testing
4. **TDD 驱动开发**：test-spec → red-tests → implementation → green-report

每种只需要：
- 写一个新的 `schema.yaml`（定义 artifact DAG）
- 写对应的 `templates/*.md`（定义输出骨架）
- `config.yaml` 中 `schema: <新名字>`

**TypeScript 代码零改动。**

这就是 OpenSpec 的 meta 本质：它不是一个 speccing 工具，而是一个 **workflow runtime**。spec-driven 恰好是第一个（也是默认的）built-in workflow。

---

## 8. 核心数据结构总览

### ArtifactInstructions（agent 创建 artifact 的完整指令包）

```typescript
interface ArtifactInstructions {
  changeName: string;
  artifactId: string;
  schemaName: string;
  changeDir: string;                    // change 目录绝对路径
  planningHome?: PlanningHomeSummary;
  initiative?: InitiativeLink;
  outputPath: string;                   // 如 "proposal.md"
  resolvedOutputPath: string;           // 如 "/project/openspec/changes/foo/proposal.md"
  existingOutputPaths: string[];        // 已存在的输出文件
  description: string;                  // artifact 描述
  instruction: string | undefined;      // schema 的指导（来自 schema.yaml）
  context: string | undefined;          // config 背景（来自 config.yaml）
  rules: string[] | undefined;          // config 约束（来自 config.yaml）
  template: string;                     // 模板文件内容
  dependencies: DependencyInfo[];       // 需先读的完成文件
  unlocks: string[];                    // 完成后解锁的 artifact
}
```

### ChangeStatus（agent 了解 DAG 状态的快照）

```typescript
interface ChangeStatus {
  changeName: string;
  schemaName: string;
  planningHome?: PlanningHomeSummary;
  initiative?: InitiativeLink;
  changeRoot: string;
  artifactPaths: Record<string, ArtifactPathSummary>;
  affectedAreas?: AffectedAreasSummary;
  nextSteps: string[];                  // 纯文本建议
  actionContext: ActionContext;         // 机器可读约束
  isComplete: boolean;                  // 所有 artifact done?
  applyRequires: string[];              // 哪些 artifact 全部 done 才能 apply
  artifacts: ArtifactStatus[];          // 每个的状态
}
```

### DeltaPlan（delta spec 的解析结果）

```typescript
interface DeltaPlan {
  added: RequirementBlock[];            // { headerLine, name, raw }
  modified: RequirementBlock[];
  removed: string[];                    // 只有 requirement 名
  renamed: Array<{ from: string; to: string }>;
  sectionPresence: {                    // 哪些 section 在文件中出现
    added: boolean;
    modified: boolean;
    removed: boolean;
    renamed: boolean;
  };
}
```

### ChangeContext（工作流引擎的内部上下文）

```typescript
interface ChangeContext {
  graph: ArtifactGraph;                 // DAG
  completed: Set<string>;              // 已完成的 artifact ID 集合
  schemaName: string;
  changeName: string;
  changeDir: string;
  projectRoot: string;
  planningHome?: PlanningHome;         // repo 还是 workspace
  metadata?: ChangeMetadata;            // .openspec.yaml 内容
  initiative?: InitiativeLink;
}
```

### ArtifactGraph（对外 API）

```typescript
class ArtifactGraph {
  static fromSchema(schema: SchemaYaml): ArtifactGraph;
  getArtifact(id: string): Artifact | undefined;
  getAllArtifacts(): Artifact[];
  getBuildOrder(): string[];              // Kahn 拓扑排序
  getNextArtifacts(completed: Set): string[];  // 哪些 ready
  isComplete(completed: Set): boolean;
  getBlocked(completed: Set): Record<string, string[]>;  // 谁被什么卡住
}
```

---

## 9. 关键源文件速查

| 组件 | 文件 | 核心函数/类 |
|------|------|------------|
| Schema 定义 | `schemas/spec-driven/schema.yaml` | 全部 |
| 模板文件 | `schemas/spec-driven/templates/*.md` | - |
| 图算法 | `src/core/artifact-graph/graph.ts` | `ArtifactGraph`, `getBuildOrder()` (Kahn) |
| Completion 检测 | `src/core/artifact-graph/state.ts` | `detectCompleted()` |
| Glob 解析 | `src/core/artifact-graph/outputs.ts` | `artifactOutputExists()`, `resolveArtifactOutputs()` |
| Schema 解析 | `src/core/artifact-graph/schema.ts` | `parseSchema()`, cycle detection (DFS) |
| Schema 查找 | `src/core/artifact-graph/resolver.ts` | `getSchemaDir()`, `resolveSchema()`, `listSchemas()` |
| 指令生成 | `src/core/artifact-graph/instruction-loader.ts` | `loadChangeContext()`, `generateInstructions()`, `formatChangeStatus()` |
| 指令格式化 | `src/commands/workflow/instructions.ts` | `printInstructionsText()`, `applyInstructionsCommand()` |
| Delta 解析 | `src/core/parsers/requirement-blocks.ts` | `parseDeltaSpec()`, `extractRequirementsSection()` |
| Delta 合并 | `src/core/specs-apply.ts` | `buildUpdatedSpec()`, `findSpecUpdates()`, `writeUpdatedSpec()` |
| 归档执行 | `src/core/archive.ts` | `ArchiveCommand.execute()` |
| 项目配置 | `src/core/project-config.ts` | `readProjectConfig()`, `validateConfigRules()` |
| Skill 模板 | `src/core/templates/workflows/*.ts` | 每个 workflow 的 skill/command 模板 |
| Profile 定义 | `src/core/profiles.ts` | `CORE_WORKFLOWS`, `getProfileWorkflows()` |
| Change 元数据 | `src/utils/change-metadata.ts` | `readChangeMetadata()`, `writeChangeMetadata()`, `resolveSchemaForChange()` |
