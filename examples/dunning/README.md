# qt-dunning — 超期催款实验

**超期应收账款** 的风险分析与批量催款工具。

## 用法

```bash
./dunning.py --demo              # 演示场景
./dunning.py ledger.json         # 加载自定义台账
```

## JSON场景格式

```json
{
  "receivables": [
    {"customer": "客户A", "owner": "业务甲", "amount": 40,
     "invoiced_on": "2026-06-18", "credit_days": 60, "reason": "追讨不紧"}
  ]
}
```

| 字段 | 说明 |
|------|------|
| `receivables[].customer` | 客户 |
| `receivables[].owner` | 跟进业务员 |
| `receivables[].amount` | 账款金额（万元） |
| `receivables[].invoiced_on` | 开票/挂账日期 |
| `receivables[].credit_days` | 账期（天） |
| `receivables[].reason` | 超期原因：追讨不紧 / 客户偿付 / 信保覆盖（可选，缺省提示向业务核实） |

## 输出

- 超期账款风险分析：按超期时长分级（关注 / 高风险 / 坏账风险）
- **催款通知**——按业务员自动生成，可直接批量发送
- **领导汇报**——风险分析邮件草稿
- 信保覆盖账款转入理赔流程提示
