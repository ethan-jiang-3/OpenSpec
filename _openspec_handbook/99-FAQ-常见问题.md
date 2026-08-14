# 99 · FAQ：常见问题

> 这一篇汇总了新手最常问的问题，按主题分类。

---

## 基础概念

### Q1: OpenSpec 到底是什么？
**A**: OpenSpec 是一个"先把 change 讲清楚，再去写代码"的协作层。它把一次改动拆成几份能讨论、能验证、能 archive 的文件（proposal/specs/design/tasks）。

### Q2: OpenSpec 和传统文档有什么区别？
**A**: 传统文档是"写完就不改"，OpenSpec 是"边做边改"。而且 OpenSpec 用 delta spec 表达增量变化，不是每次重写整份文档。

### Q3: 我必须用 AI 工具吗？
**A**: 不是必须的。OpenSpec 可以手动写，但用 AI 工具会更高效。目前已支持：Claude Code、Cline、Cursor、Codex、GitHub Copilot、Devin Desktop（原 Windsurf）、Kimi Code、Mistral Vibe、Junie、Lingma、ForgeCode、Pi、Kiro、IBM Bob、OpenCode、Trae、Oh My Pi、CodeArts Agent、Hermes Agent、ZCode、MiniMax Code、Rovo Dev CLI、Command Code 等；另有 vendor-neutral 的 `agents` 目标（`--tools agents`，写入 `.agents/skills/`）。完整列表以当前 `openspec init` 输出为准。

---

## 命令和工作流

### Q4: OpenSpec 和 OPSX 是两个东西吗？
**A**: 不是。OpenSpec 是整套机制；`opsx` 是 Claude 等 adapter 的一个 workflow command 命名空间，不是所有 agent 工具的通用语法。

- `openspec`：终端 CLI，例如 `openspec init`、`openspec status --json`、`openspec archive <name>`
- `/opsx:*`：Claude 等宿主里的用户入口，例如 `/opsx:propose`、`/opsx:apply`
- `$openspec-*`：Codex v1.8.0 的 skills-only 入口（装在 `.agents/skills/`），例如 `$openspec-propose-change`、`$openspec-apply-change`
- `.claude/commands/opsx/`：Claude Code 里保存这些入口文件的位置

所以不要把 `opsx` 理解成另一个产品。它只是让 agent 工具能触发 OpenSpec workflow 的入口层。

### Q5: 宿主 propose workflow 和 CLI 是什么关系？
**A**: 
- Claude 的 `/opsx:propose`（或 Codex 的 `$openspec-propose-change`）：宿主 workflow，agent 会按 workflow 自动跑多步 CLI
- CLI 里没有 `openspec propose` 这个等价命令
- 对应的底层步骤通常是 `openspec new change <name>`，再用 `openspec status --json` 和 `openspec instructions <artifact> --json` 生成 artifacts
- 机器协议层面（status/instructions 返回什么、agent 怎么跑多步），详见 [90 附录·给机器看的 agent 协议](90-附录-给机器看的-agent-协议.md)

### Q6: 我必须按 propose → apply → archive 的顺序吗？
**A**: 不是必须的。这是推荐顺序，但你可以：
- 在 apply 过程中回头改 proposal/design
- 跳过某些步骤（比如简单 change 可以不写 design）
- 这就是"Actions, not phases"的意思

v1.9.0 起 apply 模板要求：任务需要的工作超出 spec 描述时，停下来把新增范围摊开，不要默默缩小或推迟指定行为；勾完 checkbox 只表示指定行为已经落地。

### Q7: 什么时候该用 core profile，什么时候用 custom？
**A**:
- **core**（默认，v1.2.0 引入，v1.6.0 起 6 个命令）：propose/explore/apply/update/sync/archive，适合大多数场景。sync 在 v1.4.0 移入 core，update 在 v1.6.0 移入 core。
- **custom**：自选所有 12 个命令（可以额外启用 new/continue/ff/verify/bulk-archive/onboard 等），适合复杂项目
- **切换**：`openspec config profile`

---

## specs 和 changes

### Q8: specs/ 一开始是空的吗？
**A**: 是的，这是正常的。specs/ 是"长出来的"：
1. `openspec init` 后，specs/ 是空的
2. 第一个 change archive 后，specs/ 才有内容
3. 不需要手动写 specs/

### Q9: 我要手动维护 specs/ 吗？
**A**: 通常不需要直接手改。specs/ 由 archive 程序化更新；你只需要：
- 在 change 里写 delta spec
- archive 时把它 merge 回 specs/（除非明确 `--skip-specs` 或拒绝 spec update）

