import re, sys
WHITELIST = {'MAJOR','MINOR','PATCH','LABEL','NUMBER','type','scope','N','n'}
bad = []
import glob, os
for d in ['workflows','standards','meta','bootstrap']:
    for f in glob.glob(d + '/**/*.md', recursive=True):
        for i, line in enumerate(open(f, encoding='utf-8'), 1):
            for m in re.finditer(r'<([a-zA-Z][a-zA-Z0-9_ /-]{0,40})>', line):
                if m.group(1).strip() in WHITELIST: continue
                if '{{' in line: continue
                bad.append(f'{f}:{i}: <{m.group(1)}>')
                break
if bad:
    print('✗ [3] 内容文档残留占位符（应符号化或指向 stack-profile）：')
    for x in bad[:10]: print('  ', x)
    sys.exit(1)
print('✓ [3] 内容文档零占位符残留')