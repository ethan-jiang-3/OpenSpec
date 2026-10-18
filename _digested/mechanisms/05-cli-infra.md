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

### Fish 不再回退到文件路径

Fish 的 command/subcommand/flag/positional completion 之前在某些位置会回退到 shell 默认的文件名建议，用户按 Tab 会看到一堆无关文件名。改用带 type 信息的 `__openspec_seen_args` 记录已解析的位置参数，只在 OpenSpec 自己的候选集里建议，不再 fallback 到路径补全。

### 安装期脚本改为首次运行 tip

发布包不再包含 npm `postinstall`；registry install 因而没有 install lifecycle script，也不再触发相关 allow-scripts 警告。源码/git/directory install 仍可能因 package 的 `prepare` 构建，不能把“无 postinstall”误写成“所有安装方式绝不运行脚本”。

completion 提示移到 root commander 的 `postAction`：命令自身输出之后，第一次可读的交互运行只向 **stderr** 打印一次 `openspec completion install`，不自动安装。以下情况抑制或 defer：

- `CI` 或 `OPENSPEC_NO_COMPLETIONS=1`：不显示；
- completion 已安装、shell 未检测到/不支持：retire，一次性消费；
- `--json`、completion 命令自身、stderr 非 TTY：defer，不设置 seen，留给以后可读运行。

“运行”在这里准确指**到达 root `postAction` 的 action**。action 正常 return，或失败时只设置 `process.exitCode`，commander 仍会运行 hook；因此 `change validate` 这类非零退出也可能显示/消费 tip。若 action 的 catch 直接调用 `process.exit(1)`，进程会在 hook 前终止，这次失败既不显示也不消费 tip，下一次真正到达 `postAction` 的 eligible run 才处理。completion tip 与 telemetry shutdown 都受这个边界约束。

seen flag 写 global config 时使用 raw read/merge + 临时文件 rename，不调用会合入默认值的 `getGlobalConfig()`，避免顺带 stamp `profile`/`delivery` 并破坏一次性 profile migration。

### PowerShell completion 文档化

`openspec completion install` 对 PowerShell 的 managed 配置方式（脚本位置、profile 写入、backup）在 `docs/cli.md` 有正式文档（#1070）。Fish 之外的 shell 面此前只有生成器实现，现在 PowerShell 的 setup 路径有可查文档。

### npm git 安装免 pnpm + Node 20 chalk 兼容

- **git 安装免 pnpm**（#792）：`npm install github:...` 这类 git 安装时，package `prepare` 脚本改为 `node build.js`（不再假设 pnpm 在场）。此前 pnpm 是构建前置依赖，git 安装会因缺 pnpm 失败；现在 install scripts 测试（`test/package-install-scripts.test.ts`）覆盖了这条路径。
- **Node 20 chalk 兼容**（#1747）：依赖解析保持 Node 20 LTS 可用的 chalk 版本，避免新依赖树把 chalk 解析到 Node 22+ 才能用的版本。安装面（npm/pnpm/bun/yarn/volta）对 Node 20 用户都保持可用。

## telemetry：低信息量、低阻塞

telemetry 在 `src/telemetry/`。它的边界：

- 只记录 command name、version、surface。
- 不记录 arguments、paths、content。
- `OPENSPEC_TELEMETRY=0`、`DO_NOT_TRACK=1`、`CI=true` 会禁用。
- global config 的 `telemetry.enabled: false` 也禁用匿名遥测与 `openspec update` 版本检查；unset 保持开启（opt-out 模型），env/CI opt-out 优先。
- PostHog 请求 1s timeout、无 retry、失败静默。
- anonymous id 是随机 UUID，保存在 telemetry config。

CLI 在 `preAction` 里显示首次 notice 并 track command，在 `postAction` shutdown。

首次 telemetry notice 改写 stderr；`--json` 仍 defer 且不设置 `noticeSeen`，让 stdout 保持单一 JSON 文档，并把 disclosure 留给下一次非 JSON 运行。

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
- line-endings：写回文件时保持既有行尾（v1.13.2 新增，见下）。

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
| utility modules | `src/utils/`（v1.13.2 `line-endings.ts`；v1.14.3 新增 `spec-path-containment.ts`） |
| command registration（按需加载） | `src/cli/index.ts` + `src/cli/commands/*.ts`（v1.14.1 起） |
| version / update check | `src/core/version-check.ts`、`version` 命令注册于 `src/cli/index.ts` |
| converter | `src/core/converters/json-converter.ts` |

