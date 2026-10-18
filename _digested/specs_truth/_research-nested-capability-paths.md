# 嵌套／层次化 capability path：源码核验（2026-07-29）

> **当前基线（2026-07-29）**：本 checkout 已合入 upstream v1.7.0 `4e16790`，PATH 中实际执行的全局 `openspec` 也已核验为 v1.7.0。本笔记只以该正式发布版说明当前行为与建议。

> **v1.8.0 同步（2026-08-08）**：nested capability path 语义在 v1.8.0 不变（path namespace、非 retrieval）；源码链接保留到 v1.7.0 作为原始核验锚点，当前行为以 v1.8.0 为准。

> **v1.14.3 复核（本轮同步）**：nested 语义仍未变——目录是命名空间、无继承/聚合/自动 retrieval，`identity` 与 `identity/session` 是两个独立 capability。下面三条历史约束逐条复核结果：
> - 跳过隐藏目录 —— **仍成立**（`spec-discovery.ts:40`、`:100` `entry.name.startsWith('.')`）
> - 不追踪**目录** symlink —— **仅对"递归发现"成立，措辞需要收紧**（见下）
> - 根目录直放的 `openspec/specs/spec.md` 被忽略 —— **仍成立**
>
> **但有一条新增**：v1.14.2（#2052）/ v1.14.3（#2101）起，**`spec.md` 文件本身可以是 symlink**，会被解析（`spec-discovery.ts:19` 注释：`A symlinked \`spec.md\` IS resolved`）。本文其余结论不受影响。
>
> ### 更正：目录 symlink 不是"完全不支持"，而是"枚举看不见、按 ID 能访问"
>
> 原文只写"不追踪目录 symlink"，容易被读成"符号链接的 capability 目录不可用"。**三轮实测（v1.14.3）显示要分成三件事**：
>
> | 操作 | 目录 symlink（`openspec/specs/linkcap -> ../../docs/x`） | 证据 |
> |------|------------------------------------------------|------|
> | `openspec list --specs`（递归枚举） | **不列出** `linkcap`，只列真实目录 | 实测输出只有 `realcap requirements 1` |
> | `openspec show linkcap --type spec` / `validate linkcap --type spec` | **正常工作**，读出 `requirementCount: 1`、报 `Specification 'linkcap' is valid` | 按 ID 走 `path.join(specsDir, id, 'spec.md')`，不经过枚举 |
> | `openspec archive <change>` 写入该 capability | **穿透写入**真实目标文件，且**保留 symlink 本身** | 归档后 `docs/x/spec.md` 的 requirement 从 1 条变 2 条，`openspec/specs/linkcap` 仍是 symlink |
>
> 所以准确说法是：**枚举层不跟进目录链（所以它不会出现在列表里），但按 ID 的读写路径会穿透链接**。想让一个 symlink 目录出现在 `list --specs` 里，目前做不到；想读写它，只要知道 ID 就行。

## 结论

**可以做，而且做对后很有价值；但要分清“源码已实现”“正式 release 可用”“官方默认推荐”这三件事。**

1. **v1.7.0 完整支持 nested main specs。** `specs/<domain>/<capability>/spec.md` 会被递归发现，delta 使用相同路径，并可经 list / show / validate / apply / archive 的正常生命周期处理。
2. **层次是命名空间，不是有继承语义的 spec 树。** `identity` 与 `identity/session` 是独立 capability ID；父目录不会自动聚合、继承或推导依赖。
3. **它是可采用的大项目组织能力，但不是默认 agent instruction 的唯一推荐布局。** 团队应在 `config.yaml` / AGENTS 明确 `<domain>/<capability>` 约定，避免 agent 重新创建 flat 的同义 capability。

## 它在代码中的准确语义

在包含 #1355 的源码中，共用的 [`discoverSpecFiles()`](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/utils/spec-discovery.ts#L4-L63) 会递归发现任意深度的 `spec.md`，并把**相对于 `specs/` 的目录路径**作为 capability ID，统一用 `/`：

```text
openspec/specs/identity/session/spec.md
                 └──────────────┘  ID = identity/session
```

它不是“一个大 spec 内的章节层级”，也不是有继承、聚合或自动依赖推导的 domain model：目录只是路径命名空间；工具把每个 `spec.md` 当成一个独立 capability。父目录也可以同时有自己的 `spec.md`，此时 `identity` 和 `identity/session` 是两个独立 ID；代码没有赋予它们额外的父子语义。

