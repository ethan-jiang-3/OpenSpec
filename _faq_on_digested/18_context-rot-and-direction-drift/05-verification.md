# 05 · 可复跑验证

[← 返回索引](answer.md) ｜ 上一篇：[04 · 使用要点](04-usage.md)

以下命令在本仓库根目录可直接跑（`node bin/openspec.js` 等价于全局 `openspec`）。**每条都跑过**，注释里是当时的实际输出。

> ⚠️ 带 `mkdir`/`cd /tmp` 的那一节会**写临时目录**，不要在本仓库里跑。

---

## 5.1 证据边界：`src/`、`bin/`、`openspec/` 与上游基线 tag 逐字节一致

```bash
# src/、bin/、openspec/、package.json 相对当前基线 tag（v2.1.1 = 0c737dc1）无任何改动（输出 0）
git diff --name-only v2.1.1..HEAD -- src/ | wc -l
# → 0
git diff --name-only v2.1.1..HEAD -- src/ bin/ openspec/ package.json | wc -l
# → 0

# 所有差异文件全部落在本地研究文档目录，无一行上游产品源码
git -c core.quotepath=false diff --name-only v2.1.1..HEAD \
  | awk -F/ '{print $1}' | sort -u
# → CONTEXT.md ／ _digested ／ _faq_on_digested ／ _openspec_handbook
```

`-c core.quotepath=false` 是必需的：中文文件名会被 git 转义成 `"\344..."` 形式，导致目录统计出现重复项。这里钉基线 tag（见 [`../../_digested/README.md`](../../_digested/README.md)）而不是 `upstream/main`，避免远端后续提交污染对比。

---

## 5.2 注入体 vs 规格树规模

```bash
find openspec/specs -name '*.md' | wc -l                                   # 44
cat openspec/specs/*/spec.md | wc -c                                       # 395059
cat openspec/specs/*/spec.md | wc -l                                       # 7959
grep -rhc '^### Requirement:' openspec/specs/*/spec.md | paste -sd+ - | bc # 318
grep -rhc '^#### Scenario:'   openspec/specs/*/spec.md | paste -sd+ - | bc # 1040

# 最大单文件
for f in openspec/specs/*/spec.md; do printf "%8d %s\n" "$(wc -c < "$f")" "$f"; done | sort -rn | head -3
# → 45506 openspec/specs/cli-validate/spec.md
# → 21369 openspec/specs/cli-init/spec.md
# → 20766 openspec/specs/cli-completion/spec.md

# 单次注入总量（对活跃 change install-skills-globally）
node bin/openspec.js instructions specs --change install-skills-globally --json | wc -c   # 9729
node bin/openspec.js instructions apply --change install-skills-globally --json | wc -c   # 4181

# 载荷字段与各自体量
node bin/openspec.js instructions specs --change install-skills-globally --json \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
      for(const k of Object.keys(j))console.log('  ',k,'=',(typeof j[k]==='string'?j[k].length:JSON.stringify(j[k]).length));})"
# → instruction = 6765, context = 847, rules = 427, template = 374, …
```

---

## 5.3 分级过滤读的削减幅度

```bash
for s in artifact-graph instruction-loader cli-archive; do
  full=$(node bin/openspec.js show "$s" --type spec --json 2>/dev/null | wc -c)
  lean=$(node bin/openspec.js show "$s" --type spec --json --no-scenarios 2>/dev/null | wc -c)
  echo "$s: $full -> $lean"; done
# → artifact-graph:      12209 -> 2573
# → instruction-loader:   4208 -> 1189
# → cli-archive:         22660 -> 4320

node bin/openspec.js list --specs --json | wc -c      # 3289
node bin/openspec.js show --help                       # 确认 --no-scenarios / -r 存在
```

---

## 5.4 50 KB 闸门与 profile

