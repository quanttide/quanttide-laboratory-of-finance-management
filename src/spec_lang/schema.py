"""词汇校验：规格里出现未知字段，是造新词的信号，先回 spec.md 补词汇。"""

TOP = {"name", "facts", "baseline", "triggers"}
FACT = {"subject", "amount", "owner", "time", "received", "delay_risk", "reason"}
TIME = {"due", "due_in_days", "invoiced_on", "credit_days", "cycle", "start", "installments", "nth"}
TRIGGER = {"when", "days", "risk", "reason", "do"}


def validate(spec):
    _check(spec, TOP, "规格")
    for f in spec.get("facts", []):
        _check(f, FACT, "事实")
        _check(f.get("time", {}), TIME, "时间规则")
    for t in spec.get("triggers", []):
        _check(t, TRIGGER, "触发条件")


def _check(d, allowed, label):
    unknown = set(d) - allowed
    if unknown:
        raise ValueError(f"{label}存在未知字段 {sorted(unknown)}——这是造新词的信号，先回 spec.md 补词汇")
