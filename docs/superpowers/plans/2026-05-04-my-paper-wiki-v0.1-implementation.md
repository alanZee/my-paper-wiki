# my-paper-wiki v0.1 实施计划（README 对齐版）

## 1. 目标与完成定义

最终交付：

1. 一个可直接使用的 `SKILL.md`
2. 与 skill 匹配的最小目录与模板
3. 可追踪引用输出（最小 `citations.jsonl`）

完成定义（DoD）：

- 与 README 的“融合边界 / 范围（v0.1）/ 状态机 / 验收口径”逐项一致
- 7 个 skills 的职责、输入输出、门禁规则一致
- 文档内无 Python 工程化交付导向、无越界重特性

## 2. 强约束（执行时必须满足）

1. 仅交付单 skill 规范，不转向独立 Python CLI 项目。
2. paper 页必须遵守 `draft -> audit(pass) -> stable` 状态机。
3. survey 仅可消费 stable paper。
4. ingest 采用两阶段主键：`provisional_key` 与 `final_bibkey`。
5. pending 页面固定落在 `wiki/papers/_pending/`，且不进入 survey 证据链。
6. 运行时目录由用户显式指定 `workspace_root`（不得在文档中硬编码个人路径）。
7. skill 源码目录是固定资产，skill 不得在运行流程中自修改 `SKILL.md`、`README.md`、`references/`、`assets/`。

## 3. 范围对齐（以 README 为准）

### 3.1 范围内（v0.1）

1. wiki-init
2. wiki-ingest
3. wiki-query
4. wiki-audit
5. wiki-lint
6. wiki-survey
7. wiki-update-page

### 3.2 范围外（v0.1 不做）

1. 向量数据库 / Embedding RAG
2. Claim/Experiment 全图谱体系
3. Daily arXiv 定时抓取
4. 多语言 i18n 框架
5. 重型外部默认依赖（如 GROBID/DeepXiv）
6. 从零 Python CLI 脚手架与独立工程化实现

## 4. 执行阶段与里程碑

### 阶段 A：骨架与 schema 对齐

目标：目录结构、页面 schema、链接与引用语义与 README 一致。

产出：

- 目录骨架定义（`raw/`、`wiki/`、`outputs/`、`references/`、`assets/`）
- paper/topic/survey frontmatter 与正文区块约束
- `[@bibkey]` 与相对链接并行语义约束

验收：可用 checklist 逐项勾选，无歧义字段。

### 阶段 B：7 skills 行为对齐

目标：每个 skill 都有可执行的输入、输出、门禁与失败路径。

产出：

- wiki-init：仅初始化，不覆盖已有内容
- wiki-ingest：`ingest_raw + ingest_finalize` 双阶段
- wiki-query：优先 stable，输出路径 + `[@bibkey]`
- wiki-audit：Phase A/Phase B + pass/fail 门禁
- wiki-lint：pass / needs-fix 二元判定
- wiki-survey：stable-only + `\cite{}` 导出
- wiki-update-page：diff-before-write + 内容变更回退 draft

验收：任一 skill 都能在文档层回答“何时触发、读写哪些文件、失败时如何处理”。

### 阶段 C：一致性与越界清理

目标：清理所有与 README 冲突、重复或越界描述。

产出：

- 删除重型图谱与额外工程化叙述
- 术语统一（draft/stable、pending/finalize）
- 状态机、验收口径、交付口径三处一致

验收：反向扫描“不吸收清单”零命中。

## 5. 可执行任务清单（顺序）

- [x] T1：对齐目录与模板清单（按 README 信息架构）
- [x] T2：固化 paper/topic/survey schema 与正文结构
- [x] T3：固化 ingest 两阶段与主键迁移规则
- [x] T4：固化 audit 双阶段门禁与 stable 晋级条件
- [x] T5：固化 lint 的四类检查项与二元输出
- [x] T6：固化 query / update-page / survey 的 I/O 与状态约束
- [x] T7：补齐 `citations.jsonl` 最小字段与写入时机
- [x] T8：全篇反向扫描并移除越界项
- [x] T9：端到端流程走查：ingest → audit → update → survey（基于用户显式提供的 `workspace_root`）
- [x] T10：固化目录隔离约束（runtime 仅写 `workspace_root`；skill 源码目录固定且不可自修改）
- [x] T11：移除文档中的硬编码个人路径，统一为通用占位符（`<workspace_root>` / `<source_path>` / `<文献根目录>`）

T9 走查记录（文档级）：
1. `wiki-init(workspace_root="<workspace_root>")`：仅初始化运行时目录，不触碰 skill 源码目录。
2. `wiki-ingest(workspace_root="<workspace_root>", source_path="<source_path>")` 或 `wiki-ingest(workspace_root="<workspace_root>", source_dir="<文献根目录>")`：先写 pending（draft），再 finalize 迁移为 final_bibkey。
3. `wiki-audit(workspace_root="<workspace_root>", paper_page="wiki/papers/<bibkey>.md")`：仅 pass 才允许 stable。
4. `wiki-update-page(workspace_root="<workspace_root>", target_page="wiki/papers/<bibkey>.md", changes=...)`：diff-before-write；实体变更触发 stable→draft。
5. `wiki-survey(workspace_root="<workspace_root>", topic="<topic>")`：仅消费 stable papers，导出 `outputs/survey/<slug>.tex`。

T9 验收结果（文档一致性）：
- 状态机闭环成立：`draft -> audit(pass) -> stable` 与 update 回退规则一致。
- stable-only 门禁成立：survey 输入明确限制为 stable。
- 目录隔离成立：所有写操作目标均为 `workspace_root`，不改写 skill 源码目录。
- 可追踪性成立：`citations.jsonl` 最小字段与写入时机已定义。

下一执行项：如需进入真实运行时验证，按用户指定 `workspace_root` 手工执行并记录一次示例 log。

## 6. 阻塞点与决策点（一次性澄清）

需尽早确认的决策：

1. `citations.jsonl` 的最小字段集（建议：timestamp、source_page、bibkeys、claim_span、trace_id）。
2. `ingest_finalize` 的触发方式（手动触发 / 队列触发）在 v0.1 的文档口径。
3. metadata 冲突进入人工确认时，在 `log.md` 的记录最小字段。

说明：以上三点若不确认，会影响 T3/T7/T9 的一致性验收。

## 7. 验收清单（最终）

1. 边界一致：吸收/不吸收与 README 表格一致。
2. 流程闭环：ingest、audit、update、survey 可串联。
3. 学术约束：stable 门禁、引用可追踪、审计可复核。
4. 交付正确：核心交付物是单 `SKILL.md`，非 Python 工程。
5. 文档可执行：每条规则均可映射到具体文件与操作。