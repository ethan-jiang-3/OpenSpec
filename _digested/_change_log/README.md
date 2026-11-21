# Change Log · 上游同步记录

## 当前工作状态（从这里开始）

> **给未来的自己**：上下文会断，先读这一块，再决定做什么。不要把这张表当历史——它是**实时状态**，每次推进都要改。

| 项 | 值 |
|---|---|
| **本地源码基线** | `v2.1.1`（`0c737dc1`，2026-11-19 发布） |
| **上游是否有更新** | 已核对：`git ls-remote --tags upstream` 里 `v2.1.1` = `0c737dc1`，与本地 tag 同一对象；无更新的发行 tag |
| **源码同步提交** | `1fb874fb`（`chore: sync upstream v2.1.1`） |
| **本区间审计记录** | [`0015`](./0015-v1.17.0-to-v2.1.1.md)（v1.17.0 → v2.1.1，23 提交） |
| **当前进行中的计划** | [`_plan-14`](./_plan-14-v2.1.1-doc-complete-sync.md) — 三套资料对齐 2.1.1 |
| **计划的上游** | [`_plan-13`](./_plan-13-v2.1.1-full-sync.md)（源码同步，Phase B–D 已移交 plan-14） |
| **资料回填进度** | plan-13 与 plan-14 全部完成：首轮落点（`9e4b0dc5`、`91314d4a`、`0e80f66b`）+ 全库逐行源码精校（补齐 `0015` 第 9 组修复 `#2266` 与 `#2265` 精确判据、三套资料细节及 `_runbook` 脚本加固） |
| **机器级升级** | 14/14 个项目已从 CLI 1.15.0 升到 2.1.1，记录见 [`_runbook-machine-upgrade.md`](./_runbook-machine-upgrade.md)（含 `upgrade-all.sh` 非交互与指纹保护加固）；只剩「人工复核」 |
| **下一步** | 人工复核三套资料与 runbook 的 2.1.1 口径；之后钉下一个上游 tag 再开 `_plan-15` |

**恢复动作**（按顺序，别跳）：

```bash
git -C /Users/bowhead/OpenSpec status -sb          # 确认工作区干净、在 ethan
git -C /Users/bowhead/OpenSpec fetch upstream --tags  # 复核有没有更新的发行 tag
node bin/openspec.js --version                      # 应为 2.1.1
# 然后翻开 _plan-14，从第一个未勾选的 Phase 继续
```

**三条不能违反的约定**：基线只写在 `_digested/README.md`；`v1.x 起` 是历史、不改；handbook 受《内容宪章》约束。

---

## 同步方式（长期约定，先读这个）

**从 v1.15.0 起，新增同步只用 `git merge --squash <tag>`：不再新增真正的 `merge` 或 `rebase`。历史里已有的 merge（如 v1.14.3 的 `95b7f247`）保留不改写。**

`ethan` 是阅读消化分支，不是给上游贡献代码的分支。本分支相对目标 tag 只允许两件事：

1. **上游跟踪路径逐字节一致**：`git diff --diff-filter=MD <tag> HEAD`（M=修改，D=删除）必须为空。
2. **新增内容只放在** `_digested/`、`_faq_on_digested/`、`_openspec_handbook/`，以及根目录的 `CONTEXT.md`（FAQ 术语表，上游没有）。

因为上游从不碰这些路径，同步就只是“把目标 tag 的文件树盖上去”。squash 正好做到：代码树与 tag 一致，但不新增 upstream 血缘。再走真正的 merge 会新增 merge commit、以后每次都要处理；rebase 会改写本地提交的 hash（数量随资料提交增长）。**都不做。**

每次同步：

1. **定目标**：明确指定 tag（例如 `v1.15.0`）；不跟 `upstream/main` 漂移，tag 后 main 的提交不自动纳入。
2. `git fetch upstream --tags`
3. 先确认本地没动过源码——**用 diff，不要用 log**：

   ```bash
   git diff --stat <当前基线 tag> HEAD -- src scripts test bin build.js package.json
   ```

   必须为空。`git log <tag>..HEAD -- src …` 不能当判据：历史 merge 和 squash 提交都不在 tag 的祖先链上，这个 log 永远不空。
4. `git merge --squash <tag>`
5. 共享文件冲突一律取上游版本；本地需要的忽略项写 `.git/info/exclude`，不要改受版本控制的文件。
6. `pnpm install --frozen-lockfile && pnpm build && pnpm test`
7. 源码同步一个 commit：`chore: sync upstream <tag>`；资料回填与记录另计；不推送 upstream。

验收：

```bash
git diff --diff-filter=MD <tag> HEAD -- .   # 必须为空
git diff --stat <tag> HEAD -- src scripts test bin build.js package.json  # 也应为空
git diff --stat <tag> HEAD                  # 只应列出 _* 与 CONTEXT.md
```

> 需要讨论的只剩“这次钉到哪个 tag，然后 squash 盖上去”；历史 merge 不再重开。

