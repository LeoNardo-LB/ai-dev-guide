#!/usr/bin/env python3
# ============================================================
# _gates.py — check.sh 的 python 门禁内核（链接/预算/MUST/§引用/结构/账本）
# 由 check.sh 调用；不直接人工运行。
# 用法：_gates.py <gate> [args...]
#   links <mode>     门禁 1a：相对链接校验（{{SYS}} 规则）
#   structure <mode> 门禁 1b：文档结构完整（H1 单行无表格碎片 + 表格行首管道）
#   budget           门禁 2：行数预算（manifest 驱动）
#   must <mode>      门禁 4：MUST 稀缺性 + L0（AGENTS）≤200 行
#   sections         门禁 6：§引用可解析（行内多链接逐一尝试 + 子节号）
#   backlog          门禁 9：backlog 不变量（python 内核，无 grep -P 依赖）
# 规则归宿：meta/doc-governance.md（门禁映射）、meta/system-design.md（结构）。
# ============================================================
import re, os, sys, glob

DEPLOYED_SCOPE = ("AGENTS.md", "AGENTS.md.new", "CONTEXT.md", "backlog.md",
                   "docs/ability-domains.md", "docs/architecture-debt.md")

def repo_files(mode="source"):
    """source 模式扫全仓；deployed 模式只扫本系统产物（用户自己的 md 不属门禁管辖）。"""
    files = [f for f in glob.glob("**/*.md", recursive=True)]
    files += [f for f in glob.glob("**/*.md.template", recursive=True)]
    files += ["AGENTS.md.template"] if os.path.exists("AGENTS.md.template") else []
    seen, out = set(), []
    for f in files:
        if f not in seen:
            seen.add(f); out.append(f)
    if mode == "deployed":
        sysdir = os.environ.get("DSH_SYS_DIR", "ai-dev-guide")
        out = [f for f in out
               if f in DEPLOYED_SCOPE or f.startswith(sysdir + "/")
               or f.startswith("docs/journal/") or f.startswith("docs/specs/")]
    return out

def hist_exempt(f):
    # docs/research/ 为调研报告档案（2026-09-23 审计定规：与 journal 同为历史面）
    return f.startswith(("specs/", "docs/journal/", "docs/archive/", "docs/adr/", "docs/research/")) or f == "CHANGELOG.md"

def load_manifest():
    src = open("scripts/gen-index.py", encoding="utf-8").read().replace(
        'if __name__ == "__main__":', 'if False:')
    ns = {}
    ns['__file__'] = os.path.abspath('scripts/gen-index.py')
    exec(compile(src, "gen-index", "exec"), ns)
    return ns["load"]()

def gate_links(mode):
    broken = []
    for f in repo_files(mode):
        if hist_exempt(f): continue
        base = os.path.dirname(f)
        for i, line in enumerate(open(f, encoding="utf-8"), 1):
            for m in re.finditer(r"\]\(([^)\s]+)\)", line):
                t = m.group(1)
                if t.startswith(("http://", "https://", "mailto:", "#")): continue
                t2 = (t.split("#")[0] or t).strip()
                if "{{SYS}}" in t2:
                    if mode == "source" and f == "AGENTS.md.template": continue
                    broken.append(f"{f}:{i} 残留 {{SYS}}: {t2}"); continue
                if t2.startswith("<"): continue
                p = os.path.normpath(os.path.join(base, t2))
                if not os.path.exists(p): broken.append(f"{f}:{i} -> {t2}")
            # 含空格的裸链接（markdown 需 <> 或 %20，此前完全逃逸检查）
            for m in re.finditer(r"\]\([^)]* [^)]*\)", line):
                t = m.group(0)[2:-1]
                if t.startswith(("http", "mailto:")): continue
                broken.append(f"{f}:{i} 链接含空格（用 <> 或 %20）: {t}")
    if broken:
        print(f"✗ [1] 断链/非法链接 {len(broken)} 处")
        for x in broken[:15]: print("  ", x)
        return 1
    print("✓ [1] 全部相对链接可解析（{{SYS}} 规则符合模式；无空格链接）")
    return 0

