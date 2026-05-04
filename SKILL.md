---
name: my-paper-wiki
description: Use when building or maintaining a personal paper-centric wiki with strict audit gating, stable-only survey synthesis, and traceable citations.
---

# my-paper-wiki

基于 `Astro-Han/karpathy-llm-wiki` 作为骨架，融合 `kfchou/wiki-skills` 与 `skyllwt/OmegaWiki` 的指定能力，保持 v0.1 轻量闭环。

## 0) 先决边界（必须遵守）

1. 本仓库是 **skill 源码目录**，不是运行时知识库目录。
2. skill 只维护规范与模板；实际 wiki 数据必须写入用户指定的独立 workspace。
3. v0.1 只交付单 `SKILL.md` 规范，不转向独立 Python CLI 工程。
4. paper 状态机固定：`draft -> audit(pass) -> stable`。
5. survey 仅消费 stable paper。
6. 运行时目录必须由用户显式提供 `workspace_root`（示例：`<workspace_root>`）。
7. skill 在任何流程中都不得改写本 skill 源码目录内容。

不做（v0.1 范围外）：向量库/RAG、claim/experiment 全图谱、daily arXiv、i18n 框架、重型外部默认依赖（GROBID/DeepXiv）、从零 CLI 工程化。

---

## 1) 运行时 workspace 结构（由 wiki-init 在外部目录创建）

以下目录是 **运行时目录**，不是本 skill 仓库目录：

```text
<workspace>/
├── refs.bib
├── raw/
│   └── papers/
├── wiki/
│   ├── index.md
│   ├── log.md
│   ├── papers/
│   │   └── _pending/
│   ├── topics/
│   └── surveys/
├── outputs/
│   ├── citations.jsonl
│   └── survey/
```

本仓库 `references/` 下文件是模板资产，用于生成运行时页面。

### 1.1 最小调用示例（避免目录角色混淆）

- `wiki-init(workspace_root="<workspace_root>")`
- `wiki-ingest(workspace_root="<workspace_root>", source_path="<source_path>")`
- `wiki-query(workspace_root="<workspace_root>", question="...", save=false)`

约束：`workspace_root` 必须是用户显式指定的外部目录，不得指向本 skill 源码目录。
补充：skill 只允许在 `workspace_root` 写入运行时数据；不得修改本仓库内的 `SKILL.md`、`README.md`、`references/`、`assets/`。

---

## 2) 页面 schema（运行时）

### 2.1 paper: `wiki/papers/<bibkey>.md`

```yaml
---
type: paper
title: "<paper title>"
bibkey: "<authorYearKeyword>"
year: 2024
status: draft
source_pdf: "../../raw/papers/<file>.pdf"
source_text: "../../raw/papers/<file>.md"
updated: 2026-05-04
tags: []
---
```

固定正文区块：
- Problem
- Method
- Key Results
- Assumptions & Limits
- Repro Notes
- Citations（`[@bibkey]`）
- Links（相对链接）

### 2.2 topic: `wiki/topics/<slug>.md`

```yaml
---
type: topic
title: "<topic title>"
status: draft
updated: 2026-05-04
source_papers:
  - ../papers/<bibkey>.md
---
```

### 2.3 survey: `wiki/surveys/<slug>.md`

```yaml
---
type: survey
title: "<survey title>"
status: draft
updated: 2026-05-04
source_papers:
  - ../papers/<bibkey>.md
target_output: "../../outputs/survey/<slug>.tex"
---
```

---

## 3) 主键与状态硬约束

### 3.1 两阶段主键

- `provisional_key`: `pending-YYYYMMDD-<pdfhash8>`
- `final_bibkey`: `firstAuthorLastName + Year + Keyword`

规则：
- 未查证前禁止生成 final_bibkey。
- 必须先落盘 pending 页：`wiki/papers/_pending/<provisional_key>.md`。
- pending 页 `status` 固定 `draft`，不可进入 survey。

### 3.2 状态机

```text
paper: draft -> audit(pass) -> stable
stable -> update-page(content-change) -> draft -> audit(pass) -> stable
```

---

## 4) 7 个 skills（v0.1）

## 4.1 wiki-init

触发：首次使用、workspace 缺失，或用户显式要求初始化。

输入：
- 必填：`workspace_root`（运行时目录）

