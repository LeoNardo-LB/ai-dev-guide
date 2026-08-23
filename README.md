# ai-dev-guide

> 一套可**整体部署**到任意新项目的渐进式披露 AI 开发文档系统：以项目根 AGENTS.md 为唯一入口，把「AI 开发一个应用」所需的规范、流程、方法论、模板组织成按需加载的文档树。

## 快速开始

```
./scripts/init.sh <目标项目根> [--dir 系统目录名] [--no-ui] [--no-example]
```

脚本完成：按裁剪组复制部署平面 → 生成 AGENTS.md（索引实例化）→ 实例化 backlog/CONTEXT/登记目录 → 跑部署门禁 → 报告待补占位符。人工只剩：补栈事实、写首批术语、登记承重红线。

## 设计原则

| # | 原则 | 落地机制 |
|---|------|----------|
| 1 | 指针不是百科 | AGENTS.md 只放索引与红线；知识本体按 Use when 触发加载 |
| 2 | manifest 单源 | 索引/目录树/裁剪表全部由 scripts/gen-index.py 生成，手工副本为零 |
| 3 | 每条机械规则配门禁 | scripts/check.sh 十项门禁（链接/预算/占位符/MUST/幂等/引用/归宿/词汇/登记簿/命名） |
| 4 | 栈无关 | 语言差异隔离在 stack/；命令符号（BUILD/TEST/RUN）唯一定义于栈档案 |
| 5 | 登记三分离 | backlog 未决索引（完结即迁移）/ journal 批次证据（append-only）/ spec 设计决策（active→archive） |
| 6 | 自举 | 系统用自己的模板管理自己（CHANGELOG/ADR/journal） |

## 双平面模型

| 平面 | 内容 | 去向 |
|------|------|------|
| deployed | standards + workflows + bootstrap + stack + templates + registries + meta/edit-card | 复制进目标项目 |
| source | meta 三份治理文档 + scripts + manifest + specs + docs | 仅源仓 |

## 文档总览（manifest 生成）