## 测试锚点

- `test/core/completions/`
- `test/commands/completion.test.ts`
- `test/telemetry/`
- `test/commands/feedback.test.ts`
- `test/prompts/`
- `test/utils/`
- `test/utils/line-endings.test.ts`、`test/utils/marker-updates.test.ts`（行尾保持）
- `test/core/version-check.test.ts`
- `test/core/converters/`


## v1.12.x–v1.13.x 更新

**安全加固（v1.13.1，#1835）**：`config.yaml` 值不能再向 agent instructions 注入指令；恶意构造的文件不能再挂起 `openspec update`/`archive`；仓库 `.npmrc` 不能再重定向 update 检查。OpenSpec 现在可以在未审查的 freshly-cloned 仓库中安全运行。

**新模块**：
- `src/core/shared/ide-restart.ts` — init/update 共享 IDE restart 提示逻辑
- `src/utils/task-progress.ts` 计数器扩展（全列表标记、未识别算未完成）；新模块 `src/core/validation/task-checkboxes.ts` 负责「有列表项但无 checkbox」的 validate 警告
- `src/core/completions/installers/shell-quote.ts` — completion 安装的 shell 引用处理（bash 卸载逐字节还原 `.bashrc`，`72bf7600`）
- `src/telemetry/opt-out.ts` — 遥测 opt-out 独立模块

**其他**：init 给空目录写 `.gitkeep`；npm git 安装不再要求本机有 pnpm（`1bcdf1b0`）；pnpm overrides 移至 `pnpm-workspace.yaml`；`packageManager` 升至 pnpm@10.34.5。

## v1.13.2–v1.14.0 更新

### 行尾保持：`src/utils/line-endings.ts`（v1.13.2）

新模块三个函数：

- `detectLineEnding(content)`：dominant 判定——CRLF 与 LF 各自计数（CRLF 不重复计为 LF），取多者；**平局 CRLF 胜出**（一个 mostly-CRLF 的文件捡了零星 LF，仍按 CRLF 处理，整文件统一到一个 ending 才能让后续 diff 最小）；无换行时返回 undefined。
- `applyLineEnding(content, ending)`：先归一到 LF 再重灌指定 ending。
- `matchLineEnding(content, original)`：按 `original` 的行尾约定重写 `content`；`original` 无换行可判时保持 LF（新文件的 portable 默认）。

消费点：

- **specs-apply 写回**：`toWrite = previous === undefined ? rebuilt : matchLineEnding(rebuilt, previous)`——只有文件不存在时才写 LF。此前编辑 CRLF spec 里的一条 requirement 会把全文件重写成 LF，真实改动被淹没在整文件 diff 里；现在 Windows autocrlf 环境下的 spec 编辑恢复为单行 diff。
- **completion 安装**：`FileSystemUtils.updateFileWithMarkers` 写 managed block 后同样 `matchLineEnding`——`.bashrc`/`.zshrc` 等宿主文件的既有行尾不再被托管块拼接改写。
- **`removeMarkerBlock` 的 blank-line collapse**：压缩连续空行时用 `detectLineEnding(content) ?? '\n'` 重建分隔行——同一 dominant 读法，两条写路径口径一致，CRLF 文件里不会留下混杂的孤立 `\r`。

### archive.ts 大改（v1.13.2，+409 行）

Windows 上 staging rename 遇 EPERM/EXDEV 不再直接失败：

- `copyThenRemoveDirectory`：源→dest 逐项复制再删源，替代 rename。
- **fingerprint 中断检测**：复制前后对目录内容做指纹比对，复制窗口内的并发写入会让指纹变化、move 中止——避免把写到一半的 change 归档成功。
- `removeVerifiedTree`：只有校验通过的树才允许删除。
- `captureSpecSnapshots` / `restoreSpecSnapshots`：合并/退役失败时把 spec 文件回滚到归档前快照。
- `deepestExistingAncestor`：回滚剪裁用——新建 spec 的回滚只删自己创建的 capability 目录，已存在的空目录保留。

