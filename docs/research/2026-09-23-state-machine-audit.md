# ai-dev-guide v2.5.0 全量状态机与机制闭环审计报告

方法：通读 manifest.yaml、scripts/（check.sh / _gates.py / backlog.sh / new-batch.sh / release-version.sh / selftest.sh / init.sh / upgrade.sh / gen-index.py）、workflows/（requirements / release / acceptance / verify / evidence / debt）、templates/（backlog-entry / journal-entry / acceptance-checklist / debt-entry / adr / spec / release-runbook）、registries/、docs/journal/、CHANGELOG、CI 配置；关键缺陷在临时沙盒部署中实测复现（非臆测）。行号为审计时工作区文件实际行号。

## 零、结论总览

体系共建模出 13 个状态机。backlog 卡片三态与版本阶梯单步转移这两个核心设计本身闭环良好（脚本与文档一致、非法转移有拒绝）；但存在 1 个 P0 级数据丢失缺陷、5 个 P1 级「承诺的保护失效/文档自相矛盾」，以及一批无门禁兜底的纸面规则。

| # | 状态机 | 唯一定位 | 最高严重度缺口 |
|---|--------|----------|----------------|
| SM-1 | backlog 卡片 checkbox | requirements.md 第 4 节（L52-64） | P1 守卫死代码 + 影子状态 [X] 无门禁 |
| SM-2 | 优先级 P0-P4 | requirements.md 第 3 节（L38-50） | P1 P4 前提满足后无变迁规则、无改优先级工具 |
| SM-3 | backlog.sh 子命令 vs 文档 | scripts/backlog.sh | P0 同日二次 migrate 丢卡（实测） |
| SM-4 | journal 生命周期 | requirements.md 第 1 节/第 5 节 + journal-entry.md | P2 append-only 无门禁、迁卡后裁决无法回写 |
| SM-5 | 批次生命周期 | new-batch.sh + journal-entry.md:3 | P2 批次关闭无任何机制 |
| SM-6 | 版本阶梯 | release.md 第 2 节 + release-version.sh | P1 tag 链校验/防回退护栏有文无码 |
| SM-7 | 文档退役/替换 | doc-governance 第 5 节 + 门禁 1/5 | P3 基本闭环（豁免区断链属设计） |
| SM-8 | 验收 item（✔/✘/BLOCKED/SKIP） | acceptance.md 第 2.3 节/第 7 节 | P1 终态枚举与 SKIP 语义自相矛盾 |
| SM-9 | 裁决记录 | requirements.md 第 5 节 裁决节 | P2 「最新为准」无机制、已迁卡无法回写 |
| SM-10 | 债务 TD 状态 | debt-entry.md L35-46 | P3 处理中无中止出口、无工具无门禁 |
| SM-11 | ADR 状态 | adr.md L74-87 | P3 已接受→已废弃 图表矛盾 |
| SM-12 | Spec 状态 | spec.md L21 | P3 草稿批准权未定义、被否决稿无终态 |
| SM-13 | 文档生命周期（新建/修订/退役） | doc-governance 第 5 节 / system-design 第 7 节 | P3 replaces 溯源无强制 |

---

## SM-1 backlog 卡片 checkbox 状态机

唯一归宿：workflows/requirements.md 第 4 节（CANON·status-flow L54；状态表 L58-64）。镜像指针：registries/backlog.md:19、templates/backlog-entry.md:49（门禁 7 防分叉，check.sh:103-111）。

| 状态 | 进入 | 退出 | 触发者 | 证据 |
|------|------|------|--------|------|
| [ ] 进行中 | backlog.sh add（恒建 - [ ] 卡） | status verify → [~]；migrate（→[x]+迁出，未验须 -r）；周期审查删除失效卡 | agent/人经脚本 | backlog.sh:81,111；requirements.md:60 |
| [~] 待验证 | status N verify（自动化验证通过后） | migrate（→[x] 迁出）或 status N todo（→[ ] 修复） | agent 执行、用户验收为前提 | backlog.sh:111-112；requirements.md:61 |
| [x] 已完成 | migrate 替换瞬间（过渡态） | 随即迁出 backlog（顶层不得残留） | 脚本 | backlog.sh:123,140；requirements.md:62；门禁9 check.sh:135-139 |

