#!/usr/bin/env python3
"""dunning — 超期催款

超期应收账款的风险分析与批量催款：
  台账 → 风险分析 → 按业务员生成催款通知 → 领导汇报邮件。

用法:
  ./dunning.py --demo
  ./dunning.py ledger.json
"""

import sys, json
from datetime import date, timedelta


def _d(days: int) -> str:
    return (date.today() + timedelta(days=days)).isoformat()


DEMO = {
    "receivables": [
        {"customer": "客户A", "owner": "业务甲", "amount": 40, "invoiced_on": _d(-90), "credit_days": 60, "reason": "追讨不紧"},
        {"customer": "客户B", "owner": "业务乙", "amount": 25, "invoiced_on": _d(-180), "credit_days": 90, "reason": "信保覆盖"},
        {"customer": "客户C", "owner": "业务甲", "amount": 30, "invoiced_on": _d(-40), "credit_days": 30, "reason": "追讨不紧"},
        {"customer": "客户D", "owner": "业务丙", "amount": 35, "invoiced_on": _d(-20), "credit_days": 60},
        {"customer": "客户E", "owner": "业务丙", "amount": 30, "invoiced_on": _d(-165), "credit_days": 90},
    ],
}


def risk_level(days: int) -> str:
    if days > 60:
        return "坏账风险"
    if days > 15:
        return "高风险"
    return "关注"


def action(reason: str) -> str:
    if "信保" in reason:
        return "启动信保理赔"
    if "追讨" in reason:
        return "限期催收"
    if "偿付" in reason:
        return "评估坏账"
    return "请反馈超期原因"


def load(path=None):
    if not path or path == "--demo":
        return DEMO
    with open(path) as f:
        return json.load(f)


def analyze(scenario: dict, today: date):
    """按账期与超期时长分析风险，返回 (超期账款, 账期内账款)"""
    overdue, ontime = [], []
    for r in scenario["receivables"]:
        due = date.fromisoformat(r["invoiced_on"]) + timedelta(days=r["credit_days"])
        days = (today - due).days
        if days > 0:
            reason = r.get("reason", "")
            overdue.append({**r, "overdue": days, "level": risk_level(days),
                            "action": action(reason), "insured": "信保" in reason})
        else:
            ontime.append(r)
    return sorted(overdue, key=lambda r: -r["overdue"]), ontime


def main():
    scenario = load(sys.argv[1] if len(sys.argv) > 1 else None)
    today = date.today()
    overdue, ontime = analyze(scenario, today)

    total = sum(r["amount"] for r in scenario["receivables"])
    overdue_sum = sum(r["amount"] for r in overdue)

    print(f"╔{'═'*50}╗")
    print(f"║  量潮 · 超期催款")
    print(f"║  台账 {len(scenario['receivables'])}笔 {total:.0f}万 · 超期 {len(overdue)}笔 {overdue_sum:.0f}万")
    print(f"╚{'═'*50}╝")

    print("\n▶ 风险分析")
    for r in overdue:
        tag = "⚠" if r["level"] in ("高风险", "坏账风险") else "△"
        print(f"  {tag} {r['customer']} {r['amount']:.0f}万 {r['owner']} · 超期{r['overdue']}天 · {r['level']} · {r.get('reason') or '原因待核实'}")
    for r in ontime:
        print(f"  ─ {r['customer']} {r['amount']:.0f}万 {r['owner']} · 账期内")

    claims = [r for r in overdue if r["insured"]]
    dunning = [r for r in overdue if not r["insured"]]

    print("\n▶ 催款通知（按业务员自动生成）")
    owners = {}
    for r in dunning:
        owners.setdefault(r["owner"], []).append(r)
    if not owners:
        print("  (无)")
    for owner, rs in owners.items():
        s = sum(r["amount"] for r in rs)
        print(f"\n  ── 致 {owner}（{len(rs)}笔 {s:.0f}万）──────────")
        for r in rs:
            print(f"  · {r['customer']} {r['amount']:.0f}万，超期{r['overdue']}天（{r.get('reason') or '原因待核实'}）→ {r['action']}")
    if claims:
        print(f"\n  （{'、'.join(r['customer'] for r in claims)} 为信保覆盖，转入理赔流程，不发送催款）")

    print("\n▶ 领导汇报（邮件草稿）")
    print(f"  主题：应收账款超期风险分析（{today}）")
    print(f"  本期超期账款 {len(overdue)} 笔共 {overdue_sum:.0f} 万，占台账 {overdue_sum / total:.0%}。其中：")
    for level in ("坏账风险", "高风险", "关注"):
        rs = [r for r in overdue if r["level"] == level]
        if rs:
            names = "、".join(f"{r['customer']}（{r.get('reason') or '原因待核实'}）" for r in rs)
            print(f"  · {level} {sum(r['amount'] for r in rs):.0f}万：{names}")
    if claims:
        print(f"  · 信保覆盖 {'、'.join(r['customer'] for r in claims)}，建议启动银行理赔")


if __name__ == "__main__":
    main()
