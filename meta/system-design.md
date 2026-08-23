# 系统设计（System Design）

> 本系统的设计规范、双平面模型、术语表与交叉引用总表（由 manifest 生成）。
> 维护本系统、向目标项目部署、或协作撰写任一文档前，先读本文件。

## Use when

- 理解/修改本系统结构时
- 决定新文档放哪个平面、什么级别、哪个裁剪组时
- 查询全系统术语定义时（§6）

## 1. 设计目标

- 一套可**整体部署**到任意新项目、由项目根 AGENTS.md 作为唯一入口的渐进式披露文档系统
- **栈无关**：语言/框架差异全部隔离在 stack/，其余文档只描述方法论与纪律
- **manifest 单源**：全部索引、目录树、裁剪表由 scripts/gen-index.py 从 manifest.yaml 生成，手工副本为零
- **机器门禁**：每条机械规则配 scripts/check.sh 的一个门禁（§4）
- 每份文档自包含回答三件事：何时读（Use when）、读什么、读完怎么做

## 2. 双平面部署模型

| 平面 | 内容 | 去向 |
|------|------|------|
| deployed | 内容文档（standards/workflows/bootstrap）+ 栈档案 + 模板 + 登记簿骨架 + 编辑卡 | 复制进目标项目 |
| source | meta/ 治理三份（本文件/governance/writing-standards）+ scripts + manifest + specs + docs | 只留源仓 |

目标项目里修改文档的纪律由部署面的 [edit-card.md](./edit-card.md)（编辑卡）承载；完整治理规范按需从源仓复制。

## 3. 三层渐进披露

| 层 | 载体 | 加载方式 | 内容约束 |
|----|------|----------|----------|
| L0 入口层 | 项目根 AGENTS.md | 每个会话自动加载 | ≤200 行：简介、命令指针、红线摘要、索引表 |
| L1 分类层 | 各内容文档 | 按索引表 Use when 触发阅读 | 每文档 ≤250 行（例外在 manifest 申报）：规则 + 流程，表格优先 |
| L2 登记层 | backlog / journal / specs / research | 通常不主动读 | 未决索引、批次证据、设计决策、蒸馏结论 |

铁律：L0 只放「不内联就会出错」的内容；知识本体全部外链 L1。

## 4. 门禁映射（机械规则 ↔ check.sh）

| 门禁 | 规则 | 违反症状 |
|------|------|----------|
| 1 | 链接全部可解析（源仓模式允许 AGENTS 模板的 {{SYS}} 前缀；部署模式禁止残留） | 断链、未替换前缀 |
| 2 | 行数预算（manifest.budget，例外须申报） | 注意力稀释 |
| 3 | 内容文档零占位符（模板/栈/登记簿豁免） | 部署后残留他人项目细节 |
| 4 | MUST ≤ must_limit | 「都重要 = 都不重要」 |
| 5 | GEN 段幂等（gen-index.py --check） | 索引与 manifest 漂移 |
| 6 | §引用可解析（目标须有对应编号标题） | 死引用 |
| 7 | CANON 唯一归宿（优先级/状态机/补丁三件事各只存在一份） | 重复表分叉 |
| 8 | 术语已定义 + 退役词汇禁用（旧编号/旧仓库名） | 魔法词、词汇分叉 |
| 9 | backlog 不变量（部署模式：零完结残留/计数器/悬空链接/节序） | 登记簿膨胀失控 |
| 10 | journal/specs 命名规约（部署模式） | 批次文件不可排序 |

执行方式：本地推送前与 CI（.github/workflows/check.yml）跑同一条命令 scripts/selftest.sh——语法 + 十门禁 + 部署演练 + 版本阶梯演练一体；本地通过 = CI 通过，杜绝「本地绿 CI 红」的分叉。

## 5. 交叉引用总表（manifest 生成，勿手编）

