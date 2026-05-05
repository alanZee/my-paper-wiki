# my-paper-wiki

个人学术论文知识库管理 skill —— 以论文为原子单元，严格审计门禁，自动生成综述。

## 功能

| 功能 | 说明 |
|------|------|
| **init** | 初始化 workspace 目录骨架 |
| **ingest** | 摄入 PDF/Tex，提取元数据与深度信息，生成论文页面 |
| **finalize** | 联网查证元数据，生成正式 bibkey 与 refs.bib |
| **audit** | 引用支撑审计（Phase A/B），门禁 draft → stable |
| **query** | 基于 stable 论文回答问题，可选保存为 topic/survey |
| **survey** | 基于 stable 论文生成综述草稿 + LaTeX 导出 |
| **lint** | 一致性检查（断链、孤立页、refs 匹配） |
| **update-page** | diff-before-write 修订页面，修改后自动回退重审 |

## 适用场景

- 个人论文阅读笔记管理
- 系统性文献综述写作
- 研究方向知识积累与查询
- 论文引用可追溯性维护

## 用法

### 自然语言（推荐）

skill 自动识别意图并执行对应流程：

```
"初始化论文 wiki"                          → init
"把这些 PDF 加入 wiki"                     → ingest
"基于 stable 论文生成机器学习综述"           → survey
"我对流动控制方向都知道什么？"               → query
"/lint"                                    → lint
```

### 用法示例

```
"初始化论文 wiki"                          → init
"把这些 PDF 加入 wiki"                     → ingest
"基于 stable 论文生成机器学习综述"           → survey
"我对流动控制方向都知道什么？"               → query
"检查 wiki 一致性"                         → lint
"完整跑一遍"                               → 全流水线
```

skill 自动识别意图并执行对应流程，所有 harness 通用。

### 参数

- `workspace_root`：运行时知识库目录（必须由用户指定，不得指向 skill 源码目录）
- `source_path` / `source_dir`：论文文件路径或文献目录

## 知识库目录结构（`workspace_root`）

```text
<workspace_root>/
├── refs.bib                          # BibTeX 文献库（ingest 自动生成）
├── raw/papers/                       # 原始论文文件 + 提取文本
├── wiki/
│   ├── index.md                      # 知识库总索引
│   ├── log.md                        # 操作日志（含 trace_id）
│   ├── papers/
│   │   ├── <bibkey>.md               # 论文页面（stable）
│   │   └── _pending/                 # 待查证论文（draft）
│   ├── topics/                       # 主题汇总页
│   └── surveys/                      # 综述草稿页
└── outputs/
    ├── citations.jsonl               # 引用追踪日志
    ├── audit/                        # 审计报告
    └── survey/                       # 导出的 LaTeX 文件
```

## 核心约束

- **状态机门禁**：paper 必须通过审计才能晋级 stable
- **综述仅消费 stable**：draft 论文不进入综述
- **引用可追溯**：所有结论附 `[@bibkey]` 引用
- **目录隔离**：skill 不修改自身源码目录

## 项目结构

```
my-paper-wiki/
├── SKILL.md                    ← 主规范（自动路由 7 个子流程）
├── README.md                   ← 本文件
├── references/
│   ├── paper-template.md       ← 论文页面模板
│   ├── topic-template.md       ← 主题页面模板
│   ├── survey-template.md      ← 综述页面模板
│   ├── audit-rules.md          ← 审计规则
│   ├── subagent-examples.md    ← 子代理创建示例
│   ├── error-format.md         ← 错误分级规范
│   ├── data-contracts.md       ← 数据契约与运行时约束
│   └── skills/                 ← 子流程详细规范（agent 按需加载）
│       ├── wiki-init.md
│       ├── wiki-ingest.md
│       ├── wiki-query.md
│       ├── wiki-audit.md
│       ├── wiki-lint.md
│       ├── wiki-survey.md
│       └── wiki-update-page.md
├── scripts/
│   └── pipeline-verify.py      ← E2E 验证脚本
└── docs/
    └── design-manual.md        ← 设计手册
```

**部署**：将整个目录复制到 `.claude/skills/my-paper-wiki/`（或 `~/.agents/skills/my-paper-wiki/`），即可通过 `/my-paper-wiki` 调用。

## 开源协议与来源引用

本项目采用 [MIT License](./LICENSE)。

融合参考了以下仓库（按指定能力吸收，未整体并入）：

| 来源 | 吸收的能力 |
|------|-----------|
| [Astro-Han/karpathy-llm-wiki](https://github.com/Astro-Han/karpathy-llm-wiki) | 单 SKILL.md 架构、raw/wiki 结构、index/log 机制 |
| [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills) | wiki-audit 双 phase 审计、diff-before-write |
| [skyllwt/OmegaWiki](https://github.com/skyllwt/OmegaWiki) | PDF 摄入回退链、citations.jsonl、survey 思路 |

详细融合边界与设计决策见 [设计手册](docs/design-manual.md)。
