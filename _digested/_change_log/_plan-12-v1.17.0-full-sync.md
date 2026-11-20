# Plan 12：OpenSpec v1.17.0 完全同步计划

> 本文件是可中断、可恢复的执行账本。同步期间发现一项、完成一项、验证一项，就在对应 checkbox 和进度日志中登记；不能只改正文而不更新本计划。
>
> **本计划的范围只有 `v1.15.0` → `v1.17.0`。** 超出这个区间的任何内容都不在本计划与 0014 的记录范围内。

## 当前状态

- **计划状态**：Phase A 完成，E1/E2 已跑；Phase B–E 其余未开始
- **本地分支**：`ethan`
- **旧基线**：OpenSpec `v1.15.0`，tag/commit `8e0288df`
- **目标基线**：OpenSpec `v1.17.0`，tag/commit `579fcac5`
- **upstream 区间**：`8e0288df..579fcac5`
- **提交数量**：32（含 3 个 Version Packages：`27c05157`=1.16.0、`0fa4a970`=1.16.1、`579fcac5`=1.17.0）
- **源码规模**：280 files changed，13122 insertions，2282 deletions
- **发布状态**：三个版本均已发布 npm（10-30 / 11-07 / 11-09）
- **范围纪律**：只认 `v1.17.0` 这个 tag，tag 之外的提交一律不纳入本计划
- **合入方式**：`git merge --squash v1.17.0`，无 merge commit、无 upstream 血缘；合并提交 `1f8df1ec`
- **合并冲突**：26 处，全部共享文件，全部取上游；**无自动合并漂移**
- **源码验收**：`git diff --diff-filter=MD @fission-ai/openspec@1.17.0 --cached` 为空；工作树相对该 tag 只有 258 个本地新增文件
- **已验证**：`pnpm install --frozen-lockfile` / `pnpm build` / `pnpm test` 全绿；CLI 版本 `1.17.0`

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
- 恢复时先复核：`git diff --diff-filter=MD @fission-ai/openspec@1.17.0 HEAD` 仍为空；若不为空，先查清是谁改了上游路径，再继续
- 若发现计划漏项，先追加 checklist，再继续编辑
- **源码已同步，Phase B–E 不要再动 `src/`、`test/`、`scripts/`、`package.json`**；只改三套资料与本计划

---

## 一、同步原则（继承 0013 的长期约定）

### 1. 合入方式：只新增 squash

- 一律 `git fetch upstream --tags` + `git merge --squash <tag>`；**不新增真正的 `merge` 或 `rebase`**。历史 merge（如 `95b7f247`）保留，不重写
- 判据：`ethan` 相对目标 tag 的差异只能是**新增**。`git diff --diff-filter=MD <tag> HEAD`（M=修改，D=删除）必须为空
- 本地允许的新增只有：`_digested/`、`_faq_on_digested/`、`_openspec_handbook/`、`CONTEXT.md`
- 目标是**明确指定的 tag**；不跟 `upstream/main` 漂移，也不跟 npm `latest` 漂移

### 2. 两步验收（本次新增的硬性要求）

因为历史都是 squash，**合并基点永远落后于当前基线**（这次基点是 1.14.3，不是 1.15.0），git 会用错基准做三方合并。后果是：**冲突清零并不等于树等于 tag**——没有冲突的文件也可能被自动合并成与 tag 不同的内容。所以验收必须两条都跑：

```bash
git diff --name-only --diff-filter=U        # 必须为 0
git diff --diff-filter=MD --cached <tag>    # 自动合并漂移；必须为空
```

发现 `M` 即 `git checkout <tag> -- <path>` 覆盖。

### 3. 本版必须写对的口径

