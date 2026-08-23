#!/usr/bin/env bash
# ============================================================
# init.sh — 把 ai-dev-guide 部署到目标项目
# 用法：
#   init.sh <目标项目根> [选项]
#   选项：
#     --dir <名>     系统目录名（默认 ai-dev-guide）
#     --no-ui        裁剪 UI 裁剪组（无 UI 项目）
#     --no-example   裁剪栈范例（非参考栈）
#   交互询问栈信息不可用时暂停；全部产物落地后跑部署门禁并报告。
# 产物：
#   <项目>/<sys>/            部署平面文档（按裁剪组过滤）+ 运行时脚本 + .deploy-baseline.txt
#   <项目>/AGENTS.md         由模板生成（{{SYS}} 替换、{{INDEX}} 实例化）
#   <项目>/backlog.md        待办登记簿实例（含计数器）
#   <项目>/CONTEXT.md        术语表实例
#   <项目>/docs/ability-domains.md / architecture-debt.md   登记簿实例
#   <项目>/docs/{journal,specs,research,archive}/   登记目录约定
# ============================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$HERE/.." && pwd)"

TARGET=""; SYSNAME="ai-dev-guide"; NO_UI=0; NO_EX=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) SYSNAME="$2"; shift 2 ;;
    --no-ui) NO_UI=1; shift ;;
    --no-example) NO_EX=1; shift ;;
    *) TARGET="$1"; shift ;;
  esac
done

