# 04 · Schema 解析优先级

> 回 [导读](00-map.md)

OpenSpec 需要确定"用哪个 schema"时，走两层解析。理解这两层是避免"改了配置但没生效"这类问题的关键。

---

## 第一层：确定 schema 名字

用户创建 change 或执行 workflow 命令时，按以下优先级确定用哪个 schema：

```
1. CLI 显式参数        --schema <name>
        ↓
2. Change 元数据       openspec/changes/<name>/.openspec.yaml 的 schema 字段
        ↓
3. Planning-home 默认   workspace 场景下默认用 workspace-planning
        ↓
4. 项目 config         openspec/config.yaml 的 schema 字段
        ↓
5. 硬编码默认          spec-driven
```

### 具体例子

**情况 1：显式指定了 schema**
```bash
openspec new change my-feature --schema tdd
# → 用 tdd，忽略所有其他配置
```

**情况 2：change 已有 .openspec.yaml**
```yaml
# openspec/changes/my-feature/.openspec.yaml
schema: rapid
created: 2026-04-20
```
```bash
openspec continue my-feature
# → 用 rapid（从 .openspec.yaml 读）
```

**情况 3：在 workspace 里创建 change**
```bash
# 在 workspace planning home 下
openspec new change cross-repo-feature
# → 用 workspace-planning（planning-home 默认优先于项目 config）
```

**情况 4：只用项目 config**
```yaml
# openspec/config.yaml
schema: spec-driven
```
```bash
openspec new change my-feature
# → 用 spec-driven
```

**情况 5：什么都没配置**
```bash
openspec new change my-feature
# → 用 spec-driven（硬编码默认）
```

---

## 第二层：确定 schema 文件从哪里加载

确定 schema 名字后（比如 `my-workflow`），按以下优先级查找实际文件：

```
1. 项目级        openspec/schemas/my-workflow/schema.yaml
       ↓
2. 用户级        ~/.local/share/openspec/schemas/my-workflow/schema.yaml
       ↓
3. 包内置        <npm-package>/schemas/my-workflow/schema.yaml
```

### 影子覆盖（Shadowing）

如果同名 schema 存在于多个位置，高优先级的会**覆盖**（shadow）低优先级的：

```bash
openspec schema which spec-driven
# 如果项目里 openspec/schemas/spec-driven/ 存在：
# spec-driven resolves from: project
#   Source: /path/to/project/openspec/schemas/spec-driven
#   Shadows: package (/usr/local/lib/.../schemas/spec-driven)

# 如果项目里没有：
# spec-driven resolves from: package
#   Source: /usr/local/lib/node_modules/@fission-ai/openspec/schemas/spec-driven
```

---

## 查看解析结果

```bash
# 看单个 schema 从哪解析的
openspec schema which spec-driven

# 列出所有 schema 及其来源
openspec schema which --all

# JSON 格式（给脚本用）
openspec schema which spec-driven --json
```

来源有三种标签：
- **project** — `openspec/schemas/<name>/`
- **user** — `~/.local/share/openspec/schemas/<name>/`
- **package** — npm 包内置

---

## 为什么这样设计

| 优先级 | 设计意图 |
|--------|---------|
| 项目最高 | 团队对仓库内的工作流有完全控制权 |
| 用户次之 | 个人偏好的 schema 可跨项目复用 |
| 包最低 | 保证总有一个可用的兜底（spec-driven） |

---

## 实战建议

| 你的场景 | 推荐做法 |
|---------|---------|
| 整个团队统一工作流 | 放在项目级 `openspec/schemas/`，随 git 版本化 |
| 个人偏好、跨项目复用 | 放在用户级 `~/.local/share/openspec/schemas/` |
| 贡献回社区 | 发 PR 到 OpenSpec 的 `schemas/` 目录 |

---

## 常见陷阱

1. **改了 config.yaml 的 schema 字段，但已有 change 不受影响** — 因为已有 change 的 `.openspec.yaml` 优先级更高
2. **项目里 fork 了 spec-driven，但没改内容，结果仍然是 spec-driven 行为** — shadow 不会改变行为，除非你实际编辑了 schema.yaml
3. **在 workspace 里创建 change 却用了 spec-driven** — 检查是否在 workspace planning home 下，planning-home 默认会走 workspace-planning
