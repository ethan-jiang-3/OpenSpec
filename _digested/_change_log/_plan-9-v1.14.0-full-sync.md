# Plan 9：OpenSpec v1.14.0 完全同步计划

> 本文件是可中断、可恢复的执行账本。同步期间发现一项、完成一项、验证一项，就在对应 checkbox 和进度日志中登记；不能只改正文而不更新本计划。

## 当前状态

- **计划状态**：Phase A–D + E1/E2/E3 完成；仅剩 E5 push（等用户 `gh auth login`）
- **本地分支**：`ethan`
- **工作树**：计划创建时 clean（merge commit `a0cdcbc6` 已存在）
- **旧基线**：OpenSpec `v1.13.1`，tag/commit `634c557b`（upstream 侧 `bae58cf6` 为上次同步的 main 顶点）
- **目标基线**：OpenSpec `v1.14.0`，tag/commit `94ca9c1e`
- **upstream 区间**：`bae58cf6..94ca9c1e`
- **提交数量**：73（含 2 个 `Version Packages`：`db230978`=1.13.2、`94ca9c1e`=1.14.0）
- **源码规模**：204 files changed，10703 insertions，1236 deletions（src/ 57 files +1883 −430；test/ 57 files +6087 −191）
- **发布状态**：`v1.14.0` 已发布 npm 且 dist-tag `latest`（已用临时 cache 验证）。**`v1.14.0` 之后 upstream/main 还有 6 个未发版提交（`3a34ea30..2500d6da`），本次不同步**，留给 0012。
- **合入方式**：第一次误合 `upstream/main`（`65267416`），确认 v1.14.0 已发布后 reset 回 `7d1f3549` 重做，仅合 `v1.14.0` tag，零冲突，merge commit `a0cdcbc6`。
- **已知阻塞**：`git push origin ethan` 因凭据失败（`gh` token 失效 + keychain 无 github.com 条目），需用户在终端执行 `gh auth login -h github.com` 后由我重推。见「阻塞与决策」。

## 状态图例

- `[ ]` 未开始
- `[-]` 进行中；同一阶段最多保留一个 `[-]`
- `[x]` 已完成并满足该项完成标准
- `[~]` 已核实无需修改；必须在条目后写明依据
- `[!]` 有阻塞；必须在「阻塞与决策」中记录现象、证据和恢复入口

## 中断恢复协议

每次暂停或切换会话前必须完成以下动作：

- [ ] 将正在执行的唯一条目标记为 `[-]`，不要把未验收工作标成 `[x]`
- [ ] 在「进度日志」记录最后完成的文件、尚未完成的文件、已运行的验证及结果
- [ ] 记录当前 `HEAD`、`git status --short` 和目标 upstream hash
- [ ] 若发现计划漏项，先追加 checklist，再继续编辑；不要只在聊天里保存决定
- [ ] 恢复时从第一个未完成 checkbox 开始，并先复核工作树没有被其他工作改变

阶段完成必须有明确 checkpoint。不能跨过未通过的 checkpoint 去勾下一阶段。

---

## 一、固定事实与同步原则

### 1.1 已核实的 upstream 事实

- [x] 已 fetch upstream，确认新 tag `v1.13.2`、`v1.14.0`（及 `@fission-ai/openspec@1.13.2/1.14.0`）
- [x] 已确认 v1.14.0 已发布 npm（dist-tag latest）——因此同步到 tag 而非 main 是正确口径
- [x] 已确认目标区间 73 个提交；`v1.13.2` 为 patch（CRLF、Windows EPERM、Kilo Code 目录、artifact 输出 glob 等），`v1.14.0` 为 minor（10 个新工具目标、archived 浏览、workflow status 展示、version --check 等）
- [x] 已确认 merge `a0cdcbc6` 零冲突，`pnpm install --frozen-lockfile` + build 通过，216 test files / 6388 tests 全绿
- [ ] 逐 PR 行为审计（CHANGELOG 之外的行为细节，如 #2031 之前 main 上有 dashboard 归档、tag 内实际状态）→ 产出 0011

### 1.2 同步原则（继承 0009/0010）

