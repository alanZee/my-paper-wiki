---
name: wiki-lint
description: 一致性健康检查：断链、孤立页、refs.bib 引用匹配。
---
# wiki-lint

执行 wiki 一致性检查，输出二元结果。

## 输入

- 必填：`workspace_root`

## 检查项

- index 一致性
- 断链与孤立页
- `[@bibkey]` 在 refs.bib 中存在性

## 输出

- `pass`：全部通过
- `needs-fix`：发现不一致

## 写入

- 默认终端报告
- 仅用户明确要求时才落盘 lint 报告
