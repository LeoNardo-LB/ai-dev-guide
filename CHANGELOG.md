# Changelog

本项目遵循 [语义化版本](https://semver.org/) 与 [Keep a Changelog](https://keepachangelog.com/)。

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