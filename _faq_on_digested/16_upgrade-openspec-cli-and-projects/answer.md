# 升级与迁移：CLI 与项目（答案）

# 答案：两段式升级——先升全局 CLI，再对每个项目跑 `openspec update`

> **源码基线**：以 [`../../_digested/README.md`](../../_digested/README.md) 声明的「当前源码基线」为准。核心逻辑在 `src/core/version-check.ts`（升级命令选择 + 自升级判定）、`src/cli/index.ts` 的 `update` 命令（版本检查触发点）、`src/core/update.ts`（`UpdateCommand` 的项目内重投递）。

## 一句话结论

**OpenSpec 没有 `openspec upgrade` 命令。升级是两步：① 用你当初的安装方式升级全局 CLI（交互式 npm 全局、默认 registry 下 `openspec update` 可以替你升级并重跑；standalone 用 `openspec install`）；② 对每个项目先 `openspec update --dry-run` 预演，再跑 `openspec update`，让新 CLI 用自己的模板重新生成该项目的 skills/commands、迁移旧目录、清理旧托管文件。顺序不能反——先升 CLI，再 update 项目；用旧 CLI 跑 update 只会重新生成旧的投递文件。**

---

## 第 1 段：升级全局 CLI

### 版本检查在什么时候、受什么门控

**自动的 CLI 版本检查只发生在 `openspec update`**（`getAvailableCliUpdate()` 只在 update 命令里被调用；`openspec init` 不做）。另有一个**手动入口**：`openspec version --check`，它走同一个 `checkForCliUpdate()`，同样受下面这套门控（例如 `CI=1` 时会直接输出 `Update check disabled.`）。查到 npm registry 有新版本才提示。这个检查**不是默认一定发生**——`isCheckEnabled()` 会在下面任一条件下关掉它（`src/core/version-check.ts:67`）：

- 环境变量 `OPENSPEC_NO_UPDATE_CHECK`（显式关闭）
- `DO_NOT_TRACK=1` / `OPENSPEC_TELEMETRY=0`
- CI 环境
- `NODE_ENV=test`
- 全局 config `telemetry.enabled === false`（v1.8.0 起 telemetry 关闭会连版本检查一起关）
- 全局 config 读不出来/解析失败（`isGlobalConfigUnreadable()`）——无法解析的配置里可能正藏着上面那条关闭项，所以宁可不发请求

所以如果为了关遥测而设了 `telemetry.enabled: false`，`openspec update` 就不会再提示新版本，需要你自己留意。

### 各安装方式的升级命令

CLI 会识别自己是**怎么被装的**（`getCliInstallInfo()` 的 scope/packageManager；standalone 走 `getStandaloneBinaryPath()`），然后给对应命令（`GLOBAL_UPGRADE_COMMANDS`；standalone 为 `openspec install`）：

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
| standalone 单文件（v1.15.0+） | `openspec install`（原地重装；`version --check` 会给出这条命令） |

v1.15.0 起 CLI 也可能是 standalone 安装：`openspec version` 会标 `(standalone)`，`--json` 的 `install.scope` 为 `standalone`，升级命令是 `openspec install`（若 PATH 上的 `openspec` 是别的副本，会给带全路径的重装命令）。standalone 不需要 Node.js；npm 等包管理器方式需要 Node.js **22.20.0+**（v2.1.1 起；v1.16.0–v2.1.0 是 22.12.0；Node 20 已 EOL，且只有 Node 20 上的 npm 安装受影响）。

### 交互式 npm 全局：`openspec update` 可以替你升级

在**npm 全局安装 + 交互终端（stdout 是 TTY）**下，`openspec update` 检测到新版本时会直接**询问是否先升级**，确认后它替你跑 `npm install -g @fission-ai/openspec@latest`，成功后**用新 CLI 重跑 update**（`rerunUpdateWithUpgradedCli`，见 `src/core/version-check.ts:936`；调用点在 `src/cli/index.ts:413`）。这样本轮生成的投递文件就是新 CLI 的，不用你手工分两步。非 npm 全局（pnpm/bun/yarn/volta）、项目本地依赖、npx 缓存、源码 clone 都不会触发；**`npm_config_registry` 指向非官方源时也不会**（`canSelfUpgrade()` 里的 `isDefaultRegistry()` 检查）——企业私有镜像/npmrc 场景下别等这个提示这个自升级，只打印命令。

---

## 第 2 段：每个项目跑 `openspec update`

### 为什么项目还要再动一次

skills/commands 是 CLI **用自己当前版本的模板生成**的，生成文件里嵌入了 `OPENSPEC_VERSION`。旧 CLI 生成的文件只描述旧工具、旧 workflow、旧语义——例如 v1.9.0 的 Command Code / `validate --archived`，或 v1.8.0 的 `--tools agents`（`.agents/skills/`）、GitHub Copilot cloud 文件、`.openspec-target` ownership marker，旧 CLI 根本不知道。所以「升级全局 CLI」≠「项目自动跟上」。

