# Command Adapters

## adapter interface

`ToolCommandAdapter` 只有两个核心方法：

```ts
getFilePath(commandId: string): string
formatFile(content: CommandContent): string
```

这说明 adapter 不参与 workflow 推理，也不参与 artifact 状态判断。它只负责 tool-specific command surface。

## registry

`CommandAdapterRegistry` 是静态 registry：

- 启动时注册所有内置 adapter。
- `get(toolId)` 返回对应 adapter。
- 没有 adapter 的工具仍可通过 skills 支持。

这就是为什么有些工具能安装 skills 但不生成 command 文件。

## 典型差异

### Claude

`claudeAdapter`：

```text
.claude/commands/opsx/<id>.md
```

frontmatter 包含：

- `name`
- `description`
- `category`
- `tags`

它还会转义 YAML 特殊字符，避免 command metadata 破坏 frontmatter。

### Codex

`codexAdapter`：

```text
<CODEX_HOME>/prompts/opsx-<id>.md
```

这是绝对路径、全局 prompt 位置，不是项目内文件。`CODEX_HOME` 可覆盖默认 `~/.codex`。

这个差异很重要：并不是所有 command artifacts 都在 repo root 下。

## adapter 维护风险

新增或修改 adapter 时，要同时考虑：

- `AI_TOOLS` 是否注册该工具和 skillsDir。
- adapter 是否在 registry 里注册。
- command 文件是否带正确 frontmatter。
- update 是否能删除不再选择的 managed command。
- 测试是否覆盖路径和格式。

## 与 skill 的关系

skill generation 是统一 frontmatter；command generation 是 adapter-specific frontmatter。两者都来自同一套 workflow 内容，但面向不同发现机制。
