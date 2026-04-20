# 99 · FAQ：常见问题

> 这一篇汇总了新手最常问的问题，按主题分类。

---

## 基础概念

### Q1: OpenSpec 到底是什么？
**A**: OpenSpec 是一个"先把变更讲清楚，再去写代码"的协作层。它把一次改动拆成几份能讨论、能验证、能归档的文件（proposal/specs/design/tasks）。

### Q2: OpenSpec 和传统文档有什么区别？
**A**: 传统文档是"写完就不改"，OpenSpec 是"边做边改"。而且 OpenSpec 用 delta spec 表达增量变化，不是每次重写整份文档。

### Q3: 我必须用 AI 工具吗？
**A**: 不是必须的。OpenSpec 可以手动写，但用 AI 工具（Cline/Claude）会更高效。

---

## 命令和工作流

### Q4: `/opsx:propose` 和 `openspec propose` 有什么区别？
**A**: 
- `/opsx:propose`：在 Cline/Claude 等宿主工具里用（冒号）
- `openspec propose`：在终端 CLI 里用（空格）
- 功能是一样的，只是调用方式不同

### Q5: 我必须按 propose → apply → archive 的顺序吗？
**A**: 不是必须的。这是推荐顺序，但你可以：
- 在 apply 过程中回头改 proposal/design
- 跳过某些步骤（比如简单 change 可以不写 design）
- 这就是"Actions, not phases"的意思

### Q6: 什么时候该用 core profile，什么时候用 expanded？
**A**:
- **core**（默认）：只有 4 个命令，适合大多数场景
- **expanded**：更多命令（explore/verify/sync等），适合复杂项目
- **切换**：`openspec config profile`

---

## specs 和 changes

### Q7: specs/ 一开始是空的吗？
**A**: 是的，这是正常的。specs/ 是"长出来的"：
1. `openspec init` 后，specs/ 是空的
2. 第一个 change archive 后，specs/ 才有内容
3. 不需要手动写 specs/

### Q8: 我要手动维护 specs/ 吗？
**A**: 不需要。specs/ 是 archive 自动更新的。你只需要：
- 在 change 里写 delta spec
- archive 时自动 merge 回 specs/

### Q9: delta spec 和正式 spec 有什么区别？
**A**:
- **delta spec**：在 `changes/<name>/specs/`，描述"这次改了哪里"（ADDED/MODIFIED/REMOVED）
- **正式 spec**：在 `openspec/specs/`，描述"系统现在是什么样"
- archive 后，delta spec 会 merge 到正式 spec

### Q10: REMOVED 标记什么时候用？
**A**: 删除功能时用。要写清楚：
- **原因**：为什么删除
- **影响**：会影响谁
- **迁移**：用户怎么办

---

## artifacts

### Q11: 为什么要有这么多文件（proposal/specs/design/tasks）？
**A**: 每个文件解决一个问题：
- **proposal**：防止 scope 失控
- **specs**：防止行为不清晰
- **design**：防止技术选型随意
- **tasks**：防止实现无序

### Q12: 怎么判断该放 spec 还是 design？
**A**: 
- **spec**：用户能看到的行为变化（What）
- **design**：技术实现方式（How）和为什么这样选（Why）

例子：
- "点击按钮后下载 CSV" → spec
- "用同步方式还是异步 job" → design

### Q13: proposal 里的 Out of Scope 有什么用？
**A**: 防止 scope 失控。不明确写出"这次不做什么"，AI 和人都容易不断加功能，永远做不完。

---

## archive 和冲突

### Q14: archive 是自动的还是手动的？
**A**: 自动的。运行 `/opsx:archive` 后：
- CLI 自动读取 delta spec
- 自动 merge 到 specs/
- 自动把 change 移到 archive/

### Q15: archive 时有冲突怎么办？
**A**: 
1. CLI 会提示冲突位置
2. 手动打开冲突文件
3. 找到冲突标记（类似 git）
4. 决定保留哪个版本或合并
5. 重新运行 archive

