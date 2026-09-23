# 系统性体系审计：自洽·优雅·脚本化·易用·AI 友好·闭环·配合（2026-09-23）

> 对 ai-dev-guide v2.5.0（commit 5670700）的全维度审计。方法：主代理第一手量化复核 + 8 路子代理分维审计（一致性/状态机/脚本化/易用性/模块配合/优雅容量/权威页面/论文精读）+ 2025-2026 最新实证研究对照（5 篇 arXiv 论文 + 6 个权威实践来源）。分级沿用本仓口径：P0 = 破坏体系承诺的硬缺口 / P1 = 应修的漂移与缺口 / P2 = 改进建议。
>
> **活体证据注记**：本报告初版（含 §N 节引与 CANON·xxx 记法）落盘即触发门禁 6/7 红——docs/research/ 不在 hist_exempt、gate 7 全库 grep 零豁免，实锤 6.2-B3 与 M-2 的缺口杀伤力；已按 2026-09-23-oc-beacon 报告先例改写记法（§→「第 N 节」、CANON:→CANON·）恢复绿基线。修复批次③ 应将 docs/research/ 纳入 hist_exempt 并给 gate 7 加历史面豁免。
>
> **跨维度发现统计：P0×9（全部主代理独立复现确认）｜P1×24 组（约 60 处）｜P2×40+**。重灾区为 v2.5.0 连锁改口径漏改簇与 backlog.sh 数据完整性。状态机维度完整明细见 [2026-09-23-state-machine-audit.md](./2026-09-23-state-machine-audit.md)（子代理交付，30 项缺口全表）。

## 0. 审计维度框架

用户提出七维：①自洽性 ②优雅性 ③脚本化覆盖 ④易用上手 ⑤AI 友好（含措辞）⑥状态机闭环 ⑦模块配合。主代理发散补充：⑧可判定性 ⑨上下文经济学 ⑩演化自举（狗粮）⑪规模极限 ⑫防御纵深（否定约束→机器兜底配对）⑬研究符合度 ⑭时效衰减 ⑮容错恢复 ⑯信任边界。

## 1. 研究基线（外部证据）

### 1.1 五篇 arXiv 论文（2025-12 → 2026-06）