闭环判定：三态互达路径与脚本能力一致（[~]→[ ] 回退文档有定义、脚本支持）；[x] 为瞬态、持久 [x] 有门禁 9 兜底——设计闭环。

缺口：
1. 【P1】migrate 未验卡守卫是死代码（见 SM-3 缺口 2），「[ ] 须 -r 才能迁」的文档承诺（requirements.md:81；backlog.sh:8）实测失效。
2. 【P1】影子状态 [X]（大写）：词表只有空格/x/~，但无门禁校验 checkbox 词表——手工写 - [X] 后，门禁 9 的 grep（check.sh:135 只匹配小写 [x]）不认、backlog.sh card_start（backlog.sh:49 只认 [ x~]）也不认，成为全体系失明的幽灵卡。实测：大写 [X] 完结卡门禁 9 报「✓ 零完结残留」全绿通过。
3. 【P2】「删除失效卡片」（requirements.md:119 周期审查）无工具：backlog.sh 无 delete/close 子命令，唯一合法出账路径是 migrate——周期审查的删除动作与 invariant 8「卡片区禁手工直编」（registries/backlog.md:5）直接冲突。
4. 【P3】status 空转假成功：对已是 [~] 的卡执行 status verify、对 [ ] 卡执行 status todo，均打印「✓ #N → …」但文件未变（backlog.sh:111-112 replace 无匹配即跳过）。实测确认。
5. 【P3】第 4 节 状态表未列 [ ]→[x] 直接转移，但 第 5 节 规则 4（L81）隐含允许（未验卡带依据迁移）——两节口径未对齐。

修复建议：① 门禁 9 增加两条：顶层 "- [" 行的 checkbox 必须匹配 [ x~] 白名单；首个 P 节之后不得再出现顶层 "- [" 行（现检查 check.sh:152-154 只查表头区，实测 P4 之后自定义节下放卡全绿）。② backlog.sh 增加 delete（带理由写 journal）或明文授权周期审查手工删卡。③ status 目标态==当前态时输出「已是该状态」。④ requirements.md 第 4 节 表补 [ ]→[x]（带 -r）一行。

---

## SM-2 优先级 P0-P4

唯一归宿：requirements.md 第 3 节（CANON·priority L40；表 L42-48）。镜像：registries/backlog.md:11-17、backlog-entry.md:49。

| 等级 | 语义 | 变迁规则 | 触发者 | 证据 |
|------|------|----------|--------|------|
| P0 | 主流程体验/核心业务 bug | 登记初判、澄清复核；优先处理 | 人/agent | requirements.md:44,50 |
| P1 | 主要业务流程功能需求 | 同上 | 同上 | :45 |
| P2 | 优化与小 bug | 同上 | 同上 | :46 |
| P3 | 观察项/低价值改进 | 同上 | 同上 | :47 |
| P4 | 外部前提阻塞，卡内必含「前提」行 | 前提满足后的变迁：无定义 | 未定义 | :48；registries/backlog.md:17 |

缺口：
1. 【P1】P4 无出口：全体系没有「前提满足后如何把卡迁出 P4 节/重判优先级」的规则；第 8 节 周期审查四动作（requirements.md:115-122：去重/催验收/查 P0 积压/清 journal）不含 P4 前提复查。P4 卡实际只能无限滞留。
2. 【P1】P0-P4 之间无任何晋升/降级规则（登记初判后如何改？），且 backlog.sh 无 reprioritize/move 子命令——改优先级只能手工跨节剪切卡片，违反「禁手工直编」。机制性死锁：文档唯一授权的账本写手（脚本）不具备优先级转移能力。
3. 【P3】门禁 9 只校验 P 节序唯一（check.sh:150-151），不校验优先级语义；「查 P0 积压」纯纪律。

