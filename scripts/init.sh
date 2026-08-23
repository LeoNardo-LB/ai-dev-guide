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
#   <项目>/<sys>/            部署平面文档（按裁剪组过滤）
#   <项目>/AGENTS.md         由模板生成（{{SYS}} 替换、{{INDEX}} 实例化）
#   <项目>/backlog.md        登记簿实例（含计数器）
#   <项目>/CONTEXT.md        术语表实例
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
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
command -v python3 >/dev/null || { echo "✗ 需要 python3"; exit 1; }

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

# 1b. 复制运维脚本（版本/批次/门禁/升级工具随部署走）
mkdir -p "$DEST/scripts"
cp "$HERE"/*.sh "$HERE"/*.py "$DEST/scripts/" 2>/dev/null || true
chmod +x "$DEST/scripts/"*.sh
echo "✓ 复制运维脚本 → $SYSNAME/scripts/（release-version / new-batch / check / upgrade）"

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

# 3. 实例化登记簿与术语表
[ -f "$TARGET/backlog.md" ] || cp "$SRC/registries/backlog.md" "$TARGET/backlog.md" && echo "✓ backlog.md"
[ -f "$TARGET/CONTEXT.md" ] || cp "$SRC/templates/context.md" "$TARGET/CONTEXT.md" && echo "✓ CONTEXT.md"

# 4. 登记目录约定
for D in journal specs research archive; do
  mkdir -p "$TARGET/docs/$D"
  if [ ! -f "$TARGET/docs/$D/README.md" ]; then
    case $D in
      journal) echo "# Journal\n\n批次执行与证据日志（append-only）：每批次一个 YYYY-MM-DD-<kebab>.md，开工时创建（scripts/new-batch.sh）。" > "$TARGET/docs/$D/README.md" ;;
      specs) echo "# Specs\n\n进行中的设计决策（active）；验收后移入 docs/archive/specs/。" > "$TARGET/docs/$D/README.md" ;;
      research) echo "# Research\n\n从 journal 蒸馏的可复用调研结论。" > "$TARGET/docs/$D/README.md" ;;
      archive) mkdir -p "$TARGET/docs/$D/specs"; echo "# Archive\n\n归档：完结 spec 的最终归宿（定期清理零外部引用者，git 历史可找回）。" > "$TARGET/docs/$D/README.md" ;;
    esac
  fi
done
echo "✓ docs/{journal,specs,research,archive} 就绪"

# 5. 悬空链接清洗（裁剪/源平面目标的链接改纯文本）
python3 "$HERE/_scrub_links.py" "$DEST" "$TARGET/CONTEXT.md" "$TARGET/backlog.md" 2>/dev/null || true

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