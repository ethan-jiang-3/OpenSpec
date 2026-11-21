# 配置、Profile 与 Delivery

这一层非常关键，因为它解释了为什么同样是 OpenSpec，在不同项目、不同 AI 工具里看到的工作流外壳会不一样。

> **v2.1.1 状态注记**：本文的第三节讲 `delivery`（skills / commands / both），那是 **1.x 的机制**。**v2.0.0 起 `delivery` 退役**（#2223），一律投递 skills；配置里不再有这一项。当前的「外壳差异」只剩一件事：工具怎么读 skills（直接读 `.agents/skills/`，还是在自己的目录放一条链接）。详见 §3bis。

## 1. 为什么这层重要

如果只看业务命令，会以为 OpenSpec 是一个纯项目内工具。但 `init` / `update` 的源码说明，OpenSpec 还负责把工作流“投递”到具体 AI 工具。

这就引出了三个关键概念：

- profile
- workflows
- delivery

## 2. `profile` 是选什么 workflow

`profile` 决定“启用哪些工作流”。

当前核心认识：

- `core` profile 会启用默认核心 workflows。
- `custom` profile 允许用户自定义启用哪些 workflows。

在当前源码里，`core` 默认工作流是 6 个：

- `propose`
- `explore`
- `apply`
- `update`
- `sync`
- `archive`

系统里可用的全部 workflows 则更广（12 个），包括：

- `propose`
- `explore`
- `new`
- `continue`
- `apply`
- `ff`
- `sync`
- `archive`
- `bulk-archive`
- `verify`
- `onboard`
- `update`

所以，profile 回答的是：

“这套项目/用户要安装哪几条工作流路径？”

## 3. `delivery` 是怎么投递（1.x 机制）

### custom profile 的依赖展开

custom 选择 `archive` 或 `bulk-archive` 时，`getProfileWorkflows()` 会确保 `sync` 在第一个依赖者之前；若已有 `sync`，不重复也不重排其余项。展开后的结果仍是 custom selection，不因“碰巧含 core workflow”而降级成 core。

**（1.x 历史）** `delivery` 决定“以什么形式把 workflow 安装进工具”。

它通常有三种意义：

- `skills`
- `commands`
- `both`

也就是说，同一份 OpenSpec workflow 内容，不一定总以同一种形式出现。

例如：

- 某些工具更适合读 skill 文件。
- 某些工具更适合读 slash command 文件。
- 有的场景则两者都要生成。

所以，delivery 回答的是：

“这些 workflow 产物最终要以什么外壳落到工具目录里？”

### v1.13.x：handoff 按生成时解析（optional-workflow，v2.0.0 已删除该文件）

explore 等工作流对 `/openspec-propose`、`/openspec-apply-change` 的引用现在在**生成时**按 profile 解析（`src/core/templates/optional-workflow.ts`）：custom profile 没装 propose 时，explore 的 handoff 自动回退到自身 capture 路径或 CLI，不再指向一个不存在的命令。配套生成的 skills 只描述 profile 实际安装的 workflow（`626269ed`），且 skill description 含自然语短语（"openspec propose"、"do an openspec apply"，`5f5914e7`）；`openspec update` 这个 CLI 命令本身被刻意不归任何 workflow skill 认领。

## 3bis. v2.x 接替 delivery 的两个东西

`delivery` 退役后，原来由它回答的问题拆成两半：

**① 装在哪一年作用域** —— `openspec/config.yaml` 的 `skillsScope`：

```yaml
skillsScope: project    # 或 global
```

`project` 把技能放在项目里（团队共享）；`global` 放到本机全局位置（跨项目复用）。这个选择记在项目 config 里，**团队不会被重复询问**；CI 或 agent 调用等非交互环境不弹问题，就地刷新。相关源码：`src/core/project-config.ts`、`src/core/global-skills.ts`。

**② 怎么落到每个工具** —— 一份真身 + 链接：

