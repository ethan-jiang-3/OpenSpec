# 嵌套／层次化 capability path：源码核验（2026-07-29）

## 结论

**可以做，而且做对后很有价值；但要分清“源码已支持”“已发布版本可用”“官方默认推荐”这三件事。**

1. **本 checkout (`d4f1903`、package `1.5.0`) 不支持。** 它只查看一级的 `specs/<capability>/spec.md`；nested main spec 会从 list/show/validate 中消失，nested delta 也不会被 archive 合并。[本地 `item-discovery.ts` L25-L44](../../src/utils/item-discovery.ts#L25-L44)；[本地 `specs-apply.ts` L57-L96](../../src/core/specs-apply.ts#L57-L96)。
2. **已发布的 upstream `v1.6.0` 也还不完整，不能据此采用。** 该 release 发布于 2026-07-10；其 `getSpecIds()` 和 `findSpecUpdates()` 仍是一层 `readdir`。[v1.6.0 release](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.6.0)；[`item-discovery.ts` at v1.6.0](https://github.com/Fission-AI/OpenSpec/blob/e1b51d111ab446b54dee2d6159ac245f0339ae52/src/utils/item-discovery.ts#L25-L44)；[`specs-apply.ts` at v1.6.0](https://github.com/Fission-AI/OpenSpec/blob/e1b51d111ab446b54dee2d6159ac245f0339ae52/src/core/specs-apply.ts#L62-L101)。
3. **完整支持在 upstream main 的 PR [#1355](https://github.com/Fission-AI/OpenSpec/pull/1355) 于 2026-07-17 合入（commit [`3fdd2f2`](https://github.com/Fission-AI/OpenSpec/commit/3fdd2f2f7b055d25672d7a36ba006dcfc8478eb0)），晚于 v1.6.0 release。** 所以截至核验日，它是“已合入、但不能假定 npm stable 已带”的能力；实际使用前必须查自己安装的 CLI，而不能只看 `1.6.0` 这个版本名。

## 它在代码中的准确语义

在包含 #1355 的源码中，共用的 [`discoverSpecFiles()`](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/utils/spec-discovery.ts#L4-L63) 会递归发现任意深度的 `spec.md`，并把**相对于 `specs/` 的目录路径**作为 capability ID，统一用 `/`：

```text
openspec/specs/identity/session/spec.md
                 └──────────────┘  ID = identity/session
```

它不是“一个大 spec 内的章节层级”，也不是有继承、聚合或自动依赖推导的 domain model：目录只是路径命名空间；工具把每个 `spec.md` 当成一个独立 capability。父目录也可以同时有自己的 `spec.md`，此时 `identity` 和 `identity/session` 是两个独立 ID；代码没有赋予它们额外的父子语义。

约束也很具体：根目录直接放的 `openspec/specs/spec.md` 被忽略；隐藏目录跳过；目录 symlink 不追踪。[helper L11-L25、L37-L55](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/utils/spec-discovery.ts#L11-L25)。官方测试覆盖 flat、nested、正斜杠 ID、root-file exclusion 和 symlink 行为。[`spec-discovery.test.ts`](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/test/utils/spec-discovery.test.ts#L22-L165)。

## 生命周期是否完整

在 #1355 后，答案是“针对正常 CLI 路径，完整”：

| 动作 | 源码行为 |
|---|---|
| `list` / interactive `show` / `validate --specs` | `getSpecIds()` 调共享递归发现器，因此 ID 会列为 `identity/session`。[`item-discovery.ts` L29-L33](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/utils/item-discovery.ts#L29-L33) |
| `show identity/session`、单项 validate | 消费者以 `path.join(specsDir, id, 'spec.md')` 定位，所以 slash ID 会落到 nested 文件。[`spec.ts` L80-L121](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/commands/spec.ts#L80-L121)；[`validate.ts` L194-L211](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/commands/validate.ts#L194-L211) |
| change delta parse / validate | 同一递归发现器扫描 `changes/<change>/specs/**/spec.md`。[`change-parser.ts` L57-L66](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/core/parsers/change-parser.ts#L57-L66)；[`validator.ts` L137-L166](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/core/validation/validator.ts#L137-L166) |
| `archive` / apply | delta ID 被保持原样，target 是 `mainSpecsDir/<ID>/spec.md`；写入前递归创建父目录。故 delta 与 main spec 必须使用**同一个相对路径**。[`specs-apply.ts` L48-L77](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/core/specs-apply.ts#L48-L77)；[写入 L456-L475](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/core/specs-apply.ts#L456-L475)；[`archive.ts` L437-L446](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/core/archive.ts#L437-L446) |

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

**推荐 domain 分组这个方向，但尚未成为统一的 agent 默认。** 人类文档建议大代码库按 domain 分组，并说 monorepo 的 domain 可映射 package/service。[`existing-projects.md` L103-L119](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/docs/existing-projects.md#L103-L119)。但当前默认 schema 和生成的 propose/sync/archive workflow 仍教 agent 写 flat 的 `specs/<capability>/spec.md`。[`schema.yaml` L62-L65](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/schemas/spec-driven/schema.yaml#L62-L65)；[`propose.ts` L15-L20](https://github.com/Fission-AI/OpenSpec/blob/17af60c66e4c049e3986fdbafcdc16b202cda59f/src/core/templates/workflows/propose.ts#L15-L20)。这正是仍 open 的 [#1459](https://github.com/Fission-AI/OpenSpec/issues/1459)：作者确认代码已支持 nested，但 agent-facing guidance 尚未跟上。

所以合理结论不是“官方已把层次结构定成默认最佳实践”，而是：**它是已实现、适合较大项目的组织能力；团队要在自己的 `config.yaml` / AGENTS 指令中明确本项目的 path convention，避免 agent 又新建 flat 同义 capability。**

## 怎么用才对

1. **先升级到确实含 #1355 的版本／提交，再迁移。** 对当前本 checkout 和 released v1.6.0，不能只改目录；它会产生“文件存在但 CLI 看不见 / archive 静默漏合并”的风险，正是 #1353 报告的问题。
2. **按“独立行为合同、独立修改频率”拆，而不是按页数硬切。** 例如 `identity/login` 与 `identity/session` 可独立变更；若两个 requirement 总是共同修改、共同验证，则拆开只会增加必须同时阅读的 spec 数量。
3. **路径是 capability identity，改路径等于改 ID。** `auth` → `identity/login` 没有内建 capability-rename；一条仍在 `changes/*/specs/auth/spec.md` 的 delta 会继续指向旧 ID。把迁移当成受控 rebaseline：冻结/处理触及旧 ID 的 active changes，`git mv` main spec，同行移动或重建这些 delta，更新文档/catalog/引用，然后运行 `list --specs`、`validate --specs --strict` 和每个受影响 change 的 validate。不要让普通 archive 顺便承担重命名。
4. **维持浅而稳定的 taxonomy。** 建议一层 domain + 一层 capability 作为默认上限（如 `billing/invoices`）；只有确有稳定 namespace 时再加深。层次解决“发现与导航”，不是自动的相关性检索或上下文预算；上一个 FAQ 中的 catalog + 按需读取策略仍然需要。

## 对 FAQ 的影响

现有 FAQ 的“本 checkout 不可用、含 `3fdd2f2` 的后续 upstream snapshot/main 可用、不能把它误写为 v1.6.0 release”结论是正确的，无需改写。这个笔记补足的是更清晰的发布边界与“支持不等于当前 agent 默认推荐”的判断。
