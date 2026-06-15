---
name: [命令名，如 /agent:do-x]
description: [一句话用途]
arguments: [$ARGUMENTS 或参数说明]
---

# [命令名]

## 用户意图

[这条命令解决用户什么目标——一句话]

## 前置条件

- [依赖的前置 artifact 或环境条件]
- [需要哪些 skill 已完成]

## 工作流

1. **[步骤名]**：调用 `skills/[skill-name].md`，传入 `[参数]`，产出 `[预期产出]`
2. **[步骤名]**：调用 `skills/[skill-name].md`，传入 `[参数]`，产出 `[预期产出]`
…

## 涉及的 skill

- `skills/[skill-1].md`
- `skills/[skill-2].md`

## 成功/失败输出

- **成功**：[用户看到什么、下一步可以做什么]
- **失败**：[用户看到什么、常见原因、怎么排查]