```bash
grep -n 'MAX_CONTEXT_SIZE' src/core/project-config.ts src/core/references.ts
# → project-config.ts:256:export const MAX_CONTEXT_SIZE = 50 * 1024; // 50KB hard limit…
# → references.ts:25,46 引用同一常量；截断分支在 references.ts:510-517

node bin/openspec.js config get profile               # core
grep -n 'CORE_WORKFLOWS\|ALL_WORKFLOWS' src/core/profiles.ts | head -3
# → :14 CORE_WORKFLOWS = ['propose','explore','apply','update','sync','archive']
```

---

## 5.5 `rules:` 按 artifact 分流

```bash
for a in proposal specs design tasks; do printf "%-9s" "$a"; \
  node bin/openspec.js instructions "$a" --change install-skills-globally --json 2>/dev/null \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
      console.log('rules:',JSON.stringify(j.rules));})"; done
# → proposal rules: undefined
# → specs    rules: [5 条，含 Windows 路径 scenario…]
# → design   rules: [5 条，含 Node path 模块…]
# → tasks    rules: [2 条，含 Windows CI 验证…]
```

---

## 5.6 校验：默认 vs 严格

```bash
node bin/openspec.js validate --specs ; echo "exit=$?"
# → Totals: 44 passed, 0 failed (44 items)   exit=0

node bin/openspec.js validate --specs --strict ; echo "exit=$?"
# → Totals: 38 passed, 6 failed (44 items)   exit=1

node bin/openspec.js validate --all ; echo "exit=$?"
# → Totals: 48 passed, 0 failed (48 items)   exit=0

node bin/openspec.js validate --all --strict ; echo "exit=$?"
# → Totals: 42 passed, 6 failed (48 items)   exit=1
```

级别与种类分布（当前 44 份主 spec + 4 个活跃 change = 48 项）：

```bash
node bin/openspec.js validate --all --json 2>/dev/null \
| node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
    const L={};let loss=0,items=new Set();
    for(const it of j.items)for(const is of (it.issues||[])){
      L[is.level]=(L[is.level]||0)+1;
      if(/omits scenario\(s\)/.test(is.message)){loss++;items.add(it.id);}}
    console.log('级别:',JSON.stringify(L));            // {"WARNING":12,"INFO":2}
    console.log('scenario 丢失条数:',loss);            // 0（上游已在 PR #2128 重基线归档旧积压）
    console.log('totals:',JSON.stringify(j.summary.totals));})" // {"items":48,"passed":48,"failed":0}
```

**"零重叠检测"的精确验证**（只看 issues 文本，避免误命中 `requires` 等字段）：

```bash
node bin/openspec.js validate --all --json 2>/dev/null \
| node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
    const m=[];for(const it of j.items)for(const is of (it.issues||[]))m.push(is.message);
    console.log('命中 overlap|conflict|stack|depend 的条数:',
      m.filter(x=>/overlap|conflict|stack|depend/i.test(x)).length);})"
# → 0
```

---

## 5.7 闸门的代码位置

```bash
grep -n 'omits scenario' src/core/validation/validator.ts                    # :808 ERROR 级（804-813）
grep -n 'Refresh the change spec before archiving' src/core/specs-apply.ts   # :567 硬拒绝（564-569）
grep -n -A6 'findArchiveBlockers' src/core/validation/validator.ts | head -20 # :1000-1055 干跑
grep -n 'new Validator(' src/core/archive.ts                                 # :73 :1458 :1879 均非严格
sed -n '1062,1065p' src/core/validation/validator.ts                          # strict 语义
grep -n 'file-existence only' src/core/templates/workflows/propose.ts         # :133 (:299) status 不是新鲜度
```

---

## 5.8 跨 change 检测确实不存在