v1.8.0（v1.7.0 起）也允许 `skip_specs: true` 声明“本 change 没有 spec-level 行为变化”；它不能与 delta spec 文件共存。

### Q10: delta spec 和正式 spec 有什么区别？
**A**:
- **delta spec**：在 `changes/<name>/specs/`，描述"这次改了哪里"（ADDED/MODIFIED/REMOVED）
- **正式 spec**：在 `openspec/specs/`，描述"系统现在是什么样"
- archive 后，delta spec 会 merge 到正式 spec

### Q11: REMOVED 标记什么时候用？
**A**: 删除功能时用。要写清楚：
- **原因**：为什么删除
- **影响**：会影响谁
- **迁移**：用户怎么办

---

## artifacts

### Q12: 为什么要有这么多文件（proposal/specs/design/tasks）？
**A**: 每个文件解决一个问题：
- **proposal**：防止 scope 失控
- **specs**：防止行为不清晰
- **design**：防止技术选型随意
- **tasks**：防止实现无序

### Q13: 怎么判断该放 spec 还是 design？
**A**: 
- **spec**：用户能看到的行为变化（What）
- **design**：技术实现方式（How）和为什么这样选（Why）

例子：
- "点击按钮后下载 CSV" → spec
- "用同步方式还是异步 job" → design

### Q14: proposal 里的 Out of Scope 有什么用？
**A**: 防止 scope 失控。不明确写出"这次不做什么"，AI 和人都容易不断加功能，永远做不完。

---

## archive 和冲突

### Q15: archive 是自动的还是手动的？
**A**: archive 必须由你显式运行（CLI 或宿主 archive workflow）。在确认更新 specs 后，CLI 会：
- 读取 delta spec（也支持嵌套 capability path）
- 程序化 merge 到 specs/
- 把 change 移到 archive/

宿主 archive workflow 在 v1.8.0（v1.7.0 起）还会读取 `instructions archive` 的 context/guidance；已正确 early-sync 的完全一致 delta 会是 no-op，近似内容仍会报错。

### Q16: archive 时有冲突怎么办？
**A**: OpenSpec 不会在 main spec 写入 Git 式 conflict marker。发生真实冲突时，archive 会中止，main spec 与 change 都保持原样。正确做法是：

1. 读取报错和最新 main spec，确认另一个 change 已经怎样改变了 requirement。
2. 把当前 delta 按新基线重写；同 path 并行时，先完成前一个 archive，再做 rebaseline。
3. 运行 `openspec validate <change> --type change --strict`，再 archive。

完全相同、已 early-sync 的 delta 可以是 no-op；内容近似但不同仍必须人工重基线，不能期待自动合并。

v1.8.0 追加（archive 失败/被卡时的两种出路）：
1. **退役整个 capability**：如果这个 change 的 REMOVED 拿掉了某 capability 的**最后一个 requirement**，archive 原本会以 "must have at least one requirement" 中止；在 `.openspec.yaml` 声明 `retire_capabilities: true`（与 `schema:` 并存）后，archive 会删除该 capability 的整个 main spec。这适合"整个 capability 退役"，不能用来绕过真实行为变更。输出会列出被删 section，并给可粘贴的 `git checkout` 恢复命令；`--no-validate` 永不触发退役。
2. **非交互下被确认阻塞**：agent/CI 里 stdin closed 时，archive 会指出缺哪个 flag 并给**携带原 flags 的可重跑命令**（如 `openspec archive <name> --skip-specs --yes`）——直接粘贴重跑即可，不必凭空猜参数；不带 change 名时它现在会以 exit 1 明确请求 change 名，而不是静默吞错。v1.9.0 起非 TTY 不再往捕获日志里写 ANSI；无 change 名时要求先传入名字，不画菜单。

想在 CI 里抓“归档时 tasks 没勾完”的工作，用独立的 `openspec validate --archived`（不改普通 `validate` 行为，也不重验已应用的 delta）。

### Q17: 不 archive 会怎样？
**A**: specs/ 基线不会更新，下一个 change 就没有正确的基线。多人协作时会乱套。

---

## config 和 schema

### Q18: config.yaml 和 schema 有什么区别？
**A**:
- **config.yaml**：项目级背景和规则（技术栈、测试约定）
- `operations.apply/archive.guidance`：Apply/Archive 的项目级短稳定步骤（与 context 一起进入对应 operation）
- **schema**：change 的结构骨架（有哪些 artifact、依赖关系）