修复建议：① 第 8 节 周期审查加第五动作「P4 复查：前提已满足 → 按变迁规则重判优先级」。② 第 3 节 补优先级变迁规则（谁可改、改时须 note 留痕）。③ backlog.sh 增加 prio <N> <0-4> 子命令（删卡+目标节重插+note 留痕，计数器不动）。

---

## SM-3 backlog.sh 子命令实现 vs 文档状态机

逐命令核对（scripts/backlog.sh，166 行）：add（L70-97）/ note（L99-105）/ status（L107-114）/ migrate（L116-143）/ journal new（L150-153，委托 new-batch.sh）/ journal append（L155-160）。以下与文档一致：计数器正则（L44）、编号全局递增永不回收（L95,143）、README 排除（L127）、-p 0-4 校验（L76）、撞号防护依赖门禁 9（check.sh:140-144）。

缺口（按严重度）：

1. 【P0】同日第二次 migrate 起永久丢卡（实测复现）。backlog.sh:134-138：首次迁入走 else 分支（建节+依据行+卡片正文）；同日已存在「## 已完结卡片迁入（日期）」节时走 if 分支——只把「- 迁入依据：…」一行插在节标题后，卡片变量 card 从未写入 journal；随后 L140 照样把卡从 backlog 删除。实测：同一批次同日迁 #1/#2/#3 三卡，journal 只剩 #1 正文，#2/#3 从 backlog 与 journal 同时消失；脚本报「✓ 已迁入」、门禁 9 全绿，零告警。触发条件极常见（一批修多卡、同日验收多卡）；项目未及时 commit 则正文不可恢复。
   修复：if 分支改为向节末追加依据行+卡片正文（保留历史不动，纯尾部追加）；selftest 部署演练加「同日双卡迁移，第二张卡正文必须存在于 journal」回归断言。

2. 【P1】未验卡守卫死代码（实测复现）。backlog.sh:123 先把 "- [ ] "/"- [~] " 替换为 "- [x] "，L124 才检查 card[0].startswith("- [ ]")——恒 False，守卫永不触发。实测 [ ] 卡无 -r 直接 migrate 成功。违反 backlog.sh:8 自述（「未验卡须 -r」）与 requirements.md:81（第 5 节 规则 4「未验卡静默流失」防线）。
   修复：把状态检查移到 L123 替换之前（先读原始 checkbox 再决定）。

3. 【P1】无 -r 时自动伪造「用户验收通过」（实测复现）。backlog.sh:133 basis 默认「用户验收通过」——对 [~]（定义即「用户验收未完成」，requirements.md:61）甚至 [ ] 卡，journal 落下虚假验收记录，违反 第 4 节 铁律「未经用户确认的勾选属违规」（requirements.md:64）。
   修复：守卫生效后 [ ] 无 -r 自然拒绝；[~] 无 -r 时默认依据改为「状态 [~] 迁出，验收依据待补」，禁止默认写「用户验收通过」。

