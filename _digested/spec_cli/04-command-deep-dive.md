# 命令深挖

这一篇把 CLI 命令按“命令族”来消化，不重复帮助文本，而强调边界、本质和相互关系。

## 一、引导与安装类

### `init`

- 角色：工作流投递器。
- 核心对象：AI 工具目录、global config、skills/commands 模板。
- 改变项目状态：会。
- 改变工具状态：会。
- 主要风险：误以为只是在本地建目录，实际上它会生成工具侧产物并可能清理旧产物。

### `update`

- 角色：工作流同步器。
- 核心对象：已配置工具、OpenSpec 版本、profile/delivery 差异。
- 改变项目业务内容：通常不会。
- 改变工具工作流外壳：会。
- 主要风险：用户以为不会删除内容，但它会清理被取消选中的 workflow 产物。

## 二、发现与浏览类

### `list`

- 角色：项目索引视图。
- 核心对象：change/spec 列表。
- 输出语义：概览。
- 是否适合做 workflow 决策：有限。
- v1.9.0：项目外不再 silent pass；仅遗留 `openspec/project.md` 项目保留 cwd fallback。
- 主要边界：知道“有什么”，但不知道“下一步怎么走”。

### `view`

- 角色：交互式仪表盘；v1.7.0 按 resolved root 读取，并支持 `--store`，不是硬编码当前 cwd 的 specs。
- 核心对象：聚合浏览。
- 更偏人类，不偏自动化。

### `show`

- 角色：对象查看器。
- 核心对象：单个 change 或 spec。
- 输出语义：对象内容与解析结果。
- 主要边界：展示已有内容，不做工作流编排。

## 三、校验与治理类

### `validate`

- 角色：结构守门器。
- 核心对象：change delta specs 与正式 specs；`--archived` 则是 archive 目录的 tasks 完成度。
- 输出语义：是否合法、有哪些 issues、下一步修复建议。
- 典型边界：它不管代码是否编译，不管测试是否通过，它主要管 OpenSpec 文档结构。`--archived` 不重验已应用的 delta。bulk 标志（`--all/--changes/--specs`）在项目外非零退出。

### `archive`

- 角色：生命周期收束器。
- 核心对象：change、delta specs、正式 specs、archive 目录。
- 输出语义：变更被吸收到 specs，并从 active change 迁移到 archive。
- 系统重要性：极高，因为它会改变主 specs。
- 归档前若 main specs 已被正确 early-sync，完全一致的 ADDED/MODIFIED/REMOVED/RENAMED 会是幂等 no-op；大小写或空白等近似命中仍会报错，不能把 no-op 误解成放宽校验。

## 四、workflow runtime 类

### `new change`

- 角色：实例化器。
- 边界：创建 change 语境，不生成具体 artifact 内容。

### `status`

- 角色：状态投影器。
- 边界：告诉你“到哪一步”，不告诉你具体该写什么内容。

### `instructions <artifact>`

- 角色：artifact 指令编译器。
- 边界：编译说明，不直接写输出文件。

### `instructions apply`

- 角色：apply 工作单编译器。
- 边界：决定能否实施并给出实施上下文，但不直接执行代码修改。

### `instructions archive`

- 角色：archive operation input 编译器。
- 核心对象：change、project `context`、`operations.archive.guidance`。
- 边界：只读；不合并 specs、不移动 archive 目录。

### `templates`

- 角色：模板解析可视化接口。
- 边界：用于发现和调试，不参与业务内容推进。

### `schemas`

- 角色：schema 发现接口。
- 边界：暴露流程定义空间，不负责具体 change 生命周期。v1.9.0 起走 canonical root selection，接受 `--store <id>`，拒绝 `--store-path`。

## 五、配置与定制类

### `config`

- 角色：全局工作流配置器。
- 核心对象：profile、delivery、workflow selection。
- 影响：下次 `init` / `update` 如何生成工具侧工作流。

### `schema`

- 角色：workflow 定义管理器。
- 核心对象：schema.yaml、template 文件、来源优先级、shadowing。
- 影响：workflow 运行时如何解释 artifact 与 apply phase。

## 六、store / context / workset / doctor 命令族


### `store register`

- 角色：全局注册一个仓库 checkout。
- 核心对象：store id、backend（git type + local_path + remote + branch）。
- 产出：在 `~/.openspec/stores/registry.yaml` 中写入条目，在 checkout 下创建 `.openspec-store/store.yaml`。
- 边界：只记录已有目录，不 clone、不 init。

### `store list` / `unregister` / `info`

- 角色：store 发现与注销。
- 边界：纯 registry 操作，不改 store checkout 内容。

### `context`

- 角色：working set 查看器。
- 核心对象：root + referenced stores 的 spec 索引。
- 产出：human listing、JSON brief、或 `--code-workspace` 文件。
- 边界：纯查询，不 clone、不 sync、不写任何 repo。

### `workset save` / `open` / `list`

- 角色：个人本地多仓库视图管理。
- 核心对象：workset（name + members + optional tool）。
- 产出：`~/.openspec/worksets/worksets.yaml` + `.code-workspace` 文件。
- 边界：纯本地，不共享，不提交。

### `doctor`

- 角色：store reference 健康检查。
- 核心对象：项目 `references:` 中的 store id 到实际 checkout 的对应。
- 边界：诊断 report，不自动修复。

## 七、旧命令与兼容层

### `change ...`

- 角色：旧 noun-based 入口。
- 状态：已废弃，保留兼容。
- 作用：减少老用户迁移成本。

为什么重要：

- 它说明 CLI 正在演进，从”名词对象入口”转向”动词优先入口”。
- 这也意味着 OpenSpec 更强调任务流而不是对象菜单。

## 八、命令之间的边界关系

### `list` vs `status`

- `list` 看总览。
- `status` 看单个 change 的流程状态。

### `show` vs `instructions`

- `show` 看已有内容。
- `instructions` 生成下一步执行包。

### `validate` vs `archive`

- `validate` 负责发现结构问题。
- `archive` 负责收尾并更新 specs，但内部也会再跑验证守门。

### `config` / `schema` vs `status` / `instructions`

- 前者定义工作流系统的配置和模型。
- 后者运行这些模型并暴露当前实例状态。

## 九、从”命令百科”到”系统理解”

如果只逐条看命令，你会得到很多零散功能。如果按角色来看，会更清楚：

- `init` / `update` 负责装配系统。
- `config` / `schema` 负责定义系统。
- `list` / `show` / `view` / `doctor` 负责观察系统。
- `validate` / `archive` 负责治理系统。
- `new change` / `status` / `instructions` 负责驱动系统。
- `store` / `context` / `workset` 负责跨仓库上下文引用系统。

这才是 OpenSpec CLI 的整体结构。
