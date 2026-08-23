# ai-dev-guide v2.0 全面重构 设计（#SYS-2）

日期：2026-08-21
状态：已批准

## 背景与目标

- **#SYS-1** 现有 v1.1（34 文件/4060 行）经 DSH 自带 11 个技能对照评估，存在 6 个结构性病灶：模板层碎片化、验证团簇（5 文档 16 条互指边）、元层随行、索引四处手工副本、流程写成散文、系统不自举；另有 5 处 §断引、1 处表格断裂、4 处重复表、2 处承诺失配、5 处来源叙事泄漏、2 套验证编号词汇。
- **新增项** 来源：用户决策——允许全面重写、不考虑兼容；固定流程脚本化、固定内容模板化；双平面激进方案、维度命名化、bash+python3 混合、e2e 拆双模板均确认采纳。
- **#SYS-3** backlog/journal/spec 三分离设计确认纳入（参考 oc-beacon 生产实践）：backlog 为未决索引（完结即迁移）、journal 为批次执行与证据日志（开工时创建、append-only）、spec 带生命周期（active→archive）；另吸收 CONTEXT.md 术语表与 backlog 机械不变量脚本。
- 目标：manifest 单源驱动的双平面文档系统——手工同步点归零、门禁全绿、验证主题线性化、模板层统一、登记三分离（backlog/journal/spec）、系统用自己的模板管理自己。

## 已探测事实

1. **链接图**：374 条链接中 333 条系统内链接全部有效；41 条"断链"全部是 AGENTS.md.template 的部署前缀（设计使然但无门禁区分）（探测日期 2026-08-21，手段：python 链接校验脚本）
2. **引用汇聚**：verification.md 入度 40 为全系统最高；验证簇 5 份文档互指 16 条边（探测日期 2026-08-21，手段：出/入度统计）
3. **占位符密度**：release-workflow 49、e2e 模板 48、stack-profile 35——三者内容形态实质是模板（探测日期 2026-08-21，手段：占位符正则统计）
4. **§引用**：124 处跨文 §引用，零机器校验；已断裂 5 处（plan.md:34 §6→实际§8、architecture.md:112 §7 变更历史不存在、research-report.md:10 §2 指错文档、release-notes §4→实际§6、requirement-template 状态词表与 workflow §8 分叉）（探测日期 2026-08-21，手段：grep + 逐条人工核对目标标题）
   - 推论：§引用必须配机器门禁，否则每轮编辑都会再断——待验证（本次 check.sh 门禁 6 落地后验证）
5. **散文流程**：onboarding 125 行中步骤 1-7 全部是确定性操作；doc-governance §6 承诺的"链接机器校验"无对应脚本（探测日期 2026-08-21，手段：全文通读 + scripts/ 目录不存在）
6. **工具链约束**：目标环境 python3 + bash 可用，PyYAML 未必安装（探测日期 2026-08-21，手段：环境盘点）
   - 推论：manifest 解析用自带的严格子集解析器，零外部依赖——待验证（gen-index.py 首跑验证）

## 现状文档链路

- 入口：README.md → AGENTS.md.template → 01-meta/system-design.md §5 索引表（31 行手工）↔ template 索引表（31 行手工）✅ 结构一致 / ❌ 四处副本无生成机制
- 验证链：verification.md → qa-methodology.md → regression-guide.md → observability.md → ui-verification.md（❌ 团簇：维度 1-5 与 D0-D4 双编号 + 2 张映射表 + ui-verification §5 专门解释文档关系）
- 模板散布：08-templates/ 9 份 + bug-analysis §10 / ui-verification §2 / qa-methodology §4.1 / regression-guide §4.3 / tech-debt §3 / backlog 条目格式（❌ 6 处内嵌模板）
- 已断链路（❌ 问题点）：plan.md:34、architecture.md:112、research-report.md:10、release-notes-template 头部、requirement-template 状态字段、dev-workflow.md:31-32 孤儿表格行

## 分节设计

