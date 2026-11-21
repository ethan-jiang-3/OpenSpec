# 答案：MD/TS 交替协作时序 — Apply 如何走到 Archive-Ready

## 一句话

Apply 是四条核心命令里唯一真正修改业务代码的阶段。TS 的角色从前两个阶段的"密集交替"退到"gate + 追踪"：TS 判断能不能开始、提供上下文文件列表、解析 checkbox 进度，但读代码、写代码、跑验证、更新 checkbox 全部是 MD 的事。

```text
MD 调 TS 拿 apply gate（state + contextFiles + tasks）
  → TS 返回 ready/blocked/all_done
  → MD 读所有 contextFiles（proposal/specs/design/tasks）
  → MD 逐个执行 pending task：读源码 → 写代码 → 验证 → 勾 checkbox
  → MD 必要时重调 TS 刷新进度
  → 遇到 guard 暂停，直到全部 done
```

## 时序图

```mermaid
sequenceDiagram
    actor User as 用户
    participant MD as MD<br/>智力层<br/>Agent 工程判断
    participant TS as TS<br/>机械层<br/>OpenSpec CLI
    participant FS as 文件系统<br/>源码 + artifacts

    %% ===== Phase 0: 入口 =====
    rect rgb(240, 248, 255)
        Note over User,FS: ══════ Phase 0 · 入口 · 选择 change ══════
        User->>MD: /openspec-apply-change [change-name]
        MD->>MD: 读 apply skill template
        MD->>MD: 确定 change：<br/>① 用户显式传入 name<br/>② 从对话上下文推断<br/>③ 唯一 active change → 自动选中<br/>④ 多个 → openspec list → 让用户选
        MD-->>User: "Using change: add-oauth-login"
    end

    %% ===== Phase 1: Status + Scope =====
    rect rgb(255, 250, 240)
        Note over User,FS: ══════ Phase 1 · status 确认 scope ══════
        MD->>TS: openspec status --change "X" --json
        TS->>FS: 读 change/.openspec.yaml<br/>扫描 artifacts
        FS-->>TS: schema + 文件状态
        TS-->>MD: schemaName, planningHome,<br/>changeRoot, actionContext,<br/>artifactPaths
        MD->>MD: 确认：schema、scope、<br/>allowedEditRoots<br/>（repo-local 约束）
    end

    %% ===== Phase 2: Apply Gate =====
    rect rgb(255, 240, 255)
        Note over User,FS: ══════ Phase 2 · apply instructions gate ══════
        MD->>TS: openspec instructions apply --change "X" --json
        TS->>TS: 检查 apply.requires 是否满足<br/>收集所有 artifact → contextFiles<br/>读 apply.tracks → parseLocatedTaskLines<br/>（TASK_LINE_PATTERN 匹配 -/*/+ 和 1./1)，<br/>仅 x/X 算 done，[?]/[~]/[-]/[] 均计未完成，<br/>并拼接同段落折行续行）<br/>计算 progress
        TS-->>MD: state, contextFiles,<br/>progress{total, complete, remaining},<br/>tasks[{description, done, sourcePath, line}],<br/>instruction, [missingArtifacts]
    end

    %% ===== Branch: state =====
    alt state = "blocked"
        rect rgb(255, 240, 240)
            Note over User,FS: ══════ blocked · 不能实施 ══════
            MD->>MD: 原因：缺 required artifact /<br/>缺 tracking file / 无可用 checkbox 任务
            MD-->>User: "Apply blocked。<br/>按 CLI instruction 执行<br/>openspec instructions <target> --change X 补/修工件。"
        end
    else state = "all_done"
        rect rgb(240, 255, 240)
            Note over User,FS: ══════ all_done · 无需实施 ══════
            MD-->>User: "所有跟踪任务已完成。<br/>归档前请先复核或验证（review/verify），<br/>确认后再请求归档。"
        end
    else state = "ready"
        rect rgb(245, 255, 245)
            Note over User,FS: ══════ ready · 开始实施 ══════

            %% ===== Phase 3: 读上下文 =====
            rect rgb(250, 250, 250)
                Note over User,FS: Phase 3 · 读取 context files
                MD->>FS: 按 contextFiles 逐项读取：<br/>proposal.md（why / scope）<br/>specs/*.md（behavior / scenarios）<br/>design.md（technical decisions）<br/>tasks.md（implementation checklist）
                FS-->>MD: 全部 artifact 内容
                MD->>MD: 不能只靠记忆或 change name 写代码<br/>必须读完所有 contextFiles
            end

            %% ===== Phase 4: 展示进度 =====
            MD-->>User: "Change: add-oauth-login<br/>Schema: spec-driven<br/>Progress: 2/7 tasks complete<br/>Remaining: …"

            %% ===== Phase 5: Task Loop =====
            rect rgb(255, 255, 240)
                Note over User,FS: Phase 4 · task 实施循环
                loop 每个 done=false 的 task
                    MD->>MD: 选下一个 pending task<br/>（顺序来自 tasks.md）

                    %% 读相关代码
                    MD->>TS: rg 搜索相关符号/文件
                    TS-->>MD: 匹配行
                    MD->>FS: 读入口文件、相关模块、<br/>测试、现有 patterns
                    FS-->>MD: 源码内容

                    %% 实施
                    MD->>MD: 做最小、聚焦的代码修改<br/>沿用既有 patterns<br/>不夹带无关重构<br/>不提前实现后续 task

                    %% 验证
                    opt 有可运行的验证
                        MD->>TS: 运行相关测试 / lint / build
                        TS-->>MD: 结果
                    end

                    %% 更新 checkbox 并必跑重查进度
                    MD->>FS: 按 task 的 sourcePath + line 定位<br/>确认描述仍匹配后 - [ ] → - [x]<br/>（不符时先重跑 apply instructions 刷新定位）
                    FS-->>MD: 写入完成
                    MD->>TS: openspec instructions apply --change "X" --json（必跑核对）
                    TS->>FS: 重新解析 tracking file checkbox
                    FS-->>TS: 更新后的 checkbox 状态
                    TS-->>MD: 确认该 task 已 done 且 progress 递增
                end
            end

            %% ===== Guard Branches =====
            rect rgb(255, 248, 248)
                Note over User,FS: Phase 5 · guard 分支
                alt task 描述不清楚
                    MD-->>User: "Task 'Improve auth' 不够具体。<br/>暂停，建议更新 tasks.md。"
                else 实施暴露设计问题
                    MD->>MD: design 假设有 session abstraction<br/>代码实际只有 route-local cookie
                    MD-->>User: "代码事实推翻了 design 假设。<br/>建议回到 explore 讨论，<br/>更新 design.md 和 tasks.md。"
                else 测试失败且原因不清
                    MD-->>User: "测试失败，原因超出当前<br/>task scope。暂停待决策。"
                else 用户中断
                    MD-->>User: "已暂停。已完成 N/M tasks。<br/>当前进度：…"
                end
            end

            %% ===== Phase 6: All Done =====
            rect rgb(240, 255, 240)
                Note over User,FS: ══════ Phase 6 · 全部完成 → archive-ready ══════
                MD->>TS: openspec instructions apply --change "X" --json
                TS->>FS: 重新解析 tasks.md
                FS-->>TS: 全部 - [x]
                TS->>TS: complete == total → state: "all_done"
                TS-->>MD: state: "all_done",<br/>progress: {total:N, complete:N, remaining:0}
                MD-->>User: "Implementation Complete<br/>Change: add-oauth-login<br/>N/N tasks complete<br/>建议先复核或验证（review/verify），<br/>确认无误后再请求归档"
            end
        end
    end
```

