# 宿主工作流调用链（以 Claude 为例）

> **入口边界。** 本篇用**技能名**描述入口，例如 `openspec-propose`。调用写法随工具而变：Claude Code 等按 `/openspec-propose`，Codex 按 `$openspec-propose`，Zed 用 `/openspec-*` 或 `@openspec-*`；也可以直接用自然语言让 agent 按技能描述自己选。**1.x 的 `/opsx:*` command 文件已在 v2.0.0 移除**，下文中出现的 `/opsx:` 只用于历史对照。下文的“模板/agent”层可跨宿主复用。

这一篇专门从工作流模板的角度，反向看 `openspec` CLI 是怎样被真正使用的。

核心结论：

OPSX 不是在“直接理解整个项目”，而是在不断调用 `openspec` CLI，把本地项目状态转成结构化上下文，再继续推进工作流。

## 一、总链路

最常见的链路大体是：

1. 用户触发一个技能（1.x 是 `/opsx:*`，现为 `openspec-*`）。
2. 对应工作流 skill 模板开始执行（1.x 为 command 或 skill）。
3. 模板调用 `openspec` CLI 读取状态或说明。
4. CLI 从项目目录和 schema 中恢复运行时语义。
5. CLI 返回结构化信息。
6. 模板/agent 根据结果决定：生成文档、进入 apply、archive，或提示阻塞。

也就是说，OPSX 模板像 orchestration layer，CLI 像本地 workflow kernel。

## 二、`openspec-propose`

### 目标

把一个用户提出的意图，落成一个新的 change，并开始生成 proposal 等初始 artifact。

### 典型调用链

1. 收到用户变更意图。
2. 确认是否已有合适 change；没有则创建新 change。
3. 调用 `openspec new change <name>` 建立 change 上下文。
4. 调用 `openspec status --change <name> --json` 读取当前 artifact 状态。
5. 调用 `openspec instructions proposal --change <name> --json` 获取 proposal 生成包。
6. AI 根据 instruction/template/dependencies/context 生成 proposal。
7. 写入 `proposal.md`。
8. 再次用 `status` 判断下一阶段是否就绪。

### CLI 在其中扮演的角色

- `new change` 负责创建运行实例。
- `status` 负责判断 proposal 是否属于当前应该推进的步骤。
- `instructions proposal` 负责把 proposal 所需上下文编译出来。

## 三、`openspec-new-change`

### 目标

快速创建一个 change 脚手架并进入后续工作流。

### 典型调用链

1. 从用户请求中确定 change 名称。
2. 调用 `openspec new change <name>`。
3. 当前内置模板会立刻调用 `openspec status --change <name>`。
4. 根据状态找到第一个 `ready` artifact。
5. 调用 `openspec instructions <first-artifact> --change <name>`。
6. 到这里先停住，把第一个 artifact 的模板和说明展示给用户，等待继续。

### 它和 `openspec-propose` 的区别

- `openspec-new-change` 更像创建空上下文。
- `openspec-propose` 更像从变更请求直接进入 proposal 驱动流程。

## 四、`openspec-continue-change`

### 目标

继续当前 change，创建下一个合理 artifact。

### 典型调用链

1. 调用 `openspec status --change <name> --json`。
2. 根据状态找出 `ready` 的 artifact，或识别 `blocked` 原因。
3. 选择下一个要生成的 artifact。
4. 调用 `openspec instructions <artifact> --change <name> --json`。
5. AI 读取 dependencies 中指向的已有文件，理解上下文。
6. AI 按 template/instruction/rules 生成新的 artifact。
7. 写入相应输出路径。
8. 再次检查 `status`。

### 为什么这条链路最能体现 CLI 的价值

因为这里不是简单的 prompt 接龙，而是：

- `status` 决定“做什么”。
- `instructions` 决定“怎么做”。

这两者合在一起，才构成 continue 的运行闭环。

## 五、`openspec-apply-change`

### 目标

在文档和任务条件满足后，进入代码实施阶段。

### 典型调用链

1. 当前内置模板通常先调用 `openspec status --change <name> --json`，确认 schema 和当前 artifact 背景。
2. 再调用 `openspec instructions apply --change <name> --json`。
3. 读取返回的 `state`。
4. 如果 `blocked`：
   - 告诉用户缺什么 artifact 或 task 文件。
   - 引导回 continue/change 文档阶段。
5. 如果 `ready`：
   - 读取 `contextFiles` 指向的 proposal/spec/design/tasks 等文档。
   - 读取 tasks 列表和完成进度。
   - 开始代码修改。
6. 修改代码时持续更新任务状态。
7. 当全部任务完成，`instructions apply` 进入 `all_done`。

### CLI 在其中扮演的角色

- 它不是执行代码修改者。
- 它是 apply 阶段的准入检查器和工作单编译器。

## 六、`openspec-archive-change`

### 目标

在 agent 会话中完成 change 收尾、把 delta specs 合并进主 specs 并将 change 移入 archive。

### 真实调用链（`src/core/templates/workflows/archive-change.ts`）

> **关键勘误：`openspec-archive-change` 技能全程绝不调用 `openspec archive <name>`！** 它通过一系列只读 CLI 查询配合 agent 智能合并与 shell `mv` 完成归档：

