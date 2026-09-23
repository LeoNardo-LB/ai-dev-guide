# oc-beacon 演进回灌调研报告（2026-09-23）

> **问题**：本蓝本（ai-dev-guide v2.4.0）于 2026-08-24 前后从 oc-beacon 抽取泛化；源项目此后在实际 AI coding 中持续演进至 2026-09-23。本报告系统对比两边，找出蓝本缺失/落后的部分，并给出整合方案。
> **方法**：六路并行子代理分维度深读源项目治理文件（验证验收 / backlog 生命周期 / AGENTS 设计治理 / 机器门禁 / 发版回归 E2E / 编辑协议与探测），逐条落到「文件:行」级证据；主代理交叉核对蓝本侧全部对应文件。共核对源文件 40+ 份、蓝本文件 41 份。
> **判断标准**：只提炼**可泛化机制**（换 Python/Web 项目仍成立的纪律），不搬栈特异内容。

## 1. 总体结论

- 蓝本对源项目 **2026-09-09 之前**的方法论覆盖度高、同构清晰（铁律五步 / 交叉验证矩阵 / 证据链四环 / 能力域四件套 / 版本阶梯 / 登记三分离均不落后）。
- 系统性差距集中在源项目 **2026-09-03 ~ 09-23 的四次裁决演进**：仪器优先分类法、AI 验收三步法、backlog 账本脚本化、承重规则机器门禁化——蓝本抽取时这些尚未诞生或未定型。
- 六个 P0 主题（详见 第 2 节）：**人工维度分类法过时（方向性纠偏）**、**验收三步法与关闭权限缺失**、**backlog 脚本化与 P4 缺失**、**规则机器门禁方法论缺失**、**测试环境 runbook 模式缺失**、**发版护栏缺失**。

## 2. 差距总表（按主题分组）

### 2.1 验证与验收（源证据：docs/verification.md、docs/ai-acceptance-workflow.md）

| # | 差距 | 源证据 | 蓝本现状 | 整合位置 | 级 |
|---|------|--------|----------|----------|----|
| 1 | 人工维度分类法过时：源以「是否存在可观测仪器」划界，人工收窄为四类穷举（真手指体感/用户凭据/数日观察/主观拍板）；「用户可见 UI 变化 ≠ 需人工」，时间性现象可量化面走录屏+逐帧/像素取证 | ai-acceptance-workflow.md 第 1 节、verification.md V6 节 | workflows/verify.md 第 8 节 仍以「六种时间性现象=人工」为门禁——会把可仪器化项系统性推向人工 | verify.md 第 8 节 重构 + manual-ui-checklist.md + regression.md 第 3 节 同步 | P0 |
| 2 | 关闭权限分级：仪器可验 → AI 三步全绿+受端确凿证据直接关闭；人工项 → 全绿后待人工确认；混合卡仪器面+观感尾巴不重复验收 | ai-acceptance-workflow.md 第 1 节 | 无「关闭权限」概念 | 新建 workflows/acceptance.md 第 1 节 | P0 |
| 3 | AI 验收三步法：主 agent 生成 checklist（三块覆盖+item 五字段+层次递进）→ 纯净上下文 subagent 审查（五维度）→ 新纯净 subagent 执行（逐项打标、只观测不分析、BLOCKED 传播）→ 失败循环只重跑受影响项 | ai-acceptance-workflow.md 第 2 节/第 8 节 | 完全缺失（verify 第 6 节 只有主 agent 复核） | 新建 workflows/acceptance.md + templates/acceptance-checklist.md | P0 |
| 4 | 受端效果证据标准：网关/服务器 ok ≠ 成功，必须有执行/恢复/UI 状态变化的受端证据 | ai-acceptance-workflow.md 第 1 节 | evidence.md 第 4 节 只有正向「先直测判归属」 | evidence.md 第 4 节 + acceptance.md 第 3 节 | P1 |
| 5 | 执行/认知分离：执行者禁止分析归因修复，只记录观测事实 | ai-acceptance-workflow.md 第 2 节 | evidence.md 第 7.3 节 未显式 | evidence.md 第 7.3 节 | P1 |
| 6 | 人工清单治理：按域边界汇总一次性提交 + 活文档勾销 | ai-acceptance-workflow.md 第 1 节 | 静态模板 | manual-ui-checklist.md + acceptance.md 第 5 节 | P1 |
| 7 | 过程新问题入队量化例外（>10 轻微/影响面大/硬阻碍可只登记） | ai-acceptance-workflow.md 第 4 节 | 无 | requirements.md | P2 |
| 8 | 仪器伪影沉淀机制（伪影→互证→沉淀为禁令） | ai-acceptance 第 7 节 | 无载体 | evidence.md 第 1 节 盲区列 | P2 |

