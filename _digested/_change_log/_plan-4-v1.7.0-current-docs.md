# 计划 4/4：以 OpenSpec v1.7.0 更新当前资料

**状态**：已完成（2026-07-29；当前结论、旧断言扫描和定向验证均已完成）
**当前基线**：OpenSpec `v1.7.0`，upstream tag/commit `4e16790`  
**覆盖目录**：`_digested/`、`_faq_on_digested/`、`_openspec_handbook/`

这不是另一个 release note。`0004-v1.6.0-to-v1.7.0.md` 记录上游变化；本计划负责把会误导当前用户的旧结论改为 v1.7.0 的实际行为。完整影响清单与一手来源见 [`_v1.7.0-impact-audit.md`](_v1.7.0-impact-audit.md)。

## 执行前的源码储备

当前工作树已经包含 upstream `v1.7.0`；文档判断固定以 tag `4e16790` 为准，而不是浮动的 `main`。每个主题先读下面对应源码，再写面向读者的结论。这里列的是应理解的机制，而不是要求把源码逐行转写进手册。

| 主题 | 先读的 v1.7.0 源码 | 必须带回文档的事实 | 不应误推的结论 |
|---|---|---|---|
| nested capability | `src/utils/spec-discovery.ts`、`src/core/specs-apply.ts` 的 `findSpecUpdates()`、`src/core/list.ts` / `view.ts` | `spec.md` 可在 `specs/` 下任意深度；相对路径是 capability ID；main 与 change delta 同路径 merge | 目录层次不是继承、聚合、自动挑相关 spec，也不解决 LLM 上下文预算 |
| delta / archive parser | `src/core/parsers/requirement-blocks.ts`、`src/core/parsers/code-fence.ts`、`src/core/validation/validator.ts` | UTF-8 BOM 与 fenced code 不制造假 header；change 根级 `specs/spec.md` 会被 validate/archive 拒绝 | 不能把 parser 宽容写成 requirements 可以随意省格式 |
| new spec / Purpose | `src/core/specs-apply.ts` 的 `extractPurposeSection()` / `buildSpecSkeleton()`、`schemas/spec-driven/schema.yaml` | 新 capability 的 delta 可写 `## Purpose`，archive 会带入新 main spec；既有 main spec 的 Purpose 不被 delta 覆盖 | 不能再说 archive 总会留下 TBD；没有/不可用 Purpose 时仍会回退 placeholder |
| early sync | `src/core/specs-apply.ts` 的 RENAMED/REMOVED/MODIFIED/ADDED 应用段、`src/core/archive.ts` | 与 main spec 已完全一致的 early-synced operation 是 no-op；近似拼写（case/空白）仍是错误；archive JSON 可含 warnings | 不能把 sync 后 archive 描述成天然危险，也不能说任何不命中都会被吞掉 |
| no-spec change | `src/core/change-metadata/schema.ts`、`src/core/artifact-graph/instruction-loader.ts`、`src/core/validation/validator.ts`、`schemas/spec-driven/schema.yaml` | `.openspec.yaml` 的 `skip_specs: true` 让 specs artifact 显式 `skipped`；tasks/apply 不再被 specs 阻塞 | 不能用 marker 绕开真实行为变化，且它不能与任何非隐藏 spec 文件共存 |
| operation guidance | `src/core/project-config.ts`、`src/commands/workflow/instructions.ts` | `context` + `operations.apply.guidance` / `operations.archive.guidance` 分别进入 Apply/Archive；有只读 `openspec instructions archive --json` | `rules.<artifact>` 仍只给 artifact generation；不存在 `operations.explore` / `operations.sync` |
| workflow order | `src/core/artifact-graph/graph.ts`、`instruction-loader.ts`、`schemas/spec-driven/schema.yaml`、各 `src/core/templates/workflows/` | specs/design 在 proposal 后都 ready，但同级推荐顺序按 schema 声明，内置 schema 为 specs 再 design；下游生成前重读磁盘依赖 | 不把推荐顺序误写成新的 DAG 依赖，也不把 agent 提示当硬校验 |
| host delivery | `src/core/command-generation/`、`src/core/update.ts`、`.codex/skills/` 与 `skills/` | Codex 是 skills-only，调用 `$openspec-*`；command 名由 adapter 实际注册；`update` 清理受管理旧 Codex prompts | 不把 Claude 的 `/opsx:*` 例子删掉，也不把它推广为所有宿主语法 |
| root / CLI UX | `src/core/root-selection.ts`、`src/core/global-config.ts`、`src/core/view.ts`、`src/core/version-check.ts`、workflow templates | machine `defaultStore` 是低优先级 fallback；`view` 解析 selected root；single active change 可自动选择；CLI update 可提示升级 stale global binary | 不把 source checkout 的版本和 PATH 中 binary 混成同一个版本来源 |

