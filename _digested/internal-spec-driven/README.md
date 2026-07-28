# internal-spec-driven — spec-driven 工作流源码机制深挖

这个目录是 `_digested/` 的"内核层"之一，**专门聚焦 spec-driven 这一条 schema 下的四条核心命令**（explore、propose、apply、archive）。`_digested/` 的其他子目录（`schema/`、`spec_cli/`）侧重**概念解释和架构解读**，而项目根目录的 `_openspec_handbook/` 是按认知层次的学习手册，这里聚焦于**从 TypeScript 源码出发的精确机制剖析**。

## 文件导航

按推荐阅读顺序：

| # | 文件 | 内容 |
|---|------|------|
| 0 | `00-四条命令的共有机制.md` | 三方架构、schema 即控制器、文件系统即状态、四层注入机制、status+instructions 核心配合模式、双重交付机制 |
| 1 | `01-explore-探索模式.md` | 姿态定位（非工作流）、CLI 调用链、四种入口场景、与 propose 的衔接、guardrails |
| 2 | `02-propose-提案生成.md` | 完整 5 步流程、每个 artifact 的模板与 instruction 详解、DAG 拓扑排序保证、schema 解析优先级 |
| 3 | `03-apply-实施执行.md` | Apply gate 三种状态、checkbox 解析正则、实施循环、流体工作流理念、与 archive 的衔接 |
| 4 | `04-archive-归档合并.md` | 三阶段流程（验证→合并→移动）、RENAMED→REMOVED→MODIFIED→ADDED 合并算法的精确步骤与操作顺序原理、不可逆性 |
| 5 | `05-schema-driven-控制面.md` | 内置 `spec-driven` 的四 artifact、真实 DAG、文件存在式 completion、Apply gate、schema 名称固定边界与源码自洽性风险 |
| 6 | `06-config-yaml-机制与约束.md` | config.yaml 的技术约束（Zod schema、50KB 限制、artifact ID 验证）、context/rules 注入的精确代码路径、与 schema.yaml 的交互细节、技术层面的推荐 |
| 7 | `07-config-yaml-上下文路由源码深挖.md` | 基于当前源码补足内置 `spec-driven` 的真实上下文路由：四 artifact DAG、Apply/Explore/Archive 注入边界、schema 名称固定与维护验证方法 |

## 阅读建议

- **只想搞清楚一条命令怎么运作** → 直接跳到对应那篇
- **想理解四条命令之间的共同基础设施** → 先读 `00`，再读其他
- **想彻底理解 OpenSpec 的 meta 本质** → `00` → `05` → `06` → `07`
- **想自己写 schema 或 fork 一个** → `05` 是必读，然后去读 `../schema/` 目录

## 与上游源码的对应

正文引用以“函数名 + 当前路径”为主。少量行号只作为定位辅助，源码后续重构时以函数名、数据结构和语义描述为准。关键源文件总览见 `05` 第 9 节。
