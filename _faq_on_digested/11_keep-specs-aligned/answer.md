# 答案：怎么别让 main specs 和代码对不上

## 一句话

**别把 specs 当一次性产物。日常就活在 explore → propose → apply → archive 这个圈里，而 specs 只在 archive 那一步更新。所以 apply 完记得 archive；apply 改代码时顺手想一句"这段 spec 还准吗"；感觉不对就用 propose 写个 change 去 archive。平时几乎不用手碰 spec 文件。**

> **v1.8.0 边界。** “只在 archive 更新”说的是 main spec 的程序化归档路径；agent sync 可以在 archive 前做 early-sync，archive 对完全一致的结果会幂等 no-op。capability ID 是 `specs/` 下的相对 path（可为 `identity/session`），不是仅仅末级目录名；这些路径层次不提供自动检索或消除上下文预算。（v1.7.0 引入，v1.8.0 不变。）

## 先分清两件事

很多人把两件不同的事混成一团，先拆开：

| | archive 那一刻的 delta 合并 | 长期的 specs ↔ 代码漂移 |
|---|---|---|
| 什么时候发生 | 一次 `archive` 的瞬间 | 日子久了慢慢攒出来的 |
| 谁和谁对 | change 的 delta → 主 spec | 主 spec ↔ 真实代码 |
| 归谁管 | [`../07_archive-ready-to-archived/`](../07_archive-ready-to-archived/question.md) | **本篇** |
| 一句话 | "这一次改动怎么进 specs" | "specs 整体还对不对得上代码" |

本篇只讲后者。前者（archive 那一刻 delta 怎么并进 specs）已经有专门一篇了。

## 日常就一个圈：explore → propose → apply → archive

不用记复杂规则。日常就一个圈：**explore → propose → apply → archive**——由宿主 workflow 推进，`archive` CLI 完成程序化归档（Claude 的 `/opsx:*` 与 Codex 的 `$openspec-*` 只是不同入口）。`validate`/`list`/`view` 是只读的 CLI 工具命令，偶尔用，**不在圈里**。（CLI 命令 vs host workflow 的完整对照见 [`../../_digested/specs_truth/README.md`](../../_digested/specs_truth/README.md)；`validate` 查什么见 [`06`](../../_digested/specs_truth/06-源码锚点与缺口.md)。）

```text
explore    感觉要改、读代码判断要不要动          ← "spec 可能要修" 的入口
   │
   ▼
propose    写 change：proposal + delta(specs 怎么改)  ← 修 specs 的正道在这一步
   │
   ▼
apply      按 tasks 改代码                        ← 改代码时想一句"spec 还准吗"
   │
   ▼
archive    校验 + 把 delta 合进主 spec + 收档      ← ★ specs 只在这一步被更新
   │
   └──── 回到 explore（下一个改动）
```

关键一句：**specs 的更新只发生在 archive**。apply 只改代码，不会动 spec；apply 完不 archive，specs 就永远停在旧版本——这是最常见的失真来源。所以"别让 specs 对不上"的核心，就是别让 change 卡在 apply 之后、要走完到 archive。

下面三节就是把这个圈拆成"平时习惯 / 怎么发现 / 怎么修"。

## 1）平时的习惯（怎么别让它对不上）

最常见的几条，照着做基本就不会跑偏：

- **apply 完就 archive，别卡着** —— specs 只在 archive 时更新。change 停在 apply 之后不归档，是最常见的失真 + 噪声源（它要么指向早不存在的方向，要么没建完）。走完圈、到 archive 收尾。
- **改 requirement 名字走 RENAMED，别"删旧 + 加新"** —— requirement 没有稳定 ID，身份就是它的标题。删了再加等于把历史连续性掐断，以后任何指向旧名字的 delta 都失配。
- **apply 改代码时，顺手想一句"这段 spec 还准吗"** —— 最廉价的对齐动作。改完一个行为，花 10 秒问：spec 里有没有描述这个？我这一改让它更准还是更不准？不准就在下一个 propose 的 delta 里带上。
- **capability relative path = 它的身份，别随意搬** —— `openspec/specs/<capability-path>/spec.md` 的相对 path（可嵌套）就是 capability ID，也是 delta 的靶心。requirement 改名还有 `RENAMED`；capability path 仍没有独立 rename operation，裸搬会让旧 path 的 delta 悬空。所以完整 path 当稳定性契约对待。（详见 [`../../_openspec_handbook/09-高级-能力身份与specs漂移维护`](../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md)。）
- **别手改主 spec** —— 要改就走 propose（写 delta）再 archive。手改是核选项，而且改完没有任何工具知道你动过。

