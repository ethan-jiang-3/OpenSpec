# Plan 10：OpenSpec v1.14.3 完全同步计划

> 本文件是可中断、可恢复的执行账本。同步期间发现一项、完成一项、验证一项，就在对应 checkbox 和进度日志中登记；不能只改正文而不更新本计划。

## 当前状态

- **计划状态**：Phase A–E 全部完成（E5 见「阻塞与决策」）
- **本地分支**：`ethan`
- **旧基线**：OpenSpec `v1.14.0`，tag/commit `94ca9c1e`
- **目标基线**：OpenSpec `v1.14.3`，tag/commit `c794978f`
- **upstream 区间**：`94ca9c1e..c794978f`
- **提交数量**：39（含 3 个 `Version Packages`：`87c3595a`=1.14.1、`f80d860f`=1.14.2、`c794978f`=1.14.3）
- **源码规模**：120 files changed，7020 insertions，4077 deletions
- **发布状态**：`v1.14.3` 已发布 npm 且 dist-tag `latest`；GitHub `v1.14.3` = `upstream/main` 顶点，**tag 后无未发版提交**
- **合入方式**：`git merge v1.14.3`，零冲突，merge commit `95b7f247`

## 状态图例

- `[ ]` 未开始
- `[-]` 进行中；同一阶段最多保留一个 `[-]`
- `[x]` 已完成并满足该项完成标准
- `[~]` 已核实无需修改；必须在条目后写明依据
- `[!]` 有阻塞；必须在「阻塞与决策」中记录现象、证据和恢复入口

## 中断恢复协议

（以下为执行时的操作要求，不是待办项）

- 将正在执行的唯一条目标记为 `[-]`，不要把未验收工作标成 `[x]`
- 在「进度日志」记录最后完成的文件、尚未完成的文件、已运行的验证及结果
- 记录当前 `HEAD`、`git status --short` 和目标 upstream hash
- 若发现计划漏项，先追加 checklist，再继续编辑
- 恢复时从第一个未完成 checkbox 开始，并先复核工作树没有被其他工作改变

---

## 一、同步原则（继承 0009/0010/0011）

- CHANGELOG 不是完整审计来源；以 `git log/diff` + 源码为准
- 版本号 SSOT：`_digested/README.md` 的「当前源码基线」一行是唯一要改的"当前基线"声明；各文件正文不声明"核验于 vX"
- 正文中的 `v1.14.x 起/新增` 属不可变历史溯源，不需要批量替换；只有描述"当前行为"的语句在行为变化时才改
- 变了的原地改；新增的结构性归位（新 FAQ/handbook 章、_digested 新文件按既有编号体系）
- **本轮特殊**：0011 中所有"属 tag 后 main、不算 v1.14.0 行为"的注记（#2019 钉版、#2025 按需加载、#2020 strict 超长失败、#2031 view 移除归档）从 v1.14.3 起失效，应按当前行为书写

## 二、执行阶段

### Phase A：upstream 行为审计 → `_change_log/0012-v1.14.0-to-v1.14.3.md`

- [x] A1 产出 0012：三版主题（1.14.1 语义澄清 / 1.14.2 边界收紧 / 1.14.3 安全收尾）、按领域拆解 10 节、影响矩阵、优先级
- [x] A2 源码核实（读 diff 而非只读 changelog）：
  - glob 引擎替换与 brace 预算（`outputs.ts` 新增 `assertBraceNesting`/`expandArtifactBraces`/`globBase`/`listDirectoryMatches`）
  - spec 文件 symlink 包含规则（`spec-path-containment.ts` 的 `findProjectRoot` 与"不从文件自身能力目录重新推导信任根"）
  - `unappliedContent` 的判定边界（注释/围栏/`# ` 标题/Purpose/REMOVED-RENAMED 不报）
  - `all_done` 语义、`## Workflow follow-up`、`PARTIAL_ARTIFACT_CHECK`
  - verify 按 outputPath 找工件、REMOVED 基线三段落
  - `archive_retirement_cleanup_failed`、`view` 移除归档
  - `x-*` 扩展键、`canRenderSpinner` 根因、CLI 按需加载分层
  - `openspec/specs/` 三条 requirement 变更（#2065：schema 优先级 / archive 确认默认 Yes / telemetry 文案）
- [x] A3 checkpoint：0012 完成，影响矩阵给出每个子目录分级

### Phase B：`_digested/` 更新

