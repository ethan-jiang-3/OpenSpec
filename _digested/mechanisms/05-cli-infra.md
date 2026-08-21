# CLI Infra

## 为什么周边设施也值得消化

completion、telemetry、feedback、prompts、utils 看起来不是 OpenSpec 的核心 artifact graph，但它们决定真实用户和 agent 如何发现命令、诊断问题、提交反馈、选择工具、处理路径和读取 JSON。

CLI infra 的定位是 **周边但全局**：它不定义 `specs/`、`changes/`、schema DAG，也不决定 archive merge，但它影响所有命令的可用性和维护成本。

```text
core mechanisms
  artifact graph / runtime API / archive / workspace

CLI infra
  completion / telemetry / feedback / prompts / utils / converter
```

如果核心机制是 OpenSpec 的协议层，那么 CLI infra 是协议能否被顺畅使用和维护的支撑层。

## shell completion：独立的命令模型

completion 不是 commander runtime 自动导出的副产品。它有自己的命令 registry：

```text
COMMAND_REGISTRY
  → shell generator
  → completion script
  → installer writes shell-specific location/config
```

另有 hidden command：

```text
openspec completion __complete <type>
```

给 shell script 动态获取 change/spec/schema 等候选。

`src/core/completions/command-registry.ts` 手写维护 command name、description、positional 参数、flags、subcommands、flag value candidates。风险也在这里：CLI 新增/改名时，如果 registry 不同步，completion 会漂移。

`CompletionProvider` 提供动态候选：active change ids、spec ids、schema names。它有 2 秒 TTL cache，避免用户按 Tab 时频繁扫文件系统。

生成器消费同一个 `COMMAND_REGISTRY`，但脚本语法分成 bash、zsh、fish、PowerShell。installers 负责写 completion script、更新 shell profile、创建 backup、返回 warnings/instructions。这一层最容易碰到用户环境差异。

### v1.10.0：安装期脚本改为首次运行 tip

发布包不再包含 npm `postinstall`；registry install 因而没有 install lifecycle script，也不再触发相关 allow-scripts 警告。源码/git/directory install 仍可能因 package 的 `prepare` 构建，不能把“无 postinstall”误写成“所有安装方式绝不运行脚本”。

completion 提示移到 root commander 的 `postAction`：命令自身输出之后，第一次可读的交互运行只向 **stderr** 打印一次 `openspec completion install`，不自动安装。以下情况抑制或 defer：

- `CI` 或 `OPENSPEC_NO_COMPLETIONS=1`：不显示；
- completion 已安装、shell 未检测到/不支持：retire，一次性消费；
- `--json`、completion 命令自身、stderr 非 TTY：defer，不设置 seen，留给以后可读运行。

“运行”在这里准确指**到达 root `postAction` 的 action**。action 正常 return，或失败时只设置 `process.exitCode`，commander 仍会运行 hook；因此 `change validate` 这类非零退出也可能显示/消费 tip。若 action 的 catch 直接调用 `process.exit(1)`，进程会在 hook 前终止，这次失败既不显示也不消费 tip，下一次真正到达 `postAction` 的 eligible run 才处理。completion tip 与 telemetry shutdown 都受这个边界约束。

seen flag 写 global config 时使用 raw read/merge + 临时文件 rename，不调用会合入默认值的 `getGlobalConfig()`，避免顺带 stamp `profile`/`delivery` 并破坏一次性 profile migration。

## telemetry：低信息量、低阻塞

telemetry 在 `src/telemetry/`。它的边界：

- 只记录 command name、version、surface。
- 不记录 arguments、paths、content。
- `OPENSPEC_TELEMETRY=0`、`DO_NOT_TRACK=1`、`CI=true` 会禁用。
- v1.8.0 起，global config 的 `telemetry.enabled: false` 也禁用匿名遥测与 `openspec update` 版本检查；unset 保持开启（opt-out 模型），env/CI opt-out 优先。
- PostHog 请求 1s timeout、无 retry、失败静默。
- anonymous id 是随机 UUID，保存在 telemetry config。

