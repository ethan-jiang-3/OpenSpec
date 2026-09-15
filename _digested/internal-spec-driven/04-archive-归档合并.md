# 04 — archive：archive 合并

archive 是整个 change 生命周期的终点。它做三件事：验证 change、将 delta spec 合并到主 spec 基线、然后把 change 目录移到 archive 区。

这里需要先区分两条相关但不同的路径：

- **`openspec archive` CLI**：由 `ArchiveCommand.execute()` 执行，程序化完成验证、delta spec 合并和目录移动。
- **host 的 archive workflow skill/command 模板**：由 host agent 按 `archive-change.ts` 的指令执行，会先做 delta spec sync 状态评估，再按模板移动目录。Claude 等 command adapter 可显示为 `/opsx:archive`；Codex 使用 `$openspec-archive-change` skill。它不是 `ArchiveCommand.execute()` 的逐字封装。

本篇主体讲 `openspec archive` CLI 的内部机制；第 5 节单独说明 host archive workflow 的 sync 检查与 operation inputs。

---

## 1. 三阶段总览

![archive 三方架构实例化](figures/04-archive-flow.svg)

`openspec archive` 来自 `src/core/archive.ts` 的 `ArchiveCommand.execute()`。逻辑上可分为三大阶段（validate → merge → move），但 mutation 边界更准确地说是：① 结构/delta 验证与 tasks 检查 → ② 全量预构建 → ③ 全量 rebuilt validation → ④ 捕获 snapshots 后写入/退役 → ⑤ verified move。mutation 后任何一步失败都会尝试恢复 snapshots 和 active change；并发修改阻止安全恢复时显式报告 rollback failure。

```
Phase 1: Validate
  ├── proposal.md 验证（非阻塞，只警告）
  └── delta spec 验证（阻塞，有 ERROR 就拒绝 archive）

Phase 2: Merge（除非 --skip-specs）
  ├── 找到所有 delta spec
  ├── 全量构建更新后的 specs（buildUpdatedSpec）
  ├── 全量验证重建后的 specs
  ├── 检查 fingerprints 并捕获 mutation snapshots
  └── 写入或退役主 specs

Phase 3: Move
  ├── 创建 archive/ 目录
  ├── 无日期前缀时生成 YYYY-MM-DD-<changeName>
  ├── rename；EPERM/EXDEV 时走 private staging + verified copy
  └── 失败时尽力恢复 main specs 与 active change
```

---

## 2. 验证阶段

### 2.1 proposal 验证（非阻塞）

`archive.ts:96-111`：用 `Validator.validateChange()`（`src/core/validation/validator.ts`）验证 proposal.md 的结构（Why/What Changes 等 section 是否存在、长度是否合理）。但**验证失败不会阻止 archive**——proposal 验证是信息性的。

### 2.2 delta spec 验证（阻塞）

`archive.ts:113-151`：扫描 `<changeDir>/specs/` 下每个子目录中带 delta header 的文件（`## ADDED/MODIFIED/REMOVED/RENAMED Requirements`）。

如果发现 delta spec，用 `Validator.validateChangeDeltaSpecs()`（`src/core/validation/validator.ts`）做结构与内容验证：

| 检查项 | 级别 |
|--------|------|
| 缺少 `## Requirements` section 中的 `### Requirement:` header | ERROR |
| ADDED/MODIFIED requirement 正文缺失 | ERROR |
| requirement 正文存在但缺少 SHALL/MUST | WARNING（显示但不阻止 archive） |
| requirement 缺少 scenario | ERROR |
| 同一 section 内 requirement 名重复 | ERROR |
| 同一 requirement 出现在多个 section 中（如同时 ADDED 和 MODIFIED） | ERROR |
| requirement 文本过长 | WARNING |
| delta 数量超过阈值 | WARNING |

如果存在任何 ERROR，**CLI 拒绝 archive**。WARNING 只显示，不阻止。

`--no-validate` 可以跳过所有验证，但需要额外确认（或 `--yes`）。

### 2.3 任务完成检查

`archive.ts:174-194`：读取 tasks.md，统计未完成 checkbox。如果有未完成任务，警告并要求确认。与 `list` / `view` / `instructions apply` 共用 `src/utils/task-progress.ts` 的同一 parser——**缩进的子任务也计入**（旧版只认列 0 的 checkbox，未完成的 `  - [ ] 1.1.1` 会被漏掉，archive 于是"✓ Complete"却带着半截活收档）。

