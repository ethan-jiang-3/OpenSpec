# Workflow · onboard

## 源文件

`src/core/templates/workflows/onboard.ts` → `getOnboardSkillTemplate()` + `getOpsxOnboardCommandTemplate()`（共享 `getOnboardInstructions()`）

> **调用方式**：技能 `openspec-onboard`——Claude Code 等工具里 `/openspec-onboard`，Codex 用 `$openspec-onboard`。1.x 写作 `/opsx:onboard`；v2.0.0 起命令文件已移除，`/opsx:` 只用于历史解释。
> **agent 看到的名字**：`openspec-onboard`（skill）/ `OPSX: Onboard`（command）
> **独立 CLI 命令**：无——onboard 是纯教学实操向导，在真实代码库上带着用户走完一个 ~15–20 分钟的完整 OpenSpec 变更周期，每一步都配教学旁白。
> **profile**：custom（需在 `customWorkflows` 中显式启用，不在默认 core 里）

## 一句话

onboard 是**引导式端到端实操教学模板**，不是普通业务命令。它遵循 **EXPLAIN → DO → SHOW → PAUSE** 教学节律，在用户真实代码库里挑选一个小任务，完整走完「探索 → 建 change → 写四件套产物 → 直接实施任务 → `openspec archive --yes` 归档 → 复盘」全周期。

## 结构：Preflight + 11 个阶段（Phases 1–11）

`getOnboardInstructions()`（`onboard.ts:37-569`）在注入 `STORE_SELECTION_GUIDANCE` 与 `PROJECT_ROOT_GUARD` 后，按 **Preflight + 11 个 Phase** 推进：

| 阶段 | 名称 | 核心动作与停顿点 |
|---|---|---|
| **Preflight** | CLI 检查 | 运行 `openspec --version`，未安装则立即停止 |
| **Phase 1** | Welcome | 展示 6 步路线图与预计耗时（~15–20 分钟） |
| **Phase 2** | Task Selection | 扫描真实代码库 6 类改进信号 + 最近 10 条 `git log --oneline`，给出 3–4 个小任务建议，含软性 Scope Guardrail |
| **Phase 3** | Explore Demo | 花 1–2 分钟读相关文件、按需画 ASCII 图，演示探索姿态 → **PAUSE** 等用户确认 |
| **Phase 4** | Create the Change | 运行 `openspec new change "<derived-name>"`，展示 `status --json` 的 `changeRoot` 目录结构 |
| **Phase 5** | Proposal | 先在对话中起草 `# Proposal`（含 `<capability-path>`）→ **PAUSE** 等批准 → 调 `openspec instructions proposal --change "<name>" --json` 写到 `resolvedOutputPath` |
| **Phase 6** | Specs | 调 `openspec instructions specs --change "<name>" --json` 解析具体路径，起草 `# Spec Delta`（WHEN/THEN/AND）并落盘 |
| **Phase 7** | Design | 起草精简的 `# Design`，调 `openspec instructions design --change "<name>" --json` 写到 `resolvedOutputPath` |
| **Phase 8** | Tasks | 生成 `# Tasks`（每项自带 `— verify:`，末组为 `## 2. Integration Verification`）→ **PAUSE 1** 确认拆解 → 调 `openspec instructions tasks --change "<name>" --json` 落盘 → 询问 `"Tasks are saved. Ready to implement?"` **PAUSE 2** |
| **Phase 9** | Apply (Implementation) | **不调用 `openspec instructions apply`**，直接逐条播报任务、修改业务代码、自然引用 specs/design，并在 `tasks.md` 勾选 `- [ ]` → `- [x]` |
| **Phase 10** | Archive | 直接调用确定性 CLI **`openspec archive "<name>" --yes`** 完成 spec 合并与归档移动（解释工具调用无法回答交互提示，故传 `--yes`） |
| **Phase 11** | Recap & Next Steps | 回顾 8 个里程碑，**动态列出当前会话实际可用的 OpenSpec 工作流**（不再硬编码旧命令表），邀请开启下一个真实变更 |

## CLI 命令调用序列

```text
Preflight:
  openspec list --json                                    # PROJECT_ROOT_GUARD 写前查根
  openspec --version

Phase 2 (Task Selection):
  git log --oneline -10

Phase 4 (Create the Change):
  openspec new change "<derived-name>"
  openspec status --change "<name>" --json                # 获取 changeRoot / planningHome

Phases 5–8 (Proposal / Specs / Design / Tasks):
  openspec instructions proposal --change "<name>" --json
  openspec instructions specs    --change "<name>" --json
  openspec instructions design   --change "<name>" --json
  openspec instructions tasks    --change "<name>" --json

Phase 9 (Apply):
  [直接按 tasks.md 实施代码并勾选 - [x]，不调 openspec instructions apply]

Phase 10 (Archive):
  openspec archive "<name>" --yes                         # 直接调 CLI 归档（不走手动 mv，也不调 verify）
```