def gate_structure(mode):
    """结构完整：H1 必须单行且不含表格碎片；表格区内行必须以 | 开头。
    由 verify.md 首屏损坏事故（H1 粘表格行 + 表格行缺行首管道）定规。"""
    issues = []
    for f in repo_files(mode):
        if hist_exempt(f): continue
        lines = open(f, encoding="utf-8").read().split("\n")
        if not lines: continue
        h1 = lines[0]
        if not h1.startswith("# "):
            issues.append(f"{f}:1 首行不是 H1（# 标题）")
        elif " | " in h1:
            issues.append(f"{f}:1 H1 混入表格碎片（' | '）")
        in_table = False
        for i, l in enumerate(lines[1:], 2):
            is_trow = l.startswith("|")
            if is_trow:
                in_table = True
            elif in_table and " | " in l and l.strip() and not l.startswith((">", "-", "#", "<", "`")):
                issues.append(f"{f}:{i} 表格区断裂行（缺行首 |）：{l[:60]}")
                in_table = False
            elif not l.strip():
                in_table = False
    if issues:
        print(f"✗ [1] 结构损坏 {len(issues)} 处——H1 单行/表格行首管道（见 meta/doc-writing-standards.md）")
        for x in issues[:15]: print("  ", x)
        return 1
    print("✓ [1] 文档结构完整（H1 单行、表格行首管道齐全）")
    return 0

def gate_budget():
    data = load_manifest()
    over = []
    for d in data["docs"]:
        if d["kind"] == "template": continue
        budget = int(d.get("budget", data["defaults"]["line_budget"]))
        p = d["path"]
        if not os.path.exists(p): continue
        n = sum(1 for _ in open(p, encoding="utf-8"))
        if n > budget: over.append(f"{p}: {n} 行 > 预算 {budget}")
    if over:
        print(f"✗ [2] 超预算 {len(over)} 份")
        for x in over: print("  ", x)
        return 1
    print("✓ [2] 全部内容/登记文档在 manifest 申报预算内")
    return 0

def gate_must(mode="source"):
    n = 0; limit = 7
    try:
        data = load_manifest()
        limit = int(data["defaults"].get("must_limit", 7))
        n = sum(1 for d in data["docs"]
                if d["plane"] == "deployed" and d["level"] == "MUST"
                and d["indexed"] in ("true", True))
    except Exception:
        pass  # 部署模式无 manifest：数 AGENTS.md 实例
    if mode == "deployed":
        limit_src, n_src = n, limit
        if os.path.exists("AGENTS.md"):
            n = sum(1 for l in open("AGENTS.md", encoding="utf-8") if l.strip().startswith("| 🔴 MUST"))
            limit = 7
    rc = 0
    if n > limit:
        print(f"✗ [4] 索引 MUST {n} 条 > 上限 {limit}——新增 MUST 必须挤掉一条旧的（见 meta/edit-card.md 准入速记）")
        rc = 1
    else:
        print(f"✓ [4] 索引 MUST {n} 条 ≤ {limit}")
    # L0 行数（edit-card 硬约束：AGENTS ≤200 行）
    l0 = "AGENTS.md" if (mode == "deployed" and os.path.exists("AGENTS.md")) else "AGENTS.md.template"
    if os.path.exists(l0):
        ln = sum(1 for _ in open(l0, encoding="utf-8"))
        if ln > 200:
            print(f"✗ [4] {l0} {ln} 行 > 200——L0 硬约束（meta/edit-card.md）：删非承重行或下沉主题文档")
            rc = 1
        else:
            print(f"✓ [4] {l0} {ln} 行 ≤ 200")
    return rc