<!-- GEN:readme-tree:start -->
| 平面 | 路径 | 级别 | 用途 |
|------|------|------|------|
| deployed | `bootstrap/onboarding.md` | 🟢 | 新项目接入说明（init.sh 的人话版） |
| deployed | `meta/edit-card.md` | 🔴 | 文档与 AGENTS 规则编辑卡（核心五律 + 指回源仓） |
| deployed | `registries/ability-domains.md` | 🟡 | 能力域清单实例骨架（init 复制到 docs/ability-domains.md） |
| deployed | `registries/architecture-debt.md` | 🟡 | 架构债务登记簿实例骨架（init 复制到 docs/architecture-debt.md） |
| deployed | `registries/backlog.md` | 🟡 | 待办登记簿实例骨架（未决索引+完结即迁移；init 复制到项目根 backlog.md） |
| deployed | `stack/android-kotlin-example.md` | 🟢 | 已填充栈档案范例（Kotlin/Android） |
| deployed | `stack/stack-profile.md` | 🟡 | 栈档案：构建命令/版本真相源/平台约束唯一真相源 |
| deployed | `standards/architecture.md` | 🔴 | 架构规范：分层、承重规则、深度模块、不过度设计 |
| deployed | `standards/code-style.md` | 🟡 | 代码风格、注释覆盖矩阵、AI 友好编码 |
| deployed | `standards/reliability.md` | 🟡 | 可靠性：错误处理/并发/资源/日志/幂等 |
| deployed | `standards/test-strategy.md` | 🟡 | 测试策略、各层覆盖、Mock 纪律 |
| deployed | `standards/ui-conventions.md` | 🟡 | UI 统一性：框架忠诚/设计令牌/状态展示/本地化 |
| deployed | `templates/ability-domains.md` | 🟡 | 能力域清单骨架（四件套 + 维护规则） |
| deployed | `templates/adr.md` | 🟢 | 架构决策记录骨架 |
| deployed | `templates/backlog-entry.md` | 🟡 | 待办卡片格式（≤3 行索引卡 + 机械不变量） |
| deployed | `templates/bug-record.md` | 🟡 | Bug 修复记录（三层分类 + 判定三问结论） |
| deployed | `templates/changelog.md` | 🟢 | CHANGELOG 骨架（Keep a Changelog） |
| deployed | `templates/context.md` | 🟡 | 项目领域术语表骨架（CONTEXT.md，定义+Avoid） |
| deployed | `templates/debt-entry.md` | 🟡 | 债务条目格式（状态词表唯一归宿） |
| deployed | `templates/e2e-plan.md` | 🟡 | E2E 期望文档（测什么/期望什么） |
| deployed | `templates/e2e-runbook.md` | 🟡 | E2E 实操记录（逐轮追加/差异归属） |
| deployed | `templates/journal-entry.md` | 🟡 | 批次日志骨架（开工时创建；证据 append-only 归宿） |
| deployed | `templates/manual-ui-checklist.md` | 🟡 | 人工验证清单（时间性现象） |
| deployed | `templates/plan.md` | 🟡 | 实施计划骨架（Task/Steps/精确签名/TDD） |
| deployed | `templates/release-notes.md` | 🟡 | 发版说明骨架（面向用户公告） |
| deployed | `templates/release-runbook.md` | 🟢 | 手动发版步骤（发版脚本不可用时逐项执行） |
| deployed | `templates/requirement.md` | 🟡 | 需求澄清卡（验收标准先行） |
| deployed | `templates/research-report.md` | 🟡 | 调查报告 A / 回归报告 B |
| deployed | `templates/spec.md` | 🟡 | 设计文档骨架（事实/推论分离防幻觉；active→archive 生命周期） |
| deployed | `templates/verification-node.md` | 🟢 | 验证节点（环境/步骤/断言/证据可复现清单） |
| deployed | `workflows/bug.md` | 🔴 | Bug 分析：根治优先、补丁协议、反模式、模式审计 |
| deployed | `workflows/debt.md` | 🟡 | 技术债务登记纪律、偿还流程、grep 检查 |
| deployed | `workflows/dev.md` | 🔴 | 开发循环六步、编辑协议、提交规范、并行纪律 |
| deployed | `workflows/evidence.md` | 🟡 | 观测与取证：日志/数据直查/网络/UI dump/证据链 |
| deployed | `workflows/regression.md` | 🟡 | 回归验证：变更分类、性能基线、能力域、定性三问 |
| deployed | `workflows/release.md` | 🔴 | 发版权威：版本/构建/签名/CHANGELOG/回滚 |
| deployed | `workflows/requirements.md` | 🟡 | 需求全生命周期（优先级与状态机唯一归宿） |
| deployed | `workflows/verify.md` | 🔴 | 完成验证：五维证据、交叉验证、人工门禁 |
| source | `meta/doc-governance.md` | 🟡 | 文档治理：类型/存放决策/生命周期/门禁映射 |
| source | `meta/doc-writing-standards.md` | 🔴 | 面向 Agent 的写作规范（指针/分层/十律/泄漏分类） |
| source | `meta/system-design.md` | 🟢 | 本系统设计规范、术语表与生成索引总表 |
<!-- GEN:readme-tree:end -->

## 维护入口

| 想做什么 | 用什么 |
|----------|--------|
| 新增/修改文档 | 改 manifest.yaml → 跑 scripts/gen-index.py → 按规范撰写 → scripts/check.sh |
| 部署到新项目 | scripts/init.sh |
| 管理版本相位（dev.n → beta → 正式版） | scripts/release-version.sh |
| 推送前自检（CI 同命令） | scripts/selftest.sh |
| 升级已部署项目 | scripts/upgrade.sh（漂移报告） |
| 登记开发批次 | scripts/new-batch.sh |
| 理解系统设计 | meta/system-design.md（含术语表） |

## 版本历史

见 [CHANGELOG.md](CHANGELOG.md)（用本系统自己的 changelog 模板维护）。

## 许可

待定。