- CHANGELOG 不是完整审计来源；以 `git log/diff` + 源码为准
- 版本号 SSOT：`_digested/README.md` 的「当前源码基线」一行是唯一要改的"当前基线"声明；各文件正文不再声明"核验于 vX"
- 正文中的 `v1.13.x 起/新增` 属不可变历史溯源，**不需要**批量替换为 v1.14.0；只有描述"当前行为"的语句在行为变化时才改
- 变了的原地改；新增的结构性归位（新 FAQ/handbook 章、_digested 新文件按既有编号体系）
- `v1.14.0` tag 后 main 增量（6 commits）不属于本轮；其中 #2031（dashboard 移除归档显示）与 #399 的关系在 0011 里注明"main 上已再次调整，未含于 v1.14.0"，避免资料写死一个将被下个版本推翻的口径

## 二、执行阶段

### Phase A：upstream 行为审计 → `_change_log/0011-v1.13.1-to-v1.14.0.md`

- [x] A1 按 0009 骨架产出 0011：版本主题（1.13.2 修复性 / 1.14.0 工具生态+可观测性）、按领域拆解表、对三套资料的影响矩阵、优先级建议、验收基线
- [x] A2 重点核实（读源码而非只读 changelog）：
  - 新工具目标的目录/调用形态：`dsh`（skills-only）、codestudio、gigacode、atomcode、gsd、amp、veai、grok、warp、easycode —— 各自安装路径与命令文件格式（Markdown/TOML）
  - `openspec version --check --json` 的输出契约
  - `list --archived/--all` + view 分区显示的实际行为
  - `instructions apply --json` 的 `sourcePath`/`line` 字段与 apply 工作流的重勾选逻辑
  - archive 阻塞语义（sync 失败不归档）+ Windows EPERM/EXDEV 复制回退 + CRLF 保持
  - `.openspec.yaml` 未知键告警 + `validate --strict` 失败
  - `show --json` requirement/scenario `name` 字段
  - CRLF line-endings 新模块 `src/utils/line-endings.ts` 的机制（dominant ending 检测）
- [x] A3 checkpoint：0011 初稿完成，影响矩阵给出每个子目录的 🔴/🟡/🟢 分级

### Phase B：`_digested/` 更新（按 0011 影响矩阵执行）

- [x] B1 `system/06-源码地图`：新增模块行 6 个 + version-check 行；原地更新 archive.ts/purpose-placeholder/outputs/shared-skill-target/两个扩展点段（cb060306）
- [x] B2 `spec_cli/`（31192801：6 files +104/−17，含 version 端点契约、#2031 预告句）：01（version 命令、list --archived）、02（JSON 契约变化：show name、apply sourcePath、version --json）、04（deep-dive 补新命令链）、07（IO matrix 行更新）
- [x] B3 `workflows/`（735e681d：00 新机制节、02 命名引导、06 sourcePath/line 节拍、08 verify 大改含 Not applicable/Not verified 分界、09/10 阻塞语义、12 工具目标+Kilo 修正；全部源码锚点重算）：09-archive（阻塞语义、CRLF、EPERM 回退）、10-bulk-archive、12-update（工具目标刷新）、02-propose（capability 命名引导）、06-apply（task source location）
- [x] B4 `internal-spec-driven/`（faf2563c：02 capability 命名+500字符+任务分组、03 sourcePath/line+taskTrackingConfigured 三段式重勾选、04 阻塞语义+快照回滚+回滚剪裁，行号引用全部刷新）：03-apply（checkbox 定位重写）、04-archive（spec sync 阻塞）
- [x] B5 `mechanisms/`（cb060306：02 工具矩阵 + 05 CLI 基建；纠正审计偏差——#2019 钉版不在 tag 内）：02-tool-delivery（新工具矩阵）、05-cli-infra（依赖安全钉版、启动性能——注意 #2025 在 main 不在 tag，不写）
- [x] B6 `specs_truth/`（cb060306：06 锚点两条 + normalizeRequirementName 原地修正；02 的 CRLF 条目由主会话完成）：06-源码锚点（CRLF/行尾保持与失真的关系）
- [x] B7 `schema/`：02-内置详解（若 schema.yaml/模板有实质变化才动，先 diff）
- [x] B8 `_coverage/`（faf2563c：src-coverage 新模块表、tests-coverage 13 行新测试映射（纠正：apply-defer-guardrail.test.ts 系 v1.11.0 既有，非本轮新增）、specs-coverage 记 cli-artifact-workflow 的 Workflow Status requirement 增与 Experimental Isolation 删）：src-coverage（新模块）、tests-coverage（新测试映射）、specs-coverage（核对 `openspec/specs/` 是否有新 requirement header）
- [x] B9 `_digested/README.md`（faf2563c：SSOT 基线行 → v1.14.0 / 94ca9c1e）：SSOT 基线行 → `v1.14.0`（`94ca9c1e`）
- [x] B10 checkpoint（抽查 3 个 🔴 文件：workflows/09-archive、spec_cli/02、mechanisms/02 均通过；SSOT 行已升级）：`grep -rn "当前源码基线" _digested/README.md` 已指向 v1.14.0；抽查 3 个 🔴 文件内容与源码一致

