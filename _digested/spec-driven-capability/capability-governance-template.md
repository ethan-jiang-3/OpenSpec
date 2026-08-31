# Capability governance template

这是一份可复制、再按项目实际填写的最小约定。它适合放入项目 AGENTS；其中少量跨所有 change 都成立的原则，也可提炼到 openspec/config.yaml 的 context 或 artifact rules。

不要把整个 taxonomy、完整 catalog 或 main spec 正文复制进 config.context。它们应保持为可搜索、按需读取的项目资料。

## 1. 放入 AGENTS 的项目约定

~~~md
## Capability 约定

### 术语与边界

- capability 是可独立演化、可独立验证的行为合同切片，不等于源代码目录或实现模块。
- domain 只用于组织和发现；它不表示父 capability、继承、自动聚合或自动读取。
- main spec 是行为真相；catalog 只做导航，不能复制完整 requirements 或 scenarios。

### Path convention

- 使用 <domain>/<capability> 作为默认 path，例如 identity/session。
- path segment 使用稳定、语义明确的 kebab-case；不得使用 common、misc、utils、core 等垃圾桶名。
- 只有长期稳定且确有导航价值的 namespace 才增加第三层。
- capability path 是稳定 identity。未经受控迁移，不得重命名或移动。

### Discovery before proposal

1. 先读取 <catalog-location>，或运行 openspec list --specs --json。
2. 搜索已有 capability 的 Purpose、关键词和 requirement 标题，避免创建近义 path。
3. 在 proposal 中将每个受影响 path 标为 New 或 Modified，并记录为何相关。
4. 对要 MODIFIED、REMOVED 或 RENAMED 的 requirement，先读取完整 block 与 scenarios。
5. 只有没有 spec-level 行为变化时才能使用 skip_specs。

### Delta and archive

- change delta 必须位于 specs/<capability-path>/spec.md，并与 main spec 使用相同完整相对 path。
- 新 capability 的 delta 写明可读 Purpose；既有 capability 的 Purpose 不在 delta 中改写。
- 不要以 capability path 变更作为普通 archive 的副作用。

### Structural migration

- 拆分、合并、重命名或移动 capability path 必须作为独立 rebaseline。
- 先清理、冻结或重基线所有触及旧 path 和新 path 的 active changes。
- 更新 main specs、active deltas、catalog、文档和引用后，执行 strict validation 并人工 review。
~~~

将尖括号中的 catalog-location 替换为项目实际位置，例如 openspec/specs/README.md 或 docs/spec-catalog.md。

## 2. catalog 的最小模板

catalog 不需要先有自动生成器；先保持薄、可 review、可回指即可。

~~~md
# Capability catalog

| path | Purpose | keywords | boundary / neighboring capability | owner |
|---|---|---|---|---|
| identity/session | 建立、刷新和失效用户会话。 | JWT, refresh, expiry | 与 identity/login 相邻；不负责授权策略。 | identity |
| billing/invoices | 创建、投递和查询发票。 | invoice, tax, PDF | 不负责订阅扣款。 | billing |
~~~

维护规则：

- path 必须与 main spec 的实际相对路径完全一致。
- Purpose 应与 main spec 的 Purpose 保持同一判断边界，但无需复制正文。
- keywords、边界和 owner 是导航元数据，不应伪装成新的 requirements。
- catalog 与 main spec 冲突时，以 main spec 为准，并在同一 review 中修复 catalog。

## 3. 可提炼到 config 的极小片段

只把恒定、跨全部 change 的约束放进 config。下面是示意，不要求原样复制：

~~~yaml
context: |
  Capability paths use the project convention in AGENTS.
  Treat a capability path as stable identity; structural migrations need an explicit rebaseline.
  Main specs are the behavior source of truth. The catalog is navigation only.

rules:
  proposal:
    - Classify every affected capability as New or Modified and record discovery evidence.
  specs:
    - Use the exact capability path declared in the proposal.
    - Do not create a near-duplicate capability without checking the catalog and existing main specs.
~~~

不要在这段 context 中列出所有 paths 或复制 catalog。随着项目成长，它会变成每次注入、很快过时且受大小限制的第二份 registry。

## 4. taxonomy 变更检查清单

~~~text
[ ] 旧 path → 新 path 的映射和理由已审阅
[ ] 所有受影响 active changes 已完成、冻结、取消或重基线
[ ] main specs 与 active deltas 使用新的完整 path
[ ] catalog、AGENTS/config 和文档链接已同步
[ ] openspec list --specs --json 输出符合预期
[ ] main specs 与受影响 changes 已完成 strict validation
[ ] 人工确认没有把真实的行为合同或兼容性承诺遗留在旧 path
~~~

这份模板的唯一目的，是把 capability 规划从“每个 agent 临场猜一次”变成项目可见、可审阅、可演进的接口约定。
