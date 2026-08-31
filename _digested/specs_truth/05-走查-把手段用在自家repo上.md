# 走查与运维：一套可重复的 specs 对齐 playbook

本文用本 repo（OpenSpec 自身）的真实漂移项，演示怎么把 `02`/`03`/`04` 串成**一套可重复的对齐流程**，并给出**优先级规则**。它是 playbook，不是"你看着办"的演示——下面每一步都给了判断和顺序。

> 文中的漂移项是写作时快照（真实、已逐一指认），repo 会演化，动手前复核现状。本文不替你执行对真实 `openspec/` 的改动（只给 recipe）——这条只说一次。

## 优先级规则（先做哪类，后做哪类）

按"**可逆/低风险先，重/不可逆后**"排：

1. **先清噪声**（清除原语 SHELVE/DELETE）：① 悬空、④ 废弃 change——可逆（SHELVE 优先）、立刻让 `list`/`validate --all` 干净，几乎零风险。
2. **再做小纠正**（修复原语，少量明确的 MODIFIED/REMOVED/RENAMED）：③ 冻结 spec 的小偏差。
3. **更新结构 spec**（修复原语）：⑤ conventions 过时这类。
4. **最后做重活**：② AUTHOR-NEW 写新能力 spec（要读代码、如实描述，最费工，等方向稳定后再写）；⑥ 里整段面目全非的再基线（核选项，不可逆地丢历史连续性）。

记住一条：**能 SHELVE 就别 DELETE；能用 delta 修就别手改再基线。**

## 一次巡检的产出（漂移清单）

巡检（`03` 元实践二）产出一份清单，分类后套原语。下面六项是本 repo 的真实清单（信号→原语映射的总表见 `02`/`03`，不在此重复）。

### 项 1：`add-change-stacking-awareness` 等（信号 ① 悬空目标）— 清除原语

现状：active change，delta 指向 `specs/` 里没有的 capability（`change-stacking-workflow/` 等）；`tasks.md` 0 进度；代码零实现；4 个月没动。诊断：设计了没建，不是"做完了没 archive"。

走法（SHELVE）：

```bash
mkdir -p openspec/explorations
mv openspec/changes/add-change-stacking-awareness openspec/explorations/
openspec validate --all     # 那几项 ✗ 应消失——只证明这几个僵尸（④结构）清了，不证明 specs 对齐
```

同形态（一并 SHELVE）：`add-global-install-scope`、`add-qa-smoke-harness`、`unify-template-generation-pipeline`、`add-tool-command-surface-capabilities`。

### 项 2：`simplify-skill-installation`（信号 ⑥ 身份脆弱性 + ①）— 清除 + 修复

现状：tasks 90/90、代码齐；但 16 条 MODIFIED/RENAMED 目标全和当前 `cli-init`/`cli-update` 对不上（spec 被后续 archive 重写）。archive 报 `not found`、整批回滚（完整诊断见 `04`）。

走法（路 B：弃旧重做，代码已是既成事实时更干净）：

```bash
mv openspec/changes/simplify-skill-installation openspec/explorations/   # 过时 delta 搁置
openspec new change add-profiles-and-propose-workflow-capabilities        # = propose
#   specs/profiles/spec.md         → ## ADDED（读 src/core/profiles.ts 写实）
#   specs/propose-workflow/spec.md → ## ADDED（读 src/core/templates/workflows/propose.ts 写实）
openspec archive add-profiles-and-propose-workflow-capabilities -y        # 自校验+合并；补 ## Purpose
```

`cli-init`/`cli-update` 的内容对齐留给单独的纠正型 change（别和补 spec 混在一起）。

### 项 3：`cli-view` 冻结错误串（信号 ③ 冻结 spec）— 修复原语

现状：spec 写 `"✗ No openspec directory found"`，代码是 `'No openspec directory found'`（无 `✗`）。小偏差，但够让照 spec 的断言失败。

走法（MODIFIED 整块替换，只改那行串；archive 自校验）：

```bash
openspec new change fix-cli-view-error-string
# specs/cli-view/spec.md → ## MODIFIED Requirements → ### Requirement: Dashboard Display（整块，标题逐字等于当前 spec，含全部 scenario；把错误串改对）
openspec archive fix-cli-view-error-string -y
```

## 全貌与真正的成功指标

| 项 | 信号 | 原语 | 动作 |
|----|------|------|------|
| add-change-stacking-awareness 等 5 项 | ① | 清除 | SHELVE |
| simplify-skill-installation | ⑥+① | 清除+修复 | SHELVE 旧 delta；AUTHOR-NEW profiles/propose-workflow |
| cli-view 错误串 | ③ | 修复 | 纠正型 delta |

**真正的成功指标**：active `changes/` 清空噪声 + specs 覆盖所有已发运 capability + conventions 反映真实结构。这三条才是"specs 配得上 source of truth"。至于 `validate --all` 失败归零——那只是"僵尸 change（④）清了"的**副产品**，**只证明结构干净，不证明 specs 和代码对齐**（①②③ 它根本不查）。

## 守住的边界

走查的价值不在一次性大扫除，而在建立**可重复的 巡检 → 分类 → 按优先级套原语 → delta+archive 落地** 的节奏（运维循环图见 `07` 图4）。每一项都走受控流水线，不手搓 spec；按上面的优先级规则排顺序，可逆先做、重活后做。

## 继续阅读

- 原语详解：`03-手段清单-到底有多少种修法.md`
- 排错（not found 诊断树、跨 change 冲突）：`04-问题到方法-决策矩阵与排错.md`
- 噪声分类：`02-漂移与噪声-为什么主specs会失真.md`
- 给已有代码补 spec 的采用流程：`08-给已有代码补spec-greenfield.md`
