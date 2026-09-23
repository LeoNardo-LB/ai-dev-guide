#!/usr/bin/env bash
# ============================================================
# upgrade.sh — 上游 ai-dev-guide 升级模块（部署基线感知：报告 / 分级执行 / 三方合并 / 基线刷新）
# 用法：upgrade.sh <源仓根> <已部署项目根> [系统目录名] [子命令]
# 子命令（缺省 report）：
#   report          漂移报告——按三方状态分级列出与建议，不改任何文件
#   apply           只执行可证明安全的同步：本地==基线且上游已变 → 覆盖并刷新基线；
#                   上游新增且非当初裁剪组 → 补齐。绝不触碰本地化修改与根级实例
#                   （AGENTS.md/backlog.md/CONTEXT.md）；完成后自动跑部署门禁
#   merge [file]    双方都动过的文件：落三方工件到 <sys>/.upgrade-merge/
#                   （base 取自上游 git tag v<部署版本>；有 git 时另出 merged 三方合并稿）
#   baseline        人工合并完成且部署门禁通过后，把当前形态登记为新基准
# 原理：init.sh 写 .deploy-baseline.txt（形态哈希 + 部署档案 profile 行：
#   sysname / no_ui / no_ex / version）。本地==基线 → 未动过（上游更新可安全覆盖）；
#   本地≠基线 → 本地化修改（须三方合并，绝不自动覆盖）。
# 信任模型：基线是部署/升级产物，手改基线可掩盖本地修改——勿手改。
# ============================================================
set -uo pipefail
SRC="${1:-}"; TGT="${2:-}"; SYS="ai-dev-guide"; SUB="report"
case "${3:-}" in
  report|apply|merge|baseline) SUB="$3" ;;
  *) SYS="${3:-ai-dev-guide}" ;;
esac
case "${4:-}" in
  report|apply|merge|baseline) SUB="$4" ;;
  "") ;;
  *) echo "✗ 未知子命令：$4（合法：report | apply | merge | baseline）"; exit 2 ;;