def gate_sections():
    bad_refs, total = [], 0
    headings = {}
    dup_secs = []
    # 同文件小节编号唯一（双 §3.3 事故定规——2026-09-23 复审发现）
    for f in repo_files(os.environ.get("DSH_GATE_MODE", "source")):
        if hist_exempt(f): continue
        seen = {}
        for i, line in enumerate(open(f, encoding="utf-8"), 1):
            hm = re.match(r"^#{2,4}\s+(\d+(?:\.\d+)?)", line)
            if hm:
                k = hm.group(1)
                if k in seen: dup_secs.append(f"{f}:{i} 小节编号 {k} 重复（首见行 {seen[k]}）")
                seen[k] = i
    for f in repo_files(os.environ.get("DSH_GATE_MODE", "source")):
        if hist_exempt(f): continue
        base = os.path.dirname(f)
        for i, line in enumerate(open(f, encoding="utf-8"), 1):
            for m in re.finditer(r"§(\d+(?:\.\d+)?)|第\s?(\d+(?:\.\d+)?)\s?节", line):
                total += 1
                # 行内全部 .md 链接逐一尝试：任一含该编号即通过（防首链接误配——2026-09-23 审计 M-2）
                cands = []
                for lm in re.finditer(r"\]\(([^)\s]+\.md)\)", line):
                    tt = lm.group(1).replace("{{SYS}}/", "")
                    cands.append(os.path.normpath(os.path.join(base, tt)))
                # 文字式引用（registries 骨架等 {{SYS}} 可变名场景）：
                # a) 行内提及的 X.md（含裸文件名，全库唯一名匹配）
                # b) 「<基名> 第 N 节」模式（如「verify 第 2 节」）
                if not cands:
                    for wm in re.finditer(r"([\w./-]+\.md)", line):
                        tt = wm.group(1)
                        for root in (base, "."):
                            p = os.path.normpath(os.path.join(root, tt))
                            if os.path.exists(p): cands.append(p); break
                        else:
                            hits = glob.glob("**/" + os.path.basename(tt), recursive=True)
                            hits = [h for h in hits if not hist_exempt(h)]
                            if len(hits) == 1: cands.append(hits[0])
                if not cands:
                    for wm in re.finditer(r"([\w-]+)\s+第\s?\d", line):
                        hits = [h for h in glob.glob("**/" + wm.group(1) + ".md", recursive=True) if not hist_exempt(h)]
                        if len(hits) == 1: cands.append(hits[0]); break
                cands = [c for c in cands if os.path.exists(c)] or [f]
                sec_full = m.group(1) or m.group(2)
                sec_top = sec_full.split(".")[0]
                ok_any = False
                for cand in cands:
                    if cand not in headings:
                        hs = set()
                        for h in open(cand, encoding="utf-8"):
                            hm = re.match(r"^#{2,4}\s+(\d+(?:\.\d+)?)", h)
                            if hm: hs.add(hm.group(1))
                        headings[cand] = hs
                    if sec_full in headings[cand] or ("." not in sec_full and sec_full in headings[cand]):
                        ok_any = True; break
                if not ok_any:
                    bad_refs.append(f"{f}:{i} §{sec_full} 在候选目标无对应编号标题")
    if bad_refs or dup_secs:
        print(f"✗ [6] §引用断裂 {len(bad_refs)} 处 / 共 {total}；编号重复 {len(dup_secs)} 处")
        for x in dup_secs[:10]: print("  ", x)
        for x in bad_refs[:15]: print("  ", x)
        return 1
    print(f"✓ [6] {total} 处 §引用全部可解析（多链接逐一尝试；小节编号唯一）")
    return 0

