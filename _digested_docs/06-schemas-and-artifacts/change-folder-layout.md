# Change 目录结构

每个 change 是一个**自包含的文件夹**，放在 `openspec/changes/<name>/`。

## 典型结构（`spec-driven` schema）

```
openspec/changes/add-dark-mode/
├── .openspec.yaml           # change 元数据（可选）
├── proposal.md              # Why + What + Capabilities + Impact
├── design.md                # How（技术方案）
├── tasks.md                 # 可勾选的实施清单
└── specs/                   # Delta spec，按 domain 分子目录
    └── ui/
        └── spec.md          # 只写本次改动的 delta
```

## `.openspec.yaml` 元数据

Change 级别的可选配置文件，告诉 OpenSpec 用哪个 schema、什么时候创建的：

```yaml
schema: spec-driven        # 要用哪个 schema（可以覆盖项目默认）
created: 2025-01-23        # 创建日期
```

**优先级**：`.openspec.yaml` 的 `schema` > 项目 `openspec/config.yaml` 的 `schema` > `spec-driven`。

完整优先级链见 [07-customization/schema-resolution-order.md](../07-customization/schema-resolution-order.md)。

## `specs/` 按 domain 分目录

每个 delta spec 按 **capability / domain** 分子目录：

```
specs/
├── auth/
│   └── spec.md             # 认证相关的改动
├── ui/
│   └── spec.md             # UI 改动
└── payments/
    └── spec.md
```

domain 名字要和 `openspec/specs/<domain>/` **完全匹配**，因为 archive 时会按名字合并。新 capability 用 kebab-case（`user-auth`、`data-export`）。

## 一个 change 可能缺少某些 artifact

- 简单改动**不需要 design.md**（schema instruction 明确说：只在必要时建）
- 纯 tooling / 文档改动**不需要 specs/**（用 `openspec archive --skip-specs`）
- 所有 artifact 都是按 schema 定义生成的；缺哪个就对应 artifact 处于 `ready` 或 `blocked` 状态

## Archive 后去哪里

归档后整个 change 目录搬到：

```
openspec/changes/archive/2025-04-20-add-dark-mode/
├── proposal.md              # 全部 artifact 保留
├── design.md
├── tasks.md
└── specs/
    └── ui/
        └── spec.md
```

前缀 `YYYY-MM-DD-` 保证按时间排序。这时 delta spec 的内容已经 merge 到 `openspec/specs/ui/spec.md` 了（除非用了 `--skip-specs`）。

## 顶层 `openspec/` 目录

完整结构：

```
openspec/
├── specs/                   # 主规格（source of truth）
│   └── <domain>/
│       └── spec.md
├── changes/                 # 进行中的 change
│   ├── add-dark-mode/
│   ├── fix-login-bug/
│   └── archive/             # 已归档的 change
│       ├── 2025-01-20-add-auth/
│       └── 2025-01-22-fix-session/
├── schemas/                 # 自定义 schema（可选）
│   └── my-workflow/
│       ├── schema.yaml
│       └── templates/
└── config.yaml              # 项目 config（可选）
```
