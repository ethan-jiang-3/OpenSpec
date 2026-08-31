# Plan 7：v1.9.0 同步审计清单（工作文件）

> 对照 `0006-v1.8.0-to-v1.9.0.md` 与源码逐文件核对。范围：`_digested/` + `_faq_on_digested/` + `_openspec_handbook/`。
> #1523 task-numbering 已在 0005 / `_plan-6` 覆盖，不重复当新功能。

## 状态图例
- [x] 已修复
- [ ] 待修
- [~] 确认无需修改

---

## A. `_digested/`

- [x] README 基线 → v1.9.0 / `2826b88`
- [x] `_change_log/README.md` 加入 0006
- [x] `mechanisms/02-tool-delivery.md`：Command Code + 遗留 Codex 不抢 `.agents`
- [x] `system/04`、`06`：Command Code adapter、`--archived`、shared-skill skip
- [x] `system/03`：list/bulk validate 拒绝空 implicit root
- [x] `spec_cli/01`、`02`、`04`、`07`：list/validate/schemas 命令面
- [x] `specs_truth/06`：`--archived`、scenario 认所有 `####`
- [x] `schema/02`、`08`：scenario 四级标题；fork YAML 保真
- [x] `internal-spec-driven/00` CORE_WORKFLOWS 6 条；`02` scenario 规则；`03` apply pause-on-scope；`04` archive 非 TTY / 重建空白
- [x] `workflows/06` apply guardrail；`08` validate vs `--archived`；`09` 非 TTY

## B. `_faq_on_digested/`

- [x] README 基线
- [x] FAQ 06 apply 超出范围
- [x] FAQ 07 archive 非 TTY / 重建空白 / scenario `####`
- [x] FAQ 11 validate 边界
- [x] FAQ 12 版本表 + 当前基线
- [x] FAQ 14 / 15 / 16 基线与升级提醒

## C. `_openspec_handbook/`

- [x] README + `00-index` 手册 v1.7 / OpenSpec 1.9.0
- [x] `01` 工具提示含 Command Code
- [x] `08` schema fork YAML 保真
- [x] `09` scenario / validate
- [x] `90` 机器协议基线
- [x] `99-FAQ` 工具列表、validate、apply 范围
- [x] `11`/`12`/`15` 只补会误导操作的正文

## 最终检查

- [x] 未把 #1523 写成 v1.9.0 新功能
- [x] 未误动真实 `openspec/` 或跑 `openspec write`
- [x] 收尾扫描过时 current-version 断言（含 FAQ 07/08/14/15 残留「以 v1.8.0 为当前基线」）
- [x] 未把 PATH 上的 `openspec --version` 当成 merge 已升级；e2e 需先 `pnpm run build`
