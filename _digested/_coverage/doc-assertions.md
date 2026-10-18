# 文档断言的机械校验台账

三套文档（`_digested/`、`_faq_on_digested/`、`_openspec_handbook/`）里有些断言**不需要人读**就能验伪：commit sha 是否存在、PR 编号是否对得上、版本归因是否落在正确的 tag、`文件:行号` 是否指到该行、相对链接是否可解析。这些错误肉眼极难发现（多为一位字符错位），但可以全量机械核对。

本文件记录校验口径、当前结果和复跑方法。它不是专题正文，是维护用索引。

## 为什么需要它

按目录逐轮审读能保证**深度**，但覆盖不了**横向传播的同一错误**。实测例子：

- 一个转录错误的 sha（`f2812f62`，真值 `f2812f6d`）散播在 4 个文件、3 个目录里，按目录审只会在遇到的那个目录里修掉。
- skill 名 `$openspec-propose-change` 在 handbook 修正后，`_digested` 里仍有 3 处残留——因为这两套是分开审的。

所以每轮打磨结束后，必须再跑一遍不设目录边界的全库扫描。

## 校验项与口径

| # | 断言类型 | 判定方法 | 当前 |
|---|---------|---------|------|
| 1 | commit sha | 后引号内的 7–40 位十六进制，逐个 `git cat-file -t` 必须返回 `commit` | 189 个，0 无效 |
| 2 | sha ↔ PR 配对 | 形如 `` `sha`（#NNNN） ``，`git log -1 --format=%s%n%b <sha>` 必须含该 PR | 56 组，0 不符 |
| 3 | 版本归因 | 形如 `` `sha`（vX.Y.Z） ``，`git tag --contains` 的**最小** tag 必须等于 X.Y.Z | 5 处，0 不符 |
| 4 | 行号锚点 | `` `src/...:N` `` 的 N 不得超过文件行数，且该行内容需与上下文描述相符 | 33 处，全部命中 |
| 5 | 相对链接 | 剥掉围栏代码块后匹配 markdown 链接语法（方括号文字紧跟圆括号目标），按文件所在目录解析，须存在 | 217 文件，0 失效 |
| 6 | 锚点 fragment | `#frag` 需存在于目标文件的标题 slug 集合中 | 同上，0 失效 |
| 7 | 代码围栏 | 每文件 ``` 计数为偶数 | 0 未配平 |

### 误判排除

扫描会命中大量**合法的历史引用**，不要当成错误：

- **已删除的路径**：`src/commands/context-store.ts`、`src/commands/initiative.ts` 在 v1.5.0 被 `a0decbe3` 删除，文档引用它们是在讲历史。
- **`docs-lab/` 下的路径**：如 `docs-lab/reference/schemas/spec-driven/index.md`，是合入的上游文档树，不是本仓库的 `schemas/`。
- **示例代码路径**：`src/orders/`、`src/auth/`、`src/routes/oauth.ts` 等是教学用的虚构项目，不对应本仓库。
- **范围端点**：台账写的 “hash 范围 `5956a8e` → `60f720c`” 中，端点通常晚于该版本 tag，文档会显式注明“不是 release 本身”。

## 复跑方法

```bash
cd /Users/bowhead/OpenSpec

# 1) 全部 sha 有效性
#    豁免：本文件的「sha 更正对照」表、以及台账里记录"曾经写错"的行，
#    天然包含无效 sha，用 EXEMPT 按文件+行内容跳过。
python3 - <<'PY'
import re,glob,subprocess
# 记录"旧值→真值"的行天然含无效 sha：更正对照表、以及正文里的纠错说明
EXEMPT_LINE = re.compile(r'更正对照|文档原值|转录错误|→|^\|\s*`[0-9a-f]{7,40}`\s*\|')
bad=0
for f in glob.glob('_digested/**/*.md',recursive=True)+glob.glob('_faq_on_digested/**/*.md',recursive=True)+glob.glob('_openspec_handbook/*.md'):
    for i,line in enumerate(open(f,encoding='utf-8'),1):
        if EXEMPT_LINE.search(line): continue
        for x in set(re.findall(r'`([0-9a-f]{7,40})`',line)):
            if x.isdigit(): continue
            if subprocess.run(['git','cat-file','-t',x],capture_output=True).returncode!=0:
                bad+=1; print(f,i,x)
print("无效 sha:",bad)
PY

# 2) 链接与锚点
python3 - <<'PY'
import re,os,glob
def strip(s):
    out=[];inf=False
    for l in s.split('\n'):
        if re.match(r'^\s*(```|~~~)',l): inf=not inf; out.append(''); continue
        out.append('' if inf else l)
    return '\n'.join(out)
def slug(h):
    s=re.sub(r'[`*_~]','',h.strip().lower())
    s=re.sub(r'[^\w\u4e00-\u9fff\s-]','',s)
    return re.sub(r'\s+','-',s).strip('-')
fs=[f for f in glob.glob('_digested/**/*.md',recursive=True)+glob.glob('_faq_on_digested/**/*.md',recursive=True)+glob.glob('_openspec_handbook/**/*.md',recursive=True)]
an={os.path.abspath(f):{slug(m.group(1)) for m in re.finditer(r'^#{1,6}\s+(.+)$',strip(open(f,encoding='utf-8').read()),re.M)} for f in fs}
bad=[]
for f in fs:
    for m in re.finditer(r'!?\[[^\]]*\]\(([^)\s]+)\)',strip(open(f,encoding='utf-8').read())):
        t=m.group(1)
        if t.startswith(('http','mailto:','#')): continue
        p,_,fr=t.partition('#')
        if not p: continue
        tg=os.path.normpath(os.path.join(os.path.dirname(f),p))
        if not os.path.exists(tg): bad.append((f,t))
        elif fr and os.path.abspath(tg) in an and fr not in an[os.path.abspath(tg)]: bad.append((f,t,'frag'))
print("失效:",len(bad))
PY
```

## 历史修复记录

| 轮次 | 修掉 | 提交 |
|------|------|------|
| 0012 收尾 | 5 个转录错误的 sha（跨 7 文件 4 目录）、`$openspec-propose-change` 残留 3 处、虚构子命令 `workset save` | `e5f66e0f`、`10c62a4e` |

已知的 sha 更正对照：

| 文档原值 | 真值 | PR | 备注 |
|---------|------|----|------|
| `6e62b5d5` | `6e62b1d5` | #1806 | 拒绝畸形 RENAMED 对 |
| `db560a63` | `db560ae3` | #1858 | 拒绝无正文 scenario header |
| `f2812f62` | `f2812f6d` | #1926 | Windows EPERM 复制；同时引入 `deepestExistingAncestor`（回滚剪裁） |
| `e7a951d` | `e7a9512d` | #1994 | apply 任务源定位 |

## 升级版本时的用法

1. 先按目录逐个打磨（事实核验 → 修正 → 链接校验 → 提交）。
2. 每轮结束跑上面的全库扫描；**新增的 sha/PR/版本断言必须全绿**。
3. 有新发现就追加到「历史修复记录」，并把复跑脚本里新增的判定类型补进「校验项与口径」表。
