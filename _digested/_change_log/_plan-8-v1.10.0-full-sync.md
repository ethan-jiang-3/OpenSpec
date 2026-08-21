# Plan 8：OpenSpec v1.10.0 完全同步计划

> 本文件是可中断、可恢复的执行账本。同步期间发现一项、完成一项、验证一项，就在对应 checkbox 和进度日志中登记；不能只改正文而不更新本计划。

## 当前状态

- **计划状态**：upstream 已无冲突合入；三套资料、横向审计与最终验收完成，待创建单一 merge commit
- **本地分支**：`ethan`
- **工作树**：计划创建前 clean
- **旧基线**：OpenSpec `v1.9.0`，tag/commit `2826b8889e5223a9a8095d4428b60b56597e1020`
- **目标基线**：OpenSpec `v1.10.0`，tag/commit `1ebddd17f40dde15dfd28289e4493c3cf05ee9df`
- **upstream 区间**：`2826b88..1ebddd1`
- **提交数量**：18（含 `Version Packages`）
- **源码规模**：78 files changed，2819 insertions，618 deletions
- **发布状态**：`upstream/main` 与 `v1.10.0` 在调研时重合；没有 tag 后增量
- **资料范围**：
  - `_digested/`
  - `_faq_on_digested/`
  - `_openspec_handbook/`
  - `_digested/_change_log/`

## 状态图例

- `[ ]` 未开始
- `[-]` 进行中；同一阶段最多保留一个 `[-]`
- `[x]` 已完成并满足该项完成标准
- `[~]` 已核实无需修改；必须在条目后写明依据
- `[!]` 有阻塞；必须在“阻塞与决策”中记录现象、证据和恢复入口

## 中断恢复协议

每次暂停或切换会话前必须完成以下动作：

- [ ] 将正在执行的唯一条目标记为 `[-]`，不要把未验收工作标成 `[x]`
- [ ] 在“进度日志”记录最后完成的文件、尚未完成的文件、已运行的验证及结果
- [ ] 记录当前 `HEAD`、`git status --short` 和目标 upstream hash
- [ ] 若测试需要先 build，记录 `dist/` 是否已经按 v1.10.0 重建
- [ ] 若发现计划漏项，先追加 checklist，再继续编辑；不要只在聊天里保存决定
- [ ] 恢复时从第一个未完成 checkbox 开始，并先复核工作树没有被其他工作改变

阶段完成必须有明确 checkpoint。不能跨过未通过的 checkpoint 去勾下一阶段。

---

## 一、固定事实与同步原则

### 1.1 已核实的 upstream 事实

- [x] 已 fetch `upstream`，确认 `upstream/main` 从 `2826b88` 前进到 `1ebddd1`
- [x] 已确认新 tag `v1.10.0 = 1ebddd1`
- [x] 已确认目标区间包含 18 个提交、78 个变更文件
- [x] 已确认 v1.10.0 CHANGELOG 不是完整审计来源
- [x] 已确认以下 7 类实质变化未完整进入 v1.10.0 release notes：
  - Zed Agent 支持
  - no-spec schema 自动 `skip_specs`
  - custom profile 自动补 `sync`
  - OpenCode `$ARGUMENTS`
  - feedback 完整正文
  - telemetry notice 写 stderr
  - 测试/交互基础设施相关的行为修复

### 1.2 本次必须覆盖的行为主题

- [x] `openspec init --language <language>`
- [x] Zed Agent 与 `.agents/skills/` 三方 ownership
- [x] store-aware specs instruction：`planningHome.root`
- [x] 每条生成 task 必须声明 verification
- [x] no-spec schema 自动写 `skip_specs: true`
- [x] archive capability retirement 的 blocked-content 失败路径
- [x] custom profile 的 archive/bulk-archive → sync 依赖
- [x] OpenCode command 的 `$ARGUMENTS` 传递
- [x] 删除 npm postinstall，改为首次 CLI 运行 completion tip
- [x] telemetry 首次提示写 stderr
- [x] `openspec update` 只在需要时提示重启 IDE
- [x] feedback 长消息的 title/body 保真
- [x] `@inquirer` 升级带来的交互实现变化是否需要用户资料说明
- [x] 依赖、CI、website、测试环境变化是否仅记入 changelog 而不扩散到正文

### 1.3 写作与版本原则

- [x] 当前行为使用 v1.10.0 源码和测试作依据，不只复述 CHANGELOG
- [x] 历史记录中的 v1.9.0、v1.8.0 等版本号保留，不做机械替换
- [x] 区分 CLI 硬校验、schema instruction、workflow guidance 和文档建议
- [x] 区分源码 checkout、`package.json` 版本和 PATH 中 `openspec --version`
- [x] 区分 repo-local root、store pointer、`--store` 和 global default store
- [x] host-specific 调用语法按实际 adapter 写，不把 `/opsx:*` 当通用入口
- [x] 每个新结论至少有一个稳定源码、测试、spec 或 tag 链接作为依据
- [x] 手册正文必须改到读者实际遇到行为的位置，不能只加顶部版本提示

