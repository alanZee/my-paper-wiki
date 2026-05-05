---
name: wiki-ingest
description: 摄入论文源文件（PDF/Tex），提取元数据并生成论文页面。
---
# wiki-ingest

将论文源文件摄入 wiki，生成论文页面、提取元数据、维护 refs.bib。

## 输入

- 必填：`workspace_root`
- 二选一：`source_path`（单文件）或 `source_dir`（目录递归）

## 流程

详见 SKILL.md §4.2，分两段：

### A) ingest_raw
1. 复制/登记源文件到 `raw/papers/`
2. 计算内容哈希，生成 provisional_key
3. 文本提取回退链：tex > pdf > vision
4. 创建 pending 页（draft），更新 index/log

### B) ingest_finalize
1. 本地提取元数据（零 token）→ 必要时联网查证（子代理，搜到即停）
2. 生成 final_bibkey，写入 refs.bib
3. 执行 provisional_key → final_bibkey 迁移
4. 记录 finalize 事件

## 元数据查证

- 子代理示例详见 `references/subagent-examples.md`
- 预印本 refs.bib 格式详见 `references/data-contracts.md` §5

## 失败路径

- 源文件不存在/不可读 → 立即失败
- metadata 不完整 → 禁止 finalize
- 同一 pdf_hash 重复 ingest → 幂等处理