```bash
for k in dependsOn provides touches parent; do
  printf "%-10s in src: %s\n" "$k" "$(grep -rn "\b$k\b" src/ --include='*.ts' | wc -l | tr -d ' ')"; done
# → dependsOn  0
# → provides   2   （全是注释散文，非字段）
# → touches    6   （全是注释散文，非字段）
# → parent    89   （全是路径/文件系统语义，非 change 元数据）

# 想确认它们不是元数据字段，直接看命中的形态：
grep -rn "\bprovides\b" src/ --include='*.ts'         # → "the caller provides…" 之类
grep -rn "\bparent\b" src/ --include='*.ts' | head -3 # → const parent = path.dirname(candidate); 之类

node bin/openspec.js change --help
# → Commands: show / list (DEPRECATED) / validate 　——没有 graph
```

> ⚠️ 初版这里写的是"全部 0"，**是错的**（`parent` 89 处）。但它们**没有一个**是 `add-change-stacking-awareness` 提案里的 change 元数据字段——`dependsOn` 才是该提案的核心，它是真 0（且提案目录本身已在 PR #2128 删除）。

本仓 4 个活跃 change 的争用实测：

```bash
for d in openspec/changes/*/; do
  name=$(basename "$d")
  [ "$name" = archive ] && continue
  ls "$d/specs" 2>/dev/null
done | sort | uniq -c | sort -rn | awk '$1>1'
# → 4 cli-update ／ 4 cli-init
```

---

## 5.9 自定义 schema 给方向建门控（在临时目录跑）

> ⚠️ **会写文件**。请在 `/tmp` 下跑，别在本仓库里跑。

```bash
cd /tmp && rm -rf schematest && mkdir -p schematest/openspec/specs schematest/openspec/changes && cd schematest

# 1. 建 schema（或用 schema fork spec-driven my-flow 从内置复制）
node /path/to/OpenSpec/bin/openspec.js schema init my-flow --artifacts proposal,tasks --no-default
printf '# Direction\n' > openspec/schemas/my-flow/templates/direction.md

# 2. 改 openspec/schemas/my-flow/schema.yaml，加 direction artifact（template: direction.md）
#    direction: generates direction.md, requires: []
#    proposal : requires: [direction]

# 3. 建 change 并观察门控
node /path/to/OpenSpec/bin/openspec.js new change test-dir --schema my-flow
node /path/to/OpenSpec/bin/openspec.js status --change test-dir
# → [ ] direction
#   [-] proposal (blocked by: direction)
#   [-] tasks    (blocked by: proposal)

node /path/to/OpenSpec/bin/openspec.js instructions proposal --change test-dir --json \
| node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
    console.log(JSON.stringify(j.dependencies));})"
# → [{"id":"direction","done":false,"path":"direction.md", …}]

# 4. 验证边界：空的 direction.md 也让 validate 通过
printf '# Direction\n' > openspec/changes/test-dir/direction.md
node /path/to/OpenSpec/bin/openspec.js validate test-dir --type change
# → Change 'test-dir' is valid     ← 门控的是存在，不是一致

# 5. 生命周期走得通：补齐后归档成功
node /path/to/OpenSpec/bin/openspec.js status --change test-dir          # 3/3 artifacts complete
node /path/to/OpenSpec/bin/openspec.js archive test-dir --yes            # archived as 2026-10-18-test-dir
```

**顺带证实**：schema 里没有 `specs` artifact 时，`new change` 自动写入 `skip_specs: true` ——

```bash
cat openspec/changes/test-dir/.openspec.yaml
# → schema: my-flow
#   created: 2026-10-18
#   skip_specs: true
```

---

## 5.10 配置面与内置 schema 的边界（第 6 章的证据）

> ⚠️ 会写临时目录。在 `/tmp` 下跑。**本节全部只用内置 `spec-driven`，不 fork schema。**

### 内置 schema 的四个 artifact，没有「方向」

```bash
grep -n "id:\|generates:\|requires:" schemas/spec-driven/schema.yaml | head -20
# → proposal  → proposal.md     requires: []
#   specs     → specs/**/*.md   requires: [proposal]
#   design    → design.md       requires: [proposal]
#   tasks     → tasks.md        requires: [specs, design]
# → 没有 direction / decision / rationale 之类
```

