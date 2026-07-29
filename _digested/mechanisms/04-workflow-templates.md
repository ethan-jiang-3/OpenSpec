# Workflow Templates

## 模板是 agent 操作手册源码

OpenSpec CLI 负责保存和解释状态，但真正执行“读用户意图、调用命令、写 artifact、修改代码”的是宿主 coding agent。workflow templates 就是 agent 的操作手册源码。

这点很容易误解。`apply`、`sync`、`verify` 等模板不是 TypeScript 里的硬编码执行流程；它们由 init/update 投递到不同 agent 的指令文本。agent 读到这些指令后，调用 `openspec status --json`、`openspec instructions ... --json`、`openspec validate` 等 runtime API；然后由模型和工具执行实际写入。

所以 workflow templates 位于两层之间：

```text
OpenSpec CLI runtime API
  → status/instructions/validate/new change
workflow template
  → 告诉 agent 如何串这些 API
宿主 coding agent
  → 推理、写文件、跑测试、报告结果
```

## 当前 profile workflows

下面这些 workflow id 来自 `src/core/profiles.ts` 的 `ALL_WORKFLOWS`，会被 profile/delivery 机制选择并投递成 skill/command。

| workflow | 模板文件 | 角色 |
|----------|----------|------|
| `explore` | `explore.ts` | 探索和澄清 |
| `propose` | `propose.ts` | 一次性创建 change 并生成规划 artifact |
| `new` | `new-change.ts` | 只创建 change scaffold |
| `continue` | `continue-change.ts` | 创建下一个 ready artifact |
| `ff` | `ff-change.ts` | fast-forward 生成剩余 artifact |
| `apply` | `apply-change.ts` | 按 tasks 实施 |
| `sync` | `sync-specs.ts` | agent-driven 同步 delta specs 到主 specs |
| `verify` | `verify-change.ts` | 验证实现与 artifacts 一致 |
| `archive` | `archive-change.ts` | 收尾归档 |
| `bulk-archive` | `bulk-archive-change.ts` | 批量归档 |
| `onboard` | `onboard.ts` | 引导式端到端体验 |
| `update` | `update-change.ts` | 修订已有 planning artifacts，保持一致性 |

`profile` 只决定安装哪些 workflow；模板本身定义 agent 的动作顺序和 guardrails。

## planning 模板：动作而非阶段

`propose` 是默认 quick path：创建 change，并持续生成 artifact，直到 schema 的 apply requirements 满足。它适合用户已经有比较明确意图，想快速得到完整规划。

`new` 只创建 change scaffold，不生成 artifact 内容。它把“创建实例”和“生成内容”拆开，适合先占位、手动推进、显式选择 schema 或 initiative linkage。

`continue` 是 incremental path：每次只推进一个 ready artifact。它体现 artifact DAG 的增量工作流：先 `status --json` 找 ready artifact，再 `instructions <artifact> --json` 获取执行包。

`ff` 是 fast-forward path：批量生成剩余 artifact。它和 `propose` 相似，但语义更偏“已有 change，快速补齐剩余规划”。

| workflow | 创建 change | 生成 artifact | 粒度 |
|----------|-------------|---------------|------|
| `propose` | 会 | 会，直到可 apply | 快速完整 |
| `new` | 会 | 不会 | scaffold |
| `continue` | 不一定 | 一次一个 | 增量 |
| `ff` | 可用于已有 change | 多个 | 批量推进 |

这四个模板共同解释了 agent workflow “动作而非阶段”的体验：用户可以从不同粒度切入同一条 artifact DAG。Claude 的名称可为 `/opsx:*`；Codex v1.7.0 为 `$openspec-*` skills，不能把前者当通用入口。

## update：修订而非推进（v1.6.0 新增）

`update` 是 planning artifact 修订器，**绝不改代码**。它和规划类四个模板的职责不同——那些模板推进 build frontier（创建新 artifact），`update` 在已有 frontier 内修订已有文件。

关键约束：
- 只编辑 `existingOutputPaths` 中的已有文件，不创建新 artifact、不在 glob 下新增文件
- 每次修改前必须经用户确认
- 修订后双向检查所有已有 artifact 的一致性（改 proposal → check specs/design/tasks，反过来也成立）
- 如果修改改变了 change 的意图而非精炼细节，建议用 `/opsx:new` 重新开始