建议在修改机制型文章时直接打开以上本地源码，并在最终文档中保留到 `v1.7.0` 或 `4e16790` 的稳定链接。只改用户指南时可依赖已完成的审计与已更新的机制页，但遇到疑义仍回到这张表。

## 共同验收边界

- 面向当前使用者的行为结论以 v1.7.0 为准；`v1.5` / `v1.6` 仅留在变更史、时间线或明确标注的历史比较中。
- nested main spec 是完整生命周期支持：capability ID 是 `specs/` 下的相对路径（如 `identity/session`），delta 必须同路径；它不是继承树、自动聚合或按相关性自动读取 main specs 的机制。
- 不能把 host-specific 的 `/opsx:*` 当通用入口。Claude 专篇可以继续使用其实际 slash command；Codex 当前使用 `$openspec-*` skills。
- 文档区分“确定性 CLI 契约”和“agent 的提示/工作流建议”，不把后者写成强制执行。
- 不为 v1.7.0 无关的案例、历史 changelog 或 Claude 专篇做机械性替换。

## 主题到文件组的落点

下表是执行时的导航。它避免“看到一处旧说法才临时想起另一处”的遗漏；具体章节先按主题成组修改，再跑对应的扫描。

| 主题 | `_digested/` 主落点 | `_faq_on_digested/` 主落点 | `_openspec_handbook/` 主落点 | 完成判断 |
|---|---|---|---|---|
| nested capability 与 context scaling | `mechanisms/03-spec-model.md`、`internal-spec-driven/04-archive-归档合并.md`、`specs_truth/01,03,04,06,08`、`spec_cli/01,02,04,08` | `11_keep-specs-aligned/`，FAQ 14 只复查不回退 | `02`、`09`、`12`、`13`、`99` | 所有 current capability 定义改为相对 path；明确“不等于 retrieval” |
| `skip_specs` | `internal-spec-driven/00,02,05`、`schema/02`、`spec_cli/02,03,07`、`workflows/00,02,04,06` | FAQ 04、05 | `01`、`12` | 不再出现“零 delta 必然非法”这种无条件结论；列出 marker 冲突边界 |
| config operation inputs | `internal-spec-driven/06,07`、`schema/05`、`spec_cli/01,02,03,04,07`、`workflows/01,06,07,09,10` | FAQ 03、08、13 | `04`、`05`、`06`、`12` | 有正确 YAML；明确 context/operation guidance 与 artifact rules 的不同消费者 |
| archive / sync correctness | `mechanisms/03,04`、`internal-spec-driven/04`、`workflows/07,09,10`、`specs_truth/01,03,04,06,08` | FAQ 07、11 | `02`、`11`、`12`、`15` | Purpose 与 no-op、fence/BOM/root-delta 的表达均符合源码 |
| CLI / agent delivery | `mechanisms/02,04`、`spec_cli/05,06`、`workflows/00`、`system/04,06` | FAQ 03、04、06、07 | README、`00`、`01`、`02`、`03`、`08`、`90`、`99` | 跨工具文字不再称 `/opsx:*` 为 universal；Claude 专篇保持 Claude 语境 |
| runtime / store / status | `mechanisms/01`、`spec_cli/01,02,03,04,07`、`workflows/02,04,05,08,12`、`system/03`、`schema/06` | FAQ 01、12 | `07`、`08` | defaultStore、view、auto-select、numeric prefix、update 行为只在需要处补充 |

对于一篇同时命中多主题的文档，先修正会造成错误操作的结论（archive、config、`skip_specs`），再做术语和示例清理。只含历史案例的文件可只增加一个“以下为历史快照”边界，不能为了统一数字破坏案例的时间含义。

## 进度日志（持续更新）

### 2026-07-29 — `_digested/` 运行时与机制批完成

已把当前结论落实到下面文件，而不只是替换版本号：

- `spec_cli/00`–`08`：宿主中立入口、Codex skills-only、`instructions archive`、Apply/Archive operation inputs、`skipped`、nested capability path、`view` resolved root 和 `defaultStore` 边界。
- `mechanisms/01,04`、`system/03`：机器级 `defaultStore` fallback、`view --store`、workflow 的 inline archive/sync、schema 声明顺序与 `skip_specs`。
- `internal-spec-driven/00,02,05`：operation guidance / artifact rules 的分工、nested delta path、Purpose carry-through、`skip_specs`、同级 artifact 排序。

