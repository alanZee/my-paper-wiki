---
name: my-paper-wiki
description: Use when building or maintaining a personal paper-centric wiki with strict audit gating, stable-only survey synthesis, and traceable citations.
---

# my-paper-wiki

基于 `Astro-Han/karpathy-llm-wiki` 作为骨架，融合 `kfchou/wiki-skills` 与 `skyllwt/OmegaWiki` 的指定能力，保持 v0.1 轻量闭环。

## 自动路由（用户入口）

用户只需描述需求，skill 自动识别并执行对应流程：

| 用户意图 | 触发词 / 场景 | 自动执行 |
|----------|-------------|---------|
| **初始化文献库** | 给出文献目录 + 空/新 workspace | init → ingest(全量) → finalize → audit → survey |
| **添加新文献** | 给出单个/多个文件路径到已有 workspace | ingest → finalize → audit → survey |
| **查询知识** | `/query` 或自然语言提问 | query |
| **生成综述** | `/survey` 或要求综述/Related Work | survey |
| **修订页面** | `/update` 或要求修改已有页面 | update-page |
| **一致性检查** | `/lint` 或要求健康检查 | lint |
| **全文流水线** | 明确要求"完整跑一遍"或"端到端测试" | init → ingest → finalize → audit → survey + 验证 |

路由规则：
- 若 `workspace_root` 不存在或缺少 `wiki/index.md` → 自动先执行 init
- 若 `workspace_root` 已有完整结构 → 跳过 init，直接进入目标流程
- 若用户同时给出文献目录和 workspace → 批量 ingest 全部文献
- 所有流程全自动执行，不中途询问已确定的参数细节

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
<workspace_root>/
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
source_file: "../../raw/papers/<file>.<ext>"
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

常见触发表达：
- “初始化论文 wiki”
- “创建 my-paper-wiki 目录骨架”
- “先把 workspace 搭好”

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

常见触发表达：
- “ingest 这篇 paper”
- “把这个 PDF 加入 wiki”
- “递归导入 `<文献根目录>` 下文献”

最小调用示例：
- 单文件：`wiki-ingest(workspace_root="<workspace_root>", source_path="<source_path>")`
- 目录模式：`wiki-ingest(workspace_root="<workspace_root>", source_dir="<文献根目录>")`

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
4. 生成 provisional_key：`pending-YYYYMMDD-<contenthash8>`
5. 创建/更新 pending 页（draft）
6. 更新 `wiki/index.md`、`wiki/log.md`

### B) ingest_finalize（v0.1 手动触发）
1. 联网查证 metadata 与冲突仲裁
2. 生成 final_bibkey
3. 写入/更新 `refs.bib`
4. 执行 `provisional_key -> final_bibkey` 迁移
5. 记录 finalize 事件（含 trace_id）

查证与仲裁规则：

**第一步：本地提取（零 token 开销）**
- 从 PDF/Tex 原文件抽取首页文本，识别：标题、作者、年份、DOI、arXiv ID、期刊名
- 若本地提取信息完整且可信（标题+作者+年份均明确），直接使用，不联网
- 提取困难或可信度低时（如 PDF 为扫描件、作者名截断、无 DOI），进入联网查证

**第二步：联网查证（按需、搜到即停）**
- 联网查证由**子代理**执行，使用高性价比模型（如 Haiku），主代理一次性授予搜索权限
- 可用平台：Google Scholar、arXiv、Connected Papers、Crossref、OpenAlex、Semantic Scholar
- 搜索策略：按标题或 DOI/arXiv ID 直接搜索，从搜索结果页提取元数据；必要时访问论文详情页核验
- **搜到一条可信结果即停止**，不遍历全部源
- 仅当结果可疑（作者缺失、标题截断、年份明显错误）时，才换关键词或换平台继续查
- 所有字段均不允许 Unknown/空值：title、authors、year、venue 必须有实际值

**子代理创建示例（跨平台）**

Claude Code：
```
Agent(
    description="查证论文元数据",
    model="haiku",
    prompt="""请查找以下论文的完整元数据（title, authors, year, venue, DOI）：

标题：<title_guess>
arXiv ID：<arxiv_id>
DOI：<doi>

允许访问的学术平台（WebFetch URL 白名单）：
- DOI 解析: https://doi.org/*
- arXiv: https://arxiv.org/abs/*, https://export.arxiv.org/api/*
- Google Scholar: https://scholar.google.com/scholar*
- Connected Papers: https://www.connectedpapers.com/*
- Crossref: https://api.crossref.org/works/*
- OpenAlex: https://api.openalex.org/works*
- Semantic Scholar: https://api.semanticscholar.org/graph/v1/paper/search*

搜索步骤：
1. 若有 DOI，先 WebFetch https://doi.org/<doi>
2. 若有 arXiv ID，WebFetch https://arxiv.org/abs/<arxiv_id>
3. 若上述不足，WebSearch 按标题搜索，逐平台访问直到拿到可信结果

要求：搜到一条可信结果即返回，不遍历全部源。
返回 JSON：{"title":"...","authors":["..."],"year":2024,"venue":"...","doi":"...","source":"..."}
""",
)
```

