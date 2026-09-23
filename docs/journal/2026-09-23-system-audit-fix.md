# 2026-09-23 system-audit-fix

> 状态：已完结
> 来源：用户裁决（对规范体系做自洽/优雅/脚本化/易用/AI 友好/闭环/配合的全维度系统性审计；随后确认执行修复）
> 关联：backlog 无卡（审计直接驱动）；审计报告 [2026-09-23-system-audit.md](../research/2026-09-23-system-audit.md) + [2026-09-23-state-machine-audit.md](../research/2026-09-23-state-machine-audit.md)

## 目标

多维度系统性审计 v2.5.0（8 路子代理分维 + 主代理复核 + 5 篇 arXiv 论文 / 6 权威源对照），修复全部 P0×9 与 P1 主体，落为 v2.6.0。

## 过程与证据

- GREEN：主代理独立复现全部 P0——backlog.sh 沙盒实测：三卡同日迁移只活一张（其余从 backlog 与 journal 双双消失且留虚假「用户验收通过」依据行）、未验卡无 -r 放行、并发 add 一卡蒸发；verify.md:1 标题粘表与五维表 4 行缺行首管道（od 字节级确认）。
- GREEN：修复后沙盒回归——同日双卡正文俱在、未验卡被拒（exit≠0）、[~] 依据诚实化（不再默认写「用户验收通过」）、8 并发 add 全存活（独立锁文件 + 原子替换，规避 flock+rename 的 inode ABA 竞态）、prio 跨节迁移留痕、journal append 拒写账本本体（执行于 2026-09-23）。
- GREEN：源仓十门禁全绿——新增结构门禁首跑即抓获 verify.md 损坏与 CHANGELOG [2.4.0] 重复标题两处实锤，随后修复转绿；完整 selftest 通过（R1-R12，R12 四断言为本次新增：未验拒/同日双卡/影子 [X] 拦截/5 位编号防撞）；gen-index 幂等（执行于 2026-09-23，bash scripts/check.sh / bash scripts/selftest.sh）。
- 用户裁决：关闭权限矛盾按 v2.5.0 意图裁定——仪器可验项 AI 取证后直接关闭；CANON:status-flow 已按 acceptance 第 1 节改写。
- 勘误：2026-09-23-oc-beacon-reintegration.md 的「migrate 未验卡正确拒绝」GREEN 声明失真，已 append 勘误（当时守卫为死代码，演练未命中真实拒绝路径）。

## 完结卡片迁入（2026-09-23）

- 迁入依据：审计批次直接驱动修复，无独立卡片

## 遗留（如实）

- P2 未落项（清单见审计报告第 10.2 节批次④）：release validate --tags 机器化（已如实标注为人工核对项）；批次关闭自动化；spec 归档子命令；monorepo 嵌套 AGENTS.md 适配；B 系小门禁（单卡 tag≤3 / 债务状态词表）；upgrade 三方 diff 生成；prompt cache 稳定性注记；手段编码与命名维度深度统一。
