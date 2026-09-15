# 资料对齐 0011：v1.11.0 → v1.13.0 缺口补齐

**日期**：2026-09-15

**性质**：不是新的上游同步，而是对 0008/0009/0010 三份同步记录的**缺口回填与对齐**。0008–0010 的状态区长期未勾选，但三套资料的实际内容与状态区不符：`_digested/` 已覆盖大部分 v1.11–v1.13，`_faq_on_digested/` 存在内部矛盾，`_openspec_handbook/` 正文基本停在 v1.11。

**源码基线**：OpenSpec `v1.13.0` = `9d4e5974`（未变；本轮不改源码）。

## 审计结论（本轮起点）

| 资料集 | 覆盖状态 | 实质缺口 |
|---|---|---|
| `_digested/` | 35 项中 30 项准确 | 5 项：Purpose 占位符检测、`schema init --default`、Fish completion、ASCII 图例、（删除内置 schema 无 stale） |
| `_faq_on_digested/` | 29 项中 21 项 | 3 处 stale 矛盾 + 1 项全缺 + 3 项偏浅 |
| `_openspec_handbook/` | 31 项中约 8 项 | 14 项 MISSING / 9 项 PARTIAL，正文停在 v1.11 |

## 本轮改动

### 一、`_faq_on_digested/`：消除内部矛盾

1. **`schema init --default` 三处旧论**（v1.11.0 已修复写 `schema` 键并删除 `defaultSchema`，旧文仍称其为"静默无效字段"）：
   - `08_config-yaml-growth/sources.md`
   - `13_how_to_design_maintain_config_yaml/sources.md`
   - `13_.../02-diagnose-maintain-config-yaml.md`（症状表 + 维护规则）
2. **`09_schema-agent-dev/`、`10_schema-requirement/` stale**：上游 v1.11.0 删除了同名**内置** schema；补 v1.11.0 边界说明，澄清这两个是项目级自定义副本，并把 v1.10.0 基线升到 v1.13.0。
3. **其余缺口**：`16` 补 npm git 免 pnpm / Node20 chalk、profile 依赖展开与 feedback 保真细节；`03` 补 v1.11.0 Explore 写入前确认；`12` roadmap 表补 v1.11/v1.12/v1.13 三行并升基线到 v1.13.0。

### 二、`_digested/`：补 5 项

| 项 | 落点 |
|---|---|
| Purpose 占位符检测（v1.11.0） | `mechanisms/03-spec-model.md` 新增小节 |
| `schema init --default` 修复（v1.11.0） | `schema/06-自定义-schema-实战.md` |
| Fish completion 不再回退文件路径（v1.11.0） | `mechanisms/05-cli-infra.md` |
| Explore 图例改纯 ASCII（v1.11.0） | `workflows/01-explore.md` |
| 内置 schema 足迹（删除两个） | `schema/00-map.md` |

### 三、`_openspec_handbook/`：正文对齐到 1.13.0

- **版本戳**：01/02/03/06/07/09/11/12/13/14/15/90 的"当前模型"定位句由 v1.11.0 升到 1.13.0；`00-index.md` L279 标题由"v1.10.0 工具与环境速查"改为"工具与环境速查（v1.10.0 起，含 v1.12.0/v1.13.0）"。
- **12 章**新增整节"改完怎么审：delta 保真与审阅工具（1.11.0–1.13.0）"：四类静默失效、`show --diff`/`status --all`/`validate --report findings`、advisory preflight、Purpose 占位符、判断锚点。
- **09 章**补 `show --diff`、`status --all`、`validate --report findings` 与 rename 保序。
- **11 章**补 apply 无 spec 警告与 `missingPrerequisites`。
- **90 章**补 `instructions apply --json`（`missingPrerequisites`/`warning`）与 `validate --report findings`/`show --diff`/`status --all` 的 JSON 形状；工具投递补 Antigravity、SourceCraft、`resolveSharedSkillWriters()`。
- **99 FAQ** 新增 Q7a（审阅/校验命令）、Q16 补 advisory preflight、Q26 补 v1.10–v1.12 新工具、Q27a 补 Antigravity 与通用仲裁。
- **02/01** 补 Antigravity 共享 `.agents/` 与通用仲裁。

