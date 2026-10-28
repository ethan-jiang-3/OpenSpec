# Plan 11：OpenSpec v1.15.0 完全同步计划

> 本文件是可中断、可恢复的执行账本。同步期间发现一项、完成一项、验证一项，就在对应 checkbox 和进度日志中登记；不能只改正文而不更新本计划。

## 当前状态

- **计划状态**：Phase A 完成（源码已同步到 v1.15.0，0013 已写）；**Phase B–E 待执行**
- **本地分支**：`ethan`
- **旧基线**：OpenSpec `v1.14.3`，tag/commit `c794978f`
- **目标基线**：OpenSpec `v1.15.0`，tag/commit `8e0288df`
- **upstream 区间**：`c794978f..8e0288df`
- **提交数量**：13（含 1 个 Version Packages：`8e0288df`=1.15.0）
- **源码规模**：85 files changed，5629 insertions，1373 deletions
- **发布状态**：`v1.15.0` 已发布 npm，dist-tag `latest` = 1.15.0（2026-10-24 00:51 UTC）；GitHub Release 00:50 UTC。tag 后 `upstream/main` 还有 `6d04a1b5`（#2142 website favicon），**不纳入本版**
- **合入方式**：`git merge --squash v1.15.0`，无 merge commit、无 upstream 血缘；合并提交 `5bc2cc04`
- **合并冲突**：仅 `.gitignore`。本地 `.corepack-cache/` 与上游新增 `dist-bin/`、`*.bun-build` 冲突；按长期规则取上游文件，本地忽略项移入 `.git/info/exclude`
- **源码验收**：`git diff --diff-filter=MD v1.15.0 HEAD` 为空；工作树相对 v1.15.0 只有本地新增（`_*` 与 `CONTEXT.md`）
- **已跑验证**：`pnpm build` 成功；`pnpm test` 229 files / 6722 tests 全绿；`node bin/openspec.js --version` = 1.15.0

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
- 恢复时先复核：`git diff --diff-filter=MD v1.15.0 HEAD` 仍为空；若不为空，先查清是谁改了上游路径，再继续
- 若发现计划漏项，先追加 checklist，再继续编辑
- **源码已同步，B–E 阶段不要再动 `src/`、`test/`、`scripts/`、`package.json`**；只改三套资料与本计划

---

## 一、同步原则（继承 0009–0012，并在本轮固定 squash 约定）

### 1. 合入方式：只有 squash，没有 merge

- 同步一律 `git fetch upstream --tags` + `git merge --squash <tag>`；**永远不对 upstream 做真正的 `merge` 或 `rebase`**。
- 判据：`ethan` 相对目标 tag 的差异只能是**新增**。`git diff --diff-filter=MD <tag> HEAD`（M=修改，D=删除）必须为空。
- 本地允许的新增只有：`_digested/`、`_faq_on_digested/`、`_openspec_handbook/`、`CONTEXT.md`。
- 共享文件冲突一律取上游版本；本地需要的忽略项写 `.git/info/exclude`，不写受版本控制的 `.gitignore`。
- 目标是**明确指定的 tag**；不跟 `upstream/main` 漂移，也不跟 npm `latest` 漂移。

### 2. 审计与写作

- CHANGELOG 不是完整审计来源；以 `git log/diff` + 源码为准
- 版本号 SSOT：`_digested/README.md` 的「当前源码基线」一行是唯一要改的"当前基线"声明；各文件正文不声明"核验于 vX"
- 正文中的 `v1.15.0 起/新增` 属不可变历史溯源，不需要批量替换；只有描述"当前行为"的语句在行为变化时才改
- 变了的原地改；新增的结构性归位（新 FAQ/handbook 章、`_digested` 新文件按既有编号体系）

### 3. 本版必须写对的口径

- **Node.js 不再是运行前提**：npm 等包管理器安装才需要 Node.js 20.19+；standalone 单文件不需要
- **安装入口双轨**：官方安装器（`curl` / `irm`）与 `openspec install [version]`；后者复用同一套脚本，默认装最新完整 release
- **`openspec update --dry-run`**：与真实 update 走同一条写入路径；`--json` 只能与 `--dry-run` 同用；预演不是"少写一部分"
- **`/opsx:verify` 的 REMOVED**：按精确规范化名称匹配基线；基线找不回时该条报"未验证"，不是"删除通过"
- **`new change`**：进度行显示 `config.yaml` 实际选中的 schema
- **`--json` 性能**：相关命令不加载 `ora`；`status --json` 186 → 163 modules

## 二、执行阶段

### Phase A：upstream 行为审计 → `_change_log/0013-v1.14.3-to-v1.15.0.md`

- [x] A1 产出 0013：两件新能力（standalone / update dry-run）+ 修复 + 影响矩阵 + 验收基线
- [x] A2 源码核实（读 diff 与源码，不只读 changelog）：
  - `scripts/binary/*` 的构建、安装、校验、e2e/smoke 流程
  - `binaries.yml` 的 8 个目标与"`SHA256SUMS` 最后上传"约定
  - `install-standalone.ts` 的目标目录解析、脚本来源、PATH 检查、旧副本移除提示
  - `standalone-tip.ts` 的触发条件（update 后、全局安装、TTY、非 CI）
  - `update-plan.ts` 的 `UpdateFileOps` 接缝、`UpdatePlanRecorder`、`formatUpdatePlan`
  - `update.ts` 的真实/预演分流，`--json` 只能配 `--dry-run`
  - `feedback` 表单结构、`new change` schema 名、verify REMOVED 规范化匹配
- [x] A3 checkpoint：0013 完成，影响矩阵给出每套资料的分级

### Phase B：`_digested/` 更新

