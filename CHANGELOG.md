# Changelog

本项目遵循 [语义化版本](https://semver.org/) 与 [Keep a Changelog](https://keepachangelog.com/)。

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