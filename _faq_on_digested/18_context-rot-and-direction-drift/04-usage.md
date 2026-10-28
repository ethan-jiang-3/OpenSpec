# 04 · 使用要点

[← 返回索引](answer.md) ｜ 上一篇：[03 · 线 B](03-direction-drift.md)

每条都只对应**自带能力**，不掺外部脚本或约定。标注 `[硬]` 的是代码判定，`[软]` 的是 prompt 建议。

---

## 0 · 先确认你手上有什么：profile 决定到手面

**默认是 `core`**【实测：`openspec config get profile` → `core`；代码 `src/core/global-config.ts:47`】：

```text
core（默认）      propose  explore  apply  update  sync  archive
                  src/core/profiles.ts:14  CORE_WORKFLOWS

expanded（可选）   + new  continue  ff  verify  bulk-archive  onboard
                  启用：openspec config profile  →  openspec update
```

**所以开箱没有 `/opsx:verify`**，也没有 `new`/`continue`/`ff`/`bulk-archive`/`onboard`。

> **注意**：CLI 命令（`validate`/`show`/`status`/`instructions`/`list`/`archive`/`doctor`/`context`/`store`/`workset`/`schema`…）**不受 profile 影响**，始终可用。profile 只决定投递哪些 skill / slash command。

---

## 1 · 把 `tasks.md` 当持久记忆，实现前主动清上下文 `[软]`

官方口径【文档：`docs/faq.md:91-93`】：

```text
"Because the plan lives in files (not only in chat history), you can clear your
 context, start a fresh AI session, and pick up with `/opsx:apply`; it reads the
 artifacts and resumes from the first unchecked task. … Keeping a clean context
 window also produces better results; clear it before implementation."
```

机械支撑【实测】：`instructions apply --json` 返回每个 task 的 `done` + `sourcePath` + `line`。

**这是对"上下文腐化"最有效的一招，而且它是结构性的**——状态活在磁盘上，不在对话里。

---

## 2 · 用分级读控制上下文，别整树读 `[硬]`

```text
openspec list --specs                    # 2,687 B 盘点 36 个 capability
openspec show <id> --type spec --json --no-scenarios    # 省 84%
openspec show <id> --type spec           # 只对真正相关的读全文
```

schema 明确要求"摘要看完必须读全文再决定改什么"——但那句是 `[软]`，**分级读的工具本身是 `[硬]`**。

---

## 3 · `config.yaml` 的 `context:` 往「瘦而稳」写 `[硬]`

50 KB 是上限不是目标——它**每一次请求都注入**。稳定约束放这里，别每次在 chat 里重讲；一次性的东西别塞。

规则同理：`rules:` 按 artifact 分流就是为这个设计的。键写错会 warning 并列出合法 id——但**只有 `instructions` 会报，`validate --all` 不报**，所以 CI 里查不出来（§[02 A4](02-context-rot.md)）。

`config.yaml` 的三个面全部是**软能力**，怎么用才不白配，见 §[06](06-remedies-within-budget.md)。

---

## 4 · 方向变了先过「三问」，再决定改还是新开 `[软]`

【文档：`docs/faq.md:89` + `docs/opsx.md:298-310`】

```text
同意图？            同一件事的细化      → update
>50% 重叠？         范围收窄 / 边做边学  → update
原 change 能独立完成？ 意图根本变了       → new
```

取舍：**update 累积历史，new 换来清晰。** 文档也承认——"start fresh" 只是新建一条，**旧 change 的处置没有任何指引**【实测：无 delete-change 命令】。

---

## 5 · 走 `/opsx:update` 做双向复核，不要单文件孤立地改 `[软]`（core）

这是自带能力里**唯一**的一致性通道。它允许"改后面回头改前面"、不推进 frontier、不碰代码、逐条确认、已自洽则不修订。见 §[03 B2](03-direction-drift.md)。

---

## 6 · 归档前跑两道 `[硬]`

```bash
openspec validate --strict          # 让 WARNING 也失败（500 字符、占位 Purpose 等）
openspec validate --all             # 顺带读 INFO：Archive would refuse this delta（免费预检）
```

本仓实测【实测】：非严格 **60 passed / 6 failed**；严格 **53 passed / 13 failed**——`--strict` 多翻 7 项。**归档用的是非严格校验器，所以不跑 `--strict` 就永远看不到那 7 项。**

---

## 7 · capability 边界纪律 `[软]`（但值得当硬规则守）

来自 schema instruction【文档：`schemas/spec-driven/schema.yaml`】：

- 命名为**持久系统行为**（`user-auth`），不是本次工作（`add-login-endpoint`）
- **复用已存在 capability 的精确路径**，不要引入近似重名
- 不要为满足校验而**凭空发明 requirement**（`:42`）
- **不要移动或重命名 capability**；不要未经要求重写已存在的 spec 文件
- MODIFIED 下**保持原块完整**，不要为凑长度去拆分/裁剪既有文本

> **为什么这条特别重要**：`ADDED`-only 的 delta 写错 capability 路径会**静默新建一个 capability**，没有任何工具会提醒你。这是"规格越堆越多"里最容易失控的一环。

---

## 8 · 诚实使用两个豁免 `[硬]`

