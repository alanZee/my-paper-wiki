# my-paper-wiki 融合改造实施计划（修正版）

> 纠偏说明：本计划替换“从零 Python 项目开发”路线，改为“基于 3 个现有 skill 仓库融合改造，最终仅交付 1 个 skill”。

## 1. 最终目标

交付一个可运行的 `my-paper-wiki/SKILL.md`，并满足以下边界：

- 基底：Astro-Han 的单 skill 结构与目录骨架
- 吸收：
  - kfchou 的 `wiki-audit` 双 phase 核心
  - kfchou 的 `wiki-update` diff-before-write
  - OmegaWiki 的 PDF 摄入回退链（tex > pdf > vision）
  - OmegaWiki 的 `citations.jsonl` 思路
  - OmegaWiki 的 survey skill 思路
- 明确不吸收：
  - severity-tier 报告
  - 9 类页面 / claim-experiment 建模 / 双向边图 / DeepXiv / exp-* 全套

## 2. 范围与非范围

### 范围内

1. 单 `SKILL.md` 设计与落地
2. 最小目录骨架：`raw/`、`wiki/`、`index.md`、`log.md`
3. ingest / audit / update / survey 四条核心流程可执行
4. 引用记录与可追踪输出（最小 `citations.jsonl`）

### 范围外

1. 从零 Python 包、CLI 脚手架、单测工程化
2. 重型依赖与复杂知识图谱扩展
3. 超出单 skill 必需的多模块系统设计

## 3. 融合策略

### Phase A：基底定型（Astro-Han）

- 固定目录与文件约定
- 明确 `SKILL.md` 输入输出接口
- 锁定最小模板（paper/topic/survey）

验收：目录结构与 `SKILL.md` 可被目标代理平台识别。

### Phase B：能力注入（kfchou + OmegaWiki）

- 注入 `wiki-audit` 两阶段规则（仅保留核心）
- 注入 `wiki-update` 写前 diff
- 注入 ingest 回退链（tex > pdf > vision）
- 注入 `citations.jsonl` 最小记录模型
- 注入 survey 最小流程（只消费 stable）

验收：每条流程有明确触发条件、输入、输出、失败处理。

### Phase C：收敛与瘦身

- 删除不在范围内的重特性描述
- 去除 Python 脚手架导向语句
- 对齐术语与状态机（draft/stable）

验收：文档中无越界特性，无冲突规则。

## 4. 任务清单（执行顺序）

- [ ] Task 1：提取 Astro-Han 基底文件清单与最小不可变约束
- [ ] Task 2：提取 kfchou 的 audit 双 phase 最小规则（去除 severity-tier）
- [ ] Task 3：提取 kfchou 的 update diff-before-write 机制
- [ ] Task 4：提取 OmegaWiki 的 ingest 回退链最小流程
- [ ] Task 5：提取 OmegaWiki 的 `citations.jsonl` 最小字段集
- [ ] Task 6：提取 OmegaWiki 的 survey 最小流程（stable-only）
- [ ] Task 7：将 Task 1~6 融合为单 `SKILL.md` 主规范
- [ ] Task 8：补齐目录模板与示例文件（最小集）
- [ ] Task 9：按“不吸收清单”做反向扫描清理
- [ ] Task 10：端到端走查（ingest → audit → update → survey）

## 5. 验收标准

1. **唯一交付物导向**：核心是单个 `SKILL.md`，不是 Python 工程。
2. **边界一致**：吸收项/不吸收项与最初约定完全一致。
3. **流程闭环**：ingest、audit、update、survey 四流程可串联。
4. **引用可追踪**：有最小 `citations.jsonl` 记录方案。
5. **轻量可维护**：无重依赖、无过度建模。

## 6. 当前状态（本次纠偏）

已完成：

- 删除错误方向产物（`src/`、`tests/`、`pyproject.toml`、`.pytest_cache/`）
- README 已改为“三仓融合 + 单 skill 交付”目标
- 本计划已替换为融合改造路线

待执行：

- 按 Task 1~10 继续推进融合实现与最终 `SKILL.md` 定稿
