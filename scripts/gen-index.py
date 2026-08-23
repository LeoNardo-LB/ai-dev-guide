#!/usr/bin/env python3
# ============================================================
# gen-index.py — 从 manifest.yaml 生成全部派生索引段
# 用法：
#   gen-index.py            生成/更新各文件中的 <!-- GEN:... --> 段
#   gen-index.py --check    只校验不写入（幂等检查，漂移则退出码 1）
# 设计：manifest.yaml 是唯一元数据中心；本脚本是其唯一投影器。
# 零外部依赖：内置 YAML 严格子集解析器（两空格缩进/标量/行内列表）。
# ============================================================
import sys, re, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class ManifestError(Exception):
    pass

def parse_manifest(path):
    """解析 manifest.yaml 的受限 YAML 子集。返回 dict。"""
    data = {}
    stack = [(-1, data)]  # (indent, container)
    docs = None
    current_doc = None
    section = None

    for lineno, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = raw.rstrip("\n")
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent % 2 != 0:
            raise ManifestError(f"manifest.yaml:{lineno} 缩进必须是 2 的倍数， got {indent}")

        # 弹栈到父级
        while stack and indent <= stack[-1][0]:
            stack.pop()
        parent = stack[-1][1] if stack else data

        m_list = re.match(r"^-\s+(\w+):\s*(.*)$", stripped)
        m_kv = re.match(r"^(\w+):\s*(.*)$", stripped)

        if m_list:
            key, val = m_list.group(1), m_list.group(2).strip()
            # 列表项：docs 列表中的条目起点
            if section == "docs":
                if current_doc is None and key != "id":
                    raise ManifestError(f"manifest.yaml:{lineno} docs 列表项必须以 - id: 开始")
                current_doc = {}
                docs.append(current_doc)
                stack.append((indent, current_doc))
                _assign(current_doc, key, val, lineno)
            else:
                raise ManifestError(f"manifest.yaml:{lineno} 意外的列表项（仅 docs 允许）")
        elif m_kv:
            key, val = m_kv.group(1), m_kv.group(2).strip()
            if key in ("system", "planes", "defaults", "docs") and val == "":
                section = key
                if key == "docs":
                    docs = data.setdefault("docs", [])
                    current_doc = None
                    stack.append((indent, data))
                else:
                    sub = {}
                    data[key] = sub
                    stack.append((indent, sub))
            else:
                if current_doc is not None and stack and stack[-1][1] is current_doc:
                    _assign(current_doc, key, val, lineno)
                elif parent is not data or section is None:
                    _assign(parent, key, val, lineno)
                else:
                    raise ManifestError(f"manifest.yaml:{lineno} 顶层键 {key} 不识别")
        else:
            raise ManifestError(f"manifest.yaml:{lineno} 无法解析: {stripped[:60]}")
    return data

def _assign(target, key, val, lineno):
    if val == "":
        raise ManifestError(f"manifest.yaml:{lineno} {key} 值为空")
    if val.startswith("[") and val.endswith("]"):
        inner = val[1:-1].strip()
        target[key] = [v.strip().strip("'\"") for v in inner.split(",")] if inner else []
    else:
        target[key] = val.strip("'\"")

def load():
    mf = os.path.join(ROOT, "manifest.yaml")
    data = parse_manifest(mf)
    ids = [d["id"] for d in data["docs"]]
    if len(ids) != len(set(ids)):
        dup = [i for i in ids if ids.count(i) > 1]
        raise ManifestError(f"重复 id: {sorted(set(dup))}")
    paths = [d["path"] for d in data["docs"]]
    if len(paths) != len(set(paths)):
        dup = [p for p in paths if paths.count(p) > 1]
        raise ManifestError(f"重复 path: {sorted(set(dup))}")
    for d in data["docs"]:
        for f in ("id", "path", "kind", "plane", "level", "purpose", "use_when", "trim_group", "indexed"):
            if f not in d:
                raise ManifestError(f"docs 条目 {d.get('id','?')} 缺字段 {f}")
        if d["level"] not in ("MUST", "SHOULD", "MAY"):
            raise ManifestError(f"{d['id']}: level 非法 {d['level']}")
        if d["kind"] not in ("content", "template", "registry"):
            raise ManifestError(f"{d['id']}: kind 非法 {d['kind']}")
        if d["plane"] not in ("deployed", "source"):
            raise ManifestError(f"{d['id']}: plane 非法 {d['plane']}")
    return data

LEVEL_ORDER = {"MUST": 0, "SHOULD": 1, "MAY": 2}
LEVEL_ICON = {"MUST": "🔴", "SHOULD": "🟡", "MAY": "🟢"}

def indexed_docs(data, deployed_only=True):
    ds = [d for d in data["docs"] if d["indexed"] == "true" or d["indexed"] is True]
    if deployed_only:
        ds = [d for d in ds if d["plane"] == "deployed"]
    return sorted(ds, key=lambda d: (LEVEL_ORDER[d["level"]], d["path"]))

def b(v):
    """布尔字段归一。"""
    return v is True or v == "true"