这个目录记录每次从 upstream (Fission-AI/OpenSpec) 同步到本地的变更摘要。每条记录包含：

- 版本跨度（from → to）
- commit hash 范围
- 提交数量
- 核心变更分类
- 变更意义解读

目录结构：

```
_change_log/
├── README.md
├── 0001-v1.3.0-to-v1.4.1.md   # 第一次同步
├── 0002-v1.4.1-to-v1.5.0.md   # 第二次同步（stores 三合一）
├── 0003-v1.5.0-to-v1.6.0.md   # v1.6.0 + release 后 upstream 快照
├── 0004-v1.6.0-to-v1.7.0.md   # 实际源码合入 v1.7.0
├── 0005-v1.7.0-to-v1.8.0.md   # 实际源码合入 v1.8.0（agents 目标、GitHub Copilot、retire_capabilities）
├── 0006-v1.8.0-to-v1.9.0.md   # 实际源码合入 v1.9.0（Command Code、validate --archived、scenario ####、fork 保真）
├── 0007-v1.9.0-to-v1.10.0.md  # 完全同步 v1.10.0（多语言、Zed、store-aware instructions、task verification）
├── 0008-v1.10.0-to-v1.11.0.md  # 完全同步 v1.11.0（show --diff、status --all、explore 写入前确认、Antigravity → .agents/、Purpose 占位符检测）
├── 0009-v1.11.0-to-v1.13.1.md  # 完全同步 v1.13.1（validate --report findings、SourceCraft、delta parser 大修、安全加固、status Next、update draft-then-write）
├── 0010-doc-alignment-v1.11-to-v1.13.md # 资料对齐（非新同步）：回填 0008–0009 状态、补三套资料缺口、新增 FAQ 17 审阅/校验工具面、版本号 SSOT 重构
├── 0011-v1.13.1-to-v1.14.0.md  # 完全同步 v1.14.0（10 个新工具目标含 dsh、list --archived、version --check、apply 任务源定位、archive sync 阻塞语义、verify 模板重写、CRLF 保持）
├── 0012-v1.14.0-to-v1.14.3.md  # 完全同步 v1.14.3（glob 输出路径边界与引擎替换、symlink 包含、unappliedContent、500 字符升 WARNING、x- 扩展键、archive 清理错误码、CLI 按需加载、view 移除归档分区）
├── 0013-v1.14.3-to-v1.15.0.md  # 完全同步 v1.15.0（免 Node.js 的 standalone 二进制、update --dry-run/--json、feedback 对齐 bug 表单、new change 显示实际 schema、verify REMOVED 精确名）
├── 0014-v1.15.0-to-v1.17.0.md  # 完全同步 v1.17.0（历史产物指纹库与旧文件清扫、命令文件弃用预告、validate 三条收紧、version --check 语义、Node 22.12 门槛、安装改归档）
├── 0015-v1.17.0-to-v2.1.1.md  # 完全同步 v2.1.1（2.0 大版本：只装 skills 与单份共享副本、命令文件移除、delivery 退役、Amazon Q 退役；2.1 全局 skills；安装层外包给 skills 包；2.1.1 九组修复）
├── _plan-1-remaining-digested.md  # 计划 1/3：_digested/ → v1.5.0 更新
├── _plan-2-faq-on-digested.md     # 计划 2/3：_faq_on_digested/ → v1.5.0 更新
├── _plan-3-openspec-handbook.md   # 计划 3/3：_openspec_handbook/ → v1.5.0 更新
├── _v1.7.0-impact-audit.md        # v1.7.0 影响面审计

├── _plan-4-v1.7.0-current-docs.md # v1.7.0 当前资料同步计划（覆盖三个资料目录）
├── _plan-6-v1.8.0-sync-audit.md   # v1.8.0 同步审计清单（工作文件，非最终产物）
├── _plan-7-v1.9.0-sync-audit.md   # v1.9.0 当前资料同步审计
├── _plan-8-v1.10.0-full-sync.md   # v1.10.0 源码与三套资料的可恢复完全同步计划
├── _plan-9-v1.14.0-full-sync.md   # v1.14.0 源码与三套资料的可恢复完全同步计划
├── _plan-10-v1.14.x-full-sync.md  # v1.14.3 源码与三套资料的可恢复完全同步计划
├── _plan-11-v1.15.0-full-sync.md  # v1.15.0 源码与三套资料的可恢复完全同步计划
├── _plan-12-v1.17.0-full-sync.md  # v1.17.0 源码与三套资料的可恢复完全同步计划（第一步；2.x 另立 _plan-13）
├── _plan-13-v2.1.1-full-sync.md   # v2.1.1 源码与三套资料的可恢复完全同步计划（含 2.0 大版本）
├── _plan-14-v2.1.1-doc-complete-sync.md  # 三套资料对齐 2.1.1 的逐文件计划（口径基准 + 55 个重灾清单 + 可跑验收）
└── ...
```

编号递增，文件名简洁描述版本跨度。
