# 09 · 能力身份与 specs 漂移维护

> 适用 openspec ≥ 1.4 · 高级篇。这一章回答两个长期被轻描淡写的问题：**specs 到底按什么组织、靠什么定位？** 以及 **用久了 main specs 为什么会和代码对不上、怎么守？** 两者其实是同一件事。

## 先看清：spec-driven 是背后的 driver

前面几章你会反复看到 `config.yaml` 里写着 `schema: spec-driven`。它不是个可以略过的配置细节——**`spec-driven` 是 OpenSpec 默认、最常见的工作流 schema，也是背后的 driver。**

`schemas/spec-driven/schema.yaml` 这个文件定义了**每个 change 的骨架和契约**：

- artifact 依赖图：`proposal → specs → (design) → tasks → apply`；
- delta 操作：`## ADDED / MODIFIED / REMOVED / RENAMED Requirements`；
- 格式规则：每个 requirement 用 `### Requirement: <name>`、每个 scenario **必须** `#### Scenario:`（4 个 `#`，少了静默失败）、requirement 正文要含 `SHALL`/`MUST`；
- **能力契约**：proposal 里列的每个 capability，specs 阶段都要生成对应的 `specs/<name>/spec.md`。

关键一句（schema 原文）：

> The Capabilities section is critical. It creates the **contract between proposal and specs phases**. … Each capability listed here will need a corresponding spec file.

**为什么这点重要**：你写进 `openspec/` 的任何东西，都得合这个 schema 的契约——CLI 和 agent 是照着它解析的。**偏离契约（4 个 `#` 写成 3 个、capability 名拼错、缺 SHALL/MUST），工具要么静默忽略、要么 parse 失败，agent 就在残缺/错误的前提上推理 → 幻觉和困惑行为。**

下面要讲的"能力身份"，就是这个契约里最核心、又最容易被忽略的一条。

## capability 的身份 = 它的目录名

很多人把 `openspec/specs/` 笼统当成"规格基线"。但它**不是一堆平铺的文档，而是按 capability（能力）切成一个个目录**：

```text
openspec/specs/
├── auth/spec.md              ← "auth" 这个能力的合同
├── data-export/spec.md       ← "data-export" 这个能力的合同
└── notifications/spec.md
```

**一个 capability 的身份，就是它在 `specs/` 下那个 kebab-case 目录名**（`auth`、`data-export`）。这个目录名同时扮演四个角色：

| 角色 | 说明 |
|------|------|
| **组织单位** | main specs = 一组 `specs/<capability>/spec.md`，按能力切分管理 |
| **proposal↔specs 的契约** | proposal 列的每个 capability 名，specs 阶段必须生成同名 `specs/<name>/spec.md`（schema 写死的） |
| **delta 的靶心** | delta 写在 `changes/<id>/specs/<capability>/spec.md`，archive 时打 `openspec/specs/<capability>/spec.md`——**目录名同名才命中** |
| **没有别的身份** | capability **没有稳定 ID**，就靠这个目录名维系 |

所以 archive 能把 delta 合并进主 spec，靠的就是**目录名寻址**——不是魔法，是契约。这也意味着：**改一个 capability 的目录名，是个大事**（见下文）。

## 两层「以名字为身份」模型（无稳定 ID）

OpenSpec 的身份模型是**「以名字为身份」（name-as-identity），分两层，都没有稳定 ID**：

| 层 | 身份 = | 怕什么 | 有没有 rename 操作 |
|----|--------|--------|-------------------|
| **capability** | **目录名**（`specs/<capability>/`，kebab-case） | 改目录名 / 目录没了 | **没有** |
| **requirement** | **标题文本**（`### Requirement: <Name>`） | 改标题 / 大小写 | 有（`## RENAMED Requirements`，FROM/TO） |

两个推论，直接关系到 specs 会不会漂：

