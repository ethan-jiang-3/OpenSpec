# 命令 ↔ Skill ↔ 模板文件 三对映射

OpenSpec 装到项目里后，每个 workflow 会落地成**两种产物**：

1. **Skill** —— 放在 `.{tool}/skills/openspec-*/SKILL.md`，agent 自动发现
2. **Command** —— 放在 `.{tool}/commands/opsx-*.md`（路径因工具而异），可以在 AI 聊天里用斜杠命令触发

映射关系的源码在 [src/core/shared/skill-generation.ts](../../src/core/shared/skill-generation.ts) 的 `getSkillTemplates` 和 `getCommandTemplates`。模板本体在 [src/core/templates/workflows/](../../src/core/templates/workflows/)。

## 完整映射表

| Workflow ID | 斜杠命令（Claude 风格） | Skill 目录名 | 模板文件 | Profile |
|-------------|------------------------|------------|---------|---------|
| `propose` | `/opsx:propose` | `openspec-propose` | [propose.ts](../../src/core/templates/workflows/propose.ts) | core |
| `explore` | `/opsx:explore` | `openspec-explore` | [explore.ts](../../src/core/templates/workflows/explore.ts) | core |
| `apply` | `/opsx:apply` | `openspec-apply-change` | [apply-change.ts](../../src/core/templates/workflows/apply-change.ts) | core |
| `archive` | `/opsx:archive` | `openspec-archive-change` | [archive-change.ts](../../src/core/templates/workflows/archive-change.ts) | core |
| `new` | `/opsx:new` | `openspec-new-change` | [new-change.ts](../../src/core/templates/workflows/new-change.ts) | expanded |
| `continue` | `/opsx:continue` | `openspec-continue-change` | [continue-change.ts](../../src/core/templates/workflows/continue-change.ts) | expanded |
| `ff` | `/opsx:ff` | `openspec-ff-change` | [ff-change.ts](../../src/core/templates/workflows/ff-change.ts) | expanded |
| `verify` | `/opsx:verify` | `openspec-verify-change` | [verify-change.ts](../../src/core/templates/workflows/verify-change.ts) | expanded |
| `sync` | `/opsx:sync` | `openspec-sync-specs` | [sync-specs.ts](../../src/core/templates/workflows/sync-specs.ts) | expanded |
| `bulk-archive` | `/opsx:bulk-archive` | `openspec-bulk-archive-change` | [bulk-archive-change.ts](../../src/core/templates/workflows/bulk-archive-change.ts) | expanded |
| `onboard` | `/opsx:onboard` | `openspec-onboard` | [onboard.ts](../../src/core/templates/workflows/onboard.ts) | expanded |

## 命名规律

- **Skill 目录**：统一前缀 `openspec-`，后缀是完整动作名（比如 `openspec-archive-change` 而不是 `openspec-archive`）。
- **斜杠命令**：前缀 `opsx:`（或 `opsx-`，看工具），后缀是**短 id**（`archive`、`bulk-archive`）。
- 两者都由同一个 `workflowId` 驱动，在源码里是字符串 id（见 [src/core/profiles.ts](../../src/core/profiles.ts) 的 `ALL_WORKFLOWS`）。

## 为什么有 skill 又有 command

| | Skill | Command |
|---|-------|---------|
| **触发方式** | agent 自动识别（比如 Claude Code 看到 skills/ 目录会加载） | 用户手动输入斜杠命令 |
| **存在意义** | 让 agent 在需要时主动发起 workflow | 让用户有显式入口 |
| **是否所有工具都有** | 是（所有 28 个工具都生成 skill） | **否**——`forgecode` 和 `trae` 没有 command adapter，只走 skill |

## Delivery 模式

在 `openspec config` 里可以配 `delivery`，有三种：

- `both`（默认）—— skill + command 都装
- `skills` —— 只装 skill
- `commands` —— 只装 command

## 用 `openspec config profile` 过滤 workflow

如果只想启用一部分 workflow：

```bash
openspec config profile    # 交互式打勾
# 然后
openspec update            # 刷新项目里的 skill/command 文件
```

内部实现：`getSkillTemplates(workflowFilter)` 和 `getCommandTemplates(workflowFilter)` 会根据 profile 过滤出要生成的模板（见 [src/core/shared/skill-generation.ts:71](../../src/core/shared/skill-generation.ts)）。
