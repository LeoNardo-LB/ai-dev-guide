# 2026-09-23 <批次：external-bug-backlog-context>

> 状态：已完结
> 来源：用户反馈（外部使用者报两个源仓 bug；其部署面副本已自行修复并留痕 journal）
> 关联：docs/journal/2026-09-23-readme-agents-entry.md（同日批次）

## 目标

核实并修复外部反馈的两处缺陷；扫描同类；补自检逃逸根因的覆盖缺口。

## 过程与证据

- 第 1 轮（取证复现）：
  - bug A：scripts/backlog.sh L38 `run_gate` 与 python3 同行 → 被当作多余实参传入 _backlog_core.py，add 的 rest 解析把它拼进 tags——沙盒复现卡片 `- [ ] **#2 测试卡** `run_gate``；且 run_gate 函数从未执行（「变更后自动跑部署门禁 9」承诺失效）。RED→确认
  - bug B：templates/context.md Related 行链接 meta/system-design.md §6——部署后 scrub 将悬空链接洗为纯文本但 §6 残留，沙盒全新部署跑全量门禁：`✗ [6] §引用断裂 2 处`（sysdir 模板与实例化 CONTEXT.md 各一）。RED→确认
  - 逃逸根因：selftest 部署夹具只跑门禁 `--only 1,9,10`，门禁 6 从未在部署面运行；R12 断言不检查卡片 token。
- 第 2 轮（同类扫描）：部署面全文件 grep source 平面目标——另发现 onboarding.md:64、adr.md:4、adr.md:102 三处同类链接（无 §N 不挂门禁，但 scrub 后同样退化为死文本）。
- 第 3 轮（修复）：
  - backlog.sh L38 拆两行（python3 调用与 run_gate 分离）
  - 四处引用统一改「源仓路径 + 未随部署分发」纯文本指针（不构成链接与 §N，双模式门禁安全）
  - selftest：部署夹具两处门禁检查扩为全量（去 --only）；新增 R12e——add 后 backlog.md 与迁入 journal 均不得含 run_gate token
- 第 4 轮（复验，2026-09-23）：
  - bug A：add 卡片 `- [ ] **#2 测试卡**`（无垃圾 tag），输出新增「✓ 门禁 9 通过」（run_gate 首次真实运行）GREEN
  - bug B：全新部署全量门禁 1-10「结果：通过」，四处文件均为纯文本指针 GREEN
  - 全仓：check.sh 源面十门禁通过；selftest R1-R12e 全绿（含全量部署夹具）GREEN

## 完结迁移区

本批无卡片迁移（源仓无 backlog 账本）。

## 遗留

- 外部使用者的部署面副本含其本地修复，与本批源仓修复措辞不同——upgrade.sh 漂移报告会如实标记为「本地化修改」，由其自行合并（部署基线机制按设计工作）
- scrub_links 对「洗链接时相邻 §N 残留」无防御；本次以源头不产生此类文本 + selftest 全量夹具兜底，scrub 自身增强未做（低频场景，在册观察）
