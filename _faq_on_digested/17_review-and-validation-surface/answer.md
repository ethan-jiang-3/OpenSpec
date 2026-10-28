# 答案：审阅/校验工具面——把“spec 失真”从归档后挪到归档前

## 一句话

这一组能力沿**两条线**补 specs_truth 的洞：**解析保真**（delta 到底有没有被读懂）和**报告面**（失真到底有没有被看见）。它们不改变"validate 只查结构、archive 只合并一次"的基本分工，但把检测点**前移**到 archive 之前，并把过去只能靠人肉 diff 的判断变成 CLI 的程序化输出。

```text
解析保真（delta 有没有被读懂）       报告面（失真有没有被看见）
  ├─ CommonMark 列表标记 [-*+]        ├─ show --diff        逐 requirement 差异
  ├─ 重复 section header 全应用        ├─ status --all       全量 change 状态
  ├─ scenario 换行 bullet             ├─ validate --report findings
  ├─ code fence 内空行保真             └─ advisory merge preflight
  └─ rename 保序                          └─ Purpose 占位符检测
```

两条线缺一不可：解析保真让"写了但没生效"不再发生；报告面让"生效了但和预期不符"能被看见。

## 一、解析保真：消灭“静默不生效”

这是性质最严重的一类 bug——**命令报成功，需求没动**。现修了三处：

| 修复 | 旧行为 | 现行为 | 锚点 |
|---|---|---|---|
| CommonMark 列表标记 | REMOVED/RENAMED 硬编码只认 `-`；`*`/`+` 写的删除/改名匹配不到任何东西 | 接受 `[-*+]`，`FROM:`/`TO:` bullet 仍可选 | `#1800`，`requirement-blocks.ts` |
| 重复 section header | `DeltaPlan` 是 title-keyed record，后写的 `## ADDED Requirements` 覆盖先写的；大小写折叠 lookup 只返回第一个 | 改为按书写顺序的 list，每份 body 都应用，报错指向正确行号，FROM/TO 按 section 配对 | `#1802` |
| scenario 换行 bullet | 续行被当成"无法归属内容"，capability 无法退役；`+` 标记同样读不出 | 换行 bullet 读成一条，`+` 正确识别 | `#1782` |

另加两条保真：archive 用 `collapseBlankRunsOutsideFences` 只折叠 **fence 外**空行（YAML block scalar / Python / expected-output 样例不再被"整理"）；`RENAMED` + `MODIFIED` 同一条时，rename 更新 key 但**不移到 spec 尾部**。

**为什么这条线是"信任"问题**：validate 和 archive 都依赖 parser 的理解。parser 漏读时，validate 说 valid、archive 说成功，工具本身失去了可信度。修完之后，`show --diff` 这类报告面才有意义——否则你连"diff 出来的东西是否完整"都无法确信。

## 二、报告面：把失真挪到归档前

### `openspec show <change> --diff`

**它解决什么**：MODIFIED requirement 必须完整重述它保留的每个 scenario，导致 delta 文本和 main spec 几乎一模一样。人要看"改了哪一行"，只能自己拿两个文件做 diff。`--diff` 用统一 diff 算法把真实变化的行隔离出来。

| delta 类型 | `--diff` 输出 |
|---|---|
| MODIFIED | 彩色 unified diff（绿增红删） |
| ADDED | 全文（没有可对照的旧块，不输 diff） |
| REMOVED | Reason / Migration note（不是 diff） |
| RENAMED | FROM / TO |

`--json --diff` 保持既有 payload 形状，在 MODIFIED delta 上加 `diff` 和 `warning` 字段；`--store <id>` 可对 store 中的 main spec 做 diff。锚点：`src/utils/requirement-diff.ts`。

### `openspec status --all`

**它解决什么**：多 active change 的项目不必逐个 `openspec status`。一个进程返回全部状态。

- JSON envelope：`{ "changes": [<status>, ...], "root": ... }`，按 change name 稳定排序。
- **故障隔离**：某 change 加载失败时贡献 `{ "changeName", "status": [diagnostic] }` 替代，而不是中止全扫。
- 部分失败在 text 和 JSON 模式都 exit 1，同时保留完整 envelope。
- `--all` 与 `--change <name>` 互斥。

### `openspec validate --report findings`

**它解决什么**：批量校验时 full 报告全是"通过"条目，注意力被稀释。

