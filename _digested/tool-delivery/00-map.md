# Tool Delivery 地图

## 一句话

OpenSpec 的稳定资产是 workflow 语义；skills 和 commands 是把这些语义交给不同 coding agent 的外壳。

```text
profile/workflows
  → getSkillTemplates()/getCommandContents()
  → generateSkillContent()/generateCommands()
  → per-tool skillsDir / command adapter path
  → agent 可发现的入口文件
```

## 三层对象

| 层 | 源码 | 作用 |
|----|------|------|
| tool registry | `AI_TOOLS` in `src/core/config.ts` | 工具 id、skillsDir、检测路径 |
| workflow content | `src/core/templates/workflows/`、`src/core/shared/skill-generation.ts` | 工具无关的 workflow 指令 |
| tool-specific shell | `src/core/command-generation/adapters/` | command 文件路径和 frontmatter 格式 |

## 关键命令

| 命令 | 投递职责 |
|------|----------|
| `openspec init` | 创建 repo-local OpenSpec 根并安装 selected tools 的 workflow 入口 |
| `openspec update` | 根据当前 profile/delivery 同步已配置工具 |
| `openspec workspace update` | 在 workspace root 安装 skills-only workflow 入口 |

## 测试锚点

- `test/core/init.test.ts`
- `test/core/update.test.ts`
- `test/core/command-generation/`
- `test/core/shared/`
- `test/core/profile-sync-drift.test.ts`
- `test/core/migration.test.ts`
- `test/core/legacy-cleanup.test.ts`
