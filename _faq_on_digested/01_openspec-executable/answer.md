# 答案：`openspec` 是怎么变成可执行命令的

## 一句话

npm 安装走的是 **npm 的 `bin` 字段 + `#!/usr/bin/env node` shebang + Node.js ESM 入口**；没有自定义安装脚本，也没有为 npm 包编译二进制。v1.15.0 起官方另发 **standalone 单文件**（不依赖 Node.js），是独立于 npm 的第二条路径，见文末。

## 完整链路

```
npm install -g @fission-ai/openspec
│
├─1─ npm 读取 package.json "bin" 字段
│     package.json:30:
│       "bin": { "openspec": "./bin/openspec.js" }
│
├─2─ npm 创建符号链接（非拷贝）
│     /usr/local/bin/openspec
│       → ../lib/node_modules/@fission-ai/openspec/bin/openspec.js
│
│     本机实际路径（nvm 环境下）：
│     /Users/bowhead/.nvm/versions/node/v20.19.6/bin/openspec
│       → ../lib/node_modules/@fission-ai/openspec/bin/openspec.js
│
▼ 用户执行 openspec
│
├─3─ 内核读取 shebang
│     bin/openspec.js:1: #!/usr/bin/env node
│     └─> 内核调用 node 执行此文件
│
├─4─ 入口文件四行代码
│     bin/openspec.js 完整内容：
│       #!/usr/bin/env node
│
│       import { runCli } from '../dist/cli/index.js';
│
│       runCli();
│
│     这是 npm 包的 "bin" 入口。真正的 CLI 在 dist/cli/index.js
│
├─5─ TypeScript 编译产物
│     src/cli/index.ts ──tsc──> dist/cli/index.js
│
│     build.js → execFileSync(tsc) → 编译所有 src/**/*.ts
│     tsconfig.json: rootDir=./src, outDir=./dist
│
│     编译时从不打包成二进制，只是 .ts → .js
│
├─6─ dist/cli/index.js 才是真正的 CLI
      commander 构建：
        program.name('openspec')
        ├── init、update、install（v1.15.0）
        ├── list、view
        ├── change (show/list/validate)
        ├── archive
        ├── spec (rename：registerSpecCommand)
        ├── validate、show
        ├── config、schema
        ├── completion
        ├── status
        ├── instructions
        ├── templates、schemas
        ├── new change
        └── feedback
│     program.parseAsync() 接管 process.argv
│
└─7─ 首次交互运行的 postAction
      命令 action 收尾后尝试在 stderr 提示：
      Tip: Run 'openspec completion install' for shell completions
      JSON、CI、非 TTY、completion 子命令、已安装/不支持 shell，
      或 OPENSPEC_NO_COMPLETIONS=1 时不提示
```

## 三个关键机制拆解

### 1. npm `bin` 字段

npm 的 `package.json` 中 `"bin"` 字段告诉 npm：安装此包后，在 `$PREFIX/bin` 下创建一个指向目标文件的符号链接。

- 全局安装 (`-g`)：链接到 `/usr/local/bin`（或 nvm 下对应目录）
- 本地安装：链接到 `node_modules/.bin/`

**不是拷贝文件，是 symlink**。所以更新包源码后命令行为立刻改变。

### 2. Shebang：`#!/usr/bin/env node`

```bash
$ file $(which openspec)
/Users/bowhead/.nvm/versions/node/v20.19.6/bin/openspec:
  a /usr/bin/env node script text executable, ASCII text
```

内核执行一个文本文件时，读到第一行 `#!` 开头的 shebang，就知道该用哪个解释器执行。

`#!/usr/bin/env node` 的写法（而不是 `#!/usr/bin/node`）是因为：
- `env` 从 `$PATH` 中查找 `node`，不依赖 Node.js 的绝对路径
- 兼容 nvm、fnm、volta 等版本管理工具

### 3. `type: "module"` + 动态 import

```json
// package.json:19
"type": "module"
```

这告诉 Node.js：此包内所有 `.js` 文件默认是 ESM。所以 `bin/openspec.js` 可以用 `import` 语法，不需要 `.mjs` 后缀。

