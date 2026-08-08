# Plan 6：v1.8.0 同步审计清单（工作文件，非最终产物）

> 对照 `0005-v1.7.0-to-v1.8.0.md` 与源码逐文件核对。**发现即修，修完勾选。**
> 范围：`_digested/` + `_faq_on_digested/` + `_openspec_handbook/`。

## 状态图例
- [x] 已修复
- [ ] 待修 / 待确认
- [~] 确认无需修改（记录理由）

---

## A. `_digested/`

### A1. `internal-spec-driven/00-四条命令的共有机制.md`
- [x] A1-1 status JSON 示例缺 `isPlanningComplete`（现仅 `isComplete`；v1.8.0 主字段是 `isPlanningComplete`，`isComplete` 是兼容别名）
- [x] A1-2 status 关键字段列表缺 `isPlanningComplete` 说明
- [x] A1-3 actionContext 示例与源码不符：`mode: "repo"`→`"repo-local"`；`sourceOfTruth: "openspec/"`→`"repo"`；`allowedEditRoots: ["."]`→`[projectRoot]`；缺 `planningArtifacts`/`linkedContext`/`requiresAffectedAreaSelection`；constraints 内容与 `buildActionContext` 不一致
- [x] A1-4 `CORE_WORKFLOWS` 写 5 个（`propose/explore/apply/sync/archive`），源码已是 6 个（含 `update`：`['propose','explore','apply','update','sync','archive']`）
- [x] A1-5 skills 段补 `.agents` 共享根 + `.openspec-target` 说明

### A2. `specs_truth/06-源码锚点与缺口.md`
- [x] A2-1 L47 主 spec 校验措辞：SHALL/MUST 放宽为 guidance（正文缺失 ERROR / 正文在缺关键字 WARNING）；scenario 仍是 Zod ERROR（非 WARNING，按源码修正）
- [x] A2-2 L48 change delta：SHALL/MUST 放宽（normal WARNING / strict 强制）；scenario 仍是 ERROR
- [x] A2-3 L50 "从不打开主 spec"→"不跨文件对账"；补 scenario-loss 前置检测例外
- [x] A2-4 validate 参考补 scenario-loss 前置检测说明

### A3. `system/06-源码地图与扩展点.md`
- [x] A3-1 投递层表加 `shared-skill-target.ts`、`github-copilot/`
- [x] A3-2 "加新的 coding agent" 补共享根 ownership 说明
- [x] A3-3 repo-local 核心表补 `src/core/validation/`（validator.ts / task-numbering.ts）

### A4. `schema/02-内置-spec-driven-详解.md`
- [x] A4-1 L17 SHALL/MUST 标注为 guidance（normal WARNING / strict 强制 / 正文缺失 ERROR）

### A5. `spec_cli/`、`system/`、`mechanisms/`、`internal-spec-driven/` 其余
- [~] A5-1 `spec_cli/02-machine-facing-cli.md`（status 概念层，无字段清单）——`$openspec-*` 仍正确，无需改
- [~] A5-2 `spec_cli/04-command-deep-dive.md`、`07-command-io-matrix.md`——角色性描述，无 v1.8.0 硬性过时
- [~] A5-3 `system/02-目录与状态边界.md`——已含 v1.8.0 `.agents` 说明（实际已同步）
- [~] A5-4 `system/01/03/05/07/08`、`mechanisms/00-map`、`spec-driven-capability/*`——概念层，无硬性过时
- [~] A5-5 init 新 flag（`--tools agents`/`--tools all`/`--copilot-cloud`/`--no-copilot-cloud`）已在 `mechanisms/02-tool-delivery.md` 覆盖（L81/L84/L161），spec_cli/01 有通用 `--tools` 说明——覆盖合理
- [~] A5-6 `workflows/03-new`、`11-onboard`——无 v1.8.0 敏感内容，无需改

### A6. 扫尾追加（"从不打开主 spec" 残留）
- [x] A6-1 `_openspec_handbook/09` L156 同句修正（validate 不做跨文件对账 + MODIFIED 例外）
- [x] A6-2 `_faq_on_digested/11_keep-specs-aligned/answer.md` L118 "从不打开主 spec"→"不跨文件对账"，补 scenario-loss 例外
- [x] A6-3 `_digested/specs_truth/figures/overview.svg`、`drift-gaps.svg` 文字微调（"基本不读主 spec（MODIFIED 例外 / 仅 scenario-loss）"）

---

## B. `_faq_on_digested/`（逐条核，已过一部分）
- [x] B1 tool delivery 答案：12_upstream 已含 v1.8.0（`.agents/skills`、`agents` 目标、Copilot、MiniMax/Rovo）；无 `.codex` 残留
- [x] B2 archive 答案：07 已含 retire_capabilities、可重跑命令、exit 1、scenario-loss 前置、重复 canonical 名拒绝（answer.md L130/L335）
- [x] B3 validate 答案：07 answer.md L130 已覆盖 SHALL/MUST 放宽 + scenario-loss 前置
- [x] B4 status 答案：12_upstream 已含 isPlanningComplete
- [~] B5 config/telemetry 答案：FAQ 无 telemetry/copilot 章节（仅 12_upstream 一笔带过），config-yaml FAQ 不声称 config 面穷举，无需补
- [~] B6 README 一致性：后续与 handbook 一起复核