**Checkpoint A：** 上述主题和原则全部在 `0007` 中有对应落点，且没有把 release notes 当作完整提交清单。

---

## 二、建立本次同步记录

### 2.1 新建 `0007-v1.9.0-to-v1.10.0.md`

- [x] 写明日期、完整 hash、tag、提交数量、文件统计
- [x] 明确本区间没有 tag 后增量
- [x] 明确 CHANGELOG 覆盖与 commit-range 覆盖的差异
- [x] 按以下主题拆解并给出意义、边界、源码和测试锚点：
  - [x] 初始化与多语言
  - [x] Zed 和工具投递
  - [x] store-aware main-spec instruction
  - [x] tasks verification
  - [x] no-spec schema / `skip_specs`
  - [x] capability retirement guidance
  - [x] profile/sync 依赖
  - [x] OpenCode 参数
  - [x] completion tip / packaging
  - [x] telemetry / stdout-stderr
  - [x] update restart
  - [x] feedback 保真
- [x] 单独列出纯依赖、CI、website 和测试环境变化
- [x] 写出对三组资料的影响矩阵
- [x] 写出合并和 PATH CLI 的独立验收基线
- [x] 写出本计划文件的链接

### 2.2 更新 change-log 索引

- [x] `_digested/_change_log/README.md` 增加 `0007`
- [x] `_digested/_change_log/README.md` 增加本计划
- [x] 复核编号、版本跨度和文件名连续

**Checkpoint B：**

- [x] `0007` 可以独立回答“上游改了什么、为什么重要、影响哪些资料”
- [x] 本计划可以独立回答“下一步改哪些文件、如何验收、被打断后从哪里恢复”

---

## 三、合入 upstream 源码

> 只有 Checkpoint B 通过后才进入本阶段。合并时保留本地 `_digested/`、FAQ、handbook 和自定义内容。

### 3.1 合并前保护

- [x] 确认当前分支仍为 `ethan`
- [x] 确认工作树只包含本次计划/记录改动
- [x] 记录合并前 `HEAD`：`99d17682104c4c4d5e886ada187f9ab883e2d7a3`
- [x] 再次 fetch 并确认 `v1.10.0` 仍为 `1ebddd1`
- [x] 检查 `upstream/main` 是否已出现 tag 后提交；没有，仍与 tag 重合
- [x] 检查本地与 upstream 在源码、package、lockfile、docs 上的潜在冲突

### 3.2 执行非快进合并

- [x] 以 `git merge --no-ff --no-commit upstream/main` 合入；按用户要求全部同步完成后再生成最终 merge commit
- [~] 合并无冲突，无需执行冲突解决
- [x] 不用 destructive reset 丢弃本地资料
- [x] 最终 merge commit 由承载本计划的单一提交自身完成；hash 以提交后的 `HEAD` 为准，避免自引用
- [x] 确认 `package.json` 版本为 `1.10.0`
- [x] 确认本地资料目录仍完整

### 3.3 合并后构建与源码验证

- [x] 运行 `pnpm install --frozen-lockfile`，按新 lockfile 刷新依赖
- [x] `pnpm run build`
- [x] 运行核心定向测试，共 20 files / 1913 tests 全绿：
  - [x] `test/core/archive.test.ts`
  - [x] `test/core/init.test.ts`
  - [x] `test/core/completion-tip.test.ts`
  - [x] `test/cli-e2e/completion-tip.test.ts`
  - [x] `test/core/templates/main-spec-paths.test.ts`
  - [x] `test/commands/declared-store-fallback.test.ts`
  - [x] `test/core/profiles.test.ts`
  - [x] `test/commands/config-profile.test.ts`
  - [x] `test/core/update.test.ts`
  - [x] `test/core/available-tools.test.ts`
  - [x] `test/cli-e2e/basic.test.ts`
  - [x] `test/commands/artifact-workflow.test.ts`
  - [x] `test/core/templates/propose.test.ts`
  - [x] `test/core/templates/skill-templates-parity.test.ts`
  - [x] `test/core/command-generation/adapters.test.ts`
  - [x] `test/commands/feedback.test.ts`
  - [x] `test/package-install-scripts.test.ts`
  - [x] `test/utils/change-metadata.test.ts`
  - [x] `test/core/cli-is-json-run.test.ts`
  - [x] `test/telemetry/index.test.ts`
- [x] 定向测试全绿后运行完整验证：`pnpm test` 140 files / 4076 tests 全绿，`pnpm run lint` 通过
- [x] 当前无失败；`dist/` 已先按 v1.10.0 重建

**Checkpoint C：** 本地源码、构建产物和定向测试已证明 v1.10.0 合入可用；资料同步不建立在失败源码上。

