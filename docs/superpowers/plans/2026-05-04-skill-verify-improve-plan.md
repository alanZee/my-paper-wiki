# my-paper-wiki skill 项目验证与完善计划（2026-05-04）

## 1. 背景

用户要求：

1. 验证并完善当前 skill 项目（目录：`<skill_root>`）。
2. 明确 `.tmp-upstream` 仅为参考仓，不属于本项目，不得纳入验证结论。
3. 使用测试根目录 `<workspace_root>`（其中含 4 篇文献样本）进行可执行性验证。

现状要点（已核对）：

- 项目核心文件：`SKILL.md`、`README.md`、`references/*`、`assets/*`。
- 已有 v0.1 实施计划：`docs/superpowers/plans/2026-05-04-my-paper-wiki-v0.1-implementation.md`。
- 需要做的是“验证与完善”，不是另起炉灶重写项目。

## 2. 最终目标（DoD）

本轮完成时必须满足：

1. `SKILL.md` 与 `README.md` 关键边界一致（范围内/范围外、状态机、目录隔离、stable-only）。
2. `references/` 模板与 `SKILL.md` 声明的 schema/流程一致，关键字段可落地。
3. 在 `kb_mpw` 测试根目录上完成一轮最小可执行验证（覆盖输入约束、路径边界、状态机门禁、stable-only）。
4. 发现的问题有“已修复”或“明确暂缓+原因+后续建议”。

DoD 量化断言（必须全部通过）：

- D1（范围断言）：7 个 skills 在 `README.md` 与 `SKILL.md` 同时出现且职责不冲突。
- D2（状态机断言）：`draft -> audit(pass) -> stable` 在 `README.md` 与 `SKILL.md` 均存在。
- D3（stable-only 断言）：survey 输入仅允许 stable paper，在 `README.md`、`SKILL.md`、`references/audit-rules.md` 一致。
- D4（路径隔离断言）：运行时写入目标仅在 `workspace_root`，且明确禁止写回 skill 源码目录。
- D5（模板一致性断言）：`references/*-template.md` 关键字段与 `SKILL.md` schema 一致（含 `source_file` 字段命名）。
- D6（错误分级断言）：`error|warn|info` 结构与关键字段（`level/skill/code/message/action/trace_id`）在 `SKILL.md` 完整存在。

## 3. 关键流程与阶段目标

### 阶段 A：边界冻结（只读审计）

目标：先证明“哪里不一致”，再动手改。

动作：

1. 仅扫描本项目文件（显式排除 `.tmp-upstream`）。
2. 对齐矩阵（README vs SKILL vs references 模板）：
   - 技能范围（7 skills）
   - 状态机约束
   - 路径边界（workspace_root 外部化）
   - 输入参数命名一致性
   - 失败分级与日志字段一致性
3. 产出问题清单：按 P0/P1/P2 分级。

阶段验收：问题清单可直接驱动修改，无“描述性空话”。

### 阶段 B：最小修复（TDD 方式）

目标：先写验证（RED），再改文档/模板（GREEN），再收敛（REFACTOR）。

动作：

1. 为每个 P0/P1 问题定义可验证断言（文本断言或结构断言）。
2. 先运行断言并记录失败（RED）。
3. 只修改必要文件（优先 `SKILL.md`、`README.md`、`references/*`）。
4. 回归验证所有断言通过（GREEN）。
5. 清理重复/矛盾表述（REFACTOR）。

阶段验收：所有 P0/P1 断言通过，且未引入范围外内容。

### 阶段 C：测试根目录实测（运行时约束验证）

目标：用 `kb_mpw` 做最小实操验证，证明规则可执行。

前置闸门：仅当 P0 问题清零后允许进入阶段 C。

动作：

1. 校验测试目录结构是否与 `workspace_root` 约束一致。
2. 基于 4 篇文献样本做“输入面”验证：
   - 支持格式识别（pdf/tex）
   - 路径越界拒绝（不得写回 skill 源码目录）
3. 增补门禁验证：
   - 状态机门禁文本是否完整（`draft -> audit(pass) -> stable`）
   - stable-only 文本是否完整（survey 仅消费 stable）
