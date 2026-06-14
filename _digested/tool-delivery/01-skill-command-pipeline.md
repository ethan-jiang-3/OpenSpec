# Skill / Command Pipeline

## workflow template 是源头

workflow 文本来自 `src/core/templates/workflows/`。每个 workflow 通常同时导出：

- skill template：给 agent 自动发现。
- command template：给 slash/prompt command 文件。

`src/core/shared/skill-generation.ts` 把这些模板统一映射成两类表：

- `getSkillTemplates(workflowFilter?)`
- `getCommandTemplates(workflowFilter?)`

filter 来自 profile resolved workflow ids。

## skill 生成链

```text
SkillTemplate
  → generateSkillContent(template, version, transform?)
  → YAML frontmatter + instructions
  → <tool skillsDir>/skills/<dirName>/SKILL.md
```

frontmatter 包含：

- `name`
- `description`
- `license`
- `compatibility`
- metadata author/version/generatedBy

OpenCode/Pi 等工具会传入 `transformToHyphenCommands`，把模板里的 command references 改成对应工具习惯。

## command 生成链

```text
CommandTemplate
  → CommandContent
  → CommandAdapterRegistry.get(toolId)
  → generateCommands()
  → adapter.getFilePath(id)
  → adapter.formatFile(content)
```

`CommandContent` 是工具无关结构：

- `id`
- `name`
- `description`
- `category`
- `tags`
- `body`

adapter 只处理“放在哪里”和“外壳怎么写”，不改 workflow 语义。

## delivery 分流

repo-local init/update 根据 global config 的 `delivery` 分流：

| delivery | 行为 |
|----------|------|
| `skills` | 只生成 skills，并删除 managed commands |
| `commands` | 只生成 commands，并删除 managed skills |
| `both` | 两者都生成 |

workspace update 是例外：当前只生成 skills，即使 global delivery 是 `both` 或 `commands`，也会给出 skills-only notice。

## 工具检测

`AI_TOOLS` 定义每个工具：

- `value`
- `name`
- `skillsDir`
- `detectionPaths`
- display labels

`getAvailableTools()` 会根据项目中已存在的工具目录/检测路径推断可预选工具。检测只是辅助选择，不是 workflow source of truth。
