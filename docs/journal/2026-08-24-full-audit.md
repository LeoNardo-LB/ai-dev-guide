# 2026-08-24 <批次：full-audit>

> 状态：已完结
> 关联：#1（文档系统自身演进）

## 目标

对全仓做一次系统性审计（每个脚本能力逐条实测 + 每份文档描述双向核对），修复全部发现的缺陷并固化为回归断言。

## 过程与证据

- 审计方法：3 个并行子代理分别核对 workflows/、standards+meta+stack+bootstrap、templates+registries 共 41 份文档的事实性描述；主线逐行精读 11 个脚本并对每个可疑路径做 /tmp 沙箱实测（含异常路径与边界）。
- 实测发现脚本缺陷 10 项（D1-D10）：
  - D1 init.sh 用 echo "\n" 写 docs/*/README.md → 落盘为字面反斜杠n（od 实证）；
  - D2 check.sh --deployed 指向不存在目录时 cd 失败仍继续 → 在源仓当前目录跑部署门禁，产出 44 条假断链；
  - D3 部署门禁 1 扫描目标项目全部 .md → 用户自有文件断链导致系统门禁误失败（实测一条旧笔记即触发）；
  - D4 全新部署零修改的项目被 upgrade.sh 报 11 处「双方修改需人工合并」——init 的链接清洗改写文件但升级比对无部署基线；
  - D5 scan-secrets.sh 统计跑在 grep管道while子shell → 命中全丢，实测 6 处敏感命中后仍报「干净 0 命中」且 exit 0（CI 空转）；
  - D6 白名单规则被同时当路径 glob 与内容子串匹配 → 提及脚本路径的行内真实密码被放行（实测 trap 行）；
  - D7 gen-index.py --check 对 GEN 标记被删只警告 exit 0 → 标记删除不可检测；
  - D8 门禁 9 计数器正则不识别行尾裸编号、#N 前是空格时永不计数 → 计数器可与已用编号撞号（两轮实测）；
  - D9 release-version.sh 杂散位置参数被静默吞掉（next stray --bump patch 照常执行）；
  - D10 journal-entry.md 模板本体包在代码围栏里 → new-batch.sh 实例化产物 H1 仍是「模板」标题，且 Related 相对链接从 docs/journal/ 解析必断。
- 修复：scan-secrets.sh 重写（主 shell 计数 + 路径/内容规则语义分离 + -I 跳过二进制 + case 模式去引号保 glob）；check.sh 增目录守卫与计数器正则（空白前缀 + 行尾后顾）；_gates.py 增部署扫描范围（DSH_SYS_DIR 推导，只扫系统产物）；gen-index.py --check 缺标记即失败 + trim-table 过滤 source 面；init.sh 重写实例化（四件登记簿 + printf 真实换行 + .deploy-baseline.txt 部署基线 + sysname 合法性与自指防护 + 部署 scan-secrets）；upgrade.sh 重写为基线感知三态分类（可直接覆盖/本地化修改/无基线退化）；release-version.sh 统一拒绝非 init 的位置参数；journal-entry.md 重构为整文件即条目（零相对链接）。
- 文档缺陷 30 余项同步修复：release.md 虚构「脚本 commit/tag/push/CI」能力链改为如实双轨表述；evidence.md 两处错误栈档案引用；research-report.md 11 处（含 D0-D4 禁用维度改命名维度、两对节号互换、根因型改根治型）；requirement.md 自拟 P0-P2/六态词表改指 CANON 唯一归宿；spec/plan/e2e 模板的虚构目录（specs/、plans/）与错节号；ability-domains「P0 域」撞名改「首要域」；backlog-entry 门禁能力过述改如实标注强制/警告/纪律；test-strategy/ui-conventions/system-design/onboarding/stack-profile 各 1-3 处错引或失实。
- 回归固化：selftest.sh 部署演练扩为 R1-R11 断言（每个修过的缺陷一条会失败的测试），全部通过。
- 验证：bash scripts/selftest.sh 全绿（语法 11 项 + 十门禁 + 敏感扫描干净 + R1-R11 + 版本阶梯含 R11）；R5 实证全新部署 upgrade.sh 零本地化误报。

## 完结迁移区

（本批次为系统自身演进，无 backlog 卡片迁移）

## 蒸馏（可选）

- 教训：bash 统计类脚本禁止 grep 接 while 读管道（子 shell 丢状态）——已写入 scan-secrets.sh 头注释；case 模式内引号会把 glob 变字面量；echo 转义换行不可靠，统一 printf。
- 教训：声称脚本能力前先实测该能力（本次 D5/D6 若早有夹具测试绝不会带病上线）。
