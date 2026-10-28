# 06 · 自带能力之外的补法：只用内置 schema

[← 返回索引](answer.md) ｜ 上一篇：[05 · 可复跑验证](05-verification.md)

> ⚠️ **本章口径与前五章不同。** 前五章只认「装了 `@fission-ai/openspec` 就有」的能力。本章回答的是另一个问题：**自带能力补不上的缺口，用 `config.yaml` 和消费 CLI 的 JSON 的脚本，最便宜的补法是什么。**
>
> **另一个约束也变了：本章完全不用自定义 schema。** 只用内置的 `spec-driven`（`proposal` / `specs` / `design` / `tasks`）。理由很实际——**自定义 schema 是你自己维护的文件，OpenSpec 每次升级都可能改 schema 语义、改 artifact 解析、改 DAG 规则，你的 fork 就得跟着追**。内置 schema 随包升级，你不用管。
>
> 所以 [03 · §B4](03-direction-drift.md) 讲的「用自定义 schema 给方向建硬前置」在**理论上**成立，但**维护成本高**。本章给的是不需要它也能走的路。
>
> 每条都标 `[硬]` / `[软]` / `[外置]`。**`[外置]` 的不属于 OpenSpec**，别混进前五章的清单。

---

## 6.1 先给结论

两句话：

```text
config.yaml 里没有一条是硬的 —— 它是投递面，不是闸门面
内置 schema 也没有「方向」这个 artifact —— 方向就活在 proposal.md 里
```

第一句解释了为什么线 B 看起来有机制、实际拦不住人：线 B 的"纪律"大多落在 `config.yaml` 和 prompt 模板里。

第二句是本章的关键前提。内置 `spec-driven` 的四个 artifact 是：

```text
proposal  generates: proposal.md        requires: []
specs     generates: specs/**/*.md      requires: [proposal]
design    generates: design.md          requires: [proposal]
tasks     generates: tasks.md           requires: [specs, design]
```

**没有 `direction`，没有 `decision`，没有任何"意图层" artifact。** 方向不在任何独立的文件里。

---

## 6.2 那么「方向」到底存在哪？——`proposal.md`

答案是：**它已经在 `proposal.md` 里了**，只是没人把它当方向看。

看内置模板（`schemas/spec-driven/templates/proposal.md`）：

```markdown
## Why
<!-- Explain the motivation for this change. What problem does this solve? Why now? -->

## What Changes
<!-- Describe what will change. Be specific about new capabilities, modifications, or removals. -->

## Capabilities
## Impact
```

`## Why` + `## What Changes` **就是方向**：为什么要做、要做成什么样。后面的 `specs` / `design` / `tasks` 全是它的展开。

所以不需要新造 artifact。**你需要的只是承认这件事，然后给它加上约束和检查。**

### 关键实测：内置能力对 `## Why` 的内容**零检查**

我建了一个 proposal，`## Why` 和 `## What Changes` 里**只剩模板注释**：

```markdown
# Proposal

## Why

<!-- Explain the motivation. What problem does this solve? Why now? -->

## What Changes

<!-- Describe what will change. -->
```

`openspec status` 的判定：

```text
[x] proposal        ← 有文件就算完成
[ ] specs
```

`openspec validate` 唯一的抱怨是"没有 delta"：

```text
✗ [ERROR] Change must have at least one delta.
```

**没有任何一条检查 `## Why` 是不是空的。** 模板注释本身就足以让 proposal 读成 `[x]`。

> 这就是"方向漂移"能在工具眼皮底下发生的原因：**方向的位置是有的（proposal.md），但对它的检查是零。**

---

## 6.3 `config.yaml` 三个面：都软，但都用得上

### `context:` —— 放跨 change 恒真的方向纪律

唯一**每个 artifact + apply + archive 都会注入**的字段。50 KB 上限，超限整段丢弃（见 §[02 A3](02-context-rot.md)）。

