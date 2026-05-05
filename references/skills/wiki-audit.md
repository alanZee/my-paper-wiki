---
name: wiki-audit
description: 审计论文页面，检查引用支撑性，决定是否可晋级 stable。
---
# wiki-audit

对论文页面执行引用审计，作为 draft → stable 的门禁。

## 输入

- 必填：`workspace_root`、`paper_page`

## 流程

- Phase A：识别 uncited factual claims
- Phase B：按来源并行核查支撑性（直引 / 综合性陈述）
- 详细规则见 `references/audit-rules.md`

## 输出

- `pass` 或 `fail`
- 修复项清单
- 审计报告存放在 `outputs/audit/<bibkey>-audit.md`

## 门禁

- pass → 允许 draft → stable
- fail → 保持 draft，需修复后重审