### `openspec update` 在项目里做了什么（`src/core/update.ts` 的 `UpdateCommand`）

1. **先查 CLI 更新**（见上）。
2. **迁移 legacy 工具目录**：`migrateLegacyToolDirs`（如 `.kimi` → `.kimi-code`）。
3. **迁移已安装工具**：`migrateIfNeededShared`——v1.8.0 里最典型的就是 **Codex 的 `.codex` skill 树原地迁到共享的 `.agents/skills/`**，保留用户定制文件。
4. **智能检测哪个工具该重生成**：比较项目里已生成文件的版本戳与当前 CLI 版本，只重生成过期的；全部 up-to-date 且没新工具时输出「All tools are up to date」并收工。
5. **按 delivery 重新生成**（1.x）：`skills` / `commands` / `both` 由全局 config 的 `delivery` 决定。**v2.0.0 起 `delivery` 退役**（#2223）：一律装 skills，配置里不再有这一项，command 文件不再生成。
6. **处理共享根 ownership**：`.agents/skills` 被 `agents`、`codex` 与 v1.10.0 的 `zed` 三方共用时，用 `.openspec-target` marker 判定谁是 active writer，避免互相覆盖（`src/core/shared-skill-target.ts`）。调用形式一律走技能名：Claude Code 等用 `/openspec-<name>`，Zed 用 `/openspec-*` 或 `@openspec-*`，Codex 用 `$openspec-*`，不要混写。（1.x 的 `/openspec-*` command 文件在 2.0 已移除。）
7. **legacy 清理**：删掉 OpenSpec 历史上留的托管文件（v1.8.0 修了 CoStrict/Junie 目录误删 bug，现在只删 `openspec-*.md` 这类可识别托管文件，**永不删用户内容**）。**v1.17.0 起判据升级为内容指纹**：只有“内容等于某个已发布版本原样写出过”的文件才会被当作无主旧产物；路径上任何一段是链接就完全不碰，即使加 `--force`。
8. **清扫旧版本产物**（v1.17.0）：删掉“当前版本根本不会写”的路径上、且没人编辑过的文件（同一套指纹判据），并回收留下的空目录。这一步让 `update` 能从 **0.12 以来任意版本一次跑完**。
9. **命令弃用提示**（v1.17.0，历史形态；该函数在 2.0 已删除）：若某个已配置工具仍会得到 command 文件，打印一条「2.0 移除，建议现在切 skills」的提示。
9b. **移除 command 文件**（v2.0.0 #2223）：不再生成，按指纹清理早期版本留下的——没人改过的删掉，改过的保留并列出。skills 收成 `.agents/skills/` 单份真身，其他工具目录放链接（建不了链接退化为拷贝）。
10. **Copilot cloud 文件**：`openspec update` 从不提示——只刷新「已 opt-in」或「旧项目已存在 managed cloud 文件（视为隐含 opt-in）」的 Copilot 项目；用户自己改过的文件永不覆盖/删除；opt-out 只删 managed 文件。

### 先预演：`openspec update --dry-run`

v1.15.0 起，真跑之前可以先看计划：`openspec update --dry-run` 列出会 `add`/`update`/`delete` 的文件、归属 tool、交互式运行会问的步骤（`notes`）以及会失败的工具（`failures`，不中断其余计划）；不写任何文件。`--json` 给机器读，且只能与 `--dry-run` 同用。预演和真实更新走同一条写入路径，不是两套逻辑——预演通过不代表真实一定成功（权限/竞态仍可能失败），但计划内的新增/修改/删除不会漏报。

### `--force` 什么时候用

智能检测认为 up to date、但你怀疑模板变了没触发版本戳差异时，用 `openspec update --force` 强制全部重生成。

**v1.17.0 起，清理旧文件不再需要 `--force`**：以前 `update` 会因为“检测到 legacy 产物”而要求 `--force` 或终端确认，现在只要这些文件**没人编辑过**就直接删——因为指纹证明里面没有用户内容。还剩两个要 `--force` 的地方：`~` 里的共享 prompt 文件（同一台机器多个项目共用，不替它们擅自决定）、以及别处仍在使用但你想强制清掉的情形。工具更新失败时整个清扫会跳过，旧文件保留。

---

## 验证

```bash
openspec --version                       # 全局 CLI 已是新版本
openspec version --check                 # 看安装形态与升级命令（standalone 会给 openspec install）
openspec update --dry-run                # 先预演：会改/删哪些文件
openspec update                          # 每个项目跑一次（或带 --force）
```

## 为什么顺序不能反

`openspec update` 是从「当前这个 CLI」的模板生成文件的。**先跑 update、后升 CLI** = 用旧 CLI 生成旧文件，等于白做，升完还得再跑一遍。所以正确姿势是：先升全局 CLI（或让 `openspec update` 的交互提示替你升），**升完再对每个项目跑一次 `openspec update`**。

## 升级的爆炸半径：会波及别的项目吗