两者各自该装什么、边界在哪，详见 [04 高级·config-schema-与项目边界](04-高级-config-schema-与项目边界.md)。

如果“我明明写了 config，agent 却没遵守”，别先追加更多文字。按这个顺序排：生效 root → `config.yaml` 是否覆盖 `.yml` → 当前 change 的 `.openspec.yaml` schema → 目标 consumer → `openspec instructions ... --json` 的实际输出。`rules.<artifact>` 只给该 artifact；Apply/Archive 要用各自 `operations.*.guidance`；必须强制的约束要交给 schema、test、checker 或 CI。

### Q19: profile 和 schema 有什么区别？
**A**:
- **profile**：你能用哪些命令（core/custom）
- **schema**：每个 change 长什么样（默认是 spec-driven）

profile 和 schema 各自怎么选、怎么改，详见 [04 高级·config-schema-与项目边界](04-高级-config-schema-与项目边界.md)。

### Q20: `.openspec.yaml` 是什么？
**A**: change 目录里的配置文件，记录这次 change 用哪套 schema。大多数情况下自动生成，不需要手动改。

---

## 高级话题

### Q21: 怎么处理 change 之间的依赖？
**A**: 目前最佳实践：
- 先 archive 依赖的 change
- 再开始新的 change
- 未来可能会支持显式依赖声明

### Q22: 怎么回滚一个 change？
**A**: 
1. 找到 `changes/archive/<date>-<name>/`
2. 看 delta spec 里改了什么
3. 创建一个新 change，用 REMOVED/MODIFIED 反向操作
4. archive 新 change

（一个 change 的完整正向生命周期见 [11 实战·从真实 change 走完整条主线](11-实战-从一个真实-change-走完整条主线.md)；回滚本质是用 delta 反向操作。）

### Q23: 怎么处理 breaking change？
**A**: 
1. 在 proposal 里明确标注"Breaking Change"
2. 在 specs 里说明影响范围
3. 在 design 里说明迁移方案
4. 考虑分阶段发布（先废弃，再删除）

（proposal/specs/design 这些 artifact 具体怎么改，见 [12 实战·如何正确修改 artifacts](12-实战-如何正确修改-artifacts.md)。）

### Q24: specs/ 的目录结构怎么组织？
**A**: 推荐按**行为合同**组织，而不是按 models/services/controllers、页面或数据库表组织。大多数增长型项目可从“一层 domain + 一层 capability”开始：

```text
specs/
├── identity/login/spec.md
├── identity/session/spec.md
├── billing/invoices/spec.md
└── data-export/spec.md
```

一个 path 值得独立，通常因为它有自己的可观察行为、scenarios 和演进节奏；若两组 requirements 总是一起改变、一起验证，就别为了“层次感”硬拆。domain 只是导航 namespace，不是父 spec、继承关系或自动聚合。

**关键**：每个 capability 的身份是它在 `specs/` 下的完整相对 path。proposal、delta 和 archive 都依靠同一 path 寻址。不要随便搬改 path：requirement 改名还有 `RENAMED`，capability path 没有独立 rename 操作，改了会让 active delta 悬空。nested path 也不会自动 retrieval；spec 多时维护薄 catalog（path、Purpose、关键词、边界）并按需读取。详见 [09-高级-能力身份与specs漂移维护](09-高级-能力身份与specs漂移维护.md)。

### Q25: 一个功能涉及多个域怎么办？
**A**: 先别把所有 specs 全读一遍。先用 catalog 或 `openspec list --specs --json` 找候选，再在 proposal/design 留一张小 impact matrix：

```markdown
| capability path | action | why |
|---|---|---|
| identity/session | MODIFIED | token 生命周期改变 |
| billing/subscriptions | verify only | 依赖 token claim |
| data-export | excluded | 没有调用该 claim |
```

真正变化的 path 各写自己的 delta；仅验证的 path 不伪造 delta；明确排除的 path 留理由。身份、权限、兼容性或事件语义跨 domain 时必须扩大阅读范围，不能把全局影响伪装成局部 change。

切片、catalog 和 rebaseline 的完整判断见 [09](09-高级-能力身份与specs漂移维护.md)；真正修改 proposal/specs/design/tasks 时看 [12](12-实战-如何正确修改-artifacts.md)。

---

## 工具集成

