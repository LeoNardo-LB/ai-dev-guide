# Changelog

本项目遵循 [语义化版本](https://semver.org/) 与 [Keep a Changelog](https://keepachangelog.com/)。

## [2.7.0] - 2026-09-23

### Added

- **升级模块**：upgrade.sh 从「只报告」升级为分级执行——全量重覆盖永远不做。按「本地 vs 基线 vs 上游」三方状态自动分级：`apply` 只同步可证明安全项（本地==基线且上游已变 + 上游新增且非当初裁剪组），绝不触碰本地化修改与根级实例；`merge` 为双方修改文件落 `.upgrade-merge/` 三方工件（base 取上游 v<部署版本> git tag，有 git 另出 merged 合并稿）；`baseline` 在部署门禁通过后把当前形态登记为新基准。默认无子命令 = 原 report 行为，完全向后兼容
- **部署档案（baseline v2）**：init.sh 基线新增 profile 头（sysname / no_ui / no_ex / version）——升级模块据此区分「上游新增 vs 当初裁剪」并定位三方合并基线；旧版基线无档案自动退化兼容
- **已合并保留分级**：baseline 刷新时给「与上游不一致」的文件打 #merged 保护标记——人工合并稿含未入上游的本地内容，apply 永不覆盖（E2E 发现的覆盖事故缺口）
- 三方分级新增两类语义：「本地领先（上游未动）」不再误报待合并；「已合并保留」明确 apply 豁免
- bootstrap/onboarding.md 第 4 节重写为四级升级流程（report → apply → merge → baseline）+ 分级表；README 维护入口同步
- selftest R15（a-e）：默认子命令 / apply 分级执行与本地内容零丢失 / merge 工件 / baseline 门禁红拒绝刷新 / 子命令防呆
- **跨版本真实矩阵验证**（git worktree 检出真 v2.6.2/v2.6.3 tag 部署 → 升级到本版，11/11 全绿）：运行时脚本纳入升级分类（check/_gates/backlog/scan-secrets 等 8 件，与 init 复制清单同步）；AGENTS 入口重建（未被本地修改→直接生效，改过→AGENTS.md.new 人工合并）；旧基线裁剪事实从部署现状推断保留；apply 清洗扩为全系统目录幂等重洗（旧版 §N 残留等变换债一并修复）；AGENTS 生成器抽为 _gen_agents.py（init 与 upgrade 共用）

### Fixed

- apply 基线刷新从全量重写改为**增量**——全量重写会把本地化修改洗进基线，令其被下一次 apply 覆盖（E2E 定规）

## [2.6.3] - 2026-09-23

全脚本沙盒穷举审计（主测矩阵 + 三路子代理外围矩阵），修复 23 处缺陷并新增 R13/R14 十四条回归断言。

### Fixed

- **check.sh（P1）**：--only/--skip 垃圾值（abc/xyz）、越界值（11）、全跳空跑曾静默「零门禁运行 + 结果：通过 exit 0」——打错字即绕过全部门禁；现参数校验 exit 2 + 空跑拒绝
- **init.sh**：--no-ui --no-example 组合部署后部署门禁 6 必挂（AGENTS 手写行引用已裁剪文档 + scrub 洗链接不洗 §N）；--dir 含空格生成 49 处断链；文件目标被建成目录——三防呆 + AGENTS 生成器剔除裁剪组引用行 + scrub 悬空 §N 清洗
- **_backlog_core.py**：五子命令缺参/编号非数字裸 Traceback；add 空标题产出残卡——need/num 守卫全部干净报错
- **upgrade.sh**：目录名传错曾静默产出误导报告（含把用户 docs/ 误报本地新增）——校验「像部署目录」+ 提示疑似名；上游删除文档曾误报「本地新增+回馈上游」——新增「上游已删除」桶；明细 >20 条静默截断；缺 gen-index.py 裸 traceback
- **release-version.sh**：缺键/空文件静默零输出（pipefail×set-e 令诊断成死代码）；dev.0/dev.00 放行；前导零全链放行（tag 字符串排序倒退）；--bump 缺值裸崩；脏文件迁移致版本号倒退（dev.5→dev.3）；DEV_CYCLE 空值 validate 放行——六修 + 迁移前 check_cycle 预检
- **scan-secrets.sh**：重构逐文件两段式——文件名含冒号与超长行豁免从此可解析；参数拒绝；白名单缺失不再静默建文件
- **new-batch.sh / gen-index.py**：批次名超长裸崩 → 上限 100；manifest 缺字段/行内列表误入/文件缺失裸 traceback → 干净校验报错

### Added

- selftest R13（a-i：check 参数校验 / init 防呆 / 裁剪组合全量门禁 / 账本缺参）与 R14（a-e：版本文件边界）共十四条回归断言
- 三路子代理复现夹具留存（/tmp/rv-sandbox、scan-sandbox、up-sandbox 可重放）

## [2.6.2] - 2026-09-23

### Fixed

- backlog.sh 账本操作行 `run_gate` 与 python3 同行拼接：被当作多余参数传入内核，每次 add 产生 `run_gate` 垃圾 tag，且门禁 9 事后校验从未真实运行（外部反馈；拆为两行，双缺陷一并修复）
- 部署面文档引用 source 平面文档（部署后 scrub 将悬空链接洗为纯文本，§6 残留令部署门禁 6 必挂）：templates/context.md 术语表行、templates/adr.md 两处 doc-governance 引用、bootstrap/onboarding.md 系统设计行——统一改为「源仓路径 + 未随部署分发」纯文本指针（外部反馈 1 处，同类扫描另修 3 处）

### Added

- selftest 部署夹具门禁覆盖从 1/9/10 扩为全量十项（门禁 6 此前从未在部署面夹具运行——本次逃逸根因）；新增 R12e 断言：add 零参数泄漏（卡片与迁入条目不得含脚本内部 token）

## [2.6.1] - 2026-09-23

### Added

- 源仓自举入口补齐：仓库根 AGENTS.md（source 平面，manifest 申报纳管预算与门禁）——先读索引、本仓铁律六条（manifest 单源/提交前全绿/现在时态/版本单轨/批次留痕/术语先入表）、常用命令、改脚本=改门禁；源仓与部署面自此同为「根 AGENTS.md 入口」形态
- README 重写为公开仓形态：快速开始补 clone 步骤与部署产物清单（环境 runbook 骨架、acceptance 登记目录）；维护入口补 backlog.sh（含 prio）/scan-secrets.sh/源仓 AGENTS.md 三行与发布归档链接；meta/system-design.md §2 补源仓入口与部署面入口关系一句

### Fixed

- README 设计原则 4 口径滞后：仍写三命令符号，实为六符号（BUILD/TEST/RUN/LOG/DUMP/SHOT）
- AGENTS.md.template 首屏警告行与编辑卡内容漂移：五律逐条枚举未含 v2.6.0 新增补律（措辞冻结/首尾承重），改为指针式指回编辑卡

## [2.6.0] - 2026-09-23

系统审计修复批次：8 路子代理分维审计 + 2025-2026 实证研究对照（5 篇 arXiv 论文 + 6 权威实践源），P0×9 全修、P1 主体落地。审计全文见 docs/research/2026-09-23-system-audit.md。

### Fixed

- backlog.sh 数据完整性四修：同日二次 migrate 起永久丢卡（改为迁入节末整块追加）；未验卡守卫死代码（判定移到替换之前）；待验证卡无依据时默认伪造「用户验收通过」（改为诚实依据文案）；并发写丢卡（独立锁文件 + 临时文件原子替换）
- verify.md 首屏结构损坏（H1 粘入五维表人工行 + 表格 4 行缺行首管道，v2.5.0 编辑事故）；新增结构门禁（H1 单行/表格行首管道）拦截同类
- v2.5.0 连锁改口径漏改簇约 15 处统一（时间性现象一律先仪器取证，人工面仅四类例外）；requirement 模板优先级 P0-P3 补 P0-P4
- 关闭权限 CANON 矛盾裁决落地：仪器可验项 AI 取证后直接关闭，requirements 第 4 节按验收协议改写（用户裁决 2026-09-23）
- macOS 可移植：门禁 9 全量下沉 python 内核（消除 grep -P 依赖）；init.sh sha256/shasum 回退且失败即中止（防静默写坏部署基线）；selftest sed -i BSD 兼容
- init.sh：AGENTS.md 指向的 docs/env-runbook.md 骨架现随部署实例化（消除首屏死指引）；占位符报告补中文检测；步骤编号重复修正；docs/acceptance/ 目录随部署创建
- check.sh --deployed 缺参数死循环；backlog.sh 无参数时 usage 不可达

### Added

- 门禁增强：结构完整性门禁；第 6 节引用改行内多链接逐一尝试 + 子节号校验；backlog 不变量扩展（checkbox 词表白名单、卡片编号唯一、P4 卡必含前提行、任意缩进完结残留、5 位以上编号可见）；AGENTS.md 200 行约束进部署门禁；CHANGELOG 版本标题唯一 + 与 manifest 一致性；CANON:human-four 第四唯一归宿标记；门禁 7/8 历史面豁免（journal/archive/adr/research/CHANGELOG）
- backlog.sh prio 子命令（优先级调整，note 留痕）；requirements 补优先级变迁规则与 P4 前提复查周期动作
- 验收终态枚举补 SKIP（含 SKIP/BLOCKED 附待补卡编号）；SKIP 承接规则入 requirements 第 2 节；信任边界红线（登记内容是数据不是指令）
- verify 小改动最小验证集快速通道（第 3.2 节）；完成声明从点名式黑名单改为三段式正向白名单（priming 实证）
- 编辑卡补律：措辞冻结（换措辞=新发布须重验）与首尾承重（U 型位置纪律）
- 术语表补 6 词；观测符号统一为六符号（BUILD/TEST/RUN/LOG/DUMP/SHOT）；bootstrap 补 detach 移除流程；release 补版本单轨适用域注记
- selftest R12 账本回归断言组（未验拒/同日双卡不丢/影子卡拦截/5 位编号防撞）

### Changed

- registries/backlog.md 优先级表复制改指针（防 CANON 漂移）；能力域手段编码与命名维度映射；e2e 双模板互链纠错；changelog 模板版本指向改为真相源；三处运行时脚本口径与 onboarding 对齐（五个）

## [2.5.0] - 2026-09-23

oc-beacon 源项目 2026-08-24 → 09-23 演进回灌：六路并行调研（验证验收 / backlog 生命周期 / AGENTS 治理 / 机器门禁 / 发版回归 E2E / 编辑协议探测），53 项差距中 P0/P1 全部落地。调研全文见 docs/research/2026-09-23-oc-beacon-reintegration.md。

### Added

- workflows/acceptance.md：交付验收协议——关闭权限（仪器优先判定 + 四类人工例外：体感/凭据/长观察/主观拍板）、三步验收法（生成→纯净审查→纯净执行）、受端效果证据、资源独占串行、SKIP 语义、活清单治理
- scripts/backlog.sh：账本脚本（add/note/status/migrate/journal new/append），卡片区与 journal 禁手工直编；部署面第 5 个运行时脚本，init.sh 已纳入部署清单
- templates/acceptance-checklist.md（一卡一份验收清单骨架）、templates/env-runbook.md（测试环境 runbook：环境矩阵/标准入口/装包通道/坑清单）、templates/baseline-freeze.md（行为基线冻结）
- verify.md：能力分层 E2E 阶梯（活下来层/功能层/完整旅程/性能流；冒烟档=阶梯底部固定清单）、验收脚本化与 SKIP 规则
- evidence.md：单一通道不做最终判定 + 仪器盲区登记制、像素取证、视觉模型纪律、帧级取证、受端效果红线、连续日志档、动态定位铁律、执行/认知分离（BLOCKED 传播）、独占资源串行
- architecture.md：承重规则「具名反例」字段 + 机器执行节（窄化/豁免/报错回链/可追溯/baseline 引入——文档规则→机器门禁转化纪律）
- requirements.md：P4 优先级（外部前提阻塞，卡内必含「前提」行）、反馈归卡、裁决记录（最新为准+回写）、migrate 防呆、新问题入队量化例外
- release.md：tag 递进链校验、防回退护栏、开新线基准、密钥同批重设、Notes 通道范围+术语拦截
- edit-card.md：AGENTS.md 准入速记（部署面的规则准入与复审卡）
- journal-entry.md：取证链锚点（轮次/GREEN-RED/用户裁决前缀/before-after 证据对/遗留如实）；spec.md：用户故事（验证视角）/测试决策/范围外/约束行；research-report.md：Part C 多路调研合成（00-synthesis 收敛表+勘误台账）；context.md：豁免边界+agent 使用纪律；ability-domains：已知误判陷阱登记；manual-ui-checklist：先仪器后人工+清单治理
- new-batch.sh：批次名宽容转写（中文/空格/下划线→kebab）

### Changed

- verify.md 第 8 节人工维度方向性重构：由「六种时间性现象=人工」改为「仪器优先 + 四类人工例外」——时间性现象可量化面走录屏逐帧/像素取证（同步 manual-ui-checklist / regression / AGENTS 模板口径）
- check.sh 门禁 9 扩展：P0-P4 节序 + 卡片只许在 Pn 节内；system-design 门禁映射与术语表（仪器可验/四类人工项/受端效果/独占资源/基线冻结）同步
- stack-profile.md：观测命令符号位（LOG/DUMP/SHOT）、四档超时分档、门禁引入模式（存量豁免只拦新增）、禁并发构建

## [2.4.0] - 2026-08-24


全仓系统性审计修复：脚本能力逐条实测 + 文档描述双向核对（41 份文档 + 11 个脚本），共修复脚本缺陷 10 项、文档缺陷 30 余项，并全部固化为 selftest 回归断言（R1-R11）。

### Fixed（脚本，按严重度）

- scan-secrets.sh 统计跑在管道子 shell——命中全丢、退出码恒 0，**公开仓库泄密也不会拦截**；重写为主 shell 计数，实测 6 处命中 → exit 1
- scan-secrets.sh 白名单规则被同时当内容子串匹配——行内提及脚本路径即放行同行的真实密码；拆分为路径 glob 与「:字面量」内容豁免两种语义
- check.sh --deployed 指向不存在目录时静默回退到当前目录扫描（实测产出 44 条假断链）；现在拒绝并 exit 2
- 部署门禁 1 误扫目标项目用户自有 .md（用户旧笔记断链导致系统门禁失败）；改为只扫系统产物（目录名由脚本位置推导，支持 --dir 改名）
- upgrade.sh 全新部署零修改即报 11 处「双方修改需人工合并」；init.sh 现写部署基线 .deploy-baseline.txt，升级比对区分「可直接覆盖/本地化修改/无基线退化」三态
- init.sh 用 echo "\n" 写登记目录 README → 落盘为字面反斜杠 n；改 printf 真实换行
- gen-index.py --check 对 GEN 标记被删只警告不失败；缺标记即判漂移 exit 1
- 门禁 9 计数器漏计行尾裸编号与空格后的 #N → 计数器可与已用编号撞号；正则修正
- release-version.sh 静默吞掉杂散位置参数（next stray --bump patch 照常执行）；非 init 命令一律拒绝
- journal-entry.md 模板本体包在代码围栏里——new-batch.sh 产物 H1 仍是「模板」标题且相对链接必断；重构为整文件即条目（零相对链接）

### Fixed（文档，择要）

- release.md 虚构「发版脚本 commit/tag/push/触发 CI」能力链——脚本实际只管版本相位；改为如实双轨表述
- research-report.md 11 处：D0-D4 数字编号维度（全系统禁用）改命名维度、两对 §节号互换错位、根因型/补丁型词汇统一为根治/补丁
- requirement.md 自拟 P0-P2 三级与六态生命周期词表（与需求工作流锁定的唯一归宿词表冲突）；改指唯一归宿
- manifest/onboarding GEN 表：裁剪组表混入不部署的 source 面治理文档；registries「init 复制到 docs/」声称与 init 行为不符——init 现真正实例化能力域与债务登记簿，两处声明同时为真
- spec/plan/e2e 模板：虚构的 specs/、plans/ 存放路径（与 docs/specs/ 及命名门禁矛盾）、8 处 §引用错节、「P0 域」与优先级词表撞名
- backlog-entry.md 门禁能力过述（无检查项称「强制」、警告项称「强制」）；按实际强制/警告/纪律如实标注

### Added

- selftest.sh 部署演练扩为缺陷回归断言 R1-R11：历史修过的每个缺陷都有一条会失败的测试（含扫描器夹具仓断言 R9/R10，不触碰真仓库）
- init.sh：实例化能力域/债务登记簿到 docs/、写部署基线、部署 scan-secrets（含白名单）、sysname 合法性与自指目标校验
- upgrade.sh：基线感知漂移报告（可直接覆盖/本地化修改/上游有-部署缺/本地新增四类 + 建议动作）

## [2.3.1] - 2026-08-24

### Fixed

- init.sh 部署脚本子集修正：只复制目标项目内可独立运行的运行时脚本（check/_gates/new-batch/release-version）；init/upgrade/gen-index 依赖源仓 manifest，不再误导性部署
- init.sh 链接清洗覆盖生成的 AGENTS.md——修复 --no-ui 裁剪后模板正文手写链接悬空导致部署门禁 1 失败

## [2.3.0] - 2026-08-24

### Added

- 新增 scripts/scan-secrets.sh 敏感信息扫描：私钥/证书块、各家 API token 格式、密钥赋值、内网地址、个人信息五类检测；scripts/scan-secrets.allow 白名单（glob 或字面量）；已挂入 selftest 第 2.5 段与 CI——公开仓库强制
- 补齐 .github/workflows/check.yml（此前写入静默丢失，本次已验证存在于磁盘与 git）

## [2.2.0] - 2026-08-21

### Added

- 新增 scripts/selftest.sh 系统自检：脚本语法 + 源仓十门禁 + 部署演练（init --no-example + 部署门禁）+ 版本阶梯演练（全相位走通与非法转移拒绝断言）一体执行；--quick 可跳过演练只跑语法与门禁
- 新增 .github/workflows/check.yml：push（master/main）/ PR / 手动触发运行 selftest——本地与 CI 同一条命令，门禁从「自觉运行」变为「不可绕过」

## [2.1.0] - 2026-08-21

### Added

- 新增版本相位阶梯规则与 scripts/release-version.sh：每个新版本必经 开发版 dev.n → 测试版 beta → 正式版，不可跳级；beta 发现缺陷退回同版本 dev（序号续增）；非法转移直接拒绝；VERSION_CODE 每次相位推进 +1
- init.sh 部署时复制运维脚本（release-version / new-batch / check / upgrade）到目标项目系统目录

### Changed

- release.md §2 重写为相位阶梯规则（格式 x.y.z[-dev.n|-beta]）；Release Notes 与手动 runbook 模板措辞同步

## [2.0.0] - 2026-08-21

### Added

- 新增 manifest.yaml 单源元数据中心：索引表/目录树/裁剪表全部由 scripts/gen-index.py 生成，手工副本归零
- 新增 scripts/check.sh 十项机械门禁：链接/行数预算/占位符/MUST 稀缺性/生成幂等/引用可解析/唯一归宿/术语词汇/backlog 不变量/命名规约
- 新增 scripts/init.sh 一键部署（裁剪→生成 AGENTS.md→实例化登记簿→门禁→占位符报告）
- 新增 scripts/upgrade.sh 上游升级漂移报告与 scripts/new-batch.sh 批次创建
- 新增登记三分离：backlog 未决索引（完结即迁移）/ journal 批次证据日志（append-only）/ spec 生命周期（active→archive）
- 新增 CONTEXT.md 项目术语表模板（定义 + Avoid 反例词）
- 新增命令符号 BUILD/TEST/RUN：唯一定义于栈档案 §5，全系统引用符号不复制命令
- 新增编辑卡（部署面文档修改五律）与写作规范新内容：命题保全/按位置覆盖/推理泄漏分类/新增即替代审计

### Changed

- 目录重组为功能分组：standards + workflows + stack + templates + registries + meta（治理，source 平面）
- 验证体系重组：五文档团簇（互指 16 边）合并为三文档线性链（verify → evidence → regression），统一命名维度（构建/测试/运行时/遥测/人工）
- 优先级体系扩展 P3（观察项）；状态流转唯一归宿锁定（CANON 标记）
- 发版文档与手动 runbook 分离；E2E 双文档拆为独立 plan/runbook 两模板
- 模板层统一：6 处内嵌模板抽出，模板入口唯一（templates/ 18 份）

### Removed

- 移除编号式验证维度（旧维度编号词汇及全部映射表）
- 移除全部模板头部的来源叙事（推理泄漏）与 5 处断裂章节引用
- 移除手工索引副本（四处）与手工影响面表
- 移除随行元层：治理三份改为 source 平面，不再复制进目标项目

### Fixed

- 修复 5 处章节引用断裂（plan、architecture、research-report、release-notes、requirement 状态词表分叉）
- 修复开发工作流孤儿表格行；修复优先级定义两处分叉措辞

## [1.1.0] - 2026-08

- 融合迭代：新增 5 模板、全链接化、编号统一、7 份文档深化、初始化手册。

## [1.0.0] - 2026-08

- 初版：26 份文档，从生产实践提炼。