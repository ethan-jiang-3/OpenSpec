# Plan 14：三套资料 v2.1.1 完全同步计划

> 这是**资料同步的执行账本**，接续 [`_plan-13`](./_plan-13-v2.1.1-full-sync.md) 的 Phase B–D。
> plan-13 管「源码怎么进来」，本计划管「资料怎么改对」。
>
> **状态同步纪律**：本计划的进度与 [`README.md`](./README.md) 顶部的「当前工作状态」表**必须同步更新**。每次推进先勾本计划，再改 README 状态表的「下一步」。只改一边 = 下一次恢复会读错状态。
>
> **为什么需要单独一份**：v2.0 是破坏性大版本，它删掉的不是某个字段，而是**一整套接口层**（命令文件）。靠逐页目测必然漏——漏掉的不是拼写，是「以现在时讲一件已经不存在的事」这类语义错误。所以本计划的前提是：**先定口径，再用口径全量扫描，不靠印象。**

---

## 一、盘面（已实测）

| 目录 | 文件数 | 行数 | 重灾 | 需复核 | 低影响 |
|---|---|---|---|---|---|
| `_digested/` | 112 | 18,496 | 38 | 15 | 59 |
| `_faq_on_digested/` | 102 | 14,300 | 5 | 6 | 91 |
| `_openspec_handbook/` | 20 | 10,660 | 12 | 2 | 6 |
| **合计** | **234** | **43,456** | **55** | **25** | **125** |

「重灾」判定：`/opsx:`·command 类命中 ≥3，或 `delivery` 命中 ≥2。
「需复核」：其它有 ≥2 处 2.x 相关命中的文件。
「低影响」：125 个，多数是纯概念页；**仍需按 §六 的规则过一遍扫描**，只是预期无改动。

## 二、口径基准（SSOT，每条都有源码证据）

**这一节是本计划的核心。所有改动都以这张表为准，不以印象为准。**

| # | 事实（v2.1.1） | 源码证据 |
|---|---|---|
| 1 | 技能共 **12 个**：`openspec-explore` `openspec-new-change` `openspec-continue-change` `openspec-apply-change` `openspec-update-change` `openspec-ff-change` `openspec-sync-specs` `openspec-archive-change` `openspec-bulk-archive-change` `openspec-verify-change` `openspec-onboard` `openspec-propose` | `src/core/config.ts:6` `OPENSPEC_SKILL_NAMES` |
| 2 | `core` profile = **6**：propose / explore / apply / update / sync / archive；`custom` = 全部 12 | `src/core/profiles.ts` `CORE_WORKFLOWS` / `ALL_WORKFLOWS` |
| 3 | **命令文件（`/opsx:*`）已移除**，2.0 起不生成 | `shouldGenerateCommandsForTool` 已不存在于 `src/` |
| 4 | skills **单一真身**在 `.agents/skills/` | `src/core/shared/shared-skill-install.ts` |
| 5 | 其他工具目录放**指向真身的链接**，建不了链接退化为拷贝 | `src/core/shared/skill-links.ts`（`SkillLinkSpot` 五态） |
| 6 | **`delivery` 退役**：配置里不再有，写入不改变行为 | `src/core/command-surface.ts` 三条判定只剩 skills/reconcile |
| 7 | 技能作用域写作 **`skillsScope: project \| global`**，记在 `openspec/config.yaml` | `src/core/project-config.ts:92,454` |
| 8 | **Amazon Q Developer 已退役**，指向 Kiro；`init --tools amazon-q` 报错 | `src/core/retired-tools.ts` + `RETIRED_TOOLS` |
| 9 | 安装层用**运行时依赖 `skills@1.8.1`**；`init`/`update` 从 **npm 包**装，不 clone | `package.json`、`src/core/skill-installer.ts` |
| 10 | `engines.node` = **`>=22.20.0`** | `package.json` |
| 11 | Windows checkout 链接需 `core.symlinks` + 开发者模式 | `docs-lab/help/upgrade-to-2.md` |
| 12 | **34 个命令适配器保留但不再生成**，只做路径解析/清理 | `src/core/command-generation/adapters/`、调用方只剩 migration/reconcile/sweep 等 |
| 13 | 新增 8 个源文件：`skill-installer` `global-skills` `known-projects` `shared-skill-install` `skill-links` `retired-tools` `project-skills-scope` `project-dir`；删除 `templates/optional-workflow.ts` | `git diff v1.17.0 v2.1.1 --name-status -- src` |
| 14 | 测试 **249 文件 / 6510 个**（248 passed + 1 skipped；19 skipped） | `pnpm test`（2026-11-21） |

