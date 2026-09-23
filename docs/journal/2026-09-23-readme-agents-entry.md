# 2026-09-23 <批次：readme-agents-entry>

> 状态：已完结
> 来源：用户反馈（v2.6.0 发布后要求检查 README/AGENT 文件是否需更新；授权「允许优化、重构甚至全面重写」）
> 关联：docs/research/2026-09-23-system-audit.md（自举项在册方向）

## 目标

把 README 与 AGENT 入口文件对齐 v2.6.0 后的真实口径；补齐源仓自身无 AI 协作入口的自举缺口。

## 过程与证据

- 第 1 轮（口径核查）：README.md 与 AGENTS.md.template 逐行对照 v2.6.0 变更面（六符号统一、backlog prio、init 实例化 env-runbook 骨架与 docs/acceptance/、编辑卡补律）。判定：README 三处滞后（设计原则 4 仍写三符号；init 产物清单缺环境 runbook 骨架与 acceptance 登记目录；维护入口缺 backlog.sh/scan-secrets.sh/源仓入口行）；模板首屏警告行逐条枚举五律、未含补律。根因 = v2.6.0 批次连锁改口径时 README 与模板首屏不在改清单。GREEN
- 第 2 轮（缺口定性）：源仓无根 AGENTS.md——系统核心主张「项目根 AGENTS.md 唯一入口」，源仓自身入口此前散在 README 维护入口表，属自举缺口。GREEN
- 第 3 轮（实施）：
  - 新增仓库根 AGENTS.md（约 60 行）：先读索引（级别口径复用 manifest）+ 本仓铁律六条 + 常用命令 + 改脚本=改门禁；manifest 申报 id=agents-source（plane=source，budget=80，indexed=false——不进部署面索引，不计 MUST 稀缺分母，gen-index 复核 MUST 仍 6 条）
  - AGENTS.md.template 首屏警告行改指针式（编辑五律 + 补律），消除对编辑卡内容的枚举复制
  - meta/system-design.md §2 补源仓入口与部署面入口关系一句；GEN full-table 由 gen-index.py 重建（46 文档）
  - README.md 重写为公开仓形态（clone 步骤、六符号、维护入口补三行、发布归档链接）；GEN readme-tree 重建
  - 版本 2.6.0 → 2.6.1；CHANGELOG.md 增 [2.6.1] 条目（门禁 8 版本一致性）
- 用户裁决：「允许优化、重构甚至全面重写」（2026-09-23）
- 第 4 轮（RED→GREEN，改脚本=改门禁）：首跑 check.sh 门禁 6 报 standards/architecture.md:124 §2 断裂。取证：该行「新增承重规则 → §2 登记 + 判断是否内联进 AGENTS.md」的裸 §2 按本仓惯例指本文 §2，但根 AGENTS.md 落地后「行内文件名提及」候选首次可命中，_gates.py 的 `cands ... or [f]` 只在无显式候选时才回退本文——显式候选劫持裸引用，属伪阳性缺陷类。修复：自身文件作为末位候选加入逐一尝试序列（与 v2.6.0 多链接 trial 语义一致）。GREEN
- 验证输出（2026-09-23，本批最终轮）：
  - bash scripts/check.sh → 已运行门禁 1 2 3 4 5 6 7 8 9 10；§引用 191 处全部可解析；结果：通过
  - bash scripts/selftest.sh → R1-R12 全部 ✓（含 R1/R5/R7 部署夹具门禁——修复后的门禁 6 双模式均验证）；自检结果：通过

## 完结迁移区

本批无卡片迁移（源仓无 backlog 账本；本仓待办以各批 journal「遗留」节承载）。

## 遗留

- 许可证待定：仓库已公开（github.com/LeoNardo-LB/ai-dev-guide），README 许可节为「待定」——需用户决策许可证后补 LICENSE 文件与 README 对应节
- README.md 未纳入 manifest 预算申报（沿历史现状；是否纳入属结构决策，建议与「发版 validate --tags 机器化」同批议）