| 豁免 | 何时用 | 护栏 |
|---|---|---|
| `skip_specs: true` | 纯重构 / 工具 / 文档，**确实没有行为变化** | marker + `specs/` 下有文件 = **硬 ERROR 冲突**，陈旧 marker 藏不住 |
| `retire_capabilities: true` | 真正要删整个 capability | 唯一退场通道；删除**只能从 git 恢复**，且需过校验器 oracle + `unaccountedContent` 否决 |

---

## 9 · 想要 `/opsx:verify` 就开 expanded profile `[软]`

```bash
openspec config profile      # 选 expanded
openspec update              # 重新投递
```

它是 advisory、不阻塞归档——当"待办清单"用，不要当门禁。

---

## 10 · 用 `operations.guidance` 把纪律投递到 apply / archive `[软]`

`config.yaml` 还有一个前五章没提的面——它是**唯一**能进 apply/archive 运行时的配置字段：

```yaml
operations:
  apply:
    guidance:
      - Re-read direction.md before starting; if it contradicts tasks.md, stop and ask.
  archive:
    guidance:
      - Name any direction change this change made, and its successor.
```

`openspec instructions apply|archive --json` 会返回 `operationGuidance` 数组【实测】。

**必须知道的边界**：
- 只支持 `apply` / `archive` 两个 id；写别的会 warning 并列出合法值
- 它和 `rules:` 分工不同：`rules` 约束**产物内容**，`guidance` 约束**做事方式**
- **归档时 CLI 不读它**（`src/core/archive.ts` 里 `readProjectConfig` 调用数为 0）【代码】——**挡不住任何归档**，纯 prompt 投递

详见 §[06.3](06-remedies-within-budget.md)。

---

## 11 · 用自定义 schema 给「方向」建硬前置 `[硬]` —— 但先算维护成本

如果你受够了"方向在脑子里、产物在文件里、两者逐渐脱节"，**自带能力里有一条真路**：

```bash
openspec schema fork spec-driven my-flow     # 复制内置 schema 到项目
# 编辑 openspec/schemas/my-flow/schema.yaml
```

```yaml
artifacts:
  - id: direction
    generates: direction.md
    requires: []
  - id: proposal
    requires: [direction]        # ← 方向成为 proposal 的硬前置
```

效果【实测】：`proposal` 在 `direction.md` 存在之前**根本写不出来**（`status` 显示 `blocked by: direction`），`instructions` 会把方向作为依赖注入，`nextSteps` 也会先指向它。schema 落在 `openspec/schemas/<name>/`，**随 git 提交、团队共享**。

**但必须清楚它的边界**（§[03 B4](03-direction-drift.md)）：门控的是**存在**，不是**一致**。空的 `direction.md` 照样让 validate 通过。**它强迫你先写下方向，不保证方向与提案不矛盾。**

> ⚠️ **先算这笔账**：`schema fork` 之后，**这份 schema 是你自己的文件了**。OpenSpec 升级不会更新它——上游改 schema 语义、改 artifact 解析、改 DAG 规则时，你得自己核对、自己追。**这是"方向是一等 artifact"的代价。**
>
> **不想付这笔账**：内置 schema 其实够用——方向本来就活在 `proposal.md` 的 `## Why` / `## What Changes` 里，只缺一个内容检查。用 `rules.proposal` + 一个读 `status --json` 的脚本就能补上，且**升级零成本**。见 §[06](06-remedies-within-budget.md)。

---

## 12 · 跨 change 重叠必须自己查 —— 这是能力之外的活

自带能力对"8 个 change 抢同一个 capability"**完全沉默**。进 change 前自己做个能力矩阵：

```bash
cd openspec/changes
for d in */; do d=${d%/}; [ "$d" = archive ] && continue; \
  caps=$(ls "$d/specs" 2>/dev/null | tr '\n' ' '); \
  [ -n "$caps" ] && echo "$d :: $caps"; done \
| awk '{print $3}' | sort | uniq -c | sort -rn | awk '$1>1'
```

特别盯**同一个 requirement 名的并发 MODIFIED**——那是唯一会在 archive 时炸的地方（见 §[03 B5](03-direction-drift.md)）。

> 说明白：这不是"补它的能力"，这是它能力之外的工作。已有提案 `add-change-stacking-awareness` 想解决，但**未落地**。

---

## 13 · 想要硬闸门，只有两条路 `[外置]`

前 12 条里标 `[硬]` 的，全部来自**代码**（50 KB 预算、校验器、DAG）或**CLI 的 JSON 结构**（分级读）。`config.yaml` 里的三个面**一条都不硬**。

如果空 `direction.md` 能过门、或者"改了方向下游没跟上"这两件事让你难受，唯一能补成硬的办法是**消费 `status --json` 的脚本**：

```text
openspec status --change <name> --json → artifactPaths.<id>.resolvedOutputPath
                                        → 比对 mtime + 检查内容行数
                                        → exit 1 进 CI
```

完整脚本与实测见 §[06.5](06-remedies-within-budget.md)。**这是外置补丁，不是 OpenSpec 能力。**

---

[← 返回索引](answer.md) ｜ 下一篇：[05 · 可复跑验证 →](05-verification.md)