def gen_agents_index(data):
    """AGENTS.md.template 的索引表体（{{SYS}} 前缀）。"""
    rows = ["| 级别 | 文档 | 用途 | Use when |", "|------|------|------|----------|"]
    for d in indexed_docs(data):
        p = d["path"]
        rows.append(f"| {LEVEL_ICON[d['level']]} {d['level']} | [{{{{SYS}}}}/{p}]({{{{SYS}}}}/{p}) | {d['purpose']} | {d['use_when']} |")
    return "\n".join(rows)

def gen_readme_tree(data):
    """README 的文档总览表体。"""
    rows = ["| 平面 | 路径 | 级别 | 用途 |", "|------|------|------|------|"]
    for d in sorted(data["docs"], key=lambda d: (d["plane"], d["path"])):
        icon = LEVEL_ICON.get(d["level"], "·")
        rows.append(f"| {d['plane']} | `{d['path']}` | {icon} | {d['purpose']} |")
    return "\n".join(rows)

def gen_full_table(data):
    """system-design 的全字段交叉引用表（含裁剪组与溯源）。"""
    rows = ["| id | 路径 | 类 | 平面 | 级别 | 裁剪组 | 用途 | Use when |", "|----|------|----|------|------|--------|------|----------|"]
    for d in sorted(data["docs"], key=lambda d: (d["plane"], d["path"])):
        rows.append(f"| {d['id']} | {d['path']} | {d['kind']} | {d['plane']} | {d['level']} | {d['trim_group']} | {d['purpose']} | {d['use_when']} |")
    return "\n".join(rows)

def gen_trim_table(data):
    """onboarding 的裁剪组表体。"""
    groups = {}
    for d in data["docs"]:
        groups.setdefault(d["trim_group"], []).append(d)
    rows = ["| 裁剪组 | 文档 | 何时可删 |", "|--------|------|----------|"]
    policy = {
        "core": "永不（系统核心）",
        "ui": "无 UI 的项目（库/CLI）",
        "stack-example": "非对应栈的项目",
        "registry": "永不（init 实例化源）",
    }
    for g in sorted(groups):
        paths = "、".join(f"`{d['path']}`" for d in sorted(groups[g], key=lambda d: d["path"]))
        rows.append(f"| {g} | {paths} | {policy.get(g, '?')} |")
    return "\n".join(rows)

GENERATORS = {
    "agents-index": gen_agents_index,
    "readme-tree": gen_readme_tree,
    "full-table": gen_full_table,
    "trim-table": gen_trim_table,
}

def rewrite(path, name, body):
    """把生成体写入文件的 GEN 段；返回是否发生变化。"""
    start, end = f"<!-- GEN:{name}:start -->", f"<!-- GEN:{name}:end -->"
    txt = open(path, encoding="utf-8").read()
    if start not in txt or end not in txt:
        raise ManifestError(f"{path} 缺 GEN 标记 {name}")
    pat = re.compile(re.escape(start) + r".*?" + re.escape(end), re.S)
    new_block = start + "\n" + body + "\n" + end
    new_txt = pat.sub(lambda _: new_block, txt, count=1)
    if new_txt == txt:
        return False
    open(path, "w", encoding="utf-8").write(new_txt)
    return True

def main():
    check_only = "--check" in sys.argv
    data = load()
    sysinfo = data.get("system", {})
    targets = {
        "agents-index": os.path.join(ROOT, "AGENTS.md.template"),
        "readme-tree": os.path.join(ROOT, "README.md"),
        "full-table": os.path.join(ROOT, "meta", "system-design.md"),
        "trim-table": os.path.join(ROOT, "bootstrap", "onboarding.md"),
    }
    drifted = []
    for name, fn in GENERATORS.items():
        path = targets[name]
        if not os.path.exists(path):
            print(f"⚠ 跳过 {name}（{path} 不存在——迁移期允许）")
            continue
        body = fn(data)
        if check_only:
            start, end = f"<!-- GEN:{name}:start -->", f"<!-- GEN:{name}:end -->"
            txt = open(path, encoding="utf-8").read()
            if start not in txt:
                print(f"⚠ {os.path.relpath(path, ROOT)} 缺 {name} 标记")
                continue
            cur = txt.split(start, 1)[1].split(end, 1)[0].strip()
            if cur != body.strip():
                drifted.append(name)
        else:
            if rewrite(path, name, body):
                print(f"✓ 更新 {name} → {os.path.relpath(path, ROOT)}")
    if check_only:
        if drifted:
            print(f"✗ GEN 段漂移: {drifted}（跑 gen-index.py 同步）")
            sys.exit(1)
        print("✓ 全部 GEN 段与 manifest 一致（幂等）")
    else:
        n_docs = len(data["docs"])
        must_n = sum(1 for d in indexed_docs(data) if d["level"] == "MUST")
        print(f"完成：{n_docs} 文档；索引 MUST {must_n} 条")

if __name__ == "__main__":
    try:
        main()
    except ManifestError as e:
        print(f"✗ manifest 错误: {e}")
        sys.exit(2)
