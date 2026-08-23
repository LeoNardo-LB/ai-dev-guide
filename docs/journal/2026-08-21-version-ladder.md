# 2026-08-21 版本相位阶梯批次
> 状态：已完结
> 关联：workflows/release.md §2 · scripts/release-version.sh · CHANGELOG [2.1.0]

## 目标

把用户规定的版本号顺序（开发版 dev.n → 测试版 beta → 正式版，必经路径、不可跳级）落成机器强制的脚本与文档规则。

## 过程与证据

1. scripts/release-version.sh：相位状态机（init/current/next/dev/beta/stable/validate + --dry-run）；版本文件 KEY=VALUE（VERSION_NAME/VERSION_CODE/DEV_CYCLE，DEV_CYCLE 记录 beta 退回修复时的续增序号）
2. 全阶梯演练（/tmp）：init 1.0.1 → next --bump patch → 1.0.2-dev.1 → dev.2 → beta → 退回 dev.3（n 续增）→ beta → stable 1.0.2；VERSION_CODE 1→7 每步 +1 ✓
3. 非法转移全部被拒：stable→beta、stable→stable、next 缺 --bump ✓；stable→next --bump minor（合法）dry-run 产出 1.1.0-dev.1 ✓
4. 文档同步：release.md §2 重写（格式/阶梯表/示例/脚本强制）；release-runbook 步骤 1 改走脚本；release-notes 模板预发布措辞对齐（beta.2 旧表述清除）；AGENTS.md.template 增版本阶梯红线一行
5. init.sh 增 1b 步：部署时复制运维脚本到目标项目（脚本此前只在源仓，new-batch/release-version 在部署侧不可用的潜在缺陷一并修复）
6. 自举：manifest 2.0.0 → 2.1.0；CHANGELOG 增 [2.1.0] 条目

## 完结迁移区

（本批次为系统自身规则增强，无 backlog 卡片）

## 蒸馏

- 版本相位是不可协商的机器规则：口头规定会漂移，脚本拒绝才是门禁——与「每条机械规则配门禁」同构