<!-- GEN:full-table:start -->
| id | 路径 | 类 | 平面 | 级别 | 裁剪组 | 用途 | Use when |
|----|------|----|------|------|--------|------|----------|
| onboarding | bootstrap/onboarding.md | content | deployed | MAY | core | 新项目接入说明（init.sh 的人话版） | 新项目初始化时 |
| edit-card | meta/edit-card.md | content | deployed | MUST | core | 文档与 AGENTS 规则编辑卡（核心五律 + 指回源仓） | 修改任何文档或 AGENTS.md 规则前 |
| r-ability-domains | registries/ability-domains.md | registry | deployed | SHOULD | registry | 能力域清单实例骨架（init 复制到 docs/ability-domains.md） | 初始化能力域清单时 |
| r-architecture-debt | registries/architecture-debt.md | registry | deployed | SHOULD | registry | 架构债务登记簿实例骨架（init 复制到 docs/architecture-debt.md） | 初始化债务登记簿时 |
| r-backlog | registries/backlog.md | registry | deployed | SHOULD | registry | 待办登记簿实例骨架（未决索引+完结即迁移；init 复制到项目根 backlog.md） | 初始化待办登记簿时 |
| stack-example | stack/android-kotlin-example.md | content | deployed | MAY | stack-example | 已填充栈档案范例（Kotlin/Android） | 参考栈档案填法时 |
| stack-profile | stack/stack-profile.md | content | deployed | SHOULD | core | 栈档案：构建命令/版本真相源/平台约束唯一真相源 | 不确定构建命令、依赖版本、目录约定时 |
| architecture | standards/architecture.md | content | deployed | MUST | core | 架构规范：分层、承重规则、深度模块、不过度设计 | 跨层改动、设计/修改模块接口前 |
| code-style | standards/code-style.md | content | deployed | SHOULD | core | 代码风格、注释覆盖矩阵、AI 友好编码 | 编写新代码、评审风格前 |
| reliability | standards/reliability.md | content | deployed | SHOULD | core | 可靠性：错误处理/并发/资源/日志/幂等 | 涉及错误处理、并发、日志、边界时 |
| test-strategy | standards/test-strategy.md | content | deployed | SHOULD | core | 测试策略、各层覆盖、Mock 纪律 | 编写测试、决定层级与范围时 |
| ui-conventions | standards/ui-conventions.md | content | deployed | SHOULD | ui | UI 统一性：框架忠诚/设计令牌/状态展示/本地化 | 编写/修改 UI 前 |
| t-ability-domains | templates/ability-domains.md | template | deployed | SHOULD | core | 能力域清单骨架（四件套 + 维护规则） | 建立/维护能力域清单时 |
| t-adr | templates/adr.md | template | deployed | MAY | core | 架构决策记录骨架 | 记录架构决策时 |
| t-backlog-entry | templates/backlog-entry.md | template | deployed | SHOULD | core | 待办卡片格式（≤3 行索引卡 + 机械不变量） | 登记待办前 |
| t-bug-record | templates/bug-record.md | template | deployed | SHOULD | core | Bug 修复记录（三层分类 + 判定三问结论） | 修复完成随 commit 附记录时 |
| t-changelog | templates/changelog.md | template | deployed | MAY | core | CHANGELOG 骨架（Keep a Changelog） | 更新 CHANGELOG 时 |
| t-context | templates/context.md | template | deployed | SHOULD | core | 项目领域术语表骨架（CONTEXT.md，定义+Avoid） | 初始化项目术语表、统一领域用语时 |
| t-debt-entry | templates/debt-entry.md | template | deployed | SHOULD | core | 债务条目格式（状态词表唯一归宿） | 登记债务时 |
| t-e2e-plan | templates/e2e-plan.md | template | deployed | SHOULD | core | E2E 期望文档（测什么/期望什么） | 大型 E2E 测试设计时 |
| t-e2e-runbook | templates/e2e-runbook.md | template | deployed | SHOULD | core | E2E 实操记录（逐轮追加/差异归属） | 执行 E2E 测试时 |
| t-journal-entry | templates/journal-entry.md | template | deployed | SHOULD | core | 批次日志骨架（开工时创建；证据 append-only 归宿） | 开启新工作批次时 |
| t-ui-checklist | templates/manual-ui-checklist.md | template | deployed | SHOULD | ui | 人工验证清单（时间性现象） | UI 涉及动画/闪烁/计时类现象时 |
| t-plan | templates/plan.md | template | deployed | SHOULD | core | 实施计划骨架（Task/Steps/精确签名/TDD） | 大改动实施前 |
| t-release-notes | templates/release-notes.md | template | deployed | SHOULD | core | 发版说明骨架（面向用户公告） | 撰写发版说明时 |
| t-release-runbook | templates/release-runbook.md | template | deployed | MAY | core | 手动发版步骤（发版脚本不可用时逐项执行） | 手动发版时 |
| t-requirement | templates/requirement.md | template | deployed | SHOULD | core | 需求澄清卡（验收标准先行） | 澄清需求、展开规格时 |
| t-research-report | templates/research-report.md | template | deployed | SHOULD | core | 调查报告 A / 回归报告 B | bug 深挖、回归走查输出时 |
| t-spec | templates/spec.md | template | deployed | SHOULD | core | 设计文档骨架（事实/推论分离防幻觉；active→archive 生命周期） | 大改动设计前 |
| t-verify-node | templates/verification-node.md | template | deployed | MAY | core | 验证节点（环境/步骤/断言/证据可复现清单） | 组织多步验证证据时 |
| bug | workflows/bug.md | content | deployed | MUST | core | Bug 分析：根治优先、补丁协议、反模式、模式审计 | 诊断或修复任何 bug 前 |
| debt | workflows/debt.md | content | deployed | SHOULD | core | 技术债务登记纪律、偿还流程、grep 检查 | 登记/偿还技术债时 |
| dev | workflows/dev.md | content | deployed | MUST | core | 开发循环六步、编辑协议、提交规范、并行纪律 | 任何代码编辑任务开始前 |
| evidence | workflows/evidence.md | content | deployed | SHOULD | core | 观测与取证：日志/数据直查/网络/UI dump/证据链 | 调试、取证、验证运行时行为前 |
| regression | workflows/regression.md | content | deployed | SHOULD | core | 回归验证：变更分类、性能基线、能力域、定性三问 | 涉及已有能力的变更后 |
| release | workflows/release.md | content | deployed | MUST | core | 发版权威：版本/构建/签名/CHANGELOG/回滚 | 任何发版、版本号、tag、Release 操作前 |
| requirements | workflows/requirements.md | content | deployed | SHOULD | core | 需求全生命周期（优先级与状态机唯一归宿） | 接收新需求、澄清拆解、验收前 |
| verify | workflows/verify.md | content | deployed | MUST | core | 完成验证：五维证据、交叉验证、人工门禁 | 声称任何任务完成前 |
| doc-governance | meta/doc-governance.md | content | source | SHOULD | core | 文档治理：类型/存放决策/生命周期/门禁映射 | 维护、审查、重组本系统时 |
| doc-writing-standards | meta/doc-writing-standards.md | content | source | MUST | core | 面向 Agent 的写作规范（指针/分层/十律/泄漏分类） | 修改本系统任何文档前（源仓） |
| system-design | meta/system-design.md | content | source | MAY | core | 本系统设计规范、术语表与生成索引总表 | 理解/修改本系统结构时 |
<!-- GEN:full-table:end -->