---

## 四、同步 `_digested/`

### 4.1 当前基线与覆盖矩阵

- [x] `_digested/README.md` 当前基线改为 v1.10.0 / `1ebddd1`
- [x] `_digested/_coverage/src-coverage.md` 加入 `src/core/completion-tip.ts`
- [x] 复核新增测试并写入 `_coverage/tests-coverage.md`
- [x] 复核新增 OpenSpec specs/change 并写入 `_coverage/specs-coverage.md`
- [x] 所有 coverage 行都指向实际承载机制说明的文章

### 4.2 Store-aware specs instruction

- [x] `_digested/schema/02-内置-spec-driven-详解.md`
  - [x] 补 MODIFIED step 1 使用 `<planningHome.root>/openspec/specs/...`
  - [x] 补 Purpose 直编也使用 resolved root
  - [x] 明确这是 instruction 修复，不是 archive/sync 新增 store 能力
- [x] `_digested/internal-spec-driven/02-propose-提案生成.md`
  - [x] 替换 cwd-relative main-spec 读取说法
  - [x] 说明 `planningHome.root` 来自 instructions JSON
- [x] `_digested/internal-spec-driven/05-schema-driven-控制面.md`
  - [x] 增加 specs artifact 的 root 来源
- [x] `_digested/specs_truth/01-机理-主specs如何被delta构造.md`
  - [x] 区分 agent instruction 路径和 CLI merge 路径
- [x] 复核以下已 store-aware 的文章并按需增加交叉引用：
  - [x] `_digested/workflows/07-sync.md`
  - [x] `_digested/workflows/09-archive.md`
  - [x] `_digested/internal-spec-driven/04-archive-归档合并.md`

**完成标准：** 全部“agent 生成 MODIFIED delta 前读取主 spec”的当前说明都以 `planningHome.root` 为根；没有把 nested path 或 store root误写成自动 retrieval。

### 4.3 Capability retirement 的 blocked-content 分支

- [x] `_digested/internal-spec-driven/04-archive-归档合并.md`
  - [x] 将 retirement 写成三分支决策表
  - [x] 仅缺 marker 时才提示 `retire_capabilities: true`
  - [x] 有 unaccounted content 时列出 blocking lines，marker 不是出路
  - [x] marker 存在但不可 honor 时报告具体原因
  - [x] 记录控制字符清理、长度限制和最多展示行数
- [x] `_digested/workflows/09-archive.md`
  - [x] 增加 v1.10.0 的操作性处理步骤
- [x] `_digested/spec-driven-capability/04-演进与治理.md`
  - [x] 补退役前清理 orphan sections / notes 的治理要求
- [x] `_digested/mechanisms/04-workflow-templates.md`
  - [x] 区分 agent template 与 CLI 的 content-specific refusal
- [x] `_digested/specs_truth/04-问题到方法-决策矩阵与排错.md`
  - [x] 新增“empty spec + blocking lines”排错入口
- [x] `_digested/specs_truth/06-源码锚点与缺口.md`
  - [x] 记录 `change-metadata.ts` 的 reason sanitize

**完成标准：** 文档不再暗示“空 capability archive 失败时加 marker 总能解决”。

### 4.4 `init --language` 与多语言

- [x] `_digested/spec_cli/01-human-facing-cli.md`
  - [x] 增加 `--language`
  - [x] 写明仅为新 config 种子
  - [x] 写明已有 config 时拒绝覆盖
- [x] `_digested/spec_cli/04-command-deep-dive.md`
  - [x] 解释 flag、context 和 schema 的职责边界
- [x] `_digested/spec_cli/07-command-io-matrix.md`
  - [x] 更新 init 输入和 config 写入
- [x] `_digested/internal-spec-driven/06-config-yaml-机制与约束.md`
  - [x] 新增 init flag 与手工 context 两条路径
  - [x] 明确 artifact prose 可本地化，结构 heading 与 SHALL/MUST 保持英文
  - [x] 写明空值、多行、控制字符和大小限制
- [x] `_digested/schema/02-内置-spec-driven-详解.md`
  - [x] 将多语言与 SHALL/MUST normal/strict 边界讲清

**完成标准：** 读者能判断 greenfield 用 flag、已有项目手改 config，并知道哪些结构词不能本地化。

### 4.5 Zed、OpenCode 与共享 skills 根

- [x] `_digested/mechanisms/02-tool-delivery.md`
  - [x] 增加 Zed tool id、目录、调用语法、最低版本和 trust 边界
  - [x] `.agents` ownership 从 Codex/agents 两方改为 Codex/Zed/agents 三方
  - [x] 增加 OpenCode `$ARGUMENTS` 注入和避免重复占位符的条件
- [x] `_digested/system/04-agent-contract-与工具投递.md`
  - [x] 更新三方共享根
