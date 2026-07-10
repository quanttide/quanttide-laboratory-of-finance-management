#!/usr/bin/env python3
"""qt-runway — 现金流推演实验

推演回款周期不确定 vs 固定支出矛盾下的现金跑道。

用法:
  ./runway.py                          # 交互模式
  ./runway.py --demo                   # 演示场景
"""

import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta


@dataclass
class Receivable:
    label: str
    amount: float
    days_to_arrival: int  # 预计多少天后到账


@dataclass
class Scenario:
    cash: float
    monthly_expense: float
    receivables: list = field(default_factory=list)


def project(scenario: Scenario, delay_days: int = 0):
    """按月推演现金流，delay_days 是全部回款的统一延迟天数"""
    cash = scenario.cash
    monthly = scenario.monthly_expense
    # 按预计到账时间排序
    recvs = sorted(scenario.receivables, key=lambda r: r.days_to_arrival + delay_days)

    print(f"\n{'='*50}")
    print(f"现金流推演")
    print(f"{'='*50}")
    print(f"当前现金: {cash:.0f} 万元")
    print(f"月固定支出: {monthly:.0f} 万元")
    print(f"回款延迟假设: {delay_days} 天")
    print()

    rcv_idx = 0
    month = 1
    while cash > 0:
        print(f"--- 第 {month} 月 ---")
        print(f"  月初现金: {cash:.0f} 万元")

        # 当月到账的回款
        incoming = 0
        while rcv_idx < len(recvs):
            r = recvs[rcv_idx]
            days = r.days_to_arrival + delay_days
            arrival_month = (days - 1) // 30 + 1
            if arrival_month <= month:
                incoming += r.amount
                print(f"  + 回款到账: {r.label} {r.amount:.0f} 万元 (预计{r.days_to_arrival}天, 实际延迟{delay_days}天)")
                rcv_idx += 1
            else:
                break

        cash += incoming
        print(f"  到账后现金: {cash:.0f} 万元")

        cash -= monthly
        print(f"  - 固定支出: {monthly:.0f} 万元")
        print(f"  月末现金: {cash:.0f} 万元\n")

        if cash <= 0:
            print(f"⚠️  第 {month} 月末现金断裂！")
            return month
        month += 1

    return month - 1


def demo():
    """演示场景：一家典型中小企业的现金流"""
    s = Scenario(
        cash=50,           # 当前现金 50万
        monthly_expense=30, # 月支出 30万（薪资为主）
        receivables=[
            Receivable("客户A", 40, 15),   # 15天后回款40万
            Receivable("客户B", 60, 45),   # 45天后回款60万
            Receivable("客户C", 30, 75),   # 75天后回款30万
        ],
    )

    print("=" * 50)
    print("演示场景：典型中小企业月收支")
    print(f"当前现金: {s.cash}万 | 月支出: {s.monthly_expense}万")
    print("预期回款:")
    for r in s.receivables:
        print(f"  {r.label}: {r.amount}万（{r.days_to_arrival}天后）")
    print("=" * 50)

    # 正常情况
    normal_runway = project(s, delay_days=0)
    print(f"\n正常情况: 可维持 {normal_runway} 个月")

    # 回款延迟30天
    delayed_runway = project(s, delay_days=30)
    print(f"\n回款延迟30天: 可维持 {delayed_runway} 个月")

    # 回款延迟60天
    delayed_runway2 = project(s, delay_days=60)
    print(f"\n回款延迟60天: 可维持 {delayed_runway2} 个月")

    # 结论
    print("\n" + "=" * 50)
    print("结论")
    print("=" * 50)
    if delayed_runway < 3:
        print("⚠️  回款延迟30天即面临断裂风险，需准备现金缓冲或短期融资渠道。")
    if normal_runway >= 3:
        print("✅ 正常情况下现金流健康，可维持3个月以上。")
    print()


def interactive():
    s = Scenario(cash=0, monthly_expense=0)
    s.cash = float(input("当前现金余额（万元）: "))
    s.monthly_expense = float(input("月固定支出（万元）: "))
    n = int(input("预期回款笔数: ") or "0")
    for i in range(n):
        label = input(f"  第{i+1}笔 回款来源: ") or f"回款{i+1}"
        amount = float(input(f"  第{i+1}笔 金额（万元）: "))
        days = int(input(f"  第{i+1}笔 预计到账天数: "))
        s.receivables.append(Receivable(label, amount, days))
    delay = int(input("回款延迟天数假设 (0=正常): ") or "0")
    m = project(s, delay)
    print(f"\n可维持 {m} 个月")


if __name__ == "__main__":
    if "--demo" in sys.argv:
        demo()
    elif len(sys.argv) > 1:
        interactive()
    else:
        interactive()
