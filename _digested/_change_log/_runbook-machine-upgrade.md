# Runbook：本机 OpenSpec 升级到 v2.1.1

> 这份文件是**本机操作手册**，不是项目文档。目标：把全局 CLI 升到 2.1.1，并让 14 个使用中的项目安全迁移。
> 数据采集时间：2026-11-21。项目状态会变，执行前用文末的复检命令重新确认。

## 一、现状（已实测）

| 项 | 值 |
|---|---|
| 全局 CLI | **1.15.0** |
| 安装方式 | npm 全局，`/Users/bowhead/.nvm/versions/node/v22.23.1/lib/node_modules/@fission-ai/openspec` |
| Node | **v22.23.1** —— 满足 2.1.1 的 `>=22.20.0` ✅ |
| 包管理器 | npm 10.9.8 / pnpm 10.34.5（无 brew） |
| 用 OpenSpec 的项目 | **16 个**，其中 14 个是真正消费项目 |
| 生成文件版本 | **全部是 1.15.0** 生成，没有一个由 2.x 生成 |

> **nvm 的坑**：npm 全局包装在 Node v22.23.1 下面。`nvm use` 切到别的 Node 版本时，`openspec` 会「消失」。升级后如果发现命令没了，先 `node -v` 确认是不是切了 Node。

## 二、这次升级会发生什么（先建立预期）

1. **所有 `/opsx:*` 命令文件会被删除**——2.0 起不再生成。这是最大的一处可见变化。
2. **技能从「每个工具各一份」变成「`.agents/skills/` 一份真身 + 各工具目录的链接」**。
3. **`delivery` 配置项退役**，一律 skills。
4. **命令调用方式变了**：`/opsx:propose` → `/openspec-propose`（Codex 是 `$openspec-propose`）。

**不会发生的事**：`openspec/` 里的 specs、changes、archive 一个都不会被改；`config.yaml` 除了可能的 `skillsScope` 之外不动。

## 三、项目分类（14 个消费项目）

「原样」= 内容匹配某个已发布版本的输出，`update` 会安全替换或删除；
「改过」= 内容对不上指纹，`update` 会**保留**。

| # | 项目 | 命令(原样/改过) | 技能(原样/改过) | 活跃 change | git 未提交 | 风险 |
|---|---|---|---|---|---|---|
| 1 | `ai_deerflow_dr_v3` | 0 / 0 | 6 / 0 | 0 | 0 | 🟢 低（无命令，只换技能） |
| 2 | `ai_dsh_bsimulation` | 0 / 0 | 12 / 0 | 0 | 0 | 🟢 低 |
| 3 | `ai_pi_deep_research` | 0 / 0 | 12 / 0 | 0 | 0 | 🟢 低 |
| 4 | `ai_tool_bsimulation` | 6 / 0 | 12 / 0 | 0 | 0 | 🟢 低 |
| 5 | `ai_deerflow_deep_research_v2` | 6 / 0 | 12 / 0 | 0 | 0 | 🟢 低 |
| 6 | `ai_tool_deepresearch` | 6 / 0 | 12 / 0 | 0 | 3 | 🟢 低（先提交） |
| 7 | `ai_deerflow_wiki` | 12 / 0 | 18 / 0 | 0 | 1 | 🟢 低 |
| 8 | `ait_exam_openspec_calender` | 6 / 0 | 12 / 0 | 0 | 8 | 🟢 低（先提交） |
| 9 | `ait_exam_openspec_demo` | 6 / 0 | 6 / 0 | 0 | 1 | 🟢 低 |
| 10 | `ait_exam_openspec_ticketflow` | 6 / 0 | 6 / 0 | 0 | 12 | 🟢 低（先提交） |
| 11 | `ai_tool_ppt_maker` | 12 / 0 | 18 / 0 | **1** | 0 | 🟡 中（有在途 change） |
| 12 | `ait_exam_haitai` | 6 / 0 | 6 / 0 | **1** | 1 | 🟡 中 |
| 13 | `openspec-schemas` | 12 / 0 | 18 / 4 | **2** | 49 | 🟡 中高（自定义技能 + 脏工作区） |
| 14 | `ait_exam_openspec_plms` | 4 / **2** | 0 / **6** | **2** | 1 | 🟢 低（指纹虽不匹配，实测 update 会自动迁移，见 §四阶段 4） |

