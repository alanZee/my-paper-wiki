---
name: wiki-update-page
description: 修订既有 wiki 页面，diff-before-write，修改 paper 内容后需重审。
---
# wiki-update-page

修订既有 wiki 页面，支持根据新证据修正结论。

## 输入

- 必填：`workspace_root`、`target_page`、`changes`

## 流程

1. 读取 target_page 当前全文
2. 计算并展示 diff（diff-before-write）
3. 用户确认后写入
4. 更新 index/log
5. 若修改 paper 实体内容 → 状态回退 draft，需重新 audit

## 失败路径

- 变更无来源依据 → 拒绝写入
- 目标页不存在 → 立即失败
- 目标页在 skill 源码目录 → 拒绝写入
