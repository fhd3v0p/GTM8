#!/usr/bin/env python3
import argparse
import csv
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict

import requests


DEFAULT_API = os.environ.get("RATING_API_URL", "https://api.gtm.baby/api")
DEFAULT_REFERRALS_API = os.environ.get("REFERRALS_API_URL", "https://api.gtm.baby/referrals")
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")


@dataclass
class AwardResult:
    success: bool
    status: int
    ticket_awarded: bool
    message: str
    raw: Optional[Dict]


def call_referral_join(telegram_id: int, referral_code: str, use_direct_referrals: bool) -> AwardResult:
    # Prefer direct referrals service if requested, else go through rating_api proxy
    base = DEFAULT_REFERRALS_API if use_direct_referrals else DEFAULT_API
    url = f"{base}/referral-join"
    payload = {"referred_telegram_id": telegram_id, "referral_code": referral_code}
    try:
        resp = requests.post(url, json=payload, timeout=30)
        status = resp.status_code
        ok = 200 <= status < 300
        data = None
        awarded = False
        msg = ""
        try:
            data = resp.json()
        except Exception:
            data = None
        if isinstance(data, dict):
            awarded = bool(data.get("ticket_awarded") or data.get("awarded") or data.get("granted"))
            msg = data.get("message") or data.get("detail") or ""
        return AwardResult(success=ok, status=status, ticket_awarded=awarded, message=msg, raw=data)
    except requests.RequestException as e:
        return AwardResult(success=False, status=0, ticket_awarded=False, message=str(e), raw=None)


def notify_user_dm(telegram_id: int, message: str) -> bool:
    token = TELEGRAM_BOT_TOKEN.strip()
    if not token:
        return False
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    try:
        r = requests.post(url, json={"chat_id": telegram_id, "text": message, "parse_mode": "HTML"}, timeout=10)
        return 200 <= r.status_code < 300
    except requests.RequestException:
        return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Award referral tickets idempotently based on CSV of pairs.")
    parser.add_argument("--csv", required=True, help="Path to CSV: referred_telegram_id,referral_code")
    parser.add_argument("--direct", action="store_true", help="Call referrals service directly instead of rating_api proxy")
    parser.add_argument("--dry", action="store_true", help="Dry run (do not call API)")
    parser.add_argument("--report", default="logs/referral_awarder_report.jsonl", help="Path to write JSONL report")
    parser.add_argument("--notify", action="store_true", help="Send Telegram DM to user if a ticket was actually granted")
    parser.add_argument(
        "--notify-template",
        default=(
            "🎟️ Вам доначислен билет за реферала!\n"
            "Спасибо за активность — вы ближе к призам. Продолжайте в том же духе!"
        ),
        help="Notification text to send on award (HTML allowed)",
    )
    args = parser.parse_args()

    csv_path = Path(args.csv)
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    total = 0
    granted = 0
    errors = 0

    with csv_path.open("r", encoding="utf-8") as f, report_path.open("w", encoding="utf-8") as out:
        reader = csv.DictReader(f)
        if not {"referred_telegram_id", "referral_code"}.issubset(reader.fieldnames or set()):
            raise SystemExit("CSV must contain headers: referred_telegram_id, referral_code")
        for row in reader:
            total += 1
            try:
                telegram_id = int(str(row["referred_telegram_id"]).strip())
            except Exception:
                errors += 1
                out.write(json.dumps({"row": row, "error": "invalid telegram id"}, ensure_ascii=False) + "\n")
                continue
            referral_code = str(row["referral_code"]).strip().upper()
            if args.dry:
                out.write(json.dumps({"telegram_id": telegram_id, "referral_code": referral_code, "dry": True}, ensure_ascii=False) + "\n")
                continue
            result = call_referral_join(telegram_id, referral_code, args.direct)
            if result.ticket_awarded:
                granted += 1
                if args.notify:
                    notify_user_dm(telegram_id, args.notify_template)
            if not result.success:
                errors += 1
            out.write(json.dumps({
                "telegram_id": telegram_id,
                "referral_code": referral_code,
                "status": result.status,
                "success": result.success,
                "ticket_awarded": result.ticket_awarded,
                "message": result.message,
                "raw": result.raw,
            }, ensure_ascii=False) + "\n")

    print(f"Processed: {total}, granted: {granted}, errors: {errors}. Report: {report_path}")


if __name__ == "__main__":
    main()