---

## 3. 合并阶段：核心算法

这是整个 OpenSpec 中最精密的单段算法。核心入口是 `buildUpdatedSpec()` in `src/core/specs-apply.ts`。

### 3.1 找 delta spec

`findSpecUpdates()` (`src/core/specs-apply.ts`)：递归扫描 `<changeDir>/specs/`。对于每个包含 `spec.md` 的 capability path，查找相同相对路径的主 spec 文件：

```
change/specs/data-export/spec.md  →  openspec/specs/data-export/spec.md
change/specs/user-auth/spec.md    →  openspec/specs/user-auth/spec.md
change/specs/identity/session/spec.md → openspec/specs/identity/session/spec.md
```

返回 `SpecUpdate[]`，每个包含 `{source, target, exists}`（target 是主 spec 路径，exists 表示主 spec 是否已存在）。

`changes/<change>/specs/spec.md` 没有 capability folder，递归发现器不会把它当 update；validator/archive 会把这种根级 delta 作为 ERROR 拒绝，而不是静默跳过。

### 3.2 解析 delta plan

`parseDeltaSpec()` (`src/core/parsers/requirement-blocks.ts`)：将 delta 格式的 spec 文件解析成 `DeltaPlan`：

```typescript
interface DeltaPlan {
  added: RequirementBlock[];       // { headerLine, name, raw }
  modified: RequirementBlock[];
  removed: string[];               // 只是 requirement 名
  renamed: Array<{ from: string; to: string }>;
  sectionPresence: {               // 标记哪些 section 出现了
    added: boolean;
    modified: boolean;
    removed: boolean;
    renamed: boolean;
  };
}
```

解析过程：
1. 用 `splitTopLevelSections` 按 `##` headers 切分内容
2. 大小写不敏感匹配四个 section 类型
3. `parseRequirementBlocksFromSection()`：提取 `### Requirement:` header 和 body 内容（包括所有 `#### ` 级 scenario；不限于字面 `#### Scenario:`）
4. `parseRemovedNames()`：提取 requirement 名（可以是 `### Requirement:` header 或 bullet 中的引用）
5. `parseRenamedPairs()`：解析 `FROM:` / `TO:` 对

### 3.2.1 delta section 是 list，列表标记全接受

`DeltaPlan` 的 section 解析有两处保真修复（`src/core/parsers/requirement-blocks.ts`）：

1. **sections 从 title-keyed record 改为按书写顺序的 list**。之前重复写同一 header（如两个 `## ADDED Requirements`，或 fence 示例自带重复 header）时，后写的覆盖先写的，大小写折叠 lookup 只返回第一个匹配——被丢弃副本里的 requirement 在 validate/merge 之前就没了，但 `validate` 报零问题、`archive` 报成功，主 spec 悄悄和已审阅的 delta 不一致。现在每个 section 保留自己的出现次序和行号；lookup 返回所有匹配 section；`FROM:`/`TO:` 按 section 配对，一份里的 `FROM:` 不会和另一份的 `TO:` 配对。

2. **REMOVED 的 bullet 形式与 RENAMED 的 `FROM:`/`TO:` 行接受 `[-*+]` 全部 CommonMark 列表标记**。之前硬编码 `-`，用 `*`/`+` 写的删除/改名 delta 匹配不到任何东西——`validate` 报 valid、`archive` 退出 0，但需求根本没动。`FROM:`/`TO:` bullet 保持可选；`### Requirement:` header 形式不变。

### 3.2.2 scenario bullet 换行不再挡退役

`retire_capabilities` 之前拒绝任何 scenario bullet 换行到第二行的 spec——续行被当成 merge 无法归属的内容，退役被整个阻塞，且提示 marker 的 hint 也被吞掉。把续行读成同一条 bullet；`+` 列表标记也被正确识别（之前只认 `-`/`*`，`+` 写的 scenario 全部报 unaccounted，capability 完全无法退役）。

### 3.3 预验证（合并前）

`specs-apply.ts:113-200`，在修改任何文件之前先做六重检查（前五项是"重复/冲突"类，最后一项是"空 delta"防护）：

