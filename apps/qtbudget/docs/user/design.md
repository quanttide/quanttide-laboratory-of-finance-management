# 设计思路

## 定位

现金日记账。不是传统会计预算，不是额度管理，就是一本账。

核心模型：

```
Journal        — 日记账（name, createdAt）
JournalEntry   — 凭证（entryDate, description, status, lines[]）
JournalEntryLine — 分录行（debit, credit, description）
```

余额 = sum(借方) - sum(贷方)，从 0 开始。

## 用户交互

- 创建一本日记账（如"研发部备用金"）
- 录入借方或贷方分录，系统不要求借贷平衡（不强加会计约束）
- 看余额（借方-贷方）

## 不做什么

- 不做科目表、不做账户、不做标签
- 不做审批流、不做预算编制
- 不强约束借贷平衡（底层模型支持多行分录，但 UI 简化到一次只录一行）