（`openspec validate` 是真实的 CLI 命令（和 `archive` 同列），但**不是工作流一步**——archive 自己会先校验，平时不用单独跑它；而且它只查结构、查不出 specs↔代码漂移，见误区 1 和 [`06` validate 命令参考](../../_digested/specs_truth/06-源码锚点与缺口.md)。）

## 2）怎么感觉 main spec 要修了

出现下面这些信号，就该想想 spec 是不是漂了——多数就藏在那个四步圈里：

- **agent 读了 spec 后，做出和现状矛盾的判断** —— 最直接、也最刺耳的信号。它按 spec 说"应该有 X"，可代码里是 Y。spec 在骗它。
- **apply 改代码时发现：spec 说应该 X，但我正把它改成 Y** —— 你自己就是那个让 spec 失真的人，改的时候就该顺手把 spec 也对上（下一个 propose 带上）。
- **archive 报 `... not found`** —— delta 指向的 requirement 标题在主 spec 里找不到。这几乎都是"标题被改过 / spec 被别的 archive 重写过"，漂移被抓现行了。
- **新功能/新命令上线了，specs 里只字未提** —— 反向漂移：代码有了（apply 完了），但没 propose + archive 进 specs。
- **瞄一眼 `openspec list`，挂着一堆很久没人动的 change** —— 多半是没走完圈、卡在半路的废弃/没建完方向，本身是噪声，还可能指向已不存在的目标。

## 3）怎么修（最常见的几种）

修 specs 的正道就是回到那个圈：用 **propose 写 delta，再 archive**。这里只给平时最常用的**四招**（修复原语 + 清除原语的短版）；另外还有 `/opsx:sync`（LLM 重对齐）、手改再基线（核选项）、前置纪律、巡检——日常用不到，全貌见 [`03`](../../_digested/specs_truth/03-手段清单-到底有多少种修法.md)。

### 招一：内容失准（spec 说错了 / 说多了）→ propose 改，再 archive

```bash
openspec new change fix-<something>      # 这一步就是 propose，脚手架出 change
# 编辑 changes/fix-<something>/specs/<capability>/spec.md：
#   ## MODIFIED Requirements   ← 整块换成正确版本
#   ## REMOVED Requirements    ← 要删的，只写名字
openspec archive fix-<something> -y      # archive 会先校验，再把 delta 合进 spec
```

注意：`MODIFIED` 是**整块替换**，名字要和当前 spec 里的标题**逐字一致**，否则 archive 报 not found。

### 招二：漏了能力（代码有、spec 没）→ propose 用 ADDED 补

```bash
openspec new change add-<capability>-spec
#   ## ADDED Requirements   ← 如实描述代码里已经发运的行为
openspec archive add-<capability>-spec -y
# 新 capability delta 可先写 ## Purpose；archive 会带入 main spec
```

### 招三：噪声 change（废弃了 / 没建完 / 早被别的方向取代）→ 挪走或删

```bash
# 设计还有参考价值 → 搁置（可逆，推荐）
mv openspec/changes/<dead-change> openspec/explorations/
# 死透了 / 重复 / 明显错方向 → 删（不可逆，慎用）
rm -rf openspec/changes/<dead-change>
```

openspec 没有"删除 change"的命令，这一步就是文件操作。拿不准就搁置（可逆优先）。

### 招四：archive 报 `not found` → 先 grep 当前标题，对齐 delta

```bash
# 先看主 spec 里现在到底叫什么名字
grep -nE "^### Requirement:" openspec/specs/<capability>/spec.md
# 把 delta 里的名字改成和 spec 逐字一致，再 archive
openspec archive <change> -y
```

只有当整段已经面目全非、对不上号时，才升级到宿主 sync workflow（Claude 示例 `/opsx:sync`；让 agent 重对齐），或手改 spec + 再写个 rebaseline change——这是最后手段，平时用不到。

## 常见误区

### 误区 1：以为 `validate` 能查出 specs 和代码对不上

