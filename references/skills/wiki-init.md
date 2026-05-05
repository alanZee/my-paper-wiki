---
name: wiki-init
type: technique
description: Use when workspace_root is missing, lacks wiki/index.md, or user explicitly requests wiki initialization.
---
# wiki-init

在用户指定的 `workspace_root` 下创建运行时目录结构与基础文件。

## 输入

- 必填：`workspace_root`

## 流程

1. 检查 `workspace_root` 是否已存在
2. 创建缺失目录：`raw/papers/`、`wiki/papers/_pending/`、`wiki/topics/`、`wiki/surveys/`、`outputs/audit/`、`outputs/survey/`
3. 初始化空文件：`wiki/index.md`、`wiki/log.md`、`refs.bib`、`outputs/citations.jsonl`
4. 不覆盖已有内容（除非用户显式 reinit）

## 失败路径

- `workspace_root` 指向 skill 源码目录 → 立即拒绝
- 父目录不可写 → 返回失败原因
