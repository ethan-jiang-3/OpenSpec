# 答案：两段式升级——先升全局 CLI，再对每个项目跑 `openspec update`

> **源码基线**：以 v1.8.0（`e50bd09`；release tag `v1.8.0` = `d578896`）为准。核心逻辑在 `src/core/version-check.ts`（升级命令选择 + 自升级判定）、`src/cli/index.ts` 的 `update` 命令（版本检查触发点）、`src/core/update.ts`（`UpdateCommand` 的项目内重投递）。

## 一句话结论

**OpenSpec 没有 `openspec upgrade` 命令。升级是两步：① 用你当初的安装方式升级全局 CLI（`openspec update` 在交互式 npm 全局下甚至可以替你升级并重跑）；② 对每个项目跑 `openspec update`，让新 CLI 用自己的模板重新生成该项目的 skills/commands、迁移旧目录、清理旧托管文件。顺序不能反——先升 CLI，再 update 项目；用旧 CLI 跑 update 只会重新生成旧的投递文件。**

---

## 第 1 段：升级全局 CLI

### 版本检查在什么时候、受什么门控

**只有 `openspec update` 会做 CLI 版本检查**（`getAvailableCliUpdate()` 只在 update 命令里被调用；`openspec init` 不做）。查到 npm registry 有新版本才提示。这个检查**不是默认一定发生**——`isCheckEnabled()` 会在下面任一条件下关掉它（`src/core/version-check.ts:33-42`）：

- 环境变量 `OPENSPEC_NO_UPDATE_CHECK`（显式关闭）
- `DO_NOT_TRACK=1` / `OPENSPEC_TELEMETRY=0`
- CI 环境
- `NODE_ENV=test`
- 全局 config `telemetry.enabled === false`（v1.8.0 起 telemetry 关闭会连版本检查一起关）

所以如果为了关遥测而设了 `telemetry.enabled: false`，`openspec update` 就不会再提示新版本，需要你自己留意。

### 各安装方式的升级命令

CLI 会识别自己是**怎么被装的**（`detectPackageManager()`），然后给对应命令（`GLOBAL_UPGRADE_COMMANDS`）：

| 安装方式 | 升级命令 |
|---|---|
| npm 全局 | `npm install -g @fission-ai/openspec@latest` |
| pnpm 全局 | `pnpm add -g @fission-ai/openspec@latest` |
| bun 全局 | `bun add -g @fission-ai/openspec@latest` |
| yarn 全局 | `yarn global add @fission-ai/openspec@latest` |
| volta | `volta install @fission-ai/openspec@latest` |
| npx / 临时缓存 | `npx @fission-ai/openspec@latest update`（这条命令本身就算一次完整更新） |
| 项目本地依赖 | 更新该项目的 `@fission-ai/openspec` 依赖（走该项目的包管理器） |
| git clone 源码 | 没有升级建议——版本就是分支说的，`git pull`/切 tag 即可 |

### 交互式 npm 全局：`openspec update` 可以替你升级

在**npm 全局安装 + 交互终端（stdout 是 TTY）**下，`openspec update` 检测到新版本时会直接**询问是否先升级**，确认后它替你跑 `npm install -g @fission-ai/openspec@latest`，成功后**用新 CLI 重跑 update**（`rerunUpdateWithUpgradedCli`，见 `src/cli/index.ts:249-266`）。这样本轮生成的投递文件就是新 CLI 的，不用你手工分两步。非 npm 全局（pnpm/bun/yarn/volta）、项目本地依赖、npx 缓存、源码 clone 都不会触发这个自升级，只打印命令。

---

## 第 2 段：每个项目跑 `openspec update`

### 为什么项目还要再动一次

skills/commands 是 CLI **用自己当前版本的模板生成**的，生成文件里嵌入了 `OPENSPEC_VERSION`。旧 CLI 生成的文件只描述旧工具、旧 workflow、旧语义——例如 v1.8.0 的 `--tools agents`（`.agents/skills/`）、GitHub Copilot cloud 文件、`.openspec-target` ownership marker，旧 CLI 根本不知道。所以「升级全局 CLI」≠「项目自动跟上」。

