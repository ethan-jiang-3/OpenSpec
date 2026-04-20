# CLI · 浏览 & 校验

## `openspec list`

列 change 或 spec。

```
openspec list [--specs|--changes] [--sort recent|name] [--json]
```

- 不加选项默认列 change
- `--sort recent`（默认）按修改时间；`--sort name` 按字母

```bash
openspec list                     # 当前 active 的 change
openspec list --specs             # 所有 spec
openspec list --json              # 给脚本用
```

输出示例（text）：
```
Active changes:
  add-dark-mode     UI theme switching support
  fix-login-bug     Session timeout handling
```

---

## `openspec view`

**交互式**终端仪表盘，按键浏览 spec 和 change。纯人类用，没有 `--json`。

```
openspec view
```

---

## `openspec show`

查看一个 change 或 spec 的详情。

```
openspec show [item-name] [options]
```

### 通用选项

| 选项 | 说明 |
|------|------|
| `--type <type>` | `change` 或 `spec`（不写会猜） |
| `--json` | JSON 输出，给 AI/脚本 |
| `--no-interactive` | 禁用交互提示 |

### Change 专用

| 选项 | 说明 |
|------|------|
| `--deltas-only` | 只返回 delta specs（JSON 模式） |

### Spec 专用

| 选项 | 说明 |
|------|------|
| `--requirements` | 只返回 requirements，不含 scenario |
| `--no-scenarios` | 返回 requirement 但不含 scenario 正文 |
| `-r, --requirement <id>` | 按 1-based 索引返回指定 requirement |

### 示例

```bash
openspec show                           # 交互式选择
openspec show add-dark-mode             # 指定 change
openspec show auth --type spec          # 指定 spec
openspec show add-dark-mode --json      # JSON 给 agent
```

---

## `openspec validate`

校验 change 和 spec 的结构问题。

```
openspec validate [item-name] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--all` | 校验所有 change + spec |
| `--changes` | 只校验所有 change |
| `--specs` | 只校验所有 spec |
| `--type <change|spec>` | 名字有歧义时指定类型 |
| `--strict` | 严格模式 |
| `--json` | JSON 输出 |
| `--concurrency <n>` | 并行度（默认 6，或 `OPENSPEC_CONCURRENCY` 环境变量） |
| `--no-interactive` | 禁用提示 |

### 示例

```bash
# 交互式
openspec validate

# 校验单个 change
openspec validate add-dark-mode

# 校验所有 change
openspec validate --changes

# 全校验 + JSON（CI 常用）
openspec validate --all --json

# 严格模式 + 12 并发
openspec validate --all --strict --concurrency 12
```

### 输出（JSON 样例）

```json
{
  "version": "1.0.0",
  "results": {
    "changes": [
      {
        "name": "add-dark-mode",
        "valid": true,
        "warnings": ["design.md: missing 'Technical Approach' section"]
      }
    ]
  },
  "summary": { "total": 1, "valid": 1, "invalid": 0 }
}
```
