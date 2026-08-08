# Change Log · 上游同步记录

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
├── _plan-4-v1.7.0-current-docs.md # v1.7.0 当前资料同步计划（覆盖三个资料目录）
└── ...
```

编号递增，文件名简洁描述版本跨度。
