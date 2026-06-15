# 接入与发布清单

<!-- 用 - [x] 标记完成；OpenSpec CLI 解析 - [ ] / - [x] 为进度 -->

## Persona 就绪
- [ ] persona.md 填写完成、各项非占位符

## Skills 接入 harness
- [ ] `skills/[skill-1].md` → 渲染/拷贝到目标 harness 约定目录
- [ ] `skills/[skill-2].md` → 渲染/拷贝到目标 harness 约定目录

## Commands 注册
- [ ] `commands/[command-1].md` → 在目标 harness 中注册、用户可调用
- [ ] `commands/[command-2].md` → 在目标 harness 中注册、用户可调用

## Tools 可执行
- [ ] `tools/[tool-1]` → 入口可执行、dry-run 通过
- [ ] `tools/[tool-2]` → 入口可执行、dry-run 通过

## Evals 通过
- [ ] `evals/[skill-1].md` → 正常路径用例通过
- [ ] `evals/[skill-1].md` → 边界情况用例通过
- [ ] `evals/[skill-1].md` → 拒绝场景用例通过
- [ ] `evals/[skill-2].md` → 全部用例通过

## CLI 就绪
- [ ] `[my-agent] --help` 正常输出
- [ ] `[my-agent] status --json` 返回合法 JSON

## 端到端验证
- [ ] 选一个真实用户意图，从输入到输出全链路走通（persona → skill → command → tool → eval → cli）