```yaml
context: |
  方向纪律（全项目）：
  - proposal.md 的 ## Why 与 ## What Changes 是方向本身。
  - 改方向 = 改 proposal；改完必须回头核对 specs/design/tasks 是否还成立。
  - 实施中发现规格与方向冲突，停下来问，不要静默收窄范围。
```

> 注意：**别在这里写"必须写 direction.md"这种话**——内置 schema 里没有这个文件，写了只会让 agent 去找一个不存在的东西。

### `rules:` —— 按内置 artifact 定向提要求

`rules:` 的键就是内置的四个 id，不需要自定义 schema：

```yaml
rules:
  proposal:
    - "## Why 必须写清要解决的问题和为什么是现在，不能只留模板注释。"
    - "至少写一条被否决的备选方案，写清它为什么输。"
    - "如果这次换掉了先前方向，点名被取代的那个 archived change。"
  specs:
    - 每条 requirement 都能追到 proposal 的某一条 What Changes。
```

实测注入正常：`instructions proposal --json` → `rules: 3 条`。

> ⚠️ **一个实测踩到的坑，值得单独记**：上面第一条我最初写成不带引号的
>
> ```yaml
>     - ## Why 必须写清…
> ```
>
> YAML 把行首的 `##` 当**注释**，整条读成 `null`，于是 **整个 `proposal` 的 rules 全部被丢弃**：
>
> ```text
> Rules for 'proposal' must be an array of strings, ignoring this artifact's rules.
> rules.proposal[0] is null — an unquoted ": " makes YAML read the item as a key/value pair; quote the whole scalar to keep it a string.
> ```
>
> **一条写错，整组失效。** 规则里出现 `##`、`:` 这类字符时，**整条加引号**。同一文件里 `context:` 是块标量所以不受影响，`rules:` 是列表所以受影响——这个不对称很容易踩。

### `operations.*.guidance` —— 唯一进 apply/archive 的通道

FAQ 初版没提这个字段。它把纪律投递到**执行期**，而不是写作期：

```yaml
operations:
  apply:
    guidance:
      - 开工前重读 proposal.md 的 ## Why；若与 tasks.md 冲突，停下来问，不要静默收窄。
  archive:
    guidance:
      - 如果这次改变了方向，在归档总结里写明，并指出继任者。
```

`instructions apply|archive --json` 都返回 `operationGuidance` 数组（实测）。

**必须知道的边界**：

- 只支持 `apply` / `archive` 两个 id，写别的会 warning 并列出合法值
- 和 `rules:` 分工不同：`rules` 管**产物内容**，`guidance` 管**做事方式**
- **归档时 CLI 不读它**（`src/core/archive.ts` 里 `readProjectConfig` 调用数为 0）——纯 prompt 投递，**挡不住任何归档**

---

## 6.4 内置 schema 的门控：能给你什么，不能给你什么

内置 DAG 本身是硬的——`tasks` 在 `specs` 和 `design` 存在前写不出来：

```text
[ ] proposal
[-] specs   (blocked by: proposal)
[-] design  (blocked by: proposal)
[-] tasks   (blocked by: specs, design)
```

但**这个门控只覆盖"四件套齐全"，不覆盖"方向一致"**。三个绕过路径都成立：

| 绕过 | 做法 | 结果 |
|---|---|---|
| 空壳 proposal | `## Why` 只留模板注释 | `[x] proposal` ✅ |
| 手写下游 | 直接创建 `tasks.md` 绕过 `status` 引导 | `[x] tasks` ✅ |
| 顺序无约束 | `status` 只是**建议**，不是强制 | 没有任何东西拦你 |

第一条我实测过（见 §6.2）。`status` 和 `instructions` 会引导顺序，但你手写文件，它们不会拒绝。

> **一句话**：内置 DAG 买到的是**节奏对齐**（四件套齐全、按顺序写），不是**方向一致**。想要后者，得自己加检查。

---

## 6.5 补「方向检查 + 新鲜度」：一个只用内置产物的脚本

