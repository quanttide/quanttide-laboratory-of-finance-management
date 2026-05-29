# 设计思路

## 定位

现金日记账。核心模型：

```
Journal      — 日记账（name, createdAt）
JournalEntry — 分录（entryDate, description, debit, credit）
```

余额 = sum(debit) - sum(credit)，从 0 开始。

## 用户交互

- 创建一本日记账
- 录入借方或贷方分录
- 看余额

## 不做什么

- 不做科目表、不做账户
- 不做审批流、不做预算编制
- 不强约束借贷平衡
