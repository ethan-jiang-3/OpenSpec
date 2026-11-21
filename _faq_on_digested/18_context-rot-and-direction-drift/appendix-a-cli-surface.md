# 附录 A · CLI 命令面与配置面

[← 返回索引](answer.md) ｜ 上一篇：[05 · 可复跑验证](05-verification.md)

全部由 `--help` 与 `src/cli/index.ts`（含 `src/cli/commands/*.ts`）核对，非凭记忆。

---

## A.1 顶层命令与完整子命令 / 旗标

```text
全局选项      --no-color ｜ -V, --version ｜ -h, --help

version       版本 + 更新可用性（--json｜--check）
init [path]   初始化项目（--tools｜--language｜--force｜--profile｜--no-animation
                        ｜--copilot-cloud｜--no-copilot-cloud｜--scope global|project）
update [path] 重新投递技能文件（--force｜--dry-run｜--json）
install       安装/切换 standalone 单文件（[version]）
list          清单（--specs｜--changes｜--archived｜--all｜--sort recent|name｜--json｜--store）
view          交互式 dashboard（--store）
change        [DEPRECATED 名词组]                         ← 没有 graph
  show [name]     --json｜--deltas-only｜--requirements-only(DEPRECATED)｜--diff｜--no-interactive
  list            --json｜--long                          [DEPRECATED]
  validate [name] --strict｜--json｜--no-interactive
archive [id]  归档并更新主 specs（-y, --yes｜--skip-specs｜--no-validate｜--json｜--store）
spec          [DEPRECATED 名词组]
  show [id]       --json｜--requirements｜--no-scenarios｜-r, --requirement <id>｜--no-interactive
  list            --json｜--long
  validate [id]   --strict｜--json｜--no-interactive
config        全局配置（组级选项 --scope global）
  path            显示配置文件路径
  list            --json
  get <key>       读取键
  set <k> <v>     --string｜--allow-unknown
  unset <key>     移除键
  reset           --all｜-y, --yes
  edit            用 $EDITOR / $VISUAL 打开
  profile [preset] 交互勾选或预设快捷方式（当前唯一预设为 core）
schema        工作流 schema 管理 [experimental]
  which [name]    --json｜--all
  validate [name] --json｜--verbose
  fork <src> [id] --json｜--force
  init <name>     --json｜--description｜--artifacts｜--default｜--no-default｜--force
store         多仓注册 store 管理
  setup [id]      --path｜--init-git｜--no-init-git｜--remote｜--json
  register [path] --id｜--yes｜--json
  unregister <id> --json
  remove <id>     --yes｜--json
  list (别名 ls)  --json
  doctor [id]     --json
doctor        根 / 仓 / 引用关系健康（--store｜--json）
context       打印解析后的工作上下文（--store｜--json｜--code-workspace｜--force）
workset       纯本地个人工作视图（隐藏组级 --json 用于错误契约）
  create [name]   --member（可重复）｜--tool｜--json
  list (别名 ls)  --json
  open <name>     --tool
  remove <name>   --yes｜--json
validate [id] 校验（--all｜--changes｜--specs｜--archived｜--report full|findings
                  ｜--type change|spec｜--strict｜--json｜--concurrency <n>｜--no-interactive｜--store）
show [id]     查看（--json｜--type change|spec｜--no-interactive｜--deltas-only
                  ｜--requirements-only｜--diff｜--requirements｜--no-scenarios｜-r, --requirement <id>｜--store）
status        artifact 完成状态（--change｜--all｜--schema｜--json｜--store）
instructions  [artifact|apply|archive] 的增强指令（--change｜--schema｜--json｜--store）
templates     显示 schema 各 artifact 的模板路径（--schema｜--json）
schemas       列出可用 schema（--json｜--store）
new change    new change <name>（--description｜--goal｜--schema｜--json｜--store；
                               隐藏拒绝项 --initiative｜--areas）
feedback      feedback <message>（--body）
completion    Shell 补全管理
  generate [shell]
  install [shell]   --verbose
  uninstall [shell] -y, --yes

隐藏命令（{ hidden: true }，不在 --help 列出）：
  experimental  init 的已弃用别名（--tool｜--no-interactive）
  __complete    __complete <type>（供已生成的补全脚本按 Tab 调用的内部入口）
```

> `workset` 的自我定位是 *"Compose, keep, and open personal working views (purely local)"*【实测】——**面向人的编辑器窗口组合，不是 agent 上下文注入通道**。本篇没有把它算作线 A 的机制。
>
> 另注：「command 文件已移除」指的是 AI 编程工具里由 OpenSpec 1.x 生成的 `/opsx:*` 斜杠命令文件（2.0 起只装 skills），**不是**上表这些 CLI 子命令——`openspec validate` / `archive` / `update` 等 CLI 命令始终存在。

---

## A.2 按 profile 投递的 workflow