### 节 1 — 单源元数据

##### 决策点：manifest.yaml 为唯一元数据中心
- **方案**：每份文档一个条目（id/path/plane/level/purpose/use_when/trim_group/budget/replaces）；所有索引表、目录树、裁剪表由 scripts/gen-index.py 从 manifest 生成，写入各文件的 `<!-- GEN:... -->` 标记段
- **取舍**：放弃手写索引的自由度；换取增删文档只改 manifest 一行 + 幂等校验（门禁 5）
- **为什么**：v1.1 四处副本当前恰好一致纯因刚写完；结构上必漂移（DSH docs.ts manifest→投影同构）

##### 决策点：YAML 子集自解析
- **方案**：manifest 用受约束 YAML（两空格缩进、标量值、`- ` 列表项），gen-index.py 内置 60 行解析器，格式违规立即报错
- **取舍**：不能任意 YAML（锚点、多行字符串）；换零依赖
- **为什么**：系统核心卖点是"整体复制"，依赖 PyYAML 会破坏它

### 节 2 — 双平面部署

##### 决策点：deployed / source 两平面，元层不随行
- **方案**：plane 是文档级字段。deployed（19 内容 + 16 模板 + 3 登记簿骨架）复制进目标项目；source（meta/ 治理三份 + scripts + specs + docs/adr + README + template 本体）只留源仓；目标项目的文档编辑纪律由 deployed 平面的 meta/edit-card.md（≤40 行）承载并指回源仓
- **取舍**：目标项目改文档时拿不到完整写作规范全文；换 L0 索引净减约 31 行的常驻认知负载
- **为什么**："维护这套系统"的知识对目标项目 agent 几乎无触发场景，受众分离是根因修复

##### 决策点：{{SYS}} 前缀变量
- **方案**：AGENTS.md.template 内链接统一写 `{{SYS}}/<路径>`；init.sh 替换为目标目录名；check.sh 源模式将 `{{SYS}}/` 识别为合法前缀
- **取舍**：模板不可直接当 AGENTS.md 用；换 41 条"设计性断链"获得机器可判语义
- **为什么**：部署前缀断链与真断链无法区分是 v1.1 链接校验缺失的主因

### 节 3 — 验证体系线性化

##### 决策点：维度命名化，消灭双编号
- **方案**：五维改用名称：构建 build / 测试 test / 运行时 runtime / 遥测 telemetry / 人工 human；"维度 1-5""D0-D4"全部退役；结论类型×证据组合矩阵（qa-methodology §2.1）前置为 verify.md 主表
- **取舍**：失去数字排序的隐含顺序感；换 2 张映射表 + 4 处口径声明 + 门禁 8 的词汇禁令
- **为什么**：编号是影子词汇，映射表是分叉症状

##### 决策点：按 agent 问题重组四文档
- **方案**：verify.md（算完成了吗）/ evidence.md（怎么拿证据）/ regression.md（变更后测什么）+ templates/（大型验证怎么组织）；ui-verification 并入 verify.md §人工 与 templates/manual-ui-checklist.md；其 §5"文档衔接"整节删除
- **取舍**：单文档变厚（verify.md 预算放宽至 280 行）；换互指 16 边 → 3 节点线性链
- **为什么**：按主题切分是团簇根因；按问题切分让每次加载恰好一份

### 节 4 — 流程脚本化与门禁

##### 决策点：四个脚本
- **方案**：init.sh（部署：裁剪→生成 AGENTS.md→实例化登记簿→首检→commit）/ check.sh（8 门禁）/ gen-index.py（派生）/ upgrade.sh（升级漂移报告）；bash 编排 + python3 解析
- **取舍**：接入方必须有 bash+python3；换 onboarding 125 行散文退役为 ≤40 行说明
- **为什么**：确定性流程写成散文，执行质量必然依赖自觉

