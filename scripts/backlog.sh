#!/usr/bin/env bash
# ============================================================
# backlog.sh — backlog/journal 账本操作（防手工直编事故）
# 用法（在目标项目根运行；卡片区禁止手工直编——覆写丢章/同号双卡事故定规）：
#   backlog.sh add "<标题>" "<≤3行摘要>" [tag ...] [-p 0-4]  登记新卡（自动编号/计数器自增）
#   backlog.sh note <N> "<文本>"                              给 #N 追加一行注记（反馈归卡）
#   backlog.sh status <N> <todo|verify>                       切换 [ ] / [~]
#   backlog.sh prio <N> <0-4>                                 调整优先级（跨节迁移 + note 留痕）
#   backlog.sh migrate <N> [-r "<未验迁移依据>"] [--journal <file>]  迁 #N 入 journal（未验卡须 -r）
#   backlog.sh journal new "<批次名kebab>"                     建 journal 批次文件（同 new-batch.sh）
#   backlog.sh journal append <file> "<文本>"                  追加一行（append-only，禁全量覆写）
#   backlog.sh next | show <N>                                 查看计数器 / 单卡
# 状态机与迁移规则唯一归宿：workflows/requirements.md 第 4/5 节。
# 变更后自动跑部署门禁 9（存在 check.sh 时）；门禁失败即退出码 1。
# 写入均为临时文件 + 原子替换；账本加文件锁（并发操作串行化，防覆写丢卡）。
# ============================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BL="backlog.md"
[ -f "$BL" ] || { echo "✗ 未找到 $BL（请在项目根运行）"; exit 1; }

cmd="${1:-}"
[ -n "$cmd" ] || { sed -n "3,13p" "$0"; exit 2; }
shift || true

run_gate() {
  for C in "$HERE/check.sh" "ai-dev-guide/scripts/check.sh"; do
    if [ -f "$C" ]; then
      if bash "$C" --deployed "$(pwd)" --only 9 >/dev/null 2>&1; then echo "✓ 门禁 9 通过";
      else echo "⚠ 门禁 9 未过（backlog 不变量）——规则见 workflows/requirements.md 第 4/5 节"; return 1; fi
      return 0;
    fi
  done
}

case "$cmd" in
  next|show|add|note|status|prio|migrate)
    ARGV="$@" python3 - "$BL" "$cmd" "$@" <<'PYEOF'
import os, re, sys, glob, datetime, fcntl
bl_path, cmd = sys.argv[1], sys.argv[2]
argv = sys.argv[3:]
BT = chr(96)

# 账本文件锁：并发 add/migrate 串行化（防全量读改写互相覆写——并发丢卡事故定规）。
# 锁必须用独立 .lock 文件：数据文件经 os.replace 换 inode，锁旧 inode 的新进程互不可见（ABA 竞态实测）。
_lock_fd = open(bl_path + ".lock", "w")
fcntl.flock(_lock_fd, fcntl.LOCK_EX)
text = open(bl_path, encoding="utf-8").read()
lines = text.split("\n")

def atomic_write(path, content):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(content)
    os.replace(tmp, path)

def counter():
    m = re.search(r"下一编号：\*\*#(\d+)\*", text)
    if not m: sys.exit("✗ 缺「下一编号：**#N**」计数器——格式见 workflows/requirements.md 第 2 节")
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
        if p not in {"0","1","2","3","4"}: sys.exit("✗ -p 取值 0-4——分级判据见 workflows/requirements.md 第 3 节")
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
    if not placed: sys.exit("✗ 未找到 %s 节（P0-P4 节序须齐全——见 registries/backlog.md 骨架）" % sec)
    new_text = "\n".join(lines)
    new_text = re.sub(r"(下一编号：)\*\*#\d+\*\*", r"\1**#%d**" % (n+1), new_text, count=1)
    atomic_write(bl_path, new_text)
    print("✓ 已登记 #%d（P%s）；下一编号 #%d" % (n, prio, n+1)); sys.exit(0)

if cmd == "note":
    n = int(argv[0]); note = argv[1]
    i = find_card(n); s, e = card_block(i)
    stamp = datetime.date.today().isoformat()
    lines.insert(e, "  - %s note: %s" % (stamp, note))
    atomic_write(bl_path, "\n".join(lines))
    print("✓ 已给 #%d 追加注记" % n); sys.exit(0)

if cmd == "status":
    n = int(argv[0]); st = argv[1]
    if st not in {"todo", "verify"}: sys.exit("✗ status 仅 todo(进行中) | verify(待验证)")
    i = find_card(n)
    if st == "verify":
        if lines[i].startswith("- [ ]"): lines[i] = lines[i].replace("- [ ] ", "- [~] ", 1)
        elif lines[i].startswith("- [~]"): pass
        else: sys.exit("✗ #%d 非 [ ] 状态，不能转 verify" % n)
    else:
        if lines[i].startswith("- [~]"): lines[i] = lines[i].replace("- [~] ", "- [ ] ", 1)
        elif lines[i].startswith("- [ ]"): pass
        else: sys.exit("✗ #%d 非 [~] 状态，不能转 todo" % n)
    atomic_write(bl_path, "\n".join(lines))
    print("✓ #%d → %s" % (n, st)); sys.exit(0)

