# tool-delivery — 工具投递与 adapter 专题

这个专题补 OpenSpec 如何把 workflow 投递给不同 coding agent。`spec_cli/05-config-profile-delivery.md` 已经解释了 profile/delivery 的概念；这里从源码角度看 `AI_TOOLS`、tool detection、skill generation、command adapters、init/update、profile drift、migration 和 legacy cleanup。

## 文件导航

| # | 文件 | 内容 |
|---|------|------|
| 0 | `00-map.md` | 工具投递总图和源码入口 |
| 1 | `01-skill-command-pipeline.md` | workflow template 到 skill/command 文件的生成链 |
| 2 | `02-init-update-drift.md` | init/update、profile sync drift、migration、legacy cleanup |
| 3 | `03-command-adapters.md` | command adapter interface、registry、典型工具差异 |
