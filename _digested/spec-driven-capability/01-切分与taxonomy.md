# 01 · 切分与 taxonomy：让 capability 成为可管理的行为合同

## 先定术语：不是 bucket，而是行为合同切片

能力规划的目标不是给代码“分文件夹”，而是让每个可观察的系统行为都有一个稳定、足够小、又不碎裂的合同归属。

因此 capability 的最实用定义是：

> 一个 capability 是能够独立解释其用途、独立承受行为变更、并由一组 requirements 与 scenarios 验证的行为合同切片。

这个定义同时排除了三个常见误切法：

- 按源文件切：一个 capability 往往横跨 UI、服务、CLI 与存储。
- 按技术层切：database、parser、repository 通常是实现机制，不是用户或调用方应单独读取的行为合同。
- 按功能名堆放：名称相近不等于应该合为一个合同；真正要看是否共同演进、共同验证。

![系统如何长出可治理的 capability 地图](figures/growth-governance.svg)

## 切分的四个正向信号

一个候选 capability 越同时满足下列信号，越值得独立：

| 信号 | 要问的问题 | 例子 |
|---|---|---|
| 可观察性 | 用户、外部系统或其他合同能观察到它吗？ | session 刷新、invoice 生成、CLI 的 JSON 输出 |
| 独立演进 | 它常常可以不改变邻居就单独修改吗？ | identity/login 与 identity/session |
| 独立验证 | 能否用自己的 scenarios 说明成功和失败？ | session 过期与刷新失败 |
| 独立发现价值 | agent 在改它时，读这一份 spec 能显著减少猜测吗？ | 跨模块但对外一致的导出行为 |

反过来，若两个 requirement 总是一起改变、必须用同一场景才能解释、读者也无法分开理解，拆成两个 capability 只会增加跳转成本。

## 推荐 taxonomy：浅、稳定、可读

默认采用一层 domain 加一层 capability：

~~~text
openspec/specs/
  identity/
    login/spec.md
    session/spec.md
  billing/
    invoices/spec.md
    subscriptions/spec.md
  data-export/spec.md
~~~

这里的 path 是：

| 文件 | capability path |
|---|---|
| identity/login/spec.md | identity/login |
| identity/session/spec.md | identity/session |
| billing/invoices/spec.md | billing/invoices |
| data-export/spec.md | data-export |

默认上限不是硬限制。只有在第三层也代表长期稳定、可独立导航的 namespace 时才继续加深，例如 platform/observability/audit-events。不要为了复刻代码目录、团队组织图或 URL 层级而增加层数。

### domain 应承担什么

domain 只承担三件轻量的事：

1. 帮人和 agent 缩小 discovery 范围。
2. 让相邻行为的命名保持一致。
3. 在跨域 change 中帮助说明影响面。

domain 不承担继承、默认 requirement、自动 owner、自动依赖、自动加载全部子 spec 等语义。需要这些信息时，显式写入 catalog、design 或项目约定。

## 命名规则

- path segment 使用稳定、语义明确的 kebab-case 名称。
- 用领域概念而非实现名称：session 而不是 redis-session-store。
- 用行为边界而非页面或代码位置：invoice-generation 比 billing-page。
- 不用模糊垃圾桶名：common、misc、utils、core、other 都是边界未想清楚的信号。
- 不为暂时的项目阶段、团队名称、版本号命名 path。
- 在首次创建前先搜索已有 path 和近义名称；宁可修改已有合同，也不要建立同义 capability。

## 决策表：新建、复用、拆分还是保留

| 情形 | 决策 | 原因 |
|---|---|---|
| 新行为能被既有 requirement 自然描述 | 修改既有 capability | 不制造同义合同 |
| 新行为有独立用户/调用方合同、场景和演进节奏 | 新建 capability | 保持每份 spec 的内聚性 |
| 一个 spec 包含两个经常独立发布、独立修改的行为 | 规划受控拆分 | 减小下次 discovery 与修改的阅读范围 |
| 两个 spec 几乎永远同改、同测且相互引用 | 考虑合并 | 避免人为碎片化 |
| 只是新 adapter、数据库表、重构或库替换 | 通常不新建 capability | 它属于既有可观察合同的 implementation |
| 一项工作没有 spec-level 行为变化 | 使用 skip_specs | 不虚构 requirement 来满足流程 |

## 用合成案例做一次规划

假设一个产品从“账号可登录”长成完整 identity 与 billing 系统。

第一阶段可只有：

~~~text
identity/authentication
~~~

当登录、会话续期和授权策略开始各自变化时，重画为：

~~~text
identity/login
identity/session
identity/authorization
~~~

这不是“目录美化”。它意味着以后修改 session refresh 时，proposal、delta、archive 以及 agent 的按需阅读都能指向 identity/session，而不必把整个 identity 大 spec 当默认上下文。

但若 login 和 session 仍然每次一起变、同一 requirement 才能完整解释它们，就不要为了视觉整齐提前拆分。切分是为了降低未来变化的认知成本，不是为了让树更漂亮。

## 落地前的最小检查

在项目确立 taxonomy 前，完成下面五项即可：

1. 画出候选 domain 与 capability 的一页地图。
2. 为每个 capability 写一句 Purpose，能说明它不负责什么。
3. 查找近义 capability，明确复用还是新建。
4. 写明 nested path convention，并交给后续 agent。
5. 规定 catalog 只导航、main spec 才是行为真相。

可直接采用 [capability-governance-template.md](capability-governance-template.md)。接下来读 [02-schema与CLI如何读取capability.md](02-schema与CLI如何读取capability.md)，理解为什么这张地图必须稳定。
