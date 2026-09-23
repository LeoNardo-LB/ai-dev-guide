# 文档编辑卡（Edit Card）

> 部署面的文档修改五律——改任何文档或 AGENTS.md 规则前先过这张卡。完整规范在源仓 meta/（按需复制）。

## Use when

- 修改本项目任何文档、AGENTS.md 规则、backlog/journal/spec 条目前

## 编辑五律

| # | 律 | 判据 |
|---|----|------|
| 1 | 命题保全 | 删改段落前枚举事实子句（行为/条件/情态/否定保证/后果），每个子句必须存活；字数变少不是改进 |
| 2 | 单一真相源 | 一个含义只在一处定义；重复出现的表打 CANON 标记；命令用六符号（BUILD/TEST/RUN/LOG/DUMP/SHOT，定义在 [stack-profile.md](../stack/stack-profile.md) 第 5 节） |
| 3 | 现在时态 | 规则正文写「是什么/要做什么」；变更历史入 journal/CHANGELOG，不写 used-to/no-longer |
| 4 | 指针三要素 | 引用任何文档必须带级别 + 用途 + Use when（首词 = 触发动词） |
| 5 | 同 commit 更新 | 改代码的同一 commit 更新文档；完结 backlog 卡片当场迁移入 journal（顶层零完结残留） |

补律（2026-09-23 审计定规）：**措辞冻结**——定版指令禁同义改写；换措辞 = 一次新发布，须过全部门禁重验（细微措辞变化可致指令遵循可靠率显著下降—— cousin-prompt 实证）。**首尾承重**——入口/速记文件的关键规则置于文件开头或结尾，长表与低频内容放中部（长上下文中部注意力衰减——Lost in the Middle 实证）。

## AGENTS.md 准入速记（改目标项目 AGENTS.md 前过一遍）

| # | 判定 | 去向 |
|---|------|------|
| 1 | 删掉它 agent 会犯错吗？不会 → 不写（常识/噪音） | 不进 AGENTS.md |
| 2 | 是精确命令/硬红线 → 内联（一行一条，含后果） | AGENTS.md 正文 |
| 3 | 承载规则依赖它 → 一行要点内联 + 详细外链 | 正文 + 索引表 |
| 4 | 其余 → 主题文档；索引表加行并标级别（🔴不读会犯错 / 🟡更好 / 🟢背景） | L1 文档 |

硬约束：AGENTS.md ≤200 行、MUST ≤7 条——新增 MUST 必须挤掉一条旧的；多条都想加粗 = 文件太长，应删除而非强调。完整决策树与证据在源仓 meta/doc-governance.md。

## 登记三分离速记

- backlog = 未决索引（卡片 ≤3 行 + 链接；完结即迁移）
- journal = 批次证据（开工时 new-batch.sh 创建；append-only）
- spec = 设计决策（非显然取舍才写；验收后入 docs/archive/specs/）

## Related

- 需求工作流（迁移规则）：[../workflows/requirements.md](../workflows/requirements.md)
- 栈档案（命令符号定义）：[../stack/stack-profile.md](../stack/stack-profile.md)