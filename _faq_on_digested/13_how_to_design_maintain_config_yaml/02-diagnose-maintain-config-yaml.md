---
title: "如何诊断与维护 config.yaml"
document_kind: "diagnostic-maintenance-guide"
applies_to:
  - "all OpenSpec projects with an existing config.yaml or config.yml"
read_when:
  - "规则没有出现在 instructions 中、Apply/Explore/Archive 没有遵守预期，或编辑 config 后看不到变化。"
  - "需要切换 schema、维护 active changes、处理 store pointer 或检查 YAML/parser warning。"
focus:
  - "按生效 root -> config 文件 -> change schema -> consumer -> rendered instructions -> artifacts/checks 的顺序诊断。"
  - "确认 config 的真实注入边界，以及哪些约束必须升级到 schema、workflow 或 deterministic enforcement。"
not_for:
  - "不要用本文决定一段新知识应放 context、rules 还是 artifacts；先读 01-design-config-yaml.md。"
  - "不要把运行时 Flow owner、state 或 permission 问题误诊成 config 文案问题。"
next_read:
  - "发现 placement 错误后重做归位：01-design-config-yaml.md"
  - "尚未判定项目的 runtime model：00-initial-config-baselines.md"
---

# 如何诊断与维护 `config.yaml`

本文件面向“已经有配置，但规则不出现、行为不符合预期，或需要安全更新”的场景。它不重写配置哲学；先确认正在编辑的文件是否会被真实消费者读取。

## 先确认生效 root 和文件

下面四个事实能解释大部分“我改了 config 但没有变化”：

1. 同时存在 `openspec/config.yaml` 与 `openspec/config.yml` 时，`.yaml` 优先；修改 `.yml` 不会覆盖它。
2. `store:` 只在 `openspec/` 是 config-only 目录，即没有 `specs/` 和 `changes/` 时，才作为 pointer 选择已注册 store。
3. 本地已有 planning shape 时，本地 root 必然胜出；`store:` 被忽略并产生 warning。命令随后从选中的 root 读 config，因此 pointer 目录内的 `schema`、`context`、`rules`、`references` 都不是有效项目配置。
4. parser 是逐字段 fail-open：YAML 能解析不代表每个字段有效。无效字段和未知顶层 key 会被丢弃，合法兄弟字段仍可能继续工作。

因此，先解决 root 选择和文件优先级，再讨论 rule 的措辞。`store:` 目录只应承担 pointer 角色；项目 guidance 必须写在最终被选为 planning root 的目录中。

## 固定诊断顺序

```text
生效 root -> 生效 config 文件 -> 当前 change 的 schema -> 目标消费者
         -> rendered instructions -> change artifacts -> deterministic evidence
```

实际操作：

1. 确认编辑的是生效 root 中优先的 `config.yaml` 或 `.yml`。
2. 检查当前 change 的 `.openspec.yaml`；它可能记录了与 `config.schema` 不同的 schema 名称。
3. 确定需求的消费者是 planning artifact、Apply、Explore/Archive、references，还是 checker/test。
4. 运行 `openspec instructions <artifact-id> --change <change> --json`，检查 `context`、`rules`、dependencies 和 references。
5. 单独运行 `openspec instructions apply --change <change> --json` 与 `openspec instructions archive --change <change> --json`；二者会收到 `context` 和各自的 `operations.*.guidance`，但不会收到 artifact rules。
6. 运行 `openspec status --change <change> --json`，核对实际 schema、artifact 状态和后续路径。

`<artifact-id>` 必须是当前 schema 的真实 artifact ID；不能用 `apply` 代替它。

## 症状到修正