## B2. `_digested/` explore 相关（补充发现）
- [x] B2-1 `internal-spec-driven/01-explore` 第五节补 v1.8.0 scaffold-first 捕获规则
- [x] B2-2 `workflows/01-explore` 补 v1.8.0 提示与指针

---

## C. `_openspec_handbook/`（逐条核，已完成）
- [x] C1 入门：01 已含 v1.8.0 提示（Codex `.agents/skills`、`$openspec-*`）；99-FAQ 工具清单修正（Windsurf→Devin、补 v1.8.0 工具行）
- [x] C2 archive 实战：99-FAQ 已含 `retire_capabilities`
- [x] C3 validate 章节：09 三处修正（validate 不再"从不打开主 spec"、SHALL/MUST 为 guidance）；00-index validate 行、15-实战 validate 声称修正
- [x] C4 90-附录 status JSON 示例改写为真实形状（changeName/artifacts[]/isPlanningComplete/nextSteps/actionContext；旧 `todo/in_progress/nextRecommended` 移除）
- [~] C5 README / 00-index / 版本日志：版本表正确（v1.6 对齐 1.8.0），无新增章节故不加版本行；README 待最后核对

---

## 最终检查
- [x] `git diff` 复核无错漏（14 个文件，+60/-48，语义逐条核对源码）
- [x] 确认未误动真实 `openspec/` 或跑 `openspec write` 类命令（记忆约束）——只改了 `_digested/`/`_faq_on_digested/`/`_openspec_handbook/`
- [x] 已提交（`9d8f3b9`）
- [x] 三处 README 基线正确（v1.8.0 / `e50bd09` / `d578896`）；00-index 版本表正确（v1.6 对齐 1.8.0），本次为版本内勘误不新增版本行

---

## D. 三大主题覆盖核对（用户指定重点，提交后追加）

### 主题1：retire_capabilities
- [x] D1-1 `_digested/spec-driven-capability/04-演进与治理.md`：原"删除 main spec 目录不是 archive 的高阶语义"与 v1.8.0 矛盾 → 改写为 retire_capabilities 机制 + 与 in-flight MODIFIED 冲突提示
- [x] D1-2 其余覆盖已确认到位：`04-archive`（L328）、`workflows/09-archive`（L11）、`mechanisms/04`（L80）、FAQ `07/12/15`、handbook `99-FAQ Q16`/`00-index`

### 主题2：archive 可靠性（可重跑 / exit1 / 重复名 / note-loss）
- [x] D2-1 `04-archive` L329-331 已完整覆盖（重复 canonical 名、note-loss、可重跑+exit1）——无需改
- [x] D2-2 `workflows/09-archive`（L11）、`mechanisms/04`（L80）、FAQ `07`（L335）已覆盖 rerun/exit1——无需改
- [x] D2-3 handbook `99-FAQ Q16` 补"失败/被卡两种出路"：retire 完整说明（含 git checkout 恢复、--no-validate 不触发）+ 非交互可重跑命令

### 主题3：task-progress 缩进子任务（共享 parser）
- [x] D3-1 `internal-spec-driven/03-apply` 3.1-3.3：旧正则 `^[-*]\s*\[([ xX])\]\s*(.+)\s*$` + `parseTasksFile()` → 共享 `parseTaskLines()`（`/^\s*[-*]\s*\[([\sxX])\]\s*(.*)/`），补缩进子任务说明
- [x] D3-2 `internal-spec-driven/02-propose` L242-249：旧正则 → 共享 parser + 缩进说明
- [x] D3-3 `internal-spec-driven/07-config-yaml` L180/L183：`parseTasksFile()` → `parseTaskLines()`，parser 识别范围更新
- [x] D3-4 `internal-spec-driven/04-archive` 2.3：补共享 parser + 子任务计入
- [x] D3-5 FAQ `06/answer-app03` L108-121/L168、`answer-sequence` L48/L186/L216：旧正则 + `parseTasksFile()` → 共享 parser
- [~] D3-6 `workflows/06-apply` L129 已覆盖（同步时已加）；handbook 11/12 为概念层无旧正则声称，无需改

## D4. handbook 深度补漏（用户指出"更新严重不够"后的第二遍正文核查）
- [x] D4-1 确认问题模式：同步只在每章顶部加 v1.8.0 提示块，正文读者遇到旧行为处未改 → 逐个正文核查
- [x] D4-2 `12-实战-修改artifacts` 第 3 节修改表：`specs/<capability>/spec.md` 行补 retire（REMOVED 拿掉最后一个 requirement → `retire_capabilities: true`）；`tasks.md` 行补缩进子任务计入；`.openspec.yaml` 行补 retire 与 schema 并存
- [x] D4-3 `11-实战-change走主线` 第 5 步（tasks）：补 v1.8.0 缩进子任务计数提示 + 四命令共享 parser
- [x] D4-4 `15-实战-多人协作` 场景 3：补"退役 vs 在途 MODIFIED"冲突（validate 通过 / archive 拒绝 target spec does not exist）
- [x] D4-5 `90-附录-agent协议`：instructions 示例字段名对齐真实形状（`change`→`changeName`、`outputPath`→`resolvedOutputPath`、dependencies 对象化 + unlocks）
- [~] D4-6 核对无需改：01/02/03/04/05/06/07/08/10/13/14 正文无 v1.8.0 硬性过时（validate/SHALL/status/archive 声称已逐条扫过）；ch10 已含 `.agents` 共享根；ch01 init 工具选择由 ch10 覆盖
