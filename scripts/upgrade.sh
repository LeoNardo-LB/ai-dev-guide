#!/usr/bin/env bash
# ============================================================
# upgrade.sh — 上游 ai-dev-guide 升级漂移报告
# 用法：upgrade.sh <源仓根> <已部署项目根> [系统目录名]
# 输出：逐文件漂移分类（上游更新/本地化修改/双方修改/新增/删除）
#       + 建议动作。只报告，不自动覆盖（本地化修改需人工合并）。
# ============================================================
set -uo pipefail
SRC="${1:-}"; TGT="${2:-}"; SYS="${3:-ai-dev-guide}"
[ -d "$SRC" ] && [ -d "$TGT" ] || { echo '用法: upgrade.sh <源仓根> <已部署项目根> [系统目录名]'; exit 2; }
SRC="$(cd "$SRC" && pwd)"; TGT="$(cd "$TGT" && pwd)"

python3 - "$SRC" "$TGT" "$SYS" <<'PYEOF'
import sys, os, hashlib
src, tgt, sysname = sys.argv[1], sys.argv[2], sys.argv[3]
ns = {}
gsrc = open(os.path.join(src, 'scripts/gen-index.py'), encoding='utf-8').read().replace('if __name__ == "__main__":', 'if False:')
ns['__file__'] = os.path.join(src, 'scripts', 'gen-index.py')
exec(compile(gsrc, 'gi', 'exec'), ns)
data = ns['load']()
def h(p):
    return hashlib.sha1(open(p,'rb').read()).hexdigest()[:12] if os.path.exists(p) else None
up, local, both, added, removed, clean = [], [], [], [], [], []
for d in data['docs']:
    if d['plane'] != 'deployed': continue
    s, t = os.path.join(src, d['path']), os.path.join(tgt, sysname, d['path'])
    hs, ht = h(s), h(t)
    if hs and ht:
        if hs == ht: clean.append(d['path'])
        else: both.append(d['path'])
    elif hs and not ht: removed.append(d['path'])
    elif ht and not hs: added.append(d['path'])
# 部署项目里存在但源仓 manifest 没有的（本地新增）
for root, dirs, files in os.walk(os.path.join(tgt, sysname)):
    dirs[:] = [x for x in dirs if not x.startswith('.')]
    for f in files:
        p = os.path.relpath(os.path.join(root, f), os.path.join(tgt, sysname))
        if p.endswith('.md') and not any(d['path'] == p for d in data['docs']):
            local.append(p)
print(f'== 升级漂移报告 ==')
print(f'上游版本: {data["system"]["version"]}')
print(f'一致 {len(clean)} · 双方修改 {len(both)} · 上游新增 {len(removed)} · 部署缺失 {len(added)} · 本地新增 {len(local)}')
print()
for title, items, advice in [
    ('双方修改（需人工合并）', both, 'diff 两侧，保留本地化事实，吸收上游规则更新'),
    ('上游新增/更新（可直接复制）', removed, '从源仓复制——注意 manifest 是否同步'),
    ('本地新增（manifest 外）', local, '确认是否应回馈上游或本地特有'),
]:
    if items:
        print(f'-- {title} --')
        for x in items[:20]: print('  ', x)
        print(f'   建议: {advice}')
        print()
print('下一步: 人工合并「双方修改」→ 复制「上游新增」→ 跑 check.sh --deployed', os.path.basename(tgt))
PYEOF