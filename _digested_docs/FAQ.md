# 常见困惑 · FAQ

把第一次接触 OpenSpec 最容易卡壳的几个问题集中在这里，每个都给**直接答案 + 一句解释 + 深读链接**。

> 想找具体命令/路径，直接去 [00-index.md](00-index.md)。这里只解决"困惑"。

---

## Q1: OpenSpec 自己又不带 LLM，它怎么"做 AI 编程"？

**答**：它**借用**你装的 coding agent（Claude / Cursor / Cline...）里的 LLM。

OpenSpec 是个**纯文件 + JSON API** 的 CLI（grep 整个 src/ 搜 `openai|anthropic|llm` 零结果）。它的角色是"prompt 编排器 + 状态管理"：

```text
用户 ──── /opsx:propose ────→ Coding Agent (有 LLM)
                                    │
                        读 .commands/opsx-propose.md
                                    │
                       照着指示调 OpenSpec CLI 拿 JSON
                                    │
                              ↓ 这步的 JSON：
                  openspec instructions proposal --json
                  → { template, instruction, context, rules, dependencies }
                                    │
                          Agent 把 JSON 拼成 prompt
                          → 喂给自己的 LLM
                          → 拿到生成的 markdown
                          → 写到 OpenSpec 指定路径
```

**关键事实**：OpenSpec 全程**只做 IO 和模板拼装，不调任何 LLM**。

