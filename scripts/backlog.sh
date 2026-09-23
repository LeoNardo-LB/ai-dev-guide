#!/usr/bin/env bash
# ============================================================
# backlog.sh — backlog/journal 账本操作（防手工直编事故）
# 用法（在目标项目根运行；卡片区禁止手工直编——覆写丢章/同号双卡事故定规）：
#   backlog.sh add "<标题>" "<≤3行摘要>" [tag ...] [-p 0-4]  登记新卡（自动编号/计数器自增）
#   backlog.sh note <N> "<文本>"                              给 #N 追加一行注记（反馈归卡）
#   backlog.sh status <N> <todo|verify>                       切换 [ ] / [~]
#   backlog.sh migrate <N> [-r "<未验迁移依据>"] [--journal <file>]  迁 #N 入 journal（未验卡须 -r）
#   backlog.sh journal new "<批次名kebab>"                     建 journal 批次文件（同 new-batch.sh）
#   backlog.sh journal append <file> "<文本>"                  追加一行（append-only，禁全量覆写）
#   backlog.sh next | show <N>                                 查看计数器 / 单卡
# 变更后自动跑部署门禁 9（存在 check.sh 时）。
# ============================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BL="backlog.md"
[ -f "$BL" ] || { echo "✗ 未找到 $BL（请在项目根运行）"; exit 1; }

cmd="$1"
[ -n "$cmd" ] || { sed -n "3,12p" "$0"; exit 2; }
shift || true

run_gate() {
  for C in "$HERE/check.sh" "ai-dev-guide/scripts/check.sh"; do
    if [ -f "$C" ]; then
      if bash "$C" --deployed "$(pwd)" --only 9 >/dev/null 2>&1; then echo "✓ 门禁 9 通过";
      else echo "⚠ 门禁 9 未过（backlog 不变量）——请检查最近改动"; fi
      return 0;
    fi
  done
}

case "$cmd" in
  next|show|add|note|status|migrate)
    ARGV="$@" python3 - "$BL" "$cmd" "$@" <<'PYEOF'
import os, re, sys, glob, datetime
bl_path, cmd = sys.argv[1], sys.argv[2]
argv = sys.argv[3:]
text = open(bl_path, encoding="utf-8").read()
lines = text.split("\n")
BT = chr(96)

def counter():
    m = re.search("下一编号：\\*\\*#(\\d+)\\*", text)
    if not m: sys.exit("✗ 缺「下一编号：**#N**」计数器")
    return int(m.group(1))

def card_start(i):
    return re.match(r"^- \[([ x~])\] \*\*#(\d+) ", lines[i])

def card_block(idx):
    j = idx + 1
    while j < len(lines) and not card_start(j) and not lines[j].startswith("## ") and not lines[j].startswith("---"):
        j += 1
    return idx, j

def find_card(n):
    for i, l in enumerate(lines):
        m = card_start(i)
        if m and int(m.group(2)) == n: return i
    sys.exit("✗ 未找到卡片 #%s" % n)

if cmd == "next":
    print("下一编号：#%d" % counter()); sys.exit(0)

if cmd == "show":
    n = int(argv[0]); i = find_card(n); s, e = card_block(i)
    print("\n".join(lines[s:e])); sys.exit(0)

if cmd == "add":
    title = argv[0]
    summary = argv[1] if len(argv) > 1 else ""
    rest = argv[2:]; prio = "2"
    if "-p" in rest:
        k = rest.index("-p"); p = rest[k+1]
        if p not in {"0","1","2","3","4"}: sys.exit("✗ -p 取值 0-4")
        prio = p; del rest[k:k+2]
    tags = "".join(" " + BT + t + BT for t in rest if not t.startswith("-"))
    n = counter()
    if summary and len(summary) > 120: summary = summary[:117] + "…"  # 按字符截断，防 UTF-8 烂尾
    card = [("- [ ] **#%d %s**%s" % (n, title, tags)).rstrip()]
    if summary: card.append("  - " + summary)
    card.append("  - → 详情：docs/journal/（开工时 new-batch 建批次文件）")
    sec = "## P%s " % prio
    placed = False
    for i, l in enumerate(lines):
        if l.startswith(sec):
            j = i + 1
            while j < len(lines) and lines[j].strip() == "": j += 1
            lines[j:j] = card + [""]
            placed = True
            break
    if not placed: sys.exit("✗ 未找到 %s 节（P0-P4 节序须齐全）" % sec)
    new_text = "\n".join(lines)
    new_text = re.sub("(下一编号：)\\*\\*#\\d+\\*\\*", "\\1**#%d**" % (n+1), new_text, count=1)
    open(bl_path, "w", encoding="utf-8").write(new_text)
    print("✓ 已登记 #%d（P%s）；下一编号 #%d" % (n, prio, n+1)); sys.exit(0)