**最佳实践**：尽量让不同 change 修改不同的 spec 文件。

### Q16: 不 archive 会怎样？
**A**: specs/ 基线不会更新，下一个 change 就没有正确的基线。多人协作时会乱套。

---

## config 和 schema

### Q17: config.yaml 和 schema 有什么区别？
**A**:
- **config.yaml**：项目级背景和规则（技术栈、测试约定）
- **schema**：change 的结构骨架（有哪些 artifact、依赖关系）

### Q18: profile 和 schema 有什么区别？
**A**:
- **profile**：你能用哪些命令（core/expanded）
- **schema**：每个 change 长什么样（spec-driven/task-driven）

### Q19: `.openspec.yaml` 是什么？
**A**: change 目录里的配置文件，记录这次 change 用哪套 schema。大多数情况下自动生成，不需要手动改。

---

## 高级话题

### Q20: 怎么处理 change 之间的依赖？
**A**: 目前最佳实践：
- 先 archive 依赖的 change
- 再开始新的 change
- 未来可能会支持显式依赖声明

### Q21: 怎么回滚一个 change？
**A**: 
1. 找到 `changes/archive/<date>-<name>/`
2. 看 delta spec 里改了什么
3. 创建一个新 change，用 REMOVED/MODIFIED 反向操作
4. archive 新 change

### Q22: 怎么处理 breaking change？
**A**: 
1. 在 proposal 里明确标注"Breaking Change"
2. 在 specs 里说明影响范围
3. 在 design 里说明迁移方案
4. 考虑分阶段发布（先废弃，再删除）

### Q23: specs/ 的目录结构怎么组织？
**A**: 推荐按能力域组织：
```
specs/
├── auth/spec.md
├── requests/spec.md
├── approvals/spec.md
└── notifications/spec.md
```

不推荐按技术层（models/services/controllers）。

### Q24: 一个功能涉及多个域怎么办？
**A**: 
- 在多个域的 spec 文件里都写 delta spec
- 每个域写自己负责的部分
- 在 design 里说明跨域协作方式

---

## 工具集成

### Q25: OpenSpec 只能用 Cline 吗？
**A**: 不是。OpenSpec 支持：
- Cline
- Claude Code
- Cursor（通过插件）
- 或者直接用 CLI（不用 AI 工具）

### Q26: 怎么在 Cline 里安装 OpenSpec？
**A**: 
1. 在项目里运行 `openspec init`
2. 运行 `openspec update` 安装 skills
3. 重启 Cline
4. 就可以用 `/opsx:propose` 等命令了

### Q27: 为什么有 `.cline/` 和 `openspec/` 两个目录？
**A**: 
- `openspec/`：项目事实层（specs/changes/config）
- `.cline/`：工具入口层（skills/workflows）
- 这样设计是为了让 OpenSpec 不被绑死在某个工具上

---

## 疑难杂症

### Q28: 我的 change 一直卡在某个 artifact 怎么办？
**A**: 
- 检查 artifact 的依赖关系（比如 tasks 依赖 specs 和 design）
- 先完成依赖的 artifact
- 或者用 `/opsx:ff` 强制跳到下一个

### Q29: AI 生成的 artifacts 质量不好怎么办？
**A**: 
- 检查 config.yaml 是否写了项目背景和规则
- 手动修改生成的 artifacts（随时可以改）
- 给 AI 更具体的指令

### Q30: 我可以不用某个 artifact 吗？
**A**: 可以。比如：
- 简单 change 可以不写 design
- 单人项目可以简化 proposal
- 但 specs 和 tasks 通常都需要

---

## 下一步

如果这个 FAQ 没有回答你的问题：
1. 回看对应的主题文档（01-09）
2. 在 GitHub 提 issue
3. 查看 OpenSpec 官方文档

---

**提示**：这个 FAQ 会持续更新。如果你有新的常见问题，欢迎反馈。
