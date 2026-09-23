#!/usr/bin/env python3
# ============================================================
# _gen_agents.py — 由 AGENTS.md.template 实例化项目根 AGENTS（init 部署与 upgrade apply 共用）
# 用法：_gen_agents.py <源仓根> <输出路径> <系统目录名> <no_ui 0|1> <no_ex 0|1>
# 生成规则：{{SYS}} 替换 + 索引实例化（裁剪组过滤）+ 剔除引用裁剪组文档的手写行。
# ============================================================
import sys, os, re
src, out, sysname = sys.argv[1], sys.argv[2], sys.argv[3]
no_ui, no_ex = sys.argv[4] == '1', sys.argv[5] == '1'
ns = {}
gsrc = open(os.path.join(src, 'scripts/gen-index.py'), encoding='utf-8').read().replace('if __name__ == "__main__":', 'if False:')
ns['__file__'] = os.path.join(src, 'scripts', 'gen-index.py')
exec(compile(gsrc, 'gi', 'exec'), ns)
data = ns['load']()
tpl = open(os.path.join(src, 'AGENTS.md.template'), encoding='utf-8').read()
tpl = tpl.replace('{{SYS}}', sysname)
icon = {'MUST': '🔴', 'SHOULD': '🟡', 'MAY': '🟢'}
order = {'MUST': 0, 'SHOULD': 1, 'MAY': 2}
rows = ['| 级别 | 文档 | 用途 | Use when |', '|------|------|------|----------|']
for d in sorted([d for d in data['docs'] if d['plane'] == 'deployed' and d['indexed'] in ('true', True)],
                key=lambda d: (order[d['level']], d['path'])):
    g = d['trim_group']
    if g == 'ui' and no_ui: continue
    if g == 'stack-example' and no_ex: continue
    p = d['path']
    rows.append(f"| {icon[d['level']]} {d['level']} | [{sysname}/{p}]({sysname}/{p}) | {d['purpose']} | {d['use_when']} |")
pat = re.compile(r'<!-- GEN:agents-index:start -->.*?<!-- GEN:agents-index:end -->', re.S)
tpl = pat.sub('<!-- GEN:agents-index:start -->\n' + '\n'.join(rows) + '\n<!-- GEN:agents-index:end -->', tpl, count=1)
# 裁剪组文档的手写引用行一并剔除（如「其他」节的 ui-conventions 条目）——防纯文本路径与 §引用残留（沙盒审计定规）
if no_ui or no_ex:
    dropped = [d['path'] for d in data['docs']
               if (d['trim_group'] == 'ui' and no_ui) or (d['trim_group'] == 'stack-example' and no_ex)]
    tpl = '\n'.join(l for l in tpl.split('\n')
                    if not any((sysname + '/' + p) in l for p in dropped))
os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
open(out, 'w', encoding='utf-8').write(tpl)
