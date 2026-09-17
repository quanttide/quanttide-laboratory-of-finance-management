"""输出：把解释器的结果按 ▶ 分节打印。"""

from datetime import timedelta

from .engine import critical_delay, simulate_cash


def show(spec, obs, acts, today, delay=0):
    name = spec.get("name", "规格")
    tag = f"（假设：整体延迟 {delay} 天）" if delay else ""
    print(f"╔{'═'*50}╗")
    print(f"║  量潮 · {name}  基准日 {today} {tag}")
    print(f"╚{'═'*50}╝")

    print("\n▶ 状态")
    for o in obs:
        line = f"  · {o.subject} {o.amount:.0f}万"
        if o.owner:
            line += f" {o.owner}"
        line += f" · 到期 {o.effective_due} · {o.state}"
        if o.level:
            line += f" · {o.level}"
        if o.reason:
            line += f" · {o.reason}"
        print(line)

    if acts.get("remind"):
        print("\n▶ 收款提醒")
        for o in acts["remind"]:
            when = "今日到期" if o.left == 0 else f"{o.left} 天后（{o.effective_due}）到期"
            print(f"  ⏰ {o.subject} {o.amount:.0f}万 {when}，请跟进回款")

    if acts.get("dunning"):
        print("\n▶ 催款通知（按业务员）")
        for owner, rs in acts["dunning"].items():
            total = sum(r.amount for r in rs)
            print(f"  ── 致 {owner}（{len(rs)}笔 {total:.0f}万）")
            for r in rs:
                print(f"  · {r.subject} {r.amount:.0f}万，超期{r.overdue}天（{r.reason or '原因待核实'}）→ 限期催收")

    if acts.get("claim"):
        print("\n▶ 信保理赔")
        for o in acts["claim"]:
            print(f"  ✓ {o.subject} {o.amount:.0f}万，超期{o.overdue}天，启动银行理赔")

    if acts.get("report"):
        _leader_report(obs, today)

    if "baseline" in spec:
        _cash_navigation(spec, obs, today, delay)


def _leader_report(obs, today):
    print("\n▶ 领导汇报（邮件草稿）")
    print(f"  主题：应收账款超期风险分析（{today}）")
    overdue = [o for o in obs if o.overdue]
    total = sum(o.amount for o in obs)
    s = sum(o.amount for o in overdue)
    print(f"  本期超期账款 {len(overdue)} 笔共 {s:.0f} 万，占台账 {s / total:.0%}。其中：")
    for level in ("坏账风险", "高风险", "关注"):
        rs = [o for o in overdue if o.level == level]
        if rs:
            names = "、".join(f"{o.subject}（{o.reason or '原因待核实'}）" for o in rs)
            print(f"  · {level} {sum(o.amount for o in rs):.0f}万：{names}")


def _cash_navigation(spec, obs, today, delay):
    months, broke = simulate_cash(spec, obs, today, delay)
    buffer = spec["baseline"].get("buffer", 0)
    print("\n▶ 现金推演" + ("（假设路线）" if delay else ""))
    if not months:
        print("  (无数据)")
        return
    for m in months:
        print(f"  {m['month']}  进账 +{m['incoming']:.0f}  期末 {m['end']:.0f}")
    gap = months[-1]["end"] - buffer
    if broke or gap <= 0:
        status = f"亏空 {-gap:.0f}万 ⚠️ 断裂"
    elif gap <= 10:
        status = f"高于储备线 {gap:.0f}万 ⚡ 预警"
    elif gap <= 30:
        status = f"高于储备线 {gap:.0f}万 △ 关注"
    else:
        status = f"高于储备线 {gap:.0f}万 ✓ 安全"
    print(f"  → 期末 {months[-1]['end']:.0f}万（{status}）")

    if not delay:
        days, normal = critical_delay(spec, obs, today)
        warn = today + timedelta(days=days)
        print("\n▶ 预警")
        print(f"  正常续航 {normal} 个月 · 回款延迟警戒线 {days} 天 · 最晚行动日 {warn}")
        risky = [o for o in obs if (o.delay_risk or 0) > 0.2]
        if risky:
            print("  前方风险点：")
            for o in risky:
                print(f"  ⚠ {o.subject} {o.amount:.0f}万（延迟概率 {o.delay_risk:.0%}，预计 {o.left} 天后到账）")
