# 答案：MD/TS 交替协作时序 — Iterate 如何打磨 artifacts

## 一句话

Iterate 是四个阶段里 MD 比重最高、TS 参与最少的。和 Propose 的密集 MD↔TS 交替不同，本阶段的大部分工作是 MD 的内循环：读 artifact → 读代码 → 对照 → 发现 gap → 修 artifact → 再审。TS 只在需要确认 artifact 状态或补 artifact 时才被调用。

```text
MD 读 artifacts（FS）→ MD 读代码（FS + TS/rg）→ MD 对照 
  → MD 发现 gap → MD 修文件（FS）→ MD 再审
  → 循环直到真正 apply-ready
```

## 时序图

```mermaid
sequenceDiagram
    actor User as 用户
    participant MD as MD<br/>智力层<br/>Agent 工程判断
    participant TS as TS<br/>机械层<br/>OpenSpec CLI
    participant FS as 文件系统<br/>artifacts + 源码

    %% ===== Phase 0: 入口 =====
    rect rgb(240, 248, 255)
        Note over User,FS: ══════ Phase 0 · 入口 ══════
        MD->>MD: propose 刚完成<br/>mechanical apply gate 通过<br/>但 agent 判断 artifacts 需要审视
    end

    %% ===== Phase 1: 读 artifacts =====
    rect rgb(255, 250, 240)
        Note over User,FS: ══════ Phase 1 · 批判性阅读 artifacts ══════
        MD->>FS: 读 proposal.md（scope/why/capabilities/impact）
        FS-->>MD: proposal 内容
        MD->>FS: 读 specs/**/*.md（requirements + scenarios）
        FS-->>MD: specs 内容
        MD->>FS: 读 design.md（若存在，technical decisions）
        FS-->>MD: design 内容
        MD->>FS: 读 tasks.md（implementation checklist）
        FS-->>MD: tasks 内容
        MD->>MD: 结构化审视：<br/>scope 精确吗？scenario 可测吗？<br/>design 假设成立吗？tasks 可执行吗？<br/>artifacts 之间一致吗？
    end

    %% ===== Phase 2: 代码校验 =====
    rect rgb(255, 240, 255)
        Note over User,FS: ══════ Phase 2 · 真实代码校验 ══════
        MD->>MD: 从 artifacts 提取可验证声称：<br/>① 文件路径（"src/auth/session.ts"）<br/>② 符号名（"TokenStore class"）<br/>③ 行为描述（"session 超时 30 分钟"）<br/>④ 架构假设（"routes→controllers→services"）
        MD->>TS: rg 搜索相关符号/文件
        TS-->>MD: 匹配结果
        MD->>FS: 读入口文件、相关模块、测试、数据模型
        FS-->>MD: 真实代码事实
        MD->>MD: 逐项对照（从便宜到贵）：<br/>① 文件存在性 ✓<br/>② 符号存在性 ⚠ TokenStore 不存在<br/>③ 行为一致性 ✗ session 超时不是 30 分钟<br/>④ 结构一致性 ✓<br/>⑤ 测试覆盖 ⚠ 无 OAuth 测试
    end

    %% ===== Phase 3: gap =====
    rect rgb(255, 255, 240)
        Note over User,FS: ══════ Phase 3 · 发现 + 分类 gap ══════
        MD->>MD: 列出所有 gap，按六类分类：<br/>① scope 偏差<br/>② specs 不完整<br/>③ design 假设被推翻<br/>④ tasks 不可执行<br/>⑤ artifacts 间不一致<br/>⑥ 遗漏 artifact
    end

    %% ===== Branch: 有/无 gap =====
    alt 有 gap
        rect rgb(255, 248, 248)
            Note over User,FS: ══════ Phase 4 · 修 gap ══════
            MD-->>User: "发现 N 个 gap：…<br/>建议修完后我再审一轮。"

            alt 小修（补 scenario/细化 task/改文件名）
                MD->>FS: 直接编辑 artifact 文件
            else 补缺失 artifact
                MD->>TS: /opsx:continue（按 schema 规则补充）
                TS-->>MD: instructions + 操作包
                MD->>FS: 写新 artifact
            else scope 需要重定义
                MD->>MD: 回到 Explore stance<br/>重新讨论 scope<br/>可能需要更新 proposal
            else scope 太大
                MD-->>User: "建议拆成 N 个 changes"
            end

            Note over MD,FS: 修完后回到 Phase 1，再审一轮
        end
    else 无 gap（或 gap 已全部修复）
        rect rgb(240, 255, 240)
            Note over User,FS: ══════ 真正 apply-ready · 交棒 ══════
            MD->>MD: 确认六项全部通过：<br/>✓ scope 和代码一致<br/>✓ specs 每个 requirement 有可测 scenario<br/>✓ design（如需）技术决策明确<br/>✓ tasks 具体可执行<br/>✓ artifacts 间无矛盾<br/>✓ 代码校验无遗漏
            MD-->>User: "artifacts 已审核通过。<br/>可以进入 /opsx:apply。"
        end
    end
```

## 和 Propose/Apply 的 MD/TS 比重对比

| 阶段 | MD 比重 | TS 比重 | TS 被调用时机 |
|---|---|---|---|
| Propose | 中高 | 中高 | 每轮 status + instructions，交替密集 |
| **Iterate** | **极高** | **极低** | 只在补 artifact 或确认状态时按需调用 |
| Apply | 高 | 中 | gate 时一次 + 进度刷新按需 |

Iterate 是唯一一个 TS 几乎不参与核心工作的阶段。TS 的 artifact DAG 和 instructions 机制在 Propose 里已经完成了它们的任务——artifacts 已经存在，剩下的打磨不需要 CLI 每轮重新计算状态。

## 关键交替模式

### 模式 1：MD 内循环（TS 旁观）

```text
MD 读 artifact → MD 读代码 → MD 对照 → MD 发现 gap → MD 修 → MD 再审
```

这是本阶段的核心模式。TS 只有在 MD 需要补 artifact（`/opsx:continue`→`openspec instructions`）或确认状态（`openspec status`）时才被调用。大部分时候 TS 不参与。

### 模式 2：代码事实是最终裁判

```text
artifact 声称：session 逻辑在 src/auth/session.ts
代码事实：session 创建分散在 routes/auth.ts + core/session.ts + middleware/session.ts
MD 判断：proposal impact 不准确 → 更新 proposal.md
```

这和 Explore 的 EXP-05 逻辑一致，但起点不同：EXP-05 从用户意图出发做 discovery，ITR-04 从 artifact 声称出发做 verification。

### 模式 3：TS 按需介入

```text
MD 发现 design.md 需要推翻重来
  → 可能需要 /opsx:continue 重新生成 design artifact
  → MD → TS: openspec instructions design --change "X" --json
  → TS → MD: template + instruction + dependencies
  → MD 写新 design.md
```

这是本阶段少有的 TS 参与点。而且不是因为 TS 要求 MD 这样做，而是 MD 主动决定需要 TS 的 artifact 生成机制。

## 参考来源

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/explore.ts` | Explore stance：可读代码、可审视架构、不可实施 |
| `src/core/templates/workflows/continue-change.ts` | `/opsx:continue` 的 artifact 补充机制 |
| `src/commands/workflow/instructions.ts` | artifact instructions 的生成 |
| [`answer.md`](answer.md) | 主流程和 ITR 节点说明 |
| [`answer-itr03.md`](answer-itr03.md) | 批判性阅读 artifacts |
| [`answer-itr04.md`](answer-itr04.md) | 代码校验方法 |
| [`answer-itr05.md`](answer-itr05.md) | gap 分类和修复 |