前五章 §[02 A6](02-context-rot.md) 指出最大的缺口是：**没有新鲜度失效，`status` 是文件存在性**。我实测确认——把 proposal 的 mtime 回退到 2020 年，`status` 照样 `[x]`、`list` 照样显示 "just now"。

内置能力不告诉你"还算不算数"。但 `status --json` 暴露了每个 artifact 的实际文件路径，够外部脚本判定。

### 一个关键细节：`specs` 的路径是 glob

内置 schema 里 `specs` 的 `generates` 是 `specs/**/*.md`，所以：

```json
"specs": {
  "resolvedOutputPath": "…/p1/specs/**/*.md",          ← 保留 ** 字面量，不能当文件用
  "existingOutputPaths": ["…/p1/specs/cap-a/spec.md"]  ← 真实文件列表
}
```

**脚本必须用 `existingOutputPaths`**，不能对 `resolvedOutputPath` 做 `-f` 判断。

### `direction-gate.sh`（只用内置产物）

判据两条：**proposal 的 `## Why` / `## What Changes` 有实质内容**（不是只剩模板注释），且 **`specs`/`design`/`tasks` 都不严格早于 `proposal.md`**。

```bash
#!/usr/bin/env bash
# direction-gate.sh —— 只用内置 spec-driven 产物，把「方向」钉在 proposal.md 上
# 通过 exit 0；失败 exit 1。用法: ./direction-gate.sh <change-name>
set -uo pipefail
change="${1:?usage: direction-gate.sh <change>}"
info=$(openspec status --change "$change" --json) || { echo "GATE FAIL: 取不到 status"; exit 1; }
exec python3 - "$info" <<'PY'
import json, sys, os, re, glob

arts = json.loads(sys.argv[1])['artifactPaths']

def files(aid):
    """内置 schema 的 specs 是 glob，resolvedOutputPath 会保留 ** 字面量；
    existingOutputPaths 才是真实文件列表。"""
    v = arts.get(aid) or {}
    ex = v.get('existingOutputPaths') or []
    if ex:
        return ex
    r = v.get('resolvedOutputPath')
    if not r:
        return []
    return sorted(glob.glob(r)) if any(c in r for c in '*?') else [r]

fails = []

prop = next((p for p in files('proposal') if p.endswith('proposal.md')), None)
if not prop or not os.path.exists(prop):
    print('GATE FAIL: proposal.md 不存在')
    sys.exit(1)

text = open(prop, encoding='utf-8').read()

def section(name):
    m = re.search(rf'^##\s*{name}\s*$(.*?)(?=^##\s|\Z)', text, re.M | re.S | re.I)
    return m.group(1) if m else ''

def substance(body):
    """去掉模板注释和空行后还剩几行实内容。"""
    body = re.sub(r'<!--.*?-->', '', body, flags=re.S)
    return [l for l in (x.strip() for x in body.splitlines())
            if l and not l.startswith('#') and not set(l) <= set('-*_ ')]

# ① 方向闸门：Why / What Changes 必须有实质内容，不能只剩模板注释
for sec in ('Why', 'What Changes'):
    if len(substance(section(sec))) < 1:
        fails.append(f'proposal 的 ## {sec} 是空的（只有注释或占位）')

# ② 新鲜度闸门：specs/design/tasks 不许严格早于 proposal
#    用严格 < 而不是 <=：git clone 后所有文件 mtime 相同，<= 会误报。
pm = os.path.getmtime(prop)
for aid in ('specs', 'design', 'tasks'):
    for p in files(aid):
        if not os.path.exists(p) or not p.endswith('.md'):
            continue
        if os.path.getmtime(p) < pm:
            fails.append(f'{aid} 比 proposal.md 旧 —— 方向变了，{aid} 没跟上'
                         f'（{os.path.relpath(p)}）')

for f in fails:
    print('GATE FAIL:', f)
if not fails:
    print('GATE PASS: proposal 有实质方向，且 specs/design/tasks 都不旧于它')
sys.exit(1 if fails else 0)
PY
```

### 四种状态实测