- [x] `_digested/system/02-目录与状态边界.md`
  - [x] 加 Zed 检测路径与 managed 目录
- [x] `_digested/system/06-源码地图与扩展点.md`
  - [x] 加 Zed 和 `adapters/opencode.ts`
- [x] `_digested/spec_cli/01-human-facing-cli.md`
  - [x] tool id 示例加入 `zed`
- [x] `_digested/internal-spec-driven/00-四条命令的共有机制.md`
  - [x] 更新 shared skills 注解

**完成标准：** 不再出现“.agents 只被 Codex 和 agents 共用”的当前断言；Zed 与 OpenCode 的调用形式不混写。

### 4.6 Profile、sync 与 no-spec schema

- [x] `_digested/spec_cli/05-config-profile-delivery.md`
  - [x] core workflow 数量修正为 6，包含 `update`
  - [x] custom 选 archive/bulk-archive 时自动在前面加入 `sync`
  - [x] 已有 sync 不重复、不重排
  - [x] custom profile 不再误降级为 core
- [x] `_digested/system/04-agent-contract-与工具投递.md`
  - [x] 修复 core workflow 旧列表
  - [x] 增加 profile dependency expansion
- [x] `_digested/workflows/00-overview.md`
  - [x] core 5 → 6
  - [x] 补 custom archive 对 sync 的依赖
- [x] `_digested/internal-spec-driven/05-schema-driven-控制面.md`
  - [x] schema 不产生 specs artifact 时 `new change` 自动写 `skip_specs: true`
- [x] `_digested/schema/06-自定义-schema-实战.md`
  - [x] 增加 no-spec schema 示例和自动 marker
- [x] `_digested/spec_cli/03-workflow-runtime-api.md`
  - [x] `skipped` 的来源增加 no-spec schema
- [x] `_digested/internal-spec-driven/00-四条命令的共有机制.md`
  - [x] 同步 skipped 来源
- [x] 写明 `./specs/`、`specs/` 和 Windows separator 归一化

**完成标准：** 自定义 schema 作者不需要人为伪造 spec artifact，也不会误以为所有 `skip_specs` 都必须手写。

### 4.7 Tasks verification

- [x] `_digested/schema/02-内置-spec-driven-详解.md`
  - [x] 每个 checkbox task 内写 verification
  - [x] 只有跨多个实现 task 的验证才单列 Integration Verification
- [x] `_digested/internal-spec-driven/02-propose-提案生成.md`
  - [x] 更新 task 生成约束与示例
- [x] `_digested/internal-spec-driven/05-schema-driven-控制面.md`
  - [x] 把“可验证”具体化为 test/command/observable/artifact
- [x] `_digested/workflows/11-onboard.md`
  - [x] 与 onboard 模板的 `— verify:` 占位对齐
- [x] 明确这是 schema instruction / 生成契约，不是 `openspec validate` 新硬校验

**完成标准：** 文档示例本身遵守新规则，不能正文要求 verification、示例却仍只有“Implement X”。

### 4.8 CLI 基础设施与体验

- [x] `_digested/mechanisms/05-cli-infra.md`
  - [x] 删除现行 postinstall 机制
  - [x] 新增 completion tip 的 postAction、stderr、one-shot、defer 和 suppress 条件
  - [x] 说明 raw global-config read/write，避免 stamp profile
  - [x] telemetry first-run notice 改 stderr
  - [x] `--json` 仍 defer notice
  - [x] feedback title 截断、body 保留完整 message
- [x] `_digested/spec_cli/01-human-facing-cli.md`
  - [x] 增加 `OPENSPEC_NO_COMPLETIONS=1`
  - [x] 增加 update 的条件化 IDE restart
- [x] `_digested/spec_cli/04-command-deep-dive.md`
  - [x] 补 update restart 边界
  - [x] 评估后补充 feedback 命令条目
- [x] `_digested/spec_cli/05-config-profile-delivery.md`
  - [x] 补 update restart 条件
- [x] 明确 registry install 无 install lifecycle script，但 git/directory install 仍可能运行 `prepare`
- [x] 明确 CLI-only 工具更新不提示 restart

**Checkpoint D：[x] 通过。** `_digested/` 每个主题有一个主承载文章，coverage 可追到主文章，历史版本叙述未被误改；限定 diff、链接、结构与残留检查通过。

---

## 五、同步 `_faq_on_digested/`

### 5.1 全局入口与基线

- [x] `_faq_on_digested/README.md` 当前基线改为 v1.10.0 / `1ebddd1`
- [x] 只更新“当前源码基线”脚注；历史版本表和历史案例保留原版本
- [x] 全目录扫描 `2826b88` / `v1.9.0`，逐条分类为历史或待更新

### 5.2 FAQ 01：可执行包、安装与首次运行

- [x] `01_openspec-executable/answer.md`
  - [x] 删除现行 postinstall 链路
  - [x] 增加 CLI completion tip、stderr、defer 和 suppress
  - [x] 增加 telemetry notice 的 stderr 边界
