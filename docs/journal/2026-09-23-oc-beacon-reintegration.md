# 2026-09-23 批次：oc-beacon 演进回灌（v2.5.0）

> 状态：已完结
> 来源：用户裁决（/research 深度对比 oc-beacon 演进并整合进蓝本，允许重构/重写）
> 关联：docs/research/2026-09-23-oc-beacon-reintegration.md

## 目标

以六路并行子代理调研 oc-beacon 2026-08-24（蓝本抽取时点）至 2026-09-23 的治理演进，找出蓝本缺失/落后项并整合落地。

## 过程与证据

- 六路维度调研（验证验收 / backlog 生命周期 / AGENTS 设计治理 / 机器门禁 / 发版回归 E2E / 编辑协议与探测），每路输出含「文件:行」级源证据的差距报告；主代理交叉核对蓝本 41 份文档与 11 个脚本。
- 差距定级：53 项（P0×18 / P1×24 / P2×11）；完整矩阵见关联研究报告。
- GREEN：源仓十门禁通过（含门禁 6 全部 164 处 § 引用可解析、门禁 3 零占位符）——执行于 2026-09-23，命令 bash scripts/check.sh。
- GREEN：完整 selftest 通过（语法 + 敏感扫描 0 命中 + 部署演练 + 回归断言 R1-R11 全绿 + 版本阶梯演练全通）——执行于 2026-09-23。
- GREEN：backlog.sh 功能演练（临时部署）——add/note/status/migrate/journal new（中文名转写 alpha）/journal append 全链路；migrate 未验卡正确拒绝、迁入卡转 [x]、落点为日期批次文件（README 排除）；门禁 9 七项全过（含新增「卡片均在 P0-P4 节内」）。
- 修复过程中抓到并修正的实现缺陷：new-batch 转写 sed 表达式非法、migrate 误选 README.md、迁入卡 checkbox 未转 [x]、backlog.sh 嵌入 python 缩进错误——均已复测覆盖。
- 遗留（如实）：P2 项 11 条未在本批落地（外部 tracker 双轨节、编号治理注记、tombstone 评估、事件生命周期模板、宿主 CI 挂点指引、debug 后门独立成节等），已在研究报告第 4 节列为后续路线。

## 完结迁移区

（本批次无 backlog 卡片迁移；源仓 registries 不承载实际条目）

## 蒸馏

docs/research/2026-09-23-oc-beacon-reintegration.md（53 项差距矩阵 + 不搬运清单 + 整合路线）
