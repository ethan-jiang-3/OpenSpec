# 从 config.yaml 设计/维护视角继续深挖 `internal-spec-driven` 的计划

## 目标

把现有“字段和命令怎么工作”的解释，升级为一套可回答以下问题的资料：

> 一条知识、规则或决策应在什么生命周期、由谁、通过哪个 OpenSpec 表面消费；如果当前 config 无法精确路由，应该升级到 artifact、schema、skill 还是 deterministic check？

目标不是再写一篇更长的 `config.yaml` 说明，而是建立**上下文路由模型**和**维护决策程序**。

## 现有材料的价值与缺口

`_digested/internal-spec-driven/` 已经提供了很好的底座：

| 现有文档 | 可直接复用的洞察 | 为 config 设计还缺什么 |
|---|---|---|
| `00-四条命令的共有机制.md` | schema、CLI、agent 三方分工；四层注入；status + instructions | 需要把“谁消费什么”横向贯穿 explore/propose/apply/archive，而不只描述 artifact creation |
| `01-explore-探索模式.md` | Explore 是 stance，不是固定 artifact DAG | 需要明确 Explore 不自动拿 config prompt，因此配置设计不能拿它当探索期 context delivery |
| `02-propose-提案生成.md` | artifact DAG 和 dependency handoff | 需要提炼“change-local context 应通过 artifact 留痕并向下游路由”的方法 |
| `03-apply-实施执行.md` | apply gate、contextFiles、checkbox 行为 | 需要突出 apply 不消费 config context/rules 的设计后果 |
| `04-archive-归档合并.md` | archive 的验证/同步/移动语义 | 需要明确 archive 规则要由 tasks/checker/workflow 承担，而非 config 假设 |
| `05-schema-driven-控制面.md` | schema 是结构控制面、可 fork | 需要给出“何时从 config 升级到 schema”的阈值 |
| `06-config-yaml-机制与约束.md` | `schema`/`context`/`rules`、50KB、fail-open | 需要标注源码版本并补当前 `references`/`store`、多 schema、未知字段和 lifecycle coverage |

## 工作流一：建立“消费表面账本”

### 要做什么

为每个 config 字段和每个 workflow surface 建一张 source-backed matrix：

| workflow / command | 是否读取 config | 哪些字段 | 注入或使用位置 | 缺失时怎样退化 |
|---|---|---|---|---|
| `new change` | 是 | `schema` | schema 选择 | default schema |
| `instructions <artifact>` | 是 | context/rules/references | structured instructions JSON | fail-open / warning |
| `instructions apply` | 部分 | references | apply instructions JSON | 无 project context/rules |
| Explore skill | 不通过 instructions | 无自动 prompt 读取 | skill + `list/status` | agent 按需读文件 |
| Archive skill | 不通过 instructions | 无自动 prompt 读取 | status/tasks/specs | agent 按需读文件 |
| root resolution | 是 | `store` | planning-home 选择 | local root / fallback |

### 方法

1. 以当前源码的 `project-config.ts`、`instruction-loader.ts`、`workflow/instructions.ts` 和 workflow templates 为证据。
2. 将每条结论附上函数名和源码 revision，不依赖不稳定行号。
3. 与 `internal-spec-driven/06` 对照，记录“稳定机制”“新增字段”“过期/不完整描述”。

### 完成标准

- 读者可以仅凭表格判断某条规则能否在目标阶段真实出现。
- 每个“不支持”的结论都能指出应当升级到哪里。

## 工作流二：建立“信息归位分类法”

### 要做什么

把样例中的每段文本放到二维或三维坐标，而不是以长短判断：

```text
作用域：project | artifact | change | run | upstream
性质：background | guidance | contract | decision | executable invariant | state
消费者：explore | proposal | specs | design | tasks | apply | archive | engine
```

### 审计问题

1. 离开当前 change 后，这句话是否仍成立？
2. 哪个 artifact / workflow 真正使用它？
3. 它要不要在输出中留痕，供下游复核？
4. 它是否可被机器判定？
5. 是否已经有 canonical source，当前 config 是否只是在复制？
6. 如果两个 schema 并行，这条 `rules` key 在哪一个 schema 有效？

### 输出

维护一份类似 [`01-placement-audit.md`](01-placement-audit.md) 的审计表，包含：原位置、问题、推荐位置、迁移优先级、需要的验证方式。

## 工作流三：用最小实验验证，而不是靠阅读猜测

建议建立一个临时 fixture matrix（不碰真实项目配置）：

```text
fixture A: context + rules
fixture B: unknown rule key / unknown top-level key
fixture C: custom schema + different artifact IDs
fixture D: active change with metadata schema different from config.schema
fixture E: references and apply
```

对每个 fixture 记录：

