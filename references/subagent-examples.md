# 子代理创建示例（跨平台）

联网查证由**子代理**执行，使用高性价比模型（如 Haiku），主代理一次性授予搜索权限。

## Claude Code

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

## OpenCode / Codex CLI

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

## Gemini CLI

```
# 通过 Gemini 的 agents/skills 机制创建子代理，授予搜索工具与 URL 权限
```

## 通用原则

- 子代理使用最小模型（Haiku 级别），节省 token 开销
- 主代理在创建子代理时一次性授予 WebSearch + WebFetch 权限（含学术平台 URL 白名单）
- 子代理返回结构化 JSON 列表，主代理直接消费
- 子代理仅需搜索权限，无需文件读写权限

## 并行调度策略

- 论文数 < 12：单个子代理处理全部论文
- 论文数 ≥ 12：拆分为多个并行子代理，每个子代理至少处理 6 篇论文
- 拆分示例（15 篇论文 → 2 个子代理，8+7 篇）：
  ```
  Agent(description="查证论文元数据 batch-1 (6篇)", model="haiku", prompt="...论文 1-6...")
  Agent(description="查证论文元数据 batch-2 (6篇)", model="haiku", prompt="...论文 7-12...")
  ```
- harness 不支持并行时退化为串行，不影响正确性