**调用形式的写法约定**（避免全库出现「通用语法」的错觉）：

- ✅ 正确：「技能 `openspec-propose`；Claude Code 等按 `/openspec-propose`，Codex 按 `$openspec-propose`」
- ❌ 错误：把 `/opsx:propose` 当作当前可用写法
- ⚠️ 允许：明确标注为历史（「1.x 写作 `/opsx:propose`」）

## 三、不可违反的三条既有约定

1. **SSOT 只有一处基线**：`_digested/README.md:5`。FAQ 引用它，handbook 用自己的 `00-index` 版本表。**不要在各文件正文新增「本文以 vX 为准」。**
2. **正文与版本解耦**：正文用现在时描述当前行为；`v1.x.y 起 X` 这类历史溯源**保留不改**，升级时无需动。
3. **handbook 受《内容宪章》约束**（`00-index.md:349`）：禁用 🟢🟡🔴 风险灯；`✅/❌` 同篇 ≤10；H1 下第一行必须有 `>` 定位句；普通主题章不设「下一步」。**`_digested` 与 `_faq` 不受宪章约束。**

## 四、分级清单

### 4.1 重灾 55 个

按命中数排序，**前 20 是主战场**：

| # | 文件 | 命中 | 主要问题 |
|---|---|---|---|
| 1 | `_digested/mechanisms/02-tool-delivery.md` | 97 | delivery 表、生成链、能力矩阵 ✅已改，仍需复核长尾 |
| 2 | `_faq_on_digested/16_upgrade.../answer.md` | 67 | ✅已改主体，需复核 42/54 行 |
| 3 | `_faq_on_digested/12_upstream-roadmap.../answer.md` | 44 | ✅已改版本表与路线图 |
| 4 | `_openspec_handbook/00-index.md` | 40 | ✅已改命令速查；**需复核 82/88/92-98/229/305-312** |
| 5 | `_digested/system/06-源码地图与扩展点.md` | 32 | ✅已加 8 模块，需复核行号与删除项 |
| 6 | `_digested/_coverage/src-coverage.md` | 31 | __未改__ 模块计数与 delivery 描述 |
| 7 | `_digested/spec_cli/01-human-facing-cli.md` | 31 | ✅已改；需复核 331 与全文一致性 |
| 8 | `_openspec_handbook/50-实战-claude-code...md` | 31 | 部分改；**90/152/166/238/244 仍是 commands/opsx** |
| 9 | `_openspec_handbook/99-FAQ-常见问题.md` | 31 | 部分改；**26/28/34/262/300** |
| 10 | `_digested/workflows/00-overview.md` | 25 | ✅已改 |
| 11 | `_digested/system/04-agent-contract-与工具投递.md` | 21 | __未改__ |
| 12 | `_digested/mechanisms/05-cli-infra.md` | 19 | ✅Node 已改；需复核其余 |
| 13 | `_digested/_coverage/tests-coverage.md` | 18 | __未改__ 计数 |
| 14 | `_digested/internal-spec-driven/00-四条命令的共有机制.md` | 18 | __未改__ |
| 15 | `_digested/workflows/12-update.md` | 18 | 头部已改，正文未核 |
| 16 | `_digested/spec_cli/05-config-profile-delivery.md` | 15 | __未改__（标题就带 delivery） |
| 17 | `_openspec_handbook/51-实战-从一个真实-change...md` | 15 | __未改__ |
| 18 | `_digested/spec_cli/06-opsx-call-chains.md` | 14 | __未改__（整篇讲调用链） |
| 19 | `_digested/workflows/03-new.md` | 11 | 头部已改，正文示例未核 |
| 20 | `_openspec_handbook/01-初级-先把-openspec-用起来.md` | 11 | 部分改；**5/81-85/96/123/138/156/297/328** |

