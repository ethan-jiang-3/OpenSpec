# 机理：主 specs 如何由 delta 构造

## 主轴（整专题的引擎）

> **specs 只在 `archive` 那一刻写入；requirement 没有稳定 ID，身份就是 `### Requirement: <Name>` 标题文本；而且没有任何工具持续对账。 ⇒ 漂移是默认状态——"把 specs 弄对"是"用 delta + archive 重新表达"，不是手搓 spec；长期对齐靠人 + 纪律 + 巡检。**

本章讲清这个论点的前两个支柱（specs 怎么产生、身份是什么）；第三个支柱（没工具对账）在 `02`，修法在 `03`。

主 specs（`openspec/specs/<capability-path>/spec.md`）通常由 delta spec 经 `archive` 累加而来；`openspec archive` 是唯一的**确定性**主 spec 写入 CLI。host 的 sync workflow 也能在 archive 前直接改 main spec，但那是 agent 驱动的智能 merge，随后 archive 会按当前基线做幂等检查。理解这个区分，后面的失真和修法才不会把两条路径混为一谈。

路径也有两层语义：agent 在生成 MODIFIED delta 或直编 Purpose 时，必须从 `openspec instructions ... --json` 读取 `planningHome.root`，再访问 `<planningHome.root>/openspec/specs/...`；CLI archive 的 deterministic merge 则由 root selection 把 source/target 解析成真实文件路径。前者是 instruction contract，后者是 CLI 实现路径；这里修复的是前者硬编码 cwd 的问题，不新增自动 retrieval，也不能把 `<planningHome.root>` 当 shell 里的字面目录。

## 先定位：日常工作流圈里，archive 是哪一步

日常四步 **explore → propose → apply → archive**：前三步是 `/opsx:` slash 技能（agent 驱动），**archive 是 `openspec` CLI 命令**——也是这四步里**唯一会写主 spec**的一步（specs 只在这一步更新）。`validate`/`list`/`view` 是另一类 CLI 工具命令，只读不写、不在这个圈里（CLI/slash 完整对照表见 `README.md`）。

所以本章讲"specs 怎么产生"，本质上就是讲 **archive 这一步内部发生了什么**。

## 整条流水线

```text
openspec/changes/<id>/specs/<capability-path>/spec.md   ← delta（提案要改什么）
        │   用 ## ADDED / MODIFIED / REMOVED / RENAMED Requirements 表达
        ▼
   findSpecUpdates()        把每个 delta path 配对到 openspec/specs/<path>/spec.md
        ▼
   buildUpdatedSpec()       按顺序 RENAMED → REMOVED → MODIFIED → ADDED 重写主 spec
        │   匹配键 = normalizeRequirementName(标题) = 标题.trim()
        ▼
   writeUpdatedSpec()       落盘 openspec/specs/<cap>/spec.md
        ▼
   moveDirectory()          把 change 移到 openspec/changes/archive/<YYYY-MM-DD>-<id>/
```

两个入口都汇到同一个 `buildUpdatedSpec`：

| 入口 | 性质 | 是否移动 change 到 archive |
|------|------|----------------------------|
| `openspec archive <change>` | **唯一的确定写入 CLI 动词**；写前全量 fail-fast，mutation 后失败用 snapshot 尽力回滚 | 是 |
| host 的 sync workflow（Codex: `$openspec-sync-specs`；Claude command adapter 常显示 `/opsx:sync`） | LLM 读 delta + 主 spec 再对齐，非确定、幂等 | 否（它只改 spec） |

> 注意：**没有 `openspec apply` 命令**。`applySpecs()` 是 `archive` 内部调用的引擎函数，不是一个对外 CLI 动词（`src/cli/index.ts` 里 `.command('archive')` 有、`.command('apply')` 没有）。对外能以确定规则写主 spec 的路径就 `archive` 一条；想在归档前做更灵活的整段重写，走 host 的 sync workflow（它本质是让 agent 手动改 spec）。

## 身份模型：两层「以名字为身份」，无稳定 ID

这是整个模型最关键、也最容易被忽略的一点：OpenSpec 用**名字**当身份，分两层，**都没有稳定 ID**。它既是 `archive` 能可靠合并的根基，也是漂移的根源（见 `02`）。