OpenCode / Codex CLI：
```
task(
    model="haiku",
    tools=["web_search", "web_fetch"],
    allowed_urls=[
        "https://doi.org/*",
        "https://arxiv.org/abs/*",
        "https://export.arxiv.org/api/*",
        "https://scholar.google.com/*",
        "https://www.connectedpapers.com/*",
        "https://api.crossref.org/works/*",
        "https://api.openalex.org/works*",
        "https://api.semanticscholar.org/*",
    ],
    prompt="请查找以下论文的完整元数据...",
)
```

Gemini CLI：
```
# 通过 Gemini 的 agents/skills 机制创建子代理，授予搜索工具与 URL 权限
```

通用原则：
- 子代理使用最小模型（Haiku 级别），节省 token 开销
- 主代理在创建子代理时一次性授予 WebSearch + WebFetch 权限（含学术平台 URL 白名单）
- 子代理返回结构化 JSON 列表，主代理直接消费
- 子代理仅需搜索权限，无需文件读写权限

**并行调度策略**
- 论文数 < 5：单个子代理处理全部论文
- 论文数 ≥ 5：拆分为多个并行子代理，每个子代理至少处理 5 篇论文
- 拆分示例（12 篇论文 → 2 个子代理，各 6 篇）：
  ```
  Agent(description="查证论文元数据 batch-1 (6篇)", model="haiku", prompt="...论文 1-6...")
  Agent(description="查证论文元数据 batch-2 (6篇)", model="haiku", prompt="...论文 7-12...")
  ```
- harness 不支持并行时退化为串行，不影响正确性

**冲突仲裁**
- 高优先级与低优先级冲突时：高优先级覆盖
- 同优先级来源冲突时：标记 `metadata_conflict` 并进入人工确认
- 仲裁证据必须写入 `wiki/log.md`（来源 URL、冲突字段、裁决结果）

迁移必须一次完成：
- 重命名 pending 页到 `wiki/papers/<final_bibkey>.md`
- 更新 refs/index/log
- 修复内部旧路径引用（如存在）

失败路径：
- `source_path` 不存在、不可读或扩展名不在 `.pdf` / `.tex`：立即失败，不写入半成品
- 目录模式下 `source_dir` 不存在、不可读或递归后无 `.pdf` / `.tex`：立即失败，不写入半成品
- metadata 未查证：禁止生成 final_bibkey，保留 pending（draft）
- metadata 字段不完整（title/authors/year/venue 任一为空或 Unknown）：禁止 finalize，必须继续查证
- metadata 冲突且无法自动仲裁：写入冲突日志并进入人工确认
- 同一 `pdf_hash` 重复 ingest：幂等处理，不重复追加 refs/index/log
- 任何目标路径落在 skill 源码目录：立即拒绝

---

## 4.3 wiki-query

触发：用户提出 wiki 问题，或要求基于现有页面生成主题草稿。

常见触发表达：
- “我现在对 X 方向都知道什么？”
- “基于现有 stable 论文回答这个问题”
- “把这个问答保存为 topic/survey 草稿”

最小调用示例：
- 只读问答：`wiki-query(workspace_root="<workspace_root>", question="<question>", save=false)`
- 回写草稿：`wiki-query(workspace_root="<workspace_root>", question="<question>", save=true)`

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

常见触发表达：
- “审计这篇 paper 页是否可升 stable”
- “检查 claim 有没有引用支撑”
- “跑一遍 Phase A/Phase B”

最小调用示例：
- `wiki-audit(workspace_root="<workspace_root>", paper_page="wiki/papers/<bibkey>.md")`

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
- 审计报告（必须落在 `outputs/` 下并在 index/log 留痕）

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

常见触发表达：
- “跑一次 wiki 一致性检查”
- “检查断链和孤立页”
- “看 refs.bib 与引用是否一致”

最小调用示例：
- `wiki-lint(workspace_root="<workspace_root>")`

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

常见触发表达：
- “基于 stable papers 生成某主题综述”
- “导出一版 Related Work LaTeX”
- “按方法脉络整理该主题研究”

最小调用示例：
- `wiki-survey(workspace_root="<workspace_root>", topic="<topic>")`

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

