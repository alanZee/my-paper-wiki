# 统一失败分级输出模板（v0.1）

7 个 skills 在失败/异常时统一使用三级输出：

- `error`：硬失败，当前步骤立即停止
- `warn`：可继续但必须显式告警，不得默默降级
- `info`：状态说明，不构成失败

## 统一输出结构

- `level`: `error|warn|info`
- `skill`: `wiki-init|wiki-ingest|wiki-query|wiki-audit|wiki-lint|wiki-survey|wiki-update-page`
- `code`: 稳定错误码（如 `MPW-INGEST-NO-SOURCE`）
- `message`: 面向用户的简明说明
- `action`: 下一步建议（可执行）
- `trace_id`: 关键流程必须带 trace_id

## 错误码前缀

| Skill | 前缀 |
|-------|------|
| wiki-init | `MPW-INIT-*` |
| wiki-ingest | `MPW-INGEST-*` |
| wiki-query | `MPW-QUERY-*` |
| wiki-audit | `MPW-AUDIT-*` |
| wiki-lint | `MPW-LINT-*` |
| wiki-survey | `MPW-SURVEY-*` |
| wiki-update-page | `MPW-UPDATE-*` |

## 示例

error：
```json
{"level":"error","skill":"wiki-ingest","code":"MPW-INGEST-NO-SOURCE","message":"source_path 不存在或不可读","action":"检查 source_path 或改用 source_dir","trace_id":"trace-20260504-abcdef12"}
```

warn：
```json
{"level":"warn","skill":"wiki-query","code":"MPW-QUERY-WEAK-EVIDENCE","message":"stable 证据不足，结论存在不确定性","action":"先补 ingest/audit 后再生成确定性结论","trace_id":"trace-20260504-bcdefa34"}
```

info：
```json
{"level":"info","skill":"wiki-lint","code":"MPW-LINT-PASS","message":"lint 检查通过","action":"可继续后续流程","trace_id":"trace-20260504-cdefab56"}
```
