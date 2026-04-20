# OPSX vs Legacy 对比

## 总对比表

| 维度 | Legacy（`/openspec:*`） | OPSX（`/opsx:*`） |
|------|------------------------|-------------------|
| **工作流模型** | 阶段锁（planning → implementing → archiving） | 动作流（任意顺序、任意时刻） |
| **生成粒度** | 一次性生成所有 artifact | 按依赖图增量生成，单个 artifact 也可 |
| **模板** | 硬编码在 TypeScript 源码 | 外部 YAML + Markdown（用户可编辑） |
| **依赖建模** | 无（靠阶段隐式表达） | 显式 DAG（`requires` 字段） |
| **状态判定** | 凭「阶段」记号 | 凭文件系统是否存在对应产物 |
| **编辑器支持** | 每个工具一个配置器 | 统一 skill 目录 + 可选 command 适配 |
| **可迭代性** | 回头修改很尴尬 | 改文件即可，命令自然续上 |
| **自定义 schema** | 不支持 | `openspec schema init` / `schema fork` |
| **AI 获取上下文方式** | 静态指令文本 | `openspec status --json` + `openspec instructions --json` 查询 CLI |

## 两个流程图

### Legacy 流程

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│  PLANNING  │ ──► │IMPLEMENTING│ ──► │ ARCHIVING  │
└────────────┘     └────────────┘     └────────────┘
       │                 │                  │
       ▼                 ▼                  ▼
 /openspec:    /openspec:apply      /openspec:archive
   proposal

• Creates ALL artifacts at once
• 发现设计错了？没有官方的回退路径
• 只能手动改文件（会断上下文）、放弃重来、或硬着头皮改
```

### OPSX 流程

```
  /opsx:new ──► /opsx:continue ──► /opsx:apply ──► /opsx:archive
      │               │                 │
      │               │                 ├── 「设计不对？」直接改 design.md
      │               │                 │
      │               │                 └── /opsx:apply 自动接着跑
      │               │
      │               └── 一次只建一个 artifact，显示「下一步解锁了什么」
      │
      └── 只搭骨架（scaffold），等你决定方向
```

## Agent 获取上下文的差异

### Legacy：静态指令

agent 收到的是写死的字符串：「请创建 proposal.md、tasks.md、design.md、specs/<capability>/spec.md」。agent 不知道当前有什么文件、artifact 之间如何依赖。

### OPSX：查询 CLI 拿到结构化上下文

agent 先调 `openspec status --change <name> --json` 拿到：

```json
{
  "artifacts": [
    {"id": "proposal", "status": "done"},
    {"id": "specs",    "status": "ready"},
    {"id": "design",   "status": "ready"},
    {"id": "tasks",    "status": "blocked", "missingDeps": ["specs"]}
  ]
}
```

再调 `openspec instructions specs --change <name> --json` 拿到对应 artifact 的模板、项目 context、前置依赖文件内容、规则——全部打包好给 AI。

## Legacy 还能不能用

可以。`/openspec:proposal` / `/openspec:apply` / `/openspec:archive` 都保留着，适用场景（来自 [docs/commands.md](../../docs/commands.md)）：

- 既有项目还在用旧工作流
- 简单改动不需要逐个 artifact 生成
- 偏好一次性生成

**但新项目一律推荐 OPSX**，README 首推的命令就是 `/opsx:propose`。
