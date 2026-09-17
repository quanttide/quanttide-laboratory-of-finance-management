"""时间规则求值：把规格里的时间字段解析成到期日。"""

import calendar
from datetime import date, timedelta


def parse(text):
    return date.fromisoformat(text)


def month_offset(d, n):
    """从 d 起第 n 个月的同一天，超出月末时取月末。"""
    m = d.month - 1 + n
    y = d.year + m // 12
    m = m % 12 + 1
    last = calendar.monthrange(y, m)[1]
    return date(y, m, min(d.day, last))


def month_end(d):
    last = calendar.monthrange(d.year, d.month)[1]
    return date(d.year, d.month, last)


def resolve_due(time, today):
    """时间规则 → 到期日。支持到期日、预计到账天数、账期推算、按月第 n 期。"""
    if "due" in time:
        return parse(time["due"])
    if "due_in_days" in time:
        return today + timedelta(days=time["due_in_days"])
    if "invoiced_on" in time:
        return parse(time["invoiced_on"]) + timedelta(days=time["credit_days"])
    if time.get("cycle") == "monthly":
        return month_offset(parse(time["start"]), time.get("nth", 1) - 1)
    raise ValueError(f"无法解析的时间规则: {time}")