- **命令文件是「弃用」，不是「已删」**：`/opsx:*` 命令文件在 1.17.0 仍然生成、仍然可用，只是被标记弃用。资料里注明「已标记弃用」，**不写成已移除**
- **`update` 从任意版本升级**：0.12 起任意版本一次跑完，**不再需要 `--force`**；删除只针对「没人编辑过的旧 OpenSpec 文件」，编辑过的保留并列出；永不碰项目外文件
- **指纹库是生成物**：`src/core/shared/released-generated-fingerprints.ts` 由 `scripts/capture-released-fingerprints.mjs` 生成，**勿手改**；每次上游发版后需重跑
- **validate 三条收紧要分清级别**：无 WHEN/THEN 步骤 = WARNING（`--strict` 才失败）；未识别的 `## ... Requirements` 段 = ERROR（`archive` 拒绝）；坏 `config.yaml` = `validate` 退出 1（其他命令仍只警告）
- **Node 门槛**：npm 包需 **22.12.0+**（Node 20 已 EOL）；standalone 二进制不需要 Node
- **安装产物是归档**：`.tar.gz` / Windows `.zip`，不是裸二进制
- **`version --check`**：显式调用不受遥测开关与 CI 影响；standalone 只提示「真能装上」的版本

## 二、执行阶段

### Phase A：upstream 行为审计 → `_change_log/0014-v1.15.0-to-v1.17.0.md`

- [x] A1 产出 0014：指纹库与旧产物清扫、命令弃用、validate 三条收紧、解析器健壮性、`version --check` 语义、Node 门槛、安装格式、其他；附影响矩阵与两步验收
- [x] A2 源码核实（读 diff 与源码，不只读 changelog）：
  - `released-generated-fingerprints.ts` 的 2867 指纹 / 1130 路径 / 42 个版本
  - `capture-released-fingerprints.mjs` 的采集方式（一次性 HOME、每个 profile/workflow 集/delivery）
  - `generated-fingerprint.ts` 的归一化（BOM、CRLF、`generatedBy` 版本号、`[ \t]` 的复杂度原因）
  - `released-output-sweep.ts` 的三重删除条件
  - `command-reconcile.ts` 的 `removed` / `kept` / `unchecked`
  - `command-surface.ts` 的能力矩阵与四条判定
  - `command-deprecation` 文案与时机设计
  - `validator.ts` 的场景步骤检查为何 delta 与主 spec 共用
  - `stripClosingSequence` 的边界（`C#`、NBSP）
  - `version-check.ts` 的两条路径（npm registry vs GitHub releases atom）+ `node:http(s)` 的原因
- [x] A3 checkpoint：0014 完成，影响矩阵给出每套资料的分级

### Phase B：`_digested/` 更新

- [ ] B1 `README.md`：SSOT 基线行 → `v1.17.0`（`579fcac5`）
- [ ] B2 `spec_cli/01-human-facing-cli.md`（🔴）：`openspec update` 从任意版本升级、不需 `--force`、编辑过的文件保留并列出、命令弃用提示
- [ ] B3 `spec_cli/` 校验相关（🔴）：`validate` 三条收紧的级别与 `archive` 拒绝条件
- [ ] B4 `spec_cli/` 版本相关（🟡）：`version --check` 的遥测/CI 语义、standalone 只提示可装版本
- [ ] B5 `system/06-源码地图与扩展点.md`（🔴）：新增 `generated-fingerprint.ts`、`released-generated-fingerprints.ts`（**生成物**）、`released-output-sweep.ts`、`command-reconcile.ts`、`command-surface.ts`；`scripts/capture-released-fingerprints.mjs`
- [ ] B6 `mechanisms/`（🟡）：指纹归一化与清扫机制；生成物标记与 `.gitattributes`
- [ ] B7 `workflows/`（🔴）：命令弃用状态口径注记（**不改成 skills-only 现状**）
- [ ] B8 `_coverage/`（🟡）：`src-coverage.md`、`tests-coverage.md` 更新模块/测试文件计数；`doc-assertions.md` 记增量抽查
- [ ] B9 checkpoint：抽查 B2/B5/B7 三个 🔴；`grep` 确认没有把「命令文件已删除」写成现状

### Phase C：`_faq_on_digested/` 更新

