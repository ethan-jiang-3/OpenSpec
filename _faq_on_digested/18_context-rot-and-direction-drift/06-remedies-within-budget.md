# 06 · 自带能力之外的补法：`config.yaml` 能撑到哪一步

[← 返回索引](answer.md) ｜ 上一篇：[05 · 可复跑验证](05-verification.md)

> ⚠️ **本章口径与前五章不同。** 前五章只认「装了 `@fission-ai/openspec` 就有」的能力。本章回答的是另一个问题：**自带能力补不上的缺口，用项目里本来就公开给用户的 `config.yaml` / `schema.yaml`，以及消费 CLI 的 JSON 的外部脚本，最便宜的补法是什么。**
>
> 每条都标 `[硬]` / `[软]` / `[外置]`。**`[外置]` 的不属于 OpenSpec**，别混进前五章的清单。

---

## 6.1 先给结论：`config.yaml` 里**没有一条是硬的**

`openspec/config.yaml` 的全部字段，按它能不能拦住人重新排一遍：

| 字段 | 注入到哪 | 性质 | 违反时发生什么 |
|---|---|---|---|
| `schema:` | 解析默认 workflow | **硬**（但只是选择，不是判定） | schema 不存在则报错 |
| `context:` | **每个** artifact + apply + archive | **软** | 什么都不会发生 |
| `rules:` | 仅匹配的 artifact id | **软** | 什么都不会发生 |
| `operations.apply.guidance` | `instructions apply` | **软** | 什么都不会发生 |
| `operations.archive.guidance` | `instructions archive` | **软** | 什么都不会发生 |
| `references:` / `store:` / `githubCopilot:` | 根解析 / 索引 / 文件生成 | 与本题无关 | — |

**一句话**：`config.yaml` 是**投递面**，不是**闸门面**。它决定 agent **看到什么**，不决定 agent **被拦住什么**。

> 这条结论直接解释了前五章的不对称：线 A 的闸门在代码里（`MAX_CONTEXT_SIZE`、校验器），线 B 的"纪律"大多落在 `config.yaml` 和 prompt 模板里，所以线 B 看起来有机制、实际拦不住人。

想拿到硬的，只有三条路：

```text
① schema.yaml 的 DAG          → 硬，但只门控「存在」
② 消费 status/show --json 的脚本 → 硬，可门控「新鲜度 / 重叠」
③ 外部工具（不在本篇范围）      → 例如上游 issue #1387 提到的那类
```

下面 6.2 讲怎么用好三个软面；6.3 讲 ① schema 的硬门控（以及它的三种绕过）；6.4 讲 ② 新鲜度脚本；6.5 讲跨 change 的现状；6.6 是外部参照系。

---

## 6.2 三个软面：分别该放什么

### `context:` —— 放**跨 change 恒真的约束**

`context` 是唯一**每个 artifact + apply + archive 都会注入**的字段。50 KB 上限，超限**整段丢弃**（见 §[02 A3](02-context-rot.md)）。

适合放：

```yaml
context: |
  方向纪律（全项目）：
  - 任何 change 都先写 direction.md；占位或空壳不等于完成。
  - 改上游 artifact 后，必须重新核对下游 artifact 是否仍与方向一致。
  - 实施中发现规格与方向冲突，停下来问，不要静默收窄范围。
```

不适合放：本次 change 的一次性细节、能从代码读出来的事实、长文档全文。

> **为什么这是"最有效的一招"**：它不占 skill 文件的位置，也不需要每次在 chat 里重讲。但它**永远只是提醒**。

### `rules:` —— 放**按 artifact 定向的要求**（含你自己 schema 里的 artifact）

这是 `config.yaml` 里被低估的一个杠杆：**`rules:` 的键可以是自定义 schema 里任意 artifact id**，不限于 `proposal`/`specs`/`design`/`tasks`。

```yaml
rules:
  direction:
    - 每个小节都要有实内容；只有标题说明这道门没跑。
    - 至少写一条被否决的备选方案，并说明它为什么输了。
    - 如果取代了旧方向，点名被取代的那个 archived change。
  freshness:
    - 每个判定都要引用具体的那条方向决策。
    - 没有列出核对过哪些决策时，不许写"全部一致"。
  proposal:
    - 说明本提案实现的是哪一条方向决策（点名）。
```

实测注入正常（详见 §[05](05-verification.md)）：

```text
$ openspec instructions direction --change <name> --json
rules: [ "每个小节都要有实内容…", "至少写一条被否决的备选方案…", … ]
```

