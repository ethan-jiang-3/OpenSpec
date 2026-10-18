# 附录 A · CLI 命令面与配置面

[← 返回索引](answer.md) ｜ 上一篇：[05 · 可复跑验证](05-verification.md)

全部由 `--help` 实测 dump，非凭记忆。

---

## A.1 顶层命令

```text
version      版本 + 更新可用性
init         初始化项目（--tools／--language／--force／--profile／--no-animation）
update       重新投递 instruction 文件（--force）
list         清单（--specs｜--changes｜--archived｜--all｜--sort recent|name｜--json｜--store）
view         交互式 dashboard
change       show ｜ list(DEPRECATED) ｜ validate        ← 没有 graph
archive      归档并更新主 specs
spec         show ｜ list ｜ validate
config       path ｜ list ｜ get ｜ set ｜ unset ｜ reset ｜ edit ｜ profile
schema       which ｜ validate ｜ fork ｜ init            [experimental]
store        setup ｜ register ｜ unregister ｜ remove ｜ list ｜ doctor
doctor       根 / 仓 / 引用关系健康（--store｜--json）
context      打印解析后的工作上下文（--store｜--json｜--code-workspace｜--force）
workset      create ｜ list ｜ open ｜ remove             （纯本地个人视图）
validate     校验（--all｜--changes｜--specs｜--archived｜--report｜--type｜--strict｜--json｜--concurrency｜--store）
show         查看（--json｜--type｜--deltas-only｜--requirements-only｜--diff｜--requirements｜--no-scenarios｜-r｜--store）
status       artifact 完成状态（--change｜--all｜--schema｜--json｜--store）
instructions artifact / apply / archive 的增强指令（--change｜--schema｜--json｜--store）
templates    显示 schema 各 artifact 的模板路径
schemas      列出可用 schema
new change   创建 change（--description｜--goal｜--schema｜--json｜--store）
feedback ／ completion
```

> `workset` 的自我定位是 *"Compose, keep, and open personal working views (purely local)"*【实测】——**面向人的编辑器窗口组合，不是 agent 上下文注入通道**。本篇没有把它算作线 A 的机制。

---

## A.2 按 profile 投递的 workflow

```text
core（默认）      explore  propose  apply  update  sync  archive
expanded（可选）   + new  continue  ff  verify  bulk-archive  onboard
```

- 集合定义【实测：`src/core/profiles.ts:14`】：`CORE_WORKFLOWS = ['propose','explore','apply','update','sync','archive']`
- 默认值【实测：`src/core/global-config.ts:45`】：`profile: 'core'`
- 启用 expanded：`openspec config profile` → `openspec update`
- **CLI 命令不受 profile 影响**，始终可用

---

## A.3 配置面

```text
openspec/config.yaml
  schema     默认 workflow schema
  context    每个 artifact 都注入；50 KB 上限，超限【整个字段丢弃】
  rules      按 artifact id 分流注入；键对不上所有 schema 的 artifact id 时 warning

<change>/.openspec.yaml          （zod strict）
  schema              必填
  created             YYYY-MM-DD
  goal                可选目标
  affected_areas      可选
  skip_specs          声明无 spec 级行为变化；与 specs/ 下文件冲突则硬 ERROR
  retire_capabilities 声明可能退役 capability；删除的唯一通道
  initiative          legacy 键仍在 schema 里，但 CLI 已拒绝设置（--initiative 报错）

openspec/schemas/<name>/
  schema.yaml         artifact DAG：requires / generates / instruction / template
                      apply.requires / apply.tracks
  templates/*.md      各 artifact 模板
```

---

## A.4 明确**不属于**自带能力

写在这里是为了不被复用：

```text
✗ openspec/work/**                    上游团队管理自己项目的产物；src/ 引用数 0
  ├─ goal.md / roadmap.md / runbook.md
  ├─ slices/*/{spec,plan,result,log}.md
  ├─ capstone/**                      （含 32-agent 对抗式 gauntlet）
  └─ slices/delete-legacy-command-groups/deletion-ledger.md

✗ openspec/initiatives/**             运行时实现已由 PR #1190 删除
  └─ .initiative.yaml, direction.md, decisions.md, questions.md, work-items/**

✗ openspec/explorations/**            代码里标注 'legacy exploration directory'

✗ test/vocabulary-sweep.test.ts       守 OpenSpec 自己的 src/，对用户项目无作用

✗ openspec/changes/add-change-stacking-awareness/   未落地提案（卡在 3/4）

✗ 需要外部补的能力（不要误当成自带）
  ├─ 多 change 能力重叠检测
  ├─ 跨 change 依赖图 / archive 排序
  └─ artifact 新鲜度失效（"改了 proposal 要让 tasks 变陈旧"）
```

**这些可以学它的做法**（例如上游用 goal→roadmap→slice 分层 + 决策日志 + 删除台账来管方向，思路值得抄），**但工具不会替你执行任何一条**。

---

[← 返回索引](answer.md)
