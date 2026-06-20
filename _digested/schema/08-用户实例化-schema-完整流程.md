# 08 · 用户实例化 Schema 完整流程

> 回 [导读](00-map.md)

这一篇给你一个用户在落地项目中从零定义自己 schema 的完整步骤，每一步都可执行。

---

## 场景设定

小李在一个内容团队，他们的主要产出不是代码，而是技术文章和课件。团队需要 OpenSpec 来管理写作流程，但默认的 `spec-driven` 完全不对口——他们不需要 specs 和 design，需要的是 research → outline → draft → review 这样的写作流水线。

---

## 第 1 步：确认需求和 artifact 依赖图

小李先在纸上画出想要的工作流：

```text
research（调研收集）
    │
    └──→ outline（大纲）
            │
            └──→ draft（初稿）
                    │
                    └──→ review（审核反馈）
                            │
                            └──→ 发布
```

5 个 artifact，串行依赖。

---

## 第 2 步：创建 schema 骨架

小李选择用 fork 方式从 spec-driven 开始（因为它有最多的 artifact 可以参考），然后删掉不需要的：

```bash
cd my-content-project
openspec schema fork spec-driven writing-pipeline
```

产物：
```
openspec/schemas/writing-pipeline/
├── schema.yaml
└── templates/
    ├── proposal.md
    ├── spec.md       ← 不需要，待会删
    ├── design.md     ← 不需要，待会删
    └── tasks.md      ← 不需要，待会删
```

---

## 第 3 步：编辑 schema.yaml

小李把 `schema.yaml` 改成这样：

```yaml
name: writing-pipeline
version: 1
description: 技术文章写作流水线——从调研到发布

artifacts:
  - id: research
    generates: research.md
    description: 资料搜集和主题研究
    template: research.md
    instruction: |
      系统调研写作主题：
      
      **信息采集**：
      - 搜集相关技术文档、论文、博客、代码仓库
      - 记录关键数据和引用来源
      - 标注信息的时效性和可信度
      
      **分析整理**：
      - 核心论点提取
      - 对立观点整理
      - 知识盲区标注（需要进一步查证的内容）
      
      **输出格式**：
      - 信息来源清单（URL、标题、关键摘要）
      - 论点地图（核心论点 → 子论点 → 支撑论据）
      - 待查证问题列表
    requires: []

  - id: outline
    generates: outline.md
    description: 文章大纲
    template: outline.md
    instruction: |
      基于 research.md 创建文章大纲：
      
      **结构要求**：
      - 引言：钩子句 + 问题陈述 + 文章承诺
      - 主体：3-5 个核心段落，每段有明确的观点和论据
      - 结论：核心要点回顾 + 读者收获 + 延伸阅读建议
      
      **标注要求**：
      - 每段标注预计字数
      - 每段标注引用的 research 材料编号
      - 标注需要配图/代码示例的位置
    requires:
      - research

  - id: draft
    generates: draft.md
    description: 初稿
    template: draft.md
    instruction: |
      基于 outline.md 和 research.md 撰写初稿：
      
      **写作风格**：
      - 面向技术背景的中级读者
      - 每个概念先给直观理解，再给技术细节
      - 多用类比和简单示例
      - 段落不宜过长（不超过 5 句）
      
      **内容要求**：
      - 代码示例必须是可运行的
      - 数据引用必须标注来源
      - 标记不确定的内容为 [TODO: 需确认]
    requires:
      - outline

  - id: review
    generates: review.md
    description: 审核反馈
    template: review.md
    instruction: |
      系统审核 draft.md：
      
      **技术准确性**：
      - 代码示例是否能正常运行？
      - 技术概念表述是否准确？
      - 过时的 API 或版本引用？
      
      **可读性**：
      - 逻辑是否自洽？
      - 过渡是否自然？
      - 术语是否一致？
      
      **完整性**：
      - 是否有遗漏的关键概念？
      - 边界情况是否交代？
    requires:
      - draft

apply:
  requires: [review]
  tracks: review.md
  instruction: |
    根据 review 反馈修改 draft.md。
    确认所有审核意见已处理，标记 [TODO: 需确认] 已解决。
    最终检查格式、链接、图片后发布。
```

---

## 第 4 步：创建模板文件

小李删掉不需要的旧模板，创建新的：

```bash
cd openspec/schemas/writing-pipeline/templates/
rm proposal.md spec.md design.md tasks.md
```

创建 `research.md` 模板：

```markdown
## 信息来源

| # | 标题 | URL | 关键摘要 | 可信度 |
|---|------|-----|---------|--------|
| 1 |      |     |         |        |

## 论点地图

### 核心论点
<!-- 一句话表达文章的核心主张 -->

### 子论点
- 
- 

## 待查证问题
- [ ] 
- [ ] 
```