## 6. 术语表（全系统统一定义）

| 术语 | 定义 |
|------|------|
| 铁律 | 违反即产生虚假完成声明或回归的不可妥协规则；全系统当前两条：完成声明需新鲜证据、根治优先 |
| 红线 | 发版/编辑等高风险操作前必须逐条核对的禁止项清单；违反后果写在红线表内 |
| 门禁 | scripts/check.sh 中的机器校验项；每条机械规则必须有对应门禁，纸面规则无效 |
| 承重规则 | 违反会引入回归的架构规则（不是风格偏好）；必须登记并可内联 AGENTS.md |
| 单一真相源 | 每个含义只在一处定义（manifest 是元数据真相源、stack-profile 是命令真相源、版本文件是版本真相源）；他处引用不复制 |
| CANON 标记 | 唯一归宿表指纹注释；同名 CANON 全系统只允许出现一次（门禁 7） |
| 渐进披露 | 知识按需加载：L0 只放索引与红线，本体在 L1 按指针触发 |
| Use when | 索引表触发场景列；首词必须是触发动词（声称完成前/发版前/编辑 X 前） |
| 未决索引 | backlog 的定位：只含未完结卡片，完结即迁移（门禁 9 强制），不是档案 |
| 批次 | 一个工作单元（一次登记/修复/调查）的 journal 粒度；开工时创建，证据 append-only 写入 |
| 降级 | 环境受限时显式标注缺失维度的部分验证；禁止静默降级 |
| 平面 | 文档的部署属性：deployed（随项目复制）/ source（仅源仓维护） |

## 7. 文档生命周期

| 阶段 | 动作 | 验收 |
|------|------|------|
| 新建 | manifest 加条目（含 id/plane/level/trim_group）→ 跑 gen-index.py → 按写作规范撰写 | 索引表已生成行；门禁 5 过 |
| 修订 | 改文档同 commit；若动 manifest 字段则重跑 gen-index.py | 门禁全绿 |
| 新增即替代审计 | 新增登记类内容（ADR/债务/术语）时，扫描既有同类记录，判定全量替代（合并+修复入链+删除旧条）/部分替代（交叉链接）/独立新增 | 旧记录不残留已失效内容 |
| 退役 | manifest 删条目 → 删文件 → 重跑 gen-index.py → 修复入链 | 门禁 1/5 过 |

## 8. 版本与自举

- 版本号记录于 manifest.yaml system.version 与 CHANGELOG.md（用自家 [changelog.md](../templates/changelog.md) 模板维护）
- 本系统的设计决策记录于 docs/adr/（用自家 [adr.md](../templates/adr.md) 模板）
- 重构与开发批次记录于 docs/journal/（用自家 [journal-entry.md](../templates/journal-entry.md) 模板）——系统用自己的模板管理自己

## Related

- 文档治理（类型/存放/生命周期细则）：[doc-governance.md](./doc-governance.md)
- 写作规范（指针/分层/十律/泄漏分类）：[doc-writing-standards.md](./doc-writing-standards.md)
- 部署面编辑卡：[edit-card.md](./edit-card.md)
- 接入说明：[../bootstrap/onboarding.md](../bootstrap/onboarding.md)