```text
A 全新鲜（git clone 后 mtime 相同）
  GATE PASS: proposal 有实质方向，且 specs/design/tasks 都不旧于它        exit 0

B ## Why 只剩模板注释
  GATE FAIL: proposal 的 ## Why 是空的（只有注释或占位）                    exit 1

C 方向早、specs 后跟上（正常迭代顺序）
  GATE PASS: proposal 有实质方向，且 specs/design/tasks 都不旧于它        exit 0

D 又改了方向，specs 没跟上（真正的漂移）
  GATE FAIL: specs 比 proposal.md 旧 —— 方向变了，specs 没跟上             exit 1
```

**对照内置能力看**：B 那种 proposal，`openspec status` 说 `[x] proposal`、`validate` 只抱怨没有 delta。**脚本拦住的是内置能力明确不查的那一项。**

### 这个脚本做到什么、没做到什么

```text
✓ 空壳 proposal 过不去（内置零检查的地方）
✓ 改了方向而下游没改，会红（补上 A6「改了上游不会让下游失效」）
✓ 把 specs 也纳进比较（glob 用 existingOutputPaths 正确处理）
✓ 可进 CI：exit 1 即失败
✓ 不依赖任何自定义 schema —— OpenSpec 升级不用你追

✗ 不判断方向内容对不对（那要语义比对）
✗ 不判断 proposal 与 specs 是否"意思一致"（只能判断新旧）
✗ 跨 change 管不了
✗ mtime 会被 git checkout / rebase 重置 —— 用 mtime 是权宜，不是精确溯源
✗ 用 python3（内置能力里没有 jq 依赖，任何脚本都得带个解析器）
```

> **一个必须说清的局限**：mtime 只是"谁后写"的近似。如果团队在**同一次提交里**同时改 proposal 和 specs，两者 mtime 相同，脚本判为通过——这正确。但如果是 rebase 把提交顺序换了，mtime 会乱，可能误报或漏报。**它防的是"改了方向忘了回头"，不防"历史上顺序已经乱了"。**

---

## 6.6 跨 change：内置能力补不上

`openspec validate --all` 对"8 个 change 抢同一个 capability"完全沉默（实测命中 `overlap|conflict|stack|depend` 的条数为 **0**）。这一块**内置 schema 和脚本都帮不上多少**，因为根因是结构性的。

可以做的只有两件：

**① 手工能力矩阵**（前五章 §[04 要点 12](04-usage.md) 有脚本）——成本最低，进 CI 前先人工看一眼。

**② 消费 `show --json` 比对**——`openspec show <id> --json --deltas-only` 给出每个 delta 的 `operation` 和 `requirement`，能检测"两个 change 改同一条 requirement"。但**delta 不记录它派生自哪个 base**，所以只能查名字撞车，查不出语义漂移。

上游现状（当前基线）：