esac
MERGE_ONE="${5:-}"
[ -n "$SRC" ] && [ -n "$TGT" ] || { echo '用法: upgrade.sh <源仓根> <已部署项目根> [系统目录名] [report|apply|merge|baseline]'; exit 2; }
[ -d "$SRC" ] && [ -d "$TGT" ] || { echo '用法: upgrade.sh <源仓根> <已部署项目根> [系统目录名] [report|apply|merge|baseline]'; exit 2; }
SRC="$(cd "$SRC" && pwd)"; TGT="$(cd "$TGT" && pwd)"
# 前置校验：源仓缺核心文件 / 目标系统目录不存在或不像本系统部署（--dir 之名传错，如误传项目自身 docs/）
# 都曾静默产出误导报告（沙盒审计 D1/D4 定规）
[ -f "$SRC/scripts/gen-index.py" ] || { echo "✗ 源仓缺少 scripts/gen-index.py——$SRC 不是本系统源仓？"; exit 2; }
if [ ! -d "$TGT/$SYS" ] || [ ! -f "$TGT/$SYS/scripts/check.sh" ]; then
  echo "✗ $TGT/$SYS 不存在或不是本系统部署目录（缺 scripts/check.sh）——系统目录名应传部署时 --dir 之名，默认 ai-dev-guide"
  for D in "$TGT"/*/scripts/check.sh; do
    [ -f "$D" ] && echo "  疑似正确目录名：$(basename "$(dirname "$(dirname "$D")")")"
  done
  exit 2
fi

python3 - "$SRC" "$TGT" "$SYS" "$SUB" "$MERGE_ONE" <<'PYEOF'
import sys, os, hashlib, shutil, subprocess
src, tgt, sysname, sub, merge_one = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
ns = {}
gsrc = open(os.path.join(src, 'scripts/gen-index.py'), encoding='utf-8').read().replace('if __name__ == "__main__":', 'if False:')
ns['__file__'] = os.path.join(src, 'scripts', 'gen-index.py')
exec(compile(gsrc, 'gi', 'exec'), ns)
data = ns['load']()
UPVER = data['system']['version']

def h(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest() if os.path.exists(p) else None

bl_path = os.path.join(tgt, sysname, '.deploy-baseline.txt')
has_baseline = os.path.exists(bl_path)
baseline = {}
srcbase = {}           # 基线 #src= 哈希：部署时的源仓原文形态——区分「部署变换差异」与「上游真演进」
merged_keep = set()    # 基线标记 #merged 的文件：含未入上游的本地内容，apply 永不覆盖
profile = {'sysname': sysname, 'no_ui': None, 'no_ex': None, 'version': None}
if has_baseline:
    for ln in open(bl_path, encoding='utf-8'):
        if ln.startswith('#'):
            if ln.startswith('# profile'):
                for kv in ln.strip().split()[2:]:
                    k, _, v = kv.partition('=')
                    profile[k] = v
            continue
        parts = ln.split(None, 1)
        if len(parts) == 2:
            rel, _, note = parts[1].partition('#')
            rel = rel.strip()
            toks = note.split()
            if 'merged' in toks:
                merged_keep.add(rel)
            for t in toks:
                if t.startswith('src='):
                    srcbase[rel] = t[4:]
            baseline[rel] = parts[0]

# 旧基线无档案：从部署现状推断裁剪开关（一次性归一——后续分类/入口重建/基线写入全部一致；
# 曾因 None or 0 把裁剪事实洗成 0，下一轮 apply 强补裁剪文档）
if profile['no_ui'] is None:
    profile['no_ui'] = '1' if not os.path.isfile(os.path.join(tgt, sysname, 'standards', 'ui-conventions.md')) else '0'
if profile['no_ex'] is None:
    profile['no_ex'] = '1' if not os.path.isfile(os.path.join(tgt, sysname, 'stack', 'android-kotlin-example.md')) else '0'

def trimmed(d):
    """该文档是否属「按设计缺席」（部署档案裁剪开关，加载时已推断归一）——
    ui/stack-example 组缺席即当初裁剪，apply 不得强补（违背 --no-ui/--no-example 部署意图）。"""
    if d['trim_group'] == 'ui':
        return profile['no_ui'] == '1'
    if d['trim_group'] == 'stack-example':
        return profile['no_ex'] == '1'
    return False

# ---- 三方分级 ----
clean, safe_apply, local_ahead, merge_needed, merged_list = [], [], [], [], []
upstream_new, trimmed_missing, upstream_gone, local_extra = [], [], [], []
for d in data['docs']:
    if d['plane'] != 'deployed':
        continue
    rel = os.path.join(sysname, d['path'])
    s, t = os.path.join(src, d['path']), os.path.join(tgt, rel)
    hs, ht, hb = h(s), h(t), baseline.get(rel)
    hs0 = srcbase.get(rel)
    if hs and ht:
        if hs == ht: clean.append(rel)
        elif ht == hb:
            if rel in merged_keep:
                merged_list.append(rel)                  # 合并稿含本地内容，apply 永不覆盖
            elif hs0 is not None and hs != hs0:
                safe_apply.append(rel)                   # 源态真演进（区别于部署变换差异）
            elif hs0 is None and hs != ht:
                safe_apply.append(rel)                   # 旧版基线无源态哈希：不可证明，但 apply 含清洗管线、幂等安全
            else:
                clean.append(rel)                       # 变换等价：部署态即正确态（清洗产生的合法差异）
        elif hs == (hs0 if hs0 is not None else hb): local_ahead.append(rel)  # 本地改、上游未动
        else: merge_needed.append(rel)                   # 双方都动 → 须三方合并
    elif hs and not ht:
        if trimmed(d): trimmed_missing.append(rel)      # 当初 --no-ui/--no-example 裁剪，按设计保持缺失
        else: upstream_new.append(rel)                   # 上游新增（部署后加入 manifest）
    elif ht and not hs:
        (upstream_gone if (has_baseline and hb) else local_extra).append(rel)
# 运行时脚本随部署（与 init.sh 1b 复制清单保持同步）：不进 manifest，但升级必须覆盖——
# 否则跨版本升级后目标项目仍跑旧版 check.sh/scan-secrets（正是历次修复的对象）
RUNTIME = ['check.sh', '_gates.py', 'new-batch.sh', 'backlog.sh', '_backlog_core.py',
           'release-version.sh', 'scan-secrets.sh', 'scan-secrets.allow']
for f in RUNTIME:
    s = os.path.join(src, 'scripts', f)
    if not os.path.isfile(s):
        continue
    rel = os.path.join(sysname, 'scripts', f)
    hs, ht, hb = h(s), h(os.path.join(tgt, rel)), baseline.get(rel)
    if ht is None:
        upstream_new.append(rel)
    elif hs == ht:
        clean.append(rel)
    elif ht == hb:
        (merged_list if rel in merged_keep else safe_apply).append(rel)   # 脚本为原样复制，无部署变换
    elif hs == (srcbase.get(rel) or hb):
        local_ahead.append(rel)
    else:
        merge_needed.append(rel)
for root, dirs, files in os.walk(os.path.join(tgt, sysname)):
    dirs[:] = [x for x in dirs if not x.startswith('.')]
    for f in files:
        if f == '.deploy-baseline.txt' or not f.endswith('.md'):
            continue
        p = os.path.relpath(os.path.join(root, f), tgt)
        inner = os.path.relpath(p, sysname)
        if not any(d['path'] == inner for d in data['docs']):
            (upstream_gone if baseline.get(p) else local_extra).append(p)

def counts_line():
    return (f'一致 {len(clean)} · 可安全同步 {len(safe_apply)} · 双方修改(须合并) {len(merge_needed)} · '
            f'已合并保留 {len(merged_list)} · 本地领先(上游未动) {len(local_ahead)} · 上游新增 {len(upstream_new)} · '
            f'当初裁剪 {len(trimmed_missing)} · 上游已删除 {len(upstream_gone)} · 本地新增 {len(local_extra)}')

def run_gates():
    ck = os.path.join(tgt, sysname, 'scripts/check.sh')
    if not os.path.isfile(ck):
        print('⚠ 目标缺 scripts/check.sh，跳过部署门禁'); return 0
    r = subprocess.run(['bash', ck, '--deployed', tgt], capture_output=True, text=True)
    return r.returncode

def rewrite_baseline(version):
    """按当前形态全量重写基线（含档案头）；.upgrade-merge 等点目录不入册。
    只属 baseline 子命令（人工声明「当前即新基准」）。"""
    lines = [f'# profile sysname={sysname} no_ui={profile["no_ui"]} no_ex={profile["no_ex"]} version={version}']
    rels = []
    for root, dirs, files in os.walk(os.path.join(tgt, sysname)):
        dirs[:] = [x for x in dirs if not x.startswith('.')]
        for f in files:
            if f.endswith(('.md', '.sh', '.py')) and f != '.deploy-baseline.txt':
                rels.append(os.path.relpath(os.path.join(root, f), tgt))
    for extra in ('AGENTS.md', 'AGENTS.md.new', 'backlog.md', 'CONTEXT.md',
                  'docs/ability-domains.md', 'docs/architecture-debt.md'):
        if os.path.isfile(os.path.join(tgt, extra)):
            rels.append(extra)
    deployed_paths = {d['path'] for d in data['docs'] if d['plane'] == 'deployed'} \
                 | {'scripts/' + f for f in RUNTIME}
    # AGENTS.md 的 merged 判据：内容 ≠ 当前模板重生成实例 = 含自定义内容（apply 永不直接覆盖）
    regen_ag = None
    gen = os.path.join(src, 'scripts', '_gen_agents.py')
    if os.path.isfile(gen) and os.path.isfile(os.path.join(tgt, 'AGENTS.md')):
        tf = os.path.join(tgt, sysname, '.regen.tmp')
        subprocess.run(['python3', gen, src, tf, sysname, profile['no_ui'], profile['no_ex']], capture_output=True)
        scr = os.path.join(src, 'scripts', '_scrub_links.py')
        if os.path.isfile(scr) and os.path.isfile(tf):
            subprocess.run(['python3', scr, tf], capture_output=True)
        if os.path.isfile(tf):
            regen_ag = h(tf); os.remove(tf)
    for rel in sorted(rels):
        p = os.path.join(tgt, rel)
        inner = os.path.relpath(rel, sysname) if rel.startswith(sysname + os.sep) else None
        toks = []
        if inner:
            s = h(os.path.join(src, inner))
            if s:
                toks.append(f'src={s}')
            # 与上游源态不一致的部署面文件 → merged 保护：防止后续 apply 覆盖人工合并稿（E2E 定规）
            if inner in deployed_paths and h(p) != s:
                toks.append('merged')
        if rel == 'AGENTS.md' and regen_ag and h(p) != regen_ag:
            toks.append('merged')
        note = ('  #' + ' '.join(toks)) if toks else ''
        lines.append(f'{h(p)}  {rel}{note}')
    open(bl_path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')

def refresh_entries(rels, version):
    """增量刷新：只更新 rels 的条目（双哈希：清洗后目标态 + 源仓源态）与档案版本，其余原样保留。
    apply 必须用增量——全量重写会把本地化修改洗进基线，令其被下一次 apply 覆盖（E2E 定规）。"""
    cur = {}
    for ln in open(bl_path, encoding='utf-8'):
        if ln.startswith('#'): continue
        parts = ln.split(None, 1)
        if len(parts) == 2: cur[parts[1].strip()] = parts[0]
    head = f'# profile sysname={sysname} no_ui={profile["no_ui"]} no_ex={profile["no_ex"]} version={version}'
    lines = [head]
    for k in sorted(set(list(cur.keys()) + list(rels))):
        if k in rels:
            t = h(os.path.join(tgt, k))
            inner = os.path.relpath(k, sysname) if k.startswith(sysname + os.sep) else None
            s = h(os.path.join(src, inner)) if inner else None
            lines.append(f'{t}  {k}' + (f'  #src={s}' if s else ''))
        else:
            lines.append(f'{cur[k]}  {k}')
    open(bl_path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')

# ---- 子命令 ----
if sub == 'report':
    print('== 升级漂移报告 ==')
    print(f'上游版本: {UPVER}' + (f'（部署档案版本: {profile["version"]}）' if profile['version'] else '（基线无档案——旧版部署）'))
    mode = '部署基线比对' if has_baseline else '无基线（旧版部署，退化为与源仓直比）'
    print(f'比对模式: {mode}')
    print(counts_line())
    print()
    for title, items, advice in [
        ('可安全同步（本地未动、上游已变）', safe_apply, '跑 apply 子命令自动覆盖并刷新基线'),
        ('双方修改（须三方合并）', merge_needed, '跑 merge 子命令生成 <sys>/.upgrade-merge/ 工件 → 人工/agent 合并 → 跑 baseline 刷新'),
        ('上游新增（部署后加入）', upstream_new, '跑 apply 自动补齐（非当初裁剪组）'),
        ('已合并保留（基线含本地内容，apply 不覆盖）', merged_list, '无需动作；上游再次演进时跑 merge 重新合并'),
        ('本地领先（上游未动）', local_ahead, '保留本地，无需动作'),
        ('当初裁剪（按设计缺失）', trimmed_missing, '保持缺失；需要时从源仓复制'),
        ('上游已删除（基线有、上游 manifest 无）', upstream_gone, '保留或归档皆可——上游已移除，勿回馈上游'),
        ('本地新增（manifest 外）', local_extra, '确认应回馈上游或属本地特有'),
    ]:
        if items:
            print(f'-- {title} --')
            uniq = sorted(set(items))
            for x in uniq[:20]:
                print('  ', x)
            if len(uniq) > 20:
                print(f'   …另有 {len(uniq) - 20} 条未列出')
            print(f'   建议: {advice}')
            print()
    print(f'下一步: apply 同步安全项 → merge 合并双方修改 → baseline 刷新基准 → bash {sysname}/scripts/check.sh --deployed 复验')

elif sub == 'apply':
    if not has_baseline:
        print('✗ 无部署基线（旧版部署）——先人工核对后重跑 init.sh 重建基线，apply 拒绝盲同步'); sys.exit(2)
    targets = safe_apply + upstream_new
    done = []
    if targets:
        for rel in targets:
            inner = os.path.relpath(rel, sysname)
            out = os.path.join(tgt, rel)
            os.makedirs(os.path.dirname(out), exist_ok=True)
            shutil.copy2(os.path.join(src, inner), out)
            done.append(rel)
    else:
        print(f'无可安全同步项（{counts_line()}）——仍检查入口重建')
    # 部署是带变换的复制：apply 必须重跑同一清洗管线，否则把源仓原文直接盖进目标会重引入悬空链接/§N（R5 定规）。
    # 清洗范围扩到整个系统目录（幂等）：上游未变但部署形态带旧债的文件（如旧版 scrub 遗留 §N）一并修复；
    # 哈希因此变化的文件同步刷基线，防下轮误报可安全同步。
    scrub = os.path.join(src, 'scripts', '_scrub_links.py')
    if os.path.isfile(scrub):
        pre = {}
        for root2, dirs2, files2 in os.walk(os.path.join(tgt, sysname)):
            dirs2[:] = [x for x in dirs2 if not x.startswith('.')]
            for f2 in files2:
                if f2.endswith('.md'):
                    p2 = os.path.relpath(os.path.join(root2, f2), tgt)
                    pre[p2] = h(os.path.join(tgt, p2))
        subprocess.run(['python3', scrub, os.path.join(tgt, sysname)], capture_output=True)
        for p2, old in pre.items():
            if h(os.path.join(tgt, p2)) != old and p2 not in done:
                done.append(p2)
                print(f'✓ 变换债清理：{p2}（重清洗后形态更新）')
    # AGENTS 入口重建（根级实例 apply 永不覆盖）：按当前模板重实例化，与现文件有差异时落 AGENTS.md.new 供人工合并——
    # 旧版部署的 AGENTS 残留悬空引用曾令升级后门禁仍红（跨版本升级缺口）
    gen = os.path.join(src, 'scripts', '_gen_agents.py')
    ag = os.path.join(tgt, 'AGENTS.md')
    newdraft = ag + '.new'
    if os.path.isfile(gen):
        tmp = newdraft + '.tmp'
        subprocess.run(['python3', gen, src, tmp, sysname, profile['no_ui'], profile['no_ex']], capture_output=True)
        if os.path.isfile(scrub):
            subprocess.run(['python3', scrub, tmp], capture_output=True)
        if os.path.isfile(tmp):
            # .new 草稿保守保护：存在且非基线记录形态（用户编辑中/旧版产物不可辨）→ 不覆盖
            draft_locked = os.path.isfile(newdraft) and h(newdraft) != baseline.get('AGENTS.md.new')
            untouched = (not os.path.isfile(ag)) or (h(ag) == baseline.get('AGENTS.md') and 'AGENTS.md' not in merged_keep)
            if not os.path.isfile(ag):
                os.replace(tmp, ag)
                print('✓ 入口重建：AGENTS.md（原不存在，已生成）'); done.append('AGENTS.md')
            elif h(tmp) != h(ag):
                if untouched:
                    os.replace(tmp, ag)
                    print('✓ 入口重建：AGENTS.md（未被本地修改，直接生效）'); done.append('AGENTS.md')
                elif draft_locked:
                    os.remove(tmp)
                    print('⚠ 入口模板已演进，但 AGENTS.md.new 草稿已被编辑——两者都保留；合并或删除 .new 后重跑 apply')
                else:
                    os.replace(tmp, newdraft)
                    print('✓ 入口重建：AGENTS.md.new（检测到本地修改，人工合并后生效）'); done.append('AGENTS.md.new')
            else:
                os.remove(tmp)
    refresh_entries(done, UPVER)
    print(f'✓ 已安全同步 {len(done)} 项（未触碰本地化修改与根级实例；基线已刷新，档案版本 → {UPVER}）')
    for x in sorted(done)[:20]:
        if x != 'AGENTS.md':
            print('  ', x)
    if len(done) > 20:
        print(f'   …另有 {len(done) - 20} 项未列出')
    if merge_needed:
        print(f'⚠ 仍有 {len(merge_needed)} 项双方修改未处理——跑 merge 子命令生成三方工件')
    rc = run_gates()
    if rc != 0:
        print('✗ 同步后部署门禁未过——按上方清单排查（基线保持已刷新状态，可 repeat report 复核）'); sys.exit(1)
    print('✓ 部署门禁通过')

elif sub == 'merge':
    files = [merge_one] if merge_one else merge_needed
    if merge_one:
        cand = merge_one if merge_one.startswith(sysname + os.sep) else os.path.join(sysname, merge_one)
        if cand not in merge_needed and os.path.isfile(os.path.join(tgt, cand)):
            files = [cand]
        else:
            files = [cand] if cand in merge_needed else []
    if not files:
        print('无可合并项（双方修改为空；或指定文件不在双方修改清单）'); sys.exit(0 if not merge_one else 2)
    mdir = os.path.join(tgt, sysname, '.upgrade-merge')
    dep_ver = profile.get('version')
    for rel in files:
        inner = os.path.relpath(rel, sysname)
        stem = os.path.join(mdir, rel)
        os.makedirs(os.path.dirname(stem), exist_ok=True)
        yours = stem + '.yours'; theirs = stem + '.theirs'
        shutil.copy2(os.path.join(tgt, rel), yours)
        shutil.copy2(os.path.join(src, inner), theirs)
        base = stem + '.base'
        have_base = False
        if dep_ver:
            r = subprocess.run(['git', '-C', src, 'show', f'v{dep_ver}:{inner}'],
                               capture_output=True)
            if r.returncode == 0:
                open(base, 'wb').write(r.stdout); have_base = True
        merged = stem + '.merged'
        have_merged = False
        if have_base and shutil.which('git'):
            r = subprocess.run(['git', 'merge-file', '-p', '-L', '本地', '-L', '基线', '-L', '上游', yours, base, theirs],
                               capture_output=True)
            if r.returncode in (0, 1):
                open(merged, 'wb').write(r.stdout); have_merged = True
                tagline = '（含冲突标记，逐处裁决）' if r.returncode == 1 else '（自动合并干净，仍须人工复核）'
        print(f'✓ {rel} → .upgrade-merge/{rel}.yours/.theirs' + ('/.base' if have_base else '（基线内容不可得：上游无 v%s tag，退化为双方对照）' % dep_ver)
              + (f'/.merged {tagline}' if have_merged else ''))
        print('   合并：以 yours 为底，吸收 theirs 的规则更新；完成后把结果写回原文件并跑 baseline 子命令')
    print(f'工件目录：{mdir}（合并完成后可整目录删除；apply/baseline 不会将其计入基线）')

elif sub == 'baseline':
    if not has_baseline:
        print('✗ 无部署基线文件'); sys.exit(2)
    rc = run_gates()
    if rc != 0:
        print('✗ 部署门禁未过——先修复再刷新基线（防把破坏登记为基准）'); sys.exit(1)
    rewrite_baseline(UPVER)
    print(f'✓ 基线已按当前形态刷新（档案版本 → {UPVER}）；下次 upgrade 以此为比对基准')
    mdir = os.path.join(tgt, sysname, '.upgrade-merge')
    if os.path.isdir(mdir):
        print(f'提示：{mdir} 仍存在——确认合并完成后可删除')
PYEOF
