import re, sys
WHITELIST = {'MAJOR','MINOR','PATCH','LABEL','NUMBER','type','scope','N','n'}
bad = []
import glob, os
for d in ['workflows','standards','meta','bootstrap']:
    for f in glob.glob(d + '/**/*.md', recursive=True):
        in_code = False
        for i, line in enumerate(open(f, encoding='utf-8'), 1):
            if line.lstrip().startswith('```'):
                in_code = not in_code; continue
            if in_code: continue  # 代码块内为格式示例，占位符合法
            for m in re.finditer(r'<([^<>\n]{1,40})>', line):
                s = m.group(1)
                if s.startswith('!--'): continue  # HTML 注释（CANON 标记等）
                if s.strip() in WHITELIST: continue
                if s.startswith('SYS'): continue  # {{SYS}} 标记
                bad.append(f'{f}:{i}: <{s}>')
                break
if bad:
    print('✗ [3] 内容文档残留占位符（应符号化或指向 stack-profile；代码块示例除外）：')
    for x in bad[:10]: print('  ', x)
    sys.exit(1)
print('✓ [3] 内容文档零占位符残留（含中文；代码块示例豁免）')