⚠️ **键写错的后果比 FAQ 初版描述的更轻**（这是本次复核的修正）：错键会产生 warning，但**只走 stderr，且只有 `instructions` 触发**。`validateConfigRules` 的唯一调用点在 `src/core/artifact-graph/instruction-loader.ts:385`，**`openspec validate --all` 完全不报**。

```text
$ openspec validate --all | grep "Unknown artifact"
（无输出）
```

**实操后果**：如果你的 CI 只跑 `validate --all`，**`rules:` 写错永远不会被发现**，规则会静默地一条都不生效。只能靠人跑一次 `instructions` 检查。

### `operations.*.guidance` —— 放**执行期的建议**（唯一进 apply/archive 的通道）

FAQ 初版**完全没提这个字段**，而它是唯一能把纪律投递到 apply / archive 运行时的面：

```yaml
operations:
  apply:
    guidance:
      - 开工前重读 direction.md；若与 tasks.md 冲突，停下来问，不要静默吃掉漂移。
  archive:
    guidance:
      - 如果这次 change 改变了方向，在归档总结里写明，并指出它的继任者。
```

实测两个面都拿到：

```text
$ openspec instructions apply   --json  → operationGuidance: ["开工前重读 direction.md…"]
$ openspec instructions archive --json  → operationGuidance: ["如果这次 change 改变了方向…"]
```

⚠️ **性质必须说清**：`src/core/archive.ts` 里 `readProjectConfig` 调用数为 **0**。CLI 归档时**不读**这段 guidance，它只在 skill 执行时作为 prompt 投递。**它挡不住任何归档。**

另外两个边界：
- 只支持 `apply` / `archive` 两个 operation id，写别的键会 warning 并列出合法值。
- 它和 `rules:` 是**分开的**：`rules` 约束**产物内容**，`guidance` 约束**做事方式**。别把两者混写。

---

## 6.3 schema 硬门控：能建，但要认清它只门控「存在」

用自定义 schema 把方向做成 proposal 的硬前置，前五章 §[03 B4](03-direction-drift.md) 已讲清。这里只补三条**实测出来的绕过路径**，它们决定这道门到底值多少：

### 绕过路径 ①：空壳文件即通过 ★最重要

```text
$ printf '# Direction\n' > direction.md
$ openspec status --change probe-guarded
[x] direction
[ ] proposal          ← 一行标题就解锁了
```

DAG 只检查文件存在，**不读内容**。所以这道门买到的是"**强制你先停下来说方向**"，不是"方向说清楚了"。

### 绕过路径 ②：`generates:` 复用同一个文件

把后置 artifact 的 `generates` 指向**已经存在的文件**，它会直接读成 `done`：

```yaml
# freshness.generates 指向 direction.md 而不是 freshness.md
- id: freshness
  generates: direction.md      # ← 已有该文件
```

实测：

```text
$ openspec status --change probe-guarded
[x] freshness            ← 没有任何新鲜度检查，白拿一个 done
```

**结论**：`generates:` 是存在性契约，**同一文件可被多个 artifact 复用**。设计 schema 时要保证每个门控 artifact 有**独立的输出文件**，否则闸门形同虚设。

### 绕过路径 ③：先写下游，再补上游

```text
[ ] direction
[x] proposal       ← 直接手写文件绕过了 status 的引导
```

`status` 只是**建议**顺序；`instructions` 会 warning 但仍给出指令。没有任何东西阻止你手写下游文件。

> 这三条合起来说明：**schema 门控是"软门控的硬版本"** —— 它比 prompt 硬（有 `[x]/[ ]` 状态可查），但比真正的校验软（不读内容、可被文件复用绕过、可手写绕过）。**它适合用来对齐节奏，不适合用来当质量闸门。**

### 那 `validate` 能不能扩展成内容校验？

不能，且不是配置能解决的。`src/core/validation/validator.ts` 里 `validateSpec` / `validateChange` 只读 **spec 文件**，没有"自定义 artifact 规则"的钩子，`config.yaml` 也没有任何字段指向校验规则。**内容级校验在自带能力里没有入口。**

---

## 6.4 补「新鲜度」：唯一能做到硬的办法是消费 JSON

前五章 §[02 A6](02-context-rot.md) 指出最大的线 A 缺口是：**没有新鲜度失效，`status` 是文件存在性**。我实测确认：

```text
$ touch -t 202001010000 direction.md     # 把方向文件回退到 2020 年
$ openspec list --changes
probe-guarded     No tasks      just now   ← 仍显示"刚刚"

$ openspec status --change probe-guarded
[x] proposal                               ← 方向比提案旧，照样 [x]
```

