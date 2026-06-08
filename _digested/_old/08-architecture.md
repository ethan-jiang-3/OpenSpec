# 08 · 架构

> 回 [导读](00-index.md) · [FAQ](FAQ.md)

## 目录

- [§1 源码地图](#1-源码地图)
- [§2 扩展点（想改/加东西时看哪里）](#2-扩展点想改加东西时看哪里)

---

## §1 源码地图

项目根：[/Users/bowhead/OpenSpec/](../)。构建入口 [build.js](../build.js)，依赖 `tsc`，打包为 `dist/`。

### 顶层结构

| 目录 | 作用 |
|------|------|
| [bin/](../bin/) | `openspec` CLI 可执行入口 |
| [src/](../src/) | TypeScript 源码 |
| [schemas/](../schemas/) | 内置 schema（目前只有 `spec-driven`） |
| [docs/](../docs/) | 用户文档 |
| [test/](../test/) | vitest 测试 |
| [scripts/](../scripts/) | 构建/发布辅助脚本 |
| [openspec/](../openspec/) | **用 OpenSpec 管理 OpenSpec**——本项目自己的 specs / changes |

### `src/` 模块职责

#### CLI 入口
- [src/cli/index.ts](../src/cli/index.ts) — `commander` 注册所有子命令、遥测钩子

#### 命令层（`src/commands/`）
每个文件对应一个 CLI 子命令家族：

| 文件 | 命令 |
|------|------|
| [commands/change.ts](../src/commands/change.ts) | `openspec change ...`（legacy） |
| [commands/spec.ts](../src/commands/spec.ts) | `openspec spec ...`（legacy） |
| [commands/show.ts](../src/commands/show.ts) | `openspec show` |
| [commands/validate.ts](../src/commands/validate.ts) | `openspec validate` |
| [commands/config.ts](../src/commands/config.ts) | `openspec config ...` |
| [commands/schema.ts](../src/commands/schema.ts) | `openspec schema ...`（init/fork/validate/which） |
| [commands/completion.ts](../src/commands/completion.ts) | `openspec completion ...` |
| [commands/feedback.ts](../src/commands/feedback.ts) | `openspec feedback` |
| [commands/workflow/](../src/commands/workflow/) | `status` / `instructions` / `templates` / `schemas` / `new-change` —— 这些是 **agent 用**的核心 |

#### 核心引擎（`src/core/`）

| 文件/目录 | 作用 |
|-----------|------|
| [core/init.ts](../src/core/init.ts) (779 行) | `openspec init` 全流程：目录结构、config、skill/command 生成 |
| [core/update.ts](../src/core/update.ts) (702 行) | `openspec update` 重生成 AI 工具配置 |
| [core/archive.ts](../src/core/archive.ts) (339 行) | 归档：merge delta + 搬目录 |
| [core/specs-apply.ts](../src/core/specs-apply.ts) | delta spec → 主 spec 的 merge 算法 |
| [core/view.ts](../src/core/view.ts) | `openspec view` 的交互 dashboard |
| [core/list.ts](../src/core/list.ts) | `openspec list` |
| [core/config.ts](../src/core/config.ts) | **`AI_TOOLS` 数组（28 个工具）** + OPENSPEC_DIR_NAME 常量 |
| [core/profiles.ts](../src/core/profiles.ts) | `CORE_WORKFLOWS` / `ALL_WORKFLOWS` 定义 |
| [core/global-config.ts](../src/core/global-config.ts) | 全局 config 读写（profile / delivery / telemetry） |
| [core/project-config.ts](../src/core/project-config.ts) | 项目 `openspec/config.yaml` 解析 |
| [core/config-schema.ts](../src/core/config-schema.ts) | 全局 config 的 zod schema |
| [core/available-tools.ts](../src/core/available-tools.ts) | 自动检测项目里已有的 AI 工具 |
| [core/legacy-cleanup.ts](../src/core/legacy-cleanup.ts) | 清理旧版 OpenSpec 文件 |
| [core/migration.ts](../src/core/migration.ts) | 版本迁移 |
| [core/profile-sync-drift.ts](../src/core/profile-sync-drift.ts) | 检测全局 profile 和项目文件是否 drift |
| [core/artifact-graph/](../src/core/artifact-graph/) | **DAG 引擎**（见下） |
| [core/command-generation/](../src/core/command-generation/) | **按工具生成命令文件**（见下） |
| [core/schemas/](../src/core/schemas/) | Zod schema（spec / change / base 的数据模型） |
| [core/shared/](../src/core/shared/) | `skill-generation.ts` 共用 skill 模板生成 |
| [core/templates/](../src/core/templates/) | skill/workflow 的**模板文本**（TypeScript 字符串） |
| [core/parsers/](../src/core/parsers/) | spec 和 delta 的 Markdown parser |
| [core/validation/](../src/core/validation/) | 校验逻辑 |
| [core/converters/](../src/core/converters/) | 数据格式转换 |

#### DAG 引擎（`src/core/artifact-graph/`）

OPSX 的心脏。

| 文件 | 作用 |
|------|------|
| [artifact-graph/graph.ts](../src/core/artifact-graph/graph.ts) | DAG 数据结构 |
| [artifact-graph/schema.ts](../src/core/artifact-graph/schema.ts) | 解析 schema.yaml |
| [artifact-graph/resolver.ts](../src/core/artifact-graph/resolver.ts) | schema 路径解析（project/user/package 三级） |
| [artifact-graph/state.ts](../src/core/artifact-graph/state.ts) | 状态判定（`done`/`ready`/`blocked`） |
| [artifact-graph/outputs.ts](../src/core/artifact-graph/outputs.ts) | `generates` 字段的 glob 展开 |
| [artifact-graph/instruction-loader.ts](../src/core/artifact-graph/instruction-loader.ts) | 拼 agent 提示（注入 context / rules / 依赖内容） |
| [artifact-graph/types.ts](../src/core/artifact-graph/types.ts) | TypeScript 类型 |
| [artifact-graph/index.ts](../src/core/artifact-graph/index.ts) | 统一出口 |

#### 工具适配层（`src/core/command-generation/`）

| 文件/目录 | 作用 |
|-----------|------|
| [command-generation/generator.ts](../src/core/command-generation/generator.ts) | 按工具生成命令文件的主逻辑 |
| [command-generation/registry.ts](../src/core/command-generation/registry.ts) | 注册所有 adapter |
| [command-generation/types.ts](../src/core/command-generation/types.ts) | adapter 接口 |
| [command-generation/adapters/](../src/core/command-generation/adapters/) | **每个 coding agent 一个 adapter 文件**（28 个工具在 [config.ts](../src/core/config.ts) 注册，其中 `trae` 和 `forgecode` 没有 command adapter——只生成 skill，所以 adapters/ 目录里实际 adapter 文件少于 28 个） |

#### Skill 生成（`src/core/shared/skill-generation.ts`）
- `getSkillTemplates(filter?)`——按 workflow id 过滤返回 skill 模板
- `getCommandTemplates(filter?)`——同上
- `generateSkillContent(template, version, transform?)`——拼 YAML frontmatter + 正文

#### 模板文本（`src/core/templates/`）
- `workflows/` — 12 个 workflow 的模板（apply-change / archive-change / bulk-archive-change / continue-change / explore / feedback / ff-change / new-change / onboard / propose / sync-specs / verify-change）
- `skill-templates.ts` — skill 模板
- `types.ts` — 模板类型

#### UI（`src/ui/`）
终端交互用，基于 `@inquirer/prompts`。

#### Telemetry（`src/telemetry/`）
基于 `posthog-node`，匿名收集命令名和版本；`OPENSPEC_TELEMETRY=0` 或 `DO_NOT_TRACK=1` 关闭。

### 依赖速览（[package.json](../package.json)）

| 依赖 | 用途 |
|------|------|
| `commander` | CLI 框架 |
| `@inquirer/prompts` | 交互式菜单 |
| `ora` | spinner |
| `chalk` | 彩色输出 |
| `fast-glob` | 文件匹配（`generates: "specs/**/*.md"`） |
| `yaml` | 读写 YAML |
| `zod` | 运行时校验 |
| `posthog-node` | 遥测 |

---

## §2 扩展点（想改/加东西时看哪里）

### 场景 1：加一个新的 coding agent

比如「想支持新的 AI IDE『XYZ』」。三步：

#### 1. 注册到 `AI_TOOLS` 数组

[src/core/config.ts](../src/core/config.ts) 加一条：

```ts
{
  name: 'XYZ',
  value: 'xyz',
  available: true,
  successLabel: 'XYZ',
  skillsDir: '.xyz',
  detectionPaths: ['.xyz/config.json'],   // 可选，覆盖 skillsDir 的自动检测
}
```

#### 2. 写一个 command adapter

[src/core/command-generation/adapters/xyz.ts](../src/core/command-generation/adapters/)，实现 `CommandAdapter` 接口（见 [types.ts](../src/core/command-generation/types.ts)）：

```ts
import type { CommandAdapter } from '../types.js';

export const xyzAdapter: CommandAdapter = {
  toolId: 'xyz',
  commandDir: '.xyz/commands',
  commandFile: (id) => `opsx-${id}.md`,
  renderCommand: (content) => content,   // 纯 markdown
};
```

#### 3. 在 registry 注册

[src/core/command-generation/adapters/index.ts](../src/core/command-generation/adapters/) 或 [registry.ts](../src/core/command-generation/registry.ts) 里 import 并加入 adapter 列表。

**如果不想要 command，只要 skill**（像 Trae / ForgeCode）：跳过步骤 2、3，只在 `AI_TOOLS` 里注册 `skillsDir`。

#### 4. 更新文档

- [docs/supported-tools.md](../docs/supported-tools.md) 加一行
- 本消化笔记的 [02-installation.md §4](02-installation.md#4-28-个支持的工具总表) 加一行

---

### 场景 2：加一个新的 workflow（`/opsx:<new-id>`）

#### 1. 写模板

[src/core/templates/workflows/<new-id>.ts](../src/core/templates/workflows/)，导出两个函数：

```ts
export function get<NewId>SkillTemplate(): SkillTemplate { ... }
export function getOpsx<NewId>CommandTemplate(): CommandTemplate { ... }
```

参考已有的 [propose.ts](../src/core/templates/workflows/propose.ts) 和 [apply-change.ts](../src/core/templates/workflows/apply-change.ts)。

#### 2. 注册到 `ALL_WORKFLOWS`

[src/core/profiles.ts](../src/core/profiles.ts) 数组里加 id：

```ts
export const ALL_WORKFLOWS = [
  'propose', 'explore', /* ... */ 'onboard',
  'new-id',           // 新的
] as const;
```

如果想进 `core` 默认集，也加到 `CORE_WORKFLOWS`。

#### 3. 注册到 skill 和 command generation

[src/core/shared/skill-generation.ts](../src/core/shared/skill-generation.ts)：
- `getSkillTemplates` 的 all 数组里加一条
- `getCommandTemplates` 的 all 数组里加一条

#### 4. 如果新 workflow 要查 artifact graph

看 [src/commands/workflow/](../src/commands/workflow/) 里的 `instructions.ts` 和 `status.ts`，把新的 artifact 查询逻辑加进去。

---

### 场景 3：加一个新的 schema

直接用 CLI：

```bash
openspec schema init my-schema
# 或
openspec schema fork spec-driven my-schema
```

自定义 schema 不需要改源码（存放在 `openspec/schemas/<name>/` 或 `~/.local/share/openspec/schemas/<name>/`）。

**如果想让新 schema 成为内置（和 `spec-driven` 并列）**：
1. 在 [schemas/](../schemas/) 加一个目录
2. 在 [src/core/artifact-graph/resolver.ts](../src/core/artifact-graph/resolver.ts) 里确认包级查找能找到它
3. 改 default schema 时考虑 [src/core/artifact-graph/](../src/core/artifact-graph/)

---

### 场景 4：改 artifact state 判定逻辑

比如「我想让 artifact 用 Git 提交状态而不是文件存在来判 done」。

→ 改 [src/core/artifact-graph/state.ts](../src/core/artifact-graph/state.ts)。

---

### 场景 5：给 delta spec 加一种新 section（比如 `## DEPRECATED Requirements`）

→ 改 [src/core/parsers/](../src/core/parsers/) 里的 delta parser + [src/core/specs-apply.ts](../src/core/specs-apply.ts) 的 merge 逻辑。

---

### 场景 6：改全局 config 字段

→ 改 [src/core/config-schema.ts](../src/core/config-schema.ts)（zod schema）+ [src/core/global-config.ts](../src/core/global-config.ts)（读写）+ [src/commands/config.ts](../src/commands/config.ts)（CLI）。

---

### 场景 7：改 archive 的行为

→ [src/core/archive.ts](../src/core/archive.ts)（主流程）+ [src/core/specs-apply.ts](../src/core/specs-apply.ts)（spec 合并）。

---

### 扩展心智地图

```
加新 coding agent   → config.ts + command-generation/adapters/
加新 workflow 命令  → templates/workflows/ + profiles.ts + shared/skill-generation.ts
加新 schema         → CLI 就够了，或加到 schemas/
改状态判定          → artifact-graph/state.ts
改 delta 格式       → parsers/ + specs-apply.ts
改 archive 逻辑     → archive.ts
改全局 config       → config-schema.ts + global-config.ts + commands/config.ts
改项目 config       → project-config.ts
```

**原则**：OpenSpec 尽量把「数据（schema、模板、配置）」和「逻辑（引擎）」分开。大部分定制只改数据不改逻辑——这就是 OPSX 的核心价值。
