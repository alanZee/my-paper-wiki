---
name: wiki-survey
description: 基于 stable 论文生成主题综述草稿与 LaTeX 导出。
---
# wiki-survey

基于 stable 论文生成主题综述，导出 LaTeX。

## 输入

- 必填：`workspace_root`、`topic`
- 可选：风格约束

## 流程

1. 仅消费 stable paper
2. 按时间/方法/争议聚合（避免平铺罗列）
3. 生成 `wiki/surveys/<slug>.md`（draft）
4. 导出 `outputs/survey/<slug>.tex`（使用 `\cite{bibkey}`）
5. 追加 `outputs/citations.jsonl`、`wiki/log.md`

## 失败路径

- stable 论文不足（<5）→ 返回"证据不足"，不生成综述
- bibkey 不在 refs.bib → 标记未确认，不得伪造 `\cite{}`
