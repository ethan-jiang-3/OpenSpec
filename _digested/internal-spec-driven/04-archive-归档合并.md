# 04 — archive：归档合并

archive 是整个 change 生命周期的终点。它做三件事：验证 change、将 delta spec 合并到主 spec 基线、然后把 change 目录移到归档区。

---

## 1. 三阶段总览

来自 `src/core/archive.ts:50-288`（`ArchiveCommand.execute()`）：

```
Phase 1: Validate
  ├── proposal.md 验证（非阻塞，只警告）
  └── delta spec 验证（阻塞，有 ERROR 就拒绝归档）

Phase 2: Merge（除非 --skip-specs）
  ├── 找到所有 delta spec
  ├── 逐一构建更新后的 spec（buildUpdatedSpec）
  ├── 验证重建后的 spec
  └── 写入主 specs 目录

Phase 3: Move
  ├── 创建 archive/ 目录
  ├── 生成归档名 YYYY-MM-DD-<changeName>
  └── mv changeDir → archive/
```

---

## 2. 验证阶段

### 2.1 proposal 验证（非阻塞）

`archive.ts:96-111`：用 `Validator.validateChange()` 验证 proposal.md 的结构（Why/What Changes 等 section 是否存在、长度是否合理）。但**验证失败不会阻止归档**——proposal 验证是信息性的。

### 2.2 delta spec 验证（阻塞）

`archive.ts:113-151`：扫描 `<changeDir>/specs/` 下每个子目录中带 delta header 的文件（`## ADDED/MODIFIED/REMOVED/RENAMED Requirements`）。

如果发现 delta spec，用 `Validator.validateChangeDeltaSpecs()` 进行严格验证：

| 检查项 | 级别 |
|--------|------|
| 缺少 `## Requirements` section 中的 `### Requirement:` header | ERROR |
| ADDED/MODIFIED requirement 缺少 SHALL/MUST | ERROR |
| requirement 缺少 scenario | ERROR |
| 同一 section 内 requirement 名重复 | ERROR |
| 同一 requirement 出现在多个 section 中（如同时 ADDED 和 MODIFIED） | ERROR |
| requirement 文本过长 | WARNING |
| delta 数量超过阈值 | WARNING |

如果存在任何 ERROR，**归档被拒绝**。WARNING 会被显示但不阻止。

`--no-validate` 可以跳过所有验证，但需要额外确认（或 `--yes`）。

### 2.3 任务完成检查

`archive.ts:174-194`：读取 tasks.md，统计未完成 checkbox。如果有未完成任务，警告并要求确认。

---

## 3. 合并阶段：核心算法

这是整个 OpenSpec 中最精密的单段算法。位于 `src/core/specs-apply.ts:102-348`（`buildUpdatedSpec()`）。

### 3.1 找 delta spec

`findSpecUpdates()` (`specs-apply.ts:57-96`)：扫描 `<changeDir>/specs/` 下每个子目录。对于每个包含 `spec.md` 的子目录，查找对应的主 spec 文件：

```
change/specs/data-export/spec.md  →  openspec/specs/data-export/spec.md
change/specs/user-auth/spec.md    →  openspec/specs/user-auth/spec.md
```

返回 `SpecUpdate[]`，每个包含 `{source, target, exists}`（target 是主 spec 路径，exists 表示主 spec 是否已存在）。

### 3.2 解析 delta plan

`parseDeltaSpec()` (`src/core/parsers/requirement-blocks.ts:99-234`)：将 delta 格式的 spec 文件解析成 `DeltaPlan`：

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
3. `parseRequirementBlocksFromSection()`：提取 `### Requirement:` header 和 body 内容（包括 `#### Scenario:`）
4. `parseRemovedNames()`：提取 requirement 名（可以是 `### Requirement:` header 或 bullet 中的引用）
5. `parseRenamedPairs()`：解析 `FROM:` / `TO:` 对

### 3.3 预验证（合并前）

`specs-apply.ts:113-200`，在修改任何文件之前先做五重检查：

1. **section 内重复**：同一个 ADDED section 内不能有两个同名 requirement；MODIFIED/REMOVED/RENAMED 同理
2. **跨 section 冲突**：同一个 requirement 名不能同时出现在 ADDED 和 MODIFIED 中（或任何其他组合）
3. **RENAMED + MODIFIED 交互**：如果有 RENAMED 将 `OldName` → `NewName`，则 MODIFIED 必须引用 `NewName`（不能引用 `OldName`）
4. **RENAMED + ADDED 冲突**：RENAMED 的 TO 不能和 ADDED 的 requirement 重名
5. **空 delta**：至少有一个 delta 操作