| 症状 | 常见根因 | 正确修正 |
|---|---|---|
| `context` 或 rule 完全不出现 | 编辑了非生效 root、被 `.yaml` 覆盖的 `.yml`、字段被 parser 丢弃，或 rule key 不属于当前 schema | 按 root/schema/instructions JSON 定位后，再修改有效文件与合法 key。 |
| `rules.tasks` 写得很好，但 Apply 没有遵守 | Apply 不接收 artifact rules | 稳定项目 guidance 移到 `operations.apply.guidance`；gate/结构移到 schema `apply.instruction`；本次动作和证据写入 tasks/artifacts。 |
| Explore 或 Archive 没有遵守一条 config 规则 | Explore 只读 context/rules，Archive 不读 artifact rules | Archive 的短稳定步骤移到 `operations.archive.guidance`；Explore/复杂专属行为用 workflow skill、`AGENTS.md`、playbook 或 checker。 |
| 改了 `config.schema`，活跃 change 仍选择旧名称 | change metadata `.openspec.yaml` 中记录的 schema 名称优先 | 新 change 使用新默认值；既有 change 要显式改名迁移并验证，不要期待隐式切换。注意 metadata 不保存 schema 内容；修改同名 schema 定义仍可能影响既有 change。 |
| `openspec schema init --default` 后默认 schema 没变 | 当前命令写入的 `defaultSchema` 没有被 project config 消费者读取 | 手动写 `schema: <name>`，再以新 change 的 `.openspec.yaml` 验证。 |
| `store:` 指向外部 store，但本地 guidance 仍被使用 | 本地 planning shape 让 local root 胜出 | 移除歧义：使用 config-only pointer，或把 guidance 放到真正选中的 local/store root。 |
| 新增 `guidance:`、`apply_rules:`、`operations.explore:` 等字段后没有效果 | 未支持的顶层 key/operation 被静默忽略 | 使用 `operations.apply/archive.guidance` 或现有 placement，或先实现可验证的 OpenSpec feature。 |

## schema 与多 schema 的维护规则

1. `config.schema` 决定新 change 的默认 schema 名称；已有 change 的 `.openspec.yaml` 中的名称优先。它不是 schema 内容、hash 或 version 的快照。
2. `schema` 缺失或无效时，合法的 `context`/`rules` 仍可能被保留，schema 消费者则回退到默认值。能运行不等于显式选中了预期 workflow；应始终写有效 `schema: <name>`。
3. `openspec schema init --default` 当前写入的 `defaultSchema` 是静默无效字段，上游修复前不能作为维护操作依赖。
4. `rules` 对当前 schema 的 artifact IDs 有效。并行使用多个 schema 时，某个 schema 专属 key 在另一个 change 上可能 warning 且不注入。
5. 切换默认 schema 前先盘点 active changes；要么让旧 change 完结，要么为它们制定可验证的显式迁移，而不是期望一份全局 rules 同时无噪声服务两套不兼容 ID。

## 维护循环

每次 archive 后，只把满足以下四项的经验提升为 config rule：

1. 它跨多个未来 change 仍成立。
2. 它有明确的 artifact owner，或所有 planning artifacts 都需要它。
3. 它能写成可判断的触发条件和动作。
4. 它不应由 spec、schema、state 或 deterministic check 承担。

其余发现应分别回到 canonical policy、change artifact、runtime record 或测试。不要把“agent 刚犯过一次错”直接变成每个 artifact 的长期 prompt 负担。

## 每次修改后的最小验证

1. 确认实际 root、`config.yaml`/`.yml` 优先级，以及 `store:` 没有与本地 planning shape 冲突。
2. 检查每个活跃 change 的 schema 与 rule keys 是否兼容。
3. 对代表性 change 运行 `openspec instructions <artifact-id> --change <change> --json`，确认只出现预期 `context`/`rules`。
4. 运行 `openspec instructions apply --change <change> --json` 和 `openspec instructions archive --change <change> --json`，确认 operation guidance 来自正确的 `operations` 字段，而 artifact rules 没有误当作 operation input。
5. 运行 `openspec status --change <change> --json`，确认 schema、artifact 状态和后续步骤。
6. 检查 stderr 的 YAML、50 KiB、unknown artifact ID 或 ignored `store:` warning。
7. 运行硬规则对应的 checker/test/CI；“prompt 已出现”不是验收证据。

新建或重构配置的归位决策见 [`01-design-config-yaml.md`](01-design-config-yaml.md)；从项目类型开始选择基线见 [`00-initial-config-baselines.md`](00-initial-config-baselines.md)。