- [x] `01_openspec-executable/ts-to-js-and-import.md`
  - [x] published files 列表删除 `scripts/postinstall.js`
- [x] 并入子问题：全局安装为何不再出现 completion 提示/allow-scripts 警告

### 5.3 FAQ 04/05/06：规划到实施

- [x] `04_propose-to-apply-ready/answer.md`
  - [x] no-spec schema 自动 `skip_specs`
  - [x] store-aware specs instruction
  - [x] tasks verification
- [x] `04_propose-to-apply-ready/answer-prp06.md`
  - [x] `planningHome.root` 的 store 语义
- [x] `04_propose-to-apply-ready/answer-agent-md-apply-03-project-schema.md`
  - [x] OpenCode `$ARGUMENTS`
- [x] `05_iterate-to-apply-ready/answer.md`
  - [x] 审视清单加入每条 task 的 verification
- [x] `05_iterate-to-apply-ready/answer-itr03.md`
  - [x] 增加“无 verification”红灯
- [x] `06_apply-ready-to-archive-ready/answer.md`
  - [x] 勾选 task 前执行其 verification
  - [x] 保持 apply pause-on-scope 结论不变

### 5.4 FAQ 07：归档与退役

- [x] `07_archive-ready-to-archived/answer.md`
  - [x] 将 retire 写成三分支
  - [x] unaccounted content 时 marker 无效
  - [x] blocking lines 与 marker reason 的安全输出
  - [x] specs instruction 与 sync/archive 均统一到 `planningHome.root`
- [x] `07_archive-ready-to-archived/answer-arc-guards.md`
  - [x] hard-stop 表增加 blocked retirement
- [x] 并入子问题：有 marker 仍因 `## Notes` 等失败时怎么办

### 5.5 FAQ 08/13：config 与多语言

- [x] `08_config-yaml-growth/question.md`
  - [x] 区分 init 不收集一般 rules 与 `--language` 快捷入口
- [x] `08_config-yaml-growth/answer-beginner.md`
  - [x] 新项目 flag、已有项目 fail、英文结构词
- [x] `08_config-yaml-growth/answer-intermediate.md`
  - [x] greenfield flag 与 brownfield 手改 context
- [x] `08_config-yaml-growth/sources.md`
  - [x] 补 init/spec/test 锚点
- [x] `13_how_to_design_maintain_config_yaml/answer.md`
  - [x] 语言 context 的落点与消费者
- [x] `13_how_to_design_maintain_config_yaml/00-initial-config-baselines.md`
  - [x] greenfield baseline 可用 `--language`
- [x] 项目案例只做当前基线校正，不机械改写历史决策

### 5.6 FAQ 09/10：自定义 schema 示例

- [x] `09_schema-agent-dev/schema-package/schema.yaml`
  - [x] 追随 v1.10 tasks verification，并同步 store-aware instruction
- [x] `09_schema-agent-dev/answer.md`
  - [x] 解释 fork 不会自动获得 upstream instruction 更新
- [x] `10_schema-requirement/schema-package/templates/tasks.md`
  - [x] 示例 task 加 verification
- [x] `10_schema-requirement/answer.md`
  - [x] 对齐 task 可验证性

### 5.7 FAQ 11/12/14/16：对齐、版本、升级

- [x] `11_keep-specs-aligned/answer.md`
  - [x] MODIFIED 修法使用 `planningHome.root`
- [x] `12_upstream-roadmap-and-issues/answer.md`
  - [x] 当前基线改 v1.10.0
  - [x] 新增 v1.10.0 已交付事实
  - [x] 不把未入 CHANGELOG 的实质提交漏掉
- [x] `14_main_specs_context_scaling/answer.md`
  - [x] 记录 store-aware instruction 修复
  - [x] 保持“不解决自动 retrieval”结论
- [x] `16_upgrade-openspec-cli-and-projects/question.md`
  - [x] 更新 v1.10.0 能力示例
- [x] `16_upgrade-openspec-cli-and-projects/answer.md`
  - [x] 全局安装无 postinstall
  - [x] 首次 CLI completion tip
  - [x] Zed 与 `.agents` 三方 ownership
  - [x] update 条件化 restart
  - [x] CLI 升级与逐项目 update 仍是两个步骤

### 5.8 明确复核、预计无需正文修改

- [~] `02_schema-article-driven/`：逐读 10 个文件；有 specs artifact，no-spec 自动 marker 不适用
- [~] `03_explore-to-propose-change/`：Explore 机制未变，仅校正当前源码基线
- [~] `15_nested_capability_migration/`：nested path 和 migration 语义未变，仅校正当前版本基线

这些条目只有在逐篇复读后才能标 `[~]`；当前“预计”不等于已验收。