### Phase C：`_faq_on_digested/` 更新

- [x] C1 FAQ 16（v1.13.2/v1.14.0 提醒节 + 10 新工具速览含 dsh + 基线脚注→SSOT）（upgrade）：版本表 + 升级提醒 → v1.14.0（含 1.13.2/1.14.0 两条）
- [x] C2 FAQ 07（ARC-12 更新 EPERM 回退；Step 14 追加阻塞语义；新补充节）（archive-ready→archived）：archive 阻塞语义、spec sync 失败不归档
- [x] C3 FAQ 06（answer/sequence/app03/app06 四文件：sourcePath/line 契约与三段式勾选）（apply-ready→archive-ready）：apply 的 task 定位与重勾选
- [x] C4 FAQ 12（版本表 +v1.13.2/v1.14.0 两行，链接 0011；标题改「最新至 v1.14.0」）（upstream roadmap）：版本时间线补 v1.13.2/v1.14.0
- [x] C5 FAQ 17（verify 重写六节补充；明确 #2020 非 v1.14.0 行为）（review/validation）：validate --strict 未知键失败、500 字符口径（tag 内是引导文案，--strict 失败在 main，注意区分）
- [x] C6 FAQ 03（capability 命名引导补充节）（explore→propose）：capability 命名引导（e70dcc7）若影响 propose 前置
- [x] C7 其余 11 个目录 [~] 核实（各有一句依据）；README 基线脚注→SSOT
- [ ] C8 checkpoint：FAQ README 与 16 的"当前版本"一致

### Phase D：`_openspec_handbook/` 更新

- [x] D1 00-index：版本表、记录行、工具速查表（新工具全量补入，尤其 dsh）
- [x] D2 各章首版本戳/SSOT 指针核对（02/09/90 三处当前基线戳改 SSOT 指针；其余为历史溯源注记保留）
- [x] D3 01 初级：init --tools 工具清单
- [x] D4 07 store / 09 漂移维护 / 12 artifacts：archive 阻塞与 CRLF 相关表述
- [x] D5 99-FAQ / 90-agent 协议：工具列表补全
- [x] D6 checkpoint（8d67a1b5 报告：11 文件更新、8 章核实未动含依据；工具速查表全量扩容含 dsh/warp/IBM Bob）：grep 全 handbook 无"当前版本=1.13.1"的活口径残留（历史溯源除外）

### Phase E：验收与收尾

- [ ] E1 `pnpm run build` + `pnpm test` 全绿（应与 merge 时同水平：216 files / 6388 tests）
- [ ] E2 版本一致性：`package.json`=1.14.0、_digested README 基线、FAQ 16、handbook 00-index 四处一致
- [ ] E3 回填 0011 的「当前处理状态」与「验收基线」
- [ ] E4 单一 commit 提交资料更新（`docs: 同步三套资料到 v1.14.0（0011）`），本计划文件一并提交
- [ ] E5 push `origin/ethan`（依赖阻塞解除）
- [ ] E6 更新 `_change_log/README.md` 索引加 0011 行

## 阻塞与决策

| 时间 | 现象 | 证据 | 恢复入口 |
|------|------|------|----------|
| 计划创建时 | push 失败：could not read Username | `gh auth status`：token invalid（ethan-jiang-1）；keychain 无凭据 | 用户终端执行 `gh auth login -h github.com` → 通知 agent 执行 E5 |

## 进度日志（收尾）

- E1 ✅：`pnpm run build` 成功；`pnpm test` 216 files / 6388 tests 全绿（与 merge 时点同水平）。
- E2 ✅：四处版本锚点一致；全局 grep 无残留 v1.13.1 活口径（历史溯源除外）。
- E3 ✅：0011「当前处理状态」全勾。
- 计划状态：除 E5（push，等用户凭据）外全部完成。

## 进度日志

- 计划创建（Plan 9）：merge `a0cdcbc6` 已存在且验收通过（216/6388 全绿）；HEAD=`a0cdcbc6`，工作树 clean。