### 四、新增内容：`_faq_on_digested/17_review-and-validation-surface/`

"审阅/校验工具面"是此前没有独立研究的**新主题**，本轮新建探究目录（`question.md` + `answer.md`），把解析保真与报告面两条线合起来对照 `_digested/specs_truth/` 的缺口，并明确其边界（不解决 specs↔代码漂移、无持续对账、无自动 retrieval）。README 已登记。

### 五、版本号结构重构（SSOT）

本轮对齐暴露出一个结构问题：**把全局可变事实（"当前基线 vX"）抄进了几十个文件**，导致每次发版都要全量重扫。约 1248 处版本号中，真正会漂的是"每文件版本身份"（约 50 处），其余是**不可变历史溯源**（`vX 起/新增`），本就不需要随发版改动。

约定（已写入三套资料 README / 00-index）：

- **基线只写一处**：`_digested/README.md`、`_faq_on_digested/README.md`、`_openspec_handbook/00-index.md` 各声明一次当前基线；正文不再声明"本文适用/核验于某版本"。
- **正文与版本解耦**：正文用现在时描述当前行为；升级基线只改入口一处。
- **正文与版本解耦**：正文用现在时描述当前行为；不写"本文件适用/核验于某版本"。升级基线只改入口一处。
- **只有"不得不"的才留版本号**：固定到 tag 的 URL 永久链接、版本史文档、真实版本要求（如 `Zed ≥ 1.4.2`）、示例输出（如 feedback 的 `Version: x`）。
- **版本敏感文件**登记在 README 的「版本相关文件」表，而不是写在文件里。

已执行的清理：

1. **每文件版本身份**：FAQ 各 `answer*.md` 的"以 vX 为当前基线/核验于 vX"脚注、`当前边界（vX）`标签、14/15 的基线声明；handbook 各章首版本戳、07/90 的适用版本戳；`_digested` 的 `spec_cli/00-map`、`internal-spec-driven/04`（§8 标题）、`internal-spec-driven/07`、`spec-driven-capability/README` 的基线声明——均改为指向入口 SSOT。
2. **结构性去版本**：正文标题前缀（`### v1.10.0→v1.11.0：X` → `### X`）、尾部括号注记（`（v1.12.0）`）、时间状语（`vX 起，`→删、`vX 之前`→"此前"）统一清理；保留章节号、缩进与代码示例。
3. **内联历史溯源剔除**：`vX 的 <对象>` / `vX 起…` / `vX 新增…` / `vX 修复…` 等改写为现在时或去版本，使正文只描述当前行为。豁免范围仅上述"不得不"项。
4. **版本史文档豁免**：`_change_log/`、`_coverage/`、FAQ `12`（roadmap）、`16`（升级指南）、`_research-*` 快照、`00-index` 变更记录、各 README 基线。

> **过程如实记录**：内联溯源的机器批量删除曾两次造成破损（分别 56 处、49 处 + 146 行缩进误伤），均已回退；随后改用"小步规则 + 逐条精确替换 + 独立 verifier 复查"的方式完成。期间被 verifier 累计发现并修复约 80 处语法/结构破损（悬空动词、空加粗、空括号、版本区间断裂、链接断裂、误伤"起草"等）。**最终独立复核：CLEAN，537 个相对链接 0 断裂，无空标题/空单元格/悬空动词。**

## 边界与未改动

- 本轮**不改源码**，只对齐资料；未运行 build/test（无源码变更）。
- 未新增 `_digested/` 子目录：新主题集中在 FAQ 探究目录。
- `_digested/_coverage/` 已刷新（src/specs/tests 三表补入 v1.11–v1.13 新增模块与测试）。
- 上游网站 `docs-lab/`、`CONTRIBUTING.md` 等工程/站点变化不属于三套资料的覆盖范围，未纳入。

## 验收基线

```text
node -p "require('./package.json').version"   # 1.13.0（未变）
```

资料侧核对：

- 三套资料内 `defaultSchema` 不再被描述为"当前仍静默无效"。
- `09`/`10` 不再把已删除的内置 schema 当作现役内置。
- handbook 各章"当前模型"定位句为 1.13.0，`00-index` 标题不再误标 v1.10.0。
- 新增 `17_review-and-validation-surface/` 已登记进 FAQ README。