[ -n "$TARGET" ] || { echo "用法: init.sh <目标项目根> [--dir 名] [--no-ui] [--no-example]"; exit 2; }
case "$SYSNAME" in ''|.|..|*/*) echo "✗ 非法系统目录名：$SYSNAME（须为单层目录名）"; exit 2 ;; esac
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
command -v python3 >/dev/null || { echo "✗ 需要 python3"; exit 1; }
if [ "$TARGET" = "$SRC" ]; then
  echo "✗ 目标项目根不能是本源仓自身：$TARGET"; exit 2
fi

echo "== ai-dev-guide 部署 =="
echo "目标: $TARGET"
echo "系统目录: $SYSNAME"

# 1. 复制部署平面（按裁剪组过滤）
DEST="$TARGET/$SYSNAME"
mkdir -p "$DEST"
python3 - "$SRC" "$DEST" "$NO_UI" "$NO_EX" <<'PYEOF'
import sys, os, shutil
src, dest, no_ui, no_ex = sys.argv[1], sys.argv[2], sys.argv[3] == '1', sys.argv[4] == '1'
ns = {}
gsrc = open(os.path.join(src, 'scripts/gen-index.py'), encoding='utf-8').read().replace('if __name__ == "__main__":', 'if False:')
ns['__file__'] = os.path.join(src, 'scripts', 'gen-index.py')
exec(compile(gsrc, 'gi', 'exec'), ns)
data = ns['load']()
copied, skipped = [], []
for d in data['docs']:
    if d['plane'] != 'deployed': continue
    g = d['trim_group']
    if g == 'ui' and no_ui: skipped.append(d['path']); continue
    if g == 'stack-example' and no_ex: skipped.append(d['path']); continue
    p = os.path.join(src, d['path'])
    if not os.path.exists(p): continue
    out = os.path.join(dest, d['path'])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    shutil.copy2(p, out)
    copied.append(d['path'])
print(f'✓ 复制 {len(copied)} 份部署文档' + (f'（裁剪 {len(skipped)}）' if skipped else ''))
for s in skipped: print('  裁剪:', s)
PYEOF

# 1b. 复制运行时脚本（目标项目内可独立运行者）
#     check.sh(部署门禁) + _gates.py(其依赖) + new-batch.sh + release-version.sh
#     init/upgrade/gen-index 依赖源仓 manifest，不随部署（升级用源仓 upgrade.sh）
mkdir -p "$DEST/scripts"
for S in check.sh _gates.py new-batch.sh release-version.sh scan-secrets.sh scan-secrets.allow; do
  cp "$HERE/$S" "$DEST/scripts/$S"
done
chmod +x "$DEST/scripts/"*.sh
echo "✓ 复制运行时脚本 → $SYSNAME/scripts/（check / new-batch / release-version / scan-secrets）"

# 2. 生成 AGENTS.md
if [ -f "$TARGET/AGENTS.md" ]; then
  echo "⚠ 目标已有 AGENTS.md——生成到 AGENTS.md.new 供人工合并"
  OUT="$TARGET/AGENTS.md.new"
else
  OUT="$TARGET/AGENTS.md"
fi
python3 - "$SRC" "$OUT" "$SYSNAME" "$NO_UI" "$NO_EX" <<'PYEOF'
import sys, os, re
src, out, sysname, no_ui, no_ex = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]=='1', sys.argv[5]=='1'
ns = {}
gsrc = open(os.path.join(src, 'scripts/gen-index.py'), encoding='utf-8').read().replace('if __name__ == "__main__":', 'if False:')
ns['__file__'] = os.path.join(src, 'scripts', 'gen-index.py')
exec(compile(gsrc, 'gi', 'exec'), ns)
data = ns['load']()
tpl = open(os.path.join(src, 'AGENTS.md.template'), encoding='utf-8').read()
tpl = tpl.replace('{{SYS}}', sysname)
icon = {'MUST':'🔴','SHOULD':'🟡','MAY':'🟢'}
order = {'MUST':0,'SHOULD':1,'MAY':2}
rows = ['| 级别 | 文档 | 用途 | Use when |','|------|------|------|----------|']
for d in sorted([d for d in data['docs'] if d['plane']=='deployed' and d['indexed'] in ('true',True)], key=lambda d:(order[d['level']], d['path'])):
    g = d['trim_group']
    if g=='ui' and no_ui: continue
    if g=='stack-example' and no_ex: continue
    p = d['path']
    rows.append(f"| {icon[d['level']]} {d['level']} | [{sysname}/{p}]({sysname}/{p}) | {d['purpose']} | {d['use_when']} |")
pat = re.compile(r'<!-- GEN:agents-index:start -->.*?<!-- GEN:agents-index:end -->', re.S)
tpl = pat.sub('<!-- GEN:agents-index:start -->\n' + '\n'.join(rows) + '\n<!-- GEN:agents-index:end -->', tpl, count=1)
open(out, 'w', encoding='utf-8').write(tpl)
print(f'✓ 生成 {out}')
PYEOF

# 3. 实例化登记簿与术语表（幂等：已存在则保留用户内容）
for PAIR in "registries/backlog.md backlog.md" "templates/context.md CONTEXT.md" \
            "registries/ability-domains.md docs/ability-domains.md" \
            "registries/architecture-debt.md docs/architecture-debt.md"; do
  set -- $PAIR
  SRC_REL="$1"; DST_REL="$2"
  if [ -f "$TARGET/$DST_REL" ]; then
    echo "✓ $DST_REL（已存在，保留）"
  else
    mkdir -p "$(dirname "$TARGET/$DST_REL")"
    cp "$SRC/$SRC_REL" "$TARGET/$DST_REL"
    echo "✓ $DST_REL"
  fi
done

# 4. 登记目录约定
write_readme() { # $1=目录名 $2=正文（printf 格式串，勿用 echo 转\n）
  mkdir -p "$TARGET/docs/$1"
  if [ ! -f "$TARGET/docs/$1/README.md" ]; then
    printf '%b\n' "$2" > "$TARGET/docs/$1/README.md"
  fi
}
write_readme journal "# Journal\n\n批次执行与证据日志（append-only）：每批次一个 YYYY-MM-DD-<kebab>.md，开工时创建（$SYSNAME/scripts/new-batch.sh）。"
write_readme specs   "# Specs\n\n进行中的设计决策（active）；验收后移入 docs/archive/specs/。"
write_readme research "# Research\n\n从 journal 蒸馏的可复用调研结论。"
write_readme archive  "# Archive\n\n归档：完结 spec 的最终归宿（定期清理零外部引用者，git 历史可找回）。"
mkdir -p "$TARGET/docs/archive/specs"
echo "✓ docs/{journal,specs,research,archive} 就绪（README 含真实换行）"

# 5. 悬空链接清洗（裁剪/源平面目标的链接改纯文本）
#     含生成的 AGENTS.md（$OUT）：--no-ui 等裁剪后模板正文手写链接可能悬空，一并转纯文本
python3 "$HERE/_scrub_links.py" "$DEST" "$OUT" "$TARGET/CONTEXT.md" "$TARGET/backlog.md" \
        "$TARGET/docs/ability-domains.md" "$TARGET/docs/architecture-debt.md" 2>/dev/null || true

# 5b. 部署基线：记录清洗后的最终形态哈希（相对目标根路径），供 upgrade.sh
#     区分「用户本地化修改」与「上游更新」；重新部署会刷新基线。
BASELINE="$DEST/.deploy-baseline.txt"
: > "$BASELINE"
record() { # $1=相对目标根的路径
  [ -f "$TARGET/$1" ] || return 0
  echo "$(sha256sum "$TARGET/$1" | cut -d' ' -f1)  $1" >> "$BASELINE"
}
( cd "$TARGET" && find "$SYSNAME" \( -name '*.md' -o -name '*.sh' -o -name '*.py' \) | sort ) | while read -r rel; do
  echo "$(sha256sum "$TARGET/$rel" | cut -d' ' -f1)  $rel" >> "$BASELINE"
done
case "$OUT" in
  "$TARGET/AGENTS.md")     record "AGENTS.md" ;;
  "$TARGET/AGENTS.md.new") record "AGENTS.md.new" ;;
esac
record "backlog.md"; record "CONTEXT.md"
record "docs/ability-domains.md"; record "docs/architecture-debt.md"
echo "✓ 部署基线 → $SYSNAME/.deploy-baseline.txt（$(wc -l < "$BASELINE") 条；upgrade.sh 依赖）"

# 6. 残留占位符报告（人工补填清单）
echo
echo "== 待人工补填的占位符（项目事实）=="
grep -nE '<[a-zA-Z][a-zA-Z0-9_ /-]{0,40}>' "$OUT" | head -20 || echo "（无）"

# 6. 部署门禁
echo
echo "== 部署门禁 =="
bash "$HERE/check.sh" --deployed "$TARGET" --only 1,9,10 || true

echo
echo "== 完成 =="
echo "下一步：① 补填 $OUT 中的 <占位符>（栈事实）；② 填 $SYSNAME/stack/stack-profile.md；"
echo "③ 首条 backlog 登记（docs 系统初始化）；④ git add AGENTS.md $SYSNAME backlog.md CONTEXT.md docs/ 并提交。"
echo "④ 提交前可跑 $SYSNAME/scripts/scan-secrets.sh 扫敏感信息（白名单在其同目录 scan-secrets.allow）。"