- `--report full|findings`，且**必须**配显式批量 scope（`--all`/`--changes`/`--specs`/`--archived` 之一）；不能带 item name；`archived` 与 active scope 不能混用。
- findings 是**独立报告类型**（`{ "report": { "kind": "validation-findings", "scope": ... } }`），不是 full 的子集——机器接口的向后兼容靠这一点保证。
- 只含有 error/warning/information 的条目，保留全量运行的总数和退出码；默认 `full` 形状不变。
- 违规请求输出 `invalid_validation_report_request`（severity error，附 `fix`）。

### validate advisory merge preflight

**它解决什么**：validate 和 archive 对 delta 的解读从此一致。

- delta 与 main spec 的合并冲突在 validate 阶段报为 **informational findings**（成功文本报告里也出现），**不改退出码**。
- 文件系统读取错误保留为 error，不再被误判成"spec 缺失"；预检无法解析输入时报告保持完整。

### validate Purpose 占位符检测

**它解决什么**：archive 为新建 capability 写入的 `TBD - created by archiving change <name>. Update Purpose after archive.` 长于 `MIN_PURPOSE_LENGTH`，反而满足了那条用来抓"没人写过 Purpose"的 brevity 规则；此后没有任何命令会再读它。于是 capability 里一直躺着一个待办，而所有命令都报成功。

`findPurposePlaceholderIssue()` 只认两件事：writer 生成的整句（用共享常量 `PURPOSE_PLACEHOLDER_PREFIX`/`SUFFIX` 匹配），或**开头**是 `TBD`/`TODO` 的 Purpose（`^(?:TBD|TODO)(?![\p{L}\p{N}\p{M}_])`）。句子中间的 `TBD` 不报（否则训练用户忽略警告），fence 内引用先读出，空 Purpose 交给 `SPEC_PURPOSE_EMPTY`。级别 **WARNING**，`--strict` 才失败。

## 三、它们补上了什么、没补上什么

对照 [`../../_digested/specs_truth/`](../../_digested/specs_truth/) 的缺口清单：

**补上了**：

- **"静默不生效"**：parser 三修复 + rename 保序 + fence 保真，堵住了"写了但没动"这一类。
- **"delta 与 main spec 的合并冲突要等 archive"**：advisory preflight 把它提前到 validate。
- **"archive 遗留 TBD 无人发现"**：Purpose 占位符检测。
- **"多 change 状态要逐个看"**：`status --all` + `validate --report findings` 让批量审阅可行。
- **"delta 真实差异只能人肉 diff"**：`show --diff`。

**仍没补上**（边界）：

- **specs ↔ 代码漂移仍要人巡检。** `show --diff` 比的是 delta 与 main spec，不是 spec 与代码；validate 仍不做跨文件对账。`show --diff` 是"看清 delta 失真"的工具，不是"发现代码漂移"的工具。
- **没有持续对账。** 所有检测仍是**时点式**：你在跑命令时才检查，没有守护进程或 CI 钩子自动追踪。
- **没有自动 spec retrieval。** 这一组能力不改变"agent 仍需自己选相关 specs"的现状。
- **parser 修的是已知标记形式。** `[-*+]` 已覆盖 CommonMark，但更冷门的书写变体（异常缩进、非标准 header）仍可能漏读。

## 四、判断锚点

- **"validate 过了" ≠ "delta 生效了" ≠ "specs 和代码一致"。** 三个断言各有各的边界：parser 保真解决第一个到第二个的落差；specs↔代码仍靠人。
- **archive 前的最小审阅动作**：`validate <change>`（结构 + merge 预检）→ `show <change> --diff`（差异是否符合预期）→ archive。
- **CI 里抓"归档未勾完 tasks"**：`validate --archived`；抓"批量问题条目"：`validate --report findings --all`。
- **新 capability 建出后**：若 `validate` 报 Purpose 占位符 warning，别忽略——那是 archive 留下的"待办"，要么现在写，要么它永远躺在那。

## 五、结论

这一组能力不是新工作流，而是给现有"弱约束、增量演化"模型补上**可观测性**：过去你只能相信 `validate` 的"valid"和 `archive` 的"success"，现在你能在归档前用 `--diff` 看清差异、用 findings 报告收窄注意力、用 parser 保真确保"看到的差异就是真实的差异"。

一句话：**OpenSpec 没有替你解决 specs 漂移，但它第一次让你在归档前就能看清 delta 层面的失真。**

---

## 六、v1.14.0 补充：verify 按 status 契约重写、metadata 未知键告警、500 字符引导

### verify 模板重写（status 契约 + Not applicable + advisory）

verify 不再自己解析 checkbox。它改读 **`openspec instructions apply --change <name> --json`** 的顶层 `tasks` / `progress`（已聚合 schema `apply.tracks` 匹配的所有可读任务文件）与 `taskTrackingConfigured`。

