# TS → JS 编译链 & 为什么一行 import 就跑起来了

## 前半段：TypeScript 怎么变成 JavaScript 的？

### 源码 vs 产物

仓库里写的是 `.ts`：

```
src/cli/index.ts          ← 你看到的源码（TypeScript）
```

安装包里跑的是 `.js`：

```
dist/cli/index.js         ← npm 安装到机器上的（JavaScript 编译产物）
```

### 谁做的编译？

**运行 `pnpm build` 的人，不是安装的人。**

```json
// package.json:41 (scripts) / :43 (build) / :53 (prepublishOnly)
"scripts": {
  "build": "node build.js",
  "prepublishOnly": "pnpm run build"
}
```

关键是 `prepublishOnly` —— 这个 hook 在 `npm publish` 之前自动触发。也就是说：

```
开发者执行 npm publish
  └─> npm 自动跑 prepublishOnly
      └─> pnpm run build
          └─> node build.js
              └─> 调用 tsc（TypeScript compiler）
                  └─> 读取 tsconfig.json：
                      rootDir: ./src   → 从哪里读 .ts
                      outDir:  ./dist  → 把 .js 输出到哪里
                  └─> src/cli/index.ts → dist/cli/index.js
                  └─> src/core/*.ts    → dist/core/*.js
                  └─> src/commands/*.ts → dist/commands/*.js
                  └─> ...全部编译...
```

### npm 发布的包里有什么？

```json
// package.json:33-40
"files": [
  "dist",       // ← 编译产物 (ts → js)
  "bin",        // ← 入口脚本 (不是 ts, 天生就是 js)
  "schemas"     // ← YAML schema 文件
]
```

**`src/` 不在 `files` 数组里。** 所以 npm 发布的包只包含编译好的 `dist/`，安装者根本不需要装 TypeScript。

一张图总结：

```
仓库 (GitHub)                     npm 包                    你的机器
──────────────────────────────────────────────────────────────────
src/cli/index.ts  ──tsc──>  dist/cli/index.js  ──npm install──>  node_modules/.../dist/cli/index.js
src/core/*.ts     ──tsc──>  dist/core/*.js     ──npm install──>  node_modules/.../dist/core/*.js
bin/openspec.js   ──直拷──>   bin/openspec.js   ──npm install──>  node_modules/.../bin/openspec.js
```

### tsconfig.json 长什么样

```json
// tsconfig.json
{
  "compilerOptions": {
    "rootDir": "./src",     // 从 src/ 读 .ts
    "outDir": "./dist",     // 输出到 dist/
    "module": "NodeNext",   // 输出 ES module 格式（import/export）
    "target": "ES2022",     // 输出 2022 年标准的 JavaScript
    "strict": true
  },
  "include": ["src/**/*"]   // 编译 src 下所有 .ts 文件
}
```

---

## 后半段：为什么 `import '../dist/cli/index.js'` 就跑起来了？

### 一个关键认知：ESM import 会执行整个模块

你习惯的模式可能是：

```js
// 你以为的用法
import { someFunction } from './lib.js';
someFunction();  // 显式调用
```

但 Node.js 的模块系统有一个基本规则：

> **`import` 一个模块时，Node.js 会完整执行该模块的顶层代码。**

也就是说，如果你 import 的文件顶层写了：

```js
console.log('hello');
```

那 import 它的时候就会打印 `hello`，不需要你显式调用任何函数。

### `dist/cli/index.js` 的最后一行为什么是关键

看 `src/cli/index.ts` 的结构（编译后就是 `dist/cli/index.js`）：

```typescript
// src/cli/index.ts（简化）

import { Command } from 'commander';
// ... 各种 import ...

const program = new Command();
program.name('openspec');

// 注册所有子命令...
program.command('init').action(...);
program.command('list').action(...);
program.command('archive').action(...);
// ... 几百行命令注册 ...

// 文件末尾（src/cli/index.ts 的 runCli 定义）
export { program };

export function runCli(argv = process.argv): void {
  program.parse(argv);          // ← parse 在函数里，不在顶层
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  runCli();
}
```