- [x] B1 `specs_truth/`（🔴）：delta 解析与失真面新增 `unappliedContent`；requirement 长度 INFO→WARNING
- [x] B2 `workflows/`（🔴）：06-apply、08-verify、07-continue、02-propose、05-ff、09/10-archive、11-specs、12-update、03-explore
- [x] B3 `mechanisms/`（🔴）：05-cli-infra（glob 引擎、启动/补全性能、spinner）；02-tool-delivery 核实
- [x] B4 `internal-spec-driven/`（🟡）：03-apply、04-archive、02-specs 写入
- [x] B5 `spec_cli/`（🟡）：view、archive 错误码、`src/cli/commands/*` 分层、补全
- [x] B6 `schema/`（🟡）：schema.yaml 的 specs/tasks instruction、brace 限制
- [x] B7 `system/06-源码地图`（🟡）：新增/删除模块行
- [x] B8 `_coverage/`（🟡）：src/tests/specs 三件套
- [x] B9 `_digested/README.md`：SSOT 基线行 → v1.14.3（`c794978f`）
- [x] B10 checkpoint：抽查 3 个 🔴 文件

### Phase C：`_faq_on_digested/` 更新

- [x] C1 FAQ 16 升级提醒 → v1.14.x
- [x] C2 FAQ 12 版本表 +1.14.1/1.14.2/1.14.3，链接 0012
- [x] C3 FAQ 06 apply 完成语义 + `## Workflow follow-up`
- [x] C4 FAQ 07 `archive_retirement_cleanup_failed` + symlink + unappliedContent
- [x] C5 FAQ 11 delta 文本失真面
- [x] C6 FAQ 17 500 字符 strict、`x-*` 扩展键、verify REMOVED 基线
- [x] C7 其余目录 [~] 核实并写依据；README 基线脚注
- [x] C8 checkpoint

### Phase D：`_openspec_handbook/` 更新

- [x] D1 00-index 版本表
- [x] D2 01 初级：unappliedContent 告警、500 字符
- [x] D3 04/06：`x-*` 扩展键
- [x] D4 09/12：symlink、artifacts 路径边界
- [x] D5 13/90/99 等按需
- [x] D6 checkpoint：全局 grep 无 v1.14.0 活口径残留

### Phase E：验收与收尾

- [x] E1 `pnpm run build` + `pnpm test` 全绿
- [x] E2 版本一致性：package.json / _digested README / FAQ 16 / handbook 00-index
- [x] E3 回填 0012「当前处理状态」
- [x] E4 单一 commit 提交资料更新，本计划文件一并提交
- [x] E5 `_change_log/README.md` 索引加 0012 行

## 阻塞与决策

| 时间 | 现象 | 证据 | 恢复入口 |
|------|------|------|----------|
| Phase A | `pnpm install --frozen-lockfile` 在 workspace 内耗时过长（>5min，仍在跑） | `node_modules` 仅 13 项，`tinyglobby`/`fast-glob` 均未落地 | 等后台 job `bash-14745`；失败的替代方案是在 `/tmp/openspec-v1143` worktree（tag 快照）里安装并跑 build/test，本地目录不装 |
| Phase E | E5 `git push` 未执行 | 遵循"未经要求不 push"的约定；且此前轮次出现过 push 凭据失败（需 `gh auth login`） | 用户确认后再 `git push origin ethan`；本地 commit 与 tag 已就位 |

## 进度日志

- 计划创建（Plan 10）：merge `95b7f247` 零冲突；`package.json`=1.14.3；工作树 clean（0012 已写入）。
- 已建 `/tmp/openspec-v1143` worktree（detach 于 `c794978f`）作为源码锚点参照，行号引用以该快照为准。
- Phase B 完成：`specs_truth/02`+`06`、`workflows/{00,01,02,03,04,05,06,08,09,12}`、`mechanisms/05-cli-infra`、`internal-spec-driven/{03,04}`、`spec_cli/{01,04}`、`schema/02`、`system/06`、`_coverage/{tests,specs}`、`_digested/README.md`（基线 `c794978f`）。
- Phase C 完成：FAQ 16（v1.14.1–3 升级提醒）、12（版本表三行 + 部分补强段）、06（`all_done` 与 `## Workflow follow-up`）、07（三类"归档看起来成功"）、03（capture 表限 schema + 输出路径）、17（unapplied 文本 / 清理错误码 / verify 两条口径）、README 条目描述。
- Phase D 完成：handbook 00-index（1.14.3 + v1.12 行）、01（`all_done` 口径、`## Workflow follow-up`、archive 确认默认 Yes 与散文告警）、04（`x-*` 扩展键 + 五步 schema 解析顺序）、09（unapplied 文本归属表 + spec symlink）、12（update 的两条 glob 边界）。
- Phase E：`pnpm run build` OK；`pnpm test` **223 files / 6585 tests 全绿**（v1.14.0 基线 216/6388）；版本一致性 package.json=`1.14.3`、SSOT=`v1.14.3 (c794978f)`、handbook 00-index=`1.14.3`；`grep "upstream main|未发版|tag 后"` 在三套资料中已清零；0012 状态已回填；`_change_log/README.md` 已加 0012 与 `_plan-10` 两行。