##### 决策点：8 项门禁
- **方案**：①链接（{{SYS}} 感知）②行数预算（manifest 驱动+例外申报）③占位符（templates/stack/registries 豁免+白名单）④MUST 计数 ≤7 ⑤生成物幂等 ⑥§引用可解析（目标须有 `## N.` 标题）⑦重复表指纹（优先级/状态机/补丁三件事唯一归宿）⑧术语与禁用词（铁律/红线/门禁须入术语表；旧编号词汇禁用）
- **取舍**：编写时多受约束；换"每条机械规则配门禁"的 DSH 教义落地
- **为什么**：v1.1 的 5 处 §断引、4 处重复表、2 处承诺失配全部是缺失门禁的直接产物

### 节 5 — 模板层统一与自举

##### 决策点：三分离
- **方案**：模板（骨架，templates/ 16 份）/ 纪律（workflows/）/ 实例（registries/ 3 份，init.sh 复制到目标项目）；6 处内嵌模板全部抽出；e2e 拆 plan/runbook 两文件；债务状态词表统一为 待处理/处理中/已消除/已接受
- **取舍**：读纪律时看不到条目格式（多一跳链接）；换 init 机械实例化与模板单一入口
- **为什么**：三形态混装使规则文档被骨架撑长、模板无统一入口

##### 决策点：系统自举
- **方案**：本 spec 用自家 spec 模板写；重构决策落 docs/adr/ 4 份；版本史用自家 changelog 模板落 CHANGELOG.md；模板头部"由 ai-spec/ai-dev-docs 融合而来"来源叙事全部删除（推理泄漏类 1/3）
- **取舍**：无
- **为什么**：系统不用自己的模板，就永远发现不了模板的问题

### 节 6 — 登记三分离（backlog / journal / spec）

##### 决策点：backlog 是未决索引，完结即迁移
- **方案**：registries/backlog.md 头部写明机械不变量——卡片 ≤3 行摘要+链接（全文在 spec/journal，不内联）；「下一编号：**#N**」计数器；完结（用户验收）后**当场迁入** journal 对应批次文件，backlog 顶层 `[x]` 残留为零（check.sh 门禁 9 强制）；优先级 P0-P3（P3=观察项/依赖外部的低价值改进）
- **取舍**：backlog 失去"历史查询"能力；换永久 ≤250 行的扫描成本（历史走 journal 与 git）
- **为什么**：oc-beacon 实证——v1.1 的 backlog 模式（完结条目留存）必然无限膨胀，登记簿越厚扫描越被跳过

##### 决策点：journal 是批次执行与证据日志（append-only）
- **方案**：每个工作批次一个 `docs/journal/YYYY-MM-DD-<kebab>.md`，**开工时创建**（init.sh 与 workflows/requirements.md 规定）；过程中取证/验证证据直接写入 journal，卡片全程 ≤3 行；完结条目原文迁入（不压缩不删改）；可复用蒸馏结论提炼进 docs/research/，journal 只记执行与证据；journal 条目模板进 templates/journal-entry.md，`scripts/new-batch.sh` 一键创建
- **取舍**：多一层文件产物；换 backlog 恒薄、证据有 append-only 归宿、批次可回溯
- **为什么**：证据写在卡片里 = 卡片膨胀；证据散在会话里 = 随会话蒸发；journal 是唯一让两者都成立的归宿

##### 决策点：spec 带生命周期（active → archive）
- **方案**：spec 头部增加「状态 + 位置约定」两行：active 位于 `docs/specs/`，实现并验收后移入 `docs/archive/specs/` 并更新状态行与 backlog 卡片引用路径；归档 spec 定期清理零外部引用者（git 历史永久可找）；简单需求不写 spec（触发条件不变：非显然取舍 或 跨会话上下文）
- **取舍**：spec 多一次移动动作；换 active 目录永远只含"待实现/进行中"的设计
- **为什么**：specs 目录混积已完结设计 = 找当前权威设计要翻一堆死文档

