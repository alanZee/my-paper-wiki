---
name: wiki-query
description: 基于已有 wiki 内容回答问题，可选保存为 topic/survey 草稿。
---
# wiki-query

基于 wiki 中的 stable 论文回答用户问题。

## 输入

- 必填：`workspace_root`、`question`
- 可选：`save`（默认 false）

## 流程

1. 读取 `wiki/papers/*.md`（优先 stable）
2. 读取相关 topics/surveys（如问题涉及）
3. 核验 `[@bibkey]` 在 `refs.bib` 中存在性
4. 生成回答，包含引用与相对页面路径

## 写入

- 默认只读
- `save=true` 时可回写 topic/survey（draft）
- 产生引用时追加 `outputs/citations.jsonl`

## 失败路径

- stable 证据不足 → 标记不确定性，不伪造引用
- 引用 bibkey 不在 refs.bib → 标记 needs-fix