> **注意别张冠李戴**：这些字段在 `instructions apply --json` 里，**不在 `status --json` 里**。实测 `status --change t1 --json` 不含 `taskTrackingConfigured` / `unavailableTrackingFiles`；`instructions apply --json` 才有（模板原文见 `verify-change.ts:53-54,75-80`）。

- **Not applicable 语义**：schema 未定义的检查、status 报告为 intentional skip 的 artifact（`skip_specs: true`、可选 design、无任务追踪的 schema）→ 标 **Not applicable**，不算失败，也不计入 skipped-check 总数。只含 REMOVED/RENAMED 的 delta（无 ADDED/MODIFIED）时，Requirement Implementation Mapping 与 Scenario Coverage 也标 **Not applicable**——Spec Coverage 里的 REMOVED/RENAMED 检查就是这类 change 的证据。
- **Not verified 的收敛**：`unavailableTrackingFiles` 非空 → Task Completion 记 not verified，并逐条列出不可读路径及原因；`taskTrackingConfigured: true` 但 `tasks` 为空 → 记 not verified 并引用 apply `state`/`instruction` 的原因。空 `tasks` 本身不再等于"缺证据"。
- **advisory 语义**：apply 的 `state`/`instruction` 只是 context，不是 verdict；验证是 advisory 的，`Not verified` 描述的是本报告的边界，不是新的 archive 前置条件。archive 保留自己的检查与用户确认行为。
- 提示列表显示**所有** active changes（含 `status: "no-tasks"`），不再只显示有 tasks artifact 的。

### `.openspec.yaml` 未知键告警

`CHANGE_METADATA_KNOWN_KEYS` 白名单（`schema`/`created`/`goal`/`affected_areas`/`initiative`/`skip_specs`/`retire_capabilities`）之外的顶层键，status/validate/archive 都会告警"未知键被忽略、无效果"，`validate --strict` 下直接失败。拼写漂移（如把 `skip_specs` 写成 `skipSpecs`）从静默 no-op 变成可见信号。

**v1.14.2 起小写 `x-` 开头的顶层键是例外**：它们属于使用者，OpenSpec 不读不写不校验，`--strict` 照常通过（`X-Tracker`、裸 `x-`、`x- tracker` 仍报未知；`initiative:` 内部仍严格）。注意 `ChangeMetadataSchema` 会 strip 未知键**包括 `x-*`**，任何重写 `.openspec.yaml` 的调用方必须从原始 YAML 合并回来。

`--strict` 对**超长 requirement** 直接失败：v1.14.1 起 requirement 正文 >500 字从 INFO 升为 WARNING（`--strict` 即失败），且同一限制前移到 change 的 ADDED requirement（MODIFIED 不受限）。

### requirements 500 字符引导口径

500 字符上限（`MAX_REQUIREMENT_TEXT_LENGTH`）早就存在，v1.14.0 把"怎么写短"写进了 specs instruction 与 validate 提示：新 requirement 一条只写一个行为，示例和边界情况移进 scenario，覆盖多个行为的 requirement 拆成多个 `### Requirement:` 块；validate 对超长 requirement 的 flag 现在是 **WARNING**（v1.14.1 起，此前 INFO；`--strict` 会失败），仍不是 error；同一限制也作用于 change 里的 ADDED requirement，所以超长在 authoring 阶段就暴露。MODIFIED 不受此检查（避免逼人拆动既有正文），且保持既有 requirement block 完整，**不为凑长度拆写、裁剪或重写已有文本**；确需拆分时按 specs instruction：保留 header 与全部 scenario，正文收敛到一个行为，被移除的行为各自作为新的 ADDED requirement。

## 七、v1.14.1–v1.14.3 补充：归档前能看见的失真又多了两类

### delta 里"归档不会带走"的文本（v1.14.2 #2054）

归档按 delta 段合并，delta 里有三类文本**永远不会进主 spec**：

| 位置 | 例子 |
|---|---|
| 第一个 `## ` 之前的正文 | 文件开头的说明、作者备注 |
| `## ADDED/MODIFIED Requirements` 里第一个 requirement 之前的散文 | "这组改动是因为……" |
| Purpose 与四类 delta 段之外的任何 `## ` 段 | `## Notes`、`## Migration` |

以前它们静默消失。现在 `parseDeltaSpec` 返回 `unappliedContent`（`{section, line}[]`），`validate` 报 WARNING、`archive` 在重建主 spec 时 `warn()`，文案直接给出出路：挪进 requirement，或挪进 proposal/design。HTML 注释、`# ` 标题、Purpose 段、REMOVED/RENAMED 正文都不告警。