这个文件有三个事实：

1. **`program.parse()` 在 `runCli()` 函数体里**（`index.ts:848`），**不在模块顶层**。模块顶层只有命令注册 + 一个"被直接运行时才执行"的守卫
2. **模块显式导出 `program` 和 `runCli`**（`:845`、`:847`），导入方解构使用
3. **`bin/openspec.js` 调它**：

```js
#!/usr/bin/env node

import { runCli } from '../dist/cli/index.js';

runCli();
```

也就是说这不是"import 即执行"，而是**标准的具名导出 + 显式调用**，外加一个 `process.argv[1] === import.meta.url` 守卫（等价于 Python 的 `if __name__ == '__main__'`，让 `node dist/cli/index.js` 也能直接跑）

所以执行流程是：

```
用户敲 openspec init myproject
  │
  ▼
Shell 找到 /usr/local/bin/openspec（symlink）
  │
  ▼
内核读 shebang → 用 node 执行 bin/openspec.js
  │
  ▼
bin/openspec.js:  import { runCli } from '../dist/cli/index.js'
  │
  ▼
Node.js 加载 dist/cli/index.js 模块
  │  └─> 执行该文件的顶层代码（只做构建，不启动）：
  │       1. import 各种依赖（commander 等）
  │       2. new Command() → 构建 program 对象
  │       3. 注册所有子命令
  │       4. 定义并导出 runCli()；顶层守卫检查 argv[1] 是否就是自己
  │          （从 bin 进来时不是，守卫跳过）
  │
  ▼
bin/openspec.js 显式调用 runCli()
  │  └─> runCli() 里 program.parse(process.argv)
  │        └─> 读 process.argv: ['node', 'openspec', 'init', 'myproject']
  │        └─> 匹配到 'init' 命令
  │        └─> 执行 init 的 action handler
  │        └─> handler 结束 → process.exit(0) 或返回
  │
  ▼
用户看到输出
```

### 这个模式叫什么：带 main 守卫的具名导出

它是**普通具名导出 + 显式调用**，不是 side-effect import：

```js
// bin/openspec.js —— 解构导出，然后自己调
import { runCli } from '../dist/cli/index.js';
runCli();
```

`src/cli/index.ts` 末端的守卫则让同一个模块既能被 import（不执行），也能被直接 `node dist/cli/index.js` 运行：

```ts
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  runCli();
}
```

### 一个类比：Python 的 `if __name__ == '__main__'`

几乎是字面对应：

```python
# dist/cli/index.ts 的等价物
def run_cli(argv=None):
    program.parse(argv if argv is not None else sys.argv)

if __name__ == '__main__':
    run_cli()
```

```python
# bin/openspec.js 的等价物
from dist.cli.index import run_cli
run_cli()
```

两点好处和 Python 那边一样：**被 import 时不会意外执行**，**同时又能直接当脚本跑**。OpenSpec 的测试就是靠这个直接 import `runCli` 而不启动整个 CLI。

---

## 总结

| 问题 | 答案 |
|------|------|
| TS → JS 谁编译的？ | `pnpm build` → `build.js` → 调 tsc |
| 什么时候编译的？ | `npm publish` 之前（`prepublishOnly`，package.json:53）。从 **registry** 安装不需要编译；但 `prepare`（:52）也是 `node build.js`，所以 git/directory 安装仍会就地构建一次 |
| npm 包里有源码吗？ | 没有。`files` 字段只包含 `dist/`、`bin/`、`schemas/` |
| 安装时会跑 completion 脚本吗？ | 不会。registry 包已删除 `postinstall`；completion tip 改到首次 CLI 运行后的 stderr。 |
| import 会跑起来吗？ | 不会。`program.parse()` 在 `runCli()` 里，顶层只构建 program；由 bin 显式调用 |
| 这个模式叫什么？ | 具名导出 + main 守卫（main-guard），不是 side-effect import |
