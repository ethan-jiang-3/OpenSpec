# 答案：不要把全量 main specs 当成每次动作的前置上下文

## 一句话结论

**当前 OpenSpec 没有“为本仓库自动建立 main-spec 目录索引、按语义选出相关 spec、再按 token budget 注入片段”的正式能力。** 因此，不能靠一个开关解决“主 specs 变大”。正确的工作方式是：

```text
小而稳定的全局约束       -> config.yaml
轻量、可搜索的 capability 目录 -> catalog / Purpose / 路径
本次真正相关的行为合同     -> 按需读选中的 main specs
本次实施的直接上下文       -> change artifacts
历史原因                   -> changes/archive/，仅按需追溯
```

也就是说，`openspec/specs/` 是**事实库**，不是每次都应整库注入的 prompt。若一个动作真的必须理解所有 capability，问题本身就是一次全局变更或全局审查，不能假装成普通局部 propose 后靠摘要“无损压缩”掉。

## 先纠正模型：archive 造的是 capability 基线，不是一个巨型文档

`archive` 把 change delta 写入对应的 main spec；`ADDED` 追加 requirement、`MODIFIED` 整块替换、`REMOVED` 删除。它不会把整个 archive 历史拼进 agent，也不会自动归纳、切分、建立反向索引或压缩旧 requirement。于是增长会发生在两个层面：

- capability 数量增长：`openspec/specs/` 下出现越来越多的行为边界；
- 单 capability 增长：长期把不相干行为放在同一 `<capability>/spec.md`，该文件会变成难以局部理解的“大 spec”。

这不意味着每次都必须读完整个目录。默认 schema 的真实意图一直是：proposal 先确定哪些 capability 是 New / Modified，修改某个 requirement 时再定位该 capability 的主 spec 和完整 requirement block。它没有要求 agent 先读取所有 main specs；问题在于它也没有把“发现哪些 spec 相关”做成一个可靠、受预算约束的 runtime 步骤。

## v1.7.0 已有能力与缺口

本 FAQ 只以正式发布的 OpenSpec `v1.7.0`（tag `4e16790`）为基线；本 checkout 源码与当前 PATH CLI 均已核验为该版本。

| 能力 | v1.7.0 当前行为 | 它解决什么 / 没解决什么 |
|---|---|---|
| 一个 capability 一个 main spec | 有；flat layout 仍兼容 | 天然避免“整个项目一个 spec”；但不会自动控制单 capability 的膨胀。 |
| 嵌套 capability 路径 | **有完整生命周期支持**：递归发现 `specs/identity/session/spec.md`，同路径 delta 可 list / show / validate / apply / archive | 可以按领域再拆分 capability；路径是 namespace，不是父子 spec 的继承模型。 |
| 浏览指定 spec / requirement | `openspec show <id> --type spec --json --requirements`，或 `--requirement <n>` | 已知目标后可以缩小读取量；`n` 是位置，不是稳定 requirement ID。 |
| 本仓库 specs 的轻量语义 catalog | 只有 id / requirement count；#901 / PR #700 的 `--detail` 尚未合入 | agent 仍要自己浏览、grep 或使用项目自建 catalog。 |
| 自动选择并加载“本次相关 main specs” | 没有；#901 / #902 仍 open | 这是本题真正缺失的能力。 |
| `references:` 的 spec 索引 | 有 | 仅针对**外部 store**：id + `Purpose` 首行 + fetch recipe，正文不内联，且共享 50KB budget；不会索引当前 root 自己的 specs。 |
| `config.yaml` 的 context | 50KB 上限；v1.7 将 context / operation guidance 扩展到 apply、archive instructions | 适合很小的全局“宪法”；不是 main specs 的替身或检索器。 |

当前终端 PATH 中的 v1.7.0 CLI 可以创建和 archive nested path。源码 checkout 与全局 npm CLI 仍是两条独立更新路径，但当前结论不再以旧版本作限制；版本演进只见 [`0004-v1.6.0-to-v1.7.0.md`](../../_digested/_change_log/0004-v1.6.0-to-v1.7.0.md)。

## 官方现状：问题已被明确提出，但还没有落地

这不是我们凭源码臆测出来的缺口。

