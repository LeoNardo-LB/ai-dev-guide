# AGENTS.md — ai-dev-guide 源仓

> 本仓是可整体部署的渐进式披露 AI 开发文档系统的**源仓**。本文件是在源仓内工作（改文档、脚本、门禁、模板）的入口；部署到目标项目后的入口是那边项目根的 AGENTS.md（由 AGENTS.md.template 实例化）。

## 先读（源仓工作索引）

| 级别 | 文档 | 用途 | Use when |
|------|------|------|----------|
| 🔴 MUST | [meta/doc-writing-standards.md](meta/doc-writing-standards.md) | 面向 Agent 的写作规范（指针/分层/十律/泄漏分类） | 修改本系统任何文档前 |
| 🔴 MUST | [meta/edit-card.md](meta/edit-card.md) | 编辑五律 + 补律（措辞冻结/首尾承重）+ AGENTS 准入速记 | 修改任何文档或索引规则前 |
| 🟡 SHOULD | [meta/doc-governance.md](meta/doc-governance.md) | 文档治理：类型/存放决策/生命周期/门禁映射 | 维护、审查、重组本系统时 |
| 🟡 SHOULD | [meta/system-design.md](meta/system-design.md) | 系统设计、术语表（§6）与生成索引总表 | 理解/修改本系统结构、查术语时 |
| 🟢 MAY | [specs/v2-rebuild.md](specs/v2-rebuild.md) | v2 重建结构性决策（登记三分离等） | 追溯本系统设计取舍时 |

## 本仓铁律

1. **manifest 单源**：增删/移动/改级/改预算文档 = 改 manifest.yaml + 跑 `python3 scripts/gen-index.py`；`GEN` 标记段是生成物，手改会被门禁 5 打回。
2. **提交前全绿**：`bash scripts/check.sh`（十门禁）+ `bash scripts/selftest.sh`（回归 R1-R12）全绿才提交；改了门禁或脚本，两跑必做。
3. **现在时态**：规则正文零退役词汇与变更叙事词（清单见 scripts/check.sh 门禁 8）；历史叙事唯一归宿 = specs/、docs/journal|archive|adr|research/、CHANGELOG.md。
4. **版本单轨**：本系统版本 = manifest system.version + git tag，同批落位；相位阶梯只约束部署面项目（workflows/release.md §2.1 适用域注记）。
5. **批次留痕**：开工 `bash scripts/new-batch.sh "批次名kebab"` 建 journal（append-only）；未完结事项登记当批「遗留」节，随后续批次消化。
6. **术语先入表**：承重术语先定义进 meta/system-design.md §6 再使用（门禁 8 校验）。

## 常用命令

| 动作 | 命令 |
|------|------|
| 全量门禁 | `bash scripts/check.sh`（部署面加 `--deployed 目标项目根`） |
| 回归自检 | `bash scripts/selftest.sh` |
| 重建索引 | `python3 scripts/gen-index.py` |
| 新批次日志 | `bash scripts/new-batch.sh "批次名kebab"` |
| 部署到新项目 | `bash scripts/init.sh 目标项目根` |
| 升级漂移报告 | `bash scripts/upgrade.sh 源仓根 已部署项目根` |

## 改脚本 = 改门禁

scripts/ 与门禁一体：改脚本可能改变 check.sh / selftest.sh 的判定口径。改完必须全量复跑两检并在批次 journal 声明影响面；新增门禁规则同步登记 meta/doc-governance.md 的门禁映射。

## Related

- 面向外部使用者：[README.md](README.md)
- 部署面入口模板：[AGENTS.md.template](AGENTS.md.template)