### 2.2 观测与取证（源证据：docs/probing.md、scripts/prerender/README.md）

| # | 差距 | 源证据 | 蓝本现状 | 整合位置 | 级 |
|---|------|--------|----------|----------|----|
| 9 | 「单一通道不做最终判定」铁律 + 各仪器已知盲区/坑清单登记制 | probing.md 三层路由节 | verify 第 3.2 节 只判证据源独立 | evidence.md 第 1 节 增盲区列 | P0 |
| 10 | 像素探针（颜色锚点基准对照+区域色彩统计；暗色主题禁亮度启发式） | probing.md 像素节 | 无 | evidence.md 第 5 节 | P0 |
| 11 | 视觉模型纪律（只做描述/仲裁提问、禁坐标、禁引导、串行） | probing.md vision 节 | 第 5 节 仅一行 | evidence.md 第 5 节 | P0 |
| 12 | 帧级/逐帧取证（录屏→抽帧→位移分析）+ 仪器纪律六条 | probing.md 帧级节、prerender/README.md | 无 | evidence.md 第 5 节 + regression.md 基线节 | P0 |
| 13 | 性能基线可复现方法（修复前基线=git 历史构建同场景） | probing.md 性能量化节 | regression 第 3.1 节 有指标无方法 | regression.md 第 3.1 节 | P1 |
| 14 | 确定性测试入口（一键入口+到达标志校验+禁手工导航三坑） | device-testing.md、debug-entry.sh | 全库无 | templates/env-runbook.md + evidence.md | P0 |
| 15 | 关键点按动态定位铁律（键盘位移/通知劫持致固定坐标必错）；dump 前删旧文件防陈旧 | e2e-acceptance-dsh.sh | evidence 第 5 节 无定位纪律 | evidence.md 第 5 节 | P1 |
| 16 | 连续日志档（设备缓冲轮转，断言基于持续写入文件） | e2e-acceptance-dsh.sh | 无 | evidence.md 第 2 节 | P1 |
| 17 | 有状态取证须完整性校验后采信 | probing.md 活库节 | 无 | evidence.md 第 3 节 | P2 |
| 18 | 测试环境 runbook 整体模式（环境矩阵/装包通道谱系/资源独占/坑清单/后端核验） | device-testing.md 全文 | 只有 e2e 实操记录模板 | 新建 templates/env-runbook.md | P0 |
| 19 | debug 后门模式（外部参数直达测试起点+debug 构建守卫） | debug-channel.md | 无 | env-runbook.md 可选节 | P1 |

### 2.3 backlog / journal / spec 生命周期（源证据：backlog.md、scripts/backlog*.sh、docs/journal/423）

