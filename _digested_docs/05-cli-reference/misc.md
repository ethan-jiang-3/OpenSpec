# CLI · 其它

## `openspec archive`

在终端非交互归档一个 change。和 `/opsx:archive` 是同一回事，只是不走 AI。

```
openspec archive [change-name] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `-y, --yes` | 跳过确认 |
| `--skip-specs` | 跳过 spec 合并（适合 infra / tooling / 纯文档改动） |
| `--no-validate` | 跳过校验（会要求二次确认） |

### 示例

```bash
openspec archive                        # 交互式
openspec archive add-dark-mode          # 指定
openspec archive add-dark-mode --yes    # CI 无人值守
openspec archive update-ci-config --skip-specs   # tooling 改动，specs 没变
```

### 内部顺序

1. 校验 change（除非 `--no-validate`）
2. 问确认（除非 `--yes`）
3. 合并 delta → `openspec/specs/`
4. 把 change 目录搬到 `openspec/changes/archive/YYYY-MM-DD-<name>/`

---

## `openspec feedback`

创建 GitHub issue 提反馈。

```
openspec feedback <message> [--body <text>]
```

**依赖**：需要 `gh` CLI 已安装并登录。

```bash
openspec feedback "Add support for custom artifact types" \
  --body "I'd like to define my own artifact types beyond the built-in ones."
```

---

## `openspec completion`

shell 自动补全。

```
openspec completion <subcommand> [shell]
```

| 子命令 | 说明 |
|--------|------|
| `generate [shell]` | 输出补全脚本到 stdout |
| `install [shell]` | 为当前 shell 安装 |
| `uninstall [shell]` | 卸载 |

支持 shell：`bash`、`zsh`、`fish`、`powershell`。

```bash
openspec completion install              # 自动识别 shell
openspec completion install zsh          # 指定 zsh
openspec completion generate bash > ~/.bash_completion.d/openspec
openspec completion uninstall
```

---

## 全局选项

| 选项 | 说明 |
|------|------|
| `--version`, `-V` | 版本号 |
| `--no-color` | 禁用彩色输出 |
| `--help`, `-h` | 帮助 |

## 环境变量

| 变量 | 作用 |
|------|------|
| `OPENSPEC_TELEMETRY` | 设为 `0` 关闭遥测 |
| `DO_NOT_TRACK` | 设为 `1` 关闭遥测（业界标准 DNT）|
| `OPENSPEC_CONCURRENCY` | `validate --all` 的默认并发数（默认 6）|
| `EDITOR` / `VISUAL` | `openspec config edit` 用的编辑器 |
| `NO_COLOR` | 禁用彩色输出 |
| `CODEX_HOME` | Codex adapter 把全局命令装到 `$CODEX_HOME/prompts/`，没设则用 `~/.codex/` |

## 退出码

| 码 | 含义 |
|----|------|
| `0` | 成功 |
| `1` | 错误（校验失败、文件缺失等） |
| `130` | `Ctrl+C` 取消 `openspec config profile`（特殊约定） |
