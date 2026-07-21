# Workflow · onboard

## 源文件

`src/core/templates/workflows/onboard.ts` → `getOnboardSkillTemplate()` + `getOpsxOnboardCommandTemplate()`

## 一句话

onboard 是**引导式端到端体验**，不是普通业务命令。它同时包含教学叙述和实际 workflow 操作，目标是带用户走完一次完整的 explore→propose→apply→archive 循环，并在过程中解释每个概念。维护它时应当把它当作 prompt 和产品 onboarding 文案的组合体。

## 结构：六阶段教学

template 把整个体验拆成六个 Phase：

| Phase | 名称 | 做什么 |
|---|---|---|
| Preflight | CLI 检查 | `openspec --version`，未安装则停止 |
| Phase 1 | Welcome | 展示路线图 |
| Phase 2 | Task Selection | 扫描代码找 TODO/FIXME/缺少测试/类型问题/debug 残留 |
| Phase 3 | Explore + Propose | 探索问题 → 创建 change → 生成 artifacts |
| Phase 4 | Apply | 逐 task 实施 |
| Phase 5 | Verify + Archive | 验证 → sync → archive |
| Phase 6 | Wrap-up | 总结 + 下一步建议 |

## CLI 命令调用序列

```text
Preflight:
  openspec --version

Phase 2:
  rg "TODO|FIXME|HACK|XXX" src/
  [扫描代码结构]

Phase 3:
  openspec new change "<name>"
  openspec status --change "<name>" --json
  openspec instructions <artifact> --change "<name>" --json
  [循环直到 apply-ready]

Phase 4:
  openspec instructions apply --change "<name>" --json
  [逐 task 实施 + 更新 checkbox]

Phase 5:
  openspec status --change "<name>" --json
  openspec instructions apply --change "<name>" --json
  [verify 三维度检查]
  [sync delta specs]
  [archive: mv 到 archive/]
```

## 和其他 workflow 的关系

onboard 不是一个新的执行逻辑——它是对其他 workflow 的**编排 + 教学包装**：

```text
onboard
  ├── Phase 2: mini-explore（代码扫描）
  ├── Phase 3: propose（创建 change + artifacts）
  ├── Phase 4: apply（实施 tasks）
  └── Phase 5: verify + archive（验证 + 收尾）
```

它调用的是同一套 `openspec status`、`openspec instructions`、`openspec new change` 命令，区别在于每一步都附带教学叙述（"This is a proposal. It answers why and what..."）。

## Task Selection 策略

Phase 2 的代码扫描是自动化的——agent 搜索五种信号：

| 信号 | 搜索方式 | 适合 onboard 的程度 |
|---|---|---|
| TODO/FIXME 注释 | `rg "TODO\|FIXME\|HACK\|XXX"` | 高——通常是明确的小任务 |
| 缺少错误处理 | 找 `catch` 块吃错误、无 try-catch 的危险操作 | 中 |
| 函数缺少测试 | 对比 `src/` 和 `test/` | 中 |
| TypeScript `any` 类型 | `rg ": any\|as any"` | 低——类型修复可能牵涉广 |
| debug 残留 | `rg "console\.log\|debugger"` | 高——简单删除 |

agent 被要求选一个**小且明确**的任务（~15-20 分钟可完成），而不是大重构。

## Guardrails

| Guardrail | 含义 |
|---|---|
| CLI not installed → stop immediately | 不浪费时间 |
| Pick a SMALL task | ~15-20 分钟 |
| Do real work in their codebase | 不模拟 |
| Explain each step as you go | 教学优先 |
| If user gets stuck, help them through | 引导不是测试 |

## 源码锚点

| 内容 | 行号范围（onboard.ts） |
|---|---|
| SkillTemplate 定义 | L10-L18 |
| getOnboardInstructions() | L21+ |
| Preflight | L28-L42 |
| Phase 1: Welcome | L46-L66 |
| Phase 2: Task Selection | L70-L80+ |
| Phase 3-6 | 后续行 |