**自带能力确实不告诉你"还算不算数"。** 但 `status --json` 暴露了每个 artifact 的 `resolvedOutputPath`，这就够外部脚本做判定：

```json
"artifactPaths": {
  "direction": { "resolvedOutputPath": "…/probe-guarded/direction.md", "existingOutputPaths": [...] },
  "proposal":  { "resolvedOutputPath": "…/probe-guarded/proposal.md",  "existingOutputPaths": [...] }
}
```

### 一个能跑的 `freshness-gate.sh`

判据两条：**方向文件有实质内容**（≥3 行非空非标题），且**所有下游产物都比它新**。

```bash
#!/usr/bin/env bash
# 方向新鲜度闸门：direction.md 必须有内容，且每个下游产物都要比它新。
# 用法: ./freshness-gate.sh <change-name>；通过 exit 0，失败 exit 1。
set -euo pipefail

change="$1"
info=$(openspec status --change "$change" --json)
j() { python3 -c "import sys,json;d=json.loads(sys.argv[1])['artifactPaths'];print((d.get(sys.argv[2]) or {}).get('resolvedOutputPath',''))" "$info" "$1"; }

dir_path=$(j direction)
[ -f "$dir_path" ] || { echo "GATE FAIL: direction.md 不存在"; exit 1; }

# ① 内容闸门：只有标题/空行 = 空壳
body=$(grep -vcE '^\s*#|^\s*$' "$dir_path" || true)
[ "$body" -ge 3 ] || { echo "GATE FAIL: direction.md 只有 $body 行实质内容（需 ≥3）"; exit 1; }

# ② 新鲜度闸门：下游不许比方向旧
drift=0
for a in proposal specs design tasks; do
  p=$(j "$a")
  [ -n "$p" ] && [ -f "$p" ] || continue
  if [ "$p" -nt "$dir_path" ]; then
    :
  else
    echo "STALE: $a 比 direction.md 旧 —— 方向变了，下游没跟上"; drift=1
  fi
done
[ "$drift" -eq 0 ] && echo "GATE PASS: 所有产物都不旧于 direction.md"
exit $drift
```

实测三种状态都对：

```text
# 空壳
GATE FAIL: direction.md 只有 0 行实质内容（需 ≥3）        exit 1

# 有内容、下游都更新
GATE PASS: 所有产物都不旧于 direction.md                   exit 0

# 改了方向，提案没跟上
STALE: proposal 比 direction.md 旧 —— 方向变了，下游没跟上   exit 1
```

### 这个脚本做到了什么、没做到什么

```text
✓ 空壳方向文件过不去（补上 6.3 绕过路径①）
✓ 方向变了而下游没改，会红（补上 A6「改了上游不会让下游失效」）
✓ 补上 A6「specs 无陈旧信号」（把 specs 也纳进比较）
✓ 可进 CI：exit 1 即可让流水线失败

✗ 不判断方向内容对不对（那要语义比对）
✗ 不判断 proposal 与 direction 是否矛盾（同上）
✗ 跨 change 仍然管不了
✗ mtime 会被 git checkout / rebase 重置 —— 用 mtime 是权宜，不是精确的溯源
```

> **诚实边界**：这是 `[外置]` 补丁，不是 OpenSpec 能力。它的价值在于**用不到 30 行把「存在性」升级成「存在性 + 新鲜度」**，而这恰好是自带能力里最明显的洞。

---

## 6.5 跨 change：自带能力补不上，只能手工或外置

`openspec validate --all` 对"8 个 change 抢同一个 capability"完全沉默（实测命中 `overlap|conflict|stack|depend` 的条数为 **0**）。两条现实路径：

**① 手工能力矩阵**（前五章 §[04 要点 12](04-usage.md) 有脚本）——配合 CI 里 grep 产物即可，成本最低。

**② 消费 `show --json` 自己比对**——`openspec show <id> --json --deltas-only` 给出每个 delta 的 `operation` 和 `requirement`，能做出"两个 change 改同一条 requirement"的检测。但要注意：**delta 里没有记录它是从哪个 base 派生的**，所以只能检测**名字撞车**，检测不出「main 已经往前走、我的 MODIFIED 还是旧文本」的**语义漂移**。

上游对这块的现状（截至本文基线 `v1.14.3`）：

