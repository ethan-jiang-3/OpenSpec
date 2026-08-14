# 答案 ARC07：delta spec merge 到底怎么发生

## 一句话

archive 的 spec merge 不是简单复制 change spec。它把 change 下的 delta spec 解释成操作计划，然后把这些操作应用到主 `openspec/specs/` 的正式 spec 上。

核心源码在 `src/core/specs-apply.ts`：

```text
findSpecUpdates()
  -> buildUpdatedSpec()
  -> validateSpecContent()
  -> writeUpdatedSpec()
```

## 找到 spec updates

`findSpecUpdates(changeDir, mainSpecsDir)` 扫描：

```text
openspec/changes/<change>/specs/<capability-path>/spec.md
```

每个文件对应一个主 spec：

```text
openspec/specs/<capability-path>/spec.md
```

返回结构里有：

```text
source: change delta spec path
target: main spec path
exists: target 是否已存在
```

这一步不判断 delta 内容是否合理，只建立 source -> target 映射。

## 解析 delta plan

`buildUpdatedSpec()` 读取 source，然后调用 `parseDeltaSpec()`。

delta spec 识别四类 section：

```text
## ADDED Requirements
## MODIFIED Requirements
## REMOVED Requirements
## RENAMED Requirements
```

解析结果是：

```text
added: RequirementBlock[]
modified: RequirementBlock[]
removed: string[]
renamed: Array<{ from, to }>
```

`ADDED` 和 `MODIFIED` 解析成完整 requirement block；`REMOVED` 只需要 requirement 名；`RENAMED` 解析 `FROM:` / `TO:`。

## 预验证

写任何文件之前，`buildUpdatedSpec()` 会先检查：

- 同一个 section 内不能重复 requirement。
- 同一个 requirement 不能同时出现在多个 section。
- `RENAMED` 的 `TO` 不能和 `ADDED` 冲突。
- 如果有 rename，`MODIFIED` 必须引用新名字，不是旧名字。
- delta spec 至少要有一个操作。

如果目标 main spec 不存在，也就是新 capability：

- 允许 `ADDED`。
- `MODIFIED` 和 `RENAMED` 报错。
- `REMOVED` 会 warning 并忽略，因为没有东西可删。

delta 的 `## Purpose` 可位于 requirements 之前；v1.8.0（v1.7.0 起）会把可读 Purpose 写入新建 main spec。已有 main spec 的 Purpose 不会被 delta 覆盖。

## 读取或创建 main spec baseline

如果目标主 spec 存在，CLI 读取它。

如果不存在，CLI 创建 skeleton；可读的 delta Purpose 会代替占位文字：

```markdown
# <capability> Specification

## Purpose
TBD - created by archiving change <change>. Update Purpose after archive.

## Requirements
```

所以新 capability **不再总是**带 `TBD`：只有 delta 没有可读 Purpose 时，才会留下该 programmatic placeholder，之后可人工完善。

## 结构检查

对已有 main spec，CLI 调：

```text
findMainSpecStructureIssues(targetContent)
```

它会拦截两类危险结构：

- main spec 里出现 delta header，例如 `## ADDED Requirements`。
- `### Requirement:` 出现在主 `## Requirements` section 之外。

原因是 archive 只在主 `## Requirements` section 内解析 requirement。如果 requirement 藏在别的 section，合并会误判。

## 操作顺序

核心顺序固定：

```text
RENAMED -> REMOVED -> MODIFIED -> ADDED
```

### RENAMED

先把旧 requirement key 改成新 key。

通常 source 不存在会报错；但 v1.8.0（v1.7.0 起）对已正确 early-sync、内容完全一致的 ADDED/MODIFIED/REMOVED/RENAMED 识别为幂等 no-op。大小写、空白或内容只是“看起来接近”时仍会报错，不能当作宽松匹配。

### REMOVED

删除指定 requirement。

existing main spec 中找不到要删的 requirement 会报错。new spec 场景下，`REMOVED` 已经被 warning 并忽略。

### MODIFIED

用 delta 里的完整 requirement block 替换主 spec 里的旧 block。

这里不是 patch，不是“只加一个 scenario”。如果 `MODIFIED` 只写了一个新 scenario，archive CLI 会把原有 scenario 丢掉。这也是 schema instruction 强调必须复制完整 block 的原因。

### ADDED

最后加入新 requirement。

如果同名 requirement 已经存在，报错。

## 重建 spec

合并后，CLI 重建完整 spec：

```text
before
## Requirements
preamble
requirement blocks
after
```

已有 requirement 保持原顺序；新增 requirement 追加到 Requirements section 末尾。

这样做的工程价值是：避免 archive 每次把整个 spec 重排，保持 git diff 可读。

## 写前验证和写入

`ArchiveCommand.execute()` 会先 prepare 所有 updates：

```text
for each update:
  buildUpdatedSpec()
```

只要一个失败，直接中止：

```text
Aborted. No files were changed.
```

所有 rebuilt 内容都准备好后，CLI 遍历 prepared 列表。对每个 rebuilt spec，写入该 spec 前调用：

```text
Validator.validateSpecContent(specName, rebuilt)
```

有 ERROR 时会在当前 spec 写入前中止。

验证通过后才对当前 spec 调 `writeUpdatedSpec()`，并输出 operation counts。

这个边界要说精确：`buildUpdatedSpec()` 是全量预构建，失败不会写任何 spec；但 rebuilt validation 和写入是逐项交替执行的。进入写入循环后，如果前一个 spec 已写入、后一个 spec 验证失败或 I/O 失败，CLI 没有跨 spec transaction 回滚。

## 和 `/opsx:sync` 的差异

CLI archive 的 merge 是 programmatic merge：

- `MODIFIED` 是完整替换。
- 无法智能理解“只新增一个 scenario”。
- 结果可预测，规则严格。

`/opsx:sync` 是 agent-driven merge：

- agent 读 delta spec 和 main spec。
- 可以智能合并局部变化。
- 依赖 agent 判断和用户 review。

所以两者不是同一个机制。`/opsx:archive` 模板会在 archive 前做 sync assessment，就是为了避免用户误以为移动 change 等于 specs 一定已经合理同步。

## 参考来源

源码引用以 v1.9.0（`2826b88`；release tag `v1.9.0` = `2826b88`）为当前基线：

| 来源 | 用到的结论 |
|---|---|
| `src/core/specs-apply.ts` | `findSpecUpdates()`、`buildUpdatedSpec()`、operation ordering、skeleton、write |
| `src/core/parsers/requirement-blocks.ts` | delta parsing、requirement extraction、name normalization |
| `src/core/parsers/spec-structure.ts` | main spec structure guard |
| `src/core/archive.ts` | prepare all updates、validate rebuilt specs、write specs |
| `src/core/templates/workflows/sync-specs.ts` | agent-driven sync 的差异 |
