# 命令输入输出矩阵

这一页适合做快速查表。前面的几篇讲思路，这一篇讲压缩后的全景视图。

## 说明

列的含义：

- 主要受众：更偏人类还是更偏机器。
- 输入来源：命令主要依赖哪些事实源。
- 直接输出：命令最直接产出的内容。
- 间接影响：命令产出会进一步影响谁。
- 是否改状态：是否会改变项目或工具状态。

## 总表

| 命令 | 主要受众 | 输入来源 | 直接输出 | 间接影响 | 是否改状态 |
| --- | --- | --- | --- | --- | --- |
| `init` | 人类 + 工具集成 | 项目路径、global config、工具目录 | `openspec/` 基础设施、skills/commands、安装报告 | 决定外部工具能否使用 OpenSpec 工作流 | 是 |
| `update` | 人类 + 工具集成 | 当前版本、配置、已配置工具 | 更新后的 skills/commands、同步报告 | 决定工具侧工作流是否与配置一致 | 是 |
| `list` | 人类 + 机器 | changes/specs 目录、task progress、mtime | 列表或 JSON 索引 | 帮助选择目标 change/spec | 否 |
| `view` | 人类 | 项目中的 changes/specs | 交互式 dashboard | 改善浏览体验 | 否 |
| `show` | 人类 + 机器 | 指定 change/spec 及其内容 | 对象展示或 JSON | 帮助人工审阅和调试解析结果 | 否 |
| `validate` | 人类 + 机器 | change delta specs、正式 specs | 合法性报告、退出码 | 决定是否需要修复、是否适合 archive | 否 |
| `archive` | 人类 + OPSX | change 内容、主 specs、验证结果 | 更新后的 specs、归档目录、报告 | 结束 change 生命周期 | 是 |
| `config` | 人类 | global config、workflow 选择 | 配置变更与摘要 | 影响后续 `init/update` 投递结果 | 是 |
| `schema` | 高级用户/作者 | schema 搜索路径、schema.yaml、templates | schema 列表、校验结果、脚手架 | 改变 workflow 定义层 | 可能 |
| `new change` | 人类 + OPSX | change 名称、schema、项目根目录 | 新建 change 目录与元数据 | 开启一个新的 workflow 实例 | 是 |
| `status` | 人类 + OPSX | schema、artifact graph、已存在输出文件 | artifact 状态图 | 决定下一步应推进哪个 artifact | 否 |
| `instructions <artifact>` | OPSX + 高级用户 | change context、template、rules、dependencies | artifact instruction 包 | 影响 artifact 文档生成质量与顺序 | 否 |
| `instructions apply` | OPSX + 高级用户 | apply config、context files、tasks | apply instruction 包 | 决定是否进入代码实施阶段 | 否 |
| `templates` | 高级用户/工具 | schema 解析路径、artifact templates | 模板路径与来源 | 帮助调试模板覆盖与解析 | 否 |
| `schemas` | 高级用户/工具 | project/user/package schemas | schema 列表与来源 | 帮助发现可用 workflow 模型 | 否 |
| `workspace setup` | 人类 | workspace 名称、link 路径、opener 选择、工具选择 | `.openspec-workspace/view.yaml`、registry 注册 | 创建跨仓库规划 home | 是 |
| `workspace list` | 人类 + 机器 | registry + view.yaml | workspace 列表及 links | 帮助发现和选择 workspace | 否 |
| `workspace link` | 人类 | 目标目录路径 | 更新 view.yaml 的 links | 扩展 workspace 可规划的仓库范围 | 是 |
| `workspace relink` | 人类 | link name + 新路径 | 更新 link 的本地路径 | 适配不同机器的 checkout 布局 | 是 |
| `workspace open` | 人类 + agent | workspace、opener 选择、initiative 绑定 | AGENTS.md（刷新）、.code-workspace | 启动 agent/editor 并注入 workspace 上下文 | 是 |
| `workspace update` | 人类 | workspace root、profile、delivery、tool 选择 | workspace 级 skill 文件 | 同步 workspace 的 workflow skills | 是 |
| `workspace doctor` | 人类 | view.yaml、link 路径 | 诊断报告（缺失路径、建议） | 排查 workspace 配置问题 | 否 |
| `context-store setup` | 人类 | store 名称、路径 | context store 目录（含 Git repo） | 创建团队共享协调数据空间 | 是 |
| `initiative create` | 人类 + agent | initiative 名称、store | initiative 协调文件（requirements、design 等） | 创建跨仓库使命的协调单元 | 是 |

## workflow 命令简表

| 命令 | 读入什么 | 产出什么 | 产出后帮助什么 |
| --- | --- | --- | --- |
| `new change` | 名称、schema、项目目录 | 新 change 实例 | 让后续状态与说明命令有上下文可挂载 |
| `status` | graph、completed outputs | readiness / blockedness | 选择下一步 artifact |
| `instructions <artifact>` | template、rules、deps、output path | 单个 artifact 的执行包 | 生成 proposal/spec/design/tasks |
| `instructions apply` | apply config、tasks、context files | apply 工作单 | 决定能否编码与如何编码 |
| `templates` | schema 目录 | 模板定位信息 | 调试与理解 workflow 定义 |
| `schemas` | schema 搜索路径 | 可用 schema 列表 | 发现和选择工作流模型 |

## 哪些命令更像“本地 API”

最像本地 API 的是：

- `status --json`
- `instructions <artifact> --json`
- `instructions apply --json`
- `schemas --json`
- `templates --json`
- `list --json`
- `workspace list --json`

共同特征：

- 结构化输出明显。
- 结果更像中间语义而不是最终呈现。
- 常被 OPSX / 上层模板消费。

## 哪些命令最强地改变项目状态

最强的状态改变命令是：

- `init`
- `update`
- `new change`
- `archive`
- `workspace setup` / `workspace update`（v1.4.0）
- 部分 `config` / `schema` 子命令

其中：

- `init/update/workspace update` 更偏改变工具接入层。
- `new change/archive` 更偏改变业务工作流状态。
- `workspace setup` 更偏改变跨仓库规划基础设施。
- `config/schema` 更偏改变系统配置与模型定义层。

