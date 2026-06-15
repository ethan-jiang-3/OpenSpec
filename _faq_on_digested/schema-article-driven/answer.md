# 答案：Article-Driven Schema — 用 OpenSpec 管理内容生产

## 直接回答

可以。OpenSpec 的 schema 系统本质是 artifact DAG + 模板 + CLI 解释器的组合，这套抽象不绑定代码实现。这里定义的 `article-driven` schema 就是把同一套协议套在文章生产上，不改一行源码。

## 为什么会想到这个

阅读 `_digested/schema/` 系列时，有一个越来越强烈的感受：OpenSpec 的 artifact 管线在概念上非常通用 —— 定义 artifact → 声明依赖 → CLI 解释状态 → agent 按序生成 —— 但它从命名到默认 schema（spec-driven）都带着浓重的"代码实现"气味。自然会追问：换个 schema，能不能管别的事？

这个追问不是假设性问题。如果 schema 系统真的通用，它应该不需要修改 TypeScript 源码就能定义完全不同形状的工作流。article-driven schema 就是这个假设的概念验证。

## 核心设计：7 个 artifact 的 DAG

```text
brief ──→ outline ──→ tasks ──↴
  │          │                    ├──→ apply（写稿执行）
  └──→ research ──→ draft ──→ edit ──→ publish
```

每个 artifact 的职责和它对应代码工作流中的哪个角色：

| artifact | 在 article-driven 中做什么 | 对应 spec-driven 中的什么 |
|----------|--------------------------|--------------------------|
| `brief` | 定受众、目标、范围、约束 | proposal（但更短，只定边界不定方案） |
| `outline` | 核心论点 + 章节流 + 每节证据 | design（结构骨架） |
| `research` | 来源包、关键事实、证据缺口 | 没有直接对应，代码实现在这个阶段看源码就够了 |
| `tasks` | 可追踪的写稿/编辑/发布清单 | tasks（同名，职责一致） |
| `draft` | 完整初稿 | 没有直接对应，代码实现的"产物"是源码文件 |
| `edit` | 编辑审读 + 修改记录 | review artifact（部分 schema 会定义） |
| `publish` | CMS-ready 发布包（终稿 + 元数据 + 分发清单） | archive 的部分职责 |

依赖关系写在 `schema.yaml` 的 `requires` 字段里：

- `brief` 无依赖（起点）
- `outline` 依赖 brief
- `research` 依赖 brief（需要知道查什么方向）
- `draft` 依赖 outline + research（先有结构再动笔）
- `edit` 依赖 draft（改完了才能审）
- `tasks` 依赖 outline + research（知道做什么才能列清单）
- `publish` 依赖 edit（终审后才能打包）

## 关键设计决策

### 为什么保留 tasks.md 文件名

`openspec archive` 在 core logic 里对 `tasks.md` 有硬编码检查 —— 它通过文件名是否存在来判断"apply tracking file 是否完成"。如果改成别的名字（比如 `checklist.md`），archive 会直接失败。

这个约束不是 schema 系统的问题，而是当前 archive 实现的假设：tracking file 叫 tasks。article-driven 选择保留它，以此为代价换取零源码修改的兼容性。**如果要彻底脱离代码命名习惯，需要在 OpenSpec 源码层面把 tracking filename 做成 schema 可配置项。**

### 为什么 apply gate 设成 draft + tasks

`apply.requires: [draft, tasks]` 的含义是："进入生产阶段"的条件是初稿骨架和施工清单都准备好。

spec-driven 的 apply gate 通常是 design + tasks（技术方案 + 实现清单）。article-driven 里 design 的对应物是 outline，但 outline 偏结构骨架，真正的"内容产出"从 draft 开始。所以 gate 放在 draft：意思是"你知道要写什么、怎么写、写出来是什么样了，现在可以动笔了"。

同时要求 tasks 是为了让执行阶段有可追踪的进度 —— apply 的核心机制就是读 tasks、执行、勾 checkbox、继续下一个。

### 为什么加 publish 作为最终 artifact

代码实现天然有"交付"这个概念（代码 merge、部署），所以 spec-driven 的终点是 archive（delta specs 合并回基线）。但内容生产的"交付"是另一回事 —— 需要标题、摘要、正文终稿、SEO 字段、分发渠道清单。这些不是 archive 能自动完成的。

`publish` artifact 就是内容生产的"发布包"：所有 CMS 需要的东西打包在一个文件里，人和系统都能直接用。

这也验证了一个设计点：**schema 可以定义代码实现里不存在的 artifact 类型**，只要它的 `generates` 输出文件、`requires` 声明依赖、instruction 告诉 agent 怎么生成，CLI 就能正常处理。

## 这验证了什么

从 `_digested/` 对 OpenSpec 整体架构的解读来看，article-driven schema 验证了几个关键设计假设：

- **schema 作为 artifact DAG 的通用性**：`spec-driven` 只是内置实例，不是唯一可能的形状。artifact 的 id、依赖、输出、instruction 全部由 YAML 定义，换一套定义就是另一套工作流。
- **模板作为输出骨架的独立性**：templates 里的 Markdown 从"proposal / design / specs"换成"brief / outline / draft"，CLI 照常渲染。模板只解决"输出长什么样"，不参与工作流语义。
- **CLI 作为解释器的无偏性**：`openspec status` 和 `openspec instructions` 不假设 artifact 是代码相关的。它读 schema.yaml、检查文件存在性、返回结构化状态 —— 对 article-driven 和 spec-driven 一视同仁。
- **分层协议模型的可扩展性**：文件系统存状态、schema 定义产物图、CLI 解释状态、template 编译指令、agent 负责执行 —— 这五层中只有 template 和 schema 需要改，其他层直接复用。

## 使用方式

1. 把 `schema-package/` 下的 `schema.yaml` 和 `templates/` 复制到项目的 `openspec/schemas/article-driven/`。
2. 创建 change：`openspec new change write-<topic> --schema article-driven`
3. 走标准流程：`openspec status` → `openspec instructions brief` → `openspec instructions apply`

agent 会像处理代码 change 一样走完 brief → outline → research → tasks → draft → edit → publish 的全流程。

## 已知限制

- **archive 的 tasks.md 硬编码**：这是当前绕过它的原因，也是这个 schema 最大的"代码痕迹"。如果未来 archive 把 tracking filename 做成可配置项，tasks.md 可以改名来更贴合内容生产的语境。
- **v1.4.0 workspace schema 变化**：这个 schema 基于 v1.3.0 的 schema 系统设计。v1.4.0 引入了 workspace 级 schema，可能会影响 schema 的解析优先级或 workspace 层面的 apply 行为，需要后续验证。
- **不是通用 CMS 替代品**：这个 schema 适合个人或小团队的结构化写作流程，不适合需要审批流、多级编辑、发布调度等 CMS 级功能。它验证的是"OpenSpec 协议可以泛化"这个命题，不是"OpenSpec 可以替代 CMS"。
