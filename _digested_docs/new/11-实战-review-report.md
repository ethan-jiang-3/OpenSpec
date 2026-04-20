# Review Report: 11-实战-如何正确修改-artifacts.md

## 执行时间
2024-01-XX

## Review 目标
检查文档内容是否与 OpenSpec 的真实实现对齐，发现潜在的错误、误导性信息或缺失的重要细节。

---

## 🔴 严重问题（必须修复）

### 问题 1：`/opsx:continue` 命令的误导性描述

**位置**：文档多处提到 `/opsx:continue`

**问题**：
文档中多次建议使用 `/opsx:continue` 来重新生成单个 artifact，例如：
```bash
# 步骤 2：在 Cline 里重新生成
/opsx:continue
```

**真实情况**（从源码验证）：
- `/opsx:continue` 是 **expanded profile** 的命令，不是 core profile 的
- Core profile（默认）只有 4 个命令：propose, explore, apply, archive
- 新手默认使用 core profile，看到 `/opsx:continue` 会报错"命令不存在"

**来源**：
- `docs/getting-started.md` line 21: "The default global profile is `core`"
- `docs/workflows.md` 明确区分了 core 和 expanded 命令

**修复建议**：
1. 在文档开头明确说明：本文档假设使用 **expanded profile**
2. 或者，为 core profile 用户提供替代方案
3. 添加如何切换 profile 的说明

**影响**：⭐⭐⭐⭐⭐ 严重（新手会直接卡住）

---

### 问题 2：删除文件重新生成的方法不完整

**位置**：多处提到删除文件重新生成

**问题**：
文档建议：
```bash
rm openspec/changes/<name>/proposal.md
/opsx:continue
```

**真实情况**：
- 删除单个 artifact 文件后，OpenSpec 的行为取决于 schema 和依赖关系
- 没有说明删除后如何触发重新生成
- Core profile 用户无法使用 `/opsx:continue`

**修复建议**：
1. 说明删除后的正确流程
2. 区分 core 和 expanded profile 的做法
3. 可能需要说明：删除后，在 Cline 里直接说"请重新生成 proposal.md"

**影响**：⭐⭐⭐⭐ 高（会导致操作失败）

---

### 问题 3：`openspec validate` 的能力被夸大

**位置**：多处提到 `openspec validate`

**问题**：
文档暗示 `openspec validate` 可以验证很多东西，但实际上：

**真实情况**（从探索 agent 的发现）：
- `openspec validate` 只验证**结构**，不验证**内容**
- 验证的内容：
  - 文件存在
  - 基本格式（YAML、Markdown 结构）
  - Delta spec 语法（ADDED/MODIFIED/REMOVED）
  - Requirements 必须有 SHALL/MUST
  - Scenarios 必须有 GIVEN/WHEN/THEN
- **不验证**：
  - 内容质量
  - 跨 artifact 一致性
  - 业务逻辑合理性

**修复建议**：
明确说明 `openspec validate` 的能力边界，避免让用户以为它能验证所有问题。

**影响**：⭐⭐⭐ 中等（会产生错误期望）

---

### 问题 4：config.yaml 的 rules 格式不一致

**位置**：config.yaml 示例

**问题**：
文档中同时出现了两种 rules 格式：

**格式 1：纯文本**
```yaml
rules: |
  - Write tests
  - Add docs
```

**格式 2：结构化**
```yaml
rules:
  proposal:
    - Include rollback plan
  specs:
    - Add unhappy-path scenarios
```

**真实情况**：
- 需要验证 OpenSpec 是否真的支持两种格式
- 如果只支持一种，文档会误导用户

**修复建议**：
1. 查看源码确认支持哪种格式
2. 统一使用一种格式，或明确说明两种都支持

**影响**：⭐⭐⭐⭐ 高（会导致配置无效）

---

## 🟡 中等问题（建议修复）

### 问题 5：缺少 core profile 的替代方案

**位置**：整个文档

**问题**：
文档假设用户使用 expanded profile，但大多数新手使用 core profile（默认）。

**修复建议**：
为每个场景提供 core profile 的替代方案，例如：

**Expanded profile**：
```bash
rm proposal.md
/opsx:continue
```

**Core profile**：
```bash
rm proposal.md
# 在 Cline 里说："请重新生成 proposal.md"
```

**影响**：⭐⭐⭐ 中等（影响用户体验）

---

### 问题 6：缺少"AI 辅助编辑"的具体操作步骤

**位置**：方式 2：AI 辅助编辑

**问题**：
文档说"在 Cline 里说：..."，但没有说明：
- 在哪个上下文中说？
- 需要先打开文件吗？
- AI 会直接修改文件还是给出建议？

