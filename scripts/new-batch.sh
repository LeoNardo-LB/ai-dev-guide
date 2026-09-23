#!/usr/bin/env bash
# ============================================================
# new-batch.sh — 创建新的工作批次 journal 文件
# 用法：new-batch.sh "<批次名kebab>"（在目标项目根运行）
# 产物：docs/journal/YYYY-MM-DD-<批次名>.md（由 templates/journal-entry.md 实例化）
# 纪律：开工时创建；证据直接写入；完结条目从 backlog 原文迁入。
# ============================================================
set -euo pipefail
NAME="${1:-}"
[ -n "$NAME" ] || { echo '用法: new-batch.sh "<批次名kebab>"'; exit 2; }
# 宽容转写：大写→小写、空格/下划线→连字符、丢弃其余非 [a-z0-9-] 字符；转写后为空则拒绝
NAME=$(printf '%s' "$NAME" | tr 'A-Z _' 'a-z--' | tr -cd 'a-z0-9-' | sed -e 's/--*/-/g' -e 's/^-*//' -e 's/-*$//')
echo "$NAME" | grep -qE '^[a-z0-9][a-z0-9-]*$' || { echo '✗ 批次名转写后为空——请提供拉丁字母批次名（kebab-case）'; exit 2; }
# 长度上限：防 bash 原生「文件名过长」以 exit 1 混入「已存在冲突」语义（沙盒审计 D5 定规）
[ "${#NAME}" -le 100 ] || { echo "✗ 批次名过长（${#NAME} 字符 > 100）——用简短 kebab 概括批次主题"; exit 2; }

# 定位模板：优先项目内部 ai-dev-guide，其次本脚本同级
for CAND in "ai-dev-guide/templates/journal-entry.md" "$(dirname "$0")/../templates/journal-entry.md"; do
  [ -f "$CAND" ] &&TPL="$CAND" && break
done
[ -f "${TPL:-}" ] || { echo '✗ 未找到 templates/journal-entry.md'; exit 1; }

DATE=$(date +%F)
mkdir -p docs/journal
OUT="docs/journal/${DATE}-${NAME}.md"
[ -f "$OUT" ] && { echo "✗ 已存在 $OUT"; exit 1; }
sed -e "s/<批次名>/<批次：$NAME>/" -e "s/<YYYY-MM-DD>/$DATE/g" "$TPL" > "$OUT"
echo "✓ $OUT"
echo "  开工即写入；证据直接追加；完结条目从 backlog 原文迁入本文件。"