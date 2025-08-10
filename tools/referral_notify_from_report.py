#!/usr/bin/env python3
import argparse
import json
import os
from typing import Dict, Set, Tuple

import requests


DEFAULT_REPORT = "logs/referral_awarder_report.jsonl"
DEFAULT_TEMPLATE = (
    "🎟️ Вам доначислен билет за реферала!\n"
    "Спасибо за активность — вы ближе к призам. Продолжайте в том же духе!"
)


def send_dm(bot_token: str, chat_id: int, text: str) -> bool:
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    try:
        r = requests.post(url, json={"chat_id": chat_id, "text": text, "parse_mode": "HTML"}, timeout=10)
        return 200 <= r.status_code < 300
    except requests.RequestException:
        return False


def lookup_referrer_by_code(supabase_url: str, api_key: str, referral_code: str) -> int | None:
    try:
        headers = {"apikey": api_key, "Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        resp = requests.get(
            f"{supabase_url}/rest/v1/referrals",
            headers=headers,
            params={"referral_code": f"eq.{referral_code}", "select": "telegram_id"},
            timeout=15,
        )
        if resp.status_code in (200, 206):
            data = resp.json() if resp.content else []
            if isinstance(data, list) and data:
                raw = data[0].get("telegram_id")
                try:
                    return int(raw)
                except Exception:
                    return None
    except Exception:
        pass
    return None


def main() -> None:
    p = argparse.ArgumentParser(description="Send Telegram notifications based on referral_awarder report (JSONL)")
    p.add_argument("--report", default=DEFAULT_REPORT, help="Path to logs/referral_awarder_report.jsonl")
    p.add_argument("--template", default=DEFAULT_TEMPLATE, help="Notification text (HTML allowed)")
    p.add_argument("--mode", choices=["referred", "referrer"], default="referred", help="Who to notify")
    p.add_argument("--dry", action="store_true", help="Dry run (do not send messages)")
    args = p.parse_args()

    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
    if not bot_token and not args.dry:
        raise SystemExit("TELEGRAM_BOT_TOKEN env is required to send notifications")

    supabase_url = os.environ.get("SUPABASE_URL", "").strip()
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
    if args.mode == "referrer" and not (supabase_url and service_key):
        raise SystemExit("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY envs are required for --mode referrer")

    notified: Set[int] = set()
    total, eligible, sent, failed = 0, 0, 0, 0

    with open(args.report, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            total += 1
            try:
                obj: Dict = json.loads(line)
            except Exception:
                continue
            # Only entries that actually granted a ticket earlier
            if not obj.get("ticket_awarded", False):
                continue
            eligible += 1

            # Determine target chat id
            chat_id: int | None = None
            if args.mode == "referred":
                raw = obj.get("telegram_id")
                try:
                    chat_id = int(raw)
                except Exception:
                    chat_id = None
            else:
                code = (obj.get("referral_code") or "").strip().upper()
                if code:
                    chat_id = lookup_referrer_by_code(supabase_url, service_key, code)

            if not chat_id or chat_id in notified:
                continue

            if args.dry:
                notified.add(chat_id)
                continue

            ok = send_dm(bot_token, chat_id, args.template)
            if ok:
                sent += 1
                notified.add(chat_id)
            else:
                failed += 1

    print(json.dumps({
        "processed": total,
        "eligible": eligible,
        "unique_targets": len(notified),
        "sent": sent,
        "failed": failed,
        "mode": args.mode,
        "report": args.report,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()

