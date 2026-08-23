# 2026-08-21 CI 自检批次
> 状态：已完结
> 关联：scripts/selftest.sh · .github/workflows/check.yml · CHANGELOG [2.2.0]

## 目标

把十项门禁从「自觉运行」升级为「CI 强制」：本地与 CI 跑同一条命令（DSH pre-push-checks 教义）。

## 过程与证据

1. scripts/selftest.sh：四段自检（语法 ast.parse/bash -n → 源仓十门禁 → 部署演练 → 版本阶梯演练含非法转移拒绝断言）；--quick 跳演练
2. 本地全绿实证：10 个脚本语法 ✓、十门禁 ✓、init 部署 + 部署门禁 1/9/10 ✓、阶梯 1.0.1→1.0.2 全相位 + stable 态三非法转移全拒 ✓
3. .github/workflows/check.yml：ubuntu-latest（自带 bash+python3，零额外依赖）、timeout 10 分钟、push(master/main)+PR+手动三触发
4. 首轮自检抓出并清理 selftest 自身一段死代码块——自检检查自检的即时代价
5. 文档同步：system-design §4 增执行方式说明；README 维护入口增自检行；manifest 2.1.0 → 2.2.0

## 完结迁移区

（系统自身基建，无 backlog 卡片）

## 蒸馏

- 门禁的最后一公里是「保证它被运行」：CI 用与本地完全相同的命令，本地绿 = CI 绿，没有第二套真相

## 遗留

源仓尚无 git 仓库：git init + 首个 commit + 推送 GitHub 后工作流即自动生效（本批次产物已就位）。