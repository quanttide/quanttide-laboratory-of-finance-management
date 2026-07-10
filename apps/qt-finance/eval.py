#!/usr/bin/env python3
"""qt-finance eval — 财务决策推演"""

import sys, re
from dataclasses import dataclass

RULES = """
## 审批权限
≤ 千元 → 秘书/一线
千元~万元 → 合伙人
> 万元 → 创始人

## 原则
小金额决策，灵活性 > 小额优惠（未来不确定，调整成本 > 优惠金额）
"""


@dataclass
class Option:
    label: str
    term_months: int
    total_cost: float


def parse_question(q: str):
    """提取价格、优惠金额、折扣率"""
    discounts = [float(x) for x in re.findall(r"(?:省|优惠|减)(\d+(?:\.\d+)?)\s*(?:元|块)", q)]
    discount_pcts = [float(x) for x in re.findall(r"(\d+(?:\.\d+)?)\s*折", q)]
    # 去掉折扣数字再找价格，避免"省200块"的200被当成价格
    clean = re.sub(r"(?:省|优惠|减)\d+(?:\.\d+)?\s*(?:元|块)", "", q)
    prices = [float(x) for x in re.findall(r"(\d+(?:\.\d+)?)\s*(?:百)\s*(?:元|块)", clean)]
    prices = [x * 100 for x in prices]
    if not prices:
        prices = [float(x) for x in re.findall(r"(?:每年|年费|价格|单价|付)(\d+(?:\.\d+)?)\s*(?:元|块)", clean)]
    if not prices:
        prices = [float(x) for x in re.findall(r"(\d+(?:\.\d+)?)\s*(?:元|块)", clean)]
    return prices or None, discounts or None, discount_pcts or None


def interactive():
    print("未从问题中识别出金额信息，进入交互模式\n")
    price = float(input("每年费用（元）: "))
    discount = float(input("三年优惠金额（元）: ") or "0")
    opt1 = Option("一年", 12, price)
    opt2 = Option("三年", 36, price * 3 - discount)
    return opt1, opt2


def evaluate(opt1: Option, opt2: Option):
    yearly1 = opt1.total_cost / (opt1.term_months / 12)
    yearly2 = opt2.total_cost / (opt2.term_months / 12)
    saving = yearly1 * (opt2.term_months / 12) - opt2.total_cost

    print("\n========== 决策推演 ==========")
    print(f"方案A ({opt1.label}): {opt1.total_cost:.0f}元 ({opt1.term_months}个月)")
    print(f"方案B ({opt2.label}): {opt2.total_cost:.0f}元 ({opt2.term_months}个月)")
    print(f"年均费用: A {yearly1:.0f}元/年 | B {yearly2:.0f}元/年")
    print(f"B比A省: {saving:.0f}元 ({(saving / (yearly1 * (opt2.term_months / 12)) * 100):.0f}%)\n")

    if opt1.total_cost <= 1000:
        print(f"金额 {opt1.total_cost:.0f}元 ≤ 千元 → 秘书自决范围")
    elif opt1.total_cost <= 10000:
        print(f"金额 {opt1.total_cost:.0f}元 千元~万元 → 合伙人决定")
    else:
        print(f"金额 {opt1.total_cost:.0f}元 > 万元 → 创始人决定")

    print(f"\n原则: 小金额决策，灵活性 > 小额优惠")
    print(f"推演:")
    print(f"  B多付 {opt2.total_cost - opt1.total_cost:.0f}元 但覆盖 {opt2.term_months}个月")
    print(f"  若 {opt1.term_months}个月内需要调整，B已付的剩余期费用全部沉没")
    print(f"  节省 {saving:.0f}元 是否值得承担这个风险？")

    if saving / (yearly1 * 3) < 0.15:
        print(f"\n结论: 选A({opt1.label}) → 优惠幅度不大，保留灵活性更划算")
    else:
        print(f"\n结论: 选B({opt2.label}) → 优惠幅度大，锁定风险可控")


def main():
    q = " ".join(sys.argv[1:]) or input("决策问题: ").strip()
    if not q:
        print("用法: ./eval.py <决策问题>")
        print("示例: ./eval.py \"买一年还是买三年？三年省200块\"")
        sys.exit(1)

    prices, discounts, discount_pcts = parse_question(q)
    if prices or discounts or discount_pcts:
        price = prices[0] if prices else 1000
        discount = discounts[0] if discounts else 0
        if discount_pcts:
            opt1 = Option("一年", 12, price)
            opt2 = Option("三年", 36, price * 3 * discount_pcts[0] / 10)
        else:
            opt1 = Option("一年", 12, price)
            opt2 = Option("三年", 36, price * 3 - discount)
    elif "年" in q and ("优惠" in q or "折扣" in q):
        print("未识别出具体金额，使用默认场景（年费1000元，三年省200）进行演示\n")
        opt1 = Option("一年", 12, 1000)
        opt2 = Option("三年", 36, 2800)
    else:
        opt1, opt2 = interactive()

    evaluate(opt1, opt2)


if __name__ == "__main__":
    main()
