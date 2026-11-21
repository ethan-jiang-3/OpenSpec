# Plan 13：OpenSpec v2.1.1 完全同步计划

> 本文件是可中断、可恢复的执行账本。同步期间发现一项、完成一项、验证一项，就在对应 checkbox 和进度日志中登记；不能只改正文而不更新本计划。
>
> **本计划的范围只有 `v1.17.0` → `v2.1.1`**（含 `2.0.0` 大版本、`2.1.0`、`2.1.1`）。超出这个区间的任何内容都不在本计划与 0015 的记录范围内。

## 当前状态

- **计划状态**：Phase A 完成、Phase B–D 主要落点已回填、E1/E2 已跑；剩余 B9/C5/C6/D4/D5 校验项与 E3–E7 收尾未完成
- **本地分支**：`ethan`
- **旧基线**：OpenSpec `v1.17.0`，tag/commit `579fcac5`
- **目标基线**：OpenSpec `v2.1.1`，tag/commit `0c737dc1`
- **upstream 区间**：`579fcac5..0c737dc1`
- **提交数量**：23（含 3 个 Version Packages：`d12c2817`=2.0.0、`8bd4b355`=2.1.0、`0c737dc1`=2.1.1）
- **源码规模**：242 files changed，17027 insertions，7342 deletions
- **发布状态**：三个版本均已发布 npm（11-11 / 11-17 / 11-19）；`upstream/main` 首次查询时正好停在该 tag
- **范围纪律**：只认 `v2.1.1` 这个 tag，tag 之外的提交一律不纳入本计划
- **合入方式**：`git merge --squash v2.1.1`，无 merge commit、无 upstream 血缘；合并提交 `1fb874fb`
- **合并冲突**：56 处，全部共享文件，全部取上游
- **合并漂移**：3 个文件被 1.17.0 旧内容带回（`command-surface.ts` 与两个测试），已按 tag 覆盖；另有 2 个 2.0 已删测试文件残留，已删除
- **源码验收**：`git diff --diff-filter=MD @fission-ai/openspec@2.1.1 --cached` 为空；工作树相对该 tag 只有 260 个本地新增文件
- **已验证**：`pnpm install --frozen-lockfile` / `pnpm build` / `pnpm test` 全绿；CLI 版本 `2.1.1`

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
- 记录当前 `HEAD`、`git status --short` 和目标 tag
- 恢复时先复核：`git diff --diff-filter=MD @fission-ai/openspec@2.1.1 HEAD` 仍为空；若不为空，先查清是谁改了上游路径，再继续
- 若发现计划漏项，先追加 checklist，再继续编辑
- **源码已同步，Phase B–E 不要再动 `src/`、`test/`、`scripts/`、`package.json`**；只改三套资料与本计划

---

## 一、同步原则（继承 0013/0014）

### 1. 合入方式：只新增 squash

- 一律 `git fetch upstream --tags` + `git merge --squash <tag>`；**不新增真正的 `merge` 或 `rebase`**。历史 merge（如 `95b7f247`）保留，不重写
- 判据：`ethan` 相对目标 tag 的差异只能是**新增**。`git diff --diff-filter=MD <tag> HEAD`（M=修改，D=删除）必须为空
- 本地允许的新增只有：`_digested/`、`_faq_on_digested/`、`_openspec_handbook/`、`CONTEXT.md`
- 目标是**明确指定的 tag**；不跟 `upstream/main` 漂移

### 2. 三步验收（本轮新增第三步）

历史全是 squash，合并基点永远落后（本轮仍是 **1.14.3**），三方合并会同时产生两种偏差：

```bash
git diff --name-only --diff-filter=U        # 1) 冲突必须为 0
git diff --diff-filter=MD --cached <tag>    # 2) 自动合并漂移；必须为空
git diff --cached --name-only --diff-filter=A -- . ":!_\*" ":!CONTEXT.md"
                                            # 3) 上游路径上的"新增"必须是 0
```

第三项是本次新加的：2.0 删掉了若干 1.17.0 才加的文件，三方合并把它们当成「我们新增的」而保留，`--diff-filter=MD` 查不出来。发现即 `git rm`，并按 tag 覆盖。

