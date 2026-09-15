# 问题：项目 capability 太多，如何从 flat 迁移到嵌套二级目录结构？

项目运行了很长时间，`openspec/specs/` 下已经积累了二三十个（甚至更多）flat capability：

```text
openspec/specs/
├── auth/spec.md
├── billing/spec.md
├── data-export/spec.md
├── login/spec.md
├── notifications/spec.md
├── session/spec.md
├── subscriptions/spec.md
...（还有二十几个）
```

每次 `/opsx:propose` 或 `/opsx:explore` 时，agent 要么把几十个 capability 全读一遍（浪费上下文），要么跳过 discovery 直接新建了近义 capability（制造漂移）。

想把它们组织成有结构的二级目录：

```text
openspec/specs/
├── identity/
│   ├── login/spec.md
│   └── session/spec.md
├── billing/
│   ├── invoices/spec.md
│   └── subscriptions/spec.md
├── data-export/spec.md        ← 有些可能不需要 domain
```

具体问题：

1. **从 flat 到 nested 的迁移路径是什么？** 直接 `git mv` 就行吗？现有 active changes 里的 delta 指向旧 path 怎么办？
2. **怎么决定哪些 capability 归到哪个 domain？** domain 到底代表什么——是代码模块？团队 owner？还是纯导航命名空间？
3. **迁移后 `config.yaml` 需要改什么？** 需要告诉 agent "本项目用 nested layout" 吗？怎么写？
4. **迁移有没有风险？** capability 有没有 rename 操作？改 path 会不会把 archive 搞炸？
5. **迁移完成后，agent 日常怎么发现和选择正确的 capability？** catalog 怎么建、放在哪？

本文描述当前行为，基线见 [`README.md`](../README.md)。此后 nested path 已正式支持，其后版本未改变该结论。
