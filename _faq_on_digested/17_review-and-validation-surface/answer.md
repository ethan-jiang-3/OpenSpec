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

## 参考来源

- 变更史：[`../../_digested/_change_log/0008-v1.10.0-to-v1.11.0.md`](../../_digested/_change_log/0008-v1.10.0-to-v1.11.0.md)、[`0009`](../../_digested/_change_log/0009-v1.11.0-to-v1.12.0.md)、[`0010`](../../_digested/_change_log/0010-v1.12.0-to-v1.13.0.md)
- 机制：[`../../_digested/mechanisms/03-spec-model.md`](../../_digested/mechanisms/03-spec-model.md)（parser/validator 分工、Purpose 占位符、advisory preflight）
- 命令面：[`../../_digested/spec_cli/01-human-facing-cli.md`](../../_digested/spec_cli/01-human-facing-cli.md)、[`02-machine-facing-cli.md`](../../_digested/spec_cli/02-machine-facing-cli.md)
- 失真治理：[`../../_digested/specs_truth/00-map.md`](../../_digested/specs_truth/00-map.md)
- 源码：`src/utils/requirement-diff.ts`、`src/core/validation/purpose-placeholder.ts`、`src/core/parsers/requirement-blocks.ts`、`src/core/specs-apply.ts`、`src/commands/validate.ts`
- 手册：[`../../_openspec_handbook/12-实战-如何正确修改-artifacts.md`](../../_openspec_handbook/12-实战-如何正确修改-artifacts.md)、[`90-附录-给机器看的-agent-协议.md`](../../_openspec_handbook/90-附录-给机器看的-agent-协议.md)
