#!/usr/bin/env python3
import os
import re
import json
import time
import argparse
import requests
from typing import List, Tuple, Dict, Any, Set

DEFAULT_API_BASE = os.environ.get("API_BASE_URL", "https://api.gtm.baby")
REFERRAL_JOIN_PATH = os.environ.get("REFERRAL_JOIN_PATH", "/api/referral-join")
REQUEST_TIMEOUT = float(os.environ.get("REF_RECON_TIMEOUT", "20"))
SLEEP_BETWEEN = float(os.environ.get("REF_RECON_SLEEP", "0.2"))

# Example line:
# "\uD83D\uDD14 /start | 09.08.2025 11:00:40 MSK | id=6931629845 | @emitattoo | Emily Tattoo | ref=5ISJ6W3S"
LINE_REGEX = re.compile(r"id=(?P<tid>\d+).*?ref=(?P<code>[A-Z0-9]{6,12})")

# Some logs may come in two lines or with different order; also try a fallback to capture code and then nearest id
CODE_REGEX = re.compile(r"ref=(?P<code>[A-Z0-9]{6,12})")
ID_REGEX = re.compile(r"id=(?P<tid>\d+)")


def parse_log_lines(lines: List[str]) -> Set[Tuple[int, str]]:
    pairs: Set[Tuple[int, str]] = set()

    # First pass: same-line matches
    for ln in lines:
        m = LINE_REGEX.search(ln)
        if m:
            try:
                tid = int(m.group("tid"))
                code = m.group("code").strip()
                pairs.add((tid, code))
            except Exception:
                pass

    # Second pass: greedy association for code then closest following id in window of lines
    window = 3
    for idx, ln in enumerate(lines):
        mc = CODE_REGEX.search(ln)
        if not mc:
            continue
        code = mc.group("code").strip()
        # If this line already parsed in first pass, skip
        if any((tid, code) in pairs for tid in range(0, 1)):
            pass
        # Look ahead a few lines for id=
        for j in range(idx, min(idx + 1 + window, len(lines))):
            mi = ID_REGEX.search(lines[j])
            if mi:
                try:
                    tid = int(mi.group("tid"))
                    pairs.add((tid, code))
                    break
                except Exception:
                    continue

    return pairs


def reconcile_pairs(pairs: Set[Tuple[int, str]], api_base: str = DEFAULT_API_BASE) -> Dict[str, Any]:
    url = api_base.rstrip("/") + REFERRAL_JOIN_PATH
    stats = {
        "total": 0,
        "success": 0,
        "awarded": 0,
        "already_counted": 0,
        "invalid_referral_code": 0,
        "errors": 0,
        "details": [],
    }
    for (referred_id, code) in pairs:
        stats["total"] += 1
        try:
            resp = requests.post(
                url,
                json={"referral_code": code, "referred_telegram_id": int(referred_id)},
                timeout=REQUEST_TIMEOUT,
            )
            ok = (resp.status_code == 200)
            body = {}
            try:
                body = resp.json() if resp.content else {}
            except Exception:
                body = {"raw": resp.text}
            stats["success"] += 1 if ok else 0

            # Normalize outcomes
            msg = body.get("message") or body.get("error") or ""
            ticket_awarded = bool(body.get("ticket_awarded", False))
            if msg == "already_counted":
                stats["already_counted"] += 1
            elif body.get("error") == "invalid_referral_code":
                stats["invalid_referral_code"] += 1
            elif ticket_awarded:
                stats["awarded"] += 1

            stats["details"].append({
                "referred_id": referred_id,
                "code": code,
                "status_code": resp.status_code,
                "body": body,
            })
        except Exception as e:
            stats["errors"] += 1
            stats["details"].append({
                "referred_id": referred_id,
                "code": code,
                "error": str(e),
            })
        time.sleep(SLEEP_BETWEEN)
    return stats


def main():
    p = argparse.ArgumentParser(description="Reconcile referral tickets from Telegram logs")
    p.add_argument("file", help="Path to text log file with /start lines (UTF-8)")
    p.add_argument("--api-base", dest="api_base", default=DEFAULT_API_BASE, help=f"API base URL (default {DEFAULT_API_BASE})")
    args = p.parse_args()

    with open(args.file, "r", encoding="utf-8") as f:
        lines = [ln.strip() for ln in f.readlines() if ln.strip()]

    pairs = parse_log_lines(lines)
    print(f"Found {len(pairs)} unique (referred_id, referral_code) pairs")

    stats = reconcile_pairs(pairs, api_base=args.api_base)
    # Compact summary
    summary = {
        k: stats[k] for k in [
            "total", "success", "awarded", "already_counted", "invalid_referral_code", "errors"
        ]
    }
    print(json.dumps({"summary": summary}, ensure_ascii=False, indent=2))

    # If needed, write full details
    out_path = os.path.splitext(args.file)[0] + ".reconcile.result.json"
    with open(out_path, "w", encoding="utf-8") as out:
        json.dump(stats, out, ensure_ascii=False, indent=2)
    print(f"Details saved to {out_path}")


if __name__ == "__main__":
    main()