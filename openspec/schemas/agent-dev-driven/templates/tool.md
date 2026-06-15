# [工具名]

## 签名

- **名称**：`[tool-name]`
- **入参**：
```json
{ "param": "type", "…": "…" }
```
- **返回**：[JSON 结构 / exit code / stdout 格式]

## 行为

[这个工具做什么——一句话]

## 副作用

| 类型 | 详情 |
|------|------|
| 文件读写 | [是/否 — 路径或范围] |
| 网络调用 | [是/否 — endpoint] |
| 状态变更 | [是/否 — 什么状态] |

## OpenSpec CLI 依赖（如果有）

| 调用的命令 | 时机 | 失败处理 |
|-----------|------|---------|
| `openspec status --json` | [什么时候调] | [失败了怎么做] |
| … | … | … |

## 被以下 skill/command 使用

- `skills/[skill].md` → [使用场景]
- `commands/[command].md` → [使用场景]

## harness 适配差异

| harness | 文件位置 | frontmatter/外壳差异 |
|---------|---------|---------------------|
| OpenSpec | `.claude/skills/[name]/` | YAML frontmatter `--- name/description ---` |
| Claude Code | `.claude/tools/` | 直接 Markdown，无 frontmatter |
| … | … | … |
