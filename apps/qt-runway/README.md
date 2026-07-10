# qt-runway — 现金流推演实验

**回款周期不确定 vs 固定支出** 的推演工具。

## 用法

```bash
./runway.py --demo              # 演示场景
./runway.py scenario.json       # 加载自定义场景
```

## JSON场景格式

```json
{
  "cash": 50,
  "buffer": 10,
  "monthly_expense": 30,
  "receivables": [
    {"label": "客户A", "amount": 40, "due_days": 15, "delay_risk": 0.3}
  ]
}
```

| 字段 | 说明 |
|------|------|
| `cash` | 当前现金（万元） |
| `buffer` | 最低现金储备线 |
| `monthly_expense` | 月固定支出 |
| `receivables[].label` | 回款来源 |
| `receivables[].amount` | 回款金额 |
| `receivables[].due_days` | 预计到账天数 |
| `receivables[].delay_risk` | 延迟概率（0~1，可选） |

## 输出

- 月度现金流推演表
- 正常可维持月数
- **临界延迟天数**——回款延迟超过此值，跑道开始缩短
- **最晚行动日期**——到此日期若仍未回款，必须采取措施
- 高风险回款清单
