# 决策树：什么时候用什么

## `/opsx:ff` vs `/opsx:continue`

| 情况 | 选 |
|------|----|
| 需求清晰，直接上 | `/opsx:ff` |
| 边想边写，每个 artifact 想 review 一下 | `/opsx:continue` |
| 想在 proposal 定稿后再决定怎么写 specs | `/opsx:continue` |
| 时间紧、改动小 | `/opsx:ff` |
| 复杂 change，想要控制感 | `/opsx:continue` |

**经验法则**：能一次说清全部 scope 就 `ff`，还在摸索就 `continue`。

## `/opsx:propose`（core）vs `/opsx:new + ff`（expanded）

本质是一样的，只是 core profile 把两步合成一条命令。选择看你的 profile：

- 用 core：直接 `/opsx:propose <name>`
- 用 expanded：`/opsx:new <name>` 然后 `/opsx:ff`

## 更新现有 change vs 开新 change

这是常见的困惑。来自 [docs/opsx.md](../../docs/opsx.md) 的决策树：

```
                ┌────────────────────────────────────┐
                │     这件事算「同一份工作」吗？       │
                └──────────────┬─────────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
     intent 没变?       scope 重叠 >50%?      原 change 现在
     problem 没变?      scope 没跑偏?         能不能独立收尾?
          │                    │                    │
    ┌─────┴─────┐        ┌─────┴─────┐        ┌─────┴─────┐
   YES         NO       YES         NO       NO         YES
    │           │        │           │        │           │
    ▼           ▼        ▼           ▼        ▼           ▼
  UPDATE      NEW     UPDATE       NEW     UPDATE        NEW
```

### UPDATE 的情况

- **同 intent，精化执行**：发现边界 case、approach 要微调但目标没变、实现暴露了 design 的小错
- **scope 收窄**：先 ship MVP，剩下的后面做
- **学习驱动的修正**：代码库结构和预想不一样、依赖不如期、从 CSS 变量改成 Tailwind

### NEW 的情况

- **intent 根本变了**：「加 dark mode」→「做一套主题系统」
- **scope 爆炸**：改大到几乎是另一件事；「修登录 bug」→「重写 auth」
- **原 change 能独立收尾**：「ship dark mode MVP」收，然后开新 change「enhance dark mode」

### 一句话原则（来自 docs）

> **Update 保留脉络（context）；New change 提供清晰（clarity）。**
> 当思考历史本身有价值时选 update；当从头开始更清晰时选 new。

### 比喻

像 git branch：
- 同一个 feature 继续 commit
- 真正新的工作开新分支
- 有时候 ship 一个 partial feature，然后为 phase 2 开新分支

## 多 change 并行

多个进行中的 change **互不干扰**（每个 change 一个目录），切换方式：

```text
/opsx:apply fix-login-redirect   # 显式指定 change name
/opsx:apply add-dark-mode        # 切回来
```

归档时用 `/opsx:bulk-archive` 批量处理，自带冲突解决。

## 归档前要不要 verify

推荐先 verify：

```
/opsx:apply → /opsx:verify → /opsx:archive
```

verify **不会阻塞** archive，但会输出 CRITICAL / WARNING / SUGGESTION 清单。让 AI 帮你审自己写的代码，便宜又有效。

## 归档时要不要手动 sync

一般不用。`/opsx:archive` 会主动问你要不要现场 sync。

需要手动 `/opsx:sync` 的场景：
- 长周期 change，想让主 specs 先跟进（别的 change 基于它）
- 多个并行 change 都要拿最新主 specs 作为基线
- 想单独 review merge 结果再归档