→ 详细握手流程：[06-agent-protocol.md §0](06-agent-protocol.md#0-openspec-怎么借用宿主-coding-agent-的-llm)

---

## Q2: `openspec-propose` 和 `OPSX` 是同一个东西吗？

**答**：是同一套 workflow 的两种入口名字，**功能完全一样**。

| 名字前缀 | 是什么 | 谁用 |
|---------|--------|------|
| `openspec-...` | **skill 目录名**（长名带 `-change` 后缀） | LLM 自动发现；Trae/ForgeCode 当命令名用 |
| `opsx-...` 或 `opsx:...` | **斜杠命令名**（短名）| 用户手动键入 |

例子对照：

| OPSX 短名 | Claude 命令 | Trae 命令 |
|-----------|-------------|-----------|
| `apply` | `/opsx:apply` | `/openspec-apply-change` |
| `propose` | `/opsx:propose` | `/openspec-propose` |
| `archive` | `/opsx:archive` | `/openspec-archive-change` |

→ 详细对照：[05-usage-advanced.md §4](05-usage-advanced.md#4-openspec--vs-opsx--前缀之辨)

---

## Q3: 装上 OpenSpec 之后，AI 会不会平时就主动跳出来烦我？

**答**：分两层看：
- **斜杠命令** (`.commands/opsx-*.md`)：100% 按需，不打 `/opsx-...` 永远不加载
- **Skills** (`SKILL.md`)：**视 agent 而定**：
  - **Claude Code**：⚠️ 唯一会基于 SKILL 的 description 在合适时机**主动注入**到对话上下文
  - **Trae / ForgeCode**：skill 出现在斜杠命令面板，必须主动选才跑
  - **Cursor / Cline / OpenCode / 大多数 CLI**：装着不会自动加载

**想要"装上不用就完全没存在感"**：

```bash
openspec config profile
# 选 Change delivery only → Commands only
```

这样**只装 commands、不装 SKILL.md**，纯靠斜杠命令触发。

→ 详细分档：[02-installation.md §7](02-installation.md#7-安装的副作用与触发模型)

---

## Q4: 我有些项目要 OpenSpec，有些不要——能完全隔离吗？

**答**：**完全可以**。OpenSpec 是项目级隔离的纯按需 CLI。

| 项目状态 | OpenSpec 在这个项目里的存在感 |
|---------|--------------------------|
| 跑过 `openspec init` | 有 `openspec/`、`.<tool>/skills/`、`.<tool>/commands/` |
| 没跑过 init | **完全为零**——不自动启动、不写文件、不开进程 |

**唯一例外**：选了 `codex` 工具会写**全局** `$CODEX_HOME/prompts/opsx-*.md`，影响所有 Codex 项目。**规避**：init 时别勾 codex。

**强隔离方案**（连全局 PATH binary 都不留）：

```bash
cd my-project
npx @fission-ai/openspec init --tools claude,cursor    # 用 npx，不全局装
```

→ 详细方案：[02-installation.md §3](02-installation.md#3-单项目隔离)

---

## Q5: `openspec init` 会装所有 28 个工具吗？

**答**：**不会，必须主动选**。三种触发方式：

```bash
openspec init                              # 弹多选框，预勾"已检测到的工具"
openspec init --tools claude,cursor        # CI 用，精确指定
openspec init --tools all                  # 真的想全装才用 all
openspec init --tools none                 # 只建 openspec/，跳过 skill/command
```

预勾逻辑：项目里有 `.claude/` 就预勾 Claude，有 `.cursor/` 就预勾 Cursor。所以一般 `openspec init` 自己会推荐你正在用的工具。

→ 详细安装路径表：[02-installation.md §6](02-installation.md#6-每个工具的安装路径)

---

## Q6: "Schema" 是什么？为啥 OpenSpec 要引入这个词？

**答**：schema = **一份用 YAML 写的"开发工作流定义文件"**，不是数据库 schema、不是 JSON Schema。

它定义：
- 一次 change 要产出哪些 artifact（proposal / specs / design / tasks 或自定义的）
- artifact 之间的依赖（DAG 边）
- 每种 artifact 用什么模板、什么 AI 指令生成

**为什么叫 schema**：借用了"schema = 形状契约"的语义——它定义"什么样的 change 文件夹算合法"。

**为什么引入**：把"工作流"从源码硬编码改成数据文件。**Legacy** 时代所有项目必须 `proposal → specs → design → tasks`；**现在**你可以写 `rapid.yaml`（只有 proposal+tasks）、`research-first.yaml`（先 research 再 proposal）等，多种工作流共存。

→ 详细解析（含 ASCII DAG 图）：[03-concepts.md §3](03-concepts.md#3-schema-是什么为什么这么叫)

---

## Q7: Skill 和 Command 有什么区别？

**答**：

| 维度 | Skill | Command |
|------|-------|---------|
| 文件 | `<tool>/skills/openspec-*/SKILL.md` | `<tool>/commands/opsx-*.md` |
| 命名 | `openspec-` 前缀，长名 | `opsx-` 或 `opsx:` 前缀，短名 |
| 触发 | LLM 在对话中**自动发现** | 用户**主动键入** `/...` |
| 必须有 | ✅ 28 个工具都装 | 仅有 command adapter 的 26 个工具 |
| 内容 | 给 LLM 当能力说明书 | 斜杠命令的 prompt 模板 |

简单说：**skill 是"使用手册"，command 是"快捷键"**，多数工具同时装两份。

→ 详细映射：[05-usage-advanced.md §3](05-usage-advanced.md#3-workflow--skill--command-三对映射)

---

## Q8: Profile（core / custom）和 Schema 是一回事吗？

**答**：**完全不是**，是两个正交概念。

| 维度 | Profile | Schema |
|------|---------|--------|
| 控制什么 | OpenSpec **CLI 命令**装多少个 | change 文件夹的**产物结构**长什么样 |
| 影响范围 | `init/update` 时生成多少个斜杠命令 | 每次 change 的 artifact 列表和依赖 |
| 例子 | `core` = 4 个命令；`custom` = 最多 11 个 | `spec-driven` = proposal+specs+design+tasks |
| 配置位置 | 全局 `~/.config/openspec/config.json` | 项目 `openspec/config.yaml` 的 `schema:` 字段 |

切换 profile = 改你工具栏里能看到的 `/opsx-*` 数量。
切换 schema = 改 change 文件夹里产出的文件类型。

---

## Q9: OpenSpec 装了之后会不会动我的 git 仓库？

**答**：**不会**。grep 全代码搜 `gitignore|hook|prePush|preCommit` 全部零结果。

具体清单：

| 项目 | 是否会动 |
|------|---------|
| 装 git hooks | ❌ |
| 改 `.gitignore` | ❌ |
| 改 `package.json` | ❌ |
| 装 IDE 插件 | ❌ |
| 起后台 daemon | ❌ |
| 改 shell 配置 | ❌（`openspec completion install` 是可选的，要你自己跑）|
| **写文件到项目内** | ✅（`openspec/`、`.<tool>/skills/`、`.<tool>/commands/`）|
| **写文件到全局** | ⚠️ 仅 Codex（`$CODEX_HOME/prompts/`）|

要不要把 `openspec/` 加到 `.gitignore`？**通常不要**——openspec/ 是项目协作约定，应该 commit 进 git 让团队共享。skill/command 文件（`.claude/skills/...`）按团队习惯，commit 也行不 commit 也行。

---

## Q10: 不用 coding agent，纯命令行能用 OpenSpec 吗？

**答**：**能**，只是没"AI 自动生成"那一层。你可以：

- 手写 `proposal.md` / `specs/...` / `tasks.md`
- 跑 `openspec validate` 检查格式
- 跑 `openspec list` / `openspec show` 浏览
- 跑 `openspec archive` 归档

把 OpenSpec 当成 **spec 模板系统 + change 状态机** 用，agent 只是"加速器"不是必需品。

也可以**接自己的 LLM pipeline**：跑 `openspec instructions <id> --json` 拿到结构化 prompt，自己调 OpenAI/Anthropic API，把返回写到 JSON 里给的 `outputPath`。

→ 详细原理：[06-agent-protocol.md §0](06-agent-protocol.md#0-openspec-怎么借用宿主-coding-agent-的-llm)

---

## Q11: 我装了 28 个工具的 skill 会不会污染 IDE / agent 列表？

**答**：**只有你勾选的工具被装**，不会一锅端。即使你 `--tools all`：

- 每个工具的文件**只装到自己的目录**（`.claude/` 不会污染 `.cursor/`）
- 工具之间互相看不到对方的 skill/command
- 你删某个工具的目录，其它工具的 OpenSpec 集成不受影响

**实际推荐**：项目里**只装你团队真在用的工具**，比如 `--tools claude,cursor`，别贪全。

---

## Q12: `/opsx:propose` 之后 AI 卡住或生成的不对怎么办？

**答**：分两个锅看。

**锅 1：OpenSpec 给的 prompt 不对** —— 自己跑一遍看输出：

```bash
openspec instructions proposal --change my-change --json
```

如果 `template` / `instruction` / `context` / `rules` / `dependencies` 字段里有不对的，去对应位置改：
- `template` 不对 → 改 `openspec/schemas/<name>/templates/proposal.md`（或 fork 一个 schema）
- `context` 不对 → 改 `openspec/config.yaml` 的 `context` 字段
- `rules` 不对 → 改 `openspec/config.yaml` 的 `rules.<artifact>` 字段

**锅 2：LLM 不听话** —— 这是 agent 的事，OpenSpec 只能给材料：
- 换更聪明的模型
- 在 config 的 rules 里加更明确的约束
- 在 explore 阶段先 `/opsx:explore` 把需求理清

→ 详细 instructions JSON 字段：[06-agent-protocol.md §2](06-agent-protocol.md#2-openspec-instructions)

---

## Q13: 我能不能完全卸载 OpenSpec？

**答**：能，三层清理：

```bash
# 1. 清当前项目
cd <project>
rm -rf openspec
rm -rf .claude/skills/openspec-* .claude/commands/opsx
rm -rf .cursor/skills/openspec-* .cursor/commands/opsx-*.md
# ... 其它工具看 02-installation.md §6

# 2. 清 Codex 全局（如果之前选过 codex）
rm -f ~/.codex/prompts/opsx-*.md

# 3. 卸载 CLI 本身
npm uninstall -g @fission-ai/openspec
rm -rf ~/.config/openspec        # 全局配置
rm -rf ~/.local/share/openspec   # 用户级 schema（如果建过）
```

没 daemon 要 kill、没 hook 要解、没 PATH 要清——纯文件操作。

---

## 还想问？

把困惑发给我吧，沉淀到这个 FAQ 里。
