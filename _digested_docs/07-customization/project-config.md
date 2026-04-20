# 项目配置：`openspec/config.yaml`

这是最轻量的定制方式——不用自己写 schema，只通过配置文件往 AI 的提示里注入**项目上下文**和**per-artifact 规则**。

文件位置：`<your-project>/openspec/config.yaml`（`.yml` 不行，必须 `.yaml`）。

## 三个字段

```yaml
# openspec/config.yaml
schema: spec-driven           # 默认 schema

context: |
  Tech stack: TypeScript, React, Node.js
  API conventions: RESTful, JSON responses
  Testing: Vitest for unit tests, Playwright for e2e
  Style: ESLint with Prettier, strict TypeScript

rules:
  proposal:
    - Include rollback plan
    - Identify affected teams
  specs:
    - Use Given/When/Then format for scenarios
  design:
    - Include sequence diagrams for complex flows
```

| 字段 | 类型 | 作用 |
|------|------|------|
| `schema` | string | 新 change 默认用哪个 schema |
| `context` | string | 所有 artifact 共用的项目上下文 |
| `rules` | object | 按 artifact id 分组的额外规则 |

## 注入机制

当 agent 调 `openspec instructions <artifact>` 拿提示时，返回内容按这个结构拼：

```xml
<context>
Tech stack: TypeScript, React, Node.js
...（来自 config.yaml 的 context）
</context>

<rules>
- Include rollback plan
- Identify affected teams
...（只注入匹配当前 artifact id 的 rules）
</rules>

<template>
[schema 的 built-in 模板]
</template>
```

- **`context` 对所有 artifact 都注入**
- **`rules` 只对匹配 artifact id 的注入**（`rules.proposal` 只给 proposal 用）

## 限制和校验

| 规则 | 说明 |
|------|------|
| `context` 最大 50KB | 超了要摘要或拆到外部文档 |
| 未知的 artifact id 在 `rules` | 产生 warning（不报错） |
| schema 名字 | 会按 schema resolution 顺序查，找不到报错 |
| YAML 语法错误 | 会带行号 |

## 支持的 artifact id（`spec-driven` schema）

- `proposal`
- `specs`
- `design`
- `tasks`

用 `openspec schemas --json` 看其它 schema 的 artifact id。

## 怎么创建

```bash
# 方法 1：init 时交互创建
openspec init
# 会问要不要建 config，按提示填

# 方法 2：手动写
cat > openspec/config.yaml <<EOF
schema: spec-driven
context: |
  Tech stack: ...
rules:
  proposal:
    - ...
EOF
```

**改动立即生效**，不需要重启 agent 或 `openspec update`。

## 排查

| 症状 | 原因 |
|------|------|
| `Unknown artifact ID in rules: X` | 检查 artifact id 是否匹配 schema；用 `openspec schemas --json` 看 |
| config 没生效 | 确认文件叫 `config.yaml` 不是 `.yml` |
| context 太大 | 压到 50KB 以内 |

## 和**全局**（`openspec config`）配置的区别

| 层级 | 存哪里 | 控制什么 |
|------|--------|---------|
| **项目 config** | `openspec/config.yaml` | schema / context / rules（注入到提示） |
| **全局 config** | 用户目录（`openspec config path` 看） | profile / delivery / 选哪些 workflow / 遥测 |

两者**正交**，都要掌握。
