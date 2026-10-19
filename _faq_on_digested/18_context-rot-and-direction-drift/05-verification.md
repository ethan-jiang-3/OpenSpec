# 05 · 可复跑验证

[← 返回索引](answer.md) ｜ 上一篇：[04 · 使用要点](04-usage.md)

以下命令在本仓库根目录可直接跑（`node bin/openspec.js` 等价于全局 `openspec`）。**每条都跑过**，注释里是当时的实际输出。

> ⚠️ 带 `mkdir`/`cd /tmp` 的那一节会**写临时目录**，不要在本仓库里跑。

---

## 5.1 证据边界：`src/` 与上游逐字节一致

```bash
# src/ 相对 upstream/main 无改动（输出 0）
git diff --name-only upstream/main..ethan -- src/ | wc -l
# → 0

# 241 个变更文件全部是文档，无一行 src/
git diff --name-only upstream/main..ethan | wc -l
# → 241
git -c core.quotepath=false diff --name-only upstream/main..ethan \
  | awk -F/ '{print $1}' | sort | uniq -c
# → 118 _digested ／ 102 _faq_on_digested ／ 19 _openspec_handbook ／ 1 .gitignore ／ 1 CONTEXT.md
```

`-c core.quotepath=false` 是必需的：中文文件名会被 git 转义成 `"\344..."` 形式，导致目录统计出现重复项。

---

## 5.2 注入体 vs 规格树规模

```bash
find openspec/specs -name '*.md' | wc -l                                   # 36
cat openspec/specs/*/spec.md | wc -c                                       # 261948
cat openspec/specs/*/spec.md | wc -l                                       # 5758
grep -rhc '^### Requirement:' openspec/specs/*/spec.md | paste -sd+ - | bc # 252
grep -rhc '^#### Scenario:'   openspec/specs/*/spec.md | paste -sd+ - | bc # 749

# 最大单文件
for f in openspec/specs/*/spec.md; do printf "%8d %s\n" "$(wc -c < "$f")" "$f"; done | sort -rn | head -3
# → 19949 cli-completion …／16298 cli-archive …／14269 cli-artifact-workflow …

# 单次注入总量
node bin/openspec.js instructions specs --change add-amp-support --json | wc -c   # 9315
node bin/openspec.js instructions apply --change add-amp-support --json | wc -c   # 3930

# 载荷字段与各自体量
node bin/openspec.js instructions specs --change add-amp-support --json \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
      for(const k of Object.keys(j))console.log('  ',k,'=',(typeof j[k]==='string'?j[k].length:JSON.stringify(j[k]).length));})"
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
# → cli-archive:         18013 -> 2845

node bin/openspec.js list --specs --json | wc -c      # 2687
node bin/openspec.js show --help                       # 确认 --no-scenarios / -r 存在
```

---

## 5.4 50 KB 闸门与 profile

```bash
grep -n 'MAX_CONTEXT_SIZE' src/core/project-config.ts src/core/references.ts
# → project-config.ts:248:export const MAX_CONTEXT_SIZE = 50 * 1024; // 50KB hard limit…
# → references.ts … 引用同一常量；截断分支在 references.ts:510-517

node bin/openspec.js config get profile               # core
grep -n 'CORE_WORKFLOWS\|ALL_WORKFLOWS' src/core/profiles.ts | head -3
# → :14 CORE_WORKFLOWS = ['propose','explore','apply','update','sync','archive']
```

---

## 5.5 `rules:` 按 artifact 分流

```bash
for a in proposal specs design tasks; do printf "%-9s" "$a"; \
  node bin/openspec.js instructions "$a" --change add-amp-support --json 2>/dev/null \
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
# → Totals: 36 passed, 0 failed (36 items)   exit=0

node bin/openspec.js validate --specs --strict ; echo "exit=$?"
# → Totals: 34 passed, 2 failed (36 items)   exit=1

node bin/openspec.js validate --all ; echo "exit=$?"
# → Totals: 60 passed, 6 failed (66 items)

node bin/openspec.js validate --all --strict ; echo "exit=$?"
# → Totals: 53 passed, 13 failed (66 items)   exit=1
```

级别与种类分布，以及 **scenario 丢失的精确条数**：

```bash
node bin/openspec.js validate --all --json 2>/dev/null \
| node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
    const L={};let loss=0,items=new Set();
    for(const it of j.items)for(const is of (it.issues||[])){
      L[is.level]=(L[is.level]||0)+1;
      if(/omits scenario\(s\)/.test(is.message)){loss++;items.add(it.id);}}
    console.log('级别:',JSON.stringify(L));            // {"WARNING":12,"ERROR":11,"INFO":2}
    console.log('scenario 丢失条数:',loss);            // 10
    console.log('涉及 change:',[...items].join(', ')); // 5 个
    console.log('totals:',JSON.stringify(j.summary.totals));})"
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
grep -n 'omits scenario' src/core/validation/validator.ts                    # :779-786 ERROR 级
grep -n 'Refresh the change spec before archiving' src/core/specs-apply.ts   # :552 硬拒绝
grep -n -A6 'findArchiveBlockers' src/core/validation/validator.ts | head -20 # :958-1013 干跑
grep -n 'new Validator(' src/core/archive.ts                                 # :73 :1458 :1879 均非严格
sed -n '1016,1023p' src/core/validation/validator.ts                          # strict 语义
grep -n 'file-existence only' src/core/templates/workflows/propose.ts         # status 不是新鲜度
```