### `openspec update` 在项目里做了什么（`src/core/update.ts` 的 `UpdateCommand`）

1. **先查 CLI 更新**（见上）。
2. **迁移 legacy 工具目录**：`migrateLegacyToolDirs`（如 `.kimi` → `.kimi-code`）。
3. **迁移已安装工具**：`migrateIfNeededShared`——v1.8.0 里最典型的就是 **Codex 的 `.codex` skill 树原地迁到共享的 `.agents/skills/`**，保留用户定制文件。
4. **智能检测哪个工具该重生成**：比较项目里已生成文件的版本戳与当前 CLI 版本，只重生成过期的；全部 up-to-date 且没新工具时输出「All tools are up to date」并收工。
5. **按 delivery 重新生成**：`skills` / `commands` / `both` 由全局 config 的 `delivery` 决定。
6. **处理共享根 ownership**：`.agents` 被 `agents` 与 `codex` 共用时，用 `.openspec-target` marker 判定谁是 active writer，避免互相覆盖（`src/core/shared-skill-target.ts`）。
7. **legacy 清理**：删掉 OpenSpec 历史上留的托管文件（v1.8.0 修了 CoStrict/Junie 目录误删 bug，现在只删 `openspec-*.md` 这类可识别托管文件，**永不删用户内容**）。
8. **Copilot cloud 文件**：`openspec update` 从不提示——只刷新「已 opt-in」或「旧项目已存在 managed cloud 文件（视为隐含 opt-in）」的 Copilot 项目；用户自己改过的文件永不覆盖/删除；opt-out 只删 managed 文件。

### `--force` 什么时候用

智能检测认为 up to date、但你怀疑模板变了没触发版本戳差异时，用 `openspec update --force` 强制全部重生成。

---

## 验证

```bash
openspec --version                       # 全局 CLI 已是新版本
openspec update                          # 每个项目跑一次（或带 --force）
```

## 为什么顺序不能反

`openspec update` 是从「当前这个 CLI」的模板生成文件的。**先跑 update、后升 CLI** = 用旧 CLI 生成旧文件，等于白做，升完还得再跑一遍。所以正确姿势是：先升全局 CLI（或让 `openspec update` 的交互提示替你升），**升完再对每个项目跑一次 `openspec update`**。

## v1.8.0 的具体提醒（来自变更日志 0005）

`git merge` 拉进 v1.8.0 源码只会改 `git describe` 和 `package.json` 版本，**不会**改变 PATH 上的 CLI。要让 `--tools agents`、`--copilot-cloud`、`retire_capabilities` 真正可用，每台机器的全局 CLI 都要独立升级到 v1.8.0，然后各项目 `openspec update`（见 [`0005-v1.7.0-to-v1.8.0.md`](../../_digested/_change_log/0005-v1.7.0-to-v1.8.0.md) 的「验收基线」）。

## 相关材料

- 投递层总论（init/update/delivery/tool 目录）：[`../_digested/spec_cli/01-human-facing-cli.md`](../_digested/spec_cli/01-human-facing-cli.md)、[`../_digested/spec_cli/05-config-profile-delivery.md`](../_digested/spec_cli/05-config-profile-delivery.md)
- 工具投递与共享根/ownership marker：[`../_digested/mechanisms/02-tool-delivery.md`](../_digested/mechanisms/02-tool-delivery.md)
- 升级命令选择 + 自升级判定：`src/core/version-check.ts`（`GLOBAL_UPGRADE_COMMANDS`、`canSelfUpgrade`、`shouldOfferUpgrade`）
- update 命令入口 + 触发点：`src/cli/index.ts`（`update` 命令的 `.action`）
- 项目内重投递：`src/core/update.ts`（`UpdateCommand`）、`src/core/shared-skill-target.ts`