1. **section 内重复**：同一个 ADDED section 内不能有两个同名 requirement；MODIFIED/REMOVED/RENAMED 同理
2. **跨 section 冲突**：同一个 requirement 名不能同时出现在 ADDED 和 MODIFIED 中（或任何其他组合）
3. **RENAMED + MODIFIED 交互**：如果有 RENAMED 将 `OldName` → `NewName`，则 MODIFIED 必须引用 `NewName`（不能引用 `OldName`）
4. **RENAMED + ADDED 冲突**：RENAMED 的 TO 不能和 ADDED 的 requirement 重名
5. **空 delta**：至少有一个 delta 操作

如果目标 spec 不存在（新 capability）：
- 只允许 ADDED。MODIFIED/RENAMED 会报错（因为没有东西可以 modify/rename）
- REMOVED 会被忽略并产生警告（没有东西可以 remove）
- delta 若含可读的 `## Purpose`，`buildSpecSkeleton()` 会把它写入新 main spec；缺失或不可读时才回退到 TBD placeholder。已有目标的 Purpose 不被 delta 覆盖。

### 3.4 提取主 spec 的 Requirements section

`extractRequirementsSection()` (`requirement-blocks.ts`)：将目标 spec 的内容拆分为：

```
before:   "# Capability Specification\n\n## Purpose\n..."
header:   "## Requirements"
preamble: ""（或 header 后的文字直到第一个 requirement）
body:     [RequirementBlock, RequirementBlock, ...]
after:    ""（Requirements section 之后的文字）
```

然后构建 `nameToBlock` map：key 是 normalized requirement name（当前 `normalizeRequirementName()` 只做 `name.trim()`），value 是完整的 `RequirementBlock`。

注意：`normalizeRequirementName` 只做 trim，**不做 toLowerCase**。header 匹配用的 regex 是大小写不敏感的（`/^###\s*Requirement:\s*(.+)\s*$/i`），但 map key 保留原始大小写。这意味着 `### Requirement: User Auth` 和 `### Requirement: user auth` 的 header 能被同一个 regex 匹配，但它们在 map 中是不同的 key。

### 3.5 按序应用操作

这是整个archive 流程中最关键的代码段 (`specs-apply.ts:244-306`)。操作有严格的顺序，**不能打乱**：

#### 第一：RENAMED（`specs-apply.ts:245-266`）

```typescript
// 1. 在 map 中查找 from → 找不到报错
// 2. 检查 to 是否已被占用 → 已占用报错
// 3. 获取 from 的 block，改写 header 行
// 4. 删除旧 key，用新 key 替换
```

为什么 RENAMED 必须最先做？因为如果 RENAMED 在后，MODIFIED 只能引用旧名字，导致改名后 MODIFIED 的内容丢失。

**修复**：rename 操作现在使用 `orderedKeys` 列表追踪位置标识。rename 更新 key 而不把块移到 spec 尾部（之前的 Map delete+set 会将条目移到插入顺序末尾），因此 RENAMED + MODIFIED 同一条时 rename 保持在原位置，archive diff 更易读。

#### 第二：REMOVED（`specs-apply.ts:269-281`）

```typescript
// 1. 在 map 中查找 name → 找不到报错（新 spec 除外）
// 2. 从 map 中 delete
```

为什么 REMOVED 在 MODIFIED 前？因为如果 MODIFIED 在 REMOVED 前，REMOVED 会删除 MODIFIED 的结果。正确的语义是：先移掉不需要的，再修改保留的。

为什么 REMOVED 在 RENAMED 后？因为 RENAMED 改了 key，REMOVED 应该针对的是新 key。

#### 第三：MODIFIED（`specs-apply.ts:284-297`）

```typescript
// 1. 在 map 中查找 name → 找不到报错
// 2. 验证新 block 的 header 与 key 一致
// 3. 替换 map 中的 block
```

完整的 requirement block（包括所有 scenario）必须在 MODIFIED 中提供 —— 不是 diff，是整个替换。这就是为什么 schema instruction 反复强调"copy the ENTIRE requirement block"。

#### 第四：ADDED（`specs-apply.ts:300-306`）

```typescript
// 1. 在 map 中查找 name → 已存在报错
// 2. 插入新 block
```

为什么 ADDED 最后？因为如果在 RENAMED 之前做 ADDED，RENAMED 的 TO 可能和 ADDED 冲突检测为假阴性。ADDED 应该检测合并后的最终状态。

### 3.6 重建 spec（修复 rename 保序）

此前 rename 操作通过 Map delete+set 将块移到 insertion-order 尾部。它使用 `orderedKeys` 列表独立追踪位置标识：

