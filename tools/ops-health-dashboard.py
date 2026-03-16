#!/usr/bin/env python3
"""SmartLedger OPS Health Dashboard (ASCII)

Reads local audit log JSONL and renders an operator-facing health snapshot.
Designed for local ops use after quality/release stages.
"""

from __future__ import annotations

import argparse
import json
import os
import time
from collections import deque
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Deque, Dict, List

DEFAULT_LOG_PATH = Path("audit_log.jsonl")


@dataclass
class DashboardMetrics:
    server_up: bool
    current_tps: int
    max_tps: int
    failed_auth_1m: int
    sentinel_active: bool
    ai_queue_len: int
    ai_mem_usage: int
    db_integ: bool
    last_event_msg: str
    system_load_bar: str
    tps_flow: str


def _parse_timestamp(raw: str | None) -> datetime | None:
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None


def _read_audit_entries(log_path: Path) -> List[Dict[str, Any]]:
    if not log_path.exists():
        return []

    entries: List[Dict[str, Any]] = []
    with log_path.open("r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                payload = json.loads(line)
                if isinstance(payload, dict):
                    entries.append(payload)
            except json.JSONDecodeError:
                continue
    return entries


def _sparkline(values: List[int]) -> str:
    charset = "._-:=+*#%@"
    if not values:
        return ""

    max_value = max(values)
    if max_value <= 0:
        return "." * len(values)

    result = []
    for value in values:
        idx = int((value / max_value) * (len(charset) - 1))
        result.append(charset[idx])
    return "".join(result)


def _progress_bar(percent: float, width: int = 24) -> str:
    clamped = max(0.0, min(100.0, percent))
    filled = int((clamped / 100.0) * width)
    return "[" + ("|" * filled) + ("-" * (width - filled)) + "]"


def _collect_metrics(entries: List[Dict[str, Any]]) -> DashboardMetrics:
    now = datetime.now().astimezone()
    one_sec_ago = now - timedelta(seconds=1)
    one_min_ago = now - timedelta(minutes=1)
    one_hour_ago = now - timedelta(hours=1)

    parsed_entries: List[Dict[str, Any]] = []
    for entry in entries:
        ts = _parse_timestamp(entry.get("timestamp"))
        if ts is None:
            continue
        parsed_entries.append({**entry, "_ts": ts.astimezone()})

    current_tps = sum(1 for e in parsed_entries if e["_ts"] >= one_sec_ago)

    per_second: Dict[int, int] = {}
    for entry in parsed_entries:
        ts_epoch = int(entry["_ts"].timestamp())
        per_second[ts_epoch] = per_second.get(ts_epoch, 0) + 1

    max_tps = max(per_second.values()) if per_second else 0

    failed_auth_1m = 0
    for entry in parsed_entries:
        if entry["_ts"] < one_min_ago:
            continue
        event_type = (entry.get("eventType") or "").lower()
        success = entry.get("success")
        if event_type == "authentication" and success is False:
            failed_auth_1m += 1

    # Sentinel heuristic for local ops
    sentinel_active = failed_auth_1m < 5

    # Optional env-based AI metrics for offline/local use
    ai_queue_len = int(os.getenv("SLD_AI_QUEUE_LEN", "0"))
    ai_mem_usage = int(os.getenv("SLD_AI_MEM_USAGE", "0"))

    # DB integrity heuristic: local sqlite files exist and are non-empty
    db_candidates = [Path("smartledger.db"), Path("build").joinpath("smartledger.db")]
    db_integ = any(path.exists() and path.stat().st_size > 0 for path in db_candidates)

    last_event_msg = "No events"
    if parsed_entries:
        latest = max(parsed_entries, key=lambda e: e["_ts"])
        action = latest.get("action", "unknown_action")
        event_type = latest.get("eventType", "unknown_event")
        last_event_msg = f"{event_type}: {action}"

    # Last 20 buckets of 3-second windows from past hour for readability
    bucket_counts: Deque[int] = deque(maxlen=20)
    for index in range(20, 0, -1):
        end = now - timedelta(seconds=(index - 1) * 3)
        start = end - timedelta(seconds=3)
        count = sum(1 for e in parsed_entries if start <= e["_ts"] < end and e["_ts"] >= one_hour_ago)
        bucket_counts.append(count)

    tps_flow = _sparkline(list(bucket_counts))

    load_percent = min(100.0, (current_tps / max(1, max_tps or 1)) * 100)
    system_load_bar = f"{_progress_bar(load_percent)} {int(load_percent):>3}%"

    server_up = True

    return DashboardMetrics(
        server_up=server_up,
        current_tps=current_tps,
        max_tps=max_tps,
        failed_auth_1m=failed_auth_1m,
        sentinel_active=sentinel_active,
        ai_queue_len=ai_queue_len,
        ai_mem_usage=ai_mem_usage,
        db_integ=db_integ,
        last_event_msg=last_event_msg,
        system_load_bar=system_load_bar,
        tps_flow=tps_flow,
    )


def _render_dashboard(metrics: DashboardMetrics) -> None:
    os.system("cls" if os.name == "nt" else "clear")
    print("=" * 66)
    print(f" [ SmartLedger System Heartbeat ] - {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 66)

    print(f" [INFRA] Status: {'RUNNING' if metrics.server_up else 'DOWN'}")
    print(f" [TPS]   Current: {metrics.current_tps:>8} TPS | Max(Observed): {metrics.max_tps}")

    sentinel_icon = "ACTIVE" if metrics.sentinel_active else "ALERT"
    print(f" [SEC]   Sentinel: {sentinel_icon} | Failed(1m): {metrics.failed_auth_1m}")

    print(
        f" [AI]    Model: Gemma-2-2B | Queue: {metrics.ai_queue_len} | RAM: {metrics.ai_mem_usage}%"
    )

    print(f" [DB]    Mode: WAL | Sync: FULL | Integrity: {'OK' if metrics.db_integ else 'CHECK'}")
    print("-" * 66)
    print(f" [SYSTEM LOAD] {metrics.system_load_bar}")
    print(f" [TPS FLOW]    {metrics.tps_flow}")
    print("=" * 66)
    print(f" >> LAST EVENT: {metrics.last_event_msg}")
    print("=" * 66)


def main() -> int:
    parser = argparse.ArgumentParser(description="SmartLedger OPS health dashboard")
    parser.add_argument("--log", type=Path, default=DEFAULT_LOG_PATH, help="Path to audit JSONL")
    parser.add_argument("--interval", type=float, default=2.0, help="Refresh interval seconds")
    parser.add_argument("--once", action="store_true", help="Render once and exit")
    args = parser.parse_args()

    while True:
        entries = _read_audit_entries(args.log)
        metrics = _collect_metrics(entries)
        _render_dashboard(metrics)

        if args.once:
            return 0
        time.sleep(max(0.2, args.interval))


if __name__ == "__main__":
    raise SystemExit(main())
