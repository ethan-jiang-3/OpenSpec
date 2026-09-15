# Spec Model

## Markdown 不是随便写的笔记

OpenSpec 选择 Markdown 作为 specs/changes 的存储格式，是为了让人类能读、能 review、能进 Git。但如果 Markdown 只是一堆自由文本，agent 和 CLI 就无法可靠判断：

- 当前项目承认了哪些 requirement？
- 一个 change 修改了哪些 requirement？
- delta spec 是否能安全 archive？
- `show --json` 和 `validate --json` 应该输出什么？

Spec model 这一层的作用，就是把 Markdown 变成可验证、可查询、可 archive的结构化对象。

```text
Markdown files
  → parsers
  → Zod schemas
  → validation/report/conversion
  → show/list/view/archive/workflow context
```

这也是 OpenSpec 和“让 agent 随便读文档”的区别：文件是人类格式，解释结果是机器格式。

## parser 和 schema 的分工

`MarkdownParser` 是 spec 文档的基础解析器。它把 Markdown section 解析成 title、Purpose、Requirements、requirement list、scenario list。解析结果进入 `SpecSchema.safeParse()`。

这个分工很关键：

- parser 负责从 Markdown 抽取结构。
- Zod schema 负责结构合法性。
- validator 负责 OpenSpec-specific 规则。

不要把这三者混在一起。parser 不应该决定 workflow 顺序；schema 不应该处理文件系统 archive；validator 不应该替 agent 判断代码是否实现正确。

## ChangeParser

`ChangeParser` 继承 `MarkdownParser`，用于 proposal/change 文档。它会解析：

- Why
- What Changes
- Impact
- delta specs

`parseChangeWithDeltas()` 会读取 change directory 下的 delta spec 文件，把 proposal 和 specs delta 组合成 `Change` 对象。

这使得一个 change 不是“一个目录里有几个 Markdown 文件”这么简单，而是 CLI 和 agent 可作为结构化 change 来审阅、验证、输出 JSON。

### capability ID 是相对路径

delta 与 main spec 都通过 `discoverSpecFiles()` 递归发现：`specs/auth/spec.md` 的 ID 是 `auth`，`specs/identity/session/spec.md` 的 ID 是 `identity/session`。list、show、validate、change parser、archive/apply 都使用同一条发现路径，因此 nested layout 是完整生命周期支持，不是只允许把文件放进子目录。

这只是 path namespace：`identity` 和 `identity/session` 没有继承、聚合或自动加载语义。`changes/<change>/specs/spec.md` 则没有 capability 目录，会被 validate/archive 拒绝，避免它被发现器忽略后静默丢失。

## requirement-blocks 是 archive 的关键

`requirement-blocks.ts` 是 archive 和 validation 的关键 parser。它提供两套能力：

1. `extractRequirementsSection()`：从主 spec 中抽出 `## Requirements` section，并按 `### Requirement:` 切 block。
2. `parseDeltaSpec()`：从 delta spec 中解析 `ADDED/MODIFIED/REMOVED/RENAMED` 四类变更。

重要细节：

- requirement header 匹配大小写不敏感。
- `normalizeRequirementName()` 当前只 trim，不 lower-case。
- REMOVED 支持 `### Requirement:` header，也支持 bullet list header。
- RENAMED 用 FROM/TO pair。
- UTF-8 BOM 会被剥离，fenced code block 中的 header 不参与 section/requirement 识别。

### delta section 是 list 不是 record

此前，`parseDeltaSpec()` 把 `## ` section 收集成 title-keyed record——重复写同一 header（例如 `## ADDED Requirements` 写了两次，或 fence 示例自带重复 header）时，后写的 body 覆盖先写的，大小写不敏感 lookup 只返回第一个折叠匹配，于是「写了但没应用」的部分在 validate/archive 之前就丢了。

改为**按书写顺序的 list**：

- 每个 `## ` section 保留自己的出现次序和行号，重复 header 的每一份 body 都被读取。
- 大小写折叠后的 lookup 返回**所有**匹配 section，而不是第一个。
- rename 的 `FROM:`/`TO:` 按 section 配对——一份里的 `FROM:` 永远不会和另一份的 `TO:` 配对。
- 诊断仍指向正确的行号（每个 section 有自己的行号）。

### CommonMark 列表标记全接受

`## REMOVED Requirements` 的 bullet 形式和 `## RENAMED Requirements` 的 `FROM:`/`TO:` 行之前硬编码 `-`。CommonMark 用 `-`/`*`/`+` 都能开 bullet list，于是 `*`/`+` 写的删除/改名 delta 匹配不到任何东西——`validate` 报 valid、`archive` 报成功，但需求根本没动。现在接受 `[-*+]`，`FROM:`/`TO:` bullet 保持可选，`### Requirement:` header 形式不变。

这些细节看起来小，但会直接影响 archive merge 是否能找到正确 requirement，以及同名/改名冲突如何处理。

## fenced code block 的边界

`spec-structure.ts` 做主 spec 结构检查，包含 fenced code block 处理。它解决的问题是：不能把代码块里的示例 header 当成真实 requirement。

源码用 `stripFencedCodeBlocksPreservingLines()` 保留行号结构，同时屏蔽 fenced block 内容。这是典型的“人类友好格式”和“机器稳定解析”之间的折中：允许 spec 里放示例，但不能让示例破坏结构判断。

## validation 的两层规则

