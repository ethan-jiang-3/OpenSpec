# CLI · Schema 管理

管理**自定义 workflow schema** 的四个子命令。源码在 [src/commands/schema.ts](../../src/commands/schema.ts)。

关于 schema 是什么、怎么写，见 [07-customization/custom-schemas.md](../07-customization/custom-schemas.md)。

---

## `openspec schema init`

从零创建一个项目 schema。

```
openspec schema init <name> [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--description <text>` | schema 描述 |
| `--artifacts <list>` | 逗号分隔的 artifact ID（默认 `proposal,specs,design,tasks`）|
| `--default` | 设为项目默认 schema |
| `--no-default` | 不问设为默认 |
| `--force` | 覆盖已存在的 schema |
| `--json` | JSON 输出 |

### 示例

```bash
# 交互式
openspec schema init research-first

# 非交互 + 指定 artifact + 设为默认
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

### 产物

```
openspec/schemas/<name>/
├── schema.yaml
└── templates/
    ├── proposal.md
    ├── specs.md
    ├── design.md
    └── tasks.md
```

---

## `openspec schema fork`

复制一份已有 schema 做定制。

```
openspec schema fork <source> [name] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--force` | 覆盖目标 |
| `--json` | JSON 输出 |

### 示例

```bash
# fork 内置 spec-driven 到项目里
openspec schema fork spec-driven my-workflow

# 不指定新名字时默认 <source>-custom
openspec schema fork spec-driven
# → 产出 spec-driven-custom
```

---

## `openspec schema validate`

校验 schema 的 YAML 结构 + 模板引用是否齐全。

```
openspec schema validate [name] [options]
```

### 选项

| 选项 | 说明 |
|------|------|
| `--verbose` | 打印详细校验步骤 |
| `--json` | JSON 输出 |

### 示例

```bash
# 校验指定 schema
openspec schema validate my-workflow

# 不带名字 = 校验所有 schema
openspec schema validate
```

校验内容：
- `schema.yaml` 语法对不对
- 每个 `template` 字段指向的文件是否存在
- 有没有循环依赖
- artifact ID 合法

---

## `openspec schema which`

看某个 schema 从哪个来源解析出来的，用来调试优先级问题。

```
openspec schema which [name] [--all] [--json]
```

### 示例

```bash
# 看单个
openspec schema which spec-driven

# 列出全部 schema 和它们的来源
openspec schema which --all
```

### 输出

```
spec-driven resolves from: package
  Source: /usr/local/lib/node_modules/@fission-ai/openspec/schemas/spec-driven
```

来源三种：
1. **project** — `openspec/schemas/<name>/`（最高优先级）
2. **user** — `~/.local/share/openspec/schemas/<name>/`
3. **package** — npm 包内置

详见 [07-customization/schema-resolution-order.md](../07-customization/schema-resolution-order.md)。
