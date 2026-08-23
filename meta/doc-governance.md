# 文档治理（Doc Governance）

> 本系统的文档类型学、存放决策、生命周期与门禁映射——文档体系的「宪法」层（source 平面）。

## Use when

- 新增/移动/合并/退役任何文档或规则时
- 评审文档体系、做行数预算、决定内容放哪一层时

## 1. 文档类型学

| 类型 | 特征 | 更新频率 | 例子 |
|------|------|----------|------|
| 规范类 | 规则 + 违反后果；表格化 | 低 | [code-style.md](../standards/code-style.md)、[ui-conventions.md](../standards/ui-conventions.md) |
| 流程类 | 步骤 + 完成判据；顺序执行 | 中 | [dev.md](../workflows/dev.md)、[verify.md](../workflows/verify.md) |
| 手册类 | 参考 + 查表；按需查阅 | 中 | [evidence.md](../workflows/evidence.md)、[stack-profile.md](../stack/stack-profile.md) |
| 登记类 | 条目 + 状态流转；持续追加 | 高 | backlog、[architecture-debt 登记簿] |
| 模板类 | 填空骨架 | 低 | templates/ 全部 |
| 历史类 | 变更故事与证据；append-only | 单向追加 | journal、specs 归档、CHANGELOG |

判定一个内容属于哪类，再套对应结构——禁止把流程写成散文、把规范写成教程、把登记写进规则文档。

## 2. 存放决策（内联 vs 外链）

```
新规则/新知识
  ├─ 删除它，agent 会犯错吗？
  │    ├─ 不会 → 不写（常识/噪音）
  │    └─ 会  → 是精确命令/硬约束/红线吗？
  │              ├─ 是 → 内联进 AGENTS.md（一行一条，含后果）
  │              └─ 否 → 承载它的规则依赖它吗？
  │                        ├─ 是 → 一行要点内联 + 详细外链
  │                        └─ 否 → 放主题文档，manifest 加条目并标级别
  └─ 判定级别：不读会犯错 = MUST / 读了更好 = SHOULD / 背景 = MAY
```

五个排除提问（任一为「是」则排除出 AGENTS.md）：

| # | 提问 |
|---|------|
| 1 | agent 看代码/文件系统自己能推断出来吗？ |
| 2 | 是训练时已知的标准约定吗？ |
| 3 | 是通用软件工程原则吗？ |
| 4 | 是详细 API 文档/长教程吗？（→ 外链） |
| 5 | 是变化频繁的信息吗？（→ 排除或放 L1） |

## 3. 级别管理

| 规则 | 内容 |
|------|------|
| 稀缺性 | MUST ≤ must_limit（manifest）；新增 MUST 必须挤掉一条旧的（门禁 4） |
| 随场景变 | 同一文档在不同场景级别不同（Use when 列描述 MUST 生效场景） |
| 定期复审 | 每次发版前扫一遍：级别虚高与虚低同样有害 |

## 4. 行数预算与例外

- 默认预算 defaults.line_budget（250）；单文档可经 manifest.budget 字段申报例外（须附注释理由）
- 超预算的处置顺序：外链下推 → 按分支拆分 → 归档历史内容；例外申报是最后手段
- 长度本身不是缺陷：一份解释「为何故意长」的例外优于机械拆散强关联内容

## 5. 生命周期

| 阶段 | 动作 | 门禁 |
|------|------|------|
| 新建 | manifest 加条目 → gen-index.py → 按 [doc-writing-standards.md](./doc-writing-standards.md) 撰写 | 5 |
| 修订 | 同 commit 更新；动 manifest 则重跑生成器 | 1/5/6 |
| 新增即替代审计 | 新增登记类内容时扫描同类旧记录：全量替代 → 合并并修复入链后删旧；部分替代 → 交叉链接；独立 → 保留 | 1 |
| 退役 | manifest 删条目 → 删文件 → 重新生成 → 修复全部入链 | 1/5 |

陈旧指令比缺失指令更糟：命令失真后 agent 会学会忽略整个文件——宁可删除也不留过期规则。

## 6. 变更故事的合法归宿

规则正文一律现在时态陈述。历史叙事（used-to/no-longer/来源融合/评审过程）只允许出现在：

| 归宿 | 承载内容 |
|------|----------|
| docs/journal/ | 批次执行过程与证据 |
| docs/archive/specs/ | 已完结的设计决策 |
| CHANGELOG.md | 版本历史 |
| manifest replaces 字段 | 迁移溯源 |

## Related

- 写作规范：[doc-writing-standards.md](./doc-writing-standards.md)
- 系统设计与门禁映射：[system-design.md](./system-design.md)
- 上游升级流程：[../bootstrap/onboarding.md](../bootstrap/onboarding.md)