注意 `bin/openspec.js` 只是「具名 import + 调用 `runCli()`」，没有做任何 CLI 参数的预处理（argv 由 `runCli(argv = process.argv)` 默认处理），也没有检查 `dist/` 是否存在 —— 如果 `dist/` 没编译（比如 dev 环境），Node.js 会直接报 `ERR_MODULE_NOT_FOUND`。

## 关键文件清单

| 文件 | 作用 |
|---|---|
| `package.json` L30-32 | 声明 `"bin": {"openspec": "./bin/openspec.js"}` |
| `bin/openspec.js` | 4 行 shebang 入口：具名 import `runCli` 后调用它 |
| `src/cli/index.ts` | CLI 源码（commander），所有命令的注册 |
| `build.js` | 构建脚本，调用 tsc 编译 |
| `tsconfig.json` | TypeScript 配置，rootDir=src → outDir=dist |
| `src/core/completion-tip.ts` | 首次 eligible `postAction` 中的 completion 提示；只写 stderr，并记录 one-shot 状态 |
| `src/telemetry/index.ts` | 首次 telemetry notice；写 stderr，避免污染 stdout/JSON |
| `scripts/binary/entry.mjs`、`build.mjs`、`install.sh` / `install.ps1` | v1.15.0 standalone：编译入口、Bun 构建、官方安装器 |

## v1.15.0 起的第二条路径：standalone 单文件

npm 方式始终需要 Node.js；v1.15.0 起每个 release 另外提供 8 个平台的单文件（macOS / Linux glibc / Linux musl / Windows，x64 与 arm64），由 `scripts/binary/build.mjs` 用 Bun 编译，入口是 `scripts/binary/entry.mjs`。

- **安装**：文档里的一行命令（`curl ... install.sh | sh` / `irm ... install.ps1 | iex`），或 `openspec install [version]`。安装器校验 `SHA256SUMS` 后把文件放到 `~/.local/bin/openspec`（Windows：`%LOCALAPPDATA%\Programs\openspec`）。
- **运行**：单文件直接执行，不需要 Node.js；入口先 `markStandaloneBinary(process.execPath)`，再把内嵌的 schema 解到 `<globalDataDir>/binary-schemas/<hash>` 并交给 `setPackageSchemasDir`。
- **识别**：`openspec version` 会标 `(standalone)`，`--json` 的 `install.scope` 是 `standalone`；`openspec version --check` 给出的升级命令是 `openspec install`。
- **升级**：`openspec install` 原地重装（不是 npm/brew），之后再 `openspec update` 刷新工具侧文件。
- **切换**：`openspec install` 不会自动删旧的包管理器副本，只提示移除命令；切不切由用户决定。

## 不是什么

- **npm 安装包不是二进制可执行文件** — npm 包本身没有 Go/Rust 编译，也没有 nexe/pkg 打包；standalone 单文件是另一条分发物，由 Bun 编译
- **不是 shell 脚本** — 是 Node.js 脚本，靠 shebang 执行
- **不是 Python** — 虽然 `#!/usr/bin/env` 模式在 Python 脚本里也很常见，但这里是 node
- **没有现行 postinstall 链路** — registry 安装包没有 install lifecycle script，因此不会再出现 completion postinstall 文案或 allow-scripts 警告；git/directory 安装仍可能因 `prepare` 构建。
- **standalone 安装器不是 npm 的 postinstall** — 它只由用户显式运行（或 `openspec install` 调用），不会在 npm 安装时静默执行。

## 为什么全局安装后不再立即提示 completion

OpenSpec 删除了 npm `postinstall`。completion 提示改为 CLI 的 `postAction`：首次符合条件的运行、且 stderr 是 TTY 时才出现；即使命令用 `process.exitCode` 报失败，收尾 hook 仍可执行。反过来，action 若直接调用 `process.exit(1)`，会跳过 hook，这次失败不会显示或消费提示。若命令属于 JSON/机器输出，提示会 defer；设置 `OPENSPEC_NO_COMPLETIONS=1` 可抑制当前环境中的提示。提示写入全局 config 的 `completionTipSeen` 后只展示一次；读写使用 raw config，不能顺带把默认 profile 等字段写回。

telemetry 的首次 notice 也只写 **stderr**。因此脚本可以继续把 stdout 当机器接口；JSON 运行会延后 notice，不会把提示混进 JSON。
