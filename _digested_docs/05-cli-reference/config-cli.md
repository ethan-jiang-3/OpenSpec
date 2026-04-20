# CLI · Config 命令

`openspec config` 及其子命令管理**全局**（用户级）OpenSpec 配置。源码 [src/commands/config.ts](../../src/commands/config.ts)。

> 全局 config 和**项目 config**（`openspec/config.yaml`）不是一回事。项目 config 见 [07-customization/project-config.md](../07-customization/project-config.md)。

## 子命令总表

| 子命令 | 作用 |
|--------|------|
| `path` | 显示 config 文件位置 |
| `list` | 列出所有当前设置 |
| `get <key>` | 获取单个值 |
| `set <key> <value>` | 设置值 |
| `unset <key>` | 删除 key |
| `reset` | 重置默认 |
| `edit` | 用 `$EDITOR` 打开编辑 |
| `profile [preset]` | 交互式或预设配置 profile |

## 常用示例

```bash
# 查看 config 文件路径
openspec config path

# 列出所有设置
openspec config list

# 读取某个值
openspec config get telemetry.enabled

# 关掉遥测
openspec config set telemetry.enabled false

# 字符串值要显式
openspec config set user.name "My Name" --string

# 删自定义值
openspec config unset user.name

# 重置全部
openspec config reset --all --yes

# 编辑器打开
openspec config edit
```

## 重点：`openspec config profile`

这是配置 **workflow 选择** + **delivery 模式** 的入口。

### 交互式

```bash
openspec config profile
```

进入后按菜单：
1. **Change delivery + workflows** — 都改
2. **Change delivery only** — 只改 delivery 模式（both / skills / commands）
3. **Change workflows only** — 只勾选要启用哪些 workflow
4. **Keep current settings** — 退出不改

`Ctrl+C` 可以干净退出（exit code 130，无 stack trace）。

### 预设快捷

```bash
# 直接切到 core（4 个 workflow，不动 delivery）
openspec config profile core
```

### 工作流勾选 UI

进入 workflow checklist 时，`[x]` 表示**已在全局 config 里启用**。切换后要真正生效，还得 `openspec update` 去项目里重生成文件，否则会 drift（drift 检测代码在 [src/core/profile-sync-drift.ts](../../src/core/profile-sync-drift.ts)）。

### 偏好三种 delivery

| delivery 值 | 装什么 |
|-------------|--------|
| `both`（默认） | skills + commands 都装 |
| `skills` | 只装 skills |
| `commands` | 只装 commands |

## ALL_WORKFLOWS 的 11 个可勾选值

- `propose`、`explore`、`apply`、`archive`（core 默认含）
- `new`、`continue`、`ff`、`sync`、`bulk-archive`、`verify`、`onboard`（扩展）

定义在 [src/core/profiles.ts](../../src/core/profiles.ts)。