非 EPERM/EXDEV 的 staging 失败仍保持源 change 不动。

### version-check 扩展与 `openspec version` 命令（v1.14.0）

`src/core/version-check.ts` 扩展出四个导出：`getCliInstallInfo`（安装方式与位置）、`checkForCliUpdate`（查 registry，仅 `--check` 时调用）、`canSelfUpgrade`（判定能否自行升级）、`buildVersionReportLines`（人类可读输出）。`openspec version [--json] [--check]` 输出 `{ schemaVersion: 1, version, install, update? }`，`update` 含 `command` 与 `canSelfUpgrade`。

### 依赖钉版

root workspace 的 `pnpm-workspace.yaml` 早有 `brace-expansion` override（v1.13.1 前的 audit 修复）；website 侧针对新一批 advisory 把 `brace-expansion` 与 `fast-uri` 的 override 进一步抬高（#2019，`3a34ea30`，v1.14.3 起包含在发布内）。

**v1.14.3 之后这两条 website 钉版被删掉了**——不是因为 advisory 修好了，而是因为整条依赖链消失了：`serve` 被 `website/scripts/preview.mjs`（零依赖静态服务器）取代（#2110）。

## v1.14.1–v1.14.3 更新

这一轮 CLI 基建的主题是**启动成本**与**输入边界的可预测性**。

### 按需加载：命令定义与实现分离（v1.14.1 #2025）

`src/cli/index.ts` 只保留**命令定义**（名字、选项、help 文本），每个命令的实现都在 action 里 `await import()`：

| 位置 | 职责 |
|---|---|
| `src/cli/index.ts` | 薄壳：program 装配、公共 flag、错误出口 |
| `src/cli/commands/{config,context,doctor,schema,spec,store,workset}.ts` | 各命令的注册（定义层），实现延迟加载 |
| `src/commands/*.ts` | 真正的实现 |
| `src/commands/workflow/default-schema.ts` | 单独模块——让 help 文本能显示默认 schema 而不加载 workflow 实现 |

同一手法还用在三处 barrel 上：`completion-tip.ts` 的 `CompletionFactory` 改为在**真需要判定是否已安装**时才 import；`completion-provider.ts` 的 `listSchemas` 改为直接 import `artifact-graph/resolver.js`（绕过会把 `tinyglobby` 一起拉进来的 barrel）；`failWithError` 的 ora 与 `shared-output` 也延后。

效果：`--version` / `--help` 加载 **24** 个模块（原 485）；`config list`、`store list`、`doctor` 只加载自己用到的。输出、帮助文本、补全、退出码、遥测全部不变。

### Tab 补全不再付遥测的账（v1.14.2 #2064）

`isCompletionRun` 之外新增 `__complete` 的单独判定：Tab 每次按都会跑的解析器**完全跳过遥测与补全提示**。补全 changes/specs 时加载 **48** 个模块（原 344），且一次按键不会等 telemetry 请求，也不会在没人看得见的地方消耗掉首次运行的遥测提示。

### 零宽 TTY：spinner 会挂死（v1.14.3 #2108）

新函数 `canRenderSpinner(stream)`：

```ts
// 非 TTY：ora 自身禁用，只打一行 plain 输出 → 允许
// TTY 但 columns === 0 → 拒绝，调用方回退 plain 输出
return !stream.isTTY ? true : (stream.columns ?? 0) > 0;
```

根因值得记下来：ora 用 `ceil(width / stream.columns)` 决定擦几行，`columns === 0` 时该值是 `Infinity`，`clear()` 永不结束——命令烧满一个核并写出上百 MB 光标转义，`openspec validate --all` 从不返回。零宽 TTY 真实存在：pre-commit runner（如 lefthook）继承的 pty、`script -qec` 包一层都会这样。

消费点目前是 `validate --all` 与 `validate --archived`：spinner 条件改为 `!json && isInteractive(opts) && canRenderSpinner()`。顺带的口径统一：`OPEN_SPEC_INTERACTIVE=0` 与 `CI` 现在也像 `--no-interactive` 一样关掉 spinner（`isInteractive(opts)` 取代了裸 `!opts.noInteractive`）。

### glob 引擎更换（v1.14.3 #2103 / v1.14.2 #2061）

