#!/usr/bin/env bash
#
# upgrade-all.sh —— 把本机所有 OpenSpec 项目升级到 v2.x 并清理历史残留
#
# 设计原则
#   1. 默认只看不动（plan 模式），加 --apply 才写盘。
#   2. 可重复执行（幂等）：每一步都先判断当前状态，已经做完的自动跳过。
#   3. 单个项目失败不影响其余项目，最后统一汇总。
#   4. 每个项目独立提交（--commit 时），出问题可单独回退。
#
# 用法
#   ./upgrade-all.sh                       # 计划模式：只输出每个项目会发生什么
#   ./upgrade-all.sh --apply               # 真正执行（含 CLI 升级）
#   ./upgrade-all.sh --apply --clean       # 执行 + 清理历史残留（.cline 等）
#   ./upgrade-all.sh --apply --commit      # 执行 + 每项目自动提交
#   ./upgrade-all.sh --apply --only ai_tool_ppt_maker
#   ./upgrade-all.sh --apply --skip ait_exam_openspec_plms
#   ./upgrade-all.sh --apply --skip-cli    # 不升 CLI（已升过，只跑项目）
#
set -uo pipefail

# ─────────────────────────── 参数 ───────────────────────────
MODE=plan; APPLY=0; CLEAN=0; COMMIT=0; SKIP_CLI=0; ALLOW_DIRTY=0; NO_BACKUP=0; NO_VERIFY=0; RESTORE=""
ONLY=""; SKIP=""
EXPECTED_MAJOR=2
LOG="$HOME/openspec-upgrade-$(date +%Y%m%d-%H%M%S).log"

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)       APPLY=1 ;;
    --clean)       CLEAN=1 ;;
    --commit)      COMMIT=1 ;;
    --skip-cli)    SKIP_CLI=1 ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    --no-backup)   NO_BACKUP=1 ;;
    --no-verify)   NO_VERIFY=1 ;;
    --restore)     if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then RESTORE="$2"; shift; else RESTORE=latest; fi ;;
    --only)        ONLY="${2:-}"; shift ;;
    --skip)        SKIP="${2:-}"; shift ;;
    -h|--help)     sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done
[ "$APPLY" = 1 ] && MODE=apply
[ -n "$RESTORE" ] && SKIP_CLI=1   # 恢复模式不动 CLI