4. 【P2】run_gate 失败不回滚：变更落盘后才跑门禁 9，失败仅打「⚠ 门禁 9 未过」（backlog.sh:27），非法状态已写入文件。
5. 【P2】migrate 自动选「最新」journal（backlog.sh:127-129 按文件名排序取最后一个）vs 文档「迁入对应 journal 批次文件」（requirements.md:71）——不校验对应性，跨批次错配无提示。
6. 【P2】源仓自身账本不受自家工具管辖：BL 固定为根目录 backlog.md（backlog.sh:16），蓝本账本在 registries/backlog.md——backlog.sh 在源仓无法运行；门禁 9 源仓模式跳过（check.sh:161），骨架只在部署演练时校验一次（selftest.sh:47）。
7. 【P1·证据链红旗】v2.5.0 journal 验证声明失真：docs/journal/2026-09-23-oc-beacon-reintegration.md:17 记录「GREEN：…migrate 未验卡正确拒绝…」——与实测行为直接矛盾（死代码不可能拒绝），且 selftest R1-R11 无任何 backlog.sh migrate 回归断言（selftest.sh:38-159 未覆盖账本脚本），说明该 GREEN 演练未命中真实代码路径或演练后代码回退。按本体系自己的标准（journal 是证据链锚点），此条需要勘误并补真演练。
8. 【P3】journal append 无路径约束（backlog.sh:155-160）：实测可向 backlog.md 本体追加任意行，污染账本。
9. 【P3】migrate 把 [ ]/[~] 改写为 [x] 后迁入，与「原文逐字迁入（不压缩不删改）」（requirements.md:71、journal-entry.md:24）字面冲突；第 5 节 流程图（L68-74）把勾 [x] 画在迁入前，勉强自洽。

---

## SM-4 journal 生命周期

| 阶段/状态 | 进入 | 退出/例外 | 触发者 | 证据 |
|------|------|----------|--------|------|
| 批次文件创建 | new-batch.sh（同日同名拒绝；批次名宽容转写） | 文件不删除（无删除机制） | 人/agent | new-batch.sh:12-13,24 |
| 过程记录 | journal append（行首自动加日期） | —— | agent/人 | backlog.sh:159 |
| 完结卡迁入 | migrate 建「已完结卡片迁入（日期）」节 | 例外：migrate 是读-改-写（backlog.sh:131-139），未在任何文档声明为 append-only 豁免 | 脚本 | requirements.md:18「append-only」 |
| 批次状态（进行中/部分完结/已完结） | 无定义 | 无定义 | 人工改模板头 | journal-entry.md:3 |

缺口：
1. 【P2】append-only 无门禁：违反后果（「差异分析失真」，journal-entry.md:34）纯纸面；门禁 10 只查文件名（check.sh:165-172），手工改写历史零检测。且 append-only 的合法豁免（migrate 全量重写）未在 requirements.md 第 5 节 声明——纪律与脚本各说各话。
2. 【P2】已迁卡不可再 note：find_card 只扫 backlog.md（backlog.sh:57-61）→「新裁决落地时回写旧裁决域卡片注记」（requirements.md:89）对已迁卡无法执行（见 SM-9）。
3. 【P2】复活/撤销路径未成文：migrate 误迁后唯一恢复手段是 git + 新卡互引；requirements.md 通篇无「撤销迁移」条目（全仓 grep「撤销」零命中）。
4. 【P3】引用闭环尚可：编号永不回收（registries/backlog.md:7）、门禁 9 把 journal/specs 编号计入 MAX 防撞号（check.sh:142）、backlog 卡片 docs/ 链接有悬空检查（check.sh:146-147）；journal 自身禁相对链接是纪律（journal-entry.md:38）且门禁 1 豁免 docs/journal/（_gates.py:32-33）——两者一致。

修复建议：① 第 5 节 补一句「migrate 的节插入是 append-only 的唯一豁免写路径」。② selftest 加「migrate 后 journal 历史行逐字节不变」断言。③ 文档写明误迁恢复路径（git revert + 新卡 + 两卡互引）。

---

## SM-5 批次（batch）生命周期

创建：new-batch.sh 产出 docs/journal/YYYY-MM-DD-<kebab>.md（模板实例化，只替换 <批次名>/<YYYY-MM-DD> 两个占位，new-batch.sh:25）。

缺口：
1. 【P2】「关闭」不存在：模板状态行（进行中/部分完结/已完结，journal-entry.md:3）无进入/退出判据、无命令、无门禁；「批次末统一报告」（requirements.md:90）无机械钩子。源仓自己的批次也是手改状态行（2026-09-23-oc-beacon-reintegration.md:3「状态：已完结」）。
2. 【P3】「开工即建批次」无强制；migrate 反而自动挑最新批次兜底（backlog.sh:127-129），变相奖励「不建批次直接迁」。
3. 【P3】验收清单落盘目录 docs/acceptance/（acceptance.md:32、acceptance-checklist.md:4）命名规约与门禁 10 正则同构却不受查（check.sh:168 只扫 docs/journal/ docs/specs/）。

