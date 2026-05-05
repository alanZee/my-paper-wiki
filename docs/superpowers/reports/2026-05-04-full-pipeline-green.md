# 完整流水线运行报告（2026-05-05）

## Scope

- 验证目录：`<skill_root>`
- 测试目录：`<workspace_root>`
- 执行模式：纯 SKILL（agent 直接执行，无新增工程化脚本）

## 目标

验证完整流水线闭环：

`init → ingest_raw → 联网元数据查证 → finalize → audit(pass) → survey(门槛判定)`。

## 执行结果

- 输入论文：4 篇 PDF
- `ingest_raw`：完成（原文复制 + PyMuPDF 原文证据 md + pending 页面）
- `metadata verify`：完成（多源链式查证：PDF DOI/arXiv 提取 → Crossref DOI → arXiv API → Google Scholar → Crossref 标题 → OpenAlex → Semantic Scholar）
- `finalize`：完成（生成 final bibkey、final 页面、refs.bib）
- `audit`：完成（Phase A/B 报告生成，4/4 通过并晋级 stable）
- `survey`：按规则判定 `stable_count=4 < 5`，输出 warn，不生成最终 survey/tex

## 元数据查证详情

| 论文 | bibkey | metadata_source | DOI |
|------|--------|----------------|-----|
| Wang & Chu 2025 | wang2025optimisedflowcontr | crossref:doi | 10.1017/jfm.2025.304 |
| Alhashim et al. 2025 | alhashim2025controlofflowbehav | crossref:doi | 10.1073/pnas.2403644122 |
| Wang et al. 2022 | wang2022drlinfluidsanopens | arxiv:id | — |
| Li & Zhang 2021 | li2021reinforcementlearn | arxiv:id | — |

完整证据链见 `outputs/metadata_evidence.json`。

## 关键产物

- `raw/papers/*.pdf`
- `raw/papers/*.md`
- `wiki/papers/_pending/*.md`
- `wiki/papers/*.md`（状态 stable）
- `refs.bib`
- `wiki/index.md`
- `wiki/log.md`
- `outputs/citations.jsonl`
- `outputs/audit/*-audit.md`
- `outputs/survey/survey-warn.md`

## 核验要点

- `wiki/papers/wang2025optimisedflowcontr.md`：
  - `metadata_source: crossref:doi:10.1017/jfm.2025.304`
  - `status: stable`
- `outputs/survey/survey-warn.md`：
  - `stable_count=4 < 5, skip survey generation per rule.`

## E2E 验证

自动化验证脚本 `docs/superpowers/checks/pipeline-verify.py` 对 workspace 执行以下检查，全部通过：

- 目录结构完整性
- 元数据完整性（title/authors/year/venue 无 Unknown/空值）
- 状态机一致性（stable 论文均有审计通过）
- refs.bib 与 wiki/papers 一致性
- 审计报告存在且通过
- survey 门槛判定（stable=4 < 5 → 正确输出 warn）
- 无个人路径泄露
- 日志完整性

## 结论

完整流水线已在 `<workspace_root>` 跑通，并生成可追溯运行产物；由于 stable 数量未达门槛，survey 按规则仅输出告警。自动化验证脚本已替代原有 smoke 测试，覆盖元数据完整性、状态机一致性、审计报告、survey 门槛等全部关键检查点。
