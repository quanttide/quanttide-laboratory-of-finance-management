#!/usr/bin/env python3
"""qt-runway — 现金流推演 (通用版)

用法:
  ./runway.py --demo                  # 演示场景
  ./runway.py scenario.json           # 从JSON文件加载场景
"""

import sys, json, calendar
from datetime import date, timedelta

DEMO = {
    "cash": 50,
    "buffer": 10,
    "monthly_expense": 30,
    "receivables": [
        {"label": "客户A", "amount": 40, "due_days": 15, "delay_risk": 0.3},
        {"label": "客户B", "amount": 60, "due_days": 45, "delay_risk": 0.1},
        {"label": "客户C", "amount": 30, "due_days": 75, "delay_risk": 0.05},
    ],
}


def load_scenario(path=None):
    if not path or path == "--demo":
        return DEMO
    with open(path) as f:
        return json.load(f)


def month_offset(d: date, n: int) -> date:
    """返回 d 所在月份 +n 个月 (保持日不变, 超出取月末)"""
    m = d.month - 1 + n
    y = d.year + m // 12
    m = m % 12 + 1
    last = calendar.monthrange(y, m)[1]
    return date(y, m, min(d.day, last))


def month_end(d: date) -> date:
    """d所在月份的最后一天"""
    last = calendar.monthrange(d.year, d.month)[1]
    return date(d.year, d.month, last)


def project(scenario: dict, delay: int = 0, start: date = None, quiet: bool = False):
    """按月推演。返回 (可维持月数, 是否断裂)"""
    cash = scenario["cash"]
    buffer = scenario.get("buffer", 0)
    monthly = scenario["monthly_expense"]
    today = start or date.today()
    recvs = sorted(scenario["receivables"], key=lambda r: r["due_days"] + delay)

    if not quiet:
        print(f"当前现金: {cash}万元 | 最低储备: {buffer}万元 | 月支出: {monthly}万元")
        print(f"回款延迟假设: {delay}天\n")

    rcv_idx = 0
    month = 0

    while cash > buffer:
        month += 1
        m_start = month_offset(today, month - 1)
        m_end = month_end(m_start)

        if not quiet:
            print(f"--- {m_start.year}-{m_start.month:02d} ---")
            print(f"  月初现金: {cash:.0f}万元")

        incoming = 0
        while rcv_idx < len(recvs):
            r = recvs[rcv_idx]
            arr = today + timedelta(days=r["due_days"] + delay)
            if arr <= m_end:
                incoming += r["amount"]
                risk = r.get("delay_risk", 0)
                risk_str = f"(延迟概率{risk:.0%})" if risk > 0 and not quiet else ""
                if not quiet:
                    print(f"  + {r['label']} {r['amount']}万元 {risk_str}")
                rcv_idx += 1
            else:
                break

        cash += incoming
        cash -= monthly

        if cash <= 0:
            if not quiet:
                print(f"  月末现金: {cash:.0f}万元")
                print(f"\n⚠️  第{month}个月 ({m_start.year}-{m_start.month}) 现金断裂！")
            return month, True

        if not quiet:
            gap = cash - buffer
            print(f"  月末现金: {cash:.0f}万元 (距储备线: {gap:.0f}万元)")
            if gap <= monthly and gap > 0:
                print(f"  → 预警：现金逼近储备线，需关注回款进度")
            print()

    if not quiet:
        print(f"现金降至储备线({buffer}万元)以下，停止推演")
    return month, False


def find_critical_delay(scenario: dict, start: date = None):
    """找出让跑道开始缩短的最小延迟天数"""
    normal_months, _ = project(scenario, delay=0, start=start, quiet=True)
    lo, hi = 0, 365
    while lo < hi:
        mid = (lo + hi + 1) // 2
        m, _ = project(scenario, delay=mid, start=start, quiet=True)
        if m < normal_months:
            hi = mid - 1
        else:
            lo = mid
    return lo, normal_months


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "--demo"
    scenario = load_scenario(path)
    today = date.today()

    print("=" * 55)
    print("  量潮  |  现金流推演")
    print("=" * 55)

    # 正常情况
    print("\n▶ 正常情况")
    project(scenario, delay=0, start=today)

    # 压力测试
    print("\n▶ 压力测试")
    critical, normal = find_critical_delay(scenario, start=today)
    warn_date = today + timedelta(days=critical)
    print(f"\n正常可维持: {normal}个月")
    print(f"回款延迟 {critical}天 以上, 跑道开始缩短")
    print(f"最晚行动日期: {warn_date}")
    print(f"(若到 {warn_date} 仍未回款, 必须采取措施)")

    # 风险项
    print("\n▶ 高风险回款")
    high = [r for r in scenario["receivables"] if r.get("delay_risk", 0) > 0.2]
    if high:
        for r in high:
            print(f"  ⚠ {r['label']} {r['amount']}万元 延迟概率{r.get('delay_risk',0):.0%}")
    else:
        print("  (未标记延迟概率)")


if __name__ == "__main__":
    main()