修复建议：门禁 10 扩展到 docs/acceptance/（成本低）；批次状态行由 migrate 自动推进（首迁→部分完结）可作为可选项。

---

## SM-6 版本阶梯（dev.N / beta / 正式版）

先澄清：本体系相位词表是 dev.n → beta（无序号）→ 正式版，没有 rc.N 相位、beta 不带序号（release.md:33-35；2.1.0 引入，CHANGELOG.md:88）。提问中的 beta.N / rc.N 不是本体系的合法相位。

脚本实现的全部单步转移（release-version.sh）：

| 转移 | 命令 | 校验 | 证据 |
|------|------|------|------|
| 初始化 stable | init x.y.z | 已存在拒绝 | L81-87 |
| stable → 新版本 dev.1 | next --bump major/minor/patch | 仅 stable 可发起；缺 --bump 拒绝 | L89-98（L91） |
| dev.n → dev.n+1 | dev | —— | L100-103 |
| beta → dev.(DC+1)（退回修复） | dev | 缺 DEV_CYCLE 拒绝 | L104-105 |
| dev.n → beta | beta | 仅 dev 可发起 | L109-112（L111） |
| beta → stable | stable | 仅 beta 可发起 | L114-117（L116） |
| 非法：stable→beta/dev/next、dev→stable/next、beta→beta/next | 一律 die | 与文档 第 2.1 节 规则 1-4 一致 | L91,106,111,116 |

文档与实现/自检的缺口：
1. 【P1】tag 递进链校验有文无码：release.md:63「beta tag 存在 ⇒ 同线 dev.N tag 齐全；正式 tag ⇒ beta+dev 齐全（validate 可挂 CI）」——validate（L119-128）只查格式/VERSION_CODE/DEV_CYCLE，scripts/ 全目录 grep 无任何 git tag 操作。CHANGELOG.md:18 宣称 v2.5.0「Added：tag 递进链校验、防回退护栏」实为只加了文档文字。
2. 【P1】防回退护栏有文无码：release.md:64「版本文件落后于已发布正式版时禁止产出更小版本号」——无实现（唯一近似是 init 拒绝覆盖已有文件，L84）。
3. 【P2】开新线 bump 基准（release.md:65「本线正式 tag→beta tag→上一正式版逐级回溯」）无实现：next 只信版本文件当前值（L90）。
4. 【P2】selftest 版本演练覆盖不全（selftest.sh:129-159）：已测全阶梯走通、stable 态拒绝 beta/stable/dev（L146-151）、R11 杂散参数（L153-157）；未测 dev 态 stable 拒绝、beta 态 next/beta 拒绝、VERSION_CODE 单调递增、next 后 DEV_CYCLE 重置、validate 对 DEV_CYCLE≠dev 序号的拒绝（release-version.sh:124-126 无测试触达）。
5. 【P3】tag/Release/CHANGELOG 实操本就不在脚本职责内，release.md 第 1 节 已如实双轨声明（L12-21）——该部分无缺口。

修复建议：validate 增 --tags 模式（git tag 链校验 + 新版本号须大于已发布正式版）挂 CI；selftest 补 5 条断言；或按 system-design.md:114「纸面规则无效」的自我要求，把三条护栏在 release.md 第 2.2 节 如实标注「当前为发版红线上的人工核对项，暂无机器门禁」——二者必居其一。

---

## SM-7 文档退役/替换流（manifest replaces + 门禁 1）

