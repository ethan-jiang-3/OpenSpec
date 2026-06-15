# 答案：怎么在 OpenSpec 下扩展 schema——实操指南

## 一句话

OpenSpec 的 schema 系统允许你定义自己的 artifact 种类、依赖关系和生成规则——不改一行源码。三种方式：**fork 内置 schema 改**（推荐）、**从零 init**、**手写 YAML + 模板**。本指南以 `agent-dev-driven` 为例走通全流程，也适用于其他自定义 schema。

## 前置：三种扩法

| 方式 | 命令 | 适合 |
|------|------|------|
| **fork** | `openspec schema fork spec-driven my-name` | 内置 schema 基础上改（改 artifact、改 instruction、加删 artifact）。落到 `openspec/schemas/my-name/`，跟代码一起版本控制。 |
| **init** | `openspec schema init my-name` | 从零建（全新 artifact DAG）。脚手架自带 templates stub。 |
| **手写** | 直接创建 `openspec/schemas/my-name/schema.yaml` + `templates/*.md` | 完全掌控。最灵活，但也最容易漏 template 或写错 requires 引用。 |

**fork 优先**——它继承内置 schema 的所有模板和 instruction，你只改需要改的部分。init 和手写适合目标 artifact 集合和内置完全不同的场景（如 `article-driven`、`agent-dev-driven`）。

## 装一个已有的 schema（如 agent-dev-driven）

如果你已有完整的 `schema-package/`（含 `schema.yaml` + `templates/`），直接复制：

```bash
cp -r schema-package/ openspec/schemas/agent-dev-driven/
```

校验它是否合法：

```bash
openspec schema validate agent-dev-driven --verbose
# 输出：Checking schema.yaml exists...
#       Parsing YAML...
#       Validating schema structure...
#       Checking template files...
#       Dependency graph validation passed
#       ✓ Schema 'agent-dev-driven' is valid
```

查它从哪解析：

```bash
openspec schema which agent-dev-driven
# 输出：project: openspec/schemas/agent-dev-driven/schema.yaml
```

## 装在哪里——两个位置

| 位置 | 可见范围 | 什么时候用 |
|------|---------|-----------|
| `openspec/schemas/<name>/` | 当前项目 | 团队共享、跟代码版本控制——**推荐** |
| `~/.local/share/openspec/schemas/<name>/` | 当前用户所有项目 | 个人用、跨项目复用 |

## 创建第一个 change 并走通 DAG

创建一个 change 并绑定 schema：

```bash
openspec new change build-my-agent --schema agent-dev-driven
# 输出：✔ Created change 'build-my-agent' at openspec/changes/build-my-agent/
#       (schema: agent-dev-driven)
```

检查 `.openspec.yaml` 确认绑定：

```bash
cat openspec/changes/build-my-agent/.openspec.yaml
# 输出：schema: agent-dev-driven
#       created: 2026-06-15
```

看 DAG 状态——哪些 artifact 可以开始写、哪些被阻塞：

```bash
openspec status --change build-my-agent --json
# charter=ready（requires []，没有下游阻塞）
# skills=blocked（missingDeps: [charter]）
# commands/tools/evals/cli=blocked（missingDeps: [skills]）
# tasks=blocked（missingDeps: [skills, commands, tools, evals]）
# apply=blocked（missingDeps: [tasks]）
```

**写 artifact 的顺序就是 DAG 的拓扑序**：

```text
1. 写 charter.md           → skills 解锁
2. 写 skills/*.md          → commands/tools/evals 同时解锁（cli 也解锁，不强制写）
3. 写 commands/*.md        ┐
   写 tools/*              ├→ 都写完后 tasks 解锁
   写 evals/*.md           ┘
4. 写 tasks.md（勾 checkbox）→ apply 解锁
5. apply（接入 harness + 端到端验证）
```

每个 artifact 写什么，看它的完整 instruction（context + rules + template + instruction + 依赖状态都在一起）：

```bash
openspec instructions charter --change build-my-agent --json
# 输出 instruction 字段就是 agent 写这个 artifact 时要遵循的完整 prompt
```

## 校验和调试

**改 schema.yaml 后必须重校验**：

