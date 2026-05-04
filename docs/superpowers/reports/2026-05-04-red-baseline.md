# RED 基线报告（2026-05-04）

## Scope

- 仅检查 `<skill_root>`。
- 显式排除 `.tmp-upstream`。

## Static checks（RED）

### D1 范围断言（7 skills）
- 结果：通过（README 与 SKILL 均定义 7 个 skills）。

### D2 状态机断言
- 断言：`draft -> audit(pass) -> stable` 同时存在于 README 与 SKILL。
- 结果：通过。

### D3 stable-only 断言
- 断言：survey 仅消费 stable paper 在 README/SKILL/audit-rules 三处一致。
- 结果：通过。

### D4 路径隔离断言
- 断言：运行时写入仅限 `workspace_root`，禁止写回 skill 源码目录。
- 结果：通过（README 第 56-60 行、SKILL 第 52-53 行等）。

### D5 模板一致性断言（预期失败）
- 断言：`references/paper-template.md` 字段命名与 SKILL schema 一致（`source_file`）。
- 结果：失败。
- 证据：`references/paper-template.md:7` 为 `source_pdf`，与 `README.md:121`、`SKILL.md:69` 的 `source_file` 冲突。

### D6 错误分级断言
- 断言：`error|warn|info` 结构与字段（`level/skill/code/message/action/trace_id`）在 SKILL 完整存在。
- 结果：通过（见 `SKILL.md:430-468`）。

## Runtime-like checks（RED）

- 尚未执行。按计划待 D5 修复后进入 GREEN 回归并开展 `kb_mpw` 验证。

## RED 结论

- 当前 P0/P1 问题：
  1. 模板字段不一致（`source_pdf` vs `source_file`）【需修复】。
- 进入 GREEN 条件：完成上述最小修复并重跑 D1-D6。
