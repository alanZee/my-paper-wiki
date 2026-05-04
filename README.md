# my-paper-wiki

基于 3 个现有 skill 仓库融合改造，最终仅交付 1 个 skill（`my-paper-wiki`），用于个人学术论文维护与综述写作。

## 融合边界（已定）

| 来源 | 吸收什么 | 不吸收什么 |
|---|---|---|
| **Astro-Han**（基底） | 单 `SKILL.md` + `raw/` + `wiki/<topic>/` + `index/log` 三件套 | — |
| **kfchou** | `wiki-audit` 双 phase 核心；`wiki-update-page` 的 diff-before-write | severity-tier 报告（过度设计） |
| **OmegaWiki** | PDF 摄入回退链（tex > pdf > vision）；`citations.jsonl` 思路；survey skill 思路 | 9 类页面、claim/experiment 建模、双向边图、DeepXiv 依赖、exp-* 全套 |
[skyllwt/OmegaWiki](https://github.com/skyllwt/OmegaWiki)
[kfchou/wiki-skills](https://github.com/kfchou/wiki-skills)
[Astro-Han/karpathy-llm-wiki](https://github.com/Astro-Han/karpathy-llm-wiki)

---

## 1. 背景与目标

my-paper-wiki 是一个跨 Claude Code / Cursor / Codex / OpenCode 的 Agent Skill，遵循 Karpathy LLM Wiki 的持久、增量、可复用理念，并保持轻量。

核心目标：

1. 以论文为原子单元（paper-centric）构建长期知识库；
2. 对论文页面执行严格引用审计（wiki-audit）；
3. 在仅使用 stable 论文页的前提下生成综述草稿（LaTeX）；
4. 使用最小必要结构，不引入重型图谱与复杂外部依赖。

## 2. 范围（v0.1）

包含 7 个 skills：

1. wiki-init
2. wiki-ingest
3. wiki-query
4. wiki-audit
5. wiki-lint
6. wiki-survey
7. wiki-update-page

不在 v0.1 范围内：

- 向量数据库 / Embedding RAG
- Claim/Experiment 全图谱体系
- Daily arXiv 定时抓取
- 多语言框架 i18n 系统
- 重型外部服务默认依赖（如 GROBID/DeepXiv）
- 从零 Python CLI 脚手架与独立工程化实现

## 3. 核心设计原则

1. 轻量优先：仅实现直接服务学术写作的最小闭环。
2. 原子优先：每篇论文对应一个 paper 页面，避免跨文献信息混杂。
3. 审计前置：paper 页不通过审计不得进入 stable。
4. 可追溯优先：每条关键结论应能回溯到来源论文与 bibkey。
5. 兼容优先：使用标准 markdown 相对链接，减少平台绑定。
6. 目录隔离：运行时写入仅允许发生在用户指定 `workspace_root`，skill 源码目录视为固定资产且不可被 skill 自修改。

## 4. 信息架构（Hybrid）

本仓库是 **skill 源码目录**，仅维护规范与模板资产：

```text
my-paper-wiki/
├── SKILL.md
├── README.md
├── references/
│   ├── raw-template.md
│   ├── paper-template.md
│   ├── topic-template.md
│   ├── survey-template.md
│   └── audit-rules.md
└── assets/
    └── glossary.md
```

运行时知识库由 skill 在 `workspace_root` 外部目录创建：

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
└── outputs/
    ├── citations.jsonl
    └── survey/
```

运行时目录职责：

- raw/papers/: 原始 PDF 与提取文本副产物
- wiki/papers/: 论文原子页（唯一强约束实体）
- wiki/topics/: 主题汇总页（可渐进生长）
- wiki/surveys/: 综述草稿页
- outputs/survey/: 导出 LaTeX 文本
- refs.bib: ingest 自动维护的 BibTeX 派生产物
- outputs/citations.jsonl: 引用追踪日志

## 5. 页面 Schema

### 5.1 paper 页面（wiki/papers/<bibkey>.md）

```yaml
---
type: paper
title: "<paper title>"
bibkey: "<authorYearKeyword>"
year: 2024
status: draft   # draft | stable
source_pdf: "../../raw/papers/<file>.pdf"
source_text: "../../raw/papers/<file>.md"
updated: 2026-05-03
tags: [fluid, control]
---
```

正文固定区块：

1. Problem
2. Method
3. Key Results
4. Assumptions & Limits
5. Repro Notes
6. Citations（使用 [@bibkey]）
7. Links（相对链接到 topic/survey）

### 5.2 topic 页面（wiki/topics/<slug>.md）

```yaml
---
type: topic
title: "<topic title>"
status: draft
updated: 2026-05-03
source_papers:
  - ../papers/<bibkey>.md
---
```

### 5.3 survey 页面（wiki/surveys/<slug>.md）

```yaml
---
type: survey
title: "<survey title>"
status: draft
updated: 2026-05-03
source_papers:
  - ../papers/<bibkey>.md
target_output: "../../outputs/survey/<slug>.tex"
---
```

## 6. 链接与引用语义

采用语义分离：

1. 页面内部跳转：标准 markdown 相对链接（如 `../papers/xxx.md`）
2. 文献引用：`[@bibkey]`

说明：

- 不使用 Obsidian 专用 `[[wikilinks]]` 作为主链接机制；
- 不引入独立双向边图文件；
- 通过 lint 扫描保障可达性与一致性。

## 7. 元数据与主键规范（硬约束）

### 7.1 两阶段主键与落盘约束

为解决“未查证不得 final bibkey”与“ingest 必须落盘页面”的冲突，采用两阶段主键：

1. `provisional_key`：摄入阶段临时主键
2. `final_bibkey`：查证完成后的正式主键

约束：

- 未完成查证前，禁止生成 `final_bibkey`；
- 必须先以 `provisional_key` 落盘；
- pending 页面位置：`wiki/papers/_pending/<provisional_key>.md`；
- pending 页面 `status` 固定为 `draft`，不得被 survey 消费。

### 7.2 provisional_key 规则

`provisional_key` 统一形态：`pending-YYYYMMDD-<contenthash8>`

- `YYYYMMDD`：摄入日期（本地时区）
- `contenthash8`：文献源文件内容哈希前 8 位（小写十六进制）
- 幂等键字段：`pdf_hash`（v0.1 字段名保留）

同一内容哈希（字段 `pdf_hash`）的重复 ingest 必须幂等：

- 不重复创建 pending 页面；
- 不重复追加 refs/index/log；
- 仅更新必要字段（时间戳、重试计数、状态）。

### 7.3 final bibkey 生成规则

`final_bibkey` 必须内容正确、准确且规范：

- 形态：`firstAuthorLastName + Year + Keyword`
- 例：`smith2024turbulence`
- Year 以查证后出版年份为准；
- Keyword 采用中等规范词元化：小写、去标点、连字符归一、常见缩写保留；
- 冲突时追加最短必要后缀（a/b 或短 hash），保持可读性。

### 7.4 元数据查证来源与冲突仲裁

当 PDF 元数据不完整或冲突时，必须联网查证。来源优先级：

1. 出版方/期刊官网页面
2. DOI 官方落地页
3. arXiv 页面（如适用）
4. Crossref / OpenAlex / Semantic Scholar（交叉核验）

冲突处理：

- 若高优先级与低优先级冲突，默认高优先级覆盖；
- 若同优先级来源冲突，标记 `metadata_conflict` 并进入人工确认；
- 记录仲裁证据到 `log.md`（来源 URL、字段、裁决结果）。

### 7.5 refs.bib 写入策略（方案 A）

- refs.bib 为 ingest 派生产物；
- 仅在 `final_bibkey` 生成后新增/更新正式条目；
- pending 阶段不写入正式 bib 条目；
- 修改依据以查证元数据为准，不以 PDF 内嵌脏元数据为准。

### 7.6 finalize 迁移规则

当 `provisional_key -> final_bibkey` 发生迁移时，必须一次性完成：

1. `wiki/papers/_pending/<provisional_key>.md` 重命名到 `wiki/papers/<final_bibkey>.md`
2. 更新 `refs.bib` 正式条目
3. 更新 `wiki/index.md` 对应路径
4. 追加 `wiki/log.md` 迁移事件（含 trace_id）
5. 修复内部相对链接中的旧路径引用（若存在）

## 8. 7 个 skills 职责与数据流

### 8.1 wiki-init

职责：初始化目录骨架与基础文件。

- 创建（若缺失）：raw/papers, wiki/*, outputs/survey, refs.bib
- 生成空 index.md, log.md
- 不覆盖已有内容（除非显式 reinit）

### 8.2 wiki-ingest

输入：文献源路径（支持 `.pdf` / `.tex`；可传单文件或 `<文献根目录>` 递归扫描）。

采用双阶段流水线：`ingest_raw` + `ingest_finalize`。

阶段 A：ingest_raw（快速摄入，不阻塞落盘）

1. 复制/登记文献源文件至 raw/papers/
2. 计算内容哈希（幂等键，字段名保持 `pdf_hash`）
3. 提取文本（优先 tex，其次 pdf，最后 vision 回退）
4. 生成 `provisional_key = pending-YYYYMMDD-<pdfhash8>`
5. 生成/更新 `wiki/papers/_pending/<provisional_key>.md`（draft）
6. 更新 `index.md` 与 `log.md`

阶段 B：ingest_finalize（异步定稿）

1. 执行元数据联网查证与冲突仲裁
2. 生成 `final_bibkey`
3. 写入/更新 refs.bib 正式条目
4. 执行 `provisional_key -> final_bibkey` 迁移
5. 记录 finalize 事件

### 8.3 wiki-query

职责：只读 wiki 回答问题。

- 优先读取 stable paper；
- 输出引用包含 `[@bibkey]` 与页面相对路径；
- 可选 save：写入 topic/survey 页（默认 draft）。

### 8.4 wiki-audit

保留核心：Phase A + Phase B + 并行 subagent。

- Phase A：识别 uncited factual claims
- Phase B：按来源并行核查（直引匹配、综合性陈述支撑判断）

判定：

- pass：允许 draft -> stable
- fail：保持 draft，输出修复项

### 8.5 wiki-lint

简化为二元结果：

- pass
- needs-fix

检查项：

- index 一致性
- 断链
- 孤立页
- `[@bibkey]` 在 refs.bib 中存在性

### 8.6 wiki-survey

输入：主题 + 可选风格约束。

流程：

1. 仅消费 stable paper 页
2. 聚合分组（时间/方法/争议）
3. 生成 wiki/surveys/<slug>.md（draft）
4. 导出 outputs/survey/<slug>.tex（使用 `\cite{bibkey}`）

### 8.7 wiki-update-page

职责：页面修订先 diff 再写入。

流程：

1. 计算并展示 diff
2. 确认后写入
3. 更新 index/log
4. 若修改 paper 页实体内容，状态回退到 draft，需重新 audit

## 9. 状态机（硬约束）

```text
paper: draft -> audit(pass) -> stable
stable -> update-page(content-change) -> draft -> audit(pass) -> stable
```

规则：

- survey 仅可引用 stable paper；
- draft paper 不得作为最终综述证据源。

## 10. 错误处理、重试与一致性

### 10.1 统一错误模型

- 输入边界：文件不存在、格式错误、基础文件缺失
- 提取失败：记录并提示，不伪造结论
- 元数据未查证：阻止 `final_bibkey` 与 stable 晋级
- 审计失败：不阻断查询，但阻断 stable 与 survey 最终消费

### 10.2 重试与回退参数

- `max_retries = 3`
- `backoff = 2^n`
- `per_source_timeout = 8s`

### 10.3 并发一致性

保护共享文件：`refs.bib`、`wiki/index.md`、`wiki/log.md`

- 获取写锁
- 写入临时文件
- 原子替换目标文件
- 释放锁

### 10.4 幂等与可恢复

- 幂等键：`pdf_hash`
- 中断后允许按 `pdf_hash` 重入
- 重入时不得重复写入 refs/index/log
- 关键事件写入 `trace_id` 到 `log.md`

## 11. 测试与验收

### 11.1 单元测试

1. `provisional_key` 生成与幂等
2. `final_bibkey` 生成与冲突处理
3. refs.bib 追加/更新与去重
4. index/log 原子更新一致性
5. 状态机转换规则
6. lint pass/fail 判定

### 11.2 集成测试

1. init -> ingest_raw -> ingest_finalize -> audit(pass) -> survey(tex)
2. ingest -> update-page -> draft 回退 -> re-audit
3. query --save -> topic/survey 回写与索引更新
4. 弱网/离线：仅 raw 成功、finalize 入队、stable 被阻断

### 11.3 学术严谨性验收

1. stable paper 必须有审计通过记录
2. survey 不消费 draft paper
3. 关键结论段需具备 `\cite{}`
4. claim-to-citation 抽检可定位且语义一致
5. 综合性陈述需多源支撑或不确定性声明

## 12. 实现顺序建议

1. 初始化与基础文件（wiki-init）
2. ingest + refs.bib 自动维护（含查证钩子）
3. audit 双阶段与状态切换
4. lint pass/fail
5. query / update-page
6. survey 与 LaTeX 导出

## 13. 风险与缓解

1. PDF 文本质量波动：保留原 PDF 路径，审计回源核查
2. 元数据源冲突：采用来源优先级并写入决策日志
3. 综述过度概括：仅 stable 输入 + 引用密度约束
4. 外部源抖动：双阶段 ingest + 重试队列 + 人工介入阈值

## 14. 交付物与验收口径（执行层）

最终交付：

- 一个可直接使用的 `SKILL.md`
- 与 skill 匹配的最小目录与模板
- 可追踪引用输出（`citations.jsonl` 最小实现）

验收口径：

- 边界一致：吸收/不吸收与融合边界表一致
- 流程闭环：ingest、audit、update、survey 可串联
- 学术约束：stable 门禁、引用可追踪、审计可复核
- 交付正确：核心交付物是单 `SKILL.md`，不是 Python 项目