---

## 5.8 跨 change 检测确实不存在

```bash
for k in dependsOn provides touches parent; do
  printf "%-10s in src: %s\n" "$k" "$(grep -rn "\b$k\b" src/ --include=*.ts | wc -l)"; done
# → dependsOn  0
# → provides   2   （全是注释散文，非字段）
# → touches    2   （全是注释散文，非字段）
# → parent    87   （全是路径/文件系统语义，非 change 元数据）

# 想确认它们不是元数据字段，直接看命中的形态：
grep -rn "\bprovides\b" src/ --include=*.ts   # → "the caller provides…" 之类
grep -rn "\bparent\b" src/ --include=*.ts | head -3  # → const parent = path.dirname(candidate); 之类

node bin/openspec.js change --help
# → Commands: show / list (DEPRECATED) / validate 　——没有 graph
```

> ⚠️ 初版这里写的是"全部 0"，**是错的**（`parent` 87 处）。但它们**没有一个**是 `add-change-stacking-awareness` 提案里的 change 元数据字段——`dependsOn` 才是该提案的核心，它是真 0。

本仓 8 路争用实测：

```bash
cd openspec/changes
for d in */; do d=${d%/}; [ "$d" = archive ] && continue; \
  ls "$d/specs" 2>/dev/null | sed "s|^|$d |"; done > /tmp/capmap.txt
cut -d' ' -f2 /tmp/capmap.txt | sort | uniq -c | sort -rn | awk '$1>1'
# → 8 cli-init ／ 6 cli-update ／ 6 ai-tool-paths ／ 5 command-generation ／ …
```

---

## 5.9 自定义 schema 给方向建门控（在临时目录跑）

> ⚠️ **会写文件**。请在 `/tmp` 下跑，别在本仓库里跑。

```bash
cd /tmp && rm -rf schematest && mkdir schematest && cd schematest

# 1. 建 schema（或用 schema fork spec-driven my-flow 从内置复制）
node /path/to/OpenSpec/bin/openspec.js schema init my-flow --no-default

# 2. 改 openspec/schemas/my-flow/schema.yaml，加 direction artifact
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

## 5.10 配置面与门控绕过（第 6 章的证据）

> ⚠️ 会写临时目录。在 `/tmp` 下跑。

### `operations.guidance` 真的进了两个面

```bash
# 在 config.yaml 里加 operations.apply.guidance / operations.archive.guidance
node bin/openspec.js instructions apply   --change <name> --json \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).operationGuidance))"
node bin/openspec.js instructions archive --change <name> --json \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).operationGuidance))"
# → 两个面都返回数组；说明它是唯一进 apply/archive 的配置通道
```

**归档不读它**：

```bash
grep -c "readProjectConfig" src/core/archive.ts     # → 0
```

### `rules:` 的键可以是自定义 artifact id

```bash
# schema 里有 direction artifact，config.yaml 写 rules.direction
node bin/openspec.js instructions direction --change <name> --json \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).rules))"
# → 注入成功
```

### `rules:` 写错：只有 stderr，`validate` 不报

```bash
# 把 rules.direction 拼成 rules.dirrection
node bin/openspec.js instructions proposal --change <name> 2>&1 >/dev/null | grep "Unknown artifact"
# → Unknown artifact ID in rules: "dirrection". … Known artifact IDs: design, direction, …
node bin/openspec.js instructions proposal --change <name> 2>/dev/null | grep -c "Unknown artifact"
# → 0（stdout 里没有）
node bin/openspec.js validate --all 2>&1 | grep -c "Unknown artifact"
# → 0（validate 完全不报）

grep -rn "validateConfigRules" src/ --include=*.ts
# → 唯一调用点：src/core/artifact-graph/instruction-loader.ts:385
```

### 门控绕过路径

```bash
# ① 空壳文件即通过
printf '# Direction\n' > openspec/changes/probe/direction.md
node bin/openspec.js status --change probe | grep -E "direction|proposal"
# → [x] direction
#   [ ] proposal          ← 一行标题就解锁

# ② generates 复用同一文件 → 白拿 done
#    把某个后置 artifact 的 generates 指向 direction.md
node bin/openspec.js status --change probe | grep freshness
# → [x] freshness          ← 没做任何检查

# ③ 手写下游文件可绕过引导
printf '# Proposal\n' > openspec/changes/probe/proposal.md
node bin/openspec.js status --change probe | grep proposal
# → [x] proposal           ← status 只是建议，不是强制
```

### 新鲜度不被追踪

```bash
touch -t 202001010000 openspec/changes/probe/direction.md   # 回退到 2020
node bin/openspec.js list --changes          # → 仍显示 "just now"
node bin/openspec.js status --change probe   # → 下游仍 [x]
```

新鲜度闸门脚本的四种状态（空壳 / 通过 / 陈旧 / 通过）已在 §[06.4](06-remedies-within-budget.md) 实测记录。

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