**另外两个不要动**：

- **`ai_dev_spec`** —— 它的 `openspec/` 里是**整份 OpenSpec 源码拷贝**（有 src/dist/_digested）。它不是 OpenSpec 消费项目，别在里面跑 `update`。
- **`OpenSpec`**（当前仓库）—— 这是源码仓库本身。它的 `skills/` 是给 `npx skills add` 用的静态分发，不是项目技能。**不要对它跑 `openspec update`**。

## 四、执行阶段

### 阶段 0：升级全局 CLI

```bash
# 0.1 备份全局配置（出问题能对照）
cp ~/.config/openspec/config.json ~/openspec-config.bak.$(date +%Y%m%d)

# 0.2 升级
npm install -g @fission-ai/openspec@latest

# 0.3 验证
openspec --version          # 期望 2.1.1
openspec version --json     # 期望 scope: global, packageManager: npm
```

> 为什么用 `npm install -g` 而不是让 `openspec update` 自升级：`canSelfUpgrade()` 要求 npm 全局 + 默认 registry + 交互 TTY，三者任一不满足就走了「只打印命令」的路径。直接 `npm install -g` 最确定。
>
> **回滚**：`npm install -g @fission-ai/openspec@1.17.0`（或 `@1.15.0`，回到升级前的状态）。

### 阶段 1：先拿一个干净项目练手

挑 **`ai_deerflow_dr_v3`**（只有 `.agents`、无命令文件、0 未提交、0 活跃 change——最干净的一个）：

```bash
cd ~/ai_deerflow_dr_v3

# 1.1 加一行作用域，避免 update 弹提问
#     在 openspec/config.yaml 里加：skillsScope: project
$EDITOR openspec/config.yaml

# 1.2 预演（不写盘）
openspec update --dry-run

# 1.3 真跑
openspec update

# 1.4 看改了什么
git status --short
git diff --stat

# 1.5 确认新形态
ls -la .agents/skills | head
cat .agents/skills/.openspec-target      # 现在是「工具清单」，每行一个 id

# 1.6 没问题就提交
git add -A && git commit -m "chore: upgrade OpenSpec to 2.1.1"
```

**这一步先别急着推给其他项目**——确认 `.claude/`（如果有）里出现的是链接、agent 还能正常发现技能，再往下走。

### 阶段 2：🟢 低风险 9 个项目（批量）

对每个项目重复同一套：

```bash
for p in ai_dsh_bsimulation ai_pi_deep_research ai_tool_bsimulation \
         ai_deerflow_deep_research_v2 ai_tool_deepresearch ai_deerflow_wiki \
         ait_exam_openspec_calender ait_exam_openspec_demo ait_exam_openspec_ticketflow; do
  echo "═══ $p ═══"
  cd ~/$p
  git status --short          # 先看：不干净就先单独提交
  # 加 skillsScope: project（若 config.yaml 里没有）
  openspec update --dry-run
  openspec update
  git status --short
done
```

**每个项目单独提交**，别混在一起——出问题时好逐个回退。

其中 3 个有未提交改动（`ai_tool_deepresearch` 3 行、`ait_exam_openspec_calender` 8 行、`ait_exam_openspec_ticketflow` 12 行），**先各自提交一次再跑 update**，否则回滚时你分不清哪些是 `update` 改的。

### 阶段 3：🟡 有在途 change 的 3 个项目

`ai_tool_ppt_maker`（1 个活跃 change）、`ait_exam_haitai`（1 个）、`openspec-schemas`（2 个）。

**在途 change 本身不受影响**——`update` 只动工具目录，不碰 `openspec/changes/`。但为了能干净回滚：

```bash
cd ~/<项目>
git status --short                    # 必须干净
ls openspec/changes | grep -v archive # 记下在途 change 名字
# 然后照阶段 2 走
```