1. **都怕改名，且没有 ID 兜底。** 传统系统里改个名字，ID 不变，引用不断链。OpenSpec **没有 ID**——名字一改，所有指向旧名字的引用全部失配，而且**没有任何工具告诉你断了**。
2. **capability 比 requirement 更脆。** requirement 至少有 `RENAMED` 操作（`FROM: ### Requirement: 旧` / `TO: ### Requirement: 新`），改名是个一等动作；**capability 没有任何 rename 操作**——改 capability 名只能靠你手动搬目录，然后所有指向旧目录名的 delta 默默变成"悬空目标"。

> 一句话：**requirement 改名有"正规手续"（RENAMED）；capability 改名没有手续，是裸操作。** 所以 capability 目录名要当**稳定性契约**对待——能不改就不改。

## 这就是 specs 漂移的根

`openspec/specs/` 号称 source of truth，但用着用着就和代码对不上了。根因就是上面这套身份模型 + 一个事实：**没有任何工具持续对账**（`validate` 只查文件结构、从不打开主 spec 去比对，`archive` 只在那一刻匹配一次）。

漂移，就是**两层"名字身份"失配**：

- **capability 层失配**：delta 指向的 capability 目录名，在 `openspec/specs/` 里对不上——要么"设计了没建"、要么"目录被改名了"、要么"早删了"。**表现：archive 一个 change 时，目标 spec 不存在或对不上；或一堆 change 悬空挂在 active。**
- **requirement 层失配**：delta 的 `MODIFIED`/`REMOVED` 指向的标题，在当前主 spec 里找不到——标题被别的 archive 改写过、大小写变了、或手改过。**表现：archive 报 `... not found`，整批原子回滚。**

两层是**同一个病**（名字身份失配），只是发生在不同层。再加上"有代码无 spec"（反向漂移：能力上线了 specs 没记）、"废弃 change 仍挂 active"（噪声）等，specs 就慢慢配不上"source of truth"这个名号了——而 agent 还把它当事实读，于是被带偏。

## 平时怎么守住（handbook 通俗版）

不必背一堆手段，记住几条就够：

- **做完一个 change 就 `archive`，别让它卡在 active。** specs 只在 archive 那一刻更新；不 archive，specs 永远停在旧版本。
- **requirement 改名走 `RENAMED`**，别"删旧 + 加新"（那会掐断历史，让老 delta 失配）。
- **capability 目录名尽量别改。** 没有正规 rename 操作，改名=裸搬目录，要同步所有引用它的 delta——当稳定性契约对待。
- **apply 改代码时，顺手想一句"这段 spec 还准吗"。** 这是最廉价的对齐动作。
- **偶尔巡检**：`openspec list` / `openspec validate --all` 能抓结构坏死（僵尸 change）；但**别把"validate 干净"当成"specs 对齐"**——它查不出 capability/requirement 的名字失配和 specs↔代码漂移。
- **别手改主 spec 文件**。要改就写 change（delta）再 archive；手改没有任何工具追踪，下次 delta 一撞就 `not found`。

## 手册内继续读

- [`02-中级-把核心概念真正串起来`](02-中级-把核心概念真正串起来.md)——`specs/`、`changes/`、delta、archive 合并的基础（本章的根）。
- [`04-高级-config-schema-与项目边界`](04-高级-config-schema-与项目边界.md)——schema 是什么、怎么选；本章的 `spec-driven` 就是默认那套。
- [`12-实战-如何正确修改-artifacts`](12-实战-如何正确修改-artifacts.md)——动手改 artifact 时怎么不踩格式契约的坑（4 个 `#`、exact 名字等）。
- [`07-高级-workspace-跨仓库规划-v1.4.0`](07-高级-workspace-跨仓库规划-v1.4.0.md)——多仓库时 capability / area 目录怎么组织。

> 想看**源码级深挖**（schema 字段逐项、合并算法、六类噪声/修法的完整机理）：仓库里另有 `_digested/` 专题——那是给挖源码的人准备的，不是本手册的一部分。