# ─────────────────────────── 输出 ───────────────────────────
if [ -t 1 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; N=$'\033[0m'
else B=""; DIM=""; R=""; G=""; Y=""; N=""; fi
say()  { printf '%s\n' "$*" | tee -a "$LOG" >/dev/null; printf '%s\n' "$*"; }
hdr()  { say ""; say "${B}════ $* ════${N}"; }
ok()   { say "  ${G}✓${N} $*"; }
warn() { say "  ${Y}!${N} $*"; }
err()  { say "  ${R}✗${N} $*"; }
info() { say "  ${DIM}·${N} $*"; }

# 结果收集
declare -a R_DONE R_SKIP R_FAIL
markdone() { R_DONE+=("$1"); }
markskip() { R_SKIP+=("$1"); }
markfail() { R_FAIL+=("$1"); }

# ─────────────────────────── 常量 ───────────────────────────
OPENSPEC_DIR_NAME="openspec"
CONFIG_REL="openspec/config.yaml"

# 绝不触碰的项目（源码仓库 / 内含整份 OpenSpec 源码的项目）
PROTECTED=("OpenSpec" "ai_dev_spec")

# 本脚本负责的项目（实测清单，2026-11-21）
DEFAULT_PROJECTS=(
  ai_deerflow_dr_v3
  ai_dsh_bsimulation
  ai_pi_deep_research
  ai_tool_bsimulation
  ai_deerflow_deep_research_v2
  ai_tool_deepresearch
  ai_deerflow_wiki
  ait_exam_openspec_calender
  ait_exam_openspec_demo
  ait_exam_openspec_ticketflow
  ai_tool_ppt_maker
  ait_exam_haitai
  openspec-schemas
  ait_exam_openspec_plms
)

# 判定「不属于 OpenSpec 的脏文件」数量（内嵌 python，供脏检测调用）
read -r -d '' FOREIGN_COUNTER <<'PYCNT' || true
import sys, re
opsx = re.compile(r"^(\.claude|\.cursor|\.agents|\.codex|\.cline|\.clinerules|\.agent|\.opencode|\.dsh|\.pi)(/|$)|^openspec/config\.yaml$")
n = 0
for line in sys.stdin:
    path = line.strip()
    if path and not opsx.search(path):
        n += 1
print(n)
PYCNT

# ─────────────────────────── 前置检查 ───────────────────────────
require_cmd() { command -v "$1" >/dev/null 2>&1 || { err "缺少命令: $1"; exit 1; }; }
require_cmd git
require_cmd node
require_cmd python3
command -v openspec >/dev/null 2>&1 || { err "PATH 上没有 openspec，先在能用的 Node 环境下运行"; exit 1; }

say "${B}OpenSpec 批量升级${N}  模式=${MODE}  清理=${CLEAN}  提交=${COMMIT}  跳过CLI=${SKIP_CLI}"
say "日志: $LOG"
say "Node: $(node -v)   CLI: $(openspec --version 2>/dev/null || echo '?')"

NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
NODE_MINOR=$(node -v | sed 's/^v//' | cut -d. -f2)
if [ "$NODE_MAJOR" -lt 22 ] || { [ "$NODE_MAJOR" -eq 22 ] && [ "$NODE_MINOR" -lt 20 ]; }; then
  err "Node $(node -v) 低于 2.1.x 要求的 22.20.0，中止"; exit 1
fi

# ─────────────────────────── 工具函数 ───────────────────────────

# 项目是否受支持：有 openspec/ 目录，且不在保护名单
project_ok() {
  local p="$1"
  [ -d "$HOME/$p/$OPENSPEC_DIR_NAME" ] || return 1
  for prot in "${PROTECTED[@]}"; do [ "$p" = "$prot" ] && return 1; done
  return 0
}

# 确保项目 config.yaml 有 skillsScope: project（幂等）
ensure_scope() {
  local dir="$1" cfg="$1/$CONFIG_REL"
  [ -f "$cfg" ] || { info "无 config.yaml，跳过作用域设置"; return 0; }
  if grep -qE '^skillsScope:[[:space:]]*project[[:space:]]*$' "$cfg"; then
    info "skillsScope 已是 project"
    return 0
  fi
  if [ "$APPLY" = 1 ]; then
    if grep -qE '^skillsScope:' "$cfg"; then
      python3 - "$cfg" <<'PYX'
import sys, re, pathlib
p = pathlib.Path(sys.argv[1])
p.write_text(re.sub(r'^skillsScope:.*$', 'skillsScope: project', p.read_text(), count=1, flags=re.M))
PYX
      ok "skillsScope 改为 project"
    else
      printf 'skillsScope: project\n' >> "$cfg"
      ok "已写入 skillsScope: project"
    fi
  else
    info "[plan] 将写入 skillsScope: project"
  fi
}

# 统计残留（不属于 .agents/skills 真身的旧技能/命令）
# 备份工具目录与 config（有些项目把 .claude/ 等 gitignore 了，git 回滚不了）
BACKUP_DIR="$HOME/openspec-upgrade-backups"
backup_project() {
  local dir="$1" name="$2" ts; ts=$(date +%Y%m%d-%H%M%S)
  mkdir -p "$BACKUP_DIR"
  local out="$BACKUP_DIR/${name}-${ts}.tgz"
  local present=()
  for d in .claude .cursor .agents .cline .codex .agent .clinerules .opencode .dsh .pi openspec; do
    [ -e "$dir/$d" ] && present+=("$d")
  done
  [ "${#present[@]}" -eq 0 ] && { info "无可备份目录"; return 0; }
  if tar -czf "$out" -C "$dir" "${present[@]}" 2>/dev/null; then
    ok "已备份 → $out ($(du -h "$out" | cut -f1 | tr -d ' '))"
  else
    warn "备份失败，但继续（请自行确认 $dir 的状态）"
  fi
}

# 从备份恢复。符号链接会让 tar 拒绝覆盖目录，所以先删再解。
restore_project() {
  local dir="$1" name="$2" which="${3:-latest}"
  local file
  if [ "$which" = latest ]; then
    file=$(ls -t "$BACKUP_DIR/${name}-"*.tgz 2>/dev/null | head -1)
  else
    file="$which"
  fi
  [ -n "$file" ] && [ -f "$file" ] || { err "找不到 $name 的备份"; return 1; }
  info "使用备份: $file"
  local dirs=".claude .cursor .agents .cline .codex .agent .clinerules .opencode .dsh .pi openspec"
  for d in $dirs; do
    [ -e "$dir/$d" ] && rm -rf "$dir/$d"
  done
  if tar -xzf "$file" -C "$dir"; then ok "已恢复"; else err "恢复失败"; return 1; fi
}

# 只找「OpenSpec 自己的」残留：路径命中白名单，且内容确实是 OpenSpec 生成的。
# 绝不按目录名一刀切——.agent/、.cline/ 里可能混着用户自己的技能。
find_stale() {
  local dir="$1"
  find "$dir" -maxdepth 5 \
    \( -path '*/node_modules' -o -path '*/.git' -o -path '*/dist' -o -path '*/.cache' \) -prune -o \
    \( -path '*/commands/opsx/*' -o -path '*/commands/opsx/*/*' \
       -o -path '*/.clinerules/workflows/opsx-*' -o -path '*/.clinerules/workflows/openspec-*' \
       -o -path '*/.cline/skills/openspec-*/*' -o -path '*/prompts/openspec-*' \
       -o -path '*/.codex/prompts/openspec-*' -o -path '*/.github/prompts/opsx-*' \) -type f -print 2>/dev/null \
  | while IFS= read -r f; do
      # 内容校验：必须是 OpenSpec 生成物（含 openspec 署名或 OPSX 标记）
      if grep -qiE 'author:[[:space:]]*openspec|name:[[:space:]]*["'"'"']?openspec-|name:[[:space:]]*["'"'"']?OPSX' "$f" 2>/dev/null; then
        printf '%s\n' "$f"
      fi
    done
}

clean_stale() {
  local dir="$1" list="$2"
  [ -z "$list" ] && { info "无残留需要清理"; return 0; }
  local n; n=$(printf '%s\n' "$list" | grep -c . || true)
  if [ "$APPLY" = 1 ]; then
    printf '%s\n' "$list" | while IFS= read -r f; do [ -n "$f" ] && rm -f "$f"; done
    # 清空目录
    printf '%s\n' "$list" | while IFS= read -r f; do
      [ -n "$f" ] && rmdir -p "$(dirname "$f")" 2>/dev/null || true
    done
    ok "清理 $n 个残留文件"
  else
    info "[plan] 将清理 $n 个残留文件（示例：$(printf '%s\n' "$list" | head -2 | tr '\n' ' ')）"
  fi
}

# 校验一个项目升级后的形态
verify_project() {
  local dir="$1" name="$2" problems=0

  # 1) CLI 能识别项目
  if ! ( cd "$dir" && openspec list --json >/dev/null 2>&1 ); then
    warn "openspec list --json 返回非零（根不存在时属正常）"; fi

  # 2) 共享技能真身
  local shared="$dir/.agents/skills"
  if [ -d "$shared" ]; then
    local n=0
    for k in propose explore apply-change update-change sync-specs archive-change \
             new-change continue-change ff-change verify-change bulk-archive-change onboard; do
      [ -f "$shared/openspec-$k/SKILL.md" ] && n=$((n+1))
    done
    if [ "$n" -ge 6 ]; then ok "OpenSpec 官方技能 $n 个"; else warn "官方技能只有 $n 个（预期 ≥6）"; problems=$((problems+1)); fi
  else
    warn "没有 .agents/skills（该项目可能用全局作用域）"
  fi

  # 3) 命令文件应已消失
  local cmds; cmds=$(find "$dir" -maxdepth 4 -path '*/commands/opsx*' -type f 2>/dev/null | head -5)
  if [ -z "$cmds" ]; then ok "无 commands/opsx 残留"; else warn "仍有命令文件:"; printf '%s\n' "$cmds" | sed 's/^/      /'; problems=$((problems+1)); fi

  # 4) 工具清单
  local marker="$shared/.openspec-target"
  if [ -f "$marker" ]; then
    local m; m=$(grep -c . "$marker" || true)
    ok ".openspec-target 有 $m 个工具"
  fi

  # 5) 工具目录：是链接还是拷贝
  for t in .claude .cursor .cline .opencode .dsh .pi; do
    local d="$dir/$t/skills"
    [ -d "$d" ] || continue
    local links copies
    links=$(find "$d" -maxdepth 1 -type l | wc -l | tr -d ' ')
    copies=$(find "$d" -maxdepth 1 -mindepth 1 ! -type l | wc -l | tr -d ' ')
    ok "$t/skills: 链接 $links / 实体 $copies"
  done

  # 6) spec 内容未被动
  if [ -d "$dir/openspec/specs" ]; then
    local s; s=$(find "$dir/openspec/specs" -name '*.md' | wc -l | tr -d ' ')
    ok "specs 文件 $s 个（未应被改动）"
  fi

  return $problems
}

# ─────────────────────────── 阶段 0：升级全局 CLI ───────────────────────────
hdr "阶段 0：全局 CLI"
CLI_BEFORE=$(openspec --version 2>/dev/null || echo "?")
info "当前版本: $CLI_BEFORE"

if [ "$SKIP_CLI" = 1 ]; then
  info "按参数跳过 CLI 升级"
else
  if [ "$APPLY" = 1 ]; then
    [ -f "$HOME/.config/openspec/config.json" ] && cp "$HOME/.config/openspec/config.json" "$HOME/.config/openspec/config.json.bak.$(date +%Y%m%d-%H%M%S)"
    if npm install -g @fission-ai/openspec@latest >>"$LOG" 2>&1; then
      hash -r
      ok "已升级到 $(openspec --version 2>/dev/null || echo '?')"
    else
      err "npm 全局升级失败，详见 $LOG"; exit 1
    fi
  else
    info "[plan] 将执行: npm install -g @fission-ai/openspec@latest"
  fi
fi

CLI_NOW=$(openspec --version 2>/dev/null || echo "?")
say "  CLI: $CLI_BEFORE → $CLI_NOW"
if [ "$APPLY" = 1 ] && [ "$SKIP_CLI" != 1 ]; then
  case "$CLI_NOW" in
    "$EXPECTED_MAJOR".*) ok "已是 v$EXPECTED_MAJOR.x" ;;
    *) err "升级后版本仍是 ${CLI_NOW}，中止"; exit 1 ;;
  esac