- [ ] B1 `workflows/12-update.md`（🔴）：补 `--dry-run` / `--json`；写入接缝（真实与预演共用一条路径）；`changes[]/notes[]/failures[]` 语义；"预演不是少写一部分"
- [ ] B2 `workflows/08-verify.md`（🔴）：REMOVED 基线改成精确规范化名称；基线找不回 → 该条未验证并跳过搜索
- [ ] B3 `workflows/03-new.md`（🟡）：进度行显示实际 schema，不再固定 `spec-driven`
- [ ] B4 `spec_cli/01-human-facing-cli.md`（🔴）：新增 `openspec install [version]`；`update` 的两个新选项；standalone 一次性提示；`version` 的 `(standalone)` 标识
- [ ] B5 `spec_cli/04-command-deep-dive.md` + `07-command-io-matrix.md`（🟡）：命令/选项矩阵加 `install`、`update --dry-run --json`
- [ ] B6 `system/06-源码地图与扩展点.md`（🔴）：新增 `install-standalone.ts`、`update-plan.ts`、`standalone-tip.ts`、`executable-path.ts`；`scripts/binary/*`；`binaries.yml`；`update.ts` 的写入接缝
- [ ] B7 `mechanisms/05-cli-infra.md`（🟡）：`--json` 懒加载 `ora`、模块数 186 → 163；安装形态对 CLI 启动的影响（standalone 不走 Node）
- [ ] B8 `_coverage/`（🟡）：`src-coverage.md`、`tests-coverage.md`、`doc-assertions.md` 更新模块/测试文件/断言计数（229 files / 6722 tests）
- [ ] B9 `_digested/README.md`：SSOT 基线行 → `v1.15.0`（`8e0288df`）
- [ ] B10 checkpoint：抽查 3 个 🔴 文件；`grep` 确认没有把 Node 写成绝对前提的活口径

### Phase C：`_faq_on_digested/` 更新

- [ ] C1 `01_openspec-executable`（🔴）：standalone 安装路径、Node 只是 npm 方式的前提、`openspec install`、`version --check`、`version` 的 `(standalone)`；question/answer 两份都要改
- [ ] C2 `12_upstream-roadmap-and-issues`（🟡）：版本表 + 1.15.0；链接 0013
- [ ] C3 `16_upgrade-openspec-cli-and-projects`（🔴）：`openspec install` 切换、`update --dry-run --json`、一次性提示、升级命令表
- [ ] C4 `17_review-and-validation-surface`（🟡）：verify REMOVED 精确名；`--json` 的适用范围（若该页涉及）
- [ ] C5 其余目录 `[~]` 核实并写依据；`_faq_on_digested/README.md` 基线脚注
- [ ] C6 checkpoint：抽查 C1/C3，确认没有"必须先装 Node"的绝对句

### Phase D：`_openspec_handbook/` 更新

- [ ] D1 `00-index.md`（🔴）：版本表加 1.15.0 行；手册版本/日期；链接 0013
- [ ] D2 `52-实战-如何正确修改-artifacts`（🟡）：`update --dry-run` 的正确用法；"预演"与"真实更新"共用一条路径
- [ ] D3 `99-FAQ-常见问题.md`（🔴）：Node 是否必需、standalone 安装、`openspec install`、`update --dry-run`、verify REMOVED
- [ ] D4 `90-附录-给机器看的-agent-协议.md`（🟡）：CLI 面加 `install`、`update --dry-run --json`（若该附录维护命令清单）
- [ ] D5 `21-高级-config-schema-与项目边界.md`、`26-高级-治理边界与漂移维护.md`（🟡）：只有出现"update 的行为"当前口径时才改；否则 `[~]`
- [ ] D6 checkpoint：全局 grep 无 v1.14.3 活口径残留；`npm install -g` 只作为"一种方式"出现，不再作为唯一方式

### Phase E：验收与收尾

- [ ] E1 `pnpm run build` + `pnpm test` 全绿（源码未再改动，预期 229/6722）
- [ ] E2 版本一致性：`package.json` / `_digested/README.md` / FAQ 12 版本表 / handbook 00-index
- [ ] E3 回填 0013「当前处理状态」
- [ ] E4 单一 commit 提交资料更新，本计划文件一并提交
- [ ] E5 `_change_log/README.md` 索引加 0013 与 `_plan-11` 两行
- [ ] E6 是否推送 `origin/ethan` 由用户决定；**永不推送 `upstream`**

## 阻塞与决策

| 时间 | 现象 | 证据 | 恢复入口 |
|------|------|------|----------|
| 2026-10-28 | `.gitignore` squash 冲突 | 本地 `.corepack-cache/` vs 上游 `dist-bin/`、`*.bun-build` | 取上游 `.gitignore`；`.corepack-cache/` 写 `.git/info/exclude`（`git check-ignore -v` 已验证） |

## 进度日志

- **2026-10-28 计划创建**：`git fetch upstream --tags` 发现 `v1.15.0`；确认 npm `latest`=1.15.0、GitHub Release 已发；`upstream/main` 比 tag 多 1 个 website 提交，按“钉 tag”不纳入。
- **源码同步**：`git merge --squash v1.15.0`，唯一冲突 `.gitignore`；解决后同步提交 `5bc2cc04`。`package.json`=1.15.0。
- **一致性与验证**：`git diff --diff-filter=MD v1.15.0 HEAD` 为空；`git diff --stat v1.15.0 HEAD` 仅 `_*` + `CONTEXT.md`；`pnpm install --frozen-lockfile` 成功；`pnpm build` 成功；`pnpm test` **229 files / 6722 tests 全绿**（73s）；`node bin/openspec.js --version` = `1.15.0`。
- **资料**：0013 与 `_plan-11` 已写入；Phase B–E 未开始。下一轮从 B1 开始。
