# GREEN 回归报告（2026-05-04）

## Scope

- 验证目录：`<skill_root>`
- 测试目录：`<workspace_root>`
- 显式排除：`.tmp-upstream`

## Static checks（GREEN）

### D1 范围断言（7 skills）
- 结果：通过。
- 证据：`README.md` 第 30-38 行；`SKILL.md` 第 134-429 行。

### D2 状态机断言
- 结果：通过。
- 证据：`README.md:342-343`；`SKILL.md:129-130`（并在 `SKILL.md:15` 有硬约束声明）。

### D3 stable-only 断言
- 结果：通过。
- 证据：`README.md:323,348`；`SKILL.md:16,376`；`references/audit-rules.md:18`。

### D4 路径隔离断言
- 结果：通过。
- 证据：`README.md:57`；`SKILL.md:53-54,530`。

### D5 模板一致性断言
- 结果：通过（由 RED 失败修复后回归通过）。
- 修复前：`references/paper-template.md:7` 为 `source_pdf`。
- 修复后：`references/paper-template.md:7` 为 `source_file: "../../raw/papers/<file>.<ext>"`，与 `README.md:121`、`SKILL.md:69` 一致。

### D6 错误分级断言
- 结果：通过。
- 证据：`SKILL.md:440-445` 包含 `level/skill/code/message/action/trace_id`。

## Runtime-like checks（GREEN）

### R1 样本可识别性（输入面）
- 检查：`kb_mpw` 下是否可检出 `pdf/tex` 支持格式样本。
- 结果：通过。
- 证据：`<workspace_root>/**/*.pdf` 检出 4 个 PDF。

### R2 路径边界（不写回 skill 源码目录）
- 检查：skill 源码目录是否被误当运行时目录。
- 结果：通过。
- 证据：规范层有拒绝规则（`SKILL.md:53-54,157,224,530`）；本轮未向 skill 根目录写入 `refs.bib/raw/wiki/outputs` 运行时产物。

### R3 门禁链路（状态机）
- 检查：`draft -> audit(pass) -> stable` 是否作为晋级唯一路径。
- 结果：通过。
- 证据：`README.md:342`；`SKILL.md:128-130,302-304`。

### R4 门禁链路（stable-only）
- 检查：survey 是否禁止消费 draft。
- 结果：通过。
- 证据：`README.md:348`；`SKILL.md:123,370,387`。

## 变更清单

1. `references/paper-template.md`
   - `source_pdf` → `source_file`
   - 路径占位符统一为 `<file>.<ext>`

2. `docs/superpowers/plans/2026-05-04-skill-verify-improve-plan.md`
   - 补充 DoD 量化断言（D1-D6）
   - 补充阶段闸门与 RED/GREEN 证据落盘要求
   - 补充验证报告分层（Static checks / Runtime-like checks）

3. `docs/superpowers/plans/devils_advocate_review.md`
   - 新增唱反调审查报告

## 结论

- P0：0
- P1：0（在当前验证范围内）
- 计划中定义的最小“验证与完善”目标已达成。