| # | 差距 | 源证据 | 蓝本现状 | 整合位置 | 级 |
|---|------|--------|----------|----------|----|
| 20 | 账本操作脚本化整套（add/note/status/migrate/journal append；起因=覆写丢章+同号双卡两起事故） | scripts/backlog.sh、backlog.md 首段 | 部署面仅 new-batch.sh | 新建 scripts/backlog.sh（第 5 个运行时脚本） | P0 |
| 21 | P4 优先级=外部前提阻塞（卡内必含「前提」行） | backlog.md P4 定义 | P0-P3，外部依赖混在 P3 | requirements.md 第 3 节（CANON）+ registries + backlog-entry + check.sh 门禁 9 | P0 |
| 22 | 卡片只许在 Pn 节内（防卡片散落表头区） | backlog-check.sh 5b | 不变量表无 | backlog-entry.md 不变量 7 + 门禁 9 | P0 |
| 23 | journal 取证链格式锚点：轮次编号 / GREEN-RED 判定词 / 「用户裁决:」前缀+原话 / before-after 证据对 / 遗留（如实） | docs/journal/2026-09-22-423-*.md | 模板仅自由段落 | templates/journal-entry.md | P1 |
| 24 | 反馈归卡（note 不另开卡；独立缺陷才立新卡互引） | backlog.md 首段 | 无 | requirements.md 第 2 节 | P1 |
| 25 | 裁决记录纪律（同域多裁决以最新为准+回写旧裁决域） | backlog.md 首段 | 无 | requirements.md + journal 模板前缀 | P1 |
| 26 | migrate 防呆（未验卡迁移需显式依据/标准迁入节标题/迁入依据行） | backlog.sh migrate | requirements 第 5 节 仅纪律无格式 | requirements.md 第 5 节 + backlog.sh | P1 |
| 27 | spec 结构升级：约束行引裁决先例 / 用户故事含验证视角 / 测试决策（好测试只断言外部行为）/ 范围外 / 流程状态词 | docs/specs/2026-09-23-427-*.md | spec.md 无这些节 | templates/spec.md | P1 |
| 28 | 多路调研合成（00-synthesis 收敛表+分路编号报告；多源一致才采信） | docs/research/pre-render-coordinator/ | research-report.md 无此形态 | templates/research-report.md Part C | P1 |
| 29 | 行为基线冻结（重构前现状留档；迁移期间不改语义） | 07-baseline-freeze.md | 无 | 新建 templates/baseline-freeze.md | P1 |
| 30 | new-batch 中文 kebab 化 + journal 头「来源」行 | backlog-new-batch.sh | 直接拒绝中文名 | new-batch.sh + journal-entry.md | P2 |

### 2.4 机器门禁与工程纪律（源证据：lint-checks/、AGENTS.md、release.sh）

| # | 差距 | 源证据 | 蓝本现状 | 整合位置 | 级 |
|---|------|--------|----------|----------|----|
| 31 | 宿主承重规则→机器检查的方法论（文档规则演进为 lint/CI 门禁的路径） | lint-checks 4 个 Detector | 蓝本十门禁只治理文档自身；architecture 第 2 节 仅「验证方式」占位字段 | standards/architecture.md 第 2 节 扩展「机器执行」 | P0 |
| 32 | 窄化原则（只拦高信号无歧义子集+明列不纳入项防误报） | TokenBypassDetector KDoc | 无 | 同上 | P0 |
| 33 | 错误消息回链文档（机器报错指向治理文档——机器↔文档闭环） | TokenBypassDetector 报错文本 | 无 | 同上 | P0 |
| 34 | 门禁引入模式：存量入豁免清单只拦新增（lint baseline） | app/build.gradle.kts lint 段 | 无 | stack-profile.md 第 5 节 + architecture 第 2 节 | P0 |
| 35 | 同 checkout 禁并发构建（竞写中间目录→无辜测试报错） | AGENTS.md Build 节 | 全库零命中 | dev.md 第 5 节 + stack-profile 第 5 节 | P1 |
| 36 | commit type 机器契约（用户可见必须 feat:/fix:；无前缀被发版脚本丢弃；内部维护类不进 CHANGELOG） | AGENTS.md、release.sh | dev 第 3 节 type 平列无分级义务 | dev.md 第 3 节 + release.md 第 6 节 | P1 |
| 37 | commit 用词受术语表约束（subject 遵循 CONTEXT.md；Avoid 词拦截） | AGENTS.md Commit 纪律 | 无联动 | dev.md 第 3 节 + release-notes 术语拦截 | P1 |
| 38 | 四档超时预算（补依赖解析/首次构建档） | AGENTS.md | 三符号无档位说明 | stack-profile.md 第 5 节 注释 | P2 |