### 3. 本版必须写对的口径

- **命令文件是「已移除」，不是「弃用」**：1.17.0 标弃用，2.0 真删。资料里凡是写「已标记弃用」的都要改成「已移除」
- **skills 只有一份**：`.agents/skills/` 为真身，其他工具用自己的 `skills/` 目录指向它的链接；建不了链接时退化为拷贝
- **`delivery` 已退役**：配置里不再有这一项，不要再写三态
- **作用域**：2.1 起有 `global` / `project` 两种，记在 `openspec/config.yaml`
- **安装层外包**：运行时依赖 `skills` 包；适配器层仍在，但**只做路径解析，不做生成**
- **退役工具有正式机制**：`RETIRED_TOOLS` 表 + 替代工具提示（Amazon Q → Kiro）
- **Node 门槛**：`>=22.20.0`
- **Windows**：链接需要 `core.symlinks` 与开发者模式，否则退化为拷贝

## 二、执行阶段

### Phase A：upstream 行为审计 → `_change_log/0015-v1.17.0-to-v2.1.1.md`

- [x] A1 产出 0015：2.0 破坏性变更、`skills` 包外包、全局 skills、工具退役、2.1.1 八组修复、其余；附影响矩阵
- [x] A2 源码核实（读 diff 与源码，不只读 changelog）：
  - `shouldGenerateCommandsForTool` 已不存在（命令生成能力移除）
  - 34 个适配器仍在，但调用方只剩清理/路径解析
  - `skill-installer.ts` 的 `installSkills` / `removeSkills` 与 `expectedSkillContents`
  - `skill-links.ts` 的五种 `SkillLinkSpot` 状态
  - `global-skills.ts` 的 `SkillScope` 与 `getSupportedAgents`
  - `known-projects.ts` 的「永不失败」约束
  - `retired-tools.ts` 的表结构与三条行为
  - `command-references.ts` 仍在做 `/opsx:` 引用的按工具改写
- [x] A3 checkpoint：0015 完成，影响矩阵给出每套资料的分级

### Phase B：`_digested/` 更新

- [x] B1 `README.md`：SSOT 基线行 → `v2.1.1`（`0c737dc1`）
- [x] B2 `spec_cli/01-human-facing-cli.md`（🔴）：`update` 的 2.0 行为；命令文件已移除；`delivery` 退役
- [x] B3 安装与位置（🔴）：`.agents/skills/` 单份真身 + 链接；Windows 前提；全局作用域
- [x] B4 `system/06-源码地图与扩展点.md`（🔴）：新增 `skill-installer.ts`、`global-skills.ts`、`known-projects.ts`、`shared-skill-install.ts`、`skill-links.ts`、`retired-tools.ts`、`project-skills-scope.ts`、`project-dir.ts`；删除 `optional-workflow.ts`；**写明适配器层只做路径解析**
- [x] B5 `mechanisms/`（🟡）：`skills` 包依赖与安装流程；指纹设施在 `skill-links` 里的复用
- [x] B6 `workflows/`（🔴）：命令→技能的对应表；`/openspec-<name>` 调用形式
- [x] B7 工具面（🟡）：退役机制与 Amazon Q → Kiro
- [x] B8 `_coverage/`（🟡）：计数更新（249 files / 6510 tests）；说明测试数为何下降
- [ ] B9 checkpoint：抽查 B2/B3/B4；`grep` 确认没有残留「已标记弃用」「delivery 三态」

### Phase C：`_faq_on_digested/` 更新

- [x] C1 `01_openspec-executable`（🔴）：Node 22.20；安装层变化
- [x] C2 `12_upstream-roadmap-and-issues`（🟡）：版本表到 2.1.1；链接 0015
- [x] C3 `16_upgrade-openspec-cli-and-projects`（🔴）：2.0 升级步骤、命令文件处理、改过的文件保留、Windows 链接
- [x] C4 `17_review-and-validation-surface`（🟡）：2.1.1 的 validate/archive 修复
- [ ] C5 其余目录 `[~]` 核实并写依据；`README.md` 基线脚注
- [ ] C6 checkpoint：抽查 C3/C4