`update` 填补了两个重要场景的官方 workflow 空白：① Explore 中做了决策 → 需要更新 artifacts；② Apply 中发现 design 问题 → 需要回修 artifacts。详见 `../workflows/12-update.md`。

## implementation 与 closeout 模板

`apply` 模板消费 `openspec instructions apply` 的结果。它关注 apply gate 是否 blocked、tasks 是否存在、是否有 checkbox、未完成 tasks 列表、implementation 时是否需要更新 artifacts；v1.7.0 同时读取项目 `context` 与 `operations.apply.guidance`。artifact `rules.*` 只服务 artifact 生成，不会成为 Apply 的 operation 指令。具体 apply gate 源码机制见 `../internal-spec-driven/03-apply-实施执行.md`。

`sync` 是 agent-driven spec merge，不是 CLI archive。模板要求 agent 选择 change、用 `status` 获取 delta spec path、读取 delta spec 和主 spec、智能应用 ADDED/MODIFIED/REMOVED/RENAMED，并保留 change active。main spec root 按 store-aware root selection 解析；不要再把已废止的 `workspace-planning` gate 当作当前 guardrail。

`verify` 用来检查实现是否与 proposal/specs/design/tasks 一致。它不是 `validate` 的替代：`validate` 检查 OpenSpec 文档结构，`verify` 让 agent 审查代码实现、测试、任务完成度和 artifact coherence。

`archive` 模板是 agent 层的收尾操作手册。它先读取 `openspec instructions archive --json`（project `context` 与 `operations.archive.guidance`），检查是否需要 sync、是否完成 tasks、是否适合调用 CLI archive；sync 必须 inline 完成并对全部 capability 重新验证后才移动 change。v1.7.0 下，正确 early-sync 的完全一致 delta 会在 archive 中保持幂等 no-op，仍需阻断近似匹配或真实 drift。CLI archive 源码机制见 `../internal-spec-driven/04-archive-归档合并.md`。

`bulk-archive` 面向多个 completed changes。它的风险不在单个 merge 算法，而在选择和确认：哪些 changes 完成、哪些跳过、是否逐个验证、失败时如何报告 partial results。

## onboard 与 feedback 的特殊性

`onboard.ts` 不是普通业务命令，而是引导式端到端体验。它同时包含教学叙述和实际 workflow 操作，目标是带用户走完一次真实工作流，并解释 proposal/spec/design/tasks 的角色。维护它时要把它当 prompt 和产品 onboarding 文案的组合体。

`feedback.ts` 是特殊的 workflow template module，但它当前不在 `ALL_WORKFLOWS` / profile selection 里，不随 core/custom workflow profile 一起安装。它和 `src/commands/feedback.ts` 的 CLI 实现不同：template 指导 agent 收集、整理、匿名化反馈；CLI feedback command 用 GitHub CLI 或 manual URL 提交 issue。它更适合和 `../mechanisms/05-cli-infra.md` 一起理解。

## 工程洞察

- CLI 提供 deterministic runtime API，template 提供 agent 操作策略，两者分层让行为可解释但不完全硬编码。
- expanded workflows 不是新状态机，而是围绕同一套 status/instructions API 的不同操作粒度。
- template 是跨工具复用的 workflow 语义；tool delivery 再把它投递成不同 agent 的 skill/command 外壳。
- 修改 template 会改变 agent 行为，即使 TypeScript 源码没有变化，也应当视为产品行为变更。
- **v1.7.0 当前模板契约**：① propose/continue/ff 写完 artifact 后从磁盘重读依赖文件；② 同级 ready artifact 的推荐顺序由 schema 声明顺序决定（内置为 specs 后 design，二者仍可并行）；③ schema artifact `instruction` 是生成时的权威指令；④ `skip_specs: true` 会把 specs 设为显式 skipped，不再把无 spec-level 变化的 change 卡住。

## 源码锚点

| 机制 | 路径 |
|------|------|
| workflow 模板（含 v1.6.0 新增 `update-change.ts`） | `src/core/templates/workflows/` |
| skill/command template facade | `src/core/templates/skill-templates.ts` |
| template 类型 | `src/core/templates/types.ts` |
| template 到 skill/command content | `src/core/shared/skill-generation.ts` |
| workflow profile | `src/core/profiles.ts` |
| runtime API | `src/commands/workflow/` |

## 测试锚点

- `test/core/templates/`
- `test/core/shared/`
- `test/commands/artifact-workflow.test.ts`
