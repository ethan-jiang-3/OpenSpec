# Workflow Templates 地图

## 一句话

workflow 模板是 agent 的操作手册源码。OpenSpec CLI 负责生成和暴露 runtime 数据，真正让 agent “知道怎么串起来”的，是 `src/core/templates/workflows/` 里的 skill/command instructions。

## 当前 workflow

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
| `feedback` | `feedback.ts` | 提交 OpenSpec 反馈 |

`profile` 只决定安装哪些 workflow；模板本身定义 agent 的动作顺序和 guardrails。

## 和 runtime API 的关系

模板通常会要求 agent 调用：

- `openspec list --json`
- `openspec new change`
- `openspec status --change ... --json`
- `openspec instructions <artifact> --json`
- `openspec instructions apply --json`
- `openspec validate`

模板不直接执行 TypeScript 函数。它们是交给宿主 agent/LLM 的文本约束。

## 测试锚点

- `test/core/templates/`
- `test/core/shared/`
- `test/commands/artifact-workflow.test.ts`
