# Audit Rules (v0.1)

## Gate

- 仅 `pass` 才允许 paper 从 draft 晋级 stable。
- `fail` 保持 draft，需修复后重审。

## Phase A：识别未支撑声明

扫描论文页面正文，识别所有**事实性声明**（factual claims），判定是否被引用支撑。

### 事实性声明判定标准

以下类型属于事实性声明，必须有引用支撑：

1. **量化结果**：数值、百分比、比较结论（如 "方法 A 优于方法 B"）
2. **方法描述**：具体算法/架构/实验方案的名称与细节
3. **理论断言**：定理、推论、数学性质
4. **数据声明**：数据集规模、实验条件、超参数设置
5. **归因声明**：某方法由某作者提出、某结论由某论文证明

以下类型**不**属于事实性声明：

- 页面结构文本（标题、章节名）
- 通用背景知识（如 "Navier-Stokes 方程描述流体运动"）
- 明确标注 `[待验证]` 的不确定信息
- 论文页面自身的元数据（frontmatter 字段）

### 引用支撑判定

一条声明被视为"已支撑"需满足以下**任一**条件：

1. **直引匹配**：声明附近有 `[@bibkey]`，且该 bibkey 对应的原文包含语义一致的表述
2. **区块级引用**：该声明所在区块开头或摘要处有 `[@bibkey]`，且声明内容可从引用源推导
3. **自引用**：声明引用的是该论文自身的原始文本（通过 `source_text` / `source_file` 回源）

### Phase A 输出

逐条列出所有未支撑的事实性声明，格式：

```markdown
| # | 声明片段 | 所在区块 | 缺失引用 |
|---|---------|---------|---------|
| 1 | "..."   | Results | 无 [@bibkey] |
```

**门禁**：未支撑声明数 = 0 才可进入 Phase B。

## Phase B：支撑性核查

对 Phase A 中已标记为"有引用"的声明，逐条核查引用来源的支撑性。

### 支撑等级

| 等级 | 含义 | 判定标准 |
|------|------|---------|
| `supported` | 引用源直接包含该声明的核心内容 | 引用源原文有语义一致的表述 |
| `partially-supported` | 引用源包含相关内容但不完全匹配 | 引用源有相关内容，但声明做了外推或概括 |
| `unsupported` | 引用源不包含相关内容 | 引用源无法支撑该声明 |
| `source-missing` | 引用源不可达（文件缺失、URL 失效） | 无法验证 |

### 核查方法

1. **直引核查**：读取 `[@bibkey]` 对应的论文页面原文（`source_text` 或 Key Excerpts 区块），比对声明与原文的语义一致性
2. **综合性陈述核查**：若声明是多篇论文的综合概括（如 "多项研究表明..."），需逐一核查每个 `[@bibkey]` 的支撑性，且至少 2 个为 `supported`
3. **间接引用核查**：若引用的是 survey/review 类论文，需确认该 survey 中确实包含被引用的具体结论

### Phase B 输出

```markdown
| # | 声明片段 | [@bibkey] | 支撑等级 | 依据 |
|---|---------|-----------|---------|------|
| 1 | "..."   | smith2024 | supported | 原文 §3.2 "...一致表述..." |
| 2 | "..."   | jones2023 | unsupported | 原文未提及此结论 |
```

## 最终判定

- **pass**：Phase A 未支撑声明数 = 0，且 Phase B 所有声明等级为 `supported` 或 `partially-supported`
- **fail**：任一声明为 `unsupported` 或 `source-missing`，或 Phase A 存在未支撑声明

`partially-supported` 声明需在审计报告中标注警告，但不阻断晋级。

## 审计报告模板

报告存放在 `outputs/audit/<bibkey>-audit.md`，格式：

```markdown
# Audit Report: <bibkey>

- paper_page: wiki/papers/<bibkey>.md
- result: `pass` | `fail`
- timestamp: <ISO 8601>
- trace_id: <trace-id>

## Phase A: Uncited Claims

<!-- 未支撑声明表格，无则写 "None found." -->

## Phase B: Support Verification

<!-- 支撑性核查表格 -->

## Warnings

<!-- partially-supported 声明的警告，无则省略此节 -->

## Fix Items

<!-- fail 时的修复建议，pass 时省略此节 -->
```

## Survey Constraint

- survey 仅可消费 stable paper。
- draft paper 不得作为综述证据源。