```typescript
// orderedKeys 保持源块的顺序标识，rename 更新 key 不移动尾部
const orderedKeys = parts.bodyBlocks.map((b) => normalizeRequirementName(b.name));
// ... rename 操作更新 orderedKeys[index] = to 而非 delete+set
// 重建时按 orderedKeys 顺序而非 Map 迭代顺序
for (let index = 0; index < parts.bodyBlocks.length; index++) {
  const key = orderedKeys[index];
  const replacement = nameToBlock.get(key);
  ...
}

for (const block of parts.bodyBlocks) {
  const key = normalizeRequirementName(block.name);
  const replacement = nameToBlock.get(key);
  if (replacement) keptOrder.push(replacement);  // 原有或替换
}
for (const [key, block] of nameToBlock) {
  if (!seen.has(key)) keptOrder.push(block);      // 全新追加
}

// 拼接：before + header + body + after
const rebuilt = [parts.before, parts.headerLine, reqBody, parts.after]
  .join('\n')
  .replace(/\n{3,}/g, '\n\n');  // 压缩多余空行
```

新内容（ADDED）仍追加到末尾。保留的块中有 `## Scenario:` 等被 MODIFIED 吸收的 tail 内容时，会检测 `firstForeignTail` 并标记 loss 信息。

**对顺序的尊重**：已有的 requirement 保持它们原来的相对位置。新的 requirement 追加到 Requirements section 末尾。这避免了每次archive 打乱整个 spec，让 git diff 可读。

**空行压缩不碰代码 fence**。`buildUpdatedSpec()` 末尾的空行压缩（`.replace(/\n{3,}/g, '\n\n')`）之前是无差别作用于整个重建文档——需求里 YAML block scalar、Python、expected-output 样例只要含两个以上连续空行，archive 每次跑都会「整理」一次，而空白在那些上下文里携带语义。现在改用 `collapseBlankRunsOutsideFences`（复用模块内已有的 `buildCodeFenceMask`），只在 fence 外折叠空行；fence 内原样保留。fence 外行为不变：只有真正空行算 blank，纯空格行永不作为折叠边界。

### 3.7 写前验证

CLI 会先对所有 `SpecUpdate` 调用 `buildUpdatedSpec()`，把 rebuilt 内容准备好；如果这一步任何一个 spec 失败，会在写入前中止并提示 "No files were changed."。

随后先对 prepared 列表中所有需要写回的 rebuilt spec 运行 `Validator.validateSpecContent()`（`src/core/validation/validator.ts`）。只有**全部 rebuilt validation 通过**，才会检查 archive 目标、验证输入 fingerprint、捕获每个 mutation target 的 snapshot，然后进入写入/退役阶段。

写入、退役或最终移动 change 失败时，CLI 会调用 `restoreSpecSnapshots()`，并在 change 已移动时尝试把 archive 目录移回 active 位置。因此当前边界是“尽力事务式回滚”，不是“写过就不恢复”。若并发外部修改使安全恢复不再可能，CLI 会保留现场并显式报告 `Rollback also failed`；这种 rollback failure 才需要人工按报错路径恢复。

### 3.8 已 early-sync 的 delta 不再一律失败

识别“agent sync 已把同一内容写入 main spec”的正常模式：内容相同的 ADDED/MODIFIED、已消失的 REMOVED、以及 source 已消失但 target 已存在的 RENAMED 都是 no-op，archive 不会为它们重写 main spec。REMOVED 的 no-op 会携带 warning，JSON archive 结果也可返回 `warnings`。

这个宽容只针对**确实已应用的同一操作**。主 spec 里仍存在仅大小写或空白不同的近似 requirement 时，工具会明确报错要求精确匹配；内容不同的 ADDED 仍是 collision。fenced code 中的 scenario/header 也不会参与 drift 比较，UTF-8 BOM 不会让首个 delta section 失效。

---

## 4. 移动阶段

### 4.1 生成archive 名

```typescript
const archiveName = /^\d{4}-\d{2}-\d{2}-/.test(changeName)
  ? changeName
  : `${formatLocalDate()}-${changeName}`;
// "add-dark-mode" -> "2026-06-14-add-dark-mode"
// "2026-06-01-add-dark-mode" -> 保持原名，不重复前缀
```

### 4.2 冲突检测

如果 `archive/2026-06-14-add-dark-mode/` 已存在 → 报错退出。建议用户改名或删除重复 archive。

### 4.3 移动

