# specs_truth — 主 specs 源真相：为什么会漂、怎么治

## 一句话主轴（整专题的脊柱，先记住这条）

**specs 只在 `archive` 那一刻被写入；requirement 没有稳定 ID，身份就是 `### Requirement: <Name>` 标题文本；而且没有任何工具持续对账。 ⇒ 漂移是默认状态——"把 specs 弄对"根本上是"用 delta + archive 重新表达"，不是手搓 spec 文件；长期对齐是人 + 纪律 + 巡检的责任，不是某个命令的责任。**

下面所有章节都是这条论点的展开。如果只读一句，就读上面这句。

## 这个专题在回答什么

`openspec/specs/` 号称 source of truth、反映项目现状。但它不是手写的，是一路由 delta spec（`openspec/changes/<id>/specs/`）经 `archive` 累加出来的。时间一长——change 被丢弃、目录被改名、归档同步不力、有人直接手改主 spec——specs 就会和真实项目**失真**，藏满噪声（项目里已经没有的东西，spec 还在说"有"）。这直接污染 coding agent：历史方向 A、实际方向 B 时，agent 在自相矛盾的 specs 上做 proposed change，质量打折。

三层展开：**机理**（specs 怎么被 delta 造出来）→ **漂移与噪声**（为什么会失真、为什么没工具自动抓）→ **手段**（怎么治，真实结构是什么）。

## 先分清两层：CLI 命令 vs /opsx: slash

很多人把 "explore/propose/apply/archive/validate" 当同一类动词，其实分两层（基础区分，全专题沿用；详查 `06` 的 validate 命令参考）：

| 动词 | `openspec` CLI | `/opsx:` slash |
|------|:---:|:---:|
| **validate** | ✓ | ✗（无 `/opsx:validate`） |
| **archive** | ✓ | ✓ |
| **new** | ✓（`new change`） | ✓（`/opsx:new`） |
| **explore / propose / apply** | ✗ | ✓ |
| continue / ff / sync / verify / onboard / bulk-archive | ✗ | ✓ |
| list / view / show / status / instructions / config / schema / workspace / context-store / initiative / … | ✓ | ✗ |

日常工作流圈 **explore → propose → apply → archive**：前三步在 `/opsx:` slash 层（agent 驱动），**archive 是 CLI**（把 delta 合进 specs 那一步）。`validate`/`list`/`view` 是另一类——**CLI 工具命令，只读不写、偶尔用，不在工作流圈里**。`validate` 是结构 linter，**抓不出 specs↔代码漂移**（见 `02`/`06`）。

## 与同级目录的关系

| 目录 | 关系 |
|------|------|
| `../internal-spec-driven/04-archive-归档合并.md` | 讲**单次** archive merge 算法。本专题讲**长期**下来 specs 为什么失真、怎么治 |
| `../mechanisms/03-spec-model.md` | 讲 spec/change 的 parser/schema/validator 模型。本专题追问这套身份模型的长期脆弱性 |
| `../system/02-目录与状态边界.md` | 讲"哪个目录是 source of truth"。本专题追问：目录判对了，内容还对得上代码吗 |
| `../../_openspec_handbook/` | 面向学习者的使用手册。本专题面向"想搞懂背后机理"的人 |
| `../_faq_on_digested/keep-specs-aligned/` | **通俗版**："平时习惯 / 怎么发现要修 / 最常见几招"，看不懂或嫌重就先去这 |

## 阅读路径（按受众）

- **新人（~15min 建立全貌）**：`01` 机理 → `02` 漂移 → `07` 图0，停。
- **排错（对着 `archive ... not found`）**：直跳 `04` 诊断树；只有分支 (b) 才回 `01` 身份模型。
- **维护者（季度巡检）**：`07` 图4 运维循环 → `03` 巡检 → `05` 走查当模板。
- **给已有代码补 spec（采用 OpenSpec）**：`08` greenfield。
- **想懂 `initiatives/` 那层平行权威**：`09`。
- **想查源码出处 / 确认工具边界**：`06`。

> 本专题是**纯文档**：解释机制、给方法、给决策矩阵、给走查示例，不替你执行对真实 `openspec/` 的改动——清理由你按 `03`/`04`/`05` 的 recipe 自己决定何时、是否做。（这条只说一次。）
