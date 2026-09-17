# qt-installments — 分期收款实验

**一笔款项分多期收取** 的收款计划与提醒工具。

## 用法

```bash
./installments.py --demo              # 演示场景
./installments.py scenario.json       # 加载自定义场景
```

## JSON场景格式

```json
{
  "label": "三个月服务合同",
  "amount": 90,
  "months": 3,
  "start": "2026-08-01",
  "received": [1],
  "remind_days": 15
}
```

| 字段 | 说明 |
|------|------|
| `label` | 合同名称 |
| `amount` | 合同总额（万元） |
| `months` | 收款期数，按月均分 |
| `start` | 首期收款日 |
| `received` | 已收期数列表 |
| `remind_days` | 提前提醒天数 |

## 输出

- 收款计划表：每期金额、到期日与状态（应收 / 已收 / 逾期）
- **收款提醒**——时间点临近时逐期提示
- 逾期账款清单
- 回款进度汇总
