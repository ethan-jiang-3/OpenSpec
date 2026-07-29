# 主 specs 增长与上下文：上游现状核验（2026-07-29）

> 范围：只核验 Fission-AI/OpenSpec 正式发布的 `v1.7.0`（tag `4e16790`）源码与 GitHub API；这是 FAQ 的研究底稿，不是已交付功能清单。

> **当前基线（2026-07-29）**：本 checkout 与 PATH CLI 均为 v1.7.0；下文所有源码链接均固定到该 release。关于 local main-spec catalog / 自动选择 / token-budget retrieval 的结论未变；nested path 是 v1.7.0 的正式能力，见 [`_research-nested-capability-paths.md`](_research-nested-capability-paths.md)。

## 先分开两个问题

`archive` 不会把全体 main specs 送进一个 LLM 上下文。它先发现当前 change 下的 delta spec，再把每个 delta 映射到同相对路径的 main spec；随后只重建这些目标。[`archive.ts` L438](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/archive.ts#L438)；[`specs-apply.ts` L48-L77](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/specs-apply.ts#L48-L77)。所以 archive 的规模风险是被一次 change 触及的 capability 数量，不是仓库全部 specs 的总量。

真正没有被产品化解决的是 proposal/explore 阶段的“从大量 specs 里找出该读哪几个”。当前默认 schema 只要求 agent “Check `openspec/specs/`”并“Research existing specs”；没有自动选出相关 spec 的步骤。[`schema.yaml` L15-L22](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/schemas/spec-driven/schema.yaml#L15-L22)。当前 propose workflow 也直接进入 artifact build order，没有 catalog/discovery 步骤。[`propose.ts` L30-L77](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/templates/workflows/propose.ts#L30-L77)。

## 现在已经有的窄读取能力

- `openspec list --specs --json` 的当前输出只有 `id` 与 `requirementCount`，不是带 Purpose/overview 的本地 spec catalog。[`list.ts` L190-L208](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/list.ts#L190-L208)
- 已经选定 ID 后，`spec show` 的 JSON 可以去掉 scenarios，或按 1-based requirement 取一条，因此可以按需读取，而非整库加载。[`spec.ts` L39-L58](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/commands/spec.ts#L39-L58)；[`spec.ts` L104-L122](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/commands/spec.ts#L104-L122)。
- v1.7.0 已能按相对路径发现/合并嵌套 spec；本 FAQ 即以这个正式发布版为准。[`specs-apply.ts` L52-L58](https://github.com/Fission-AI/OpenSpec/blob/4e16790d90d8f54d4773ad9a5e71a57cd9f1e86b/src/core/specs-apply.ts#L52-L58)

## 上游提案不是现有能力

| 项目 | 截至 2026-07-29 的状态 | 能说明什么 |
| --- | --- | --- |
| [Issue #901](https://github.com/Fission-AI/OpenSpec/issues/901) | Open | 明确提出 `list --specs --json --detail`，返回 ID、标题、overview、requirement count，先筛选再读全文。问题描述直接指出 20+ capabilities 会造成数千行上下文。 |
| [PR #700](https://github.com/Fission-AI/OpenSpec/pull/700) | Open，未合并 | 拟加入 `--detail`；因此不能把此 flag 当成当前 CLI 的能力。 |
| [PR #902](https://github.com/Fission-AI/OpenSpec/pull/902) | Open，未合并，依赖 #700 | 拟在 propose/ff/continue 中让子 agent 分析 catalog，并只返回相关 specs；PR 中的 token benchmark 是贡献者陈述，不是上游已承诺的效果。 |

维护者 TabishB 在 #901 的回应很明确：认同子 agent 优化重要，会在重构后加入；但对更结构化的流程持保留意见，当前倾向让模型用普通 `grep`、`find` 自行判断，并说需要 evals 验证。[#901 comment](https://github.com/Fission-AI/OpenSpec/issues/901#issuecomment-4199290550) 因而这不是有排期的承诺，更不是已发布方案。

同类痛点仍无官方答复：[Issue #872](https://github.com/Fission-AI/OpenSpec/issues/872) 直接询问长期迭代后 `changes/archive` 与 `specs` 膨胀时是否会提供 summarization，仍为 Open 且无评论。不要把已关闭的 [Issue #878](https://github.com/Fission-AI/OpenSpec/issues/878) 当作问题已解决的证据：它的两条评论均非维护者，也没有对应合并实现。

## FAQ 应给用户的可执行建议

1. 不要把“source of truth”理解成“每次都读全库”。先根据改动描述和代码位置列候选 capability，再读候选及明确的跨域依赖。
2. 将每个 capability 的 `## Purpose` 保持短、可区分；在 `openspec/specs/` 旁维护一份很小的 capability map（ID、Purpose、一两条关键词、owner/边界）。它只是导航索引，不是第二份事实源。
3. 在 proposal 前执行两段式检索：先 `openspec list --specs --json` + `rg` 搜索 capability 名、Purpose 和领域词；再对候选调用 `openspec spec show <id> --json --requirements`，必要时用 `-r` 只取某条 requirement。把最后选中的 IDs 和理由写进 proposal/design，方便 review。
4. 工具支持子 agent 时，可让一个短生命周期子 agent 只做候选发现，主 agent 只接收“相关 ID + 理由”，然后再按需读取原文。这是可立即采用的工作法，非 OpenSpec 内建 workflow。
5. 不要把全部 specs 塞进 `config.context` 或任何全局 prompt。那只是把检索问题变成固定的上下文税，并且更容易过期。

可产品化的未来方向应是：预算受限的本地 catalog（ID + Purpose + count）+ 词法/结构化检索 + 按需完整 spec/requirement fetch + workflow 内显式 discovery；子 agent 隔离是可选优化。#901/#700/#902 是这一方向的社区证据，不是交付承诺。
