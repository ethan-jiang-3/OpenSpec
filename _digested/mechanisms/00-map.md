# Mechanisms 地图

## 为什么收拢成一个目录

这些内容原本可以按源码目录拆成 workspace、tool delivery、spec model、workflow templates、CLI infra 五个专题。但对读者来说，刚进入 OpenSpec 时同时看到五个新目录，会误以为它们和 `system/`、`schema/`、`spec_cli/`、`internal-spec-driven/` 是同等主线。

实际上它们更像主干之外的五个工程问题：

| 读者问题 | 对应机制 |
|----------|----------|
| 多仓库场景下，OpenSpec 如何让 agent 看到上下文，但不乱改归属？ | store coordination |
| OpenSpec 怎么把同一套工作流放进 Claude、Codex、Cursor、OpenCode 等工具？ | tool delivery |
| Markdown spec/change 凭什么能被机器稳定理解？ | spec model |
| `/opsx:new`、`/opsx:continue`、`/opsx:sync` 这些不是核心四命令的入口有什么意义？ | workflow templates |
| completion、feedback、telemetry、prompts 这些周边设施为什么也影响系统质量？ | CLI infra |

所以这里按问题组织，而不是按源码目录组织。源码路径仍然会出现，但它们是证据，不是阅读入口。

## 推荐进入顺序

如果你已经读过 `../system/`：

1. 想理解多仓库 store 模型，读 `01-store-模型与仓库协同.md`。
2. 想理解 OpenSpec 和不同 AI Coding 工具的关系，读 `02-tool-delivery.md`。
3. 想理解 specs/changes 为什么不是“随便写的 Markdown”，读 `03-spec-model.md`。
4. 想理解 expanded workflows 和 agent 行为边界，读 `04-workflow-templates.md`。
5. 想做 CLI 质量、体验、发布支撑，读 `05-cli-infra.md`。

## 一张压缩图

```text
OpenSpec 主干
  specs/changes
  schema artifact DAG
  status/instructions runtime API
  spec-driven core workflows

补充机制
  workspace coordination     多 repo/folder 的本机协调视图
  tool delivery              workflow 语义投递到不同 agent 外壳
  spec model                 Markdown → parser → schema → validator
  workflow templates          agent 操作手册源码
  CLI infra                  completion/feedback/telemetry/prompts/utils
```

这几个机制的共同点是：它们不改变 OpenSpec 的主轴，但决定这条主轴能不能在真实工程环境里稳定运行、被不同 agent 消费、被人类诊断和维护。

## 读这些机制时要守住的边界

- workspace 是本机视图，不是把多个 repo 合成一个新的 source of truth。
- tool delivery 投递的是 workflow 入口，不是业务事实。
- spec model 解释 Markdown，不决定 workflow 顺序。
- workflow templates 约束 agent 行为，不等于 CLI 硬编码执行。
- CLI infra 支撑全局体验，但不定义 artifact DAG。

这些边界很重要，因为 OpenSpec 的工程思想不是“把所有东西塞进一个自动化黑盒”，而是把状态、解释、推理、投递、体验分层，让每层可检查、可替换、可维护。