读取：
- 检查 `workspace_root` 是否已存在目录/文件

写入：
- 仅在 `workspace_root` 创建缺失结构（见第 1 节）
- 初始化空 `wiki/index.md`、`wiki/log.md`、`refs.bib`、`outputs/citations.jsonl`

失败路径：
- 若 `workspace_root` 指向 skill 源码目录：立即拒绝并要求改用外部路径
- 若目录已存在：仅补缺失项，不覆盖已有内容（除非用户显式 reinit）
- 若父目录不可写：返回失败原因并停止

---

## 4.2 wiki-ingest

触发：用户提供单个文献源文件（`.pdf` / `.tex`），或要求从 `<文献根目录>` 递归摄入文献源文件。

输入：
- `workspace_root`
- 二选一：`source_path`（单文件，支持 `.pdf` / `.tex`）或 `source_dir`（目录模式，使用 `<文献根目录>`）

读取：
- `source_path` 或 `source_dir/**/*.{pdf,tex}`
- 已有 `wiki/papers/` 与 `wiki/papers/_pending/`（用于幂等判断）

写入：
- `raw/papers/`
- `wiki/papers/_pending/` 或 `wiki/papers/`
- `wiki/index.md`
- `wiki/log.md`
- `refs.bib`（仅 finalize 后）

流程分两段：`ingest_raw + ingest_finalize`

### A) ingest_raw（快速落盘）
1. 复制/登记文献源文件到 `raw/papers/`
2. 计算内容哈希（幂等键字段名保留为 `pdf_hash`）
3. 文本提取回退链：`tex > pdf > vision`
4. 生成 provisional_key
5. 创建/更新 pending 页（draft）
6. 更新 `wiki/index.md`、`wiki/log.md`

### B) ingest_finalize（v0.1 手动触发）
1. 联网查证 metadata 与冲突仲裁
2. 生成 final_bibkey
3. 写入/更新 `refs.bib`
4. 执行 `provisional_key -> final_bibkey` 迁移
5. 记录 finalize 事件（含 trace_id）

迁移必须一次完成：
- 重命名 pending 页到 `wiki/papers/<final_bibkey>.md`
- 更新 refs/index/log
- 修复内部旧路径引用（如存在）

失败路径：
- `source_path` 不存在、不可读或扩展名不在 `.pdf` / `.tex`：立即失败，不写入半成品
- 目录模式下 `source_dir` 不存在、不可读或递归后无 `.pdf` / `.tex`：立即失败，不写入半成品
- metadata 未查证：禁止生成 final_bibkey，保留 pending（draft）
- metadata 冲突且无法自动仲裁：写入冲突日志并进入人工确认
- 同一 `pdf_hash` 重复 ingest：幂等处理，不重复追加 refs/index/log
- 任何目标路径落在 skill 源码目录：立即拒绝

---

## 4.3 wiki-query

触发：用户提出 wiki 问题，或要求基于现有页面生成主题草稿。

输入：
- `workspace_root`
- `question`
- 可选 `save`

读取：
- `wiki/papers/*.md`（优先 stable）
- `wiki/topics/*.md`、`wiki/surveys/*.md`（如问题涉及）
- `refs.bib`（核验 `[@bibkey]`）

输出：
- 优先使用 stable paper 回答
- 回答中包含 `[@bibkey]` 与相对页面路径

写入：
- 默认只读
- `save` 时可回写 topic/survey（默认 draft）
- query/survey 产生引用输出时，追加写入 `outputs/citations.jsonl`

失败路径：
- 若无足够 stable 证据：明确标记不确定性，不得伪造引用
- 若 `save` 目标路径越界到 skill 源码目录：拒绝写入
- 若引用 bibkey 不在 `refs.bib`：标记 needs-fix，停止写入引用追踪

---

## 4.4 wiki-audit

触发：ingest 后的高价值论文审计，或 stable 晋级前审计。

输入：
- `workspace_root`
- `paper_page`

读取：
- 目标 `paper_page`
- 其正文中的 `[@bibkey]` 与相关来源页/原始文本

流程：
- Phase A：识别 uncited factual claims
- Phase B：按来源并行核查支撑性（直引 / 综合性陈述）