4. 输出验证记录（通过/失败/证据路径）。

阶段验收：至少 1 条正向链路 + 1 条边界链路 + 2 条门禁链路被验证。

## 4. 详细任务清单

1. [ ] 构建审计矩阵（README/SKILL/references）。
2. [ ] 生成差异清单并分级（P0/P1/P2）。
3. [ ] 为 P0/P1 差异写可执行断言（先失败）。
4. [ ] 记录 RED 证据到 `docs/superpowers/reports/2026-05-04-red-baseline.md`。
5. [ ] 最小化编辑修复差异。
6. [ ] 回归断言并记录 GREEN 证据到 `docs/superpowers/reports/2026-05-04-green-regression.md`。
7. [ ] 对 `kb_mpw` 执行最小实测验证并记录证据。
8. [ ] 输出最终总结：修改文件、验证结果、遗留项与建议。

阶段切换规则：

- 阶段 A 完成并冻结问题清单后，才允许进入阶段 B。
- 阶段 B 完成且 P0=0 后，才允许进入阶段 C。

## 5. 不确定点与一次性确认策略

本轮按“先执行后汇报”推进；仅在以下情况中断请求确认：

1. 需要引入新文件但位置/命名存在歧义。
2. 需要更改用户未明确授权的高风险内容（删除大量文件、重命名关键结构）。
3. 测试目录实际结构与既定规则冲突，导致无法定义“通过标准”。
4. 外部依赖不可用（如联网查证不可执行）导致验证范围需要降级。

其余显而易见低风险修复（措辞统一、模板字段补齐、路径占位符修正）直接执行。

暂缓项记录模板（如出现）：

- 问题：
- 影响：
- 暂缓原因：
- 恢复触发条件：
- 建议处理窗口：
- 优先级（P0/P1/P2）：
- 负责人：
- 关联证据：

验证报告结构约束：

- `Static checks`：文档与模板一致性、关键词与门禁断言
- `Runtime-like checks`：基于 `kb_mpw` 的输入与路径边界验证
- 两类结果分开记录，避免“静态通过 = 运行通过”的误判。

## 6. 权限与边界声明

1. 只在 `my-paper-wiki` 与 `kb_mpw` 范围内读写。
2. `.tmp-upstream` 仅可读参考，不纳入结果，也不修改。
3. 不做 git push / 远程变更。
4. 不新增范围外工程化实现（Python CLI、RAG、图谱系统等）。

## 7. 唱反调审查重点（待执行）

在进入实施前，用 devils-advocate 对本计划重点挑战：

1. 是否存在“看起来完整但不可验证”的条目。
2. 是否把“文档一致性”误当成“运行可执行性”。
3. 是否遗漏了最可能失败的边界条件（路径越界、状态机门禁、stable-only）。
4. 是否出现超范围改造风险。

审查后必须据审查意见修订本计划，再开始实施。

## 8. 审查驱动变更日志（2026-05-04）

来源：`docs/superpowers/plans/devils_advocate_review.md`

已采纳（必须修改）：

1. 为 DoD 增加量化断言 D1-D6（避免主观“完成假象”）。
2. 在阶段 C 增加状态机门禁与 stable-only 门禁验证。
3. 增加 RED/GREEN 证据落盘要求（`docs/superpowers/reports/*.md`）。

已采纳（强烈建议）：

1. 增加阶段闸门：阶段 A 冻结问题清单后才可进 B；P0 清零后才可进 C。
2. 验证报告按 `Static checks` / `Runtime-like checks` 分离，避免误判。
3. 补充外部依赖不可用时的降级确认分支。

暂未采纳（可选优化）：

1. 自动关键词扫描脚本（本轮先采用手工+grep，后续可补脚本化）。
2. P0/P1/P2 示例库（本轮不阻塞执行）。
3. 更细颗粒的暂缓项模板自动生成器（本轮不阻塞执行）。

关联证据：

- RED：`docs/superpowers/reports/2026-05-04-red-baseline.md`
- GREEN：`docs/superpowers/reports/2026-05-04-green-regression.md`
- 审查：`docs/superpowers/plans/devils_advocate_review.md`

本计划在上述修订后进入执行，并已完成本轮验证。