生命周期（doc-governance.md 第 5 节 L61-68 = system-design.md 第 7 节 L130-137）：新建（manifest 加条目→gen-index→写作；门禁5）→ 修订（门禁1/5/6）→ 新增即替代审计（门禁1）→ 退役（manifest 删条目→删文件→重跑 gen-index→修复入链；门禁1/5）。

闭环判定：退役引用清理闭环——删文件后所有指向它的相对链接断裂，门禁 1（_gates.py:43-64）源仓模式全仓拦截（历史豁免区除外），不修不能过；门禁 5（gen-index --check，gen-index.py:185-219）拦截索引漂移；门禁 8 拦截退役词汇复发（check.sh:115-121）。「清不干净」的直接后果 = 门禁 1/5 红、selftest/CI 失败（.github/workflows/check.yml:16-17）。

缺口：
1. 【P3】豁免区（specs/、docs/journal/、docs/archive/、docs/adr/、CHANGELOG，_gates.py:32-33）中的退役文档引用永久悬空不报——这是「变更故事住历史层」的设计选择（check.sh:10-11、doc-governance 第 6 节 L72-81），非缺陷，但建议在 doc-governance 明示「豁免区断链不修」。
2. 【P3】replaces 字段是纯溯源注释（manifest.yaml:42），不在 gen-index.py 必填字段清单内（L97-100）——「退役必须留 replaces」无强制。
3. 【P3】「新增即替代审计」（doc-governance:67）纯纪律无门禁（低频人工动作，可接受）。

---

## SM-8 BLOCKED-by-编号 与 SKIP（验收 item 状态机）

载体：docs/acceptance/ 清单 item，打标规则 acceptance.md 第 2.3 节；evidence.md:149 同语义（BLOCKED 传播）。

| item 状态 | 进入 | 退出 | 触发者 | 证据 |
|------|------|------|--------|------|
| ✔ / ✘ | 逐项执行完立即打标 | ✔ 终态；✘ → 根因修复→只重跑受影响 item | 执行 subagent 只观测，主 agent 分析 | acceptance.md:55,62 |
| BLOCKED-by-编号 | 依赖项 ✘ 时标注 | 隐含：阻塞解除后随 第 2.4 节 重跑受影响 item（未显式成文） | 执行 subagent 标、主 agent 解 | :57 |
| SKIP | 前置不满足（环境/依赖/数据） | 「登记待补」后 item 本身去向未定义 | 执行 subagent | :86-88 |

缺口：
1. 【P1】终态枚举自相矛盾：第 2.3 节#5「全部 item 到达终态（✔/✘/BLOCKED）才结束」（acceptance.md:58）不含 SKIP，而 第 7 节（:88）又要求前置不满足时记 SKIP——含 SKIP 项的清单按字面永远无法满足结束条件，执行 subagent 无所适从。
2. 【P2】SKIP 卡最终去向悬空：「SKIP 项登记待补（requirements.md）」——requirements.md 全文无「待补/SKIP」承接（全仓 grep「待补」仅 verify.md:81,146,148 与 acceptance.md:88），无对应 tag/优先级/登记格式；登记后清单里的 SKIP 项无人复查（docs/acceptance/ 无任何门禁覆盖：门禁 10 只查 journal/specs 命名 check.sh:168；部署模式门禁 1 扫描范围不含 docs/acceptance/，_gates.py:13-14,25-29）。
3. 【P3】BLOCKED 的解除重打标规则只是 第 2.4 节 的隐含推论，未显式写「阻塞解除后 BLOCKED→重跑→✔/✘」。

修复建议：① acceptance.md:58 终态改为「✔/✘/BLOCKED/SKIP」，并加「SKIP/BLOCKED 项须附待补 backlog 卡编号（note 留痕）」。② requirements.md 第 2 节 来源表加「验收 SKIP/降级待补 → 登记 P2 卡」一行。③ BLOCKED→重跑规则写进 第 2.4 节 一句。

---

## SM-9 裁决记录机制

