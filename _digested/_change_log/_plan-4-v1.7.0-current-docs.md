# 计划 4/4：以 OpenSpec v1.7.0 更新当前资料

**状态**：执行中  
**当前基线**：OpenSpec `v1.7.0`，upstream tag/commit `4e16790`  
**覆盖目录**：`_digested/`、`_faq_on_digested/`、`_openspec_handbook/`

这不是另一个 release note。`0004-v1.6.0-to-v1.7.0.md` 记录上游变化；本计划负责把会误导当前用户的旧结论改为 v1.7.0 的实际行为。完整影响清单与一手来源见 [`_v1.7.0-impact-audit.md`](_v1.7.0-impact-audit.md)。

## 共同验收边界

- 面向当前使用者的行为结论以 v1.7.0 为准；`v1.5` / `v1.6` 仅留在变更史、时间线或明确标注的历史比较中。
- nested main spec 是完整生命周期支持：capability ID 是 `specs/` 下的相对路径（如 `identity/session`），delta 必须同路径；它不是继承树、自动聚合或按相关性自动读取 main specs 的机制。
- 不能把 host-specific 的 `/opsx:*` 当通用入口。Claude 专篇可以继续使用其实际 slash command；Codex 当前使用 `$openspec-*` skills。
- 文档区分“确定性 CLI 契约”和“agent 的提示/工作流建议”，不把后者写成强制执行。
- 不为 v1.7.0 无关的案例、历史 changelog 或 Claude 专篇做机械性替换。

## 1. `_digested/`：源码机制与运行时契约

- [x] 建立 v1.7.0 release 记录、当前基线说明和源码影响审计。
- [x] 更新 main-spec context 的研究底稿与 FAQ 14 所依赖的 nested-path 结论。
- [x] 修正工具投递总论：Codex skills-only，adapter 命令名不是统一 `/opsx:*`。
- [ ] 更新 spec model、archive 与 specs-truth：递归发现、根级 `specs/spec.md` 非法、BOM/fenced-code 解析边界、Purpose 传递、early-sync no-op 与 archive warnings。
- [ ] 更新 config / schema / CLI runtime：`skip_specs: true`、status 的 `skipped`、`operations.apply/archive.guidance`、Apply/Archive operation inputs、`instructions archive`、schema 声明顺序与重新读取依赖文件。
- [ ] 更新 workflow 与 store/CLI 说明：单 active change 自动选择、bulk archive 仍显式选择、numeric-prefixed change、`defaultStore` / `view` root resolution、`openspec update` 的 stale CLI 提示。
- [ ] 逐篇扫描并删除仍将以上行为描述为 v1.5/v1.6 当前结论的断言；保留历史文档中的历史描述。

## 2. `_faq_on_digested/`：问题导向的当前答案

- [x] 更新 FAQ 14，使其以 v1.7.0 区分“nested path 已支持”与“main-spec 上下文自动检索仍未解决”。
- [ ] 更新 FAQ 04/05：proposal、status、continue/apply-ready 中的 `skip_specs` 和 schema artifact 顺序。
- [ ] 更新 FAQ 06/07/11：Apply/Archive 的 operation inputs、Purpose 写入新 main spec、同步后 archive 的幂等/验证边界、nested capability path。
- [ ] 更新 FAQ 08/13：`config.yaml` 增加 `operations`；`context` 会进入 Apply/Archive，artifact `rules` 不会；Explore 读取 context/rules；给出唯一合法的 operation guidance 放置方式。
- [ ] 更新 FAQ 12：将当前 upstream/CLI 结论提升到 v1.7.0，区分源码 checkout、PATH 二进制和 `openspec update` 的升级提示。
- [ ] 保留案例中明确的 Claude `/opsx:*` 调用，但在跨工具结论处注明 invocation 由 host adapter 决定。

## 3. `_openspec_handbook/`：面向使用者的手册

- [x] 更新 README、索引、能力身份章节和机器协议到 handbook v1.3 / OpenSpec v1.7.0。
- [ ] 更新入门、概念、生命周期和 FAQ 总入口：host-specific invocation、`skip_specs` 与 capability path 的用户心智模型。
- [ ] 更新 config 章节（04/05/06）和 artifacts 实战：四个 artifact 的 rules 与 Apply/Archive operation guidance 的边界，附最小正确 YAML。
- [ ] 更新 archive、多人协作和实战案例：新 capability Purpose、inline sync 后验证、幂等 early-sync，以及 nested path 的使用边界。
- [ ] 更新 store/custom-schema 章节：default store fallback、`view` 按 resolved root、schema `instruction` 的权威性；仅在当前结论处写 v1.7.0。
- [ ] 复查所有通用表格与 Q&A：不把 Claude 语法扩展到 Codex，也不把路径 namespace 说成 hierarchy/retrieval。

## 验证与收尾

- [ ] 用 v1.7.0 源码和 release note 复核每项新断言；链接固定到 tag/commit，不依赖浮动 `main`。
- [ ] 用定向 `rg` 扫描过时的 current-version 表述、"Apply/Archive 不接收 config"、"Purpose 总是 TBD"、flat-only capability 与通用 `/opsx:*` 断言。
- [ ] 运行 `git diff --check`，并运行与递归 spec discovery / metadata / instructions 相关的定向测试。
- [ ] 将 `0004-v1.6.0-to-v1.7.0.md` 的“后续逐篇重写”状态改成已完成的实际范围，并在本计划中勾选完成项。

