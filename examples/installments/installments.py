#!/usr/bin/env python3
"""installments — 分期收款

一笔款项分多期收取，每期绑定一个时间点：
  状态在 应收 → 已收 / 逾期 之间流转，时间点临近时发出提醒。

用法:
  ./installments.py --demo
  ./installments.py scenario.json
"""

import sys, json, calendar
from datetime import date, timedelta


def _d(days: int) -> str:
    return (date.today() + timedelta(days=days)).isoformat()


DEMO = {
    "label": "三个月服务合同",
    "amount": 90,
    "months": 3,
    "start": _d(-47),
    "received": [1],
    "remind_days": 15,
}


def load(path=None):
    if not path or path == "--demo":
        return DEMO
    with open(path) as f:
        return json.load(f)


def month_offset(d: date, n: int) -> date:
    m = d.month - 1 + n
    y = d.year + m // 12
    m = m % 12 + 1
    last = calendar.monthrange(y, m)[1]
    return date(y, m, min(d.day, last))


def build_plan(scenario: dict, today: date) -> list:
    """按合同生成收款计划：期数、金额、到期日与状态"""
    per = scenario["amount"] / scenario["months"]
    start = date.fromisoformat(scenario["start"])
    received = set(scenario.get("received", []))
    remind = scenario.get("remind_days", 7)

    items = []
    for i in range(1, scenario["months"] + 1):
        due = month_offset(start, i - 1)
        item = {"n": i, "amount": per, "due": due, "received": i in received}
        if i in received:
            item["status"] = "已收"
        else:
            left = (due - today).days
            item["left"] = left
            if left < 0:
                item["status"] = f"逾期 {-left} 天"
            elif left <= remind:
                item["status"] = f"{left} 天后到期"
            else:
                item["status"] = "应收"
        items.append(item)
    return items


def main():
    scenario = load(sys.argv[1] if len(sys.argv) > 1 else None)
    today = date.today()
    remind = scenario.get("remind_days", 7)
    items = build_plan(scenario, today)

    print(f"╔{'═'*50}╗")
    print(f"║  量潮 · 分期收款 — {scenario['label']}")
    print(f"║  合同 {scenario['amount']:.0f}万 分 {scenario['months']} 期 · 提前 {remind} 天提醒")
    print(f"╚{'═'*50}╝")

    print("\n▶ 收款计划")
    print("  ┌──────┬────────┬────────────┬──────────────┐")
    print("  │ 期数  │ 金额   │ 到期日      │ 状态          │")
    print("  ├──────┼────────┼────────────┼──────────────┤")
    for it in items:
        print(f"  │ {it['n']:<4} │ {it['amount']:>5.0f} │ {it['due']}  │ {it['status']:<8} │")
    print("  └──────┴────────┴────────────┴──────────────┘")

    print("\n▶ 收款提醒")
    reminders = [it for it in items if "left" in it and 0 <= it["left"] <= remind]
    if not reminders:
        print("  (无)")
    for it in reminders:
        when = "今日到期" if it["left"] == 0 else f"{it['left']} 天后（{it['due']}）到期"
        print(f"  ⏰ 第{it['n']}期 {it['amount']:.0f}万 {when}，请跟进回款")

    print("\n▶ 逾期账款")
    overdue = [it for it in items if "left" in it and it["left"] < 0]
    if not overdue:
        print("  (无)")
    for it in overdue:
        print(f"  ⚠ 第{it['n']}期 {it['amount']:.0f}万 已逾期 {-it['left']} 天，尽快催收")

    received_sum = sum(it["amount"] for it in items if it["received"])
    overdue_sum = sum(it["amount"] for it in overdue)
    print("\n▶ 回款进度")
    print(f"  已收 {received_sum:.0f}万 / 合同 {scenario['amount']:.0f}万 · 进度 {received_sum / scenario['amount']:.0%}")
    if overdue_sum:
        print(f"  ⚠ 逾期 {len(overdue)} 期共 {overdue_sum:.0f}万")


if __name__ == "__main__":
    main()