### 2026-07-29 — FAQ 主答案批完成

已更新 FAQ 03–08、11–13 的主答案（以及 Archive 的 ARC03/ARC07 子文档与 FAQ 11 问题页）：

- Explore/Propose/Apply/Archive 使用 host-neutral 结论；Claude `/opsx:*` 仅作为示例，Codex 对照为 `$openspec-*`。
- Apply/Archive 明确接收 project `context` 与 `operations.apply/archive.guidance`；Explore 读取 context/rules，但没有 `operations.explore`。
- 纳入 `skip_specs`、nested capability path、Purpose carry-through、early-sync no-op、`instructions archive` 与 v1.7.0 baseline。
- FAQ 12 标注为历史 roadmap/issue 快照，并在顶端加入 v1.7.0 current-facts 纠偏，避免历史 issue 推翻当前源码。

### 2026-07-29 — handbook、案例校正与 YAML 复核完成

- 已完成 handbook README、索引、01–09、11–15、99 的当前行为复核：入口按宿主区分，nested path 是 namespace 而非 retrieval，config 的 operation guidance 与 artifact rules 分工正确，archive/store/view 的结论以 v1.7.0 为准。
- 已复核 FAQ 13 三份项目案例；“Apply 不重收 config”的旧缩写全部明确为“不重收 artifact rules”，并补足 Apply/Archive 的 context 与 operation-guidance 边界。
- 已修复所有本轮发现的 `operations.*.guidance` YAML 示例：它们现在都是 schema 所要求的字符串数组；FAQ 初学者范本中误落在 archive 下的两条 `rules` 也已归回 `rules` 块。
- 已更新 `0004-v1.6.0-to-v1.7.0.md` 的处理状态，避免它再称三组资料“尚待逐篇重写”。

下一步只剩最终断言扫描、diff/YAML 检查和与行为变更相对应的定向测试。每项验证结果会继续登记在本计划，避免“文档已改、计划仍显示待办”。

### 2026-07-29 — 验证完成

- `git diff --check` 通过；复扫 `guidance:` 示例，没有残留 block scalar 或 YAML scalar 误用，唯一的 scalar 命中是源码类型定义 `z.array(z.string())`。
- 收尾扫描确认：没有把 `/opsx:*` 作为 Codex 或通用入口的未说明断言；所有命中均明确为 Claude/command-adapter 示例或历史记录；Apply/Archive 的 config 结论也都收窄为 artifact rules 边界。
- 与本次文档结论对应的 v1.7.0 测试均通过：`spec-discovery`（9）、`change-metadata`（28）、`workflow-instructions-skipped`（6）、`artifact-workflow`（74）、`archive`（85），共 202 个测试。
- 本计划、`0004` 和 `_v1.7.0-impact-audit.md` 共同保留了 tag `4e16790`、源码锚点、修改范围和验证证据；后续升级时应从它们复制流程而不是重新从旧 FAQ 推断版本基线。

## 1. `_digested/`：源码机制与运行时契约

- [x] 建立 v1.7.0 release 记录、当前基线说明和源码影响审计。
- [x] 更新 main-spec context 的研究底稿与 FAQ 14 所依赖的 nested-path 结论。
- [x] 修正工具投递总论：Codex skills-only，adapter 命令名不是统一 `/opsx:*`。
- [x] 更新 spec model、archive 与 specs-truth：递归发现、根级 `specs/spec.md` 非法、BOM/fenced-code 解析边界、Purpose 传递、early-sync no-op 与 archive warnings。
- [x] 更新 config / schema / CLI runtime：`skip_specs: true`、status 的 `skipped`、`operations.apply/archive.guidance`、Apply/Archive operation inputs、`instructions archive`、schema 声明顺序与重新读取依赖文件。
- [x] 更新 workflow 与 store/CLI 说明：单 active change 自动选择、bulk archive 仍显式选择、numeric-prefixed change、`defaultStore` / `view` root resolution、`openspec update` 的 stale CLI 提示。
- [x] 逐篇扫描并删除仍将以上行为描述为 v1.5/v1.6 当前结论的断言；保留历史文档中的历史描述。

**这一部分的编辑方法**：机制篇要给源码锚点并区分 parser、validator、archive、agent template 四层；workflow/CLI 篇要把 JSON input/output 面与 host skill 的行为分开。修改 `specs_truth` 的 recipe 时，优先替换绝对错误的操作说明，而不重写其真实案例的历史诊断。