- 真身只有一份：`.agents/skills/openspec-<workflow>/SKILL.md`
- 只读自己目录的工具，在其 `skills/` 下放一条指向真身的相对链接
- 建不了链接（文件系统或权限限制）就退化为拷贝，功能一样、只是不去重
- Windows 上 checkout 提交进仓库的链接需要 `git config --global core.symlinks true` 与开发者模式，否则链接会变成普通小文件，`openspec update` 会把它替换成拷贝

相关源码：`src/core/shared/shared-skill-install.ts`（安装与比对）、`src/core/shared/skill-links.ts`（链接与退化，`SkillLinkSpot` 五态）、`src/core/skill-installer.ts`（调用运行时依赖 `skills` 包）。

**③ `update` 会就作用域提问**（终端里）：项目里已有自己的技能时，`openspec update` 会问「这个项目的技能放在哪」——「留在这个项目」或「切到全局」。选「留在项目」会把选择写进项目的 `openspec/config.yaml`（`skillsScope: project`）并提示你把它提交，团队就不会被重复询问；写不进去也不阻塞更新，只是下次还会问。选「切到全局」前，如果这个仓库开着 GitHub 托管的 Copilot，会再确认一次要不要关掉它（托管 agent 只读项目内的技能）。

**两个机器级状态文件**（都在全局数据目录，从不出机器）：

| 文件 | 作用 |
|---|---|
| `projects.json` | `init` / `update` 记下「这台机器上用过 OpenSpec 的项目」，供后续迁移用。**没有任何东西依赖它**：读不了、写不了都当空处理，永不使命令失败 |
| `global-skills.lock` | 机器级安装的互斥锁（目录 + 里面写 pid）。因为 `skills` 包在多个项目间共用一个锁文件，同机并发安装会撞车。等锁最多 60s，锁超过 10 分钟视为陈旧；数据目录不可写时**放弃加锁继续执行**，不因此阻断安装 |

**共同的底座**：判断「这个文件是不是我没改过的」仍用 1.17.0 引入的内容指纹（`isReleasedGeneratedContent`），所以清理旧产物不需要 `--force`。

## 4. `init` 在做什么

`init` 的行为可以概括为：

1. 读取全局配置中的 profile（v2.x 无 delivery）。
2. 根据 profile 选出要启用的 workflows。
3. 生成技能内容（v2.x 只有 skills；1.x 还会按 delivery 决定是否生成 command）。
4. 确定作用域（`skillsScope`：项目或全局），把技能装到共享真身与各工具目录（链接或拷贝）。
5. 在必要时创建项目级 OpenSpec config。
6. 清理不再需要的旧产物（按内容指纹判断是否被用户改过）。

从系统角度看，`init` 是一次“工作流安装过程”。

## 5. `update` 在做什么

`update` 的本质不是重新安装，而是同步：

- 同步 OpenSpec 版本变化。
- 同步 profile 变化。
- 同步 `skillsScope` 变化（v2.x）／delivery 变化（1.x）。
- 同步 workflow selection 变化。
- 处理 legacy 目录和旧配置。

它还会判断：

- 哪些工具需要版本更新。
- 哪些工具虽然版本没变，但配置已经漂移，需要同步。
- 哪些 workflow 现在不再启用，需要删除对应文件。
- 本次实际更新的工具是否包含 IDE-resident surface；只有 registry 标为 `requiresIdeRestart` 且确实生成了对应 command/skill 时才提示 restart，CLI-only 工具更新不提示。

所以 `update` 更像“声明式同步器”。

## 6. Skills 与 Commands 是同一内容的不同外壳

源码里的 `skill-generation` 和 `command-generation` 非常说明问题：

- 系统先维护一组 workflow 模板内容。
- 然后把这些内容映射成 skill templates 或 command contents。
- 再通过不同 adapter 生成不同工具需要的文件格式。

这说明：