| 环节 | 规则 | 机制支撑 | 证据 |
|------|------|----------|------|
| 生成 | journal 批次内「用户裁决：」+原话/要点+日期 | journal append 自动加日期前缀（backlog.sh:159）；模板锚点 journal-entry.md:16 | requirements.md:88 |
| 覆盖 | 同域多次裁决以最新为准 | 无机制：「域」无登记结构、无裁决索引，「最新」靠人工比对 journal 日期 | requirements.md:89 |
| 回写 | 新裁决落地时回写旧裁决域卡片注记 | backlog.sh note 可执行；但旧卡已迁入 journal 时 note 找不到卡（find_card 只扫 backlog.md，backlog.sh:57-61）→ 回写链断裂且无替代路径 | :89 |
| 违反后果 | 裁决蒸发/旧裁决复活执行 | 无门禁（自由文本，机械检查成本高，属可接受局限但应明示） | :88-89 |

缺口：【P2】回写对已迁卡失效；【P2】「最新为准」无枚举工具。
修复建议：① note 支持对 journal 迁入卡追加（定位文件+编号追加「后续裁决」行——append-only 合法写）。② 要求裁决行带域标签（如「用户裁决(签名体系)：」），grep 即可枚举同域历史。

---

## SM-10/11/12 附属登记簿状态机（简要）

SM-10 债务 TD（debt-entry.md L35-46，唯一词表：待处理/处理中/已消除/已接受）：合法边 = 待处理→处理中→已消除（附 commit）、待处理→已接受（必写理由+触发条件）。缺口【P3】：处理中无中止出口（处理中→已接受、处理中→待处理均未定义）；已接受无「触发条件满足→重开待处理」回边（debt.md 第 4 节 定期复审隐含但未写状态转移）；全登记簿无工具无门禁（状态词表、TD-N 永不复用均无 grep/计数器检查）。

SM-11 ADR（adr.md L74-87）：提议→已接受/已废弃；已接受→被替代；被替代→已废弃。缺口【P3】：状态图（L77-80）无「已接受→已废弃」边，但状态表 L87 已废弃触发写明「决策失效/回退时」（不要求有替代者）——图与表矛盾；被替代的显式互引规则（L95）无门禁。

SM-12 Spec（spec.md L21：草稿/已批准/已实施/已归档）：草稿→已批准的批准权/判据全体系未定义；被否决的草稿无终态（无「已否决」，只能删文件）；已实施→已归档闭环（requirements.md:73：验收后移入 docs/archive/specs/ 并回填卡片引用；spec.md:23）。

---

## 附：审计中确认的一致性小缺陷

1. 【P3】bootstrap/onboarding.md:14「目标项目内只有 check/new-batch/release-version/scan-secrets 四个运行时脚本」——init.sh:77-81 实际部署 5 脚本 + 2 依赖文件（含 v2.5.0 新增 backlog.sh），未同步。
2. 【P3】CHANGELOG.md:29-31「## [2.4.0]」标题连续重复两次，破坏 Keep-a-Changelog 结构。
3. 【P2】selftest/CI 全绿 ≠ 账本机制健康：R1-R11 无一条覆盖 backlog.sh（add/status/migrate）——本次 P0 丢卡缺陷正是这个盲区放行的。建议部署演练增加三条回归断言：同日双卡迁移不丢卡、未验卡无 -r 被拒、[X] 影子态被门禁 9 拦截。

## 修复优先级排序

- P0 ×1：backlog.sh:135-136 同日二次 migrate 丢卡（先修：一行改动 + 回归断言）。
- P1 ×5：migrate 守卫死代码（backlog.sh:123-124）；伪造「用户验收通过」依据（backlog.sh:133）；P4 前提满足后无变迁规则（requirements.md 第 3 节/第 8 节）；acceptance 终态枚举与 SKIP 矛盾（acceptance.md:58 vs :88）；release.md:63-65 三条 tag/回退护栏有文无码（补实现，或如实降级为人工红线并改文档措辞）。
- P2 ×约12、P3 ×约12：见各节。