##### 决策点：CONTEXT.md 术语表模板
- **方案**：templates/context.md——每术语 = 名称 + 1-2 句定义 + _Avoid_ 反例词（避免哪些近义混用）；只收项目特有概念，不收通用工程概念；init.sh 在项目根创建
- **取舍**：无（纯增量）
- **为什么**：oc-beacon 的 CONTEXT.md（渲染供给/流式 turn/跳转稳定窗口…）实证了术语表对 agent 用语一致性的价值；v1.1 的 system-design §8 术语表只覆盖本系统自身词汇，未提供项目领域术语的承载位

##### 决策点：check.sh 增加登记门禁（门禁 9-10）
- **方案**：⑨ backlog 不变量（部署模式）：顶层 `[x]` 零残留、计数器 > 全库最大编号（扫 backlog+docs/journal+docs/specs）、卡片本地链接存在、backlog 内零 archive 引用、P0-P3 节有序唯一、行数 ≤250 警告；⑩ journal/specs 命名规约：`YYYY-MM-DD-<kebab>.md` 格式校验（部署模式）
- **取舍**：check.sh 需区分源仓/部署两模式（源仓无项目 backlog）
- **为什么**：oc-beacon backlog-check.sh 六项全部是实战沉淀的机械不变量，零成本移植

## 风险与回滚

| 风险 | 影响 | 回滚方式 |
|------|------|----------|
| 重构期间交叉链接大面积失效 | 门禁 5/6 红 | 整个 v2.0 在旧结构并存期完成迁移，最后一次性删除旧目录；git revert 整个重构 commit |
| manifest 解析器遇到意外格式 | gen-index 崩溃 | 解析器报错带行号；manifest 格式约束写入 doc-governance；回退手写索引（v1.1 结构保留在 git 历史） |
| verify.md 合并后超预算 | 注意力稀释 | 预算例外已在 manifest 申报（280 行）并由门禁 2 显式认可；若仍超，将 subagent 复核协议下推 evidence.md |
| 双平面造成目标项目改文档无规范可依 | 编辑质量下降 | meta/edit-card.md 承载核心五律；完整规范按需复制 meta/ 三份（onboarding FAQ 记录该路径） |
| 三分离流转被绕过（完结不迁移/journal 事后补写） | backlog 复膨胀 | 门禁 9 机器强制零 `[x]` 残留；workflows/requirements.md 把「开工建 journal」写为验收前置；脚本 new-batch.sh 降低创建成本 |
| 脚本在目标环境不可用（无 python3） | init/check 失败 | init.sh 启动时探测并明确报缺；check.sh 各门禁可独立跳过运行（--only/--skip），文档层检查不阻塞项目本身 |

## 验证要点

1. 门禁幂等：连续两次 `scripts/check.sh` 输出一致且全绿（无状态残留）
2. gen 反证：改 manifest 一行 level 后 gen-index.py --check 必须变红；还原后复绿
3. §引用全覆盖：门禁 6 报告的已解析 §引用数 ≥ 新结构中实际 §引用总数（无漏检）
4. 旧词汇禁令：全库 grep "维度[1-5]|D[0-4] 维度" 零命中（历史文件已删）
5. init 演练：在 /tmp 试验项目跑 init.sh，产物 AGENTS.md 无 {{SYS}}/{{INDEX}}/占位符残留、链接全部可解析（部署模式 check 通过）
6. 自举检查：本 spec、4 份 ADR、CHANGELOG 均能在自家模板的字段表中逐字段对上
7. 登记演练：在 /tmp 试验项目登记一条假需求 → new-batch.sh 建 journal → 模拟完结迁移 → check.sh 门禁 9 通过且迁移后 backlog 零 `[x]`

## 变更记录

- 2026-08-21：初版，基于 DSH 技能对照评估 + 用户五项决策（双平面激进/命名化/混合脚本/e2e 拆分/spec 先行）
- 2026-08-21：追加节 6 登记三分离（backlog 索引化+journal 批次日志+spec 生命周期+CONTEXT 术语表+门禁 9/10），设计参照 oc-beacon 生产实践实证；门禁总数 8→10
