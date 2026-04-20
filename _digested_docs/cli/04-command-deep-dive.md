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
- 主要边界：知道“有什么”，但不知道“下一步怎么走”。

### `view`

- 角色：交互式仪表盘。
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
- 核心对象：change delta specs 与正式 specs。
- 输出语义：是否合法、有哪些 issues、下一步修复建议。
- 典型边界：它不管代码是否编译，不管测试是否通过，它主要管 OpenSpec 文档结构。

### `archive`

- 角色：生命周期收束器。
- 核心对象：change、delta specs、正式 specs、archive 目录。
- 输出语义：变更被吸收到 specs，并从 active change 迁移到 archive。
- 系统重要性：极高，因为它会改变主 specs。

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

### `templates`

- 角色：模板解析可视化接口。
- 边界：用于发现和调试，不参与业务内容推进。

### `schemas`

- 角色：schema 发现接口。
- 边界：暴露流程定义空间，不负责具体 change 生命周期。

## 五、配置与定制类

### `config`

- 角色：全局工作流配置器。
- 核心对象：profile、delivery、workflow selection。
- 影响：下次 `init` / `update` 如何生成工具侧工作流。

### `schema`

- 角色：workflow 定义管理器。
- 核心对象：schema.yaml、template 文件、来源优先级、shadowing。
- 影响：workflow 运行时如何解释 artifact 与 apply phase。

## 六、旧命令与兼容层

### `change ...`

- 角色：旧 noun-based 入口。
- 状态：已废弃，保留兼容。
- 作用：减少老用户迁移成本。

为什么重要：

- 它说明 CLI 在演进中，正在从“名词对象入口”转向“动词优先入口”。
- 这也意味着 OpenSpec 更强调任务流而不是对象菜单。

## 七、命令之间的边界关系

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

## 八、从“命令百科”到“系统理解”

如果只逐条看命令，你会得到很多零散功能。如果按角色来看，会更清楚：

- `init` / `update` 负责装配系统。
- `config` / `schema` 负责定义系统。
- `list` / `show` / `view` 负责观察系统。
- `validate` / `archive` 负责治理系统。
- `new change` / `status` / `instructions` 负责驱动系统。

这才是 OpenSpec CLI 的整体结构。