### 2.5 发版与 E2E（源证据：release-workflow.md、maestro/README.md）

| # | 差距 | 源证据 | 蓝本现状 | 整合位置 | 级 |
|---|------|--------|----------|----------|----|
| 39 | 能力分层 E2E 阶梯（L1 活下来→功能层→完整旅程；冒烟档=阶梯底部固定清单；性能流独立） | maestro/README.md | verify 第 5 节 只有两档骨架无内容形态 | verify.md 第 5 节 + test-strategy.md | P0 |
| 40 | tag 递进链校验 + 防回退护栏 + 开新线基准 | release-workflow.md 第 2.5 节/3.3 | release.md 只校验版本文件形态 | release.md 第 2.2 节 | P0 |
| 41 | 真实环境优先方针 + 后备环境适用表 | device-testing.md 环境矩阵 | 无 | test-strategy.md 新节 | P1 |
| 42 | 验收脚本化（人工验收压缩为确定性门禁；截图仅抽查不作门禁输入） | e2e-acceptance-dsh.sh | verify 第 5 节 手工口径 | verify.md 第 5 节 | P1 |
| 43 | 实验隔离 + SKIP 语义（破坏性实验只落一次性数据；前置不满足显式 SKIP） | e2e-acceptance-dsh.sh | 全库无 | acceptance.md 第 7 节 + env-runbook | P1 |
| 44 | 换密钥材料同批重设+立即验证（事故教训固化） | release-workflow.md 第 9 节 | release 第 5 节 只核对齐全 | release.md 第 5 节 | P1 |
| 45 | 能力域条目增「已知误判陷阱」登记 | regression-guide 12 域内嵌陷阱 | ability-domains 无此列 | templates/ability-domains.md | P1 |
| 46 | Release Notes 通道范围视角 + 术语拦截 | release-workflow.md 第 5 节 | 范围仅 last tag | release.md 第 6 节 | P2 |

### 2.6 AGENTS.md 治理与术语（源证据：docs/agents-file-design.md、docs/agents/）

| # | 差距 | 源证据 | 蓝本现状 | 整合位置 | 级 |
|---|------|--------|----------|----------|----|
| 47 | 部署面 AGENTS.md 长期维护卡（准入决策+级别复审在 source 面，部署面不可达） | agents-file-design 全文 | 部署面只有 edit-card 五律 | edit-card.md 增「AGENTS.md 准入速记」节 | P0 |
| 48 | 术语表豁免边界（Avoid 仅指名称性使用；标识符/证据引用/历史产物豁免） | CONTEXT.md 总则 | context.md 零豁免概念 | templates/context.md | P1 |
| 49 | agent 消费术语/ADR 行为约定（不存在静默继续勿预建；冲突显式提出） | docs/agents/domain.md | 无 | templates/context.md | P1 |
| 50 | 行数预算证据注记（<60 尖锐/<150 舒适/200 上限/>400 失效） | agents-file-design 第 2 节/第 3 节 | manifest 裸数字 | meta/doc-governance.md 第 4 节 注记 | P2 |
| 51 | 外部 issue tracker 双轨模式（分工+同步三规则） | docs/agents/issue-tracker.md | 单轨 | requirements.md 可选节（后续） | P2 |
| 52 | 编号治理四则（引入编号须配映射表+标识符豁免+grep 零残留） | numbering-charter.md | 蓝本命名维度已规避编号，暂无编号体系 | meta/doc-governance.md 注记（后续） | P2 |
| 53 | 文档合并 tombstone 模式（旧路径留 3 行占位防断链） | #382 四个 tombstone 文件 | 蓝本用 manifest replaces+删文件+门禁 1 修链（等价且更严） | 不搬运（见 第 3 节） | — |

