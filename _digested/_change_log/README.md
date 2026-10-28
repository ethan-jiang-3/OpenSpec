# Change Log · 上游同步记录

## 同步方式（长期约定，先读这个）

**永远不要对 upstream 做真正的 `merge` / `rebase`；同步一律 `git merge --squash <tag>`。**

`ethan` 是阅读消化分支，不是给上游贡献代码的分支。本分支相对目标 tag 只允许两件事：

1. **上游跟踪路径逐字节一致**：`git diff --diff-filter=MD <tag> HEAD`（M=修改，D=删除）必须为空。
2. **新增内容只放在** `_digested/`、`_faq_on_digested/`、`_openspec_handbook/`，以及根目录的 `CONTEXT.md`（FAQ 术语表，上游没有）。

因为上游从不碰这些路径，同步就只是“把目标 tag 的文件树盖上去”。squash 正好做到：代码树与 tag 一致，但不留下 upstream 血缘。真正的 merge 会多出 merge commit、以后每次都要处理；rebase 会改写 270+ 本地提交的 hash。**都不做。**

每次同步：

1. **定目标**：明确指定 tag（本次 `v1.15.0`）；不跟 `upstream/main` 漂移，tag 后 main 的提交不自动纳入。
2. `git fetch upstream --tags`
3. `git log --oneline <tag>..HEAD -- src scripts test bin build.js package.json` → 应为空；有输出说明本地动过源码，先停下来查清。
4. `git merge --squash <tag>`
5. 共享文件冲突一律取上游版本；本地需要的忽略项写 `.git/info/exclude`，不要改受版本控制的文件。
6. `pnpm install --frozen-lockfile && pnpm build && pnpm test`
7. 一个 commit：`chore: sync upstream <tag>`；不推送 upstream。

验收：

```bash
git diff --diff-filter=MD <tag> HEAD -- .   # 必须为空
git diff --stat <tag> HEAD                  # 只应列出 _* 与 CONTEXT.md
```

> 这里没有“怎么 merge 上游”的问题。只有“这次钉到哪个 tag，然后 squash 盖上去”。

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
└── ...
```

编号递增，文件名简洁描述版本跨度。