其余 35 个（命中 2–10）：`mechanisms/00-map`、`schema/08-用户实例化`、`specs_truth/06-源码锚点与缺口`、`workflows/06-apply`、`spec_cli/README`、`system/00-map`、`_digested/README`、`internal-spec-driven/01-explore`、`spec-driven-capability/_research-long-term...`、`spec_cli/04-command-deep-dive`、`workflows/01-explore`、`_faq/04_.../answer-agent-md-apply-03`、`_openspec_handbook/11-中级`、`spec_cli/08-glossary`、`specs_truth/01`、`specs_truth/02`、`specs_truth/README`、`system/07-工程思想`、`workflows/04-continue`、`_openspec_handbook/52-实战`、`_coverage/specs-coverage`、`mechanisms/04-workflow-templates`、`workflows/02-propose`、`workflows/07-sync`、`workflows/08-verify`、`workflows/09-archive`、`workflows/10-bulk-archive`、`_openspec_handbook/10-中级`、`internal-spec-driven/03-apply`、`specs_truth/03`、`system/08-对照`、`spec_cli/00-map`、`system/README`。

### 4.2 需复核 25 个

按命中排序：`_faq/01_openspec-executable/answer`、`spec_cli/07-command-io-matrix`、`spec_cli/02-machine-facing-cli`、`system/02-目录与状态边界`、`_openspec_handbook/24-store`、`_faq/04_.../answer-agent-md-apply-01/02`、`workflows/05-ff`、`workflows/11-onboard`、`_coverage/doc-assertions`、`internal-spec-driven/02`、`internal-spec-driven/04`、`mechanisms/01-store`、`mechanisms/README`、`schema/07`、`spec_cli/03-workflow-runtime-api`、`system/01`、`system/03`、`_faq/01_.../question`、`_faq/01_.../ts-to-js-and-import`、`_faq/09_.../tasks.md`、`_faq/11_keep-specs-aligned`、`_faq/18_.../06-remedies`、`_faq/18_.../appendix-a-cli-surface`、`_openspec_handbook/20-高级`。

### 4.3 低影响 125 个

不逐条列。按 §六 的 E1 扫描规则批量验证；预期大部分零改动。

---

## 五、执行阶段

### Phase A：基线校准（10 分钟，先做）

- [ ] A1 `_digested/README.md:5` 基线 → `v2.1.1` / `0c737dc1`　✅已完成
- [ ] A2 `_faq_on_digested/README.md` 引用 `_digested` 的 SSOT，**不需要改**；确认无本地版本声明
- [ ] A3 `_openspec_handbook/README.md:3` 表头「手册版本 v1.14 · 对齐 OpenSpec 1.15.0」**仍是旧值** → `v1.16 · 2.1.1 · 2026-11`
- [ ] A4 `_openspec_handbook/00-index.md` 版本表 + v1.16 行 ✅已完成；`对齐 OpenSpec` 两处 → 2.1.1 ✅已完成
- [ ] A5 `_faq_on_digested/12_.../answer.md` 版本表 + 3 行 ✅已完成

**验收**：`grep -rn "1\.17\.0" _digested/README.md _openspec_handbook/00-index.md _openspec_handbook/README.md` 只应出现在历史表行里。

### Phase B：`_digested` 重灾（最大一块）

按 §4.1 前 20 逐条处理。每条的完成标准是**三选一**：

1. 改成 v2.1.1 的现状陈述；
2. 明确标为历史（「1.x / v1.17.0」）并给出当前值；
3. 确认与 2.x 无关（例如纯 spec 语义页），在进度日志写明依据。

重点场次（未改的 5 个先做）：

