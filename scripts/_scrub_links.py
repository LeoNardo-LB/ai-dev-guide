import os, re, sys, glob
dest = sys.argv[1]
roots = sys.argv[2:]
files = []
for root in roots + [dest]:
    if os.path.isfile(root):
        files.append(root)
        continue
    for f in glob.glob(os.path.join(root, '**', '*.md'), recursive=True):
        files.append(f)
scrubbed = 0
def process(f):
    global scrubbed
    base = os.path.dirname(f)
    txt = open(f, encoding='utf-8').read()
    changed = []
    def sub(m):
        text, target = m.group(1), m.group(2)
        if target.startswith(('http://', 'https://', 'mailto:', '#')):
            return m.group(0)
        t2 = target.split('#')[0]
        if not t2:
            return m.group(0)
        p = os.path.normpath(os.path.join(base, t2))
        if not os.path.exists(p):
            changed.append(1)
            return text
        return m.group(0)
    new = re.sub(r'\[([^\]]+)\]\(([^)]+\.md)\)', sub, txt)
    if changed:
        scrubbed += len(changed)
        open(f, 'w', encoding='utf-8').write(new)
for f in files:
    process(f)
print('链接清洗：' + str(scrubbed) + ' 处悬空链接改为纯文本')