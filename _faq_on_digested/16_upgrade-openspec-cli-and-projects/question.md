# 问题：OpenSpec 整体怎么升级？升级完全局 CLI 之后，每个项目里还要做什么？

OpenSpec 有两层东西都要升级，但它们不是一个动作：

1. **全局 CLI 本身**（PATH 上的 `openspec` 可执行文件）——它决定你能用哪些命令和参数（例如 v1.10.0 的 `init --language`、`--tools zed`、completion tip，v1.9.0 的 `--tools command-code` / `validate --archived`，以及 v1.8.0 的 `--tools agents` / `retire_capabilities`，旧 CLI 根本没有）。
2. **每个项目里的投递产物**——`openspec init` / `openspec update` 往 `.claude/`、`.agents/`、`.cursor/` 等工具目录里生成的 skills/commands。这些文件是 CLI **用自己的模板**生成的，旧 CLI 生成的文件不会包含新工具、新 workflow 或新语义。

困惑点：
- 是不是跑一个 `openspec upgrade` 就全搞定了？（我看到似乎没有这个命令）
- 全局 CLI 升级后，为什么每个项目还要再动一次？跑 `openspec init` 还是 `openspec update`？
- 如果我在 CI / 非交互环境 / 用 npx 跑，升级命令是不是不一样？
- 升级全局 CLI 之后，项目里那些 `.codex` 旧文件（v1.8.0 已迁到 `.agents`）是怎么被处理掉的？