fi

# ─────────────────────────── 恢复模式 ───────────────────────────
if [ -n "$RESTORE" ]; then
  hdr "恢复模式"
  for name in "${DEFAULT_PROJECTS[@]}"; do
    [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
    dir="$HOME/$name"
    [ -d "$dir" ] || { markskip "$name (不存在)"; continue; }
    say ""
    say "${B}── $name ──${N}"
    if [ "$APPLY" = 1 ]; then
      restore_project "$dir" "$name" "$RESTORE" && markdone "$name" || markfail "$name (恢复失败)"
    else
      info "[plan] 将用最新备份恢复 $name"
      markdone "$name"
    fi
  done
  hdr "汇总"
  [ "${#R_DONE[@]}" -gt 0 ] && ok "恢复 ${#R_DONE[@]} 个: ${R_DONE[*]}"
  [ "${#R_FAIL[@]}" -gt 0 ] && err "失败 ${#R_FAIL[@]} 个: ${R_FAIL[*]}"
  [ "$APPLY" != 1 ] && say "确认后加 --apply 真正恢复。"
  exit 0
fi

# ─────────────────────────── 阶段 1：逐项目处理 ───────────────────────────
hdr "阶段 1：项目"

for name in "${DEFAULT_PROJECTS[@]}"; do
  [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
  [ -n "$SKIP" ] && [ "$name" = "$SKIP" ] && { markskip "$name (按参数跳过)"; continue; }

  dir="$HOME/$name"
  if ! project_ok "$name"; then
    warn "${name}：不是可处理的项目（缺 openspec/ 或在保护名单），跳过"
    markskip "$name (不适用)"
    continue
  fi

  say ""
  say "${B}── $name ──${N}"

  # update 本身幂等：无论之前是否升级过，跑一次都能收敛到当前 CLI 的状态
  [ -f "$dir/.agents/skills/.openspec-target" ] && info "已有 .openspec-target（可能是 1.x 或已升过），以下步骤仍会重新收敛"

  # git 清洁度
  if [ -d "$dir/.git" ]; then
    dirty=$(git -C "$dir" status --porcelain 2>/dev/null | grep -vE '\.DS_Store$' | wc -l | tr -d ' ')
    # 区分「OpenSpec 自己的生成物」和「用户自己的工作」：前者可被升级覆盖，后者绝不擅动
    foreign=0
    if [ "$dirty" -gt 0 ]; then
      foreign=$(git -C "$dir" status --porcelain 2>/dev/null | grep -vE '\.DS_Store$' \
        | sed 's/^...//' | python3 -c "$FOREIGN_COUNTER")
    fi
    if [ "$foreign" -gt 0 ] && [ "$ALLOW_DIRTY" != 1 ]; then
      err "$name 有 $foreign 处**不属于 OpenSpec** 的未提交改动，跳过"
      git -C "$dir" status --porcelain 2>/dev/null | grep -vE '\.DS_Store$' | head -5 | sed 's/^/      /'
      markfail "$name (有你自己的未提交改动)"
      continue
    fi
    if [ "$dirty" -gt 0 ]; then
      info "有 $dirty 处未提交改动，全部是 OpenSpec 生成物，可被本次升级覆盖"
    fi
  else
    warn "不是 git 仓库，无法回滚，跳过"
    markfail "$name (无 git)"
    continue
  fi

  # 作用域
  ensure_scope "$dir"

  # 预演
  plan_json=$( cd "$dir" && OPENSPEC_NO_UPDATE_CHECK=1 openspec update --dry-run --json 2>>"$LOG" )
  if [ -z "$plan_json" ]; then
    err "预演失败，见日志"; markfail "$name (dry-run 失败)"; continue
  fi
  printf '%s' "$plan_json" | python3 -c '
import sys, json
from collections import Counter
try:
    d = json.load(sys.stdin)
except Exception:
    print("  · 预演输出非 JSON")
    sys.exit(0)
ch = d.get("changes", []); notes = d.get("notes", []); fails = d.get("failures", [])
c = Counter(x["action"] for x in ch)
summary = dict(c) if ch else "(无变化)"
print("  · 计划: %d 项 %s" % (len(ch), summary))
for n in notes:
    print("  · note:", n.get("code"))
for f in fails:
    print("  · 失败:", f.get("tool"), str(f.get("error", ""))[:70])
'

  # 备份（apply 模式总是先备份；--no-backup 可关）
  if [ "$APPLY" = 1 ] && [ "$NO_BACKUP" != 1 ]; then
    backup_project "$dir" "$name"
  fi

  # 真跑
  if [ "$APPLY" = 1 ]; then
    if ( cd "$dir" && OPENSPEC_NO_UPDATE_CHECK=1 openspec update >>"$LOG" 2>&1 ); then
      ok "update 完成"
    else
      err "update 失败，见日志"
      markfail "$name (update 失败)"
      continue
    fi
  else
    info "[plan] 将执行 openspec update"
  fi

  # 清理
  if [ "$CLEAN" = 1 ]; then
    stale=$(find_stale "$dir")
    clean_stale "$dir" "$stale"
  fi

  # 校验
  if [ "$APPLY" = 1 ]; then
    verify_project "$dir" "$name"
  fi

  # 提交
  if [ "$APPLY" = 1 ] && [ "$COMMIT" = 1 ] && [ -d "$dir/.git" ]; then
    if [ -n "$(git -C "$dir" status --porcelain)" ]; then
      git -C "$dir" add -A >/dev/null 2>&1
      verify=""; [ "$NO_VERIFY" = 1 ] && verify="--no-verify"
      if git -C "$dir" commit -q $verify -m "chore: upgrade OpenSpec to v$CLI_NOW (commands removed, skills shared)" >>"$LOG" 2>&1; then
        ok "已提交"
      else
        warn "提交失败（仓库的 pre-commit 钩子挡住了生成文件），改动已暂存"
        info "处理: 在该仓库手动 git commit --no-verify，或重跑本脚本时加 --no-verify"
      fi
    else
      info "无改动，不提交"
    fi
  fi

  markdone "$name"
done

# ─────────────────────────── 汇总 ───────────────────────────
hdr "汇总"
[ "${#R_DONE[@]}" -gt 0 ] && { ok "完成 ${#R_DONE[@]} 个: ${R_DONE[*]}"; }
[ "${#R_SKIP[@]}" -gt 0 ] && { info "跳过 ${#R_SKIP[@]} 个: ${R_SKIP[*]}"; }
[ "${#R_FAIL[@]}" -gt 0 ] && { err "失败 ${#R_FAIL[@]} 个: ${R_FAIL[*]}"; }

say ""
if [ "$APPLY" != 1 ]; then
  say "${Y}这是计划模式，什么都没改。${N}"
  say "确认无误后加 --apply 真正执行；建议先加 --clean 看清单、再加 --commit 自动提交。"
  say "例:  $0 --apply --clean --commit"
else
  say "日志: $LOG"
  say "回滚单个项目: cd ~/<项目> && git checkout -- . && git clean -fd"
  say "回滚全局 CLI: npm install -g @fission-ai/openspec@1.15.0"
fi

[ "${#R_FAIL[@]}" -gt 0 ] && exit 1
exit 0