- [Issue #802](https://github.com/Fission-AI/OpenSpec/issues/802) 在 2026-07-27 被上游 collaborator 关闭为“已回答”：现有 capability 的权威来源是 main spec，不是 archive；proposal 时 agent 应读取它触及的 main spec。该关闭说明同时把“结构化自动发现”指向仍然 open 的 #901。
- [Issue #901](https://github.com/Fission-AI/OpenSpec/issues/901) 精确描述了同一个规模问题：当前“检查 `openspec/specs/`”只是 schema 中的一句弱提示，agent 往往跳过；若全读则在 20+ capability 时浪费上下文。它提议先取一个轻量 catalog，再选相关 spec。
- [PR #700](https://github.com/Fission-AI/OpenSpec/pull/700) 是 #901 所提 `--detail` 的实现，拟把 title / overview 加入 `openspec list --specs --json`；截至查询时仍为 open，官方 `main` 的 `ListCommand` 只输出 id 与 requirement count。
- [PR #902](https://github.com/Fission-AI/OpenSpec/pull/902) 进一步提议在 propose/continue/ff 中显式运行 catalog discovery，并在宿主支持时交给 sub-agent。它报告的 100/500 spec benchmark 是贡献者实验，不是已经进入 OpenSpec 的保证。
- [Issue #872](https://github.com/Fission-AI/OpenSpec/issues/872) 也仍在询问官方是否会提供专门的 summarization 能力。

#901 中的 TabishB 认可 sub-agent 优化值得做，但明确提到还需重构和 evals，并对更结构化的流程持保留态度；这不是排期或交付承诺。

所以答案不是“完全没路可走”，而是：**现有框架已经有 capability 分片、手动选择读取、跨 repo index-then-fetch 这些积木；针对本仓库 main specs 的可靠发现和检索闭环仍是公开未完成工作。**

## 现在应该怎么做

### 1. 把“全量必读”当作异常，而不是默认工作流

普通 change 的上下文应按下面的漏斗收缩，而不是 `cat openspec/specs/**/spec.md`：

```text
用户意图 / 代码调查
        |
        v
catalog：有哪些 capability、各自负责什么
        |
        v
候选 capability：为何相关、是否是 New / Modified
        |
        v
目标 spec 的 requirement 标题和简短正文
        |
        v
仅对要修改或明显相互约束的 requirement 读完整 block + scenarios
```

一个可重复的人工/agent 协议是：

1. 先读 `openspec/config.yaml` 的短全局 context，明确不可违反的项目级约束。
2. 用 `openspec list --specs --json`、目录树、`rg`，或项目自建 catalog 找候选 capability；不要先读正文。
3. 对候选使用 `openspec show <id> --type spec --json --requirements`，先看 requirement 列表，不带 scenarios。
4. 只有确定要 `MODIFIED` / `REMOVED` / `RENAMED` 时，才读目标 requirement 的完整 block。delta 的 `MODIFIED` 必须保留完整 block，这一步不能省。
5. 在 `proposal.md` 的 Modified Capabilities 中明确记录：选中了哪些 capability、为什么；不确定的边界要写成问题或先 Explore，不要悄悄新建一个近义 capability。
6. 实施时以当前 change 的 proposal / delta specs / design / tasks 为直接上下文。若发现还需要另一份 main spec，暂停并更新 planning artifacts，而不是让 apply 临时猜测。

`--requirement <n>` 可用于当前会话的精确抽取，但 requirement 没有稳定 ID，archive 后编号会变；不要把 `n` 当作长期引用键。长期引用应使用 capability path + requirement 标题，必要时再在正文中核对。

### 2. 让 capability 边界承担分片，而不是把章节越写越大

如果一个 main spec 长期同时包含能独立演化、独立发布、独立被修改的行为，它不是“上下文太小”的问题，而是 capability 边界已经过粗。本 checkout 源码和正式 v1.7.0 都支持：

```text
openspec/specs/
  identity/
    login/spec.md
    session/spec.md
    authorization/spec.md
  billing/
    invoices/spec.md
    subscriptions/spec.md
```

对应 change delta 使用同一相对路径；archive 会写回对应的 nested main spec。拆分依据应是**行为合同和修改独立性**，不是按文档页数硬切：若两个 requirement 每次都必须一起改、同一 scenario 才能验证，拆成两个 capability 只会制造跨 spec 跳转成本。正式采用前要确认实际 CLI 已是 v1.7.0 或更高；默认 agent instruction 仍偏 flat，项目还应在 `config.yaml` / AGENTS 写明 `<domain>/<capability>` 约定（见 [#1459](https://github.com/Fission-AI/OpenSpec/issues/1459)）。

要特别谨慎地迁移既有 flat capability。OpenSpec 的 capability 身份就是相对目录路径，没有 capability rename 操作。把 `auth/` 直接搬成 `identity/login/` 会使所有仍指向 `auth/` 的 active delta 失去目标。正确做法是把它作为一次受控 rebaseline / 结构迁移：先处理或搁置触及旧路径的 active changes，列清 requirement 到新路径的映射，人工 review 新基线，再让后续 change 全部使用新路径。不要把这个动作伪装成一次普通 archive。

### 3. 建一个“索引”，但不要制造第二份行为真相

在 #700 / #901 落地前，规模化项目最实用的本地补丁是一个**派生 catalog**，例如 `openspec/specs/README.md` 或 `docs/spec-catalog.md`。它只包含：

```text
capability path | 一句 Purpose | 关键术语 | 上游/下游边界 | owner（可选）
identity/session | 会话建立、刷新、失效 | JWT, refresh, expiry | identity/login | identity team
```

要求：

- catalog 只做导航；行为的唯一权威仍然是各 `spec.md`。
- 它最好由脚本或 archive 后的 review 生成/校验，避免手工复制整段 requirement 后再次漂移。
- `## Purpose` 必须写得像索引摘要，而不是 `TBD`；external references 已经用它的首行建立轻量 index，这正是一个现实验证过的字段职责。
- 大项目可增加关键词、依赖边界和 owner，但不要把完整 scenarios 再抄一遍。

这比把全目录塞入 `config.context` 好得多：后者是每次都注入、受 50KB 硬上限、而且会把独立的行为事实复制成第二个容易漂移的版本。

### 4. 用 config.yaml 保留“全局内核”，不是全局规格

真正必须每次都知道的内容通常很少：领域边界、兼容性/安全底线、不可破坏的协议、测试/发布纪律。把这一小层写入 `context`，把 artifact 特有的长期写作约束写入 `rules.<artifact>`。例如：

```yaml
schema: spec-driven

context: |
  Domains: identity, billing, fulfillment. Keep their public contracts compatible.
  Cross-domain changes must name every affected capability in the proposal.
  Security-sensitive changes require an explicit threat and regression plan.

rules:
  proposal:
    - Classify every affected capability as existing or new and record the evidence.
  specs:
    - Preserve externally observable contracts; do not place implementation choices here.
```

这层只放“任何 change 都成立且很短”的规则。具体的身份、账单、履约行为仍留在相应 main spec；某次迁移的临时背景仍留在该 change artifacts。当前 upstream `main` 已把 project context/operation guidance 送到 apply/archive instruction surfaces，但它仍然不是 main-spec retrieval，因此升级不会让大规格自动变小。

### 5. 跨域或全局变更，承认它需要更大范围的阅读

有些任务确实不是局部任务，例如统一权限模型、全站审计语义、全局 API 兼容性迁移。此时 catalog 的作用是**证明影响面**，不是省略阅读。建议在 proposal 先产出一张 impact matrix：

| capability | 为什么相关 | 要读到什么粒度 | 本次动作 |
|---|---|---|---|
| identity/session | token 语义改变 | 全部 requirements | MODIFIED |
| billing/subscriptions | 调用者依赖 token claim | 相关 requirement + scenarios | verify only |
| fulfillment | 无调用关系 | 无 | excluded，说明理由 |

如果范围确实超过一个 context window，可以按 domain 并行调查，再由主 agent 或人类 review 合并“已读的原文证据、冲突、未决问题”。这只是把检索工作分散，不会把全局正确性魔法化；最终的跨域决策仍必须显式 review。

## 不推荐的做法

- **每次 propose 都读全量 `openspec/specs/`**：token 花在大部分无关合同上，反而更容易漏掉真正的约束。
- **把 archive history 当当前行为来源**：archive 是溯源材料；当前真相是 main specs。只有回答“为什么当初这么定”时才回查历史。
- **把完整功能说明复制进 `config.context`**：这会创造第二份 baseline，并因 50KB 限制和阶段注入差异而更快失真。
- **为了短上下文任意拆 capability**：拆分后没有清晰的行为边界，会把一个可读的大 spec 变成大量必须同时读的小 spec。
- **以 requirement 序号做长期链接**：序号随 archive 修改而漂移；当前没有稳定 requirement ID。

## 对框架未来的建议

OpenSpec 已经在 external references 上验证了正确的方向：**index 不内联正文，正文由明确 fetch 动作按需读取，并设总预算**。把这套模式补到 local main specs，最小可行的闭环应是：

1. 一个一等 CLI catalog：每条至少有 relative path、title、Purpose、requirement count；可选 keywords / owner / declared dependencies。
2. proposal workflow 的显式 discovery step，而不是 schema 里一句“自行检查目录”。先 catalog，再说明哪些 spec 相关。
3. 一个可 review 的 selection manifest：本次 change 选了哪些 main specs、依据是什么、哪些被排除；它可以存进 proposal 或独立 artifact。
4. 按需 fetch API：读取整个 spec、仅 requirement 标题、指定 requirement block、或带明确 byte/token budget 的 excerpts；预算不足时停止并要求进一步选择，而不是静默截断关键合同。
5. 对跨域依赖和 requirement 的稳定标识做后续建模。否则“选中的 requirement”只能靠标题和文本匹配，无法成为可靠的长期链接。

Issue #901 / PR #902 已经覆盖了前两步和可选 sub-agent 的思路。它们尚未合入，因此今天需要规模化运行的团队不应等待：用项目内 catalog + 明确 discovery protocol + 小型 global context 先形成纪律；把该协议封装为本地 agent skill 或 CI 生成器也完全合理。

## 参考来源

### 本仓库材料与源码

- [`../../_digested/specs_truth/01-机理-主specs如何被delta构造.md`](../../_digested/specs_truth/01-机理-主specs如何被delta构造.md) — archive 如何把 delta 变成 main specs，requirement / capability 的身份边界。
- [`../../_digested/specs_truth/03-手段清单-到底有多少种修法.md`](../../_digested/specs_truth/03-手段清单-到底有多少种修法.md) 与 [`06-源码锚点与缺口.md`](../../_digested/specs_truth/06-源码锚点与缺口.md) — 没有 reconcile、全局审计、稳定 requirement ID 或 capability rename。
- [`../../_digested/specs_truth/_research-main-spec-context-growth.md`](../../_digested/specs_truth/_research-main-spec-context-growth.md) — 对上游 `main`、#901、PR #700 / #902 与 #872 的逐项核验底稿。
- [`../../_digested/_change_log/0004-v1.6.0-to-v1.7.0.md`](../../_digested/_change_log/0004-v1.6.0-to-v1.7.0.md) — v1.7.0 的正式发布与本 checkout 的源码合入；recursive spec discovery 已成为当前基线。
- [`../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md`](../../_digested/internal-spec-driven/07-config-yaml-上下文路由源码深挖.md) — config、references 和各 workflow 的上下文路由边界（基线 `af94ff8`）。
- [`../../_digested/mechanisms/01-store-模型与仓库协同.md`](../../_digested/mechanisms/01-store-模型与仓库协同.md) — external references 的 index-not-inline 模型。
- [`../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md`](../../_openspec_handbook/05-高级-项目级全局约束到底放哪.md) — config / specs / changes 三层分工。
- `src/utils/spec-discovery.ts`、`src/utils/item-discovery.ts`、`src/commands/spec.ts`、`src/core/references.ts`、`src/core/project-config.ts` — 本 checkout 的 recursive spec 发现、指定 spec/requirement 读取、external reference index 和 50KB context cap。

### 上游一手来源（2026-07-29 查询）

- [Issue #802: Spec Reuse](https://github.com/Fission-AI/OpenSpec/issues/802) — 上游 collaborator 的关闭说明：main spec 而非 archive、读取触及 capability、#901 是后续。
- [Issue #901: Automatic spec catalog discovery](https://github.com/Fission-AI/OpenSpec/issues/901) — 当前本地 spec discovery 缺口、规模问题和推荐方向。
- [PR #700: list --specs JSON/detail](https://github.com/Fission-AI/OpenSpec/pull/700) — #901 的 `--detail` 实现，尚未进入 main。
- [PR #902: sub-agent spec discovery](https://github.com/Fission-AI/OpenSpec/pull/902) — 社区实现和实验性 token 数据，未当作已发布能力。
- [Issue #872: too many OpenSpec files](https://github.com/Fission-AI/OpenSpec/issues/872) — summarization 需求仍为 open 问题。
- [upstream v1.7.0 `4e16790`](https://github.com/Fission-AI/OpenSpec/tree/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b) — 本次同步的官方源码基线；已确认其 `list`、references 和 project-config 仍没有 local main-spec automatic retrieval。
