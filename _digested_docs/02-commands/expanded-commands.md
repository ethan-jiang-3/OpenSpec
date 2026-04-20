# Expanded Profile 命令（7 个扩展）

开启方式：

```bash
openspec config profile   # 交互式勾选要启用的 workflow
openspec update            # 让项目目录生效
```

`ALL_WORKFLOWS` 一共 11 个，除了 core 的 4 个（propose / explore / apply / archive），还有下面这 7 个（见 [src/core/profiles.ts](../../src/core/profiles.ts)）：

```
new / continue / ff / verify / sync / bulk-archive / onboard
```

---

## `/opsx:new`

**一句话**：只搭骨架（scaffold），不生成任何 artifact，等你用 `/opsx:continue` 或 `/opsx:ff` 继续。

**语法**：`/opsx:new [change-name] [--schema <schema-name>]`

**产物**：
```
openspec/changes/<change-name>/
└── .openspec.yaml   # change 元数据（schema + 创建时间）
```

然后 AI 会告诉你「下一个可创建的 artifact 是 proposal」。

**用途**：想对每个 artifact 都做 review，或者想先把空壳 commit 一下。

---

## `/opsx:continue`

**一句话**：**查依赖图、建下一个 ready 的 artifact**。

**语法**：`/opsx:continue [change-name]`

**做了什么**：
1. 跑 `openspec status --json` 看哪些 artifact 是 ready
2. 读已经完成的依赖 artifact（给 AI 当上下文）
3. 创建**一个** artifact
4. 显示「现在解锁了什么」

**典型输出**：
```text
Artifact status:
✓ proposal    (done)
◆ specs       (ready)
◆ design      (ready)
○ tasks       (blocked - needs: specs)

Creating specs...
✓ Created openspec/changes/add-dark-mode/specs/ui/spec.md

Now available: tasks
```

**用途**：复杂 change，想一步一 review。

---

## `/opsx:ff`

**一句话**：快进——一次把**所有**规划 artifact 全部建完。

**语法**：`/opsx:ff [change-name]`

**做了什么**：按 DAG 拓扑顺序，一次性生成 proposal → specs → design → tasks，每建一个都读前置的内容再生成。

**和 `/opsx:propose` 的区别**：
- `/opsx:propose` = `/opsx:new` + `/opsx:ff` 的合体，用于 core profile
- `/opsx:ff` 用在 expanded profile，前提是已经用 `/opsx:new` 建好了骨架

---

## `/opsx:verify`

**一句话**：实现做完后，**从三个维度检查代码是否匹配 artifact**。

**语法**：`/opsx:verify [change-name]`

**三个维度**：

| 维度 | 校验什么 |
|------|----------|
| **Completeness（完整性）** | tasks 都打勾了？specs 里所有 requirement 都有代码？scenario 都覆盖了？ |
| **Correctness（正确性）** | 实现和 spec intent 一致？边界 case 处理了？错误状态符合 spec？ |
| **Coherence（一致性）** | 代码的架构体现了 design 里的决策？命名和 design 一致？ |

**输出**：按 CRITICAL / WARNING / SUGGESTION 分类的问题单，**不阻塞 archive**，只提醒。

**用途**：归档前兜底，尤其是让 AI 帮你检查 AI 自己写的代码。

---

## `/opsx:sync`

**一句话**：把 change 里的 delta spec 合并到主 `openspec/specs/`，但**不归档 change**。

**语法**：`/opsx:sync [change-name]`

**大多数人不需要用**——`/opsx:archive` 已经会问你要不要 sync。

**需要手动 sync 的场景**（见 [docs/commands.md](../../docs/commands.md)）：
- 长周期 change，想让主 specs 先跟进
- 多个并行 change 需要基于最新的主 specs
- 想单独 review merge 结果

---

## `/opsx:bulk-archive`

**一句话**：一次归档多个 change，并且能**检测和解决 spec 冲突**。

**语法**：`/opsx:bulk-archive [change-names...]`

**做了什么**：
1. 列出所有已完成的 change
2. 检查多个 change 是否 touch 同一个 spec（冲突预警）
3. 按实际代码来 agentic 地解决冲突
4. 按创建时间顺序合并

**用途**：并行工作流、团队协作、批量收尾。

---

## `/opsx:onboard`

**一句话**：**交互式教程**，用你自己的代码库走一遍完整工作流。

**语法**：`/opsx:onboard`

**11 个阶段**（来自 [docs/commands.md](../../docs/commands.md)）：

1. 欢迎 + 代码库分析
2. 找一个真实的改进机会
3. `/opsx:new` 创建 change
4. 写 proposal
5. 写 specs
6. 写 design
7. 写 tasks
8. `/opsx:apply` 真的实现
9. `/opsx:verify` 真的验证
10. `/opsx:archive` 真的归档
11. 总结 + 下一步

**用时**：15–30 分钟，新人上手最快的路。

---

## Expanded 路径典型流程

```
/opsx:explore
      ↓
/opsx:new add-feature
      ↓
/opsx:ff  或  /opsx:continue（反复若干次）
      ↓
/opsx:apply
      ↓
/opsx:verify   ← 可选但推荐
      ↓
/opsx:sync     ← 通常不需要手动
      ↓
/opsx:archive  或  /opsx:bulk-archive
```
