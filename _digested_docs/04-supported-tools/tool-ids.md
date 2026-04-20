# `--tools` 可用 ID 清单

`openspec init --tools <list>` 里可以用下列 ID，逗号分隔，或用 `all` / `none` 两个特殊值。

## 完整 ID 清单（28 个，来自 `src/core/config.ts`）

```
amazon-q
antigravity
auggie
bob
claude
cline
codebuddy
codex
continue
costrict
crush
cursor
factory
forgecode
gemini
github-copilot
iflow
junie
kilocode
kiro
lingma
opencode
pi
qoder
qwen
roocode
trae
windsurf
```

## 实用命令示例

```bash
# 只装 Claude + Cursor
openspec init --tools claude,cursor

# 全部装
openspec init --tools all

# 一个都不装（只要 openspec/ 目录结构）
openspec init --tools none

# 用 core profile（默认就是 core，显式写给 CI 看）
openspec init --tools claude --profile core

# 用 custom（当前全局 config profile 里勾选的那套 workflows）
openspec init --tools claude --profile custom

# 刷新已有项目
openspec update
openspec update --force   # 即使文件已是最新也强制重写
```

## 在 CI 里非交互地配置

```bash
# 常见组合：只装 claude + 跳过提示
openspec init --tools claude --force

# 多工具：
openspec init --tools claude,cursor,codex --force
```

## 注意官方文档暂缺的 ID

[docs/supported-tools.md](../../docs/supported-tools.md) 最底的 `--tools` 可选值清单**少列了 `bob` 和 `lingma`**。以源码 [src/core/config.ts](../../src/core/config.ts) 的 `AI_TOOLS` 为准。

## 动态发现

```bash
openspec init   # 不带 --tools 会进入交互菜单，自动扫描项目里已存在的 tool 目录
```

内部实现 [src/core/available-tools.ts](../../src/core/available-tools.ts)：遍历 `AI_TOOLS`，对每个工具检查 `detectionPaths`（如果有）或 `skillsDir` 目录是否存在，返回检测到的列表。
