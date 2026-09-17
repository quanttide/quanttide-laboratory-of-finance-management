"""规格解释器：展开事实 → 推导状态 → 求值触发 → 现金推演。"""

from datetime import timedelta

from .schema import validate
from .timeline import month_offset, month_end, resolve_due

RISK = ((60, "坏账风险"), (15, "高风险"), (0, "关注"))


def risk_level(days):
    for threshold, name in RISK:
        if days > threshold:
            return name
    return "关注"


class Obligation:
    """一笔钱的义务：主体、金额与时间规则展开后的落点。"""

    def __init__(self, subject, amount, due, owner=None, received=False, delay_risk=None, reason=None):
        self.subject = subject
        self.amount = amount
        self.due = due
        self.owner = owner
        self.received = received
        self.delay_risk = delay_risk
        self.reason = reason

    def derive(self, today, delay=0):
        """状态推导：纯函数，同样的事实与日期永远得到同样的状态。"""
        due = self.due + timedelta(days=delay)
        self.effective_due = due
        self.left = (due - today).days
        self.overdue = max(0, -self.left)
        if self.received:
            self.state = "已收"
            self.level = None
        elif self.overdue:
            self.state = f"逾期 {self.overdue} 天"
            self.level = risk_level(self.overdue)
        else:
            self.state = "应收"
            self.level = None
        return self


def expand(spec, today, delay=0):
    """事实展开为义务列表：按月一期按期数展开，其余一条一笔。"""
    obs = []
    for f in spec.get("facts", []):
        t = f["time"]
        if "installments" in t:
            per = f["amount"] / t["installments"]
            got = set(f.get("received", []))
            for i in range(1, t["installments"] + 1):
                due = resolve_due(dict(t, nth=i), today)
                obs.append(Obligation(f"{f['subject']}第{i}期", per, due, f.get("owner"),
                                      i in got, f.get("delay_risk"), f.get("reason")))
        else:
            obs.append(Obligation(f["subject"], f["amount"], resolve_due(t, today), f.get("owner"),
                                  bool(f.get("received")), f.get("delay_risk"), f.get("reason")))
    return [o.derive(today, delay) for o in obs]


def fire(spec, obs):
    """求值触发条件，生成行动。归因分支优先，命中的义务不再进入常规催款。"""
    acts = {"remind": [], "dunning": {}, "claim": [], "report": []}
    claimed = set()
    for trig in spec.get("triggers", []):
        if trig["when"] == "overdue" and trig.get("reason"):
            for o in obs:
                if o.overdue and o.reason == trig["reason"]:
                    claimed.add(id(o))
                    acts.setdefault(trig["do"], []).append(o)

    for trig in spec.get("triggers", []):
        when, do = trig["when"], trig.get("do")
        for o in obs:
            if when == "due_within" and not o.received and 0 <= o.left <= trig.get("days", 0):
                if o not in acts["remind"]:
                    acts["remind"].append(o)
            elif when == "overdue" and o.overdue and not trig.get("reason") and id(o) not in claimed:
                if do == "dunning":
                    acts["dunning"].setdefault(o.owner, []).append(o)
                elif do and o not in acts.setdefault(do, []):
                    acts[do].append(o)

    return acts


def simulate_cash(spec, obs, today, delay=0):
    """按月推演现金：进账为当月内到期的义务，固定支出按月扣减。"""
    b = spec["baseline"]
    cash = b["cash"]
    buffer = b.get("buffer", 0)
    events = sorted((o.due + timedelta(days=delay), o.amount) for o in obs)
    months = []
    m = 0
    i = 0
    while cash > buffer and m < 240:
        m += 1
        start = month_offset(today, m - 1)
        end = month_end(start)
        incoming = 0
        while i < len(events) and events[i][0] <= end:
            incoming += events[i][1]
            i += 1
        cash += incoming - b["monthly_expense"]
        months.append({"month": f"{start.year}-{start.month:02d}", "incoming": incoming, "end": cash})
        if cash <= 0:
            return months, m
    return months, None


def critical_delay(spec, obs, today):
    """临界延迟天数：回款整体延迟超过此值，跑道缩短。"""
    normal, _ = simulate_cash(spec, obs, today)
    lo, hi = 0, 365
    while lo < hi:
        mid = (lo + hi + 1) // 2
        months, _ = simulate_cash(spec, obs, today, mid)
        if len(months) < len(normal):
            hi = mid - 1
        else:
            lo = mid
    return lo, len(normal)


def run(spec, today, delay=0):
    validate(spec)
    obs = expand(spec, today, delay)
    acts = fire(spec, obs)
    return obs, acts