OpenSpec 真正稳定的资产不是某个具体工具的文件，而是“workflow 语义内容”。

skill / command 只是投递载体。

## 7. 为什么 `propose` 很特殊

从 profile 默认值和 `init` 完成后的 onboarding 提示可以看出，`propose` 放在非常显眼的位置。

这说明项目正在把默认体验向以下模式收束：

- 从用户意图出发，先 propose。
- 再通过 continue/apply/archive 等工作流推进。

也就是说，OpenSpec 并不只是维护静态规范文件，而是在尝试提供一个完整的变更工作流入口。

## 8. `config` 命令改变的不是业务数据，而是投递策略

这点非常重要。

用户运行 `openspec config`，通常不是在编辑某个 change，也不是在修改 schema 本身，而是在改：

- 启用哪些 workflow。
- 这些 workflow 怎样出现在 AI 工具里。

还要补一个实现边界：

- `openspec config` 改的是**全局配置**（`config --scope` 目前只接受 `global`）。
- 但「技能装在项目还是这台机器」这件事**不是**用 `config --scope` 表达的，而是用 `init --scope <global|project>`（v2.1.0 起），或写进项目的 `openspec/config.yaml` 的 `skillsScope`，或环境变量 `OPENSPEC_SKILLS_SCOPE`。三者优先级见下。

**作用域解析顺序**（`src/core/init.ts` 的 `resolveSkillScope`）：

1. `--tools none` → 一律 `project`
2. 显式 `--scope` → 用它
3. 项目里已有自己的技能 → `project`
4. `OPENSPEC_SKILLS_SCOPE` 环境变量 → 用它（取值非法会报错）
5. 全局 `config.json` 里的 `skillsScope` → 用它
6. 用了 `--copilot-cloud`，或所选工具里有**不支持全局技能**的 → `project`
7. 以上都没有 → **默认 `global`**

第 7 条是最容易被忽略的：**非交互（CI、agent 调用）下不传 `--scope` 时，默认装到这台机器的全局位置**，不是装进项目。想让项目自带技能，必须显式 `--scope project` 或在项目 config 里写 `skillsScope: project`。

所以 `config` 的影响路径通常是：

`config` -> `init/update` -> tool artifacts -> 用户/AI 的使用入口发生变化

而不是：

`config` -> 某个 proposal/spec/design 立即变化

**v1.13.1 起的全局 config 防重写保护（#1876）**：全局 config 文件存在但无法解析（或根不是 JSON 对象）时，任何命令——包括只读命令——都**不会隐式重写它**：不再把 fallback 默认值当遥测同意、不再铸造新匿名 ID 写回。telemetry 与 update check 将其视为已 opt-out；`config set`/`unset`/`profile` 直接报错并指向 `openspec config edit`；只有 `config reset --all` 仍会整体替换。此前一个尾逗号的手编 typo 就可能让 `openspec list` 悄悄覆盖掉整个 profile 与遥测选择。

## 9. 为什么需要把这一层单独写出来

如果不把 profile 与投递机制单独讲出来，很容易把 `init/update` 理解错：

- 误以为只是项目脚手架命令。
- 看不出 OpenSpec 其实还在做 AI 工具工作流投递。
- 看不出为什么同一个 workflow 要同时存在 skill 和 command 两种形态。

但一旦理解了这一层，你就会明白：

OpenSpec CLI 同时管理三种空间：

- 项目内状态空间（repo-local `openspec/`）
- 工具侧入口空间（skills/commands）
- Workspace 协调空间（跨仓库规划层）

而 profile 与投递机制（1.x 是 `delivery`，2.x 是 `skillsScope` + 一份真身）正是连接这些空间的桥。

（workspace 已被 store 模型替代。旧 workspace skills-only 投递和 `workspace_skills` drift 跟踪不再适用。store 不通过 skill/command 投递机制暴露——它通过 `openspec context` 的 working set 提供给 agent。）