1. **选择 change 并加载归档指引**：若有歧义先调 `openspec list --json` 让用户选择；随后运行 `openspec instructions archive --change "<name>" --json`（advisory 获取项目 `context` 与 `operationGuidance`，失败不阻断后续步骤）。
2. **检查 artifact 完成度**：调用 `openspec status --change "<name>" --json`，读取 `schemaName`、`planningHome`、`changeRoot`、`artifactPaths` 与 `artifacts`；若有既非 `done` 也非 `skipped` 的 artifact，显示警告并请用户确认是否继续。
3. **检查任务完成度**：调用 `openspec list --json` 精确匹配该 change 的 `totalTasks` 与 `completedTasks`；若有未勾完的任务，警告并请用户确认。
4. **预检归档目标并评估 delta 同步状态**：计算 `<target-name>`（已有 `YYYY-MM-DD-` 前缀保持原样，否则加当日日期前缀），**在写入任何主 spec 之前先检查 `<planningHome.changesDir>/archive/<target-name>` 是否已存在**（v2.1.1 `#2277`：若已存在立即停止，保持主 specs 和 `changeRoot` 原封不动）；再对比 `artifactPaths.specs.existingOutputPaths` 与 `<planningHome.root>/openspec/specs/<capability-path>/spec.md` 评估同步状态并询问用户。
5. **（可选）执行 inline spec 同步与校验**：用户选择同步后，再次确认归档目标不存在 → 调用一次 `openspec instructions specs --change "<name>" --json` 获取 `specs` 规则快照 → inline 运行 `openspec-sync-specs` 技能，或（若未装该技能）由 agent 自行做智能 delta 合并（此时须保留 `retire_capabilities: true` 退役护栏，并在合并后跑 `openspec validate --specs`，`#1977`）→ 对全部有 delta 的 capability 逐一复核主 spec 结构与同步结果（不一致则停止、不移动 `changeRoot`）。
6. **执行目录移动**：再次确认目标路径不存在后，直接用 shell 执行：
   ```bash
   mkdir -p "<planningHome.changesDir>/archive"
   mv "<changeRoot>" "<planningHome.changesDir>/archive/<target-name>"
   ```

### 这里的边界：agent 归档技能 vs CLI `openspec archive`

务必把两条归档路径严格区分开：

- **`openspec-archive-change`（agent 技能）**：靠 CLI 只读查询（`instructions archive` / `status` / `list` / `instructions specs`）+ agent 智能合并主 specs + shell `mkdir -p` / `mv` 完成，不调 `openspec archive`。
- **`openspec archive <name>`（确定性 CLI 命令，`src/core/archive.ts`）**：面向人类终端、CI/脚本，以及 **`openspec-onboard` Phase 10**（12 个工作流模板中唯一调用 `openspec archive "<name>" --yes` 的地方），由 CLI 自己在进程内完成 parser 级 requirement-block 合并、结构校验、失败快照回滚与目录移动。

## 七、`openspec-verify-change`

### 目标

对 change 做验证性检查。

### 可能调用链

- 如果没有明确 change，先用 `openspec list --json` 让用户选。
- 调用 `openspec status --change <name> --json` 理解 schema 与已有 artifacts。
- 调用 `openspec instructions apply --change <name> --json` 拿到 `contextFiles`，再读取 proposal/spec/design/tasks。
- 结合代码搜索、测试覆盖和实现检查生成 verification report。

补充边界：

- `openspec validate` 当然仍然是相关 CLI 能力，但它不是当前内置 `openspec-verify-change` 模板里的主调用链。

### CLI 在其中的意义

- 提供结构合法性这一层的确定性校验。
- 让 verify 不完全依赖 AI 自由判断。

## 八、`openspec-explore`

### 目标

在正式变更前探索问题、方案和上下文。

### 对 CLI 的依赖程度

- 相比 continue/apply，explore 对 workflow runtime API 的依赖可能更弱。
- 当前内置 explore 模板的明确起点是 `openspec list --json`，先判断项目里有没有 active change；v1.13.0 起还会列 spec inventory（`openspec list --specs --json` + store-aware `openspec show "<spec-id>" --type spec`），不再把 in-flight changes 当 specs。
- 它更像“带 OpenSpec 上下文感知的探索姿态”，而不是强依赖 `status`/`instructions` 的固定流程。

## 九、真正重要的系统分工

从这些调用链可以看出，整个系统分工大概是：

- 项目目录：事实来源。
- schema/template/config：工作流定义来源。
- `openspec` CLI：确定性解释器与编译器。
- OPSX 模板：行动编排器。
- AI：内容生成与代码修改执行者。

## 十、这正说明 CLI 是核心而不是附件

如果没有 CLI，这些模板就必须自己做很多脆弱工作：

- 扫目录猜当前状态。
- 手工推导依赖顺序。
- 猜模板路径。
- 猜 apply 能否开始。
- 猜 rules 和 context 从哪里来。

这些都很容易不稳定。

而有了 CLI：

- 状态判断集中化。
- schema 解析集中化。
- 模板定位集中化。
- apply gate 集中化。

这就是 OpenSpec 把 CLI 放在系统中心的真正原因。