约束也很具体：根目录直接放的 `openspec/specs/spec.md` 被忽略；隐藏目录跳过；**递归发现不跟进目录 symlink**（但按 ID 的读写会穿透，见上方更正块）。[helper L11-L25、L37-L55](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/utils/spec-discovery.ts#L11-L25)。官方测试覆盖 flat、nested、正斜杠 ID、root-file exclusion 和 symlink 行为。[`spec-discovery.test.ts`](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/test/utils/spec-discovery.test.ts#L22-L165)。

## 生命周期是否完整

在 #1355 后，答案是“针对正常 CLI 路径，完整”：

| 动作 | 源码行为 |
|---|---|
| `list` / interactive `show` / `validate --specs` | `getSpecIds()` 调共享递归发现器，因此 ID 会列为 `identity/session`。[`item-discovery.ts` L29-L33](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/utils/item-discovery.ts#L29-L33) |
| `show identity/session`、单项 validate | 消费者以 `path.join(specsDir, id, 'spec.md')` 定位，所以 slash ID 会落到 nested 文件。[`spec.ts` L80-L121](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/commands/spec.ts#L80-L121)；[`validate.ts` L194-L211](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/commands/validate.ts#L194-L211) |
| change delta parse / validate | 同一递归发现器扫描 `changes/<change>/specs/**/spec.md`。[`change-parser.ts` L57-L66](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/parsers/change-parser.ts#L57-L66)；[`validator.ts` L137-L166](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/validation/validator.ts#L137-L166) |
| `archive` / apply | delta ID 被保持原样，target 是 `mainSpecsDir/<ID>/spec.md`；写入前递归创建父目录。故 delta 与 main spec 必须使用**同一个相对路径**。[`specs-apply.ts` L48-L77](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/specs-apply.ts#L48-L77)；[写入 L456-L475](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/specs-apply.ts#L456-L475)；[`archive.ts` L437-L446](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/archive.ts#L437-L446) |

例如：

```text
openspec/specs/
  identity/
    login/spec.md
    session/spec.md
  billing/
    invoices/spec.md

openspec/changes/add-session-refresh/specs/
  identity/
    session/spec.md       # archive 的 target 正是 specs/identity/session/spec.md
```

可用命令是 `openspec list --specs`、`openspec show identity/session --type spec --json`、`openspec validate identity/session --type spec --strict`，以及正常的 `openspec archive add-session-refresh`。

## 是不是官方“推荐”布局？

**推荐 domain 分组这个方向，但尚未成为统一的 agent 默认。** 人类文档建议大代码库按 domain 分组，并说 monorepo 的 domain 可映射 package/service。[`existing-projects.md` L103-L119](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/docs/existing-projects.md#L103-L119)。但当前默认 schema 和生成的 propose/sync/archive workflow 仍教 agent 写 flat 的 `specs/<capability>/spec.md`。[`schema.yaml` L62-L65](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/schemas/spec-driven/schema.yaml#L62-L65)；[`propose.ts` L15-L20](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/templates/workflows/propose.ts#L15-L20)。这正是仍 open 的 [#1459](https://github.com/Fission-AI/OpenSpec/issues/1459)：作者确认代码已支持 nested，但 agent-facing guidance 尚未跟上。

所以合理结论不是“官方已把层次结构定成默认最佳实践”，而是：**它是已实现、适合较大项目的组织能力；团队要在自己的 `config.yaml` / AGENTS 指令中明确本项目的 path convention，避免 agent 又新建 flat 同义 capability。**

## 怎么用才对

1. **当前环境可采用 nested layout。** 本 checkout 与 PATH CLI 均为 v1.7.0，已经满足全部生命周期支持的条件；迁移既有 flat capability 时仍要按下述受控 rebaseline 执行。
2. **按“独立行为合同、独立修改频率”拆，而不是按页数硬切。** 例如 `identity/login` 与 `identity/session` 可独立变更；若两个 requirement 总是共同修改、共同验证，则拆开只会增加必须同时阅读的 spec 数量。
3. **路径是 capability identity，改路径等于改 ID。** `auth` → `identity/login` 没有内建 capability-rename；一条仍在 `changes/*/specs/auth/spec.md` 的 delta 会继续指向旧 ID。把迁移当成受控 rebaseline：冻结/处理触及旧 ID 的 active changes，`git mv` main spec，同行移动或重建这些 delta，更新文档/catalog/引用，然后运行 `list --specs`、`validate --specs --strict` 和每个受影响 change 的 validate。不要让普通 archive 顺便承担重命名。
4. **维持浅而稳定的 taxonomy。** 建议一层 domain + 一层 capability 作为默认上限（如 `billing/invoices`）；只有确有稳定 namespace 时再加深。层次解决“发现与导航”，不是自动的相关性检索或上下文预算；上一个 FAQ 中的 catalog + 按需读取策略仍然需要。

## 对 FAQ 的影响

FAQ 已更新为“v1.7.0 已支持 nested capability path，但尚未内建 local main-spec catalog / 自动选取”的表述。版本演进记录见 [`0004-v1.6.0-to-v1.7.0.md`](../_change_log/0004-v1.6.0-to-v1.7.0.md)，不作为当前决策依据。