| 提案 | 状态 | 覆盖 |
|---|---|---|
| `openspec/changes/add-change-stacking-awareness/` | **未落地**（卡 3/4） | `dependsOn`/`provides`/`requires`/`touches`/`parent` + `change graph` |
| [issue #1915](https://github.com/Fission-AI/OpenSpec/issues/1915) | open | `depends_on` 元数据 + list 可见性 + new change 时提案 |
| [issue #1387](https://github.com/Fission-AI/OpenSpec/issues/1387) | open（`design-review`） | 归档前 drift / overlap 检测，社区附了可用工具 |

> #1387 里点出的根因值得记：**delta 只记录 MODIFIED 的新文本，不记录它派生自哪个 base**。这是自带能力做不出语义漂移检测的结构性原因，不是缺个命令。

---

## 6.6 外部参照系：这两个问题别人怎么分层解（外部来源，非 OpenSpec 能力）

> 本节引用第三方材料，仅用于**说明解法分层**，不代表 OpenSpec 的官方定位。技术事实以 §[05](05-verification.md) 的实测为准。

一篇拆源码的横向对比把三个框架摆在同一条轴上：它们治的是 context rot 的**不同层**——

| 层 | 症状 | 典型解法 |
|---|---|---|
| **契约腐烂** | 需求在长对话里漂走了 | 把需求搬到版本化文件（OpenSpec 的自定位） |
| **纪律腐烂** | 流程被执行时偷懒（跳过测试、跳过评审） | 自动触发的 skill、硬门禁 |
| **注意力腐烂** | 上下文本身变长后模型变笨 | fresh-context subagent、跨会话状态文件 |

按这个分层，本篇的两条线可以重新读一遍：

- **线 A（腐化）** 在 OpenSpec 里主要靠**结构性做法**解决 —— 把状态放到磁盘（`tasks.md` 的 checkbox、`sourcePath`+`line`）、注入导航简报而非正文。这正是"清空上下文再 `apply`"有效的原因。
- **线 B（漂移）** 在 OpenSpec 里止于**单次归档正确性**。跨 change 的排序与重叠、方向的一致性，属于上表里"它不治"的部分。

对"我使用时该注意什么"的直接含义：

```text
如果你的症状是「AI 忘了最初要做什么」   → 前五章的机制已经够用，重点用分级读 + 清上下文
如果你的症状是「多个 change 打架」       → 需要外置检测（6.5），等上游落地
如果你的症状是「长会话里模型变钝」       → 这不是 OpenSpec 要解决的问题，靠切会话/subagent
```

References:

- [Effective context engineering for AI agents](https://raw.githubusercontent.com/tim-kaa-py/ai-wiki/aa5aca2d11cf355f8b39187403eaae74aa477266/summaries/2025-09-29_anthropic_effective-context-engineering.md)
- [GSD 完胜 OpenSpec 和 Superpowers？源码拆完发现：三者防的是 context rot 的三道防线](https://cloud.tencent.cn/developer/article/2704830)
- [OpenSpec issue #1387 · Pre-archive drift and overlap checking](https://github.com/Fission-AI/OpenSpec/issues/1387)
- [OpenSpec issue #1915 · depends_on change metadata](https://github.com/Fission-AI/OpenSpec/issues/1915)

---

## 6.7 一张表：缺口 → 最便宜的补法 → 硬度

| 缺口（来自 §02 A6 / §03 B5-B6） | 最便宜的补法 | 硬度 | 落点 |
|---|---|---|---|
| 方向没有机器表示 | 自定义 schema 加 `direction` artifact | **硬（存在性）** | `schema.yaml` |
| 空壳方向文件能过门 | `freshness-gate.sh` 的内容判定（≥3 行） | **硬** | `[外置]` CI |
| 改了上游，下游不失效 | 上述脚本的 mtime 比较 | **硬（近似）** | `[外置]` CI |
| specs 无陈旧信号 | 把 `specs` 纳入同一比较 | **硬（近似）** | `[外置]` CI |
| 方向与提案矛盾 | 无自动解；靠 `update` 双向复核 | 软 | `[软]` prompt |
| 跨 change 重叠 | 手工能力矩阵 / 消费 `show --json` | 手工或 `[外置]` | 脚本 |
| 跨 change 语义漂移 | **无解**（delta 不记 base） | — | 等上游 #1387 |
| `rules:` 写错静默失效 | CI 里跑一次 `instructions` 检查 stderr | 手工 | `[外置]` |
| 规则被模型忽略 | 无解（全是 prompt） | — | — |

**读这张表的方式**：左列是"自带能力承认做不到"的，右列是"你能补的"。**中间那列标 `[外置]` 的，都不是 OpenSpec**。别在评审时说"OpenSpec 能防腐化"——它能防的是**注入体膨胀**，防不了**语义陈旧**。

---

[← 返回索引](answer.md) ｜ [附录 A · CLI 命令面 →](appendix-a-cli-surface.md)
