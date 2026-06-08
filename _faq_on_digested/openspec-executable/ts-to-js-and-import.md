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
// package.json:45
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
// package.json:32-40
"files": [
  "dist",       // ← 编译产物 (ts → js)
  "bin",        // ← 入口脚本 (不是 ts, 天生就是 js)
  "schemas",    // ← YAML schema 文件
  "scripts/postinstall.js"
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

program.parse();   // ← 第 510 行！这是关键！
```

这个文件有两个事实：

1. **`program.parse()` 在文件顶层**（不在任何 function 里），这是 commander 的约定：`parse()` 读取 `process.argv`，匹配用户输入的子命令，执行对应的 handler
2. **文件里没有 `export` 任何东西被消费** — 这个文件的导入方 `bin/openspec.js` 只写了 `import '../dist/cli/index.js'`，没有解构任何导出

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
bin/openspec.js:  import '../dist/cli/index.js'
  │
  ▼
Node.js 加载 dist/cli/index.js 模块
  │  └─> 执行该文件的顶层代码：
  │       1. import 各种依赖（commander 等）
  │       2. new Command() → 构建 program 对象
  │       3. 注册所有子命令
  │       4. program.parse()  ← 整个 CLI 在这一行启动！
  │          └─> 读 process.argv: ['node', 'openspec', 'init', 'myproject']
  │          └─> 匹配到 'init' 命令
  │          └─> 执行 init 的 action handler
  │          └─> handler 结束 → process.exit(0) 或返回
  │
  ▼
用户看到输出
```

### 这个模式叫什么：side-effect import（副作用导入）

这是一种 JS 生态里常见但不常被解释的模式：

```js
// bin/openspec.js
import '../dist/cli/index.js';
// 我不需要它的导出，我只需要"执行它"
```

对比标准用法：

```js
// 标准用法：导入后自己调用
import { run } from '../dist/cli/index.js';
run();
```

但 OpenSpec（以及几乎所有用 commander 的 CLI）选择让入口文件「自执行」—— 文件被 import 的那一刻就是程序启动的那一刻。这样 `bin/openspec.js` 保持极简，不需要知道 CLI 入参格式。

### 一个类比：Python 的 `if __name__ == '__main__'`

如果你是 Python 背景：

```python
# Python 里的等价心理模型
# bin/openspec.js 相当于：
import dist.cli.index  # 导入就执行了，不需要再调 main()

# dist/cli/index.js 相当于：
def main():
    parser.parse_args()

main()  # 顶层调用 —— 文件被 import 时就会执行
```

Python 里通常有个 guard `if __name__ == '__main__': main()` 防止被 import 时意外执行。但 Node.js CLI 场景下正相反 —— **就是要让 import 触发执行**，因为 bin 入口的唯一职责就是执行 CLI。

---

## 总结

| 问题 | 答案 |
|------|------|
| TS → JS 谁编译的？ | `pnpm build` → `build.js` → 调 tsc |
| 什么时候编译的？ | `npm publish` 之前（prepublishOnly hook），安装者不需要编译 |
| npm 包里有源码吗？ | 没有。`files` 字段只包含 `dist/`、`bin/`、`schemas/` |
| 为什么 import 就跑起来了？ | ESM 的 `import` 会执行模块顶层代码，`program.parse()` 就在顶层 |
| 这个模式叫什么？ | side-effect import / 自执行入口模块 |