if cmd == "prio":
    if len(argv) < 2: sys.exit("✗ 用法：backlog.sh prio <N> <0-4>")
    n = int(argv[0]); p = argv[1]
    if p not in {"0","1","2","3","4"}: sys.exit("✗ 优先级取值 0-4——判据见 workflows/requirements.md 第 3 节")
    i = find_card(n); s, e = card_block(i)
    m = card_start(i)
    if not m: sys.exit("✗ #%d 非卡片行" % n)
    cur_sec = None
    for k in range(i, -1, -1):
        if lines[k].startswith("## P"): cur_sec = lines[k]; break
    sec = "## P%s " % p
    if cur_sec and cur_sec.startswith(sec):
        sys.exit("✓ #%d 已在 P%s 节" % (n, p))
    card = list(lines[s:e])
    stamp = datetime.date.today().isoformat()
    card.append("  - %s prio: %s → P%s（经 backlog.sh prio）" % (stamp, (cur_sec or "?").split(" ")[1] if cur_sec else "?", p))
    del lines[s:e]
    while s < len(lines) and lines[s] == "" and s > 0 and lines[s-1] == "": del lines[s]
    placed = False
    for k, l in enumerate(lines):
        if l.startswith(sec):
            j = k + 1
            while j < len(lines) and lines[j].strip() == "": j += 1
            lines[j:j] = card + [""]
            placed = True
            break
    if not placed: sys.exit("✗ 未找到 %s 节（P0-P4 节序须齐全）" % sec)
    atomic_write(bl_path, "\n".join(lines))
    print("✓ #%d 优先级已调至 P%s（note 留痕；计数器不动）" % (n, p)); sys.exit(0)

if cmd == "migrate":
    n = int(argv[0]); rest = argv[1:]
    reason = None; jf = None
    if "-r" in rest: k = rest.index("-r"); reason = rest[k+1]; del rest[k:k+2]
    if "--journal" in rest: k = rest.index("--journal"); jf = rest[k+1]; del rest[k:k+2]
    i = find_card(n); s, e = card_block(i)
    card = list(lines[s:e])
    # 守卫必须先于状态改写：读原始 checkbox 判定（否则恒假——死守卫事故定规）
    orig_open  = card[0].startswith("- [ ]")
    orig_verify = card[0].startswith("- [~]")
    if orig_open and not reason:
        sys.exit("✗ #%d 尚未验证（[ ]）——先 status %d verify，或 -r \"<显式依据>\"（规则见 workflows/requirements.md 第 5 节）" % (n, n))
    card[0] = card[0].replace('- [~] ', '- [x] ', 1).replace('- [ ] ', '- [x] ', 1)
    if not jf:
        js = sorted(f for f in glob.glob("docs/journal/*.md") if not f.endswith("README.md"))
        if not js: sys.exit("✗ docs/journal/ 无批次文件——先 backlog.sh journal new")
        jf = js[-1]
    if not os.path.exists(jf): sys.exit("✗ journal 文件不存在：%s" % jf)
    # 依据行诚实化：未验迁移必须显式依据（上方已拦）；[~] 无 -r 时如实记录，禁止默认写「用户验收通过」
    if reason: basis = reason
    elif orig_verify: basis = "[~] 迁出——自动化验证通过，显式验收依据未附"
    else: basis = "已验证迁移"
    stamp = datetime.date.today().isoformat()
    jt = open(jf, encoding="utf-8").read()
    sec = "## 已完结卡片迁入（%s）" % stamp
    if sec in jt:
        # 同日多卡：在节【末尾】整块追加（依据行 + 卡片正文）——只追加不动已有行，
        # 防「只插依据行、正文丢失」的同日二次迁移丢卡事故
        jl = jt.split("\n")
        si = jl.index(sec)
        ej = len(jl)
        for k in range(si + 1, len(jl)):
            if jl[k].startswith("## "): ej = k; break
        while ej > 0 and jl[ej-1].strip() == "": ej -= 1
        jl[ej:ej] = ["", "- 迁入依据：" + basis, ""] + card
        jt = "\n".join(jl)
    else:
        jt = jt.rstrip("\n") + "\n\n" + sec + "\n\n- 迁入依据：" + basis + "\n\n" + "\n".join(card) + "\n"
    atomic_write(jf, jt)
    del lines[s:e]
    while s < len(lines) and lines[s] == "" and s > 0 and lines[s-1] == "": del lines[s]
    atomic_write(bl_path, "\n".join(lines))
    print("✓ #%d 已迁入 %s（计数器不动，编号永不回收）" % (n, jf)); sys.exit(0)
PYEOF
    run_gate || exit 1
    ;;
  journal)
    sub="${1:-}"
    [ -n "$sub" ] || { echo '用法: backlog.sh journal new <批次名> | journal append <file> "<文本>"'; exit 2; }
    shift || true
    case "$sub" in
      new)
        NB="$HERE/new-batch.sh"
        [ -f "$NB" ] || NB="ai-dev-guide/scripts/new-batch.sh"
        exec bash "$NB" "$1"
        ;;
      append)
        F="$1"; T="$2"
        if [ -z "$F" ] || [ -z "$T" ]; then echo '用法: backlog.sh journal append <file> "<文本>"'; exit 2; fi
        case "$F" in
          */backlog.md|backlog.md) echo "✗ 拒绝：journal append 不能写账本本体（backlog 卡片区禁覆写）"; exit 1 ;;
        esac
        if [ ! -f "$F" ]; then echo "✗ 文件不存在：$F"; exit 1; fi
        printf '%s %s\n' "$(date +%F)" "$T" >> "$F"
        echo "✓ 已追加到 $F（append-only——禁全量覆写重写 journal）"
        ;;
      *) echo '用法: backlog.sh journal new <批次名> | journal append <file> "<文本>"'; exit 2 ;;
    esac
    ;;
  *) echo "未知子命令 $cmd"; sed -n "3,13p" "$0"; exit 2 ;;
esac
