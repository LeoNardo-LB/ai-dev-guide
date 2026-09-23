# 验收清单模板（Acceptance Checklist）

> 一卡一份、单文件自包含的验收 checklist 骨架——三步验收法（生成→审查→执行）的载体，流程见 [../workflows/acceptance.md](../workflows/acceptance.md) 第 2 节。
> 落盘位置：docs/acceptance/YYYY-MM-DD-<编号>-<slug>.md。

## Use when

- 生成验收 checklist 时（acceptance 第 2.1 节）
- 审查/执行 subagent 逐项打标时（checklist 即执行记录）

## 模板本体

```markdown
# <编号> <标题> 验收 checklist

- 卡片：backlog #<编号> | 日期：YYYY-MM-DD
- 构建：<commit> | 环境：<设备/环境标识（见 docs/env-runbook.md 环境矩阵）>
- 分类：仪器可验（全部 item 走三步）/ 含人工项（列出 item → 类别①-④ + 为何仪器不可行）
- 回归域：<能力域列表 + 一句话理由（为何回归/不回归）>

## A. 新特性 / 修复效果

### A1 <目的一句话：校验<场景>下<表现>，无歧义指代>
- 前置：<环境/数据/状态准备>
- 操作：<可被照做的步骤序列>
- 期望：<可观测现象>
- 判定：<成功标准，尽量指向仪器证据：日志 tag / 数据行 / UI 树节点 / 像素采样 / 录屏逐帧>
- 实测记录：（执行者填写：✔ / ✘ / BLOCKED-by-<id> + 观测事实 + 证据路径）

## B. 回归（受影响能力域）

### B1 <目的一句话>
- 前置：
- 操作：
- 期望：
- 判定：
- 实测记录：

## 人工验收清单（仅四类人工项；按域边界汇总提交）
- [ ] <操作路径 + 预期现象 + 判定标准>（类别①-④ + 为何仪器不可行：…）
```

## item 编写规则

| # | 规则 | 违反后果 |
|---|------|----------|
| 1 | 边界清晰、职责单一，item 互不重叠不模糊 | 审查打回、验重复或漏验 |
| 2 | 覆盖本卡改动全部分支：正向 + 逆向 + 边界；层次递进（连接/启动 → 数据 → 交互 → 回归） | 分支漏验 |
| 3 | 判定尽量指向仪器证据（[../workflows/evidence.md](../workflows/evidence.md) 手段） | 无法客观核对 |
| 4 | 操作步骤可照做（命令/路径/定位明确；关键点按动态查询定位，不用固定坐标） | 执行者卡壳或点错 |
| 5 | 执行者只填「实测记录」区，不改其余内容；失败继续后续独立项（acceptance 第 2.3 节） | 半程终止、记录被污染 |

## Related

- 验收工作流（三步法/关闭权限）：[../workflows/acceptance.md](../workflows/acceptance.md)
- 测试环境 runbook（前置环境来源）：[./env-runbook.md](./env-runbook.md)
- 回归域能力清单：[./ability-domains.md](./ability-domains.md)
