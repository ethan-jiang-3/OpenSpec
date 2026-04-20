# Core Profile 命令（4 个）

安装 OpenSpec 后**默认就开启**这 4 个命令（来自 [src/core/profiles.ts](../../src/core/profiles.ts) 的 `CORE_WORKFLOWS`）：

```
propose / explore / apply / archive
```

> 想用更细粒度的 7 个扩展命令，去 `openspec config profile` 切到 custom，见 [expanded-commands.md](expanded-commands.md)。

---

## `/opsx:propose`

**一句话**：创建一个新的 change 并**一次性生成**所有规划 artifact（proposal / specs / design / tasks），到可以实现的状态就停。

**语法**：`/opsx:propose [change-name-or-description]`

**做了什么**：
1. 在 `openspec/changes/<name>/` 建目录
2. 按当前 schema（默认 `spec-driven`）依次生成四个 artifact
3. 停在「ready for `/opsx:apply`」

**典型输出**：
```text
You: /opsx:propose add-dark-mode

AI:  Created openspec/changes/add-dark-mode/
     ✓ proposal.md
     ✓ specs/ui/spec.md
     ✓ design.md
     ✓ tasks.md
     Ready for implementation. Run /opsx:apply.
```

**什么时候用**：端到端最快的路径，知道自己要什么时首选。

**不适合**：需要逐个 artifact review、迭代，那要切到扩展模式用 `/opsx:new` + `/opsx:continue`。

---

## `/opsx:explore`

**一句话**：**不创建任何文件**的思考搭档——梳理想法、对比方案、调研代码库，最后再决定要不要发起 change。

**语法**：`/opsx:explore [topic]`

**做了什么**：
- 开一段探索式对话
- AI 可读代码、搜索 repo、比较多种方案、画图
- 确认方向后，过渡到 `/opsx:propose`（core）或 `/opsx:new`（expanded）

**典型场景**：
- 需求还模糊，先想清楚
- 性能 / 架构问题要先调研
- 多个候选方案要对比

---

## `/opsx:apply`

**一句话**：读 `tasks.md`，逐个打勾地把任务实现掉。

**语法**：`/opsx:apply [change-name]`

**做了什么**：
1. 读当前 change 的 `tasks.md`
2. 找未勾选的任务
3. 写代码、建文件、跑测试
4. 完成一个就把 `- [ ]` 改成 `- [x]`

**可恢复性**：中断后再跑会从上次停下的 task 接着做（因为状态存在 checkbox 里）。

**多 change 并行**：可以显式 `/opsx:apply add-dark-mode` 指定，否则 AI 会从上下文推断。

---

## `/opsx:archive`

**一句话**：把完成的 change 归档——合并 delta spec 到主 specs，然后把整个文件夹搬到 `changes/archive/YYYY-MM-DD-<name>/`。

**语法**：`/opsx:archive [change-name]`

**做了什么**：
1. 检查 artifact 完整性
2. 检查 `tasks.md` 的勾选状态（有未完成会 warn，但不阻塞）
3. 若 delta spec 没 sync，问要不要现在 sync
4. 合并 delta 到 `openspec/specs/<domain>/spec.md`
5. 搬家：`openspec/changes/<name>/` → `openspec/changes/archive/YYYY-MM-DD-<name>/`

**和 CLI 的关系**：也可以在终端直接跑 `openspec archive [--yes] [--skip-specs] [--no-validate]`。

**何时不阻塞**：archive 不会因 task 未完成而失败，只会打 warning。

---

## Core 路径典型流程

```
/opsx:explore（可选，随时）
      ↓
/opsx:propose add-feature
      ↓
（自动生成 proposal / specs / design / tasks）
      ↓
/opsx:apply
      ↓
/opsx:archive
```

想要更细的控制（只生成一个 artifact、先 verify 再 archive、批量 archive）？见 [expanded-commands.md](expanded-commands.md)。
