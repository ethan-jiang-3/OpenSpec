# Shell Completion

## 四层结构

```text
COMMAND_REGISTRY
  → shell generator
  → completion script
  → installer writes shell-specific location/config
```

另有 hidden command：

```text
openspec completion __complete <type>
```

给 shell script 动态获取 change/spec/schema 等候选。

## command registry

`src/core/completions/command-registry.ts` 是 completion 的命令模型，不是 commander runtime 自动导出。

它手写维护：

- command name
- description
- positional 参数
- flags
- subcommands
- flag value candidates

风险：CLI 新增/改名时，如果 registry 不同步，completion 会漂移。

## CompletionProvider

`CompletionProvider` 提供动态候选：

- active change ids
- spec ids
- schema names

它有 2 秒 TTL cache，避免用户按 Tab 时频繁扫文件系统。

## generators

`src/core/completions/generators/` 为不同 shell 生成脚本：

- bash
- zsh
- fish
- powershell

生成器消费同一个 `COMMAND_REGISTRY`，但脚本语法完全不同。

## installers

`src/core/completions/installers/` 负责安装/卸载：

- 写 completion script。
- 必要时更新 shell profile。
- 创建 backup。
- 返回 warnings/instructions。

安装器是最容易碰到用户环境差异的地方，尤其是 zsh/oh-my-zsh、PowerShell profile、bashrc/profile 的差异。

## completion command

`CompletionCommand` 提供：

- `generate [shell]`
- `install [shell]`
- `uninstall [shell]`
- hidden `__complete <type>`

它先通过 `detectShell()` 自动检测 shell；检测不到或不支持时要求用户显式传 shell。