def gate_backlog():
    """backlog 不变量（部署模式）。原 bash+grep -P 实现下沉 python：
    消除 BSD grep 无 -P 的部署炸点（macOS 可移植——2026-09-23 审计 U-P0-2）。
    归宿：workflows/requirements.md 第 4/5 节 + registries/backlog.md 不变量表。"""
    import glob as g
    issues = []
    if not os.path.exists("backlog.md"):
        print("✓ [9] 无 backlog.md，跳过"); return 0
    text = open("backlog.md", encoding="utf-8").read()
    lines = text.split("\n")
    # 1) 完结残留：任意缩进的 [x]/[X] 均报（[x] 仅迁移瞬间存在；嵌套/大写为绕过面）
    for i, l in enumerate(lines, 1):
        m = re.match(r"^(\s*)- \[([xX])\]", l)
        if m:
            issues.append(f"backlog.md:{i} 完结残留（迁移后顶层必须为零，嵌套/大写同罪）：{l[:50]}")
    # 2) checkbox 词表白名单 + 卡片编号唯一
    m = re.search(r"下一编号：\*\*#(\d+)\*", text)
    if not m:
        issues.append("backlog.md 缺「下一编号：**#N**」计数器")
        nxt = 0
    else:
        nxt = int(m.group(1))
    seen_ids = {}
    card_ids = []
    for i, l in enumerate(lines, 1):
        cm = re.match(r"^(\s*)- \[(.)\] \*\*#(\d+)", l)
        if cm:
            box, cid = cm.group(2), int(cm.group(3))
            if box not in (" ", "x", "~"):
                issues.append(f"backlog.md:{i} 非法 checkbox 状态 [{box}]（词表：[ ]/[~]/[x]，见 requirements 第 4 节）")
            if cm.group(1) == "":
                card_ids.append((cid, i))
                if cid in seen_ids:
                    issues.append(f"backlog.md:{i} 卡片编号 #{cid} 重复（首见于行 {seen_ids[cid]}——同号双卡事故）")
                seen_ids[cid] = i
    # 3) 计数器 > 全库最大编号（含 journal/specs；不限位数——5 位编号失明定规）
    max_id = 0
    for path in ["backlog.md"] + sorted(g.glob("docs/journal/*.md")) + sorted(g.glob("docs/specs/*.md")):
        if path.endswith("README.md"): continue
        try: t2 = open(path, encoding="utf-8").read()
        except OSError: continue
        if path == "backlog.md":
            # 账本内只认卡片标题行的编号——正文/note/P4 前提行里的外部单号（上游 #789、JIRA #4471）不算已用编号
            for hm in re.finditer(r"^- \[[ x~]\] \*\*#(\d+)", t2, re.M):
                max_id = max(max_id, int(hm.group(1)))
        else:
            # journal/specs 保留宽匹配（迁入卡为原文，编号出现在正文属正常）
            for hm in re.finditer(r"(?:^|\s|\*\*|>)#(\d+)(?=[\s：:*）]|$)", t2, re.M):
                if "下一编号" not in t2[max(0, hm.start()-20):hm.start()]:
                    max_id = max(max_id, int(hm.group(1)))
    if nxt > 0 and nxt <= max_id:
        issues.append(f"计数器 #{nxt} ≤ 最大编号 #{max_id}（编号永不回收——requirements 第 5 节）")
    # 4) P0-P4 节序唯一 + 卡片只在 P 节内 + P4 卡必含「前提」
    secs = [l for l in lines if l.startswith("## P")]
    sec_names = [s.split()[1] for s in secs]
    if sec_names != ["P0", "P1", "P2", "P3", "P4"]:
        issues.append(f"P 节异常（须 P0-P4 有序唯一）：{sec_names}")
    first_p = next((i for i, l in enumerate(lines, 1) if l.startswith("## P")), None)
    last_p = max((i for i, l in enumerate(lines, 1) if l.startswith("## P")), default=None)
    if first_p is not None:
        for i, l in enumerate(lines, 1):
            if re.match(r"^- \[", l) and not (first_p <= i):
                issues.append(f"backlog.md:{i} 卡片出现在 P 节之外（表头区）：{l[:40]}")
        # P4 节后自定义节放卡（审计 9.5 盲区）：P 节区块之外的顶层卡全部报
        p4_idx = next((i for i, l in enumerate(lines, 1) if l.startswith("## P4")), None)
        if p4_idx is not None:
            for i, l in enumerate(lines, 1):
                if i > p4_idx and re.match(r"^## ", l) and not l.startswith("## P"):
                    issues.append(f"backlog.md:{i} P 节之后出现自定义节（卡片只许在 P0-P4 节内）：{l[:40]}")
        # P4 卡必含「前提」行（逐卡块检查）
        in_p4 = False; block = []
        for i, l in enumerate(lines, 1):
            if not in_p4:
                if l.startswith("## P4"): in_p4 = True
                continue
            if l.startswith("## "):
                _p4_check(block, issues); block = []; in_p4 = False; continue
            if re.match(r"^- \[", l):
                _p4_check(block, issues); block = [(i, l)]; continue
            if block and (l.startswith("  ") or not l.strip()):
                block.append((i, l))
        _p4_check(block, issues)
    # 5) 悬空 docs/ 链接 + archive 引用
    for i, l in enumerate(lines, 1):
        for lm in re.finditer(r"\]\((docs/[^)#]+)\)", l):
            if not os.path.exists(lm.group(1)):
                issues.append(f"backlog.md:{i} 悬空链接：{lm.group(1)}")
        if "docs/archive/" in l:
            issues.append(f"backlog.md:{i} 含 archive 引用（backlog 只指向未决/journal）")
    # 6) 行数（warn-only，ADR-0004）
    n_lines = len(lines)
    warn_note = ""
    if n_lines > 250:
        warn_note = f"（⚠ {n_lines} 行 > 250——考虑迁移/清退，ADR-0004 承诺 ≤250）"
    if issues:
        print(f"✗ [9] backlog 不变量违反 {len(issues)} 处{warn_note}")
        for x in issues[:15]: print("  ", x)
        return 1
    print(f"✓ [9] backlog 不变量全部通过：零完结残留/计数器 #{nxt}>#{max_id}/P 节序/词表/编号唯一/P4 前提 {warn_note}")
    return 0

def _p4_check(block, issues):
    if not block: return
    body = "\n".join(x[1] for x in block)
    if "前提" not in body:
        issues.append(f"backlog.md:{block[0][0]} P4 卡缺「前提」行（外部前提阻塞——requirements 第 3 节）")

def main():
    if len(sys.argv) < 2:
        print("用法: _gates.py <links|structure|budget|must|sections|backlog> [mode]"); return 2
    gate = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("DSH_GATE_MODE", "source")
    if gate == "links":      return gate_links(mode)
    if gate == "structure":  return gate_structure(mode)
    if gate == "budget":     return gate_budget()
    if gate == "must":       return gate_must(mode)
    if gate == "sections":   return gate_sections()
    if gate == "backlog":    return gate_backlog()
    print(f"未知门禁 {gate}"); return 2

if __name__ == "__main__":
    sys.exit(main())