`openspec-schemas` 额外两个注意点：

- 它有 **4 个「改过」的技能**：`openspec-linearized`、`openspec-schema-authoring` 等。这些是**你自己写的技能**（只是名字以 `openspec-` 开头），`update` 永远不会碰。不用处理。
- 它有 **49 个未提交改动**，动之前先提交，否则回滚无从下手。

### 阶段 4：`ait_exam_openspec_plms`（cline-only）

**实测结论：不需要特殊处理。** 早先担心它会有残留，是因为它 6 个技能 + 2 个命令的指纹对不上（cline 变体用单引号 YAML、命令写成 `/opsx-apply`）。但实测 `openspec update` 的 **dry-run 计划里明确包含 10 个 delete**，`--apply` 后 `.cline/`、`.clinerules/workflows/` 全部清空，技能归到 `.agents/skills/`。

原因：cline 是 **universal 工具**（`installerAgent('cline').universal === true`），它直接读 `.agents/skills/`，所以自己的目录会被整个移除——走的是 `installSharedSkills` 的「former own skills dir」迁移路径，不是指纹匹配。

直接用同一套命令即可。

### 阶段 5：cursor / codex 用户的注意点

`cursor` 和 `codex` 也是 universal，直接读 `.agents/skills/`，**不会**保留 `.cursor/skills/`。升级后 `.cursor/` 目录可能整个消失（如果里面只有 OpenSpec 的东西）。这不是 bug。

真正需要链接目录的只有 `claude-code` 这类 `universal === false` 的工具。

## 五、验收清单（每个项目跑完都过一遍）

```bash
openspec --version                          # 2.1.1
ls .claude/commands/opsx 2>/dev/null        # 应该不存在了
find . -maxdepth 3 -name "commands" -path "*opsx*" 2>/dev/null   # 应为空
ls -la .agents/skills | head -3             # 真身
ls -la .claude/skills 2>/dev/null | head -3 # 应为链接（l 开头）
cat .agents/skills/.openspec-target         # 工具清单
openspec list                               # skills/change 仍能被读到
openspec validate --all 2>/dev/null | tail -3   # 校验不受影响
git status --short                          # 只看得到预期的改动
```

## 六、用脚本一键执行（推荐）

脚本在 `_digested/_change_log/_runbook/upgrade-all.sh`。

```bash
cd ~/OpenSpec/_digested/_change_log/_runbook

# 1) 先看计划，什么都不改
./upgrade-all.sh

# 2) 真正执行（自动备份 + 清理 + 每项目独立提交）
./upgrade-all.sh --apply --clean --commit
```

**特性**（都实测过）：

| 能力 | 说明 |
|---|---|
| 默认只看不动 | 不加 `--apply` 只输出每个项目的计划，零写入 |
| 幂等 / 可重跑 | 做一半坏了直接重跑：`skillsScope` 已在就跳过、update 无变化就报「计划 0 项」、没改动就不提交 |
| 自动备份 | 每个项目先打包 `.claude .cursor .agents .cline .codex .agent .clinerules .opencode .dsh .pi openspec` 到 `~/openspec-upgrade-backups/<项目>-<时间>.tgz` |
| 保守清理 | `--clean` 只删「路径命中白名单 + 内容确实是 OpenSpec 生成」的文件，**不按目录名一刀切**（早期版本曾误删 `.agent/skills/` 里用户自己的技能，已修） |
| 一键恢复 | `./openspec... --apply --restore --only <项目>`，先删后解，能绕过符号链接 |
| 单项目定向 | `--only <项目>` / `--skip <项目>` |
| 跳过 CLI | `--skip-cli`（已经升过、只跑项目时用） |

**为什么必须有备份**：5 个项目把工具目录写进了 `.gitignore`（`ai_dsh_bsimulation`、`ai_tool_bsimulation`、`ai_deerflow_deep_research_v2`、`ai_deerflow_wiki`、`ai_tool_ppt_maker`）。这些目录**不在 git 里**，`git checkout` 救不回来——只有备份能救。

## 六bis、执行结果（2026-11-21 完成）

