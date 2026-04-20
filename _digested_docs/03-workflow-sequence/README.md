# 03 · 工作流次序

OPSX 的命令不是随便排的——它们分成两档 **profile**，每档决定了「你能看到哪些 `/opsx:*` 命令」。

## 两档 profile

源码定义：[src/core/profiles.ts](../../src/core/profiles.ts)

```ts
export const CORE_WORKFLOWS = ['propose', 'explore', 'apply', 'archive'] as const;

export const ALL_WORKFLOWS = [
  'propose', 'explore',
  'new', 'continue', 'apply', 'ff',
  'sync', 'archive', 'bulk-archive',
  'verify', 'onboard',
] as const;
```

| Profile | 包含 workflow | 适用人群 |
|---------|--------------|----------|
| **core**（默认） | `propose` / `explore` / `apply` / `archive` | 刚上手 / 大多数场景 |
| **custom** | 任意子集（最多 11 个） | 想要精细控制 / 批量归档 / 做 onboarding |

## 如何切换

```bash
# 交互式切换 profile + 勾选 workflow
openspec config profile

# 快速切回 core
openspec config profile core

# 切换后刷新项目
openspec update
```

`openspec config profile` 进入后有四个动作：
1. 改 delivery（both / skills / commands）+ workflows
2. 只改 delivery
3. 只改 workflows
4. 什么都不改（退出）

## 本目录其它文档

- [sequence-diagrams.md](sequence-diagrams.md) — 流程图（mermaid）
- [when-to-use-what.md](when-to-use-what.md) — 决策树：ff vs continue、update vs new change
