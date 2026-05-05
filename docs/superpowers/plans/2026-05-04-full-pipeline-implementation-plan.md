# 完整流水线实现计划（2026-05-04）

## 背景

现有执行仅完成 smoke 级验证（占位 metadata/audit），不满足“完整可用流水线”的要求。本次目标是在**纯 SKILL**前提下，由 agent 直接执行完整流程：init → ingest_raw → 联网元数据查证 → finalize → audit → survey，并落盘可追溯产物。

## 最终目标

1. 不新增工程化脚本（保持纯 SKILL 形态）。
2. 在 `<workspace_root>` 完成完整流水线，生成真实可用的运行时产物：
   - `raw/papers/` 与 `raw/papers/*.md`
   - `wiki/papers/_pending/*.md`、`wiki/papers/*.md`
   - `refs.bib`
   - `wiki/index.md`、`wiki/log.md`
   - `outputs/citations.jsonl`
   - `outputs/audit/*.md`
   - `wiki/surveys/*.md` 与 `outputs/survey/*.tex`（若满足 stable 数量门槛）
3. metadata 查证来源符合优先级规则；final_bibkey 可复核。
4. audit 结果可追溯，paper 状态符合 `draft -> audit(pass) -> stable`。
5. 全程不在 skill 源码目录写入运行时产物。

## 关键流程与阶段性目标

| 阶段 | 目标 | 产物 | 验证方式 |
|---|---|---|---|
| P0 准备 | 确认输入与边界 | 运行清单 | 路径边界检查 | 
| P1 ingest_raw | 原文落盘 + pending 页 | raw/papers + pending 页 | index/log 更新 | 
| P2 metadata 查证 + finalize | 真实 bibkey 与 refs.bib | final paper + refs.bib | 元数据来源记录 | 
| P3 audit | 通过审计并晋级 stable | audit 报告 + stable 状态 | 报告与状态一致 | 
| P4 survey | 生成综述或输出证据不足 | survey/tex 或 warn | 规则一致性 | 
| P5 报告 | 运行证据归档 | 运行报告 | 不含个人路径 | 

## 详细任务清单

1. **准备与边界确认**
   - 读取 `<文献根目录>` 中可用 `pdf/tex`。
   - 确认 `<workspace_root>` 不指向 `<skill_root>`。
   - 验证是否需要清理旧的 runtime 产物（见“待确认”）。

2. **ingest_raw（逐篇）**
   - 复制源文件到 `raw/papers/`。
   - 生成 `raw/papers/<file>.md`（抽取标题/作者/摘要等最小原文证据）。
   - 生成 pending 页并写入 index/log。

3. **联网元数据查证（逐篇）**
   - 以出版方/DOI/arXiv/Crossref 等来源核验：title、authors、year、venue、doi/url。
   - 记录查证来源与冲突仲裁（写入 log 事件）。

4. **finalize（逐篇）**
   - 生成 `final_bibkey`。
   - 迁移 pending → final paper。
   - 写入/更新 `refs.bib`。
   - 更新 index/log。

5. **audit（逐篇）**
   - Phase A：识别所有事实性陈述。
   - Phase B：核对每条陈述的引用支撑（必须带 `[@bibkey]`）。
   - 产出 `outputs/audit/<bibkey>-audit.md`。
   - 通过后晋级 stable，更新 index/log。

6. **survey**
   - 若 stable 数量 ≥ 5：生成 `wiki/surveys/<slug>.md` 与 `outputs/survey/<slug>.tex`。
   - 若 < 5：输出 warn 并不生成最终综述（保持规则一致）。

7. **验证与报告**
   - 复查：index/log/refs/outputs 与状态机一致。
   - 生成 `docs/superpowers/reports/2026-05-04-full-pipeline-green.md`（无个人路径）。

## 验收标准

- 真实 metadata 查证与 refs.bib 完整可追溯。
- 每篇 final paper 均通过 audit 且 `status: stable`。
- 运行时产物齐全且路径不越界。
- 报告无个人路径信息。

## 待确认（一次性）

1. **清理策略**（避免污染新结果）：
   - A) 清理 `<workspace_root>` 下既有 `wiki/outputs/refs.bib/raw/papers` 再重建（保留原始输入目录）。
   - B) 另建新的 `<workspace_root>` 运行，保留旧产物。
   - 默认建议：A（结果更干净）。

2. **survey 门槛**：当前可用论文 < 5 时，是否允许降低门槛输出综述？
   - 默认：不降低，输出 warn 并不生成最终综述。

3. **依赖**：若需要更稳定的 PDF 抽取，是否允许临时安装 `pymupdf`？
   - 默认：优先使用内置 Read；不足时再安装。
