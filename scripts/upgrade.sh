#!/usr/bin/env bash
# ============================================================
# upgrade.sh — 上游 ai-dev-guide 升级漂移报告（部署基线感知）
# 用法：upgrade.sh <源仓根> <已部署项目根> [系统目录名]
# 原理：部署时 init.sh 写下 .deploy-baseline.txt（清洗后形态哈希）。
#   当前文件 == 基线  → 未动过（上游更新即可直接覆盖）
#   当前文件 != 基线  → 用户本地化修改（需人工合并）
#   无基线（旧版部署）→ 退化为与源仓当前文件比对并提示。
# 只报告，不自动覆盖。
# ============================================================
set -uo pipefail
SRC="${1:-}"; TGT="${2:-}"; SYS="${3:-ai-dev-guide}"
[ -d "$SRC" ] && [ -d "$TGT" ] || { echo '用法: upgrade.sh <源仓根> <已部署项目根> [系统目录名]'; exit 2; }
SRC="$(cd "$SRC" && pwd)"; TGT="$(cd "$TGT" && pwd)"

python3 - "$SRC" "$TGT" "$SYS" <<'PYEOF'
import sys, os, hashlib, subprocess
src, tgt, sysname = sys.argv[1], sys.argv[2], sys.argv[3]
ns = {}
gsrc = open(os.path.join(src, 'scripts/gen-index.py'), encoding='utf-8').read().replace('if __name__ == "__main__":', 'if False:')
ns['__file__'] = os.path.join(src, 'scripts', 'gen-index.py')
exec(compile(gsrc, 'gi', 'exec'), ns)
data = ns['load']()

def h(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest() if os.path.exists(p) else None

baseline = {}
bl_path = os.path.join(tgt, sysname, '.deploy-baseline.txt')
has_baseline = os.path.exists(bl_path)
if has_baseline:
    for ln in open(bl_path, encoding='utf-8'):
        parts = ln.split(None, 1)
        if len(parts) == 2:
            baseline[parts[1].strip()] = parts[0]

up_new, local_mod, upstream_changed, missing, local_extra, clean = [], [], [], [], [], []
for d in data['docs']:
    if d['plane'] != 'deployed':
        continue
    rel = os.path.join(sysname, d['path'])          # 目标项目内路径
    s, t = os.path.join(src, d['path']), os.path.join(tgt, rel)
    hs, ht, hb = h(s), h(t), baseline.get(rel)
    if hs and ht:
        if hs == ht:
            clean.append(rel)
        elif has_baseline and hb == ht:
            up_new.append(rel)                       # 用户未动，直接覆盖即同步
        elif has_baseline and hb and hb != ht:
            local_mod.append(rel)                    # 用户改过
        else:
            local_mod.append(rel)                    # 无基线：内容异于源仓，按需合并
    elif hs and not ht:
        missing.append(rel)                          # 上游有、部署缺（曾被裁剪或新增）
    elif ht and not hs:
        local_extra.append(rel)

# 部署目录里存在但 manifest 没有的（本地新增）
for root, dirs, files in os.walk(os.path.join(tgt, sysname)):
    dirs[:] = [x for x in dirs if not x.startswith('.')]
    for f in files:
        if f == '.deploy-baseline.txt':
            continue
        p = os.path.relpath(os.path.join(root, f), tgt)
        inner = os.path.relpath(p, sysname)
        if p.endswith('.md') and not any(d['path'] == inner for d in data['docs']):
            local_extra.append(p)

print('== 升级漂移报告 ==')
print(f'上游版本: {data["system"]["version"]}')
mode = '部署基线比对' if has_baseline else '无基线（旧版部署，退化为与源仓直比）'
print(f'比对模式: {mode}')
print(f'一致 {len(clean)} · 可直接覆盖 {len(up_new)} · 本地化修改 {len(local_mod)} · 上游有/部署缺 {len(missing)} · 本地新增 {len(local_extra)}')
print()
for title, items, advice in [
    ('本地化修改（需人工合并）', local_mod, 'diff 基线/本地/上游三方，保留本地化事实，吸收上游规则更新'),
    ('可直接覆盖（用户未动，上游已更新）', up_new, '从源仓复制同名文件，复制后重跑 init.sh 刷新基线'),
    ('上游有/部署缺', missing, '曾被 --no-ui/--no-example 裁剪或上游新增——按需从源仓复制'),
    ('本地新增（manifest 外）', local_extra, '确认应回馈上游或属本地特有'),
]:
    if items:
        print(f'-- {title} --')
        for x in sorted(set(items))[:20]:
            print('  ', x)
        print(f'   建议: {advice}')
        print()
print('下一步: 人工合并「本地化修改」→ 复制「可直接覆盖」→ bash <sys>/scripts/check.sh --deployed', os.path.basename(tgt))
PYEOF