**修复建议**：
补充完整的操作步骤，例如：
1. 在 Cline 的聊天框里输入指令
2. AI 会读取文件、分析、修改
3. 检查修改是否正确
4. 运行 validate 验证

**影响**：⭐⭐⭐ 中等（新手不知道具体怎么操作）

---

### 问题 7：缺少"改错了怎么办"的完整方案

**位置**：常见问题部分

**问题**：
文档提到了 3 种方案（Git 回滚、删除重新生成、让 AI 修复），但没有说明：
- 什么情况下用哪种方案？
- 如果没有 Git 历史怎么办？
- 如果 AI 修复失败怎么办？

**修复建议**：
补充决策树和完整的故障恢复流程。

**影响**：⭐⭐ 低（但会影响用户信心）

---

## 🟢 轻微问题（可选修复）

### 问题 8：示例过于理想化

**位置**：所有示例

**问题**：
所有示例都假设操作一次就成功，但实际上：
- AI 可能生成不符合预期的内容
- validate 可能报错
- 需要多次迭代

**修复建议**：
添加一些"不完美"的示例，展示迭代过程。

**影响**：⭐ 很低（但会让文档更真实）

---

### 问题 9：缺少"什么时候不应该修改"的指导

**位置**：整个文档

**问题**：
文档强调"可以随时修改"，但没有说明：
- 什么时候不应该修改？
- 修改后会有什么副作用？
- 如何评估修改的影响？

**修复建议**：
添加"修改的最佳时机"和"修改的风险评估"章节。

**影响**：⭐ 很低（进阶内容）

---

## ✅ 做得好的地方

1. **丰富的真实场景**：每个 artifact 都有多个真实场景
2. **完整的示例**：从空配置到强配置的演进过程
3. **决策树**：帮助用户判断该用哪种方式
4. **对比表**：清晰展示不同方式的优缺点
5. **错误示例**：展示常见错误和修复方法

---

## 🎯 必须补充的内容

### 1. Profile 说明

在文档开头添加：

```markdown
## 重要前提

本文档中的某些命令（如 `/opsx:continue`）需要 **expanded profile**。

**检查你的 profile**：
```bash
# 查看当前 profile
openspec config profile

# 如果是 core，切换到 expanded
openspec config profile
# 选择 custom/expanded
openspec update
```

**Core profile 用户**：
如果你使用默认的 core profile，某些命令不可用。
你可以：
1. 切换到 expanded profile（推荐）
2. 使用替代方案（在 Cline 里直接说明需求）
```

### 2. 真实的命令验证

需要验证以下命令是否真实存在：
- `openspec validate`
- `openspec instructions proposal --json`
- `openspec status --json`

### 3. 补充"没有 AI 工具时怎么办"

文档假设用户使用 Cline，但如果用户：
- 只用 CLI
- 用其他 AI 工具
- 完全手动操作

应该怎么做？

---

## 📋 修复优先级

### P0（立即修复）
1. ✅ 添加 profile 说明
2. ✅ 修正 `/opsx:continue` 的使用场景
3. ✅ 明确 `openspec validate` 的能力边界
4. ✅ 验证 config.yaml 的 rules 格式

### P1（尽快修复）
5. ✅ 为 core profile 提供替代方案
6. ✅ 补充"AI 辅助编辑"的完整步骤
7. ✅ 完善"改错了怎么办"的方案

### P2（可选）
8. 添加不完美的示例
9. 添加"修改的最佳时机"章节

---

## 🔍 需要进一步验证的内容

1. **config.yaml 的 rules 格式**
   - 查看 `src/core/config-schema.ts` 或相关文件
   - 确认支持哪种格式

2. **删除文件后的行为**
   - 测试删除 proposal.md 后会发生什么
   - OpenSpec 是否会自动检测并提示重新生成？

3. **validate 命令的完整能力**
   - 查看 `src/commands/validate.ts`
   - 列出所有验证项

4. **instructions 命令的输出格式**
   - 运行 `openspec instructions proposal --json`
   - 确认输出格式是否如文档所述

---

## 总结

**整体评价**：⭐⭐⭐⭐ (4/5)

**优点**：
- 内容丰富，场景真实
- 结构清晰，易于理解
- 大量示例和对比表

**主要问题**：
- 假设用户使用 expanded profile，但大多数新手用 core
- 某些命令的使用场景不准确
- 缺少 profile 切换的说明

**修复后预期评分**：⭐⭐⭐⭐⭐ (5/5)

---

## 下一步行动

1. 立即修复 P0 问题（profile 说明、命令准确性）
2. 验证需要确认的内容（rules 格式、validate 能力）
3. 补充 P1 问题（替代方案、完整步骤）
4. 考虑是否添加 P2 内容（进阶指导）