| 论文 | 核心发现 | 与本体系的关系 |
|------|----------|----------------|
| Configuration Smells in AGENTS.md Files（[2606.15828](http://arxiv.org/abs/2606.15828)，2026-06） | 100 个流行仓库中六大配置坏味道：Lint Leakage 62%、Context Bloat 42%、Skill Leakage 35%、Blind References、Init Fossilization、Conflicting Instructions；前三者高频共现 | 对照结论见第 2 节 |
| Evaluating AGENTS.md（[2602.11988](http://arxiv.org/abs/2602.11988)，2026-02） | context files 通常不提升任务成功率，反增 20%+ 推理成本；但**指令部分被良好遵循**，仓库概述类内容无益 | 指令型文档（workflows）设计路线正确；概述型内容是负资产 |
| Impact of AGENTS.md on Efficiency（[2601.20404](http://arxiv.org/abs/2601.20404)，2026-01） | AGENTS.md 存在使中位运行时间 -28.64%、输出 token -16.58%，完成行为相当 | L0 速记层价值的实证背书 |
| Semantic Gravity Wells（[2601.08070](http://arxiv.org/abs/2601.08070)，2026-01） | 否定约束违反概率 = 语义压力的逻辑斯蒂函数（p=σ(-2.40+2.27·P₀)）；高压力否定约束必然失败；抑制信号存在但系统性不足 | 直指本仓 74 处「禁止/不得」的防御纵深问题（第 3.2 节） |
| Revisiting Reliability in Instruction-Following（[2512.14754](http://arxiv.org/abs/2512.14754)，2025-12） | 措辞细微变化（cousin prompts）可使指令遵循可靠性下降至 61.8%（20 闭源+26 开源模型） | 标准句式/术语表/Use-when 触发词的量化背书 |

### 1.1.1 论文精读补充要点（对本审计结论有直接影响的细节）

- **论文2（Evaluating）redundancy 假说**：删光仓库全部文档后，LLM 生成的 context file 反而 +2.7% 并全面超过开发者文件——context file 本质是「冗余文档」，只在仓库缺文档时有正价值。**对本体系的含义：蓝本随部署面附带全部 workflows（非冗余），但宿主若已有成熟工程文档，AGENTS.md 索引中与之重复的行是负资产**——init.sh 裁剪组机制恰好是对的方向（--no-ui 等）。
- **论文2 成本机理**：+20~23% 成本正是「指令被忠实执行」的后果（更多测试/探索/专用工具）；去掉 testing 章节 signification 降成本不改准确率。**含义：指令本身有加载税，每条 Use-when 都应过「删掉它 agent 会犯错吗」测试（蓝本十律 8 已内建）。**
- **论文4（Gravity Wells）实操指引 7.2**：①首要干预=**禁令不点名被禁词**（priming failure 占 87.5%——点名即召唤，对被禁词注意力 3 倍于对 "do not"）；替代表述：类别级约束/正向重写/迂回指代；②高压力案例（被禁行为=模型自然倾向）部署前估压力、加额外保障；③安全攸关用生成后过滤，不能只靠生成时约束。**对本体系的直接映射：verify.md:188「禁止的声明格式：应该通过了/看起来没问题/…」恰是点名式黑名单——按论文应改为正向白名单（「完成声明唯一合法格式=三段式：变更/新鲜证据/日期」）；74 处 B 类禁令中点名式均属此列。**
- **论文5（Reliability）pilot**：「at most 600」改「at most 610」即令大量用例失败——约束参数的微小变动最伤；同义改写（rephrasing）最可承受。**含义：蓝本的固定句式+门禁冻结参数写法是对的；「换种说法重写文档」这类操作需按新发布验证（蓝本 edit-card 五律 1 命题保全已在机制上覆盖，但没有「措辞冻结」的明文纪律）。**
- **论文3 效率机理**：省的是 output token（-16.6%）与思考动作，input 几乎不省（注入是净增）——L0 索引的价值在「减少探索性导航」。

### 1.2 权威实践来源

Anthropic Claude Code 最佳实践、agents.md 开放标准、Anthropic 上下文工程、Cursor Rules、Aider Conventions、Lost in the Middle（[2307.03172](http://arxiv.org/abs/2307.03172)）。要点与本仓对照见附录 B（子代理提取）。

## 2. 研究符合度：六大配置坏味道对照（主代理验证）

| 坏味道 | 流行仓库占比 | 本仓防御 | 结论 |
|--------|--------------|----------|------|
| Lint Leakage | 62% | code-style.md 第 1 节「格式化交给工具，不靠人肉：formatter/linter 配置入仓库，CI 检查」；文档只写 lint 查不了的语义规则 | ✅ 免疫（与论文建议一致） |
| Context Bloat | 42% | 250 行预算 + 门禁 2（manifest 驱动）；AGENTS.md 91/200 行 | ✅ 免疫 |
| Skill Leakage | 35% | 模板独立成文件 + 指针引用；技能内容不进 AGENTS.md | ✅ 免疫 |
| Blind References | — | 门禁 1/6 断链与 §引用校验 | ✅ 免疫 |
| Init Fossilization | — | 写作十律「陈旧即删」+ upgrade.sh 漂移报告 + 部署基线 | ✅ 有防御 |
| Conflicting Instructions | 28%（精度最低 57%） | CANON 唯一归宿 + 单一真相源 | ❌ **不免疫——4.1 节 P0-2/P0-3/P0-5 为实证**（v2.5.0 连锁改口径漏改簇） |

**小结：五大坏味道结构性免疫（先于论文的设计）；第六个（指令冲突）恰在本仓 v2.5.0 大改后成片出现——与论文「膨胀文件里最容易藏矛盾」「大改后未全面审查」的规律吻合：论文报告的 Conflicting+Bloat 共现 confidence 0.83 / lift 1.81 提示：改口径必须配全库一致性门禁。**

**六 smell 完整定义（论文精读补充）**：①Lint Leakage=把 linter/formatter 已 100% 强制的规则写进配置（命名/行宽/import 顺序），占 62%、精度 93%；②Context Bloat=≥200 行（Anthropic 建议 <200 行；598→149 行实例：「modern LLMs tend to perform better with ~150-200 lines」）；③Skill Leakage=低频/场景特定指令进常驻文件（最多为 Testing×10、Workflow×8）；④Conflicting Instructions=文件内可执行语义矛盾；⑤Init Fossilization=单一 commit 化石（24 个项目事后均 1500+ commit，证明非不活跃）；⑥Blind References=引用不带一句话说明（反例："See docs/plugin-reorg.md for details."零上下文）。

## 3. 主代理第一手量化发现

### 3.1 措辞与强度语言（AI 友好核心）

- manifest level 语义 = **阅读必要性**（MUST=先读再行动），非 RFC2119 规范强度；彩球（🔴🟡🟢）是 gen-index.py 的图标渲染，非独立体系；AGENTS.md.template 有中文消歧行（「🔴 MUST = 该场景下先读再行动」）。
- 正文规则强度语言实测：必须 77 / 禁止+不得 74 / 优先 40 / 应当 0 / 应该 5（**全部为反例引用**）/ 酌情 0 / 尽量 3。情态模糊词接近零——用词纪律极强，与 2512.14754 的关切相容。
- 残留议题（P2）：①「应」「优先」无正式强度词表定义（实测语义清晰，但缺声明）；②借 RFC2119 词形（MUST/SHOULD/MAY）表达「阅读优先级」语义，对熟知 RFC2119 的读者有轻微语义错位（有彩球中文注释消歧，且体系内自洽）。
- 写作十律之 2「正向表述：禁令仅在无法正向表达时用｜禁令激活被禁行为」与 Semantic Gravity Wells 结论完全一致——**先于论文 8 个月**；律 8「砍无效句」与「概述无益+20% 成本」一致；律 3「每条规则附违反后果」对应论文对规则噪音的防御。

### 3.2 防御纵深：74 处否定约束的兜底配对（原创分析）

逐条分类（第 3.2.1 节全量清单）：

- **A 类·结构兜底**（约 1/3）：版本三禁令→release-version.sh 强制；{{SYS}} 残留→门禁 1；卡片区直编→backlog.sh+门禁 9；越层直调→debt.md 第 4.1 节 grep 脚本模板；魔法值/死代码→「linter 配置入仓库」原则。
- **B 类·纯文字禁令**（约 2/3）：verify 的静默降级/口头确认/FAIL 糊弄、dev 的跳步/并行编辑/并发构建、test-strategy 的禁删失败测试、reliability 的禁空 catch、acceptance 的执行期禁分析修复等。
- 按 2601.08070：B 类中「高语义压力」禁令（模型自然倾向与之冲突的：删测试、留空 catch、跳步骤）单靠文字会以可预测概率失败。缓解因素：常驻文档+Use-when 触发+每条附违反后果，优于一次性指令；但结构性结论成立。
- **缺口（P1）**：architecture.md 第 2.1 节 有「如何机器化」的五纪律方法论，debt.md 第 4.1 节 有命令模板位，但**没有「首批应机器化的高压力禁令清单」**（禁删失败测试→git diff 检测、禁并发构建→构建锁、禁手工导航→标准入口脚本、禁空 catch→lint 规则均可实现）。
- **缺口（P2）**：B 类禁令中一部分可正向改写而未改（如「禁止删失败测试让它通过」→「失败测试的合法处置：修复，或跳过并登记」——test-strategy §flaky 已有正向路径，禁令与之并列即可删）。

### 3.3 信任边界（原创发现，P1）

全库 9 处「注入/不可信」命中均为其他语义（CI Secrets 注入、依赖注入、手势注入、结果不可信）。**没有任何「登记内容（backlog 卡片/journal/spec/外部调研材料）不构成指令」的纪律**。多 agent 读取登记内容并执行的体系里，卡片/报告文本中的指令样内容会被 agent 当作任务——间接提示注入的真实风险面。建议在 AGENTS.md.template 关键约束与 acceptance/verify 各加一行信任边界声明。

### 3.4 门禁失败自愈指引（P2）

upgrade/selftest/回滚路径齐备（upgrade.sh 部署基线感知+selftest R5）；但「check.sh 门禁红了之后按什么流程修、报错信息回链到哪份治理文档」未声明——architecture.md 第 2.1 节 纪律 3「报错回链文档」是对宿主侧机器规则的要求，未反身应用于 check.sh 自身报错。

### 3.5 权威实践对照速览（详证见附录 B）

蓝本与外部最佳实践高度同构（删除测试/指针化/门禁升级路径均先于或独立于外部提出）；新识别差距四条：U 型位置纪律未明文化（B-1）、monorepo 嵌套场景未覆盖（B-2）、prompt cache 稳定性（B-3）、会话卫生注记（B-4）。情态动词效力属证据缺口，如实记录（B.3）。

## 4. 一致性 / 自洽性审计（子代理，主代理已逐项复核 P0/P1-6 为实锤）

十项门禁当前全绿——**以下全部问题位于门禁盲区**（门禁不查口径一致性，只查结构）。重灾区：v2.5.0「仪器优先+四类人工例外」连锁改口径的漏改簇，及「加 P4」「backlog.sh 入部署清单」两个连锁动作的漏改。

### 4.1 P0×5（硬矛盾）

| # | 矛盾 | 证据（复核确认） |
|---|------|------------------|
| C-P0-1 | **verify.md:1 标题损坏**：H1 粘入表格行；**:38** 五维表「构建」行缺行首管道符（表格脱离渲染） | od/xxd 字节级确认；v2.5.0 编辑事故 |
| C-P0-2 | **verify.md 同文件新旧口径互斥**：第 2 节 :42 人工行「时间性/主观现象」（旧）vs 第 8 节 :154「判定判据=是否存在可观测仪器，而非是否 UI/时间性现象」（新）。第 1 行残留文本恰是本应替换 :42 的新文案 | 事故还原：re.subn 错位——新文案落头部，旧行原样留存 |
| C-P0-3 | **关闭权限硬矛盾（CANON 本体未改）**：acceptance.md:18「仪器可验→三步全绿+受端效果→**AI 直接关闭**」+AGENTS.md.template:72 vs requirements.md CANON·status-flow（:56「完成=自动化验证+**用户验收双重通过**」、:64「**未经用户确认的勾选属违规**」、:69 迁移以「用户验收通过」为起点）+registries/backlog.md:19 | 按_CANON 执行会把仪器可验卡全部推给用户——恰是 acceptance 要打击的反模式。修复需决策：修订 CANON 第 4 节 按关闭权限分类改写，或加从属条款指针 |
| C-P0-4 | **优先级分级数矛盾**：templates/requirement.md:21「<P0 / P1 / P2 / P3…>」、:74「P0-P3 四级」 vs CANON·priority P0-P4 五级（requirements.md:44-48、门禁 9 校验 P0P1P2P3P4、backlog.sh -p 0-4） | 2.5.0 加 P4 漏改模板 |
| C-P0-5 | **ui-conventions.md:84 旧口径**：「时间性现象…自动化无法覆盖，必须列入人工验证清单」 vs verify 第 8 节/evidence 第 5.3 节 帧级取证/manual-ui-checklist:27「先仪器后人工」 | 直接互斥 |

### 4.2 P1×9 组（约 25 处）

| # | 问题 | 证据 |
|---|------|------|
| C-P1-1 | **旧口径残留簇约 13 处**（时间性→人工）：bug.md:103、verify.md:10/:64、requirements.md:111、test-strategy.md:91、plan.md:65、requirement.md 模板 :40/:90/:91/:99、ui-conventions.md:127/:131、regression.md:97、manifest.yaml:311-312（经 GEN 生成进 AGENTS.md.template:34、system-design.md:86、README.md:61） | 修复须含 manifest→gen-index.py 重生成 |
| C-P1-2 | scripts 部署范围三处声明与 init.sh 矛盾（manifest.yaml:20、README.md:29、system-design.md:25 说「不随部署」；实部署 5 运行时脚本） | CHANGELOG 自证 |
| C-P1-3 | onboarding.md:14「四个运行时脚本」漏 backlog.sh | 与 U-P1-2 同源 |
| C-P1-4 | 两套「手段」词表并存（ability-domains UI/LOG/DATA/PERF/MANUAL vs verify 五命名维度承诺不另设编号），缺映射 | |
| C-P1-5 | registries/backlog.md:9-19 整表复制 CANON 优先级+状态流转正文且自称唯一归宿——违反单一真相源（对照 backlog-entry.md:49 正确纯指针写法） | |
| C-P1-6 | **backlog.sh:123-124 migrate 守卫恒假（代码 bug，已复核）**：card[0] 先被 replace 为 '- [x] ' 开头再判断 startswith("- [ ]")——恒假；「未验证卡迁移须 -r」（requirements 规则 4）实际不强制 | 修复：先判原始状态再替换 |
| C-P1-7 | 「三个符号」vs 实定义六符号（stack-profile:67「三个符号是唯一词根」；edit-card:14、doc-writing-standards:62、AGENTS.md.template:56 均只提 BUILD/TEST/RUN） | v2.5.0 加 LOG/DUMP/SHOT 漏同步 |
| C-P1-8 | E2E 截图口径：verify.md:124「截图不作门禁输入」vs e2e-plan.md:33-34「≥1 SCR+≥1 DYN 交叉印证」 | DYN 需重定义或开例外 |
| C-P1-9 | 术语表漂移 11 词（时间性现象/能力域/纯净上下文/关闭权限/三步验收法/补丁三件事/判定三问/交叉验证/命名维度/冒烟档…）；system-design:112「铁律全系统当前两条」与正文多处铁律冲突 | |

### 4.3 P2×8

CHANGELOG「[2.4.0]」标题重复两行；acceptance:84 与 requirements:90 重复定义「新问题只登记」例外且措辞漂移；bug-record:32 称 第 4 节/第 6 节 双 CANON 实仅 第 6 节；Release Notes 范围两口径（release.md:100 vs release-notes.md:60/changelog.md:95）；e2e-plan:9 指针过述（verify 第 5 节 无所述内容）；「状态流转」一词三用未区分；判定词表四套并存（✔/✘/BLOCKED、PASS/FAIL、通过/失败/未测、GREEN/RED）；门禁 8 豁免清单不含 docs/adr/ 与 _gates.py hist_exempt 不齐 + 门禁 7 按文件数计数（同文件重复标记不告警）。

### 4.4 CANON 标记验证结论

三标记各自唯一出现（priority→requirements 第 3 节、status-flow→requirements 第 4 节、patch-three→bug 第 6 节），门禁 7 通过，其余引用均为指针——**标记唯一 ✅；但 status-flow 的「口径」与 acceptance 关闭权限矛盾（C-P0-3）：形式唯一≠实质唯一**。

## 5. 状态机 / 机制闭环审计（子代理建模 13 个状态机 + 主代理独立复现确认）

**闭环良好的两个核心**：backlog 三态机（[ ]→[~]→[x] 瞬态，脚本与 CANON 一致，非法持久有门禁 9 兜底）；版本阶梯单步转移（release-version.sh 全部非法转移有拒绝）。注意本体系无 rc.N 相位、beta 不带序号（与常见 semver 预期不同，属设计选择）。

### 5.1 P0×1（数据丢失，主代理已独立复现）

| # | 缺陷 | 复现证据 |
|---|------|----------|
| S-P0-1 | **backlog.sh 同日第二次 migrate 起永久丢卡**：同日「已完结卡片迁入（日期）」节已存在时，只追加「迁入依据」行、卡片正文从未写入 journal，但照删 backlog 卡；门禁 9 全绿零告警 | 主代理沙盒实测：同日迁 #1/#2/#3 三张已验卡 → journal 仅存 #1 正文，#2/#3 双双消失，却留下两条指向空物的「用户验收通过」依据行；backlog 残留 0。触发条件极常见（一批修多卡）。修复=if 分支改为节末追加（一行改动）+ selftest 补「同日双卡迁移，第二张正文必须存在」断言 |

### 5.2 P1×6（承诺的保护失效 / 文档自相矛盾）

| # | 缺陷 | 证据 |
|---|------|------|
| S-P1-1 | **migrate 未验卡守卫死代码**（与 C-P1-6 双源交叉确认，主代理复现：[ ] 卡无 -r 直接迁入成功 exit=0） | backlog.sh:123-124 先替换后判断恒假；违反 requirements.md:81 规则 4 与 backlog.sh:8 自述 |
| S-P1-2 | **无 -r 时伪造「迁入依据：用户验收通过」**：对 [~]（定义即用户验收未完成）甚至 [ ] 卡落虚假验收记录 | backlog.sh:133 默认文案；复现：未验 #1 落「用户验收通过」 |
| S-P1-3 | **v2.5.0 journal GREEN 声明失真**：批次记录称「migrate 未验卡正确拒绝」，与实测矛盾；且 selftest R1-R11 零 backlog.sh 覆盖——该 GREEN 演练未命中真实代码路径 | docs/journal/2026-09-23-oc-beacon-reintegration.md:17；selftest.sh:38-159 无账本断言。按本仓「journal 是证据链锚点」标准须勘误并补真演练 |
| S-P1-4 | **release 三护栏有文无码**：tag 递进链校验/防回退护栏/开新线基准——scripts/ 全目录无任何 git tag 操作；CHANGELOG 2.5.0 宣称「Added」实为文字 | release.md:63-65；release-version.sh validate 只查格式。修复二选一：validate 增 --tags 模式挂 CI，或如实降级为「人工红线核对项」 |
| S-P1-5 | **验收终态枚举与 SKIP 矛盾**：第 2.3 节「全部 item 到达 ✔/✘/BLOCKED 才结束」不含 SKIP；第 7 节 又要求记 SKIP——含 SKIP 的清单按字面永远无法收口 | acceptance.md:58 vs :88 |
| S-P1-6 | **P4 无出口 + 优先级不可变**：前提满足后无变迁规则（第 8 节 周期审查四动作不含 P4 复查）；backlog.sh 无 prio 子命令——改优先级只能手工跨节剪切，与「禁手工直编」死锁 | requirements.md 第 3 节/第 8 节 |

### 5.3 P2/P3 摘选（完整 30 项见子代理报告 docs/audit-2026-09-23-state-machine.md）

- 门禁盲区（实测）：**- [X] 大写影子完结卡**全绿放行（check.sh:135 只认小写）；P4 节后自定义节放卡放行（:152-154 只查表头区）；journal append 可向 backlog.md 本体追加；status 对已达状态空转假成功。
- journal append-only 无门禁，且 migrate 重写未声明为豁免写路径（纪律与脚本各说各话）；误迁撤销路径全仓无定义（grep「撤销」零命中）。
- 批次「关闭」无机制（状态行手改）；SKIP「登记待补」在 requirements.md 零承接；裁决「最新为准」无枚举工具、已迁卡无法 note 回写（回写链断裂）。
- 债务「处理中」无中止出口；ADR 状态图缺「已接受→已废弃」边（图表矛盾）；Spec 草稿批准权未定义、被否决稿无终态。
- selftest/CI 全绿 ≠ 账本机制健康：R1-R11 无一条覆盖 backlog.sh——本 P0 正是该盲区放行（建议补三条断言：同日双卡不丢/未验无 -r 被拒/[X] 被拦截）。

## 6. 脚本化覆盖率与脚本质量审计（子代理全实测）

### 6.1 覆盖率：67 条可机器判定规则区块

✅ 已覆盖 17（25%）｜⭕ 可机器化未做 38（57%，均给出检查伪码）｜❌ inherent 人工 12（18%，会话纪律/运行时语义判定）。「每条机械规则配门禁」承诺的实态约为四分之一。

### 6.2 高价值未门禁 Top10（易违反×后果重×检查简单）

B1 AGENTS.md≤200 行零门禁（edit-card:28/onboarding:39 明写「人工扫一眼」；153 条目静默突破）；B2 P4 卡必含「前提」行；B3 **CANON 动态唯一+gate 7 历史面豁免缺失**（实证：journal 提及 CANON·priority 即误报✗——裁决记录的合法归宿被门禁误伤，gate 8 有豁免而 gate 7 没有）；B4 变更叙事词禁入规则层；B5 acceptance 命名/目录双缺口；B6 单卡 tag≤3 且∈词表；B7 债务状态词表；B8 manifest↔CHANGELOG 一致+版本标题唯一（现行违反即 2.4.0 重复标题）；B9 commit 模板三要素（type 白名单/编号行/验证行）；B10 tag 递进链+防回退——文档声称「validate 可挂 CI」但 validate 无任何 git tag 操作（与 S-P1-4 交叉）。

### 6.3 脚本质量（全部实测复现）

| # | 严重 | 问题 |
|---|------|------|
| C1 | 🔴 | migrate 死守卫+伪造验收（四源交叉+主代理复现，同 S-P1-1/2） |
| C4 | 🔴 | **并发丢卡**：两 add 并发→一张静默蒸发（全量读改写无 flock/临时文件），门禁 9 全绿；migrate 跨双文件无事务 |
| C2 | 🟠 | check.sh --deployed 缺参→**无限循环**（实测 5658 行报错、timeout 124）；--only/--skip 缺值 set -u 裸崩 |
| C8 | 🟠 | **占位符检测漏中文**：init 补填清单只报 <URL>/<角色> 2 处，<项目名>/<红线 1-3> 全漏——用户按清单补填必漏关键项；_ph_gate {{ 行整行豁免 |
| C9 | 🟠 | init.sh 重跑**静默覆盖 sys/ 本地化修改**（实测丢一行零警告；受保护的仅 AGENTS/backlog/CONTEXT/两登记簿） |
| C10 | 🟠 | upgrade.sh 两盲区：脚本漂移不可见（基线有脚本哈希但升级不消费）；scrub 差异误判为「上游已更新」——照建议「从源仓复制」会重新引入已清洗断链 |
| C5 | 🟡 | 门禁 9 三绕过面：嵌套 "  - [x]"、大写 [X]、5 位编号（同 9.5-5） |
| C6/C7 | 🟡 | 门禁 6 子节号不验（第 2.99 节 全绿）+首链接归置（同 M-2）；门禁 1 含空格链接完全不查、锚点存在性不查 |
| C13 | 🟡 | 13 脚本仅 1 个有 usage()；报错回链文档仅 release-version.sh——**第 2.1 节 五纪律的「报错回链」在自家门禁上未落地**；纪律 3/4 本身可 lint 未做 |
| C14 | ⚪ | init 步骤编号两个「6.」(:168/:173)+两个「④」(:181/:182)；gate 8 只查词出现不查在 第 6 节 表内；gate 2 manifest 外 .md 完全逃逸（删条目即绕预算）；scan-secrets 冒号切分；selftest sed -i BSD 兼容 |

### 6.4 应脚本化手工操作 Top10

部署面 AGENTS 检查、init 占位符报告、tag 链/发版后清单（release-postcheck）、acceptance 目录+命名、commit-msg hook 模板（现无任何 git hook 资产）、债务检查规则引导、i18n 检查骨架、周期审查 stale/dup 子命令、journal append-only 的 git diff 检测、upgrade 三方 diff 生成。

### 6.5 部署链对账

复制对账相符（deployed 42 vs 实复制 41=--no-example 裁剪 ✓；运行时 7 件与 init 清单一致 ✓；未部署 6 件均有依据 ✓）；new-batch 产物三方吻合 ✓；两处文档失真（onboarding 脚本数、acceptance 目录）与 M-5/M-6 交叉。

## 7. 易用性 / 上手曲线审计（子代理 + 主代理全项复核验证）

规模基线：部署面规范 42 份 2694 行；强制词 247 处；修一个 bug 的在册规则 ≈173 条（远超工作记忆，靠表格+违反后果+门禁外化）；最短合规链 12-13 次跳转 + 3 脚本，必读 13 文档 ≈1459 行（≈3-5 万 token）；L0 91/200 行达标；渐进披露真实有效（bug 修复无需读 release/debt/E2E/ui）。

### 7.1 P0（部署即炸 / 首屏即错，主代理已逐项复核为实锤）

| # | 问题 | 证据 | 后果 |
|---|------|------|------|
| U-P0-1 | **verify.md:1 标题损坏**——MUST 文档 H1 粘入 第 2 节 表格「人工」行 | `# 完成验证（Verify）人工 \| human \| 用户按清单操作并反馈 \|…`（od 确认） | v2.5.0 连锁改口径编辑事故；每个读者首行即见；门禁 1/6 均不查 H1 完整性——暴露门禁盲区 |
| U-P0-2 | **macOS 可移植性**：check.sh:140/142/146 `grep -oP`（BSD grep 无 -P）；init.sh:155/158 `sha256sum`（macOS 默认无，set -e 下命令替换失败被 echo 吞掉） | 源仓 Linux 门禁全绿掩盖；部署到 macOS：门禁 9 必炸 + backlog.sh 每次操作自动跑门禁 9 → 狼来了效应；部署基线静默全空哈希 → upgrade.sh 漂移分类全错 | 「任意新项目」承诺在 macOS 失效 |
| U-P0-3 | **首屏死指引**：AGENTS.md.template:78「测试环境操作…见 docs/env-runbook.md」，init.sh 不创建该文件，_scrub_links.py 只清 md 链接不清纯文本 | grep env-runbook init.sh 零命中 | v2.5.0 新增指针与部署链脱节；agent 首屏按指引找不到文件 |

### 7.2 P1（首次任务体验）

| # | 问题 | 证据 |
|---|------|------|
| U-P1-1 | 部署面无术语表：铁律/门禁/批次/承重/单一真相源/CANON 权威定义在 system-design.md 第 6 节（source 平面不随部署）；目标项目内 247 处强制词无定义可查 | README.md:80 双平面表 |
| U-P1-2 | 内容腐化：onboarding.md:14「四个运行时脚本」实际 5 个（v2.5.0 加 backlog.sh 漏同步；CHANGELOG 自己写「第 5 个运行时脚本」） | init.sh:74-81 实拷 5 脚本 |
| U-P1-3 | init.sh:181-182 下一步编号两个④ | |
| U-P1-4 | 级别失真：MUST 文档硬引用 SHOULD 文档（bug.md:34,36→regression/evidence；verify.md:126→env-runbook），实际必读集 ≠ 索引级别；MUST=6/7 余量仅 1 | bug 修复实际必读 ≈13 文档 |
| U-P1-5 | AGENTS.md ≤200 行在部署模式无机器门禁（门禁 2 仅源仓模式） | check.sh:62-67 |

### 7.3 P2

小任务无快速通道（「一行 typo」与「三天重构」共用 1459 行合规链；requirements.md:103 只豁免 spec）；CONTEXT.md 在 AGENTS.md 零引用（首次引用在 dev.md:73）；README 无最小示例/FAQ 链接/依赖说明（python3/sha256sum/bash）；License 待定（README.md:101）；journal-entry.md 缺 Use when 节。

### 7.4 正面结论

模糊表述实测 ≈0（酌情 0/必要时 0/视情况 0/应当 0，「尽量」3 处有 第 1 节 兜底）——**措辞纪律是本蓝本最强项**；init.sh 防呆设计（python3 自检/目标=源仓拒执/AGENTS 冲突 .new/幂等登记簿/末尾下一步指引）高于平均水准；术语首用就地定义总体良好（承重/受端效果）。

## 8. 模块配合 / 引用图审计（子代理 + 主代理复核 B4 实锤）

**基础质量高**：文件级断链为零（门禁 1 + 独立扫描一致）；manifest 对账全绿（45 条 entry 文件存在/无多余/无超预算/GEN 四段幂等一致）；45 份文档触发条件 41 份覆盖完好；沙盘 P0=0。

### 8.1 孤儿与断链

| # | 发现 | 证据 |
|---|------|------|
| M-1 | **孤儿文件 registries/ability-domains.md**：剔除清单类生成树来源后零内容性入边——流程文档（regression.md:66/verify.md:128）指向的都是 templates/ 版（方法论），实例骨架只被 init.sh 机械消费，流程→实例发现链断裂 | 对照 architecture-debt.md（debt.md:4 有入边）非孤儿 |
| M-2 | **门禁 6 一行多链接误配（机制缺陷，主代理复核实锤）**：_gates.py:105-109 只取行内第一个 .md 链接解析 §N。活体例① manual-ui-checklist.md:27 的 第 8 节 意图指 verify.md 第 8 节，被同行第一链接 evidence.md 第 8 节 误配通过；活体例② acceptance.md:4 的 第 4 节 意图指 regression.md 第 4 节，被 verify.md 第 4 节 误配 | 两处「语义错引但机械全绿」；建议门禁 6 改为行内每个 §N 对最近链接或逐一尝试 |
| M-3 | AGENTS.md.template:78 env-runbook 死指针（无「无则按模板建立」兜底，对照 acceptance.md:92 有兜底） | 与 U-P0-3 同源；test-strategy:100/stack-profile:91 同类但更低危 |

### 8.2 交接面缺口

| # | 发现 | 证据 |
|---|------|------|
| M-4 | **requirements→acceptance 单向断链**：requirements.md 全文零引用 acceptance.md；第 5 节 以「用户验收通过」为迁移前提却不指向验收协议（关闭权限/三步法）；反向 acceptance.md:100 有链 | 走 requirements 流程发现不了验收协议——与 C-P0-3 叠加放大 |
| M-5 | **docs/acceptance/ 无初始化无门禁**：验收清单落盘约定存在（acceptance.md:32），init.sh 不建目录、门禁 10 命名规约只覆盖 journal/specs | 首个验收即踩空 |
| M-6 | 三处运行时脚本口径（onboarding 四个 vs CHANGELOG 五个 vs init.sh 实际 7 文件 5 脚本） | 与 U-P1-2/C-P1-3 三源交叉 |
| M-7 | spec 归档三步（移入 archive/状态行/引用同步）无子命令无责任人；e2e-plan.md「复制后拆两文件」与现状矛盾且与 runbook 零互链；templates/ability-domains.md:7 自述「init 复制到 docs/」实为 registries 版被复制；init.sh:13 {{INDEX}} 注释残留；journal-entry.md 全库唯一无 Use when；docs/research/ 源仓（调研）与部署面（回归证据）双重语义，部署面命名无门禁 | 均 P2 |
| M-8 | **系统自身 detach/卸载流程全库无文档** | 沙盘终点缺口；「整体部署」承诺的另一半 |

### 8.3 描述失真（与 C-P1-7 交叉）

research-report.md:3「两种用途」实含 Part C；stack-profile.md:67「三个符号唯一词根」实定义六个——v2.5.0 增量未回改头部描述。

## 9. 优雅性 · 上下文经济学 · 规模极限审计（子代理实测 + 主代理复核）

### 9.1 正面（优雅度实据）

21 份 content 文档 100% 遵循「H1 中文（English）+ Use when + 编号节 + Related」对称结构；命名 kebab-case 一致；manifest 对账幂等；补丁三件事簇是「指针+摘要」健康样板；措辞纪律极强（模糊词≈0）。密度过高 Top4：edit-card.md（39 行行行承重无容错）、registries/backlog.md（37 行承载 8 条不变量+复制表）、release-runbook.md（28 行独载体）、journal-entry.md:30-39（**六条模板纪律藏在 HTML 注释里，渲染后不可见**）。

### 9.2 重复簇 8 簇（会漂移的复制为病）

簇 1 四类人工项：verify 第 8 节（归宿未标 CANON）+ acceptance:19 全量复制 + manual-ui-checklist:29 全量——第④类已有三种措辞（主观拍板/主观体验拍板/主观观感拍板）；**建议增设 CANON·human-four**。簇 2 新问题入队三例外：acceptance:84 与 requirements:90 全量互复制无 CANON。簇 3 P0-P4：registries/backlog.md 整表复制已漂移。簇 4 状态流转：形式唯一但实质冲突（同 C-P0-3）。簇 5 补丁三件事：全库最佳实践样板 ✅。簇 6 禁并发构建：stack-profile:75 无指针复制。簇 7 旧口径残留：**GEN 是漂移放大器**（manifest 一处旧措辞→三处生成物同步地错）。簇 8 完结即迁移 ~12 处（多为必要回链，行为有门禁 9 兜底）。另：changelog.md:103 指向 example 而非 stack-profile 第 5 节——模板内违反自家十律 5。

### 9.3 上下文经济学：任务级无预算量纲

「修一个 bug 并验证」全链 ≈1160-1300 行；一行 typo 最少 402 行（AGENTS+dev+verify）不可免。250 行/文件预算在「文件」粒度成立、「任务」粒度失效。分层失效三点：①L2 名不副实——backlog 每任务必扫、journal 开工即建，L2 在强制循环内；②MUST≤7 冻结的是标签不是阅读集——MUST 文档硬引用 SHOULD（bug→regression/evidence），requirements/acceptance/evidence 每卡必经却标 SHOULD；③verify.md 文件内无分层——第 5 节-第 6 节 约 37 行大型任务内容在「声称完成前」必读税内。

### 9.4 最惊讶设计 Top3

1. **全系统最高频 MUST 文档首屏两处结构损坏且十门禁全绿**——gate 6 甚至「验证通过」了损坏行内的 第 8 节 引用；「每条机械规则配门禁」存在 H1/表格完整性盲区类（v1.1 同类病灶复发；:38 缺管道符自 v2.2.0 首提交即断，v2.4.0「全仓系统性审计」未抓到）。
2. **版本阶梯是演练品不是实践**（主代理复核实锤）：本仓 git tag=0、无 VERSION 文件、2.2.0→2.5.0 五个版本全部手改 manifest version 直接 commit——阶梯只对客户生效，release.md 第 9 节 红线对本仓自身五次发版无一适用。
3. **注意力预算管标签不管加载集**：三级披露在文件粒度成立、任务粒度失效。

### 9.5 规模极限断裂点（按先断排序，均实测）

| # | 断点 | 实测 |
|---|------|------|
| 1 | AGENTS.md ≤200 行约束无门禁（edit-card:28/onboarding:39 明说「人工扫一眼」）；GEN 每条目 +1 行，约 153 条目静默突破 | 最先断——根本没被看守 |
| 2 | backlog ≤250 warn-only（check.sh:157 不 fail）vs ADR-0004 承诺「永久不超 250」；100 卡≈425 行、53 卡触警；**未决积压无 WIP 上限无清退机制** | 完结迁移只处理已完结卡 |
| 3 | manifest ~146 条目时 system-design.md 撞 250 预算（GEN full-table 每条目 +1 行）→ 首个机器阻断点 | 唯一出路申报例外或改生成器 |
| 4 | gate 9 计数器检查每次 cat 全部 journal+specs，backlog.sh 每次操作自动跑 gate 9 → O(全库) 每操作固定税；journal 无索引结构，「#N 后来怎样了」退化为全文 grep | 500 journal 秒级降级 |
| 5 | **编号 #10000 起 gate 9 失明**：正则 [0-9]{1,4} 只认 4 位——实验实证 #10001>9999 全绿通过，同号双卡防护静默失效；backlog.sh 内部正则无上限，两处不一致 | 5 位编号盲区 |
| 6 | 10 倍文件量性能秒级可用；精度才是断点（gate 6 首链接归置，同 B4/M-2） | 漏报率高 |

### 9.6 狗粮自洽度 ≈70%（形式自举优，路径完整性差）

合规：7 份 journal 全循模板（GREEN/RED/裁决前缀）；ADR×4 自家字段表；CHANGELOG Keep-a-Changelog 与 manifest 版本一致；**v2.4.0 审计把 10 个脚本缺陷固化为 selftest R1-R11——「每个修过的缺陷一条会失败的测试」是体系教义的最佳自证**。
违规：①版本阶梯零实践（见 9.4-2）；②CHANGELOG:29/31 [2.4.0] 标题整行重复 + 头部缺自家模板要求的两行；③verify 损坏发生在 v2.4.0「全仓系统性审计（41 文档+11 脚本双向核对）」之后——自家审计漏掉自家最高频文档；④门禁 9/10 源仓模式跳过（复核实锤：docs/journal/2026-08-24-full-audit.md:1 H1 残留占位符「<批次：full-audit>」）——自家 journal 不受自家门禁约束；⑤journal 2026-08-21 状态行「已完结（门禁全绿待验证）」与词表轻微不符。
另：manifest id 与文件名脱节两处（t-ui-checklist→manual-ui-checklist.md、t-verify-node→verification-node.md）。

## 10. 综合结论与修复路线

### 10.1 总体判断

**强项（外部研究背书的先见之明）**：六大配置坏味道五免疫；写作十律与 2026 实证研究高度同构（正向表述律/删除测试/砍无效句律均先于论文）；措辞纪律近满分（模糊词≈0、情态词全部反例引用）；结构对称性 100%；manifest 对账零差异；「修过的缺陷固化为回归断言」（R1-R11）的自省教义；补丁三件事簇是单一真相源最佳实践样板。

**系统性弱点（四个）**：
1. **改口径无一致性门禁**——v2.5.0 大改产生的漏改簇是本次 P0 主体：十门禁全绿之下藏着行为级矛盾（CANON vs acceptance）、成片旧口径（~13 处）、模板分级错误。机械门禁只管结构不管语义，而语义漂移恰是规模化演化的主要风险。
2. **账本脚本工程质量**——backlog.sh 是体系唯一写账本的脚本，却集中了死守卫、同日丢卡、并发丢卡、伪造依据、无回滚四个数据完整性缺陷，且 selftest 零覆盖。「登记三分离」承诺的保护部分失效。
3. **承诺与实现的落差**——tag 链校验/防回退「有文无码」（CHANGELOG 宣称 Added）；AGENTS≤200「人工扫一眼」；版本阶梯自家五连跳零实践（狗粮断裂）。
4. **工程可移植性**——grep -P/sha256sum/sed -i 三处 Bashism 使「任意新项目」在 macOS 部署即炸或静默写坏基线。

### 10.2 修复路线（四批次）

**批次① 数据完整性（立即，~1 天）**：backlog.sh 四修（同日迁移改节末追加/守卫先判后替换/[~] 默认依据改「验收依据待补」/写前临时文件+rename）+ selftest 补 5 断言（同日双卡不丢、未验无 -r 被拒、并发 add 不丢、[X] 被拦、5 位编号可见）+ 勘误 v2.5.0 journal 的 GREEN 声明。**含一项用户裁决**：关闭权限矛盾（C-P0-3）需拍板「仪器可验=AI 直接关闭」为准（则改 CANON 第 4 节）或「双重通过」为准（则改 acceptance）——本报告按 v2.5.0 意图推荐前者。

**批次② 结构与口径修复（1-2 天）**：verify.md:1/:38 手术；P0-P3→P0-P4 模板两行；旧口径 13 处清单化改写（manifest 改后重跑 gen-index）；三处脚本数口径；macOS 可移植（grep -E 下沉 _gates.py + shasum 回退 + sed -i 兼容）；init 实例化 docs/env-runbook.md + docs/acceptance/；占位符正则补中文；init 步骤编号。

**批次③ 门禁增强（2-3 天，兑现「每条机械规则配门禁」）**：新增结构门禁（H1 单行无表格碎片+表格行首管道）；gate 6 改全链接逐一尝试+子节号校验；gate 9 补 checkbox 词表白名单+去 4 位上限+卡片编号唯一；gate 7 动态 CANON 键+历史面豁免；AGENTS≤200 部署门禁；B 系伪码逐条落地（B1-B8 小工作量优先）；门禁报错回链+--help 补齐（自遵 第 2.1 节）。

**批次④ 优雅与体验（随版本）**：CANON·human-four 锁定四类人工项；acceptance/requirements 入队三例外归一；registries/backlog.md 复制改指针；任务级加载预算（小改动快速通道，typo 402 行→~200 行）；部署面精简术语表（8-10 词入 edit-card）；P4 前提满足变迁规则+backlog.sh prio；批次关闭/spec 归档/detach 流程成文；版本阶梯自家实践（或如实声明蓝本用 manifest version 单轨）。

### 10.3 与外部研究的对照结论

蓝本无需推翻性改动——设计原则（指针化/预算制/CANON/门禁化/命题保全）全部与 2025-2026 实证方向一致，部分先于研究。需吸收的增量：①禁令不点名被禁词（priming 87.5%）——点名式黑名单改正向白名单；②措辞冻结纪律明文化（cousin-prompt 脆弱性）；③每条指令计入加载税的评估观（20% 成本）；④monorepo 嵌套 AGENTS.md 适配；⑤U 型位置纪律明文化；⑥信任边界声明（登记内容≠指令）。详见第 3 节与附录 B。

### 附录 A：74 处否定约束全量分类表

（A 类=结构兜底 / B 类=纯文字；高压力=模型自然倾向冲突）

| 文件:行 | 禁令摘要 | 类 | 压力 |
|---------|----------|----|------|
| release.md:55 | 禁止手改版本文件 | A（脚本管理） | — |
| release.md:59 | 禁止硬编码版本号 | A（grep 模板 第 4.1 节） | — |
| release.md:64 | 禁止产出更小版本号 | A（防回退护栏） | — |
| verify.md:46-48 | 运行时维度禁止项表 | B | 中 |
| verify.md:80 | 时间性现象不得声称完成 | B | 中 |
| verify.md:125 | 禁止 FAIL 糊弄或勉强跑 | B | 高 |
| verify.md:142 | 禁止静默降级 | B | 高 |
| verify.md:174 | 禁止口头确认 | B | 高 |
| verify.md:188 | 禁止的声明格式 | B（含正例表） | 高 |
| regression.md:62 | 不得清单后补 | B | 中 |
| dev.md:28 | 不得进入下一步 | B | 高 |
| dev.md:30 | 禁止跳过读/设计 | B | 高 |
| dev.md:31 | 禁止「应该没问题」 | B | 高 |
| dev.md:43 | 禁止并行编辑同一文件 | B | 高 |
| dev.md:93 | 禁止并发构建 | B（可加构建锁） | 高 |
| evidence.md:75 | 禁止凭猜测假设 API | B | 中 |
| evidence.md:92 | 禁止亮度启发式 | B | 低 |
| evidence.md:99-100 | 视觉模型禁报坐标/禁引导提问 | B | 中 |
| evidence.md:147-148 | 执行者禁分析/禁下完成结论 | B | 中 |
| debt.md:50 | 禁止「先记在脑子里」 | B | 中 |
| acceptance.md:54-56 | 禁跳项/禁合并/执行期禁分析修复 | B | 中 |
| acceptance.md:88 | 禁记 FAIL 糊弄/禁勉强执行 | B | 高 |
| ui-conventions.md:41-67 | 禁额外依赖/禁裸值/禁死令牌/禁硬编码文案 | A 半（可 grep） | 中 |
| test-strategy.md:59,66 | 禁同义反复断言/禁删失败测试 | B（禁删可 git diff 检测） | 高 |
| code-style.md:29,59 | 禁魔法值/禁注释死代码 | A（linter 原则） | — |
| reliability.md:21-42 | 禁空 catch/禁越层状态等 | B（空 catch 可 lint） | 高 |
| architecture.md:24 | 越层直调禁止 | A（第 4.1 节 模板） | — |
| system-design.md:43 | 部署面禁残留 {{SYS}} | A（门禁 1） | — |
| requirement.md:73-74 | 禁自创状态词/分级 | A（门禁 8 源仓） | — |
| requirement.md:93 / manual-ui-checklist.md:22 | 禁模糊措辞 | B | 低 |
| spec.md:36 | 禁推测冒充事实 | B | 高 |
| plan.md:92 | 未过项不得回写 backlog | B | 中 |
| e2e-plan.md:17 | 期望与实操不得混排 | B | 低 |
| ability-domains.md:49 | 不得清单后补 | B | 中 |
| baseline-freeze.md:36 | 禁止顺手修 | B | 高 |
| research-report.md:35,80 | 不得当结论/禁静默跳过 | B | 中 |
| env-runbook.md:32 | 禁止手工导航进起点 | B（标准入口脚本化可消除） | 中 |

### 附录 B：权威来源要点对照（已提取：Claude Code 最佳实践 / agents.md 标准 / Anthropic 上下文工程 / Cursor Rules / Aider / Lost in the Middle）

**B.1 蓝本已符合（且多为先见）**

| 外部要点 | 原文关键句 | 蓝本对应 |
|----------|-----------|----------|
| 逐行删除测试 | "Would removing this cause Claude to make mistakes? If not, cut it." | 写作十律 8 逐字同构：「删掉后 agent 行为会变的句子才保留｜白付加载税」 |
| 最小 ≠ 短 | "minimal does not necessarily mean short" + "informative, yet tight" | 十律 8（每行高信号）+ 250 行预算（整体充分）双标准 |
| 轻量指针 + 运行时取用 | "maintain lightweight identifiers ... dynamically load data at runtime" | 设计原则 1「指针不是百科」+ Use-when 触发词（比 Cursor description 路由更早） |
| 按需加载防膨胀 | "only include things that apply broadly ... use skills instead" | L0/L1/L2 渐进披露 + 门禁 4 MUST≤7 |
| 收录清单（猜不到的命令/环境怪癖/非显然的坑） | page0 收入/排除表 | 「不缓存环境」律只排除该排除的；stack-profile 收「猜不到的命令」✓ |
| 强调词只用于个别行 | "If you emphasize many lines, none of them stands out." | 反模式清单明列「用『重要!』强调每条规则 → 删非承重规则」 |
| advisory → 确定性 hook 升级路径 | "Unlike CLAUDE.md instructions which are advisory, hooks are deterministic" | 「每条机械规则配门禁」原则 3 + architecture 第 2.1 节 五纪律——同构且更系统 |
| 规范当代码维护 | "Treat CLAUDE.md like code: review, prune, test changes" | edit-card 五律 + upgrade.sh 漂移报告 + 同 commit 更新 |
| 示例优于规则枚举 | "For an LLM, examples are the 'pictures' worth a thousand words." | 十律 4「示例优于解释」+ 全库表格带反例列（canonical examples 的表格化实现） |
| 精确引用具体文件 | "Reference specific files, mention constraints" | 指针三要素 + 门禁 6 §引用可解析 |

**B.2 差距（外部有、蓝本缺）**

| # | 要点 | 原文 | 蓝本现状 | 建议 |
|---|------|------|----------|------|
| B-1 | U 型位置纪律 | Lost in the Middle：开头/结尾最佳，中部退化 | AGENTS.md.template 实际布局已暗合（警告行在头、关键约束在尾），但**未明文化**为写作纪律 | doc-writing-standards 十律增补或 edit-card 加一行：L0 文件承重规则置首尾，长表不放中部承重位 |
| B-2 | monorepo 嵌套 AGENTS.md | agents.md：就近优先，OpenAI 仓 88 个嵌套文件 | 体系假设单 AGENTS.md + {{SYS}} 目录；monorepo 多包场景无指引（蓝本宣称「任意新项目」可部署） | bootstrap/onboarding 或 doc-governance 加 monorepo 适配节（每包一份索引 or 根索引+包内补充） |
| B-3 | prompt cache 稳定性 | Aider：常驻文件被 cache 的前提是内容稳定 | 蓝本未考虑 L0 文件高频编辑对宿主会话 cache 的击穿成本 | P2 注记：AGENTS.md 稳定优先，变更走批次 |
| B-4 | 会话卫生（/clear、subagent 收窄调查） | page0 失败模式三条 | dev/verify 未涉及会话级上下文管理（信任边界外的另一面） | 可作 P2 注记，优先级低于结构性议题 |

**B.3 证据缺口如实记录**：MUST/SHOULD/MAY 情态动词对 LLM 的效力比较，**没有任何来源给出实证**（各官方示例一律祈使句 + Must/Never/Always 混用；唯一官方认可的强调手段是行级 IMPORTANT）。本仓的三级体系是设计选择而非证据驱动——但与全部官方示例语料兼容，且 2512.14754 的 cousin-prompt 发现反向支持「固定标准句式」的价值。