输出：
- `pass` 或 `fail`
- 修复项清单
- 审计报告（建议落在 `outputs/` 下并在 index/log 留痕）

写入：
- 追加 `wiki/log.md`
- 更新 `wiki/index.md`（登记审计报告）
- 若 pass 且用户执行晋级：更新 paper `status: stable`

门禁：
- pass 才允许 `draft -> stable`
- fail 保持 draft

失败路径：
- 页面不存在：立即失败
- 引用源不可达：标记 source-missing，不得判定为 supported
- 存在 uncited factual claims：直接 fail
- 审计失败时禁止 stable 晋级

---

## 4.5 wiki-lint

触发：周期性健康检查，或 ingest/audit/update 后一致性校验。

输入：
- `workspace_root`

读取：
- `wiki/index.md`
- `wiki/papers/`、`wiki/topics/`、`wiki/surveys/`
- `refs.bib`

检查项：
- index 一致性
- 断链
- 孤立页
- `[@bibkey]` 在 `refs.bib` 存在性

输出仅二元：
- `pass`
- `needs-fix`

写入：
- 仅在用户明确要求落盘时写 lint 报告；否则终端报告

失败路径：
- 基础文件缺失（index/log/refs）：直接 `needs-fix`
- 检查过程中发现越界路径：直接 `needs-fix` 并停止自动修复

---

## 4.6 wiki-survey

触发：用户要求生成某主题综述草稿或 Related Work 草稿。

输入：
- `workspace_root`
- `topic`
- 可选风格约束

读取：
- `wiki/papers/*.md`（仅 `status: stable`）
- `wiki/topics/*.md`（用于主题分组）
- `refs.bib`

流程：
1. 仅消费 stable paper
2. 按时间/方法/争议聚合（避免平铺罗列）
3. 生成 `wiki/surveys/<slug>.md`（draft）
4. 导出 `outputs/survey/<slug>.tex`（使用 `\cite{bibkey}`）

写入：
- `wiki/surveys/<slug>.md`
- `outputs/survey/<slug>.tex`
- `outputs/citations.jsonl`
- `wiki/log.md`

失败路径：
- stable 论文不足（<5）：返回“证据不足”并建议先 ingest/audit，不输出最终综述
- 出现未在 `refs.bib` 的 bibkey：标记未确认，不得伪造 `\cite{}`
- 不得直接改写 paper/topic 正文，只允许新增 survey 产物

---

## 4.7 wiki-update-page

触发：用户要求修订既有页面，或根据新证据修正既有结论。

输入：
- `workspace_root`
- `target_page`
- `changes`

读取：
- `target_page` 当前全文
- 相关来源（URL/本地文件/已入库页面）
- `wiki/index.md`（同步摘要）

流程：
1. 必须 diff-before-write
2. 逐页确认（不批量盲写）
3. 用户确认后写入
4. 更新 `wiki/index.md` 与 `wiki/log.md`
5. 若修改 paper 实体内容，状态回退 draft，并要求重新 audit

失败路径：
- 变更无来源依据：拒绝写入
- 目标页不存在：立即失败
- 目标页在 skill 源码目录：拒绝写入
- 关联页面可能受影响但未处理：至少给出明确告警

---

## 5) 引用追踪（citations.jsonl）

文件：`<workspace>/outputs/citations.jsonl`

最小字段：
- `timestamp`
- `source_page`
- `bibkeys`
- `claim_span`
- `trace_id`

示例：

```json
{"timestamp":"2026-05-04T12:34:56+08:00","source_page":"wiki/surveys/fluid-control.md","bibkeys":["smith2024turbulence"],"claim_span":"方法 A 在 Re=1e5 下优于方法 B。","trace_id":"trace-20260504-abcdef12"}
```

---

## 6) 元数据冲突记录最小字段（log）

当 metadata 冲突进入人工确认，`wiki/log.md` 事件最小字段：
- `timestamp`
- `trace_id`
- `provisional_key`
- `candidate_final_bibkey`
- `conflict_fields`
- `source_urls`
- `decision`

---

## 7) 执行原则

1. README 是验收基线；上游仓库仅作基底与能力来源，不作为最终边界定义。
2. 先保证流程闭环，再补细节，不引入范围外重特性。
3. 所有运行时写入都发生在 `workspace_root`，不得写回 skill 源码目录。