`moveDirectory()` 先用 `fs.rename()` 尝试原子移动。如果失败且错误码为 `EPERM` 或 `EXDEV`（Windows/跨设备常见），不会直接从仍可能被编辑的 active path 复制并删除，而是：

```text
active source
  -> rename 到同级私有 .openspec-move-<uuid>
  -> fingerprint staged source
  -> 复制到目标
  -> 验证 source/destination fingerprint 与 archived deltas
  -> 删除 staged source
```

复制或验证失败时，CLI 清理自己创建的目标并把 staged source 改回 active path。若最后清理 staged source 失败但目标已是唯一完整副本，则保留完整目标并给 recovery 错误，而不是为追求表面原子性再把目标删除。

### 4.4 最终状态

```
openspec/changes/archive/2026-06-14-add-dark-mode/
  .openspec.yaml
  proposal.md
  specs/
    theme/spec.md
  design.md
  tasks.md

openspec/specs/theme/spec.md    ← 已更新（如果有 delta spec）
```

---

## 5. Sync 检查与 operation inputs（host workflow 层面）

host archive workflow (`archive-change.ts`) 在选择 change 后先调用 `openspec instructions archive --change <name> --json`。返回的 `context` 是项目级 prompt input，`operationGuidance` 是适用时遵守的 advisory guidance；它们不改变 CLI root、validator、任务确认或 merge 规则。随后 workflow 才在移动之前检查 delta spec 是否已经合并到主 spec。这个检查属于 **agent 模板层**，不是 `ArchiveCommand.execute()` 的内部步骤。

```text
if delta specs exist:
   对比 change 中的 delta spec 和主 spec
   提示用户四选一：
     - "Sync now (recommended)"  → inline 执行 sync → 验证全部 capability → 通过后才 mv
     - "Archive without syncing" → 直接 archive
     - "Cancel"                  → 停止，changeRoot 完整
     - 其他输入                  → 重新询问
```

**当前加固行为**：
- sync 必须 **inline** 执行（不等完成绝不 mv——防止 changeRoot 被移走后 sync 读不到 delta spec）
- sync 完成后对 `artifactPaths.specs.existingOutputPaths` 中**每个 capability** 重新验证：ADDED 存在、MODIFIED 含变更且其他 scenario 完整、REMOVED 消失、RENAMED 用新名
- 任何 mismatch 都停止 archive，changeRoot 保持完整
- main spec 路径改用 store-aware `planningHome.root`，不硬编码当前 repo 路径
- 新增 **Cancel** 选项

---

## 6. 命令行标志

| flag | 作用 |
|------|------|
| `-y, --yes` | 跳过所有确认提示 |
| `--skip-specs` | 跳过 spec 合并（只验证+移动） |
| `--no-validate` | 跳过验证（不推荐，需要额外确认） |

---

## 7. archive 后的不可逆性

archive 操作没有"unarchive"。一旦 change 移入 `archive/`，它就从活跃工作流中消失了。如果 spec 合并出问题，只能手动修正主 spec 文件然后重新提交。

这也是为什么验证阶段如此严格 —— 一旦写入主 spec，错误的 requirement 就会成为系统的正式基线。

---

## 8. 当前行为摘要

