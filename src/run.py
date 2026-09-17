#!/usr/bin/env python3
"""run — 运行一份规格。

用法:
  python3 src/run.py src/specs/dunning.json
  python3 src/run.py src/specs/cashflow.json --today 2026-09-17
  python3 src/run.py src/specs/cashflow.json --today 2026-09-17 --what-if 延迟30
"""

import argparse
import json
from datetime import date

from spec_lang import engine, report


def main():
    ap = argparse.ArgumentParser(description="运行一份规格")
    ap.add_argument("spec", help="规格文件路径")
    ap.add_argument("--today", help="基准日期 YYYY-MM-DD，缺省为今天")
    ap.add_argument("--what-if", help="假设推演：回款整体延迟天数，如 延迟30")
    args = ap.parse_args()

    with open(args.spec, encoding="utf-8") as f:
        spec = json.load(f)

    today = date.fromisoformat(args.today) if args.today else date.today()
    delay = 0
    if args.what_if:
        digits = "".join(ch for ch in args.what_if if ch.isdigit())
        delay = int(digits or 0)

    obs, acts = engine.run(spec, today)
    report.show(spec, obs, acts, today)

    if delay:
        obs, acts = engine.run(spec, today, delay)
        report.show(spec, obs, acts, today, delay)


if __name__ == "__main__":
    main()