`validate` 是**真实的 `openspec` CLI 命令**（和 `archive` 同列，**不是** `/opsx:` slash 技能）——别误以为它不存在或是什么隐藏功能。但它只是**结构 linter**：只查文件结构（段头/`SHALL`/`MUST`/scenario/僵尸 change），**从不打开主 spec、抓不出 specs↔代码漂移**；而且 `archive` 自己默认就先校验，平时不用单独跑它。所以"specs 对不对得上代码"靠走完四步圈的习惯，不是 `validate`。（完整边界见 [`02` 缺口一](../../_digested/specs_truth/02-漂移与噪声-为什么主specs会失真.md) 和 [`06` validate 参考](../../_digested/specs_truth/06-源码锚点与缺口.md)。）

### 误区 2：手改主 spec 最快

是快，但埋的是长期失配地雷。requirement 身份就是标题文本，你手改了标题，以后所有指向旧标题的 delta 全失配，而且**没有任何工具会告诉你改过**。要改就走 propose（写 delta）再 archive。

### 误区 3：apply 完代码就完事了，忘了 archive

apply 只改代码，**specs 只在 archive 时才更新**。不 archive，spec 就永远停在旧版本，下一次 agent 读到就被带偏。"apply 完就 archive"就是专门防这个的——这比任何"改完代码想 spec"都更根本。

### 误区 4：废弃的 change 留着也无害

有害。它给 agent 释放"这里有个进行中方向"的假信号，还可能指向已不存在的目标，长期堆着就是噪声。不做了就挪走（`explorations/`）或删掉。

## 结论

把 specs 当**和代码一起活的活文档**，不是写完就锁起来的产物。日常就一个圈——explore → propose → apply → archive——**specs 只在 archive 时更新**。守住三件套：

- **平时的习惯**：走完圈、apply 完就 archive；改名走 RENAMED；apply 改代码时想一句 spec；capability 名别乱改；别手改主 spec。
- **会看信号**：agent 自相矛盾、apply 时发现 spec 说 X 你改 Y、archive 报 not found、新功能没进 spec。
- **会用圈来修**：内容失准/漏能力 → propose 写 delta 再 archive；噪声 change → 挪走。

想看全貌（机理、六类噪声、原语、决策矩阵、实战走查），去 [`../../_digested/specs_truth/`](../../_digested/specs_truth/)。

## 参考来源

源码引用以 v1.8.0（`e50bd09`；release tag `v1.8.0` = `d578896`）为当前基线：

| 来源 | 用到的结论 |
|---|---|
| [`../../_digested/internal-spec-driven/00-四条命令的共有机制.md`](../../_digested/internal-spec-driven/00-四条命令的共有机制.md) | 四步圈 explore/propose/apply/archive 是核心工作流 |
| [`../../_digested/specs_truth/01-机理-主specs如何被delta构造.md`](../../_digested/specs_truth/01-机理-主specs如何被delta构造.md) | specs 由 delta 经 archive 累加；requirement 无 ID、身份=标题；archive 是唯一写入动词 |
| [`../../_digested/specs_truth/02-漂移与噪声-为什么主specs会失真.md`](../../_digested/specs_truth/02-漂移与噪声-为什么主specs会失真.md) | 失真信号：悬空目标、有代码无 spec、冻结 spec、废弃 change、身份脆弱性 |
| [`../../_digested/specs_truth/03-手段清单-到底有多少种修法.md`](../../_digested/specs_truth/03-手段清单-到底有多少种修法.md) | 修法：纠正型 delta、AUTHOR-NEW、DELETE/SHELVE |
| [`../../_digested/specs_truth/04-问题到方法-决策矩阵与排错.md`](../../_digested/specs_truth/04-问题到方法-决策矩阵与排错.md) | `archive ... not found` 怎么排错 |
| [`../../_digested/specs_truth/06-源码锚点与缺口.md`](../../_digested/specs_truth/06-源码锚点与缺口.md)（validate 命令参考） | `validate` 是 CLI 命令（非 slash）、结构 linter、抓不出漂移；archive 自校验使单独 validate 冗余 |
| [`../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md`](../../_openspec_handbook/09-高级-能力身份与specs漂移维护.md) | capability=specs 相对 path=身份、capability 无独立 rename；specs 漂移与维护（用户向） |
| `src/core/specs-apply.ts` | `buildUpdatedSpec`：MODIFIED 整块替换、按标题精确匹配、原子 fail-fast |
| `src/core/validation/validator.ts` | `validateChangeDeltaSpecs` 只读 change delta、不打开主 spec（误区 1 的根） |