- [ ] C1 `01_openspec-executable`（🔴）：Node 门槛 22.12.0；安装产物归档格式
- [ ] C2 `12_upstream-roadmap-and-issues`（🟡）：版本表加到 1.17.0；链接 0014
- [ ] C3 `16_upgrade-openspec-cli-and-projects`（🔴）：从任意旧版升级、`--force` 不再是必需、编辑过的文件处理、命令弃用状态口径
- [ ] C4 `17_review-and-validation-surface`（🔴）：WHEN/THEN 警告、未识别 Requirements 段 ERROR、坏 config 退出 1
- [ ] C5 其余目录 `[~]` 核实并写依据；`_faq_on_digested/README.md` 基线脚注
- [ ] C6 checkpoint：抽查 C3/C4

### Phase D：`_openspec_handbook/` 更新

- [ ] D1 `00-index.md`（🔴）：版本表加 1.16.0 / 1.16.1 / 1.17.0 行；链接 0014
- [ ] D2 `99-FAQ-常见问题.md`（🔴）：Node 门槛、命令弃用状态口径、validate 收紧
- [ ] D3 `52-实战-如何正确修改-artifacts`（🟡）：`update` 升级旧项目的新行为；WHEN/THEN 书写要求
- [ ] D4 `24-高级-store-跨仓库协同.md`（🟡）：找不到 root 时的 store 提示
- [ ] D5 其余章节 `[~]` 核实并写依据
- [ ] D6 checkpoint：全局 grep 无旧口径残留

### Phase E：验收与收尾

- [x] E1 `pnpm install --frozen-lockfile` + `pnpm run build` + `pnpm test` 全绿（241 files / 6931 tests passed，1 file / 16 tests skipped，81.68s）
- [x] E2 CLI 版本：`node bin/openspec.js --version` = `1.17.0`
- [ ] E3 版本一致性：`package.json` / `_digested/README.md` / FAQ 12 版本表 / handbook 00-index
- [ ] E4 回填 0014「当前处理状态」与本计划进度日志
- [ ] E5 `_change_log/README.md` 索引加 0014 与 `_plan-12` 两行
- [ ] E6 提交（源码一个 commit `1f8df1ec` 已在；资料回填另计）；**永不推送 `upstream`**
- [ ] E7 交人复核

## 阻塞与决策

| 时间 | 现象 | 证据 | 恢复入口 |
|------|------|------|----------|
| 2026-11-20 | 曾按「直接跳到上游最新」合入并提交 | 需求改为钉 `v1.17.0`、只做本区间 | `git reset --hard 2766c95d` 回到 1.15.0 后重做 |
| 2026-11-20 | 一次未采用的合入尝试中出现自动合并漂移 | 某测试文件在冲突清零后仍偏离 tag | 本计划 §2「两步验收」；`git checkout <tag> -- <path>` |

## 进度日志

- **2026-11-20 计划创建**：`git fetch upstream --tags`，确认上游 `v1.17.0` 已发布（`579fcac5`，2026-11-09）；本地基线仍是 `v1.15.0`（`8e0288df`）。本轮钉死该 tag。
- **基线校正**：确认工作树与 `v1.15.0` 逐字节一致（`package.json`=1.15.0）后开始。
- **源码同步**：`git merge --squash @fission-ai/openspec@1.17.0`，26 处冲突全部共享文件、全部取上游；两步验收均通过，**无自动合并漂移**；同步提交 `1f8df1ec`，`package.json`=1.17.0。
- **审计（Phase A）**：按源码而非 changelog 读，确认本版重量在 `released-generated-fingerprints.ts`（4010 行 / 2867 指纹 / 1130 路径 / 42 个版本），其余是 validate、解析器、`version --check` 的收紧，外加 Node 门槛与安装归档格式。0014 写入。
- **验证（E1/E2）**：`pnpm install --frozen-lockfile` 成功（15.2s，`prepare` 已顺带构建）；`node bin/openspec.js --version` = `1.17.0`；`pnpm test` **241 passed | 1 skipped（242 files）、6931 passed | 16 skipped（6947 tests）**，81.68s。相对 v1.15.0 基线（229 files / 6722 tests）多 13 个测试文件、225 个测试。
- **下一步**：Phase B–D 三套资料回填。