```text
core（默认）      propose  explore  apply  update  sync  archive
custom（可选）    通过 openspec config profile 交互勾选（最多全部 12 项 ALL_WORKFLOWS）：
                  + new  continue  ff  verify  bulk-archive  onboard
```

- 集合定义【实测：`src/core/profiles.ts:14,19`】：`CORE_WORKFLOWS = ['propose','explore','apply','update','sync','archive']`，`ALL_WORKFLOWS` 共 12 项
- 默认值【实测：`src/core/global-config.ts:52`】：`profile: 'core'`（合法值仅有 `'core' | 'custom'`，不存在 `expanded` 预设）
- 启用额外 workflow：`openspec config profile`（交互勾选保存为 `custom`）→ `openspec update`
- **CLI 命令不受 profile 影响**，始终可用

---

## A.3 配置面

```text
openspec/config.yaml        （8 个顶层键：3 个散文投递面为软能力，5 个结构键由 CLI 硬解析）
  ── 面向写作 / 执行的散文投递面（除 50 KB 上限与 #2127 YAML 语法校验外，内容全部是软 prompt）──
  context    每个 artifact + apply + archive 都注入；50 KB 硬上限，超限【整个字段丢弃】
  rules      按 artifact id 分流注入；内置 id 为 proposal/specs/design/tasks【实测】
             ⚠ 按全部可用 schema 的 artifact id 并集对账；错键 warning 只走 stderr、
               只有 instructions 触发，validate --all 不报（instruction-loader.ts:385）【实测】
             ⚠ 单条写错（如行首未加引号的 ## 被 YAML 当注释）会让该 artifact
               的整组 rules 失效并回落到「忽略」【实测】
  operations 除 context 外唯一进入 apply/archive 指令输出的专属操作指导【实测】
    apply.guidance      → instructions apply   --json 的 operationGuidance
    archive.guidance    → instructions archive --json 的 operationGuidance
    ⚠ 只支持 apply|archive 两个 id；archive.ts 不读它（readProjectConfig 调用数 0）
    ⚠ 与 rules 分工：rules 管产物内容，guidance 管做事方式

  ── 结构性配置键（由 CLI 代码硬解析执行，但同样不检查方向语义；#2127 让 validate 对不可读/非法 YAML 直接 exit 1）──
  schema                    新 change 的默认 workflow schema（解析顺序第 3 位）
  references                跨仓 store 索引，50 KB 二分截断
  store                     仅 config-only 根时用作默认 store 指针回退
  githubCopilot.cloudAgent  是否生成 GitHub Copilot 云代理文件的布尔开关
  skillsScope               'project' | 'global'：记录项目技能保留在仓库内，供 openspec update 读取免重复询问

<change>/.openspec.yaml          （zod strict）
  schema              必填
  created             YYYY-MM-DD
  goal                可选目标（仅存储，无校验用途）
  affected_areas      可选；status 的 requiresAffectedAreaSelection 恒为 false【代码】
  skip_specs          声明无 spec 级行为变化；与 specs/ 下文件冲突则硬 ERROR
  retire_capabilities 声明可能退役 capability；删除的唯一通道
  initiative          legacy 键仍在 schema 里，但 CLI 已拒绝设置（--initiative 报错）
  x-*                 扩展键：不算 unknown，OpenSpec 忽略【代码】

内置 spec-driven 的四个 artifact（无需自定义 schema）：
  proposal  proposal.md      requires: []
  specs     specs/**/*.md    requires: [proposal]      ← generates 是 glob
  design    design.md        requires: [proposal]
  tasks     tasks.md         requires: [specs, design]
  ⚠ 没有 direction / decision 之类的「意图层」artifact；方向活在
    proposal.md 的 ## Why + ## What Changes，且内置能力对其内容零检查【实测】
  ⚠ specs 是 glob：status --json 的 resolvedOutputPath 保留 ** 字面量，
    真实文件要看 existingOutputPaths【实测】

openspec/schemas/<name>/          （仅在你选择自定义 schema 时才有）
  schema.yaml         artifact DAG：requires / generates / instruction / template
                      apply.requires / apply.tracks
                      ⚠ generates 是存在性契约：同一文件可被多个 artifact 复用，
                        复用会让后置 artifact 白拿一个 done【实测】
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

✗ openspec/changes/add-change-stacking-awareness/   曾提案但未落地（已在 PR #2128 删除）

✗ 需要外部补的能力（不要误当成自带）
  ├─ 多 change 能力重叠检测
  ├─ 跨 change 依赖图 / archive 排序
  └─ artifact 新鲜度失效（"改了 proposal 要让 tasks 变陈旧"）
```

**这些可以学它的做法**（例如上游用 goal→roadmap→slice 分层 + 决策日志 + 删除台账来管方向，思路值得抄），**但工具不会替你执行任何一条**。

---

[← 返回索引](answer.md)