`src/core/artifact-graph/outputs.ts` 从 `fast-glob` 迁到 `tinyglobby` + `brace-expansion` + `picomatch`：

| 目的 | 做法 |
|---|---|
| 不再经由本包把未修补的 `braces` 带给下游 | 移除 `fast-glob`（它的传递链里有 `braces`），GHSA-vfj7-8cjw-p6xm 不再出现 |
| 严格 brace 预算 | `assertBraceNesting`：镜像 braces 解析器（`[...]` 与引号内为字面量，`(` 与 `{` 同计深，关闭符只闭合同类最内层），> 16 层直接报错 |
| 防展开爆炸 | `MAX_BRACE_EXPANSIONS = 1024`：`{a,b}` 重复十余次、`file-{1..5000}.md` 这类展开被拒绝。嵌套深度单独不够——`{a,b}` 重复 20 次只有一层深却展开 1,048,576 个模式，足以打爆堆 |
| 逐顶层组展开 | 不交给 brace-expansion 一次性递归：`{a,{a,{a,b}}}` 这类 16 层模式在超时前跑不完。同时绕开 brace-expansion 5 在 `{draft}` 在前时把后续范围当字面量的行为；字面量 `{...}` 用 NUL 前缀哨兵承载（`resolveArtifactOutputPath` 的 `path.join` 会先拒绝 NUL 字节，故无法被 `generates` 值伪造） |
| 保留 `../` 防护 | `globBase()` 取代 fast-glob 的 `generateTasks().base`，静态目录前缀仍先做 `assertPathWithin(changeDir, …)`；**绝对模式保持绝对**，否则 `path.resolve(changeDir, '/etc/*')` 会被重基进 change 目录而绕过检查 |
| 目录遍历收紧 | `assertGlobDirectoryTraversal` 从 `fg.sync` 改为 `listDirectoryMatches()`（`readdirSync` + `picomatch` 单段匹配），显式处理 `.`/`..`——`**/../` 在 glob 跑之前就被限制 |

`ARTIFACT_GLOB_OPTIONS`：`braceExpansion: false`（先自行展开，留下的 `{draft}` 仍作字面量）、`expandDirectories: false`（迁移对齐：目录模式不再长尾巴 `/**`）、`followSymbolicLinks: true`、`onlyFiles: true`。

### 依赖与 npm 审计

| 项 | 变化 |
|---|---|
| 移除 | `fast-glob` |
| 新增 | `tinyglobby@^0.2.17`、`brace-expansion@^5.0.12`、`picomatch@^4.0.4`（+ dev `@types/picomatch`） |
| root override | `brace-expansion@<5.0.12: '>=5.0.12 <6'`（GHSA-6j4f-fj2g-mc7p / GHSA-qhr7-859c-m2p7 / GHSA-q2hr-2g5m-vwhr）；新增 `shell-quote@>=1.8.4 <1.11.0: '>=1.11.0 <2'`（仅 dev，经 `@changesets/cli > launch-editor`） |
| website | `serve` 移除 → `scripts/preview.mjs`；随之删掉 `brace-expansion`/`fast-uri` 两条 website 钉版 |

### website 预览（v1.14.3 #2110）

`pnpm start` 在 `website/` 下改为 `node scripts/preview.mjs`：零依赖静态服务器，按 Next 静态导出的路由解析（**不应用 `out/_redirects`**）。连带升了整组 website 依赖（next 16.3.8、react 19.3.0、fumadocs 16.16.x 等）。

## 测试锚点补充（v1.14.1–v1.14.3）

- `test/cli-e2e/startup-modules.test.ts` + `test/helpers/record-loaded-modules.mjs`：记录并断言启动时加载的模块数（防止按需加载被无意退回）
- `test/utils/interactive.test.ts`：零宽 TTY 下 spinner 被拒绝
- `test/utils/spec-path-containment.test.ts`、`test/cli-e2e/spec-symlink-into-project.test.ts`：symlink 包含边界
- `test/core/templates/glob-path-bounding.test.ts`：propose/ff/continue 的 glob 路径边界
- `test/core/artifact-graph/outputs.test.ts`：brace 嵌套/展开预算
- `test/website-preview.test.ts`：预览服务器的路由解析