### Phase D：`_openspec_handbook/` 更新

- [x] D1 `00-index.md`（🔴）：版本表加 2.0.0 / 2.1.0 / 2.1.1；链接 0015
- [x] D2 `99-FAQ-常见问题.md`（🔴）：命令文件没了怎么办、skills 在哪、怎么全局装
- [x] D3 `50-实战-claude-code 里的 openspec 到底怎么落地.md`（🔴）：调用形式从 `/opsx:*` 改为技能名
- [ ] D4 其余章节 `[~]` 核实并写依据
- [ ] D5 checkpoint：全局 grep 无 `/opsx:` 的现行用法（历史溯源除外）

### Phase E：验收与收尾

- [x] E1 `pnpm install --frozen-lockfile` + `pnpm run build` + `pnpm test` 全绿（248 files / 6491 tests passed，1 file / 19 tests skipped，122.91s）
- [x] E2 CLI 版本：`node bin/openspec.js --version` = `2.1.1`
- [ ] E3 版本一致性：`package.json` / `_digested/README.md` / FAQ 12 版本表 / handbook 00-index
- [ ] E4 回填 0015「当前处理状态」与本计划进度日志
- [ ] E5 `_change_log/README.md` 索引加 0015 与 `_plan-13` 两行
- [ ] E6 提交（源码一个 commit `1fb874fb` 已在；资料回填另计）；**永不推送 `upstream`**
- [ ] E7 交人复核

## 阻塞与决策

| 时间 | 现象 | 证据 | 恢复入口 |
|------|------|------|----------|
| 2026-11-21 | 自动合并把 2.0 已删代码带回 | `command-surface.ts` 里重新出现 `formatCommandDeprecationNotice` | §2 第二项；`git checkout <tag> -- <path>` |
| 2026-11-21 | 2.0 已删测试文件被误判为「本地新增」 | `command-deprecation-notice.test.ts`、`delivery-deprecation-docs-claims.test.ts` | §2 第三项；`git rm` |

## 进度日志

- **2026-11-21 计划创建**：复核上游最新发行版本为 `v2.1.1`（`0c737dc1`，2026-11-19），且 `upstream/main` 正好停在该 tag。上一轮 1.17.0 的资料回填已完成（`9e91eed5`）。
- **源码同步**：`git merge --squash @fission-ai/openspec@2.1.1`，56 处冲突全部共享文件、全部取上游；三步验收中第二、三步都触发告警并已修正；同步提交 `1fb874fb`，`package.json`=2.1.1。
- **验证（E1/E2）**：`pnpm install --frozen-lockfile` 成功（2.9s，`prepare` 顺带构建）；`node bin/openspec.js --version` = `2.1.1`；`pnpm test` **248 passed | 1 skipped（249 files）、6491 passed | 19 skipped（6510 tests）**，122.91s。相对上一轮基线（242 files / 6947 tests）测试**净减 437 个**，因命令生成能力的覆盖随代码一起删除。
- **审计（Phase A）**：确认 2.0 删掉了命令生成能力但保留 34 个适配器做路径解析；安装层改为依赖 `skills` 包；0015 写入。
- **Phase B–D（2026-11-21）**：`_digested` 回填基线、命令移除、skills 单份共享、delivery 退役、源码地图 8 个新模块与适配器新职责、12 个 workflow 的调用头；`_faq_on_digested` 回填 Node 22.20、2.x 升级段、校验面 2.1.1 三项、版本表 3 行与 2.0 五步路线图状态；`_openspec_handbook` 回填版本表、命令速查改技能名、Q27h、01/50/52/55/90 的 `/opsx:*` → `/openspec-*`。全库相对链接 0 断链。
- **一处口径反转**：`_coverage/doc-assertions.md` 里「不得写已移除」的旧口径已作废并改写——那是 v1.17.0 轮的要求，2.0 起 command 文件真的没了。
- **下一步**：B9/C5/C6/D4/D5 的抽查与全局 grep，再走 E3–E7。