```bash
openspec new change <name>
openspec instructions proposal --change <name> --json
openspec instructions specs --change <name> --json
openspec instructions design --change <name> --json
openspec instructions tasks --change <name> --json
openspec instructions apply --change <name> --json
```

检查 JSON 中的 `context`、`rules`、`references`、`dependencies`、`contextFiles`，以及 stderr warnings。实验的目的不是测 LLM 表现，而是锁定 CLI 的真实 routing contract。

## 工作流四：补齐 internal-spec-driven 的资料形状

建议在确认上述账本后，不要把所有内容继续塞进 `06`。更清晰的演进是：

```text
06-config-yaml-机制与约束.md
  - 保持字段、解析、限制、fail-open 的低层机制
  - 标明源码 revision，补 references/store 与版本差异

07-config-guidance-routing.md（新增候选）
  - workflow × config-field 消费矩阵
  - artifact DAG 如何传递 change-local context
  - Explore/apply/archive 的非消费边界
  - config -> artifact -> schema -> checker 的升级决策树

08-config-maintenance-playbook.md（新增候选）
  - promotion test、审计表、schema migration、验证命令
  - 样例的渐进拆分方法
```

若不希望增加文档编号，也可以把 07/08 作为本 FAQ 的长期维护材料；但低层机制和设计/维护方法应保持分离，避免 `06` 再次变成“什么都装”的 context 式文档。

## 工作流五：选择解决层级

完成审计后，按以下门槛作决定：

| 发现 | 首选动作 | 不该做的事 |
|---|---|---|
| 规则只对一个 artifact 长期有效 | `rules.<artifact>` | 放到 context |
| 规则只在一个 change 有效 | 写入 proposal/spec/design/tasks | 提升为项目全局 rule |
| 多个 artifact 都要用同一长政策 | 每个目标 rule 加短指针；正文单独维护 | 在多个 rules/context 复制政策全文 |
| apply 总是需要一项指导 | custom schema 的 `apply.instruction` | 新增 `rules.apply` |
| 需要一个新的前置决策/审查节点 | fork schema，新增 artifact + requires | 用 context 暗示 agent “先做它” |
| 规则必须不可绕过 | checker/test/CI | 仅靠 prompt |
| 想支持真正规则包选择器 | 先设计 OpenSpec feature | 在 config 写未支持的 `guidance:` 字段 |

## 若要产品化阶段化 guidance 的设计门槛

只有在“短 context + artifact rules + change context card + schema”仍不能解决问题时，才建议为 OpenSpec 设计新能力。候选能力必须至少回答：

1. selector 如何精确定位 artifact、apply、Explore、Archive，而不是创造含糊的 phase 名？
2. guidance 是 inline 文本还是引用文件？如何避免再次成为 50KB 全局 blob？
3. 如何验证 selector、文件路径、重复项、大小预算与 schema 演进？
4. instructions JSON 怎样公开“本次选中了哪些 guidance”，便于调试和测试？
5. 未支持字段如何报错，而非静默丢弃？
6. 一个 change 的 classification 如何影响选择，又怎样持久化、可复核？
7. 如何保证旧 config 和旧 schema 的兼容性？

一个可能的未来形状是外置且可验证的 guidance packs：

```yaml
# 仅为未来 API 讨论，不是当前可用写法
guidance:
  - id: control-paths
    targets: [proposal, design]
    source: openspec/policies/control-paths.md
  - id: apply-verification
    targets: [apply]
    source: openspec/policies/apply-verification.md
```

但这必须配套 resolver、instruction rendering、diagnostics、测试和 source-of-truth 规则；在实现前不能写入真实 config。

## 分阶段落地计划

1. **证据冻结**：完成消费表面账本，标注 `_digested` 与当前源码的版本差异。
2. **样例审计**：完成两个样例的逐块归位与重复/冲突清单。
3. **Native-first 整理**：先用现有 `context`、`rules`、artifacts、policy docs 试行，不改 CLI。
4. **三类 change 验证**：普通 change、跨模块 change、控制/运行时 change 各走一次完整 lifecycle。
5. **Gap review**：只记录经过试行仍无法精确路由的场景。
6. **Schema upgrade**：对 apply、前置分类 artifact 或特殊 DAG 需求 fork schema。
7. **Feature decision**：只有 remaining gap 证明 schema 仍不足时，再立 OpenSpec change 讨论 guidance packs。

## 退出标准

这项深挖可以在满足以下条件后认为完成：

- 每个 workflow stage 都有明确的 context 来源和 owner。
- 所有 config 条目都能解释其 scope、consumer、canonical source 和验证方式。
- 两份样例可以在不丢失治理意图的前提下，把全局 context 缩为短 profile。
- apply/explore/archive 的规则不再错误依赖 config 注入。
- schema 变更、multi-schema、未知字段、active change 不追溯等维护风险被写入 playbook。
- 若还提议新 config API，已有可复现实验说明现有机制无法覆盖的具体 gap。