CLI 在 `preAction` 里显示首次 notice 并 track command，在 `postAction` shutdown。

v1.10.0 的首次 telemetry notice 改写 stderr；`--json` 仍 defer 且不设置 `noticeSeen`，让 stdout 保持单一 JSON 文档，并把 disclosure 留给下一次非 JSON 运行。

工程含义是：telemetry 只提供粗粒度使用信号，不能成为命令成功与否的依赖，也不能接触项目内容。

## feedback：agent workflow 和 CLI 提交分层

feedback 有两层：

- workflow template：指导 agent 收集、整理、匿名化反馈。
- CLI command：实际提交 GitHub issue 或输出 manual URL。

CLI 用 `execFileSync('gh', [...args])`，避免 shell injection。gh 不存在或未认证时，不报失败，而是输出可手动提交的内容和预填 URL。

反馈 title 会归一化空白并截到 72 字符（grapheme-safe、省略号）；body 的 `## Summary` 始终保留原始完整 message，可选 details 另列。title 截断不会丢掉 GitHub issue body，也不会在 gh 失败的 manual fallback 中丢失。

它不上传源码、不收集项目文件，只附加 version/platform/timestamp metadata。这个边界和 telemetry 一样重要：反馈通道应该帮助维护项目，但不能变成隐式数据采集。

## prompts / ui：人类路径的入口质量

`src/prompts/searchable-multi-select.ts` 和 `src/ui/` 属于交互体验层：

- tool selection。
- welcome screen。
- searchable selection。

它们不定义 OpenSpec 业务状态，但影响 init、workspace setup、interactive validate/show 等命令的人类路径。对一个 CLI 工具来说，prompt 质量会直接影响用户是否能正确建立配置。

## utils：辅助层里也可能藏行为

`src/utils/` 是跨模块基础设施：

- file-system：路径规范化、写文件、权限等。
- item-discovery：发现 active changes/spec ids。
- shell-detection：completion shell auto-detect。
- task-progress：读取 checkbox progress。
- command-references：按工具转换 command 引用。
- change-utils/change-metadata：change 名称和 metadata 辅助。

这些 util 通常不是专题核心，但很多机制依赖它们。文档引用源码时要注意 util 里可能有实际行为，不只是“辅助函数”。

## JsonConverter 的归属

`JsonConverter` 把 spec/change Markdown 转成 JSON：

- 复用 `MarkdownParser` / `ChangeParser`。
- 添加 `metadata.sourcePath`。
- 不定义新模型。

它在概念上属于 spec model 的读模型链路，同时在 CLI infra 中作为 converter 支撑设施出现。这个双重归属说明 `_coverage/` 里有些模块会指向多个专题：不是重复，而是视角不同。

## 工程洞察

- completion registry 是 CLI 表面的一份独立模型，维护时要和 commander 注册同步。
- telemetry 和 feedback 都必须低阻塞、低敏感度，不能影响核心命令成功路径。
- interactive prompts 不定义业务事实，但影响用户能不能正确生成初始配置。
- utils 不是无意义杂物层，路径、shell、task progress 等实际行为会影响上层机制。

## 源码锚点

| 子系统 | 路径 |
|--------|------|
| shell completion | `src/core/completions/`、`src/commands/completion.ts` |
| shell detection | `src/utils/shell-detection.ts` |
| telemetry | `src/telemetry/` |
| feedback | `src/commands/feedback.ts`、`src/core/templates/workflows/feedback.ts` |
| interactive prompts | `src/prompts/`、`src/ui/` |
| utility modules | `src/utils/` |
| converter | `src/core/converters/json-converter.ts` |

## 测试锚点

- `test/core/completions/`
- `test/commands/completion.test.ts`
- `test/telemetry/`
- `test/commands/feedback.test.ts`
- `test/prompts/`
- `test/utils/`
- `test/core/converters/`