> **与其他工作流的分工差异**：普通日常开发中，实施走 `openspec-apply-change`（消费 `openspec instructions apply --json`），归档可走 `openspec-archive-change`（agent 驱动 sync + `mv`）或 CLI `openspec archive`。而在 `onboard` 教学流程里，Phase 4–8 刚刚亲手写完四份产物，因此 Phase 9 直接逐项改代码勾选，Phase 10 直接跑 `openspec archive "<name>" --yes` 一步完成验证、主 spec 合并与归档。

## Phase 2：6 类代码库扫描信号与范围软护栏

agent 在用户代码库中搜索 **6 类**小而明确的改进机会（`onboard.ts:92-100`）：

| # | 信号 | 搜索目标 |
|---|---|---|
| 1 | **TODO/FIXME 注释** | 代码中的 `TODO`、`FIXME`、`HACK`、`XXX` |
| 2 | **缺少错误处理** | 吞异常的 `catch` 块、无 `try-catch` 的高风险操作 |
| 3 | **缺少测试的函数** | 交叉比对 `src/` 与测试目录 |
| 4 | **类型问题** | TypeScript 文件中的 `: any`、`as any` |
| 5 | **调试残留** | 非调试代码里的 `console.log`、`console.debug`、`debugger` |
| 6 | **缺少输入校验** | 未做校验的用户输入处理函数（Missing validation） |

若用户挑选或提出的任务过大（多日特性开发），**Scope Guardrail**（`onboard.ts:142-160`）会温和提供三选一：**切小一点（Slice it smaller）** / **换一个小任务** / **坚持照做（Do it anyway）**——尊重用户最终决定。

## Phase 8：任务清单的两段式确认（#1940）

Phase 8 生成 `# Tasks` 时遵守两条教学与质量契约（`onboard.ts:398-432`）：
1. 每条任务内嵌验证方式 `- [ ] 1.1 [Specific task] — verify: [test, command, observable behavior, or delivered artifact]`，每个分组自带本组测试与文档，末尾组 `## 2. Integration Verification` 仅做集成验证。
2. **两次独立 PAUSE**：先展示草稿问 `"Does this task breakdown look right?"`（**PAUSE 1**），批准并写入 `resolvedOutputPath` 后再问 `"Tasks are saved. Ready to implement?"`（**PAUSE 2**），绝不保存后直接写代码。

## 优雅退出与动态技能速查（Graceful Exit）

`onboard.ts:514-556` 已移除 1.x 时代硬编码的 `/opsx:*` 命令速查表常量，改为要求 agent **动态列出当前会话中实际已安装且可调用的 OpenSpec 工作流**（省略未安装的 custom 技能）：
- **中途暂停退出（`L529-L542`）**：告知进度已保存在 `status --json` 报告的 `changeRoot` 下，提示后续可用 `openspec status --change "<name>" --json` 查看状态，并从当前可用工作流中给出下一步建议。
- **只想看技能列表跳过教程（`L544-L556`）**：输出当前会话可用工作流的一句话速查表并礼貌退出。

## Guardrails（7 条，`onboard.ts:560-568`）

| Guardrail | 含义 |
|---|---|
| Follow the **EXPLAIN → DO → SHOW → PAUSE** pattern | 在关键节点（explore 后、proposal 草稿后、tasks 前后）严格执行四步教学节拍 |
| Keep narration light during implementation | 边做边讲但不长篇说教 |
| Don't skip phases even if the change is small | 目标是完整演示工作流，不跳步 |
| Pause for acknowledgment at marked points, don't over-pause | 只在标记处停顿 |
| Handle exits gracefully | 用户想停或想跳过时绝不施压 |
| Use real codebase tasks | 用真实代码改动教学，不用假示例 |
| Adjust scope gently | 温和引导小范围任务，但允许用户坚持己见 |

## 源码锚点

| 内容 | 行号范围（`onboard.ts`，共 579 行） |
|---|---|
| 提示常量 `EXPLORE_MODE_NOTE` / `NEXT_STEP_INVITE` / `QUICK_REFERENCE_INVITE` | L16-L24 |
| `getOnboardSkillTemplate()` | L26-L35 |
| `getOnboardInstructions()`（skill 与 command 共用） | L37-L569 |
| Preflight（`openspec --version`） | L46-L60 |
| Phase 1: Welcome | L64-L84 |
| Phase 2: Task Selection（6 类扫描信号 + Scope Guardrail） | L88-L160 |
| Phase 3: Explore Demo | L163-L190 |
| Phase 4: Create the Change（`openspec new change`） | L194-L224 |
| Phase 5: Proposal（起草 → PAUSE → `instructions proposal` 落盘） | L228-L292 |
| Phase 6: Specs（`instructions specs` + `# Spec Delta`） | L296-L340 |
| Phase 7: Design（`instructions design` + `# Design`） | L344-L387 |
| Phase 8: Tasks（双 PAUSE + `instructions tasks`） | L390-L432 |
| Phase 9: Apply（直接改代码并勾 `tasks.md`） | L435-L465 |
| Phase 10: Archive（`openspec archive "<name>" --yes`） | L469-L490 |
| Phase 11: Recap & Next Steps（动态列出可用技能） | L494-L523 |
| Graceful Exit Handling & Guardrails | L527-L568 |
| `getOpsxOnboardCommandTemplate()`（1.x 历史命令模板，2.0 起不再生成） | L571-L579 |
