# 2026-09-23 <批次：script-audit-sandbox>

> 状态：已完结
> 来源：用户指令（「系统性分析是否可能存在其他 bug，尤其各类脚本，自行配置沙箱环境自行测试，确保各脚本各参数各 case 无 bug」）
> 关联：docs/journal/2026-09-23-external-bug-backlog-context.md（同日外部反馈批次）

## 目标

对全部脚本做沙盒化穷举测试：每个子命令、每个参数、合法/非法/边界 case，产出并修复缺陷。

## 过程与证据

### 方法

主测（核心链：账本 / check / init）+ 三路轻量子代理并行（release-version 全矩阵；scan-secrets+new-batch+gen-index；upgrade 漂移矩阵），全部实验于 /tmp 沙盒，不触真仓。

### 第 1 轮：主测矩阵（RED 发现）

账本矩阵 34 case（add/note/status/prio/migrate/journal/并发 6 路/计数器）：29 PASS；另修正 3 个测试自身笔误后补验。
check 矩阵 10 case：参数 6 + 门禁注错 4（断链/CANON 双归宿/禁用词/AGENTS 超行——四个注错全部被对应门禁捕获）。
init 矩阵 8 case：缺参/自定义 dir/no-ui+no-example 组合/已有 AGENTS.md/已有系统目录/相对路径/文件目标/dir 含空格。

缺陷（主测发现 5 项，全部修复）：

| # | 严重度 | 缺陷 | 修复 |
|---|--------|------|------|
| S1 | P1 | check.sh --only/--skip 垃圾值或越界值（abc/11/xyz）静默「零门禁运行 + 结果：通过 exit 0」——打错字即绕过全部门禁，击穿「门禁绿=已验证」信任模型 | validate_ids 参数校验（非数字/越界 exit 2）+ --skip 全跳空跑拒绝 |
| S2 | P2 | init.sh --no-ui --no-example 组合部署后部署门禁 6 断裂 2 处：AGENTS.md「其他」节纯文本引用已裁剪的 ui-conventions.md §7；templates/plan.md 链接被 scrub 洗纯文本但 §7 残留（R1 只测 --no-ui+门禁1，组合与门禁6 从未覆盖） | AGENTS 生成器剔除引用裁剪组文档的手写行；_scrub_links 悬空路径 §N 一并清洗 |
| S3 | P2 | init.sh --dir 含空格 → 生成 49 处含空格 markdown 链接，门禁 1 全断 | --dir 空白字符拒绝（exit 2） |
| S4 | P2 | _backlog_core.py 五个子命令缺参/编号非数字 → 裸 Python Traceback（泄内部、对使用者不友好） | need/num 守卫，全部干净用法报错 |
| S5 | P3 | init.sh 目标为已存在文件 → mkdir -p 把文件路径建成目录静默部署；backlog.sh add 空标题被接受产出残卡；journal 子命令 set -u 未绑定参数报错形态丑 | 文件目标拒绝（exit 2）；空标题拒绝；journal 参数 ${1:-} 防呆 |

### 第 2 轮：修复复验（GREEN）

- check：--only abc/--only 11/--skip xyz/--skip 全跳 → 全部 exit 2 带明确报错；--only 6 合法路径不受影响
- init：--dir 'a b' 拒绝；文件目标拒绝；--no-ui --no-example 组合全量部署门禁 1-10 通过（AGENTS 残留 ui 引用 0、plan.md 残留 §7 0）
- 账本：7 个缺参/非数字 case 全部干净用法报错（Traceback 行数 0）；空标题被拒
- 全仓：check.sh 十门禁通过；selftest R1-R13 全绿（新增 R13a-i 九断言固化本批全部修复）

### 第 3 轮：子代理外围矩阵（三路报告，全部沙盒复现可重放）

**C 组 upgrade.sh（4 缺陷，已修）**：D1 目录名错误（省略/传错第三参）曾静默产出误导报告——现校验「目录存在且像部署目录（含 scripts/check.sh）」并提示疑似正确名；D2 上游删除文档曾误报「本地新增+回馈上游」——新增「上游已删除（基线有、manifest 无）」桶，语义反转纠正；D3 明细 >20 条静默截断——补「另有 N 条未列出」；D4 源仓缺 gen-index.py 裸 traceback——exit 2 可读报错。观察项 O1（手改基线可掩盖本地修改）记入脚本头注信任模型。

**B 组 scan-secrets / new-batch / gen-index（8 缺陷，已修）**：scan-secrets 重构为逐文件两段式（先 grep -l 列文件再逐文件 grep -n）——文件名含冒号（cut -d: 曾截断文件名）与超长行豁免（head -c 90 曾令 minified 行豁免静默失效）从此可正确解析；参数拒绝（对齐 R11 纪律）；白名单缺失改「警示 + 按空表扫描」不再静默建文件。new-batch 批次名长度上限 100（防 bash 文件名过长以 exit 1 混入冲突语义）。gen-index：字段校验前移（缺 path 曾裸 KeyError）、标量校验 + trim_group 枚举（行内 [..] 列表误入曾致 unhashable）、manifest 缺失干净报错。修复中发现并修正一处修复自身缺陷：case 模式的 | 选择符是语法元素、不能来自变量展开——glob 改空格分隔逐个判定（R10 抓住）。

**A 组 release-version（6 缺陷，已修）**：B1 缺键/空文件静默 rc=1 零输出（pipefail×set-e 令 die 成死代码）——grep 管道加 || true 保住诊断出口；B2 dev.0/dev.00 放行（违反 §2.1 序号从 1 起）——正则收紧 [1-9][0-9]*；B3 前导零全链放行（SemVer 禁、tag 字符串排序倒退）——数字段 ([1-9][0-9]*|0)；B4 --bump 缺值 set -u 裸崩——exit 2 带用法；B5 脏文件（DC 与序号不一致）迁移曾致版本号倒退（dev.5→beta→dev.3）——check_cycle 预检与 validate 同规；B6 DEV_CYCLE 空值 validate 放行（fail-open）——dev/beta 相位强制非空 ≥1。在册事项实证确认：§2.2 末三条（tag 递进链/防回退/开新线基准）validate 未覆盖属实、VERSION_CODE 手改回退不可发现——均属「防回退机器化」在册遗留。

### 第 4 轮：终验（GREEN）

- 全仓 check.sh 十门禁通过；selftest R1-R14 全绿（R13a-i 九断言固化主测五修复，R14a-e 五断言固化 A 组修复）
- A/B/C 三组全部复现脚本可在沙箱重放（/tmp/rv-sandbox、/tmp/scan-sandbox、/tmp/up-sandbox 留存）

## 完结迁移区

本批无卡片迁移（源仓无 backlog 账本）。

## 遗留

- release-version：§2.2 末三条（tag 递进链 / 防回退 / 开新线基准）与 VERSION_CODE 手改回退检测仍未机械化——需 git 历史基准，与「release validate --tags」在册项合并处理
- release-version：stable 相位 DEV_CYCLE 行缺失属合法（沿原设计：stable 无需循环序号）——如需强制三键齐全属结构决策，在册观察
- scan-secrets：同一行命中多类别时重复计数（O2）——展示语义问题，在册观察
- new-batch：从子目录运行时 journal 建到 cwd/docs/journal（O1，文档已约定在项目根运行）——加项目根校验属增强，在册
- _gates.py 经 exec 调 gen-index load() 时 ManifestError 会以 traceback 形态漏出（各门禁未包裹）——低频破损仓场景，在册观察