**Checkpoint E：[x] 通过。** FAQ 能从用户问题进入正确答案；38 个文件完成同步，限定 diff、91 个本地链接、代码围栏、YAML 与残留检查通过。

---

## 六、同步 `_openspec_handbook/`

### 6.1 版本入口与 changelog

- [x] `_openspec_handbook/README.md`：手册 v1.8 / OpenSpec v1.10.0
- [x] `_openspec_handbook/00-index.md`
  - [x] 版本表新增手册 v1.8
  - [x] changelog 覆盖 v1.10.0 全部用户相关主题
  - [x] init 命令增加 `--language`
  - [x] tools 增加 Zed
  - [x] env 增加 `OPENSPEC_NO_COMPLETIONS`
  - [x] 不重复各深度章节的长解释

### 6.2 入门与多语言主线

- [x] `01-初级-先把-openspec-用起来.md`
  - [x] 新项目中文/其他语言的完整 init 示例
  - [x] 生成的 context 示例
  - [x] 已有项目失败与手改入口
  - [x] Zed 的入口和目录
- [x] `06-高级-config-yaml-怎么写到真正好用.md`
  - [x] 作为多语言深度单一事实源
  - [x] `init --language` 与手改 context 判断表
  - [x] 本地化 prose 与英文结构词边界
  - [x] 合法 YAML 示例
- [x] `99-FAQ-常见问题.md`
  - [x] 新增/更新多语言短答并回链 01/06

### 6.3 Store 与机器协议

- [x] `07-高级-store-跨仓库协同.md`
  - [x] 增加 store-aware main-spec 路径
  - [x] 给出错误/正确路径对照
  - [x] 给出 `instructions specs --json` 排错步骤
  - [x] 不把 root resolution 写成自动 spec retrieval
- [x] `90-附录-给机器看的-agent-协议.md`
  - [x] 基线升 v1.10.0
  - [x] instructions 字段表增加 `planningHome.root`
  - [x] 增加 store 场景 JSON 示例
  - [x] Zed skills-only
  - [x] OpenCode `$ARGUMENTS`

### 6.4 Tasks verification 与实战示例

- [x] `03-高级-openspec-的软件开发生命周期思想.md`
  - [x] tasks 定义增加 verification 脚注并回链 12
- [x] `08-高级-自定义-schema-创建自己的工作流.md`
  - [x] fork spec-driven 时同步 tasks instruction
- [x] `11-实战-从一个真实-change-走完整条主线.md`
  - [x] 至少一组 tasks 示例逐条嵌入 verification
- [x] `12-实战-如何正确修改-artifacts.md`
  - [x] 写清 schema instruction 要求与 validate 硬校验的区别
  - [x] bad/good task 对照
- [x] `13-实战-从零开始设计一个较复杂系统.md`
  - [x] 实际 tasks 示例遵守新契约
- [x] `14-实战-用-openspec-管理-devops-部署与验证.md`
  - [x] 现有 post-deploy verification 已加强为逐项验证

### 6.5 Archive retirement 与治理

- [x] `09-高级-能力身份与specs漂移维护.md`
  - [x] 退役前“可干净合并”检查
- [x] `12-实战-如何正确修改-artifacts.md`
  - [x] 带 `## Notes` 的反例
  - [x] blocking content 的三步修复
  - [x] marker cannot be honored
- [x] `15-实战-多人协作与Git工作流.md`
  - [x] 退役与在途 MODIFIED 冲突
  - [x] 退役与 orphan content 冲突
- [x] `99-FAQ-常见问题.md`
  - [x] archive 失败短答覆盖新分支

### 6.6 Tool delivery、completion、update、profile

- [x] `02-中级-把核心概念真正串起来.md`
  - [x] Codex/Zed/agents 三方共享 `.agents`
  - [x] completion 首次 stderr tip
  - [x] `OPENSPEC_NO_COMPLETIONS`
  - [x] feedback title/body 行为
- [x] `04-高级-config-schema-与项目边界.md`
  - [x] custom archive 自动依赖 sync
  - [x] no-spec schema 自动 marker
- [x] `10-实战-claude-code-里的-openspec-到底怎么落地.md`
  - [x] update 后重启是条件性的；CLI-only 工具通常不需重启
- [x] `12-实战-如何正确修改-artifacts.md`
  - [x] 不再笼统要求所有 AI 工具更新后重启
- [x] `99-FAQ-常见问题.md`
  - [x] Zed、profile sync、completion tip 可检索

### 6.7 明确复核、预计无需正文修改

- [~] `05-高级-项目级全局约束到底放哪.md`：约束分层未变，仅随跨章节契约加强 task 示例
- [~] `14-实战-用-openspec-管理-devops-部署与验证.md`：主线未变，仅加强逐项 verification
- [~] capability identity/path 主干：v1.10.0 未改变身份模型

