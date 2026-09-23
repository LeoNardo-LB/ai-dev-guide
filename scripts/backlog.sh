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
    python3 "$HERE/_backlog_core.py" "$BL" "$cmd" "$@"
    run_gate || exit 1
    ;;
  journal)
    sub="${1:-}"
    [ -n "$sub" ] || { echo '用法: backlog.sh journal new <批次名> | journal append <file> "<文本>"'; exit 2; }
    shift || true
    case "$sub" in
      new)
        NBJ="${1:-}"
        [ -n "$NBJ" ] || { echo '用法: backlog.sh journal new <批次名kebab>'; exit 2; }
        NB="$HERE/new-batch.sh"
        [ -f "$NB" ] || NB="ai-dev-guide/scripts/new-batch.sh"
        exec bash "$NB" "$NBJ"
        ;;
      append)
        F="${1:-}"; T="${2:-}"
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