## 2. `_faq_on_digested/`：问题导向的当前答案

- [x] 更新 FAQ 14，使其以 v1.7.0 区分“nested path 已支持”与“main-spec 上下文自动检索仍未解决”。
- [x] 更新 FAQ 04/05：proposal、status、continue/apply-ready 中的 `skip_specs` 和 schema artifact 顺序。
- [x] 更新 FAQ 06/07/11：Apply/Archive 的 operation inputs、Purpose 写入新 main spec、同步后 archive 的幂等/验证边界、nested capability path。
- [x] 更新 FAQ 08/13：`config.yaml` 增加 `operations`；`context` 会进入 Apply/Archive，artifact `rules` 不会；Explore 读取 context/rules；给出唯一合法的 operation guidance 放置方式。
- [x] 更新 FAQ 12：将当前 upstream/CLI 结论提升到 v1.7.0，区分源码 checkout、PATH 二进制和 `openspec update` 的升级提示。
- [x] 保留案例中明确的 Claude `/opsx:*` 调用，但在跨工具结论处注明 invocation 由 host adapter 决定。

**这一部分的编辑方法**：答案先给用户能据此行动的 v1.7.0 结论，随后给边界和最小命令/YAML；将源码细节链接回 `_digested`。FAQ 14 的重点是“层级 path 能帮助切分但没有自动检索”，不要用其他 FAQ 的 nested-path 更新冲掉这个结论。

## 3. `_openspec_handbook/`：面向使用者的手册

- [x] 更新 README、索引、能力身份章节和机器协议到 handbook v1.3 / OpenSpec v1.7.0。
- [x] 更新入门、概念、生命周期和 FAQ 总入口：host-specific invocation、`skip_specs` 与 capability path 的用户心智模型。
- [x] 更新 config 章节（04/05/06）和 artifacts 实战：四个 artifact 的 rules 与 Apply/Archive operation guidance 的边界，附最小正确 YAML。
- [x] 更新 archive、多人协作和实战案例：新 capability Purpose、inline sync 后验证、幂等 early-sync，以及 nested path 的使用边界。
- [x] 更新 store/custom-schema 章节：default store fallback、`view` 按 resolved root、schema `instruction` 的权威性；仅在当前结论处写 v1.7.0。
- [x] 复查所有通用表格与 Q&A：不把 Claude 语法扩展到 Codex，也不把路径 namespace 说成 hierarchy/retrieval。

**这一部分的编辑方法**：手册避免堆源码名；以“应该怎样配置/怎样归档/什么时候不能这样做”为主。总体入口用 host-neutral 表述，Claude 实战章节继续展示真实的 `/opsx:*` 例子；必要时用一句 Codex 对照，而不是把 Claude 章节改成多工具教程。

## 验证与收尾

- [x] 用 v1.7.0 源码和 release note 复核每项新断言；链接固定到 tag/commit，不依赖浮动 `main`。
- [x] 用定向 `rg` 扫描过时的 current-version 表述、"Apply/Archive 不接收 config"、"Purpose 总是 TBD"、flat-only capability 与通用 `/opsx:*` 断言。
- [x] 运行 `git diff --check`，并运行与递归 spec discovery / metadata / instructions 相关的定向测试。
- [x] 将 `0004-v1.6.0-to-v1.7.0.md` 的“后续逐篇重写”状态改成已完成的实际范围，并在本计划中勾选完成项。

### 收尾扫描词

完成每一批后，针对其主题检查以下词组是否还在表达当前错误结论：

```text
af94ff8 | v1.5.0 | v1.6.0                  # 仅允许历史区或 changelog
Apply ... 不接收 config/context             # 应改为不接收 artifact rules，但接收 operation inputs
Archive ... 不接收 config/context
Purpose ... TBD / 每次 archive 后补          # 应说明 Purpose carry-through 与 fallback
No deltas found / 零 delta 必然失败          # 应区分无 marker 与 skip_specs
capability = 目录名 / 只支持一级目录          # 应改为 specs/ 下相对 path
/opsx:* ... Codex / 所有工具                  # 应改为 host-specific invocation
```

验证不是只看文本替换：每一处命中都要判断它是否在讲历史。最终除了 `git diff --check`，至少运行 `spec-discovery`、change metadata / instruction、archive 相关定向测试，并复读 v1.7.0 源码中被文档引用的函数签名。