**Checkpoint F：[x] 通过。** 19 个文件完成同步；P0 主题均有正文级示例、对照或排错步骤。最终验收覆盖三套资料 208 个 Markdown 文件中的 132 个 YAML fence，全部可解析。

---

## 七、三套资料的横向一致性检查

### 7.1 术语与行为矩阵

- [x] `--language`：三套资料都写成新项目快捷入口，不覆盖已有 config
- [x] 多语言：prose 可本地化，结构 heading 与 SHALL/MUST 保持英文
- [x] Zed：skills-only、`.agents/skills`、真实调用语法、ownership 边界一致
- [x] store path：统一使用 `planningHome.root`，且不声称自动 retrieval
- [x] tasks：每条含 verification，但 validate 不做对应硬性质量校验
- [x] retirement：marker-only、blocked-content、invalid-marker 三分支一致
- [x] completion：无 postinstall、到达 `postAction` 的 eligible run、stderr、one-shot、可抑制
- [x] telemetry：stderr；JSON 模式不污染机器输出
- [x] update restart：只在实际更新 IDE-resident surface 时提示
- [x] custom profile：archive/bulk-archive 自动依赖 sync
- [x] no-spec schema：自动 `skip_specs`，仍不能用 marker 绕过真实行为变化
- [x] feedback：title 截断不丢完整 body

### 7.2 单一事实源与交叉引用

- [x] `_digested/` 承载源码机制和边界
- [x] FAQ 回答问题并链接机制篇，不复制大段源码
- [x] handbook 承载用户做法和完整示例
- [x] handbook 多语言深文只在 06 展开，01/99 回链
- [x] handbook store path 以 07/90 为深文
- [x] archive retirement 以 internal archive / handbook 12 为深文
- [x] change log 只记录版本变化，不冒充当前操作手册

### 7.3 历史保护

- [x] 历史 `0001`–`0006` 不倒灌当前行为
- [x] 历史 roadmap、案例、版本表保留其时间语境
- [x] Claude 专篇继续使用真实 Claude 调用语法
- [x] v1.9.0 功能不被错误重写成 v1.10.0 新功能

**Checkpoint G：[x] 通过。** 两轮只读横向审计已修复 archive transaction、completion `postAction`、store path、`.agents` ownership 和 SHALL/MUST 级别等残留矛盾。

---

## 八、最终验证

### 8.1 文档结构与文本检查

- [x] `git diff --check`
- [x] 检查所有新增/修改 Markdown 本地链接（74 个 changed Markdown / 268 个本地链接）
- [x] 检查 Markdown 表格、代码块、标题层级
- [x] 检查 YAML 示例可以解析，尤其是 `context` block scalar（全量 208 Markdown / 132 YAML fences；另有 7 个 changed standalone YAML）
- [x] 检查命令示例与 v1.10.0 CLI help 一致
- [x] 检查没有把 `<planningHome.root>` 当作 shell 中可直接使用的字面目录

### 8.2 定向残留扫描

- [x] 扫描 `v1.9.0|2826b88`，逐条确认历史或当前基线残留
- [x] 扫描 `postinstall`，当前行为只能是“已移除”
- [x] 扫描 `.agents`，当前共享根不能只写 Codex/agents 两方
- [x] 扫描 `openspec/specs/<`，store/MODIFIED 语境必须解释 resolved root
- [x] 扫描 `retire_capabilities`，不能只有“加 marker”单一路径
- [x] 扫描 tasks 示例，重点检查缺 verification 的当前推荐写法
- [x] 扫描 `Restart your IDE`，确认条件化
- [x] 扫描 `/opsx:`，确认没有推广为所有宿主
- [x] 扫描 `SHALL|MUST`，确认多语言与 archive/validate 级别说法一致

### 8.3 行为验证

- [x] `openspec init --language "Portuguese (pt-BR)"` 生成预期 context
- [x] 已有 config 时 `init --language` 明确失败且不改文件
- [x] `--tools zed` 生成正确目录、marker 和 invocation
- [x] store 场景的 specs instructions 使用 `planningHome.root`
- [x] no-spec schema 的新 change 自动含 `skip_specs: true`
- [x] custom profile 仅选 archive 时实际包含 sync
- [x] OpenCode 生成命令包含 `$ARGUMENTS`
- [x] blocked retirement 报告 blocking lines，而不是只建议 marker
- [x] 到达 root `postAction` 的首次 eligible CLI run 只在 stderr 给 completion tip
- [x] `OPENSPEC_NO_COMPLETIONS=1` 可抑制 tip
- [x] JSON/非 TTY 场景不污染 stdout
- [x] update 仅更新 CLI 工具时不提示重启 IDE
- [x] feedback 长 message 在 body 中完整保留

### 8.4 版本与仓库验收

