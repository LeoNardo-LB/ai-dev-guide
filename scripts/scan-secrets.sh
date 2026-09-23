#!/usr/bin/env bash
# ============================================================
# scan-secrets.sh — 敏感信息扫描（提交/发版前与 CI 运行）
# 检测：私钥/证书块、API token 各家格式、密码赋值、
#       内网地址、个人信息（邮箱/手机/身份证）。
# 白名单 scripts/scan-secrets.allow 两种规则（每行一条，# 开头为注释）：
#   路径 glob   如 scripts/scan-secrets.sh —— 整个文件放行（按路径匹配）
#   :字面量     以冒号起头 —— 仅当命中行包含该字面量时放行（内容豁免）
# 退出码：0 干净 / 1 发现疑似敏感信息 / 2 用法错误。
# 设计约束：
#   1. 计数与判定必须在主 shell 完成——逐文件 + 进程替换读命中，
#      禁止 grep | while 管道（子 shell 内变量自增会丢失）。
#   2. 逐文件两段式（先 grep -l 列文件、再逐文件 grep -n）：文件名含冒号
#      与超长行豁免才可正确解析（沙盒审计 D3/D4 定规）。
# ============================================================
set -uo pipefail
[ $# -eq 0 ] || { echo '用法: scan-secrets.sh（无参数；扫描脚本所在仓库，白名单 scripts/scan-secrets.allow）'; exit 2; }
cd "$(dirname "$0")/.." || exit 2
FAIL=0; HITS=0
ALLOW=scripts/scan-secrets.allow
# 白名单缺失：按空表扫描（不静默建文件污染仓库）；警示自报风险（沙盒审计 D2 定规）
if [ ! -f "$ALLOW" ]; then
  echo "⚠ 白名单缺失：scripts/scan-secrets.allow——按空表扫描（扫描器自身规则可能自报）；从源仓恢复后消除"
  ALLOW=/dev/null
fi

# 路径规则：整个文件放行（glob 匹配相对仓根路径）
allow_path() {
  local f="$1" rule
  f="./${f#./}"
  while IFS= read -r rule; do
    case "$rule" in ''|'#'*|:*) continue ;; esac
    case "$f" in ./$rule) return 0 ;; esac
  done < "$ALLOW"
  return 1
}

# 内容规则：命中行包含指定字面量时放行（判定用完整行，仅展示截断——沙盒审计 D3 定规）
allow_content() {
  local content="$1" rule
  while IFS= read -r rule; do
    case "$rule" in :*) ;; *) continue ;; esac
    rule="${rule#:}"
    [ -z "$rule" ] && continue
    case "$content" in *"$rule"*) return 0 ;; esac
  done < "$ALLOW"
  return 1
}

# $1=类别；$2=文件名 glob（空格分隔多个）；$3=内容豁免正则（可空）；$4=主 pattern；$5=i（可选，大小写不敏感）
scan_pattern() {
  local cat="$1" globs="$2" vpat="$3" pat="$4" gi="${5:-}"
  [ "$gi" = i ] && gi=-i || gi=
  local f line n content g matched
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in ./.git/*) continue ;; esac
    # case 的 | 选择符是语法元素，不能来自变量展开——多 glob 空格分隔逐个判定（R10 回归定规）
    matched=0
    for g in $globs; do
      case "${f##*/}" in $g) matched=1; break ;; esac
    done
    [ "$matched" = 1 ] || continue
    f="./${f#./}"
    if allow_path "$f"; then continue; fi
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      n="${line%%:*}"; content="${line#*:}"
      if [ -n "$vpat" ] && printf '%s\n' "$content" | grep -qiE -- "$vpat"; then continue; fi
      if allow_content "$content"; then continue; fi
      echo "✗ [$cat] $f:$n"
      echo "    ${content:0:90}"
      HITS=$((HITS+1)); FAIL=1
    done < <(grep -nI $gi -E -- "$pat" "$f" 2>/dev/null)
  done < <(grep -rIl $gi -E -- "$pat" . 2>/dev/null)
}

echo "== 敏感信息扫描 =="

scan_pattern "私钥/证书" '*' '' \
  'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY|BEGIN CERTIFICATE'

scan_pattern "token" '*' '' \
  'gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}'

scan_pattern "密钥赋值" '*.sh *.py *.yml *.yaml *.properties' \
  '占位|待填|placeholder|<[a-z]+>|\$\{|用 Secrets|CI Secrets|不进.?git|Secrets? 注入' \
  '(password|passwd|secret|api[_-]?key|access[_-]?token).{0,4}[:=].{0,4}[^ <>{}]+' i

scan_pattern "内网地址" '*.md *.yml *.sh' \
  '示例|范文|template|待填|10\.0\.2\.2' \
  '\b(10\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]+\.[0-9]+\b'

scan_pattern "邮箱" '*.md *.yml *.sh' \
  'semver\.org|keepachangelog\.com|github\.com|example\.com|@param|@see|@return' \
  '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(\.[a-z]{2,})+'

scan_pattern "手机/身份证" '*.md' '' \
  '\b1[3-9][0-9]{9}\b|\b[0-9]{17}[0-9Xx]\b'

echo "---"
if [ "$FAIL" -eq 0 ]; then
  echo "扫描结果：干净（0 疑似命中）"
else
  echo "扫描结果：发现 $HITS 处疑似敏感信息"
  echo "处置：真敏感 → 脱敏后重新提交；确认误报 → 加白名单 scripts/scan-secrets.allow（路径 glob 或 :字面量）"
  exit 1
fi