### 内置能力对 `## Why` 的内容零检查 ★关键

```bash
printf '# Proposal\n\n## Why\n\n<!-- Explain the motivation -->\n\n## What Changes\n\n<!-- Describe -->\n' \
  > openspec/changes/p1/proposal.md

node bin/openspec.js status --change p1
# → [x] proposal          ← 只剩模板注释也算完成

node bin/openspec.js validate p1 --type change
# → 唯一的 ERROR 是 "Change must have at least one delta"
node bin/openspec.js validate p1 --type change 2>&1 | grep -ci "why"
# → 0                     ← 没有任何一条检查 Why
```

### `specs` 的路径是 glob，脚本要用 `existingOutputPaths`

```bash
node bin/openspec.js status --change p1 --json | node -e "
let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{
  const a=JSON.parse(s).artifactPaths.specs;
  console.log('resolved:',a.resolvedOutputPath);
  console.log('existing:',a.existingOutputPaths);})"
# → resolved: …/p1/specs/**/*.md                  ← 保留 ** 字面量，不能当文件
#   existing: […/p1/specs/cap-a/spec.md]          ← 真实文件，脚本用这个
```

### `rules:` 单条写错会让整组失效

```bash
# 规则行首的 ## 没加引号 → YAML 当注释 → 该条读成 null
node bin/openspec.js instructions proposal --change p1 2>&1 >/dev/null | grep -i "must be an array"
# → Rules for 'proposal' must be an array of strings, ignoring this artifact's rules.
#   rules.proposal[0] is null — an unquoted ": " makes YAML read the item as a key/value pair
node bin/openspec.js instructions proposal --change p1 --json | node -e "
let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log('rules:',(JSON.parse(s).rules||[]).length))"
# → rules: 0              ← 整组被丢弃

# 整条加引号后恢复正常
# → rules: 3
```

### `operations.guidance` 进了两个面，但归档不读

```bash
node bin/openspec.js instructions apply   --change p1 --json | node -e "
let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).operationGuidance))"
node bin/openspec.js instructions archive --change p1 --json | node -e "
let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).operationGuidance))"
# → 两个面都返回数组（唯一进 apply/archive 的配置通道）

grep -c "readProjectConfig" src/core/archive.ts     # → 0   归档时根本不读它
```

### 内置 DAG 的绕过路径

```bash
# ① 空壳 proposal：见上方「零检查」——[x] proposal
# ② 手写下游文件可绕过 status 的引导
printf '# Tasks\n\n- [ ] x\n' > openspec/changes/p1/tasks.md
node bin/openspec.js status --change p1 | grep tasks
# → [x] tasks            ← status 只是建议，不是强制
```

### 新鲜度不被追踪

```bash
touch -t 202001010000 openspec/changes/p1/proposal.md    # 回退到 2020
node bin/openspec.js list --changes                      # → 仍显示 "just now"
node bin/openspec.js status --change p1                  # → 下游仍 [x]
```

`direction-gate.sh` 的四种状态（全新鲜 / `## Why` 空 / 方向早下游后 / 真漂移）已在 §[06.5](06-remedies-within-budget.md) 实测记录；脚本直接从该章代码块复制即可运行。

---

## 5.11 图的重建

图是手写 SVG（`figures/*.svg`），无构建依赖。要出位图预览：

```bash
cd _faq_on_digested/18_context-rot-and-direction-drift/figures
for f in *.svg; do rsvg-convert -w 1100 "$f" -o "/tmp/${f%.svg}.png"; done
```

XML 合法性检查：

```bash
for f in *.svg; do python3 -c "import xml.dom.minidom;xml.dom.minidom.parse('$f')" && echo "OK $f"; done
```

---

[← 返回索引](answer.md) ｜ 附录：[A · CLI 命令面 →](appendix-a-cli-surface.md)