- [x] 提交前确认 `MERGE_HEAD = v1.10.0 / 1ebddd1`；单一 merge commit 创建后从最终 `HEAD` 外部验证 `git describe`
- [x] `node -p "require('./package.json').version"` 输出 `1.10.0`
- [x] 记录 PATH 中 `openspec --version`：`1.9.0`
- [x] PATH CLI 是独立环境待升级，不把它误判为 merge 失败
- [x] `git status --short` 只包含 upstream merge 和三套同步的预期文件
- [x] 复读最终 diff，确认真实 `openspec/` 规划内容只包含 upstream v1.10.0 change/spec 更新

**Checkpoint H：[x] 通过。** `build`、`lint`、140 test files / 4076 tests、CLI help、链接、YAML、残留与横向审计全部通过。

---

## 九、收尾与提交边界

- [x] 回填 `0007` 的本地 `--no-commit` merge 状态和最终验证；提交自身 hash 不能写入自身内容，以最终 `HEAD` 为准
- [x] 回填本计划所有完成项、`[~]` 理由和验证结果
- [x] 在“进度日志”写最终文件数量、测试数量和已知未解决项
- [x] 确认不存在 `[!]` 或未解释的 `[-]`
- [x] 提交前再次运行 `git diff --check`
- [x] 用户已明确要求全部同步完成后创建单一 git commit
- [~] 用户未要求 push，本次不 push

---

## 阻塞与决策

> 发生阻塞时追加记录，不覆盖旧记录。

| 日期 | 阶段 | 阻塞/决策 | 证据 | 恢复入口 |
|---|---|---|---|---|
| 2026-08-21 | 计划 | 暂无阻塞 | upstream `v1.10.0 = 1ebddd1`，工作树 clean | 从“二、建立本次同步记录”开始 |

## 进度日志

> 每次工作批次结束追加一条。必须写“完成了什么”和“下一步从哪里开始”。

### 2026-08-21 — 计划建立

- 已 fetch 并固定 upstream 范围 `2826b88..1ebddd1`
- 已审计完整 commit range，而不只依赖 v1.10.0 CHANGELOG
- 已分别审计 `_digested/`、`_faq_on_digested/`、`_openspec_handbook/` 的预期影响
- 已建立分阶段 checklist、checkpoint、中断恢复协议和最终验收矩阵
- 尚未 merge upstream，尚未修改三套资料
- 下一步：新建 `0007-v1.9.0-to-v1.10.0.md`，完成 Checkpoint B 后再合并

### 2026-08-21 — 记录建立与源码合入

- 已新增 `0007-v1.9.0-to-v1.10.0.md` 并更新 change-log 索引
- 已在 `ethan` 上执行 `git merge --no-ff --no-commit upstream/main`；自动合并无冲突，最终提交留到全部同步验收完成后
- 合并前 `HEAD` 为 `99d17682104c4c4d5e886ada187f9ab883e2d7a3`；目标仍为 `1ebddd17f40dde15dfd28289e4493c3cf05ee9df`
- `pnpm install --frozen-lockfile` 与 `pnpm run build` 通过；`dist/` 已按 v1.10.0 重建
- 20 个主题定向测试文件共 1913 tests 全绿；随后完整测试 140 files / 4076 tests 与 `pnpm run lint` 全部通过
- 手工验证 `init --language` 能生成三行 context、已有 config 时 fail 且文件不变；`--tools zed` 生成 `.openspec-target: zed` 与 `/openspec-*` skill 引用
- 内建 CLI 版本为 1.10.0；PATH 中全局 CLI 仍为 1.9.0，后者是独立环境状态
- 下一步：完成三套资料正文同步，随后执行横向审计和最终验证

### 2026-08-21 — 三套资料同步与审计修复

- `_digested/`、`_faq_on_digested/`、`_openspec_handbook/` 已按 v1.10.0 完整同步
- completion audit 发现并修复 archive 旧原子性描述、completion `postAction` 失败边界、retirement 安全输出、两处 YAML 对照示例和 `0007` 状态
- 横向审计继续修复 archive SHALL/MUST 级别、入口总览、Zed 三方 ownership 和 store-aware 排错路径
- 两轮复核后未留可执行文档缺陷
- 下一步：运行最终自动验收并创建用户要求的单一 merge commit

### 2026-08-21 — 最终验收完成

- 完整同步 diff：168 files changed，3778 insertions，994 deletions
- `pnpm run build`、`pnpm run lint`、`pnpm test`（140 files / 4076 tests）全部通过
- `git diff --check` 通过；74 个 changed Markdown 的 268 个本地链接和 fence 通过
- 三套资料共 208 个 Markdown、132 个 YAML fence 全部可解析；7 个 changed standalone YAML 也可解析
- package/checkout 版本为 1.10.0；PATH CLI 仍为 1.9.0，作为独立环境待升级
- 已知未解决项：无同步缺陷；不含 PATH 全局 CLI 升级和 push（均不在本次授权范围）
- 下一步：创建单一 merge commit；提交后验证最终 `HEAD`、`git describe` 和 clean status