## 关键交替模式

### 模式 1：TS 判 gate → MD 分流

```text
TS: instructions apply --json
  → 检查 apply.requires
  → 解析 tracking file checkbox
  → 返回 state: ready | blocked | all_done

MD: 根据 state 走不同分支
  → blocked: 不写代码，展示 CLI instruction 给出的 openspec instructions <target> 恢复步骤
  → all_done: 不写代码，提示归档前先复核或验证（review/verify）
  → ready: 读 contextFiles，进入 task loop
```

这是 apply 阶段 MD 和 TS 最重要的协作点。TS 不替 MD 决定"怎么做"，但 TS 决定"能不能做"。没有这个 gate，MD 可能在 planning 不完整时就动手写代码。

### 模式 2：TS 给 contextFiles → MD 读 → MD 写代码

```text
TS: contextFiles = {
  proposal: ["…/proposal.md"],
  specs: ["…/specs/auth/spec.md"],
  design: ["…/design.md"],
  tasks: ["…/tasks.md"]
}

MD: 逐项读取 → 理解 why/scope/behavior/decisions/checklist
MD: 写业务代码（src/routes/oauth.ts, test/auth/oauth.test.ts, …）
```

TS 不告诉 MD "改哪个源文件"。它只告诉 MD "读这些 planning 文件"。具体改哪些源码，是 MD 从 planning artifacts 和代码调查中自己判断的。这和 Explore 的 EXP-04/EXP-05 分工一致。