| 提案 | 状态 | 覆盖 |
|---|---|---|
| `openspec/changes/add-change-stacking-awareness/` | **未落地**（卡 3/4） | `dependsOn` 等元数据 + `change graph` |
| [issue #1915](https://github.com/Fission-AI/OpenSpec/issues/1915) | open | `depends_on` 元数据 + list 可见性 |
| [issue #1387](https://github.com/Fission-AI/OpenSpec/issues/1387) | open（`design-review`） | 归档前 drift / overlap 检测 |

> #1387 点出的根因值得记：**delta 只记录 MODIFIED 的新文本，不记录派生自哪个 base**。这是自带能力做不出语义漂移检测的**结构性**原因，不是缺个命令。等上游，或者接受这块管不了。

---

## 6.7 外部参照系：这两个问题别人怎么分层解（外部来源，非 OpenSpec 能力）

> 本节引用第三方材料，仅用于**说明解法分层**，不代表 OpenSpec 的官方定位。技术事实以 §[05](05-verification.md) 的实测为准。

一篇拆源码的横向对比把几个框架摆在同一条轴上：它们治的是 context rot 的**不同层**——

| 层 | 症状 | 典型解法 |
|---|---|---|
| **契约腐烂** | 需求在长对话里漂走了 | 把需求搬到版本化文件（OpenSpec 的自定位） |
| **纪律腐烂** | 流程被执行时偷懒（跳过测试、跳过评审） | 自动触发的 skill、硬门禁 |
| **注意力腐烂** | 上下文本身变长后模型变笨 | fresh-context subagent、跨会话状态文件 |

按这个分层重读本篇两条线：

- **线 A（腐化）** 主要靠**结构性做法**解决——把状态放磁盘（`tasks.md` 的 checkbox、`sourcePath`+`line`）、注入导航简报而非正文。"清空上下文再 `apply`"有效正是因为这个。
- **线 B（漂移）** 止于**单次归档正确性**。方向一致、跨 change 排序，属于上表里 OpenSpec 不治的部分。

对"我使用时该注意什么"的直接含义：

```text
症状「AI 忘了最初要做什么」   → 前五章机制够用，重点用分级读 + 清上下文
症状「多个 change 打架」       → 需要外置检测（6.6），等上游落地
症状「长会话里模型变钝」       → 不是 OpenSpec 要解决的问题，靠切会话 / subagent
```

References:

- [Effective context engineering for AI agents](https://raw.githubusercontent.com/tim-kaa-py/ai-wiki/aa5aca2d11cf355f8b39187403eaae74aa477266/summaries/2025-09-29_anthropic_effective-context-engineering.md)
- [GSD 完胜 OpenSpec 和 Superpowers？源码拆完发现：三者防的是 context rot 的三道防线](https://cloud.tencent.cn/developer/article/2704830)
- [OpenSpec issue #1387 · Pre-archive drift and overlap checking](https://github.com/Fission-AI/OpenSpec/issues/1387)
- [OpenSpec issue #1915 · depends_on change metadata](https://github.com/Fission-AI/OpenSpec/issues/1915)

---

## 6.8 一张表：缺口 → 最便宜的补法 → 硬度

| 缺口（来自 §02 A6 / §03 B5-B6） | 只用内置 schema 的补法 | 硬度 | 落点 |
|---|---|---|---|
| 方向没有独立 artifact | **不需要**——方向在 `proposal.md` 的 `## Why`/`## What Changes` | — | 内置 |
| `## Why` 空着也能过 | `direction-gate.sh` 内容判定 | **硬** | `[外置]` CI |
| 改了 proposal，下游不失效 | 同一脚本的 mtime 比较 | **硬（近似）** | `[外置]` CI |
| specs 无陈旧信号 | 用 `existingOutputPaths` 纳入比较 | **硬（近似）** | `[外置]` CI |
| 方向与 specs 语义矛盾 | 无自动解；靠 `update` 双向复核 | 软 | `[软]` prompt |
| `rules:` 写错整组失效 | 整条加引号；CI 里查 `instructions` 的 stderr | 手工 | `[外置]` |
| 跨 change 重叠 | 手工能力矩阵 / 消费 `show --json` | 手工或 `[外置]` | 脚本 |
| 跨 change 语义漂移 | **无解**（delta 不记 base） | — | 等上游 #1387 |
| 规则被模型忽略 | 无解（全是 prompt） | — | — |

**读这张表的方式**：左列是"自带能力做不到"的，中列是"你能补的"。**标 `[外置]` 的都不是 OpenSpec。**

而且整张表**没有一项需要自定义 schema**——这是本章相比初版最重要的修正：**内置 schema 已经够用，代价是需要一个脚本 + 几条 `rules`。**

> 如果你确实想要"方向是一等 artifact"的门控，[03 · §B4](03-direction-drift.md) 那条自定义 schema 的路依然成立。但要有心理准备：**你 fork 的 schema 会成为你的维护负担**，OpenSpec 升级时得核对 artifact 语义有没有变。本章给的是不用付这笔账的做法。

---

[← 返回索引](answer.md) ｜ [附录 A · CLI 命令面 →](appendix-a-cli-surface.md)