| 变更 | 影响位置 | 说明 |
|---|---|---|
| date prefix 防堆叠 | `archive.ts`：move 前检测 change name 是否已有 `YYYY-MM-DD-` 前缀 | 已有前缀则不再叠加，避免 `2026-07-21-2026-06-14-xxx` |
| recursive capability path | `spec-discovery.ts` / `findSpecUpdates()` | 支持 `specs/identity/session/spec.md`；delta/main 同路径；根级 delta 会报错 |
| Purpose carry-through | `specs-apply.ts` | 新 capability 的 delta Purpose 进入新 main spec；existing Purpose 保持权威 |
| early-sync no-op | `specs-apply.ts` | 完全一致的 ADDED/MODIFIED、已移除 REMOVED、已改名 RENAMED 不造成无意义失败或重写 |
| parser / drift robustness | `requirement-blocks.ts` / `code-fence.ts` | BOM、fenced code 不再造成假 delta 或 scenario drift |
| inline verified sync | `archive-change.ts` | agent sync 后逐 capability 验证才允许移动 change；Cancel 保留 changeRoot |
| **retire_capabilities** | `.openspec.yaml` marker（`archive.ts` / `specs-apply.ts`） | change 的 REMOVED 拿掉某 capability 最后一个 requirement 时，声明 `retire_capabilities: true` 可让 archive 删除整个 main spec，而不是以 "at least one requirement" 中止；无 marker 时行为不变。退役只发生在 spec 确实无法保留时，输出会列出被删 section 并给可粘贴的 `git checkout` 恢复命令；`--no-validate` 永不触发退役。与退役 capability 的 in-flight MODIFIED change 会 validate 通过、archive 拒绝（blocked-content 细分见下） |
| 重复 canonical 名拒绝 | `archive.ts` | main spec 存在重复 canonical requirement 名时拒绝归档，避免 delta reconciliation 压掉重复块之一 |
| note-loss 提示 | `archive.ts` | 重建 spec 会丢失 requirement 旁的 note（缩进 note、未识别 heading）时，先指名会删的内容与迁移位置；merge 本身不自动搬移 |
| 交互失败可重跑 | `archive.ts` 的 `confirmOrBlock()` | agent 以 stdin closed 跑 archive 时，每个被阻塞的确认会给出需要哪个 flag 和携带原 flags 的可粘贴重跑（如 `openspec archive <name> --skip-specs --yes`）；无 change 名时从 exit 0 吞错改为 exit 1 请求 change 名 |
| 非 TTY 无 ANSI | `src/utils/interactive.ts` | stdout/stdin 不是终端时 confirm 走纯文本；无 change 名时要求先传入名字，不画菜单。避免捕获日志里塞满 cursor-move 转义 |
| spec 重建保空白 | `specs-apply.ts` | 保留 `## Requirements` 周围空行，文件末尾恰好一个 LF，避免 Markdown whitespace 检查失败 |
| scenario-loss 认所有 `####` | `requirement-text.ts` `SCENARIO_HEADER` | requirement 下任何非 fence 的 `#### ` 子标题都算 scenario；比较时剥可选 `Scenario:` 前缀 |

### retirement 的三分支

| 重建后状态 | archive 的诊断 | 正确处理 |
|---|---|---|
| 空 capability，除 title/Purpose/requirements 外无内容，且只缺 marker | 提示添加 `retire_capabilities: true` | 在有效 `.openspec.yaml` 中与 `schema:` 并列添加后重跑 |
| 空 capability，但有 `## Notes`、orphan section、requirement 外注释等 unaccounted content | 列出 blocking lines；不会建议 marker | 把内容移入 `## Purpose` 或 canonical requirement，或人工删除 spec，再重跑 |
| marker 已存在但不能 honor，或 marker 有效但仍有 blocking content | 报具体 invalid reason，或明确“declares retire_capabilities, but ...” | 先修 YAML/schema/boolean marker，或清理 blocking content；marker 不能绕过内容丢失保护 |

### archive / parser 加固

| 变更 | 影响位置 | 说明 |
|---|---|---|
| rename 保序 | `specs-apply.ts` `buildUpdatedSpec()` | `orderedKeys` 独立追踪位置标识，RENAMED 更新 key 但不移到 spec 尾部 |
| Purpose 占位符检测 | `src/core/validation/purpose-placeholder.ts` | validate 检测 archive 遗留的 `TBD - created by archiving change ...`，WARNING 级、`--strict` 失败 |
| advisory merge preflight | `src/core/validation/` | delta 与 main spec 的合并冲突在 validate 阶段报为 informational findings，不改退出码；FS 读取错误保留为 error |
| delta section 改 list | `requirement-blocks.ts` | 重复 `## ADDED/...` header 全部应用，不再互相覆盖；FROM/TO 按 section 配对 |
| 全 CommonMark 标记 | `requirement-blocks.ts` | REMOVED/RENAMED 接受 `[-*+]`；此前 `*`/`+` 写的 delta 静默不生效 |
| 换行 scenario bullet | `specs-apply.ts` / retirement | 包裹换行的 bullet 读成一条，`+` 标记也识别 |
| fence 内空行保真 | `specs-apply.ts` `collapseBlankRunsOutsideFences` | 只折叠 fence 外空行；YAML block scalar / Python / expected-output 样例不再被整理 |

安全输出也有硬边界：blocking content 最多展示 3 行，每行按 Unicode code point 截到 200，超出加省略号并汇总剩余行数；NUL–US、DEL 等控制字符替换为 `?`。marker 无法 honor 的 reason 同样清理控制字符，避免伪造终端行或重绘屏幕。