创建 `outline.md` 模板：

```markdown
## 引言
<!-- 钩子 + 问题 + 承诺 -->
预计字数：

## 主体

### 段落 1：[主题]
<!-- 核心观点 -->
预计字数：
引用材料：
配图需求：

### 段落 2：[主题]
预计字数：
引用材料：
配图需求：

## 结论
预计字数：
```

创建 `draft.md` 模板：

```markdown
# [文章标题]

> [一句话摘要]

## 引言

<!-- 正文 -->

## [第一个核心段落]

<!-- 正文 -->

## 总结

<!-- 正文 -->

---

*初稿 · [日期] · 待审核*
```

创建 `review.md` 模板：

```markdown
## 技术审核

| 检查项 | 状态 | 备注 |
|--------|------|------|
| 代码可运行 | ⬜ |      |
| 概念准确 | ⬜ |      |
| 版本时效 | ⬜ |      |

## 可读性审核

| 检查项 | 状态 | 备注 |
|--------|------|------|
| 逻辑自洽 | ⬜ |      |
| 过渡自然 | ⬜ |      |
| 术语一致 | ⬜ |      |

## 修改建议

### 必须修改
- 

### 建议修改
- 
```

---

## 第 5 步：校验 schema

```bash
openspec schema validate writing-pipeline
```

期望输出：
```
✔ writing-pipeline is valid
  - YAML syntax: OK
  - Schema structure: OK
  - Templates: 4/4 files exist
  - Dependency graph: no cycles
```

如果有错误，根据提示修复。

---

## 第 6 步：设为项目默认

```bash
# 方法 1：用 CLI
openspec config set schema writing-pipeline

# 方法 2：直接编辑 config.yaml
# schema: writing-pipeline
```

或者如果 init 时忘了设默认：
```bash
openspec schema init writing-pipeline --default   # 如果已存在会报错
# 改 config.yaml 更直接
```

---

## 第 7 步：创建第一个 change 验证

```bash
# 创建一个测试 change
openspec new change "intro-to-rust-async"

# 查看生成的 change 结构
ls openspec/changes/intro-to-rust-async/

# 检查 .openspec.yaml 是否正确绑定
cat openspec/changes/intro-to-rust-async/.openspec.yaml
# 应该输出：schema: writing-pipeline
```

---

## 第 8 步：检查 AI 收到的指令

在真正开始写之前，验证 AI 实际收到的 prompt：

```bash
# 看 research artifact 的完整 prompt
openspec instructions research --json | jq '.'
```

输出会包含：
- `context`（来自 config.yaml 的 project context）
- `rules`（来自 config.yaml 的 rules.research）
- `template`（research.md 的模板内容）
- `instruction`（schema.yaml 中 research 的 instruction）
- `dependencies`（哪些 artifact 已完成/未完成）

---

## 第 9 步：实战使用

现在可以用这个 schema 工作了：

```bash
# AI 通过 skill 命令触发
/opsx:propose intro-to-rust-async
# → 生成 research.md

# 编辑 research.md，补充更多材料...

/opsx:continue
# → 生成 outline.md

# 调整 outline.md...

/opsx:continue
# → 生成 draft.md

# 或者一次性生成所有 artifact
/opsx:ff
```

---

## 第 10 步：迭代优化

用了几次后发现的问题和调整：

| 发现的问题 | 调整位置 |
|-----------|---------|
| research 总是写得太浅 | 改 schema.yaml → research.instruction，加"至少引用 5 个来源" |
| draft 代码示例格式不统一 | 改 config.yaml → rules.draft，加"使用 ```language 标记代码块" |
| outline 经常偏离 research | 在 outline.instruction 里加"每个段落必须引用 research 中的具体来源编号" |
| 想给所有 artifact 统一提醒 | config.yaml → context 里加"目标读者是 2-3 年经验的开发者" |

**这些都只需要改 YAML 或 Markdown 文件，不需要碰代码。**

---

## 总结：用户定义自己 schema 的核心步骤

1. **画依赖图** — 想清楚 artifact 之间的依赖关系
2. **创建骨架** — `openspec schema fork` 或 `openspec schema init`
3. **编写 instruction** — 这是最有价值的部分，写清楚 AI 在每个阶段要怎么思考
4. **创建模板** — 给每个 artifact 一个 Markdown 骨架
5. **校验** — `openspec schema validate`
6. **设为默认** — 改 config.yaml
7. **实战验证** — 创建一个 change 跑一遍
8. **迭代优化** — 根据实际产出质量微调 instruction 和 rules

**整个过程不需要写任何 TypeScript/JavaScript 代码。纯配置驱动。**
