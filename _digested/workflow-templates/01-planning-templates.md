# Planning Templates

## propose

`propose` 是默认 quick path：创建 change，并持续生成 artifact，直到 schema 的 apply requirements 满足。

模板关键点：

- 从用户输入推导 change name。
- 调 `openspec new change`。
- 调 `status` 找 ready artifact。
- 对 ready artifact 调 `instructions`。
- 写完 artifact 后重新 status。
- 直到 ready for apply。

它适合“用户已经有比较明确意图，想快速得到完整规划”。

## new

`new` 只创建 change scaffold，不生成 artifact 内容。

它适合：

- 想先占位。
- 想手动/逐步推进。
- 想显式选择 schema 或 initiative linkage。

它把“创建实例”和“生成内容”拆开。

## continue

`continue` 是 incremental path：每次只推进一个 ready artifact。

模板关键点：

- 如果 change 不明确，先 `list --json` 让用户选。
- `status --json` 找 ready artifacts。
- 选择下一个 ready artifact。
- `instructions <artifact> --json` 获取执行包。
- 写文件后报告下一步。

它体现 artifact DAG 的增量工作流。

## ff

`ff` 是 fast-forward path：批量生成剩余 artifact。

它和 `propose` 相似，但语义更偏“已有 change，快速补齐剩余规划”。它通常从 active change 开始，而不是总是创建新 change。

## 四者边界

| workflow | 创建 change | 生成 artifact | 粒度 |
|----------|-------------|---------------|------|
| `propose` | 会 | 会，直到可 apply | 快速完整 |
| `new` | 会 | 不会 | scaffold |
| `continue` | 不一定 | 一次一个 | 增量 |
| `ff` | 可用于已有 change | 多个 | 批量推进 |

这四个模板共同解释了 OPSX “动作而非阶段”的体验。
