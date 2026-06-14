# system — OpenSpec 总体系统专题

这个目录补 `_digested/` 里缺的总体层：不是讲某一条命令，也不是教用户怎么使用，而是从当前源码出发，把 OpenSpec 的几个系统层对象放到一张图里。

它承接旧版消化材料里的总览、概念、架构、agent 协议、项目结构这些内容，但不迁移旧文档原文。旧材料只当覆盖清单，结论以当前源码为准。

## 与其他专题的边界

| 目录 | 视角 | 这里怎么衔接 |
|------|------|--------------|
| `system/` | 总体系统模型 | 解释 repo-local planning、workspace、context store、tool delivery、agent runtime API 如何组成整体 |
| `spec_cli/` | CLI 运行时接口 | 深挖具体 CLI 命令的输入输出与调用链 |
| `schema/` | schema 系统 | 深挖 artifact DAG、schema 解析、模板与注入机制 |
| `internal-spec-driven/` | spec-driven 命令机制 | 深挖 explore/propose/apply/archive 在默认 repo-local schema 下的精确执行 |

读法上，`system/` 适合作为第一层地图。看完这里再进入某个专题，会更容易知道自己正在看的模块处于哪一层。

## 文件导航

| # | 文件 | 内容 |
|---|------|------|
| 0 | `00-map.md` | 总体阅读地图：OpenSpec 当前由哪些系统层组成 |
| 1 | `01-系统心智模型.md` | specs/changes 的主轴、OpenSpec 的本质、LLM 与 CLI 的边界 |
| 2 | `02-目录与状态边界.md` | repo-local、workspace、global data/config、context store、agent 集成目录分别保存什么 |
| 3 | `03-planning-home-与-workspace.md` | `PlanningHome` 抽象与 workspace beta 的本地视图模型 |
| 4 | `04-agent-contract-与工具投递.md` | init/update/profile/delivery/skills/commands/adapter 的整体契约 |
| 5 | `05-lifecycle-总览.md` | OPSX workflow 生命周期总览，以及和现有专题的链接 |
| 6 | `06-源码地图与扩展点.md` | 当前源码模块职责和扩展点，使用路径 + 函数/类名作为锚点 |

## 推荐阅读路径

- **第一次建立整体模型**：`00` → `01` → `02`
- **想理解 workspace/context-store**：`01` → `03`，再去看 `../schema/03-内置-workspace-planning-详解.md`
- **想理解 agent 为什么会自动知道怎么做**：`04` → `../spec_cli/03-workflow-runtime-api.md`
- **想从系统图进入命令细节**：`05` → `../internal-spec-driven/00-四条命令的共有机制.md`