- [ ] B1 `_coverage/src-coverage.md`：模块计数、`delivery` 描述、8 个新文件
- [ ] B2 `system/04-agent-contract-与工具投递.md`：投递面
- [ ] B3 `_coverage/tests-coverage.md`：**249 文件 / 6510 测试**
- [ ] B4 `internal-spec-driven/00-四条命令的共有机制.md`：入口形态
- [ ] B5 `spec_cli/05-config-profile-delivery.md`：标题与全文（delivery 退役）
- [ ] B6 `spec_cli/06-opsx-call-chains.md`：整篇讲调用链，需按技能名重写
- [ ] B7 `workflows/12-update.md`：`/openspec-update-change` 语义

**验收**：
```bash
grep -rn "delivery" _digested --include="*.md" | grep -v _change_log | grep -vE "1\.x|v1\.1[0-9]|历史|退役|曾经"
# 期望：无输出，或每条都带历史标记
```

### Phase C：`_digested` 需复核 + 低影响扫描

- [ ] C1 25 个需复核文件逐个判定
- [ ] C2 125 个低影响文件跑一次批量扫描（§六 E1）
- [ ] C3 记录「确认无需改」的文件数与依据

### Phase D：`_faq_on_digested`

- [ ] D1 `01_openspec-executable/answer.md`（21):Node 现值、安装路径 ✅部分已改
- [ ] D2 `04_.../answer-agent-md-apply-01/02/03`：apply 入口形态
- [ ] D3 `11_keep-specs-aligned`：入口表述
- [ ] D4 `18_.../06-remedies`、`appendix-a-cli-surface`：CLI 面
- [ ] D5 `_faq_on_digested/README.md` 的「已有问题」索引：16/17 两条描述补 2.x

**验收**：
```bash
grep -rn "/opsx:" _faq_on_digested --include="*.md" | grep -vE "1\.x|v1\.1[0-9]|历史|曾经|→"
# 期望：无输出
```

### Phase E：`_openspec_handbook`（受宪章约束）

- [ ] E1 `00-index.md:82/88/92-98/229/305-312`：入口定义、工具表、术语表示例
- [ ] E2 `01-初级`：5/81-85/96/123/138/156/297/328（含 mermaid 状态图与三个小节标题）
- [ ] E3 `10-中级`：155/157/222 示例
- [ ] E4 `11-中级`：76-81 状态图标签、195
- [ ] E5 `20-高级`：346/390
- [ ] E6 `24-高级`：store 相关（低影响，复核即可）
- [ ] E7 `50-实战`：90/152/166/238/244 目录树与表格
- [ ] E8 `51-实战`：162/167/453/587/668
- [ ] E9 `52-实战`：已批量换名，需复核 36-52 的表格与 279/285/326 的节标题
- [ ] E10 `53-实战`：392/827/832/876/923
- [ ] E11 `55-实战`：58/173-227/298-357/667-705
- [ ] E12 `90-附录`：79/225/227/229 时序图与工具族
- [ ] E13 `99-FAQ`：26/28/34/262/300

**验收（含宪章）**：
```bash
# 1) 无现行 /opsx:
grep -rn "/opsx:" _openspec_handbook --include="*.md" | grep -vE "1\.x|v1\.1[0-9]|历史|曾经|→"
# 2) 宪章：无风险灯
grep -rn "🟢\|🟡\|🔴" _openspec_handbook --include="*.md"
# 3) 宪章：每篇 ✅/❌ ≤10
for f in _openspec_handbook/*.md; do n=$(grep -o "✅\|❌" "$f" | wc -l); [ "$n" -gt 10 ] && echo "$f: $n"; done
```

### Phase F：全局一致性校验

- [ ] F1 **命令已移除**：`grep -rn "/opsx:" 三个目录 | 排除历史行` → 空
- [ ] F2 **delivery 退役**：同上规则
- [ ] F3 **Node 版本**：`grep -rn "22\.12"` → 每条必须与「现值 22.20」同现或标为历史
- [ ] F4 **技能名一致**：12 个名字拼写正确（对照 §二 #1）
- [ ] F5 **skillsScope 拼写**：`grep -rn "skillsScope"` 必须是 `project`/`global`
- [ ] F6 **相对链接零断链**：全量脚本
- [ ] F7 **源码地图行号**：所有 `src/...:N` 锚点不超文件行数（§七 的脚本）
- [ ] F8 **计数一致**：249 文件 / 6510 测试出现在 `_coverage/*`

