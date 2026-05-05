# my-paper-wiki 设计手册

> 本文档记录设计决策与权衡取舍，供人类开发者参考。
> Agent 执行规范见 [SKILL.md](../SKILL.md)，运行时约束见 [data-contracts.md](../references/data-contracts.md)。

## 1. 融合边界

基于 3 个现有 skill 仓库融合改造，最终仅交付 1 个 skill（`my-paper-wiki`）。

| 来源 | 吸收什么 | 不吸收什么 |
|---|---|---|
| **Astro-Han/karpathy-llm-wiki**（基底） | 单 `SKILL.md` + `raw/` + `wiki/` + `index/log` 三件套 | — |
| **kfchou/wiki-skills** | `wiki-audit` 双 phase 核心；`wiki-update-page` 的 diff-before-write | severity-tier 报告（过度设计） |
| **skyllwt/OmegaWiki** | PDF 摄入回退链（tex > pdf > vision）；`citations.jsonl` 思路；survey skill 思路 | 9 类页面、claim/experiment 建模、双向边图、DeepXiv 依赖、exp-* 全套 |

来源仓库链接：
- [Astro-Han/karpathy-llm-wiki](https://github.com/Astro-Han/karpathy-llm-wiki)
- [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills)
- [skyllwt/OmegaWiki](https://github.com/skyllwt/OmegaWiki)

## 2. 设计目标

1. 以论文为原子单元（paper-centric）构建长期知识库
2. 对论文页面执行严格引用审计（wiki-audit）
3. 在仅使用 stable 论文页的前提下生成综述草稿（LaTeX）
4. 使用最小必要结构，不引入重型图谱与复杂外部依赖

## 3. v0.1 范围外

- 向量数据库 / Embedding RAG
- Claim/Experiment 全图谱体系
- Daily arXiv 定时抓取
- 多语言框架 i18n 系统
- 重型外部服务默认依赖（如 GROBID/DeepXiv）
- 从零 Python CLI 脚手架与独立工程化实现

## 4. 核心设计原则

1. **轻量优先**：仅实现直接服务学术写作的最小闭环
2. **原子优先**：每篇论文对应一个 paper 页面，避免跨文献信息混杂
3. **审计前置**：paper 页不通过审计不得进入 stable
4. **可追溯优先**：每条关键结论应能回溯到来源论文与 bibkey
5. **兼容优先**：使用标准 markdown 相对链接，减少平台绑定
6. **目录隔离**：运行时写入仅允许发生在用户指定 `workspace_root`
7. **全自动优先**：skill 被调用后默认自动完成批量构建流程，不在中途反复询问已确定的参数
8. **一次性权限**：流程启动时一次性申请本轮所需权限
9. **非阻塞执行**：单篇失败不阻塞整批，最终统一输出失败清单
10. **自动化不越界**：全自动执行也必须遵守状态机门禁、目录隔离与引用可追溯约束

## 5. 链接与引用语义

采用语义分离：

1. **页面内部跳转**：标准 markdown 相对链接（如 `../papers/xxx.md`）
2. **文献引用**：`[@bibkey]`

设计决策：
- 不使用 Obsidian `[[wikilinks]]` 作为主链接机制（减少平台绑定）
- 不引入独立双向边图文件（v0.1 用 lint 扫描保障可达性）
- 通过 lint 检查保障一致性

## 6. 重试与回退参数

| 参数 | 值 | 说明 |
|------|-----|------|
| `max_retries` | 3 | 单个操作最大重试次数 |
| `backoff` | 2^n | 指数退避（秒） |
| `per_source_timeout` | 8s | 单个联网查证源超时 |

## 7. 测试与验收

### 7.1 单元测试

1. `provisional_key` 生成与幂等
2. `final_bibkey` 生成与冲突处理
3. refs.bib 追加/更新与去重
4. index/log 原子更新一致性
5. 状态机转换规则
6. lint pass/fail 判定

### 7.2 集成测试

1. `init → ingest_raw → ingest_finalize → audit(pass) → survey(tex)` 全链路
2. `ingest → update-page → draft 回退 → re-audit` 状态回退链
3. `query --save → topic/survey` 回写与索引更新
4. 弱网/离线：仅 raw 成功、finalize 入队、stable 被阻断

### 7.3 学术严谨性验收

1. stable paper 必须有审计通过记录
2. survey 不消费 draft paper
3. 关键结论段需具备 `\cite{}`
4. claim-to-citation 抽检可定位且语义一致
5. 综合性陈述需多源支撑或不确定性声明

## 8. 实现顺序建议

1. 初始化与基础文件（wiki-init）
2. ingest + refs.bib 自动维护（含查证钩子）
3. audit 双阶段与状态切换
4. lint pass/fail
5. query / update-page
6. survey 与 LaTeX 导出

## 9. 风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| PDF 文本质量波动 | 保留原 PDF 路径，审计回源核查 |
| 元数据源冲突 | 采用来源优先级并写入决策日志 |
| 综述过度概括 | 仅 stable 输入 + 引用密度约束 |
| 外部源抖动 | 双阶段 ingest + 重试队列 + 人工介入阈值 |

## 10. 交付物与验收口径

最终交付：
- 一个可直接使用的 `SKILL.md`
- 与 skill 匹配的最小目录与模板
- 可追踪引用输出（`citations.jsonl` 最小实现）

验收口径：
- 边界一致：吸收/不吸收与融合边界表一致
- 流程闭环：ingest、audit、update、survey 可串联
- 学术约束：stable 门禁、引用可追踪、审计可复核
- 交付正确：核心交付物是单 `SKILL.md`，不是 Python 项目

## 11. 开源协议与来源引用

- 本项目采用 [MIT License](../LICENSE)。
- 融合参考了上述 3 个仓库（按指定能力吸收，未整体并入）。