`Validator` 在 `src/core/validation/validator.ts`，主要入口：

- `validateSpec(filePath)`
- `validateSpecContent(specName, content)`
- `validateChange(filePath)`
- `validateChangeDeltaSpecs(changeDir)`

校验分两层：

```text
parser output
  → Zod schema safeParse
  → OpenSpec-specific rules
```

Zod 负责基础结构；规则校验负责 OpenSpec 语义，比如 Purpose 长度、SHALL/MUST、scenario 数量、delta 冲突。

`validateChangeDeltaSpecs()` 会递归扫描 change 的 `specs/` 目录，检查 ADDED/MODIFIED/REMOVED/RENAMED 的结构、重复、冲突和 scenario 要求。这套校验是 archive 前的重要守门器。`skip_specs: true` 是一个受限例外：无 spec-level 行为改动的 change 可显式跳过 specs artifact；但 marker 与 specs 下任意非隐藏文件共存会报错，不能用来掩盖真实 delta。

validate 还带一个 advisory merge preflight：delta 与 main spec 的合并冲突报为 **informational findings**（成功文本报告里也出现，不改退出码）；文件系统读取错误保留为 error，不再被误判成「spec 缺失」；预检无法解析输入时 validation 报告保持完整。validate 与 archive 对 delta 的解读从此一致——archive 会拒绝的东西，validate 阶段就亮出来。

新 capability 的 delta 可以写 `## Purpose`。archive 创建 main spec 时会带入该 Purpose；缺失或无法构成可读 Purpose 时才留下 TBD placeholder。已有 main spec 的 Purpose 不会被 delta 覆盖。

### validate 检测遗留的 Purpose 占位符

archive 写入的占位符是 `TBD - created by archiving change <name>. Update Purpose after archive.`——它长于 `MIN_PURPOSE_LENGTH`，于是那条专门用来抓「没人写过 Purpose」的 brevity 规则反而被它满足。此前没有任何命令会再读它：capability 里一直躺着一个待办，而所有命令都报成功。

新增 `src/core/validation/purpose-placeholder.ts` 的 `findPurposePlaceholderIssue()`，只认两件事：

- writer 生成的整句——通过 `PURPOSE_PLACEHOLDER_PREFIX` / `PURPOSE_PLACEHOLDER_SUFFIX` 两个共享常量匹配，和 archive writer 使用同一份定义；
- **开头**是 `TBD` 或 `TODO` 的 Purpose（`^(?:TBD|TODO)(?![\p{L}\p{N}\p{M}_])`，所以 `TBDs` / `TODOs` 不算，`TODO:` / `TBD -` 算）。

句子中间的 `TBD`（如 `The retry budget is TBD`）是有效 Purpose，不报——否则会训练用户忽略警告。fence 内的引用先被读出（复用 `buildCodeFenceMask`），空 Purpose 交给已有的 `SPEC_PURPOSE_EMPTY` 规则，不重复报。

级别是 **WARNING**：normal 模式通过，`--strict` 才失败。诊断尽量定位到占位符所在行（leading marker 取 section 首行，生成句取包含它的行），定位不到就只报 finding、不报行号，避免给出错误行号。

## warnings 与 errors

`ValidationIssue` 有 `level`。strict mode 会影响 report 是否通过：

- ERROR 一定失败。
- WARNING 在 strict mode 下也会导致失败。

因此 `validate --strict` 和普通 validate 的语义不同。这个设计允许 OpenSpec 同时支持“宽松审阅”和“严格 CI/archive 前检查”。

## read commands 是模型的外部视图

| 命令 | 本质 |
|------|------|
| `list` | 读取 active changes/specs，输出索引视图 |
| `show` | 把 change/spec 内容解析后展示，human/JSON 两种形态 |
| `view` | 人类交互 dashboard，偏浏览体验 |
| `validate` | 包装 Validator，转换成 CLI report、JSON 和退出码 |
| `JsonConverter` | spec/change Markdown 到 JSON object 的轻量转换 |

它们回答的是“现有状态是什么、是否结构有效”，不回答“下一步应该写什么”。workflow 决策要看 `status` / `instructions`。

## 工程洞察

- OpenSpec 不是把 Markdown 当纯文档，而是把它当 local protocol file。
- parser/validator 让 Git-friendly 文本具备机器可检查语义。
- archive 可靠性依赖 requirement block 解析，而不是 LLM 自由合并。
- enriched validation messages 是产品能力的一部分，因为错误修复路径要给人和 agent 都看得懂。

## 源码锚点

| 机制 | 路径 |
|------|------|
| spec/change Zod schema | `src/core/schemas/` |
| Markdown parser | `src/core/parsers/markdown-parser.ts` |
| change parser | `src/core/parsers/change-parser.ts` |
| requirement blocks | `src/core/parsers/requirement-blocks.ts` |
| main spec structure | `src/core/parsers/spec-structure.ts` |
| recursive spec discovery | `src/utils/spec-discovery.ts` |
| validator | `src/core/validation/validator.ts` |
| JSON converter | `src/core/converters/json-converter.ts` |
| read commands | `src/core/list.ts`、`src/core/view.ts`、`src/commands/show.ts`、`src/commands/validate.ts` |

## 继续阅读

- archive merge 算法见 `../internal-spec-driven/04-archive-归档合并.md`。
- schema artifact graph 见 `../schema/`。
- CLI command IO 见 `../spec_cli/`。
