# 00 · capability：从系统切片到稳定合同

## 一句话模型

一个 capability 是一个可以独立说明、独立改变、独立验证的行为合同切片。它在文件系统中的 capability path 同时成为 OpenSpec 用来发现、校验和合并这个合同的地址。

~~~text
系统的可观察行为
    → 切成 capability
    → 放入浅 taxonomy 的 capability path
    → proposal 声明本次会触及哪些 path
    → delta 写入同一路径
    → archive/apply 合并到同一路径的 main spec
    → 下一次 agent 通过 catalog 和按需读取再次找到它
~~~

这条链上任何一个环节都不是纯文档习惯：

| 环节 | 人类需要决定的事 | OpenSpec 的确定性行为 |
|---|---|---|
| 切分 | 哪些行为应共享一个合同，哪些应独立演化 | 不替团队划 capability 边界 |
| taxonomy | domain 名称、path 命名和层级深度 | 不赋予目录父子继承或聚合语义 |
| proposal | New / Modified Capabilities 及选择依据 | spec-driven 将它作为 proposal↔specs 契约 |
| delta | 使用精确 capability path 和 requirement 操作 | 递归发现 spec.md 并保留相对路径 ID |
| archive/apply | 当前 main spec 是否仍是正确目标 | 将 change delta 映射到相同相对路径 |
| 后续发现 | 哪些 main specs 与新 change 有关 | 提供 list/show/validate；不自动完成相关性检索 |

## 三层而非一棵继承树

~~~text
系统
  └─ domain：为了发现、导航和委派而分组
       └─ capability：独立的行为合同
            └─ requirements：该合同内可验证的具体承诺
~~~

这是人类的组织视图，不是 OpenSpec 的对象模型：

- identity 与 identity/session 都可以同时存在，但它们是两个独立 capability。
- identity 并不会自动包含、解释或约束 identity/session。
- 任意父目录都不自动拥有 README、catalog、依赖图或汇总 spec 的运行时语义。
- 要表达跨 capability 约束，应把约束放在真正拥有它的合同、短小全局 context，或明确的 change design 中，而不是期待目录层次推导它。

## 本专题的导航图

~~~text
                         01 切分与 taxonomy
                        /                       \
系统行为 ── 定义边界 ──                         ── path 作为稳定身份
                        \                       /
                         02 schema 与 CLI 契约
                                   |
                                   v
                      03 catalog 与按需上下文协议
                                   |
                                   v
                        04 增长、迁移与治理
~~~

## 快速判断

| 看到的现象 | 优先阅读 | 首要动作 |
|---|---|---|
| 一个 spec 越来越长，什么都往里塞 | 01 | 按独立行为和修改频率检查边界，不按页数硬切 |
| 团队在 flat 与 nested 名称之间摇摆 | 01、02 | 先定稳定 path convention，再写入项目指令 |
| agent 总在创建近义的新 capability | 03 | 建薄 catalog，要求 proposal 先记录 discovery 证据 |
| archive 找错目标或 active delta 指向旧 path | 02、04 | 把 path 当 identity，停止把迁移混进普通 archive |
| 想把所有 specs 塞进 config 或 prompt | 03 | 保留全局内核，其他内容按候选 capability 读取 |

## 不在这里解决的事

- 不能凭 nested layout 获得自动检索、token budget 或语义相关性排序。
- 不能凭 validate 证明 specs 与代码语义对齐。
- 不能凭目录改名获得 capability rename；当前没有该操作。
- 不能把 implementation module 一一映射为 capability；spec 的边界是可观察行为的合同边界。

后续先读 [01-切分与taxonomy.md](01-切分与taxonomy.md)。若已经知道边界，只想核对 runtime 如何读取 nested path，则直接读 [02-schema与CLI如何读取capability.md](02-schema与CLI如何读取capability.md)。