**结论先说**：`openspec update` **只动你运行它的那个项目**，加上全局配置；如果一个项目从没用过 OpenSpec，它不会被创建、也不会被修改。但**一旦你装了全局技能，就会有跨项目共享面**——这是 2.1 唯一真正的「副作用」。

### 不会被波及的

| 情形 | 为什么 |
|---|---|
| 别的、你没运行过 `update` 的项目 | `update` 不接受「批量升级所有项目」的入口；它只处理当前路径 |
| 从没用过 OpenSpec 的项目 | 不会被创建 `openspec/`；那是 `init` 的动作，`update` 不做 |
| 你机器上的项目清单 `projects.json` | 它**只写不读**。`init`/`update` 会记下自己跑过哪里，但生产代码里没有任何地方读这个清单去遍历别的目录（`readKnownProjects` 只在测试里被调用）。所以它不会变成「自动升级所有项目」的开关 |

### 会波及的：全局技能

如果你选过全局作用域，技能落在**用户级目录**（例如 Claude Code 的 `~/.claude/skills/`，由 `skills` 包定义），不在任何项目里。于是：

- 这些技能会出现在你**每一个** Claude Code 会话的技能列表中，**包括完全没用过 OpenSpec 的仓库**
- 之后在**任意项目**里跑 `openspec update`，都会顺带刷新这套全局技能（`update` 检测到机器上有全局技能就刷新，这是设计行为）

### 为什么实际风险比你担心的小

技能自带一道**项目检查守卫**（`src/core/templates/workflows/project-root.ts` 的 `PROJECT_ROOT_GUARD`）：任何会写文件的动作之前，先跑 `openspec list --json` 读 `root`。

- `root` 是对象 → 项目正常，继续
- `root: null` → **这里没有 `openspec/`**，技能**停下，不创建、不修改任何文件**

而且区分两种进入方式：

- **agent 自己选中的技能**（你没提 OpenSpec）→ 它放弃 OpenSpec，按普通请求回答，不打扰你
- **你点名调用的技能** → 它会停下来问你：在这里 `openspec init`、用 `--store` 指定 store、还是不用 OpenSpec

所以**不会有一个陌生仓库被偷偷塞进 `openspec/` 目录**。唯一的「痕迹」是技能出现在列表里。

### 想彻底隔离就选项目作用域

```bash
openspec init --scope project          # 装进当前项目
# 或写进 openspec/config.yaml：skillsScope: project
```

项目作用域的技能只在这个仓库生效，别处看不见，也不会因为别处跑 `update` 而被改。

> **注意默认值**：非交互（CI、agent 调用）下不传 `--scope` 时**默认是 global**。想让技能跟仓库走，必须显式指定。

## 版本细节（按版本拆到独立文件）

主线只讲**现在该怎么做**；每个版本的具体提醒单独成篇，因为不同版本的做法不一样，混在一处读不出重点。

| 版本 | 文件 | 关键内容 |
|---|---|---|
| v2.0.0 – v2.1.1 | [`releases/v2.0-v2.1.md`](releases/v2.0-v2.1.md) | 命令文件移除、skills 单份共享、delivery 退役、Amazon Q 退役、全局技能 |
| v1.16.0 – v1.17.0 | [`releases/v1.16-v1.17.md`](releases/v1.16-v1.17.md) | 指纹库与旧文件清扫、`--force` 不再必需、validate 三条收紧 |
| v1.15.0 | [`releases/v1.15.md`](releases/v1.15.md) | standalone 安装、`update --dry-run` |
| v1.13.2 – v1.14.3 | [`releases/v1.13-v1.14.md`](releases/v1.13-v1.14.md) | glob 工件路径、symlink 边界、`x-` 扩展键 |
| v1.12.0 – v1.13.1 | [`releases/v1.12-v1.13.md`](releases/v1.12-v1.13.md) | delta parser 大修、`validate --report`、安全加固 |
| v1.10.0 – v1.11.0 | [`releases/v1.10-v1.11.md`](releases/v1.10-v1.11.md) | 多语言、`.agents` 共享根、`show --diff` |
| v1.9.0 | [`releases/v1.9.md`](releases/v1.9.md) | Command Code、`validate --archived` |

## 相关材料

- 投递层总论（init/update/delivery/tool 目录）：[`../../_digested/spec_cli/01-human-facing-cli.md`](../../_digested/spec_cli/01-human-facing-cli.md)、[`../../_digested/spec_cli/05-config-profile-delivery.md`](../../_digested/spec_cli/05-config-profile-delivery.md)
- 工具投递与共享根/ownership marker：[`../../_digested/mechanisms/02-tool-delivery.md`](../../_digested/mechanisms/02-tool-delivery.md)
- 升级命令选择 + 自升级判定：`src/core/version-check.ts`（`GLOBAL_UPGRADE_COMMANDS`、`canSelfUpgrade`、`shouldOfferUpgrade`）
- update 命令入口 + 触发点：`src/cli/index.ts`（`update` 命令的 `.action`）
- 项目内重投递：`src/core/update.ts`（`UpdateCommand`）、`src/core/shared-skill-target.ts`