如果目标 spec 不存在（新 capability）：
- 只允许 ADDED。MODIFIED/RENAMED 会报错（因为没有东西可以 modify/rename）
- REMOVED 会被忽略并产生警告（没有东西可以 remove）

### 3.4 提取主 spec 的 Requirements section

`extractRequirementsSection()` (`requirement-blocks.ts`)：将目标 spec 的内容拆分为：

```
before:   "# Capability Specification\n\n## Purpose\n..."
header:   "## Requirements"
preamble: ""（或 header 后的文字直到第一个 requirement）
body:     [RequirementBlock, RequirementBlock, ...]
after:    ""（Requirements section 之后的文字）
```

然后构建 `nameToBlock` map：key 是 normalized requirement name（trim 后的小写），value 是完整的 `RequirementBlock`。

### 3.5 按序应用操作

这是整个归档流程中最关键的代码段 (`specs-apply.ts:244-306`)。操作有严格的顺序，**不能打乱**：

#### 第一：RENAMED（`specs-apply.ts:245-266`）

```typescript
// 1. 在 map 中查找 from → 找不到报错
// 2. 检查 to 是否已被占用 → 已占用报错
// 3. 获取 from 的 block，改写 header 行
// 4. 删除旧 key，插入新 key
```

为什么 RENAMED 必须最先做？因为如果 RENAMED 在后，MODIFIED 只能引用旧名字，导致改名后 MODIFIED 的内容丢失。

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

### 3.6 重建 spec

```typescript
// 保持原有顺序，新加的内容追加到末尾
const keptOrder = [];
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

**对顺序的尊重**：已有的 requirement 保持它们原来的相对位置。新的 requirement 追加到 Requirements section 末尾。这避免了每次归档打乱整个 spec，让 git diff 可读。

### 3.7 写前验证

在写入每个重建后的 spec 之前，用 `Validator.validateSpecContent()` 验证。如果有 ERROR，**整个归档中断**，所有已写入的 spec 不会被回滚（但归档移动还没发生，change 目录还在原地）。

---

## 4. 移动阶段

### 4.1 生成归档名

```typescript
const archiveName = `${YYYY-MM-DD}-${changeName}`;
// 例: "2026-06-14-add-dark-mode"
```

### 4.2 冲突检测

如果 `archive/2026-06-14-add-dark-mode/` 已存在 → 报错退出。建议用户改名或删除重复归档。

### 4.3 移动

`moveDirectory()` (`archive.ts:36-48`)：先用 `fs.rename()` 尝试原子移动。如果失败且错误码为 `EPERM` 或 `EXDEV`（Windows 常见），降级为递归复制+删除：

```typescript
async function moveDirectory(src: string, dest: string): Promise<void> {
  try {
    await fs.rename(src, dest);           // 首选原子操作
  } catch (err) {
    if (err.code === 'EPERM' || err.code === 'EXDEV') {
      await copyDirRecursive(src, dest);   // 复制
      await fs.rm(src, { recursive: true, force: true });  // 删除源
    } else {
      throw err;
    }
  }
}
```

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

## 5. Sync 检查（OPSX 模板层面）

OPSX archive skill 模板 (`archive-change.ts:57-70`) 在移动之前会做一个额外检查：delta spec 是否已经合并到主 spec。

```
if delta specs exist:
   对比 change 中的 delta spec 和主 spec
   提示用户：
     - "Sync now (recommended)"  → 调用 openspec-sync-specs skill
     - "Archive without syncing" → 直接归档（delta 丢失但 change 保留在 archive 中）
```

这是一个**安全网**——如果用户在归档前忘了同步 spec，agent 会提醒。但用户可以选择跳过。

---

## 6. 命令行标志

| flag | 作用 |
|------|------|
| `-y, --yes` | 跳过所有确认提示 |
| `--skip-specs` | 跳过 spec 合并（只验证+移动） |
| `--no-validate` | 跳过验证（不推荐，需要额外确认） |

---

## 7. 归档后的不可逆性

归档操作没有"unarchive"。一旦 change 移入 `archive/`，它就从活跃工作流中消失了。如果 spec 合并出问题，只能手动修正主 spec 文件然后重新提交。

这也是为什么验证阶段如此严格 —— 一旦写入主 spec，错误的 requirement 就会成为系统的正式基线。