### Phase G：索引与收尾

- [ ] G1 `_digested/_change_log/README.md` 索引含 0015 与 plan-13/14
- [ ] G2 `_digested/_coverage/doc-assertions.md` 记本轮增量与口径反转
- [ ] G3 plan-13 的 Phase B–D 标注「由 plan-14 接续」
- [ ] G4 本计划勾选完毕、进度日志收尾
- [ ] G5 提交（资料回填单独一个 commit）

---

## 六、批量扫描规则（E1 用）

对任一文件，按顺序判断：

1. **含现行 `/opsx:`** → 必改
2. **含 `delivery` 且非历史** → 必改
3. **含「每个工具各一份 skill」语义** → 必改
4. **含 Node 22.12 且无现值** → 必改
5. **含 Amazon Q 作为可用目标** → 必改
6. **其余** → 判定无需改，登记

**判官标准**：一句话里如果出现「现在/默认/当前」等现在时标志，且描述的是 2.x 已改变的行为，就是错的。反之，只要明确写了 `v1.x`，就是历史，不动。

## 七、辅助脚本

**行号锚点校验**（F7）：

```bash
grep -rhoE '`(src|test|scripts)/[^`]+:[0-9]+`' _digested _faq_on_digested _openspec_handbook \
 | tr -d '`' | sort -u | while IFS=: read -r f n; do
   [ -f "$f" ] || { echo "缺失文件: $f"; continue; }
   total=$(wc -l < "$f")
   [ "$n" -gt "$total" ] && echo "越界: $f:$n (共 $total 行)"
 done
```

**断链校验**：见 plan-13 的 Python 片段（已被验证可用）。

## 八、例外与风险

| 情形 | 处理 |
|---|---|
| 历史溯源（`v1.17.0 起 …`） | **不改**。这是不可变事实 |
| `_change_log/` 下所有文件 | **一律不改**（历史记录） |
| `_faq/18_...` 的 SVG/图表 | 若图内文字含 `/opsx:`，优先改图注而非重画 SVG |
| 概念页（`specs_truth/`、`schema/` 多数） | 2.x 未改 spec 语义，预期零改动；仍需过扫描 |
| 宪章约束的措辞 | handbook 改动若触发风格问题，以宪章为准 |
| 12 个技能名 | 唯一权威是 `src/core/config.ts`，不要凭记忆写 |

**已知风险**：`_digested` 里 40 个文件仍有 `/opsx:`，多数是机制解释中的新旧对照。**不批量替换**——批量替换会毁掉历史语义。策略是「README 定读法约定 + 逐条判断是否现行陈述」。

## 九、进度账本

> 每次推进后：① 勾选对应 checkbox；② 在本节追加一行；③ **同步更新 `README.md` 的「当前工作状态」表**（基线、计划、下一步）。


- **2026-11-21 计划创建**：全量盘点 234 文件 / 43,456 行；分级 55 重灾 / 25 需复核 / 125 低影响；从源码钉死 14 条口径基准。
- **此前已完成**（plan-13 阶段）：源码同步 `1fb874fb`、0015 与 plan-13 `4fd3ff0d`、资料主要落点 `9e4b0dc5`（66 文件）。
- **待办**：Phase A3（handbook README 表头）→ B（6 个未改重灾）→ C/D/E/F/G。

## 十、完成定义（DoD）

本计划完成，当且仅当：

1. §二 的 14 条口径在三个目录里**没有反例**；
2. §五 各 Phase 的验收命令**全部通过**；
3. §4.1 的 55 个重灾文件**每个都有处理记录**（改了 / 标历史 / 无需改+依据）；
4. 全库相对链接 0 断链；
5. `_coverage` 的计数与实测一致；
6. 提交完成，plan-14 勾选完毕。