```bash
openspec schema validate agent-dev-driven --verbose
```

常见报错和解决：

| 报错 | 原因 | 修法 |
|------|------|------|
| `Duplicate artifact id: "xxx"` | schema.yaml 里两个 artifact 用了同一个 id | 改其中一个 |
| `Unknown artifact id in requires: "xxx"` | requires 引用了一个不存在的 artifact | 检查 requires 列表，id 必须匹配 |
| `Cyclic dependency detected` | requires 关系成环 | 画 DAG 图，找环，砍一条边 |
| `Template file not found: templates/xxx.md` | `template:` 字段指向的文件在 `templates/` 下不存在 | 创建那个模板文件，或改 template 字段指向一个已有的 |
| `Unknown artifact ID in rules: "xxx"` | config.yaml 的 `rules` key 不在新的 artifact 集合里 | 改 config.yaml 的 rules key，对齐 schema 的 artifact id |

**如果 CLI 解析行为不符合预期**——直接看 agent 收到的完整 instruction：

```bash
openspec instructions <artifact> --change <name> --json | python3 -m json.tool
```

这个 JSON 里有 `instruction`（你写的 instruction）、`template`（模板内容）、`context`（项目 config.yaml 注入的背景）、`dependencies`（上游 artifact 状态）——全部拼在一起才是 agent 实际看到的 prompt。如果你改了 instruction 但 agent 行为没变，可能是 template 或 context 干扰了。

## 设为项目默认 vs per-change

**项目默认**——在 `openspec/config.yaml` 里设：

```yaml
schema: agent-dev-driven
```

之后 `openspec new change <topic>` 默认用这个 schema，不必每次加 `--schema`。

**per-change**——只在某个 change 用非默认 schema：

```bash
openspec new change build-special-agent --schema agent-dev-driven
```

创建的 change 的 `.openspec.yaml` 会永久绑定 `schema: agent-dev-driven`——之后 `openspec status/instructions/apply` 都读这个 schema，不受项目 config.yaml 影响。

**解析优先级**（谁说了算）：

```text
CLI --schema 参数  >  change 的 .openspec.yaml  >  config.yaml 的 schema 字段  >  内置 spec-driven
```

## 迭代改 schema 后要做什么

改 schema.yaml 或 templates 后，已创建的 change **不会自动感知变更**——schema 内容是**即时重读**的：

1. `openspec schema validate` ——先确认改对了
2. `openspec status --change <name> --json` ——看 DAG 有没有新的 blocked artifact
3. 如果删了某个 artifact 的 requires 依赖：下游 artifact 会从 blocked 变 ready
4. 如果加了新 artifact：`openspec status` 会显示它出现在 DAG 里（状态是 ready 或 blocked）
5. 如果改了 instruction：下一次 `openspec instructions <artifact>` 就返回新内容——**不需要重建 change**

## 守则

- **fork 优先、不改内置**。直接改 `node_modules` 里的 `spec-driven` 或 `workspace-planning` 会被 npm update 覆盖。fork 一份到 `openspec/schemas/`。
- **每次改完先 `validate`**。schema.yaml 写错不像 config.yaml 那样 fail-open——硬错误会阻止指令生成。
- **`template` 文件名不能写错**。`openspec schema validate` 会检查每个 `template` 指向的文件是否存在。
- **requires 只引用存在的 artifact id**。拼写错误 → `Unknown artifact id in requires` 报错。
- **`apply.tracks` 尽量用 `tasks.md`**。OpenSpec 的 change 列表 UI 把 `[tasks X/Y]` 进度计数硬编码到了 `tasks.md` 这个文件名——不管 schema 的 `apply.tracks` 设什么，列表只看 `tasks.md`。用别的文件名，进度计数永远显示 0/0。
- **per-change pin 优先于项目默认切换**。大多数 change 沿用项目默认；只有特殊 work流 的 change 在创建时指定 `--schema`。

---

> 本指南是 [`answer.md`](answer.md) 的实操伴侣——那里解释 agent-dev-driven schema **为什么这样设计**；这里是**怎么装上用起来**。
> `openspec schema` 命令的完整参考见 `openspec schema --help`。