> 驱动这套契约的是 **spec-driven schema**（OpenSpec 默认、最常见的 schema，背后的 driver）——`schemas/spec-driven/schema.yaml` 把 proposal↔specs 的 capability path 定为 "critical contract"。结构字段级详解见 `../schema/02-内置-spec-driven-详解.md`；需要采用 nested layout 时，建议同时读 `src/utils/spec-discovery.ts`。

### 第一层：capability 身份 = `specs/` 下的相对路径

一个 capability 的身份，是它在 `openspec/specs/` 下的**相对目录路径**，例如 `auth` 或 `identity/session`。它承担四个角色：main specs 的组织单位、proposal↔specs 的契约、delta 的靶心（`changes/<id>/specs/<path>/` 打 `specs/<path>/`，**相对路径相同才命中**）、以及它唯一的"身份"。nested path 是 namespace，不含父子继承或自动 retrieval。

- **没有 ID** ⇒ 一个 capability 全靠这条相对路径维系。
- **capability 没有 rename 操作**——requirement 有 `## RENAMED`，capability 没有任何对应物；改 path 只能裸搬目录，指向旧 path 的 delta 会失配（见 `02` 信号①、`03` 纪律、`06` 缺口）。

### 第二层：requirement 身份 = 标题文本

一个 requirement 的"身份"，**不是某个 ID，不是某个序号，而是它 `### Requirement: <Name>` 这行标题的原文**。定位时经过的唯一规范化是 `normalizeRequirementName()`：

```ts
// src/core/parsers/requirement-blocks.ts
export function normalizeRequirementName(name: string): string {
  return name.trim();   // 只 trim，不 lower-case，不做任何其他规范化
}
```

推论（每一条都会在 `02` 变成真实的漂移来源）：

- **没有 ID** ⇒ 一个 requirement 的一生，全靠这行标题文本维系。
- **只 trim** ⇒ 改一个字母的大小写、换个标点，规范化都"消化不掉"，会被当成**另一个** requirement。
- delta 的 `MODIFIED`/`REMOVED`/`RENAMED` 要命中主 spec 里的 requirement，靠的就是用这行标题文本去 `Map` 里精确查找。只对已同步完成的 REMOVED/RENAMED 放宽为 no-op；其余找不到仍需诊断（见 `04`）。

一个容易踩的细节：**delta 的段落标题大小写不敏感，但 requirement 名字的大小写敏感**。

```text
## ADDED Requirements          ← 段头：getSectionCaseInsensitive()，大小写不敏感
                                （写成 "## added requirements" 也能认）
### Requirement: Skill Gen     ← 名字：normalizeRequirementName()，只 trim
                                （"Skill Gen" 与 "skill gen" 是两个不同 key）
```

段头宽容、名字严格——这个不对称会让人误以为"标题随便写大小写都行"，于是在主 spec 里把 `Skill Generation` 改成 `skill generation`，结果后续所有指向它的 delta 默默失配。

## delta 的四种操作

delta 文件用 `##` 级段头声明操作，每个操作里用 `### Requirement: <Name>` 块表达：

| 操作 | 写法 | archive 时怎么作用 |
|------|------|--------------------|
| **ADDED** | 整个 `### Requirement:` 块（正文 + ≥1 个 `#### Scenario:`） | 按名字插入；同名且内容不同报 `already exists`，完全相同则视为已 early-sync 的 no-op |
| **MODIFIED** | 整个 `### Requirement:` 块（完整新版本） | **整块替换**：丢掉旧块、在同名位置塞入新块。不是 diff/patch |
| **REMOVED** | 只要名字（`### Requirement: <Name>` 或 bullet `- `### Requirement: <Name>``） | 按名字删除；已不存在时以 warning 视为已 early-sync 的 no-op，大小写/空白 near-miss 仍报错 |
| **RENAMED** | `FROM: `### Requirement: 旧```<br>`TO:   `### Requirement: 新``` | 改名；可配合一个指向**新名**的 MODIFIED。对**旧名**做 MODIFIED 是错的 |

合并顺序是写死的：**RENAMED → REMOVED → MODIFIED → ADDED**（`src/core/specs-apply.ts` 的注释 `Apply operations in order: RENAMED → REMOVED → MODIFIED → ADDED`）。先改名、再删、再改、最后增，这样各操作不会互相踩。

## 原子性与 fail-fast

