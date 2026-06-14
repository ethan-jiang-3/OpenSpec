# Onboard 与 Feedback

## onboard

`onboard.ts` 是最长的 workflow 模板之一。它不是普通业务命令，而是引导式端到端体验。

它的目的：

- 帮新用户理解 OpenSpec。
- 带用户走完一次真实工作流。
- 在过程中解释 proposal/spec/design/tasks 的角色。
- 尽量使用真实 codebase context，而不是纯 demo。

所以 onboard 同时包含教学叙述和实际 workflow 操作。维护时要小心：它既是 prompt，又是产品 onboarding 文案。

## feedback skill

`feedback.ts` 定义 agent 如何帮助用户提交反馈。它和 `src/commands/feedback.ts` 的 CLI 实现不同：

- workflow template 指导 agent 收集反馈。
- CLI feedback command 用 GitHub CLI 或 manual URL 提交 issue。

## feedback CLI

`FeedbackCommand` 的边界：

- 检查 `gh` 是否存在。
- 检查 `gh auth status`。
- 用 `execFileSync` 调 `gh issue create`，避免 shell injection。
- 如果 gh 不可用，输出预填 GitHub issue URL 和格式化内容。

它不上传源码、不收集项目文件，只附加 version/platform/timestamp metadata。