### 模式 3：MD 改文件 → MD 勾 checkbox → 必调 TS 重算进度

```text
MD: 完成 task 2.1 → 写代码 → 验证通过
MD: instructions apply --json 的 task 带 sourcePath + line（1-based）
MD: 按 sourcePath/line 定位该 checkbox，确认描述仍匹配后 - [ ] 2.1 → - [x] 2.1
MD: 必跑 openspec instructions apply --change <name> --json 核对
TS: 重新解析 tracking file → 确认 2.1 done，complete: 3/7 → remaining: 4
```

进度不在 agent 的口头总结里，也不在隐藏数据库里。它在 tracking file checkbox 里，由 TS 的共享解析器 `TASK_LINE_PATTERN` + `parseLocatedTaskLines()`（`src/utils/task-progress.ts:55, 126-150`）实时解释——全部 CommonMark 列表标记（`-`/`*`/`+`/`1.`/`1)`）与缩进子任务均计入，非 `x`/`X` 标记（如 `[?]`/`[~]`/`[-]`/`[]`）计为未完成，同一段落的折行续行以单空格拼入 `description`（v2.0.0 `#2228`）。MD 勾了才算，TS 扫了才认。

### 模式 4：MD 遇 guard → 暂停，不硬写

```text
MD 发现 design 假设和真实代码冲突
  → 不硬写代码
  → 暂停，输出：当前进度 + 具体阻塞 + 可选下一步
  → 建议回到 explore 或更新 artifacts
```

apply 不是 "phase lock"。发现 planning 问题时回写 artifacts 是允许的。这是 MD 的工程判断，TS 不参与这个决策。

## 和 Propose 的对比

| | Propose | Apply |
|---|---|---|
| TS 调用频率 | 极高（先 `context --json`，再每轮 `status` + `instructions`） | 中高（入口 gate 一次，且每勾完一个 task 重跑 `instructions apply` 核对进度） |
| MD 主要动作 | 按操作包写 artifact 内容 | 读源码、写业务代码、跑验证、勾 checkbox |
| TS 的核心输出 | artifact DAG + 操作包（模板、规则、依赖） | state gate + contextFiles + progress |
| 产物 | proposal.md, specs/, design.md, tasks.md | 修改后的业务代码 + 全部勾完的 tasks.md |
| MD 可以改什么 | planning artifacts（change 目录内） | 业务代码（src/, tests/, config）+ tasks.md checkbox |

## 参考来源

源码引用以 [`../../_digested/README.md`](../../_digested/README.md) 声明的「当前源码基线」（`0c737dc1`）为准：

| 来源 | 用到的结论 |
|---|---|
| `src/core/templates/workflows/apply-change.ts` | apply skill 的完整步骤、guardrails、checkbox 更新后重跑核对、暂停条件 |
| `src/utils/task-progress.ts` + `src/commands/workflow/instructions.ts` | `TASK_LINE_PATTERN`、`parseLocatedTaskLines()`（含折行续行拼接）、`generateApplyInstructions()`、state/progress/tasks 输出 |
| `src/core/artifact-graph/outputs.ts` | required artifact 输出文件判定 |
| `src/core/artifact-graph/instruction-loader.ts` | change context 和 contextFiles 收集 |
| `src/core/change-status-policy.ts` | `actionContext`（repo-local）语义 |
| `schemas/spec-driven/schema.yaml` | `apply.requires: [tasks]`、`tracks: tasks.md` |
| [`answer-app03.md`](answer-app03.md) | apply instructions JSON 细节 |
| [`answer-app06.md`](answer-app06.md) | task 循环和 checkbox 更新细节 |
| [`answer-app-guards.md`](answer-app-guards.md) | blocked/all_done/暂停条件细节 |
