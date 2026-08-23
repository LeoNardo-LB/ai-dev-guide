#!/usr/bin/env bash
# ============================================================
# scan-secrets.sh — 敏感信息扫描（提交/发版前与 CI 运行）
# 检测：私钥/证书块、API token 各家格式、密码赋值、
#       内网地址、个人信息（邮箱/手机/身份证）。
# 白名单：scripts/scan-secrets.allow 逐行 glob 或字面量，命中即放行
# 退出码：0 干净 / 1 发现疑似敏感信息
# ============================================================
set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0; HITS=0
ALLOW=scripts/scan-secrets.allow
[ -f "$ALLOW" ] || : > "$ALLOW"

allow() {
  local f="$1" content="$2" rule
  f="${f#./}"                       # 路径归一：去掉 ./ 前缀
  while IFS= read -r rule; do
    [ -z "$rule" ] && continue
    case "$f" in $rule) return 0 ;; esac
    case "$content" in *"$rule"*) return 0 ;; esac
  done < "$ALLOW"
  return 1
}

report() {
  local cat="$1" loc="$2" content="$3"
  if allow "${loc%%:*}" "$content"; then return; fi
  echo "✗ [$cat] $loc"
  echo "    $content"
  HITS=$((HITS+1)); FAIL=1
}

hit() { # $1=类别；stdin=文件:行号 列表
  local cat="$1" line f n
  while read -r line; do
    [ -z "$line" ] && continue
    f="${line%%:*}"; n="${line##*:}"
    report "$cat" "$line" "$(sed -n "${n}p" "$f" 2>/dev/null | head -c 90)"
  done
}

echo "== 敏感信息扫描 =="

grep -rnE 'BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY|BEGIN CERTIFICATE' --include='*' . 2>/dev/null \
  | grep -v '^./.git/' | cut -d: -f1,2 | hit "私钥/证书"

grep -rnE 'gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}' --include='*' . 2>/dev/null \
  | grep -v '^./.git/' | cut -d: -f1,2 | hit "token"

grep -rniE '(password|passwd|secret|api[_-]?key|access[_-]?token).{0,4}[:=].{0,4}[^ <>{}]+' \
  --include='*.sh' --include='*.py' --include='*.yml' --include='*.yaml' --include='*.properties' . 2>/dev/null \
  | grep -v '^./.git/' \
  | grep -viE '占位|待填|placeholder|<[a-z]+>|\$\{|用 Secrets|CI Secrets|不进.?git|Secrets? 注入|ALLOW|ALLOW=' \
  | cut -d: -f1,2 | hit "密钥赋值"

grep -rnE '\b(10\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]+\.[0-9]+\b' \
  --include='*.md' --include='*.yml' --include='*.sh' . 2>/dev/null \
  | grep -v '^./.git/' | grep -v '10\.0\.2\.2' \
  | grep -vE '示例|范文|template|待填' \
  | cut -d: -f1,2 | hit "内网地址"

grep -rnE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+(\.[a-z]{2,})+' --include='*.md' . 2>/dev/null \
  | grep -v '^./.git/' \
  | grep -vE 'semver\.org|keepachangelog\.com|github\.com|example\.com|@param|@see|@return' \
  | cut -d: -f1,2 | hit "邮箱"

grep -rnE '\b1[3-9][0-9]{9}\b|\b[0-9]{17}[0-9Xx]\b' --include='*.md' . 2>/dev/null \
  | grep -v '^./.git/' | cut -d: -f1,2 | hit "手机/身份证"

echo "---"
if [ "$FAIL" -eq 0 ]; then
  echo "扫描结果：干净（0 疑似命中）"
else
  echo "扫描结果：发现 $HITS 处疑似敏感信息"
  echo "处置：真敏感 → 脱敏后重新提交；确认误报 → 加白名单 scripts/scan-secrets.allow"
  exit 1
fi