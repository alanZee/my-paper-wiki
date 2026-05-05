# 数据契约与运行时约束（v0.1）

## 1) 引用追踪（citations.jsonl）

文件：`<workspace_root>/outputs/citations.jsonl`

最小字段：

| 字段 | 说明 |
|------|------|
| `timestamp` | ISO 8601 时间戳 |
| `source_page` | 引用来源页相对路径 |
| `bibkeys` | 被引用的 bibkey 列表 |
| `claim_span` | 引用所支撑的原文片段 |
| `trace_id` | 流程追踪 ID |

示例：
```json
{"timestamp":"2026-05-04T12:34:56+08:00","source_page":"wiki/surveys/fluid-control.md","bibkeys":["smith2024turbulence"],"claim_span":"方法 A 在 Re=1e5 下优于方法 B。","trace_id":"trace-20260504-abcdef12"}
```

## 2) 元数据冲突记录（wiki/log.md）

当 metadata 冲突进入人工确认，`wiki/log.md` 事件最小字段：

| 字段 | 说明 |
|------|------|
| `timestamp` | 冲突发生时间 |
| `trace_id` | 流程追踪 ID |
| `provisional_key` | 待确认的临时主键 |
| `candidate_final_bibkey` | 候选最终主键 |
| `conflict_fields` | 冲突字段列表 |
| `source_refs` | 来源 URL 与本地路径 |
| `decision` | 最终裁决 |

## 3) 失败重试

- `max_retries = 3`
- `backoff = 2^n`
- `per_source_timeout = 8s`

## 4) 共享文件写入安全

- 共享目标：`refs.bib`、`wiki/index.md`、`wiki/log.md`
- 写入约束：先写临时文件（如 `refs.bib.tmp`），确认内容完整后再重命名覆盖目标文件，避免写入中途崩溃导致文件损坏
- 批量操作时，对共享文件的修改应攒批后一次性写入，避免频繁 open/write/close

## 5) refs.bib 格式规范

- 期刊论文：`@article{bibkey, ..., journal={...}, ...}`
- 预印本：`@article{bibkey, ..., note={Preprint}, eprint={arXiv:XXXX.XXXXX}, ...}`
  - `journal` 字段可省略，但 `note` 或 `eprint` 必须保留，用于标识预印本身份
- 审计报告必须存放在 `outputs/audit/<bibkey>-audit.md`

## 6) 幂等与恢复

- 幂等键：`pdf_hash`
- 中断后允许按 `pdf_hash` 重入
- 重入不得重复追加 refs/index/log
- 关键事件需写入 `trace_id` 到 `wiki/log.md`
