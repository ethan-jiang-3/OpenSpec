# CLI Infra 地图

## 一句话

CLI infra 是 OpenSpec 的“周边但全局”层：它不定义 artifact DAG，但影响命令发现、shell 体验、遥测、反馈、路径处理、交互选择和 JSON 转换。

## 覆盖范围

| 子系统 | 路径 |
|--------|------|
| shell completion | `src/core/completions/`、`src/commands/completion.ts` |
| shell detection | `src/utils/shell-detection.ts` |
| telemetry | `src/telemetry/` |
| feedback | `src/commands/feedback.ts`、`src/core/templates/workflows/feedback.ts` |
| interactive prompts | `src/prompts/`、`src/ui/` |
| utility modules | `src/utils/` |
| converter | `src/core/converters/json-converter.ts` |

## 测试锚点

- `test/core/completions/`
- `test/commands/completion.test.ts`
- `test/telemetry/`
- `test/commands/feedback.test.ts`
- `test/prompts/`
- `test/utils/`
- `test/core/converters/`