**搬运行为不变**——这条只让丢失可见，不改变结果。

### 退役备份清理失败有独立错误码（v1.14.1 #1792）

`archive` 删掉某 capability 最后一个 requirement 之后要清理备份。它失败时以前报通用 `archive_error`，且文案断言"每个列出的备份都被保留"——部分成功时这句话是假的。现在：错误码 `archive_retirement_cleanup_failed`，文案拆成两件事——**change 已归档**（retry 回不去）、**清理未完成**（要按诊断里所有 recovery path 逐个检查）。

### verify 的口径修正（v1.14.2–v1.15.0）

- **按输出路径发现工件**（#2028/#2083）：spec 工件 = `artifactPaths.<id>.outputPath` 在 `specs/` 之下者；design 工件 = id 为 `design` **或** outputPath 命中 `design.md` 者。自定义 schema 下不再因为 id 起得不一样而漏检。
- **REMOVED 必须先读基线**（#2083）：先从 `openspec/specs/<capability-path>/spec.md` 读该 requirement 的基线；读不到就翻文件历史（`git log -p -- <path>` / `show <commit>^:./<path>`）。基线只是标题重述（没有 scenario）视同缺失；两者都没有就把 Spec Coverage 记 not verified 并**跳过搜索**，而不是空手去代码里猜。只有行为确实仍在时才判 CRITICAL。
- **精确规范化名称匹配**（#2114，v1.15.0）：匹配规则收紧为 OpenSpec 应用 REMOVED 时的同一条规则——取 `Requirement:` 后的标题文本、trim，只在结尾 `#` 串前有空格/tab 时去掉这段 `#`（所以 `C#` 保留自己的 `#`），大小写敏感比较。相似措辞的标题**不算**匹配；改名属于 RENAMED。此前按近似名字扫描，一个在 sync 后顶替了被移除条目的相似 ADDED requirement 会被当成基线，从而把"仍然实现"误报成"已移除"。

### 归档前的最小审阅动作（更新版）

```text
validate <change>            # 结构 + merge 预检 + unapplied 文本 WARNING
  → show <change> --diff     # 差异是否符合预期
  → 超长 requirement / 超长 ADDED：按 specs instruction 拆分
  → archive                  # 确认提示默认是 Yes（回车即继续）
```

`archive` 的 spec 更新确认提示默认值是 **Yes**（`Proceed with spec updates? (Y/n)`，回车即继续；拒绝要显式输入 `n`）。这是 v1.14.1 起被 spec 追认的既有行为——旧 spec 写的是默认 No。

---

## 参考来源

- 变更史：[`../../_digested/_change_log/0008-v1.10.0-to-v1.11.0.md`](../../_digested/_change_log/0008-v1.10.0-to-v1.11.0.md)、[`0009`](../../_digested/_change_log/0009-v1.11.0-to-v1.13.1.md)、[`0011-v1.13.1-to-v1.14.0.md`](../../_digested/_change_log/0011-v1.13.1-to-v1.14.0.md)、[`0012-v1.14.0-to-v1.14.3.md`](../../_digested/_change_log/0012-v1.14.0-to-v1.14.3.md)、[`0013-v1.14.3-to-v1.15.0.md`](../../_digested/_change_log/0013-v1.14.3-to-v1.15.0.md)
- 机制：[`../../_digested/mechanisms/03-spec-model.md`](../../_digested/mechanisms/03-spec-model.md)（parser/validator 分工、Purpose 占位符、advisory preflight）
- 命令面：[`../../_digested/spec_cli/01-human-facing-cli.md`](../../_digested/spec_cli/01-human-facing-cli.md)、[`02-machine-facing-cli.md`](../../_digested/spec_cli/02-machine-facing-cli.md)
- 失真治理：[`../../_digested/specs_truth/00-map.md`](../../_digested/specs_truth/00-map.md)
- 源码：`src/utils/requirement-diff.ts`、`src/core/validation/purpose-placeholder.ts`、`src/core/validation/constants.ts`（`MAX_REQUIREMENT_TEXT_LENGTH`）、`src/core/parsers/requirement-blocks.ts`、`src/core/specs-apply.ts`、`src/commands/validate.ts`、`src/utils/change-metadata.ts`（未知键白名单）、`src/core/templates/workflows/verify-change.ts`（status 契约）
- 手册：[`../../_openspec_handbook/52-实战-如何正确修改-artifacts.md`](../../_openspec_handbook/52-实战-如何正确修改-artifacts.md)、[`90-附录-给机器看的-agent-协议.md`](../../_openspec_handbook/90-附录-给机器看的-agent-协议.md)
