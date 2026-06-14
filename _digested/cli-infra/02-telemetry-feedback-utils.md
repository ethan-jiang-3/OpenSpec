# Telemetry / Feedback / Utils

## telemetry

telemetry 在 `src/telemetry/`。它的设计边界：

- 只记录 command name、version、surface。
- 不记录 arguments、paths、content。
- `OPENSPEC_TELEMETRY=0`、`DO_NOT_TRACK=1`、`CI=true` 会禁用。
- PostHog 请求 1s timeout、无 retry、失败静默。
- anonymous id 是随机 UUID，保存在 telemetry config。

CLI 在 `preAction` 里显示首次 notice 并 track command，在 `postAction` shutdown。

## feedback

feedback 有两层：

- workflow template：指导 agent 收集反馈。
- CLI command：实际提交 GitHub issue 或输出 manual URL。

CLI 用 `execFileSync('gh', [...args])`，避免 shell injection。gh 不存在或未认证时，不报失败，而是输出可手动提交的内容。

## prompts / ui

`src/prompts/searchable-multi-select.ts` 和 `src/ui/` 属于交互体验层：

- tool selection。
- welcome screen。
- searchable selection。

它们不定义 OpenSpec 业务状态，但影响 init/workspace setup 等命令的人类路径。

## utils

`src/utils/` 是跨模块基础设施：

- file-system：路径规范化、写文件、权限等。
- item-discovery：发现 active changes/spec ids。
- shell-detection：completion shell auto-detect。
- task-progress：读取 checkbox progress。
- command-references：按工具转换 command 引用。
- change-utils/change-metadata：change 名称和 metadata 辅助。

这些 util 通常不是专题核心，但很多机制依赖它们。文档引用源码时要注意 util 里可能有实际行为，不只是“辅助函数”。

## JsonConverter

`JsonConverter` 把 spec/change Markdown 转成 JSON：

- 复用 `MarkdownParser` / `ChangeParser`。
- 添加 `metadata.sourcePath`。
- 不定义新模型。

它适合被归入 spec-model 的读模型链路，同时在 cli-infra 作为 converter 归档。