常见触发表达：
- “更新这篇 paper 页里的某段结论”
- “根据新证据修订已有内容”
- “先看 diff 再决定是否写入”

最小调用示例：
- `wiki-update-page(workspace_root="<workspace_root>", target_page="<target_page>", changes="<changes>")`

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

## 4.8 统一失败分级输出模板（执行时格式约束）

为降低执行歧义，7 个 skills 在失败/异常时统一使用三级输出：

- `error`：硬失败，当前步骤立即停止
- `warn`：可继续但必须显式告警，不得默默降级
- `info`：状态说明，不构成失败

统一输出结构（终端或日志均适用）：
- `level`: `error|warn|info`
- `skill`: `wiki-init|wiki-ingest|wiki-query|wiki-audit|wiki-lint|wiki-survey|wiki-update-page`
- `code`: 稳定错误码（如 `MPW-INGEST-NO-SOURCE`）
- `message`: 面向用户的简明说明
- `action`: 下一步建议（可执行）
- `trace_id`: 关键流程必须带 trace_id

推荐错误码前缀：
- `MPW-INIT-*`
- `MPW-INGEST-*`
- `MPW-QUERY-*`
- `MPW-AUDIT-*`
- `MPW-LINT-*`
- `MPW-SURVEY-*`
- `MPW-UPDATE-*`

示例（error）：
```json
{"level":"error","skill":"wiki-ingest","code":"MPW-INGEST-NO-SOURCE","message":"source_path 不存在或不可读","action":"检查 source_path 或改用 source_dir","trace_id":"trace-20260504-abcdef12"}
```

示例（warn）：
```json
{"level":"warn","skill":"wiki-query","code":"MPW-QUERY-WEAK-EVIDENCE","message":"stable 证据不足，结论存在不确定性","action":"先补 ingest/audit 后再生成确定性结论","trace_id":"trace-20260504-bcdefa34"}
```

示例（info）：
```json
{"level":"info","skill":"wiki-lint","code":"MPW-LINT-PASS","message":"lint 检查通过","action":"可继续后续流程","trace_id":"trace-20260504-cdefab56"}
```

---

## 5) 引用追踪（citations.jsonl）

文件：`<workspace_root>/outputs/citations.jsonl`

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
- `source_refs`
- `decision`

说明：`source_refs` 允许同时记录 URL 与本地来源路径（含 `<文献根目录>` 下相对路径）。

---

## 7) 失败重试与并发一致性（运行时约束）

重试与回退参数：
- `max_retries = 3`
- `backoff = 2^n`
- `per_source_timeout = 8s`

并发一致性约束（共享文件）：
- 共享目标：`refs.bib`、`wiki/index.md`、`wiki/log.md`
- 写入流程：获取写锁 -> 写临时文件 -> 原子替换目标文件 -> 释放锁

幂等与恢复：
- 幂等键：`pdf_hash`
- 中断后允许按 `pdf_hash` 重入
- 重入不得重复追加 refs/index/log
- 关键事件需写入 `trace_id` 到 `wiki/log.md`

---

## 8) 执行原则

1. README 是验收基线；上游仓库仅作基底与能力来源，不作为最终边界定义。
2. 先保证流程闭环，再补细节，不引入范围外重特性。
3. 所有运行时写入都发生在 `workspace_root`，不得写回 skill 源码目录。
4. 全自动执行：skill 一旦被调用，应默认在用户给定 `workspace_root` 与文献根目录范围内自动完成 `init -> ingest -> finalize -> audit -> survey` 全流程，不在中途反复向用户询问已被规范确定的细节参数。
5. 一次性权限策略：在流程启动阶段一次性申请本轮所需权限（读文献目录、写运行时目录、必要联网查证）；执行中不重复弹出同类权限请求，除非出现越界写入、破坏性操作或用户显式追加新范围。
6. 非阻塞式沟通：执行过程中只输出阶段进度与最终结果摘要；仅在触发硬失败（error）且无法依据既定规则自动恢复时才中断并请求用户决策。
7. 默认无交互细节模式：凡已在本 SKILL 约束、模板、错误分级中可判定的分支，必须由 skill 自主决策并落盘留痕，不将中间实现细节回抛给用户。
8. 失败可恢复优先：遇到临时失败按 `max_retries` 与回退策略自动重试；超过阈值后写入结构化错误并继续处理其余文献，最终统一输出失败清单。
9. 大批量导入的完成标准：以“文献根目录内可处理文件全部完成 ingest_raw，且可推进者进入 finalize/audit”为批次完成条件，不因单篇异常阻塞整批构建。
10. 权限安全边界不放宽：即便全自动模式启用，也不得突破目录隔离、状态机门禁和引用可追溯约束。