`buildUpdatedSpec` 对**真实冲突**是 fail-fast 的：MODIFIED 找不到目标、内容不同的 ADDED 重名、RENAMED 两端都不存在，或 requirement 只有大小写/空白近似但不精确，都会抛错；`archive` 会在写入前中止并输出 `Aborted. No files were changed.`，change 不移动、spec 不改动。例外是已 early-sync 的完全一致操作：它们按 no-op 处理，不应被误诊为 archive 冲突。

这是真实抓到的一次（本 repo 的 `simplify-skill-installation`）：

```text
Specs to update:
  cli-init: update
  cli-update: update
  profiles: create
  propose-workflow: create
cli-init MODIFIED failed for header "### Requirement: Skill generation per tool (REPLACES fixed 9-skill mandate)" - not found
Aborted. No files were changed.
```

注意几点：

- 报错只输出一行 `... - not found`，**不会提示"你是否想指…"，也不会列出当前 spec 里实际存在的名字**。
- 因为是原子的，连本来能成功创建的 `profiles`/`propose-workflow` 也一并没动。一个 delta 坏，整批不落地。
- 这种"找不到"几乎都来自身份脆弱性：主 spec 的标题被改过、被别的 archive 重写过、或 delta 本身就指向一个从没存在过的名字。

完整的"看到 not found 怎么诊断、怎么修"见 `04`。

## 为什么这条机理决定了"specs 会失真"

把上面几节拼起来，失真的根因就清楚了：

1. **写入只走 archive** ⇒ specs 的现状 = 历史上所有成功 archive 的累积结果。一次没 archive、archive 失败、或 archive 了错误方向，都会直接写进真相。
2. **身份是标题文本** ⇒ 任何一次手改标题、大小写变化、改名没走 RENAMED，都会让历史 delta 和当前 spec 对不上。
3. **`validate` 不做这件事**（见 `02`/`06`）⇒ 上述对不上不会在 validate 阶段报警，只在下一次 archive 撞上时，用一句 `not found` 暴露。
4. **没有回溯/审计命令** ⇒ "这条 requirement 当年为什么进来"只能去 `changes/archive/` 里人肉 grep。

`02` 把这些根因展开成六类具体噪声；`03` 给修法。

## 它守护的边界

主 specs 是**事实层**：它描述"项目现在是什么"。愿望（想要变成什么）放在 `changes/` 和 `initiatives/`。这条机理的设计意图是——事实层的改写只能通过 explore → propose → apply → archive 这条受控流水线（且只有 archive 写 spec），而不是随手编辑。代价是：一旦绕过这条流水线（手改、漏 archive、改名没走 RENAMED），没有工具会帮你发现，specs 就开始和现实分叉。

## 源码锚点

| 机制 | 路径 |
|------|------|
| 身份规范化（仅 trim） | `src/core/parsers/requirement-blocks.ts` — `normalizeRequirementName` |
| delta 段头解析（大小写不敏感） | `src/core/parsers/requirement-blocks.ts` — `getSectionCaseInsensitive` |
| delta 四操作解析 | `src/core/parsers/requirement-blocks.ts` — `parseDeltaSpec` |
| **唯一改写器** | `src/core/specs-apply.ts` — `buildUpdatedSpec` |
| 合并顺序 RENAMED→REMOVED→MODIFIED→ADDED | `src/core/specs-apply.ts`（`Apply operations in order` 注释处） |
| delta→主 spec 配对 | `src/core/specs-apply.ts` — `findSpecUpdates` |
| recursive capability discovery | `src/utils/spec-discovery.ts` — `discoverSpecFiles` |
| BOM / fenced code 解析边界 | `src/core/parsers/requirement-blocks.ts`、`src/core/parsers/code-fence.ts` |
| 落盘 | `src/core/specs-apply.ts` — `writeUpdatedSpec` |
| 内部引擎（被 archive 调用） | `src/core/specs-apply.ts` — `applySpecs` |
| archive 流程（全量写前校验、snapshot 回滚、移动 change） | `src/core/archive.ts` |
| CLI 命令注册（证实无 `apply`） | `src/cli/index.ts` |
| /opsx:sync LLM 模板 | `src/core/templates/workflows/sync-specs.ts` |

## 继续阅读

- 单次 archive merge 的精确代码走查：`../internal-spec-driven/04-archive-归档合并.md`
- 这套身份模型长期下来怎么失真：`02-漂移与噪声-为什么主specs会失真.md`
- 失真之后怎么修：`03-手段清单-到底有多少种修法.md`
- spec/change 的 parser/schema/validator 模型：`../mechanisms/03-spec-model.md`
