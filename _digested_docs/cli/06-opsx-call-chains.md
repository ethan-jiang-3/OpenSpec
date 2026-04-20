# OPSX 调用链

这一篇专门从工作流模板的角度，反向看 `openspec` CLI 是怎样被真正使用的。

核心结论：

OPSX 不是在“直接理解整个项目”，而是在不断调用 `openspec` CLI，把本地项目状态转成结构化上下文，再继续推进工作流。

## 一、总链路

最常见的链路大体是：

1. 用户触发 `/opsx:*`。
2. 对应 skill/command 模板开始执行。
3. 模板调用 `openspec` CLI 读取状态或说明。
4. CLI 从项目目录和 schema 中恢复运行时语义。
5. CLI 返回结构化信息。
6. 模板/agent 根据结果决定：生成文档、进入 apply、归档，或提示阻塞。

也就是说，OPSX 模板像 orchestration layer，CLI 像本地 workflow kernel。

## 二、`/opsx:propose`

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

## 三、`/opsx:new`

### 目标

快速创建一个 change 脚手架并进入后续工作流。

### 典型调用链

1. 从用户请求中确定 change 名称。
2. 调用 `openspec new change <name>`。
3. 视模板设计，可能立即调用 `status` 或某个 artifact 的 `instructions`。

### 它和 `/opsx:propose` 的区别

- `/opsx:new` 更像创建空上下文。
- `/opsx:propose` 更像从变更请求直接进入 proposal 驱动流程。

## 四、`/opsx:continue`

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

## 五、`/opsx:apply`

### 目标

在文档和任务条件满足后，进入代码实施阶段。

### 典型调用链

1. 调用 `openspec instructions apply --change <name> --json`。
2. 读取返回的 `state`。
3. 如果 `blocked`：
   - 告诉用户缺什么 artifact 或 task 文件。
   - 引导回 continue/change 文档阶段。
4. 如果 `ready`：
   - 读取 `contextFiles` 指向的 proposal/spec/design/tasks 等文档。
   - 读取 tasks 列表和完成进度。
   - 开始代码修改。
5. 修改代码时持续更新任务状态。
6. 当全部任务完成，`instructions apply` 进入 `all_done`。

### CLI 在其中扮演的角色

- 它不是执行代码修改者。
- 它是 apply 阶段的准入检查器和工作单编译器。

## 六、`/opsx:archive`

### 目标

完成 change 收尾，把 delta specs 纳入正式 specs 并归档。

### 典型调用链

1. 检查当前 change 是否准备归档。
2. 调用 `openspec archive <name>`。
3. CLI 自己完成验证、spec 重建、写入和归档移动。
4. 模板向用户报告归档完成或失败原因。

### 这里的边界

和 `continue` / `apply` 不同，`archive` 本身就已经是强执行型命令，不只是“出说明”。

也就是说：

- `continue` 常常是 CLI 出包，AI 执行。
- `archive` 则是 CLI 直接执行核心收尾动作。

## 七、`/opsx:verify`

### 目标

对 change 做验证性检查。

### 可能调用链

- 读取 change 或 spec 内容。
- 调用 `openspec validate`。
- 结合测试、人工规则或工具链结果给出总结。

### CLI 在其中的意义

- 提供结构合法性这一层的确定性校验。
- 让 verify 不完全依赖 AI 自由判断。

## 八、`/opsx:explore`

### 目标

在正式变更前探索问题、方案和上下文。

### 对 CLI 的依赖程度

- 相比 continue/apply，explore 对 workflow runtime API 的依赖可能更弱。
- 但它仍可能使用 `list`、`show`、`schemas` 等命令辅助理解项目与可用模型。

## 九、真正重要的系统分工

从这些调用链可以看出，整个系统分工大概是：

- 项目目录：事实来源。
- schema/template/config：工作流定义来源。
- `openspec` CLI：确定性解释器与编译器。
- OPSX 模板：行动编排器。
- AI：内容生成与代码修改执行者。

## 十、为什么这说明 CLI 是核心而不是附件

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