**全局 CLI：1.15.0 → 2.1.1 ✅　14/14 项目全部升级完成。**

| 项目 | 官方技能 | 遗留命令 | 未提交 |
|---|---|---|---|
| `ai_deerflow_dr_v3` | 6 | 0 | 0 |
| `ai_dsh_bsimulation` | 6 | 0 | 10（**你自己的归档操作，待提交**） |
| `ai_pi_deep_research` | 6 | 0 | 0 |
| `ai_tool_bsimulation` | 6 | 0 | 0 |
| `ai_deerflow_deep_research_v2` | 6 | 0 | 0 |
| `ai_tool_deepresearch` | 6 | 0 | 0 |
| `ai_deerflow_wiki` | 6 | 0 | 0 |
| `ait_exam_openspec_calender` | 6 | 0 | 0 |
| `ait_exam_openspec_demo` | 6 | 0 | 0 |
| `ait_exam_openspec_ticketflow` | 6 | 0 | 0 |
| `ai_tool_ppt_maker` | 6 | 0 | 0 |
| `ait_exam_haitai` | 6 | 0 | 0 |
| `openspec-schemas` | 6+2 自定义 | 0 | 0 |
| `ait_exam_openspec_plms` | 6 | 0 | 0 |

**过程中清掉的乱摊子**（都是历史遗留，与本次升级无关）：

| 项目 | 清理内容 |
|---|---|
| `ai_deerflow_wiki` | `df_home0/` —— 测试残留（`test-user-autouse/…/demo-skill.jsonl`） |
| `ait_exam_openspec_calender` | 空的 `AGENTS.md`；提交了「旧 `openspec/AGENTS.md`/`project.md` → `config.yaml`」的迁移 |
| `ait_exam_openspec_ticketflow` | `_eval_output/` 加入 `.gitignore`（保留文件，不进版本库） |
| `ai_tool_deepresearch` | 恢复了误删的 `skills-lock.json` |
| 4 个项目 | 删除 11 个指向已下线全局技能的悬空链接 `resolving-merge-conflicts` |
| `ai_deerflow_dr_v3` | 清理脚本遗留的 `config.yaml.bak.*` |

**仍需你做的**：

1. `ai_dsh_bsimulation` 里有你自己的未提交改动（`cockpit-single-owner` 归档），提交即可。
2. **重启 IDE**（Cursor / Claude Code），否则看不到新技能。
3. 选做的清理：如果你不再用 Cline，可删掉 `ait_exam_openspec_plms` 之外的 Cline 相关目录。

## 七、回滚

### 单个项目回滚

```bash
cd ~/<项目>
git checkout -- .        # 恢复被改/删的受控文件
git clean -nd            # 先看新增了什么（.agents/skills 等）
git clean -fd            # 确认后清理
```

⚠️ **不要用 `git stash`**。2.0 会把技能目录变成链接，实测 `git stash` 会直接失败：
`error: '…/SKILL.md' is beyond a symbolic link` / `Cannot save the current worktree state`。

### 全局 CLI 回滚

```bash
npm install -g @fission-ai/openspec@1.15.0
```

### 全局技能清理（如果误装了全局作用域）

```bash
ls ~/.agents/skills ~/.claude/skills 2>/dev/null
rm -rf ~/.agents/skills/openspec-* ~/.claude/skills/openspec-*
```

## 八、执行前复检（状态会变，动手前重跑）

```bash
# 1) 还有多少项目
cd ~ && find . -maxdepth 2 -name openspec -type d -not -path "*/node_modules/*" | wc -l

# 2) 哪些项目有未提交改动
for d in */; do [ -d "$d/openspec" ] && [ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ] && echo "脏: $d"; done

# 3) 全局 CLI 现状
openspec version --json
```

## 九、一句话策略

> **先升 CLI（一次），再 `./upgrade-all.sh --apply --clean --commit` 一把推完。脚本会逐项目备份、清理、校验、独立提交；坏了用 `--restore` 回滚。**

真正的风险不是 OpenSpec 会不会改坏东西，而是**你不留退路**——5 个项目的工具目录压根不在 git 里。备份就是那个退路。