## 3. 明确不搬运清单（栈特异 / 与蓝本哲学冲突）

| 内容 | 理由 |
|------|------|
| V1-V6 / R0-R4 / A1-A13 编号体系本体 | 蓝本用命名维度（构建/测试/运行时/遥测/人工）已规避编号治理负担；搬编号反而引入映射成本（子代理 A/D 一致结论） |
| 4 条 lint 规则具体实现、ServerType 白名单路径、lint-baseline.xml 本体 | Android Lint API 栈特异；搬「规则设计纪律」（窄化/豁免/回链）不搬实现 |
| adb/Maestro/uiautomator/screenrecord/MIUI 具体命令与坑 | 栈命令归 stack-profile 由各栈填写（蓝本哲学：命令符号化） |
| 签名矩阵/keystore 编年史、Google Play 上架、flavor 差异 | Android 发布机制；蓝本 release.md 已有等价抽象 |
| 12 能力域清单本体、L1-L4 具体层名 | 项目特异切分；蓝本「从用户旅程切 8-12 域」已泛化，层名作示例 |
| terminology 全套取证工程（990 文件盘点/五轮裁决日志） | 一次性大决战过程产物；轻量三层结构即可 |
| V1/V2 双后端差异、SSE 滚动铁律、ChatScreen 具体协议内容 | 项目特异；其泛化形态（编辑协议/回归铁律文档模式）蓝本已有 |
| tombstone 合并模式 | 蓝本 manifest replaces + 退役流程 + 门禁 1 断链拦截是更强等价物 |
| 「每术语必有中文对应名」 | i18n 应用特有；泛化为「唯一规范名」 |

## 4. 本次整合落地（v2.5.0）

**新增 5 份**：workflows/acceptance.md（三步法+关闭权限+资源独占+SKIP）、templates/acceptance-checklist.md、templates/env-runbook.md、templates/baseline-freeze.md、scripts/backlog.sh（账本脚本，第 5 个运行时脚本）。
**重构 1 处**：verify.md 第 8 节 人工维度改为「仪器优先 + 四类人工例外」（同步 manual-ui-checklist / regression 第 3 节）。
**增补 15 份**：evidence / architecture（机器执行节+具名反例）/ dev / requirements（P4+反馈归卡+裁决+入队例外）/ release（护栏）/ regression / test-strategy / stack-profile / edit-card（准入速记）/ backlog-entry / registries-backlog / journal-entry / spec / research-report（Part C）/ context / ability-domains / manual-ui-checklist / AGENTS.md.template / system-design。
**机械升级**：check.sh 门禁 9 扩为 P0-P4 节序 + 卡片只许在 Pn 节内；init.sh 部署 backlog.sh；manifest +4 条目、版本 2.5.0。

**后续路线（P2，本次未做）**：外部 tracker 双轨节、编号治理四则注记、tombstone 评估、事件生命周期模板、宿主 CI 挂点指引、debug 后门独立成节。

## 5. 调研方法与佐证

- 六路子代理报告全文见本批次 journal：docs/journal/2026-09-23-oc-beacon-reintegration.md。
- 源侧关键文件：AGENTS.md、CONTEXT.md、backlog.md、docs/{verification,ai-acceptance-workflow,agents-file-design,probing,device-testing,release-workflow,regression-guide,numbering-charter,chatscreen-editing-protocol,debug-channel}.md、docs/agents/{domain,issue-tracker,skills,triage-labels}.md、lint-checks/src/main/kotlin/dev/leonardo/ocbeacon/lintrules/*.kt、scripts/{backlog.sh,backlog-check.sh,backlog-new-batch.sh,debug-entry.sh,e2e-acceptance-dsh.sh}.sh、maestro/README.md、docs/journal/2026-09-22-423-prerendercoordinator.md、docs/research/pre-render-coordinator/、docs/specs/2026-09-23-427-step-group-slicing-windowing.md。
- 蓝本侧全部 41 份文档与 11 个脚本已逐一核对。