if cmd == "note":
    n = int(argv[0]); note = argv[1]
    i = find_card(n); s, e = card_block(i)
    stamp = datetime.date.today().isoformat()
    lines.insert(e, "  - %s note: %s" % (stamp, note))
    open(bl_path, "w", encoding="utf-8").write("\n".join(lines))
    print("✓ 已给 #%d 追加注记" % n); sys.exit(0)

if cmd == "status":
    n = int(argv[0]); st = argv[1]
    if st not in {"todo", "verify"}: sys.exit("✗ status 仅 todo(进行中) | verify(待验证)")
    i = find_card(n)
    if st == "verify": lines[i] = lines[i].replace("- [ ] ", "- [~] ", 1)
    else: lines[i] = lines[i].replace("- [~] ", "- [ ] ", 1)
    open(bl_path, "w", encoding="utf-8").write("\n".join(lines))
    print("✓ #%d → %s" % (n, st)); sys.exit(0)

if cmd == "migrate":
    n = int(argv[0]); rest = argv[1:]
    reason = None; jf = None
    if "-r" in rest: k = rest.index("-r"); reason = rest[k+1]; del rest[k:k+2]
    if "--journal" in rest: k = rest.index("--journal"); jf = rest[k+1]; del rest[k:k+2]
    i = find_card(n); s, e = card_block(i)
    card = list(lines[s:e])
    card[0] = card[0].replace('- [~] ', '- [x] ', 1).replace('- [ ] ', '- [x] ', 1)
    if card[0].startswith("- [ ]") and not reason:
        sys.exit("✗ #%d 尚未验证（[ ]）——先 status %d verify，或 -r \"<显式依据>\"" % (n, n))
    if not jf:
        js = sorted(f for f in glob.glob("docs/journal/*.md") if not f.endswith("README.md"))
        if not js: sys.exit("✗ docs/journal/ 无批次文件——先 backlog.sh journal new")
        jf = js[-1]
    if not os.path.exists(jf): sys.exit("✗ journal 文件不存在：%s" % jf)
    jt = open(jf, encoding="utf-8").read()
    stamp = datetime.date.today().isoformat()
    basis = reason if reason else "用户验收通过"
    sec = "## 已完结卡片迁入（%s）" % stamp
    if sec in jt:
        jt = jt.replace(sec, sec + "\n\n- 迁入依据：" + basis, 1)
    else:
        jt = jt.rstrip("\n") + "\n\n" + sec + "\n\n- 迁入依据：" + basis + "\n\n" + "\n".join(card) + "\n"
    open(jf, "w", encoding="utf-8").write(jt)
    del lines[s:e]
    while s < len(lines) and lines[s] == "" and s > 0 and lines[s-1] == "": del lines[s]
    open(bl_path, "w", encoding="utf-8").write("\n".join(lines))
    print("✓ #%d 已迁入 %s（计数器不动，编号永不回收）" % (n, jf)); sys.exit(0)
PYEOF
    run_gate
    ;;
  journal)
    sub="$1"; shift || true
    case "$sub" in
      new)
        NB="$HERE/new-batch.sh"
        [ -f "$NB" ] || NB="ai-dev-guide/scripts/new-batch.sh"
        exec bash "$NB" "$1"
        ;;
      append)
        F="$1"; T="$2"
        if [ -z "$F" ] || [ -z "$T" ]; then echo '用法: backlog.sh journal append <file> "<文本>"'; exit 2; fi
        if [ ! -f "$F" ]; then echo "✗ 文件不存在：$F"; exit 1; fi
        printf '%s %s\n' "$(date +%F)" "$T" >> "$F"
        echo "✓ 已追加到 $F（append-only——禁全量覆写重写 journal）"
        ;;
      *) echo '用法: backlog.sh journal new <批次名> | journal append <file> "<文本>"'; exit 2 ;;
    esac
    ;;
  *) echo "未知子命令 $cmd"; exit 2 ;;
esac