### Q26: OpenSpec 支持哪些 AI 工具？
**A**: 支持工具列表会随 release 变化，应以当前 `openspec init` / release note 为准；以下是历史示例：
- **主要**：Claude Code、Cline、Cursor、Codex、Devin Desktop（原 Windsurf）、GitHub Copilot
- **v1.2.0 新增**：Pi（pi.dev）、Kiro（AWS）
- **v1.3.0 新增**：Junie（JetBrains）、Lingma、ForgeCode、IBM Bob
- **v1.4.0 新增**：Kimi CLI、Mistral Vibe
- **v1.6.0 新增**：Trae、Oh My Pi
- **v1.7.0 新增**：CodeArts Agent、Hermes Agent、ZCode
- **v1.8.0 新增**：MiniMax Code（全局 skills-only）、Atlassian Rovo Dev CLI、GitHub Copilot 一等支持（本地 skill + opt-in cloud agent）、vendor-neutral `agents` 目标（`.agents/skills/`，与 Codex 共享根）
- **v1.9.0 新增**：Command Code（`.commandcode/skills/` + `/opsx-*` slash commands）
- 也可以直接用 CLI（不用任何 AI 工具）

### Q27: 怎么安装 OpenSpec 到我的 AI 工具？
**A**: 
1. 在项目里运行 `openspec init`（v1.2.0+ 会自动检测已安装的工具并预选）
2. 也可以手动指定：`openspec init --tools claude,cursor`
3. 运行 `openspec update` 确保 skills/commands 是最新的
4. 重启 AI 工具，使用该宿主安装的入口：Claude 可为 `/opsx:propose`，Codex 为 `$openspec-propose-change` 等 skills

### Q28: 为什么有 `.claude/` 和 `openspec/` 两个目录？
**A**: 
- `openspec/`：项目事实层（specs/changes/config）
- `.claude/`（或其他工具目录）：工具入口层（skills/commands）
- 这样设计是为了让 OpenSpec 不被绑死在某个工具上

---

## 疑难杂症

### Q29: 我的 change 一直卡在某个 artifact 怎么办？
**A**: 
- 检查 artifact 的依赖关系（比如 tasks 依赖 specs 和 design）
- 先完成依赖的 artifact
- 或者使用该宿主的 ff workflow（Claude 示例 `/opsx:ff`）生成剩余 ready artifact；它不能绕过 schema 的真实依赖

### Q30: AI 生成的 artifacts 质量不好怎么办？
**A**: 
- 检查 config.yaml 是否写了项目背景和规则
- 手动修改生成的 artifacts（随时可以改）
- 给 AI 更具体的指令

### Q31: 我可以不用某个 artifact 吗？
**A**: 可以。比如：
- 简单 change 可以不写 design
- 单人项目可以简化 proposal
- 有可观察行为变化时，specs delta 和 tasks 通常都需要
- 确认只是重构、换实现、工具或文档工作而没有 spec-level 行为变化时，可在 `.openspec.yaml` 用 `skip_specs: true`；它不能与 delta specs 共存

---

## Store 跨仓库协同

### Q32: store 是什么？和 repo 里的 OpenSpec 有什么关系？
**A**: Store 是可选的跨仓库 OpenSpec 引用。它不替代 repo 级 OpenSpec，也不协调跨 repo change；它只让当前项目声明已 checkout 的其他 root，并给人或 agent 一个按需读取入口。单仓库项目不需要 store。所有 change 仍在具体 repo 下，使用 `spec-driven` schema。

### Q33: 我什么时候需要 store？
**A**: 只有当前 change 需要读取另一个已 checkout repo 的正式 specs 时才考虑 store。不要因为本地 specs 多、或仓库多就启用它；本地 context scaling 先走 capability taxonomy、catalog 和按需读取。

### Q34: store 会修改我 referenced 的仓库吗？
**A**: 不会。`references:` 只是名称声明；不带 `--code-workspace` 的 `openspec context` 会显示 referenced store 的 working set、可用本地路径和按需 `show --store` 入口，不内联内容，也不写入 referenced repo。

### Q35: store、context、workset 有什么区别？
**A**:
- **store**：全局注册的仓库 checkout（`openspec store register`）
- **reference**：项目声明的 store 依赖（`config.yaml` 的 `references:`）
- **context**：working set 查询（`openspec context`）——root + referenced stores 的路径与按需读取入口
- **workset**：个人本地的多目录打开视图（`openspec workset create/open/list/remove`），不从 `references:` 推导，也不共享

### Q36: 怎么开始使用 store？
**A**:
1. `openspec store register /path/to/other-repo --id other-repo`（注册一个仓库）
2. 在 `openspec/config.yaml` 加 `references: [other-repo]`
3. `openspec context`（查看 working set）
4. 正常创建 change：`openspec new change <name>`（change 仍在当前 repo 下）
