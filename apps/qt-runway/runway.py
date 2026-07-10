#!/usr/bin/env python3
"""qt-runway — 现金流导航

不是预算。是导航：
  当前位置 + 前方路况 + 预警提示 = 随时知道怎么走。

用法:
  ./runway.py --demo
  ./runway.py scenario.json
  ./runway.py scenario.json --what-if "+延迟30天"   # 对比场景
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


def month_end(d: date) -> date:
    last = calendar.monthrange(d.year, d.month)[1]
    return date(d.year, d.month, last)


def simulate(scenario: dict, delay: int = 0, start: date = None, quiet: bool = False):
    """按月推演，返回 (月列表, 断裂月份)"""
    cash = scenario["cash"]
    buffer = scenario.get("buffer", 0)
    monthly = scenario["monthly_expense"]
    today = start or date.today()
    recvs = sorted(scenario["receivables"], key=lambda r: r["due_days"] + delay)

    months = []
    rcv_idx = 0
    m = 0

    while cash > buffer:
        m += 1
        ms = month_offset(today, m - 1)
        me = month_end(ms)

        incoming = 0
        details = []
        while rcv_idx < len(recvs):
            r = recvs[rcv_idx]
            arr = today + timedelta(days=r["due_days"] + delay)
            if arr <= me:
                incoming += r["amount"]
                details.append(r)
                rcv_idx += 1
            else:
                break

        cash += incoming
        cash -= monthly

        months.append({
            "month": f"{ms.year}-{ms.month:02d}",
            "start_cash": round(cash + monthly - incoming, 1),
            "incoming": incoming,
            "expense": monthly,
            "end_cash": round(cash, 1),
            "gap": round(cash - buffer, 1),
        })

        if cash <= 0:
            return months, m

    return months, None


def format_route(months, label="当前位置"):
    """输出一段导航路线"""
    if not months:
        print("  (无数据)")
        return

    end = months[-1]["end_cash"]
    broke = end <= 0

    print(f"  ┌─────┬──────────┬────────┬────────┬────────┐")
    print(f"  │ 月份 │ 期初现金 │ 进账   │ 支出   │ 期末   │")
    print(f"  ├─────┼──────────┼────────┼────────┼────────┤")
    for m in months:
        inc = f"+{m['incoming']:.0f}" if m['incoming'] else "   -"
        print(f"  │ {m['month']} │ {m['start_cash']:>6.0f}  │ {inc:>5} │ {m['expense']:.0f}    │ {m['end_cash']:>5.0f}  │")
    print(f"  └─────┴──────────┴────────┴────────┴────────┘")

    alert = months[-1]["gap"]
    if broke:
        tag = "⚠️ 断裂"
        status = f"亏空 {-alert:.0f}万元"
    elif alert <= 0:
        tag = "⚠️ 断裂"
        status = f"亏空 {-alert:.0f}万元"
    elif alert <= 10:
        tag = "⚡ 预警"
        status = f"高于储备线 {alert:.0f}万元"
    elif alert <= 30:
        tag = "△ 关注"
        status = f"高于储备线 {alert:.0f}万元"
    else:
        tag = "✓ 安全"
        status = f"高于储备线 {alert:.0f}万元"

    print(f"  → {label}: 期末 {end:.0f}万元 ({status}) {tag}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--what-if")]
    whatif = [a.split("+", 1)[1] for a in sys.argv[1:] if a.startswith("--what-if")]

    scenario = load(args[0] if args else None)
    today = date.today()

    print(f"╔{'═'*50}╗")
    print(f"║  量潮 · 现金流导航")
    print(f"║  当前位置: 现金{scenario['cash']}万  储备线{scenario.get('buffer',0)}万  月支出{scenario['monthly_expense']}万")
    print(f"╚{'═'*50}╝")

    # 路线预览
    months, broke_at = simulate(scenario)
    print(f"\n▶ 前方路况 (按当前路线)")
    format_route(months)

    # 预警
    print(f"\n▶ 实时预警")
    critical, normal = find_critical_delay(scenario)
    warn = today + timedelta(days=critical)
    print(f"  正常续航: {normal}个月")
    print(f"  回款延迟警戒线: {critical}天")
    print(f"  最晚行动日: {warn}")
    print(f"  → 若到 {warn} 还没回款, 必须调整路线")

    # 高风险回款
    high = [r for r in scenario["receivables"] if r.get("delay_risk", 0) > 0.2]
    if high:
        print(f"\n▶ 前方风险点")
        for r in high:
            print(f"  ⚠ {r['label']} {r['amount']}万 (延迟概率{r.get('delay_risk',0):.0%}, 预计{r['due_days']}天后到)")

    # 如果…会怎样
    if whatif:
        print(f"\n▶ 如果: {whatif[0]}")
        try:
            extra_delay = int(whatif[0].replace("延迟", "").replace("天", ""))
            months2, _ = simulate(scenario, delay=extra_delay)
            format_route(months2, label="如果路线")
        except:
            print("  (暂只支持'+延迟N天'格式)")


def find_critical_delay(scenario: dict, start: date = None):
    normal, _ = simulate(scenario, start=start, quiet=True)
    nm = len(normal)
    lo, hi = 0, 365
    while lo < hi:
        mid = (lo + hi + 1) // 2
        m, _ = simulate(scenario, delay=mid, start=start, quiet=True)
        if len(m) < nm:
            hi = mid - 1
        else:
            lo = mid
    return lo, nm


if __name__ == "__main__":
    main()
