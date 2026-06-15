# CLI：[Agent 名] 命令行界面

## 入口

- **二进制名**：`[my-agent]`
- **安装方式**：[npm link / pip install -e . / 直接调用脚本]
- **调用示例**：`my-agent --help`

## 子命令

| 子命令 | 对应 skill | 参数 | 说明 |
|-------|-----------|------|------|
| `my-agent do-x` | `skills/[x].md` | `--param <value>` | [一句话] |
| `my-agent do-y` | `skills/[y].md` | `--param <value>` | [一句话] |

## 全局 flags

| flag | 说明 |
|------|------|
| `--help` | 输出帮助信息 |
| `--verbose` | 输出详细日志 |
| `--json` | 以 JSON 格式输出（机器可读） |

## 状态读取 API

<!-- 对外暴露的结构化状态接口——供其他工具或上层 orchestrator 查询 -->

| 命令 | 输出格式 | 说明 |
|------|---------|------|
| `my-agent status --json` | `{ "skills": N, "tools": N, "ready": bool }` | 当前 agent 运行时状态 |
| `my-agent skills --json` | `[{ "name": "...", "ready": bool }, …]` | 已注册 skill 清单及就绪状态 |
| `my-agent version --json` | `{ "version": "x.y.z" }` | agent 版本信息 |

## 退出码

| 码 | 含义 |
|---|------|
| 0 | 成功 |
| 1 | 一般错误 |
| 2 | 输入参数错误 |
| 3 | 工具/依赖不可用 |

## 安装/打包

- **目标平台**：[macOS / Linux / Windows]
- **运行时依赖**：[Node ≥ X / Python ≥ Y / …]
- **打包方式**：[npm publish / pip / 单二进制]
