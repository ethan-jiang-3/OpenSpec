# 答案：`openspec` 是怎么变成可执行命令的

## 一句话

靠的是 **npm 的 `bin` 字段 + `#!/usr/bin/env node` shebang + Node.js ESM 三行入口**。没有自定义安装脚本，没有二进制编译，纯 Node.js 生态的标准机制。

## 完整链路

```
npm install -g @fission-ai/openspec
│
├─1─ npm 读取 package.json "bin" 字段
│     package.json:33:
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
├─3─ postinstall 触发（与命令注册无关）
│     package.json:53: "postinstall": "node scripts/postinstall.js"
│     只打印一行 shell completion 提示，不参与命令注册
│
▼ 用户执行 openspec
│
├─4─ 内核读取 shebang
│     bin/openspec.js:1: #!/usr/bin/env node
│     └─> 内核调用 node 执行此文件
│
├─5─ 入口文件三行代码
│     bin/openspec.js 完整内容：
│       #!/usr/bin/env node
│       import '../dist/cli/index.js';
│
│     这是唯一入口。真正的 CLI 在 dist/cli/index.js
│
├─6─ TypeScript 编译产物
│     src/cli/index.ts ──tsc──> dist/cli/index.js
│
│     build.js → execFileSync(tsc) → 编译所有 src/**/*.ts
│     tsconfig.json: rootDir=./src, outDir=./dist
│
│     编译时从不打包成二进制，只是 .ts → .js
│
└─7─ dist/cli/index.js 才是真正的 CLI
      commander 构建：
        program.name('openspec')
        ├── init、update、list、view
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
      program.parse() 接管 process.argv
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

注意 `bin/openspec.js` 里只有一行 `import '../dist/cli/index.js'`。这里没有做任何 CLI 参数的预处理，也没有检查 `dist/` 是否存在 —— 如果 `dist/` 没编译（比如 dev 环境），Node.js 会直接报 `ERR_MODULE_NOT_FOUND`。

## 关键文件清单

| 文件 | 作用 |
|---|---|
| `package.json` L29-31 | 声明 `"bin": {"openspec": "./bin/openspec.js"}` |
| `bin/openspec.js` | 3 行 shebang 入口，import dist 产物 |
| `src/cli/index.ts` | CLI 源码（commander），所有命令的注册 |
| `build.js` | 构建脚本，调用 tsc 编译 |
| `tsconfig.json` | TypeScript 配置，rootDir=src → outDir=dist |
| `scripts/postinstall.js` | 与命令注册无关，只打印 completion 提示 |

## 不是什么

- **不是二进制可执行文件** — 没有 Go/Rust 编译，没有 nexe/pkg 打包
- **不是 shell 脚本** — 是 Node.js 脚本，靠 shebang 执行
- **不是 Python** — 虽然 `#!/usr/bin/env` 模式在 Python 脚本里也很常见，但这里是 node
- **postinstall 不参与命令注册** — 命令在 `npm install` 完成解压后就已经通过 `bin` 字段注册了，postinstall hook 是在那之后才跑的
