#!/usr/bin/env python3
"""
Broadcast helper: send a custom message/photo to all users from Supabase `users` table.

Usage examples:

  # Text only
  python3 tools/broadcast.py --text "Привет! Это тест рассылки" --dry

  # Photo with caption (URL)
  python3 tools/broadcast.py --photo-url https://example.com/promo.jpg --text "Новая акция" \
      --parse-mode HTML

  # Photo from local file
  python3 tools/broadcast.py --photo-file ./banner.jpg --text "<b>Жми</b>" --parse-mode HTML

  # Limit or resume
  python3 tools/broadcast.py --text "Только 100 юзеров" --limit 100
  python3 tools/broadcast.py --text "Продолжение" --start-from 100

Requires envs (picked from repo .env automatically):
  TELEGRAM_BOT_TOKEN, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
"""

from __future__ import annotations

import argparse
import json
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional, Tuple

import requests

# Auto-load .env from repo root
try:
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=(Path(__file__).resolve().parent.parent / ".env"))
except Exception:
    pass


TELEGRAM_BOT_TOKEN = (os.getenv("TELEGRAM_BOT_TOKEN") or "").strip()
SUPABASE_URL = (os.getenv("SUPABASE_URL") or "").strip()
SUPABASE_SERVICE_ROLE_KEY = (os.getenv("SUPABASE_SERVICE_ROLE_KEY") or "").strip()


def fetch_all_user_ids(batch_size: int = 2000, start_from: int = 0, limit: Optional[int] = None) -> List[int]:
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    }
    out: List[int] = []
    offset = start_from
    remaining = limit if limit is not None else 10**12
    while remaining > 0:
        page = min(batch_size, remaining)
        params = {
            "select": "telegram_id",
            "order": "telegram_id.asc",
            "limit": str(page),
            "offset": str(offset),
        }
        r = requests.get(f"{SUPABASE_URL}/rest/v1/users", headers=headers, params=params, timeout=20)
        if r.status_code not in (200, 206):
            raise SystemExit(f"Supabase users error {r.status_code}: {r.text}")
        rows = r.json() or []
        if not rows:
            break
        ids = []
        for row in rows:
            try:
                tid = int(row.get("telegram_id"))
                ids.append(tid)
            except Exception:
                continue
        out.extend(ids)
        got = len(rows)
        offset += got
        remaining -= got
        if got < page:
            break
    return out


def tg_send_message(chat_id: int, text: str, parse_mode: Optional[str], disable_preview: bool) -> Tuple[bool, str]:
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "disable_web_page_preview": disable_preview,
    }
    if parse_mode:
        payload["parse_mode"] = parse_mode
    r = requests.post(url, json=payload, timeout=20)
    if r.status_code == 429:
        try:
            retry = int((r.json() or {}).get("parameters", {}).get("retry_after", 1))
        except Exception:
            retry = 1
        return False, f"rate_limited:{retry}"
    if 200 <= r.status_code < 300:
        return True, "ok"
    try:
        body = r.json()
    except Exception:
        body = {"text": r.text}
    return False, f"{r.status_code}:{body}"


def tg_send_photo(chat_id: int, photo_url: Optional[str], photo_file: Optional[Path], caption: Optional[str], parse_mode: Optional[str]) -> Tuple[bool, str]:
    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendPhoto"
    if photo_file:
        with open(photo_file, "rb") as f:
            data = {"photo": f}
            payload = {"chat_id": chat_id}
            if caption:
                payload["caption"] = caption
            if parse_mode:
                payload["parse_mode"] = parse_mode
            r = requests.post(url, data=payload, files=data, timeout=30)
    else:
        payload = {"chat_id": chat_id, "photo": photo_url}
        if caption:
            payload["caption"] = caption
        if parse_mode:
            payload["parse_mode"] = parse_mode
        r = requests.post(url, json=payload, timeout=20)
    if r.status_code == 429:
        try:
            retry = int((r.json() or {}).get("parameters", {}).get("retry_after", 1))
        except Exception:
            retry = 1
        return False, f"rate_limited:{retry}"
    if 200 <= r.status_code < 300:
        return True, "ok"
    try:
        body = r.json()
    except Exception:
        body = {"text": r.text}
    return False, f"{r.status_code}:{body}"


def main() -> None:
    ap = argparse.ArgumentParser(description="Broadcast to all users from Supabase users table")
    ap.add_argument("--text", default="", help="Text message (or photo caption if photo provided)")
    ap.add_argument("--parse-mode", choices=["HTML", "Markdown", "MarkdownV2"], default=None)
    ap.add_argument("--disable-preview", action="store_true", help="Disable link preview for text messages")
    ap.add_argument("--photo-url", default=None, help="Photo URL to send")
    ap.add_argument("--photo-file", default=None, help="Local photo file path to send")
    ap.add_argument("--start-from", type=int, default=0, help="Offset in users list")
    ap.add_argument("--limit", type=int, default=None, help="Max users to send to")
    ap.add_argument("--sleep", type=float, default=0.05, help="Sleep between requests (seconds)")
    ap.add_argument("--report", default="logs/broadcast_report.jsonl", help="Path to JSONL report")
    ap.add_argument("--dry", action="store_true", help="Dry run (no sends)")
    args = ap.parse_args()

    if not TELEGRAM_BOT_TOKEN:
        raise SystemExit("TELEGRAM_BOT_TOKEN not set")
    if not (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY):
        raise SystemExit("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required")

    photo_path = Path(args.photo_file).resolve() if args.photo_file else None
    if photo_path and not photo_path.exists():
        raise SystemExit(f"Photo file not found: {photo_path}")

    users = fetch_all_user_ids(start_from=args.start_from, limit=args.limit)
    total = len(users)
    sent = failed = skipped = 0

    Path(args.report).parent.mkdir(parents=True, exist_ok=True)
    with open(args.report, "w", encoding="utf-8") as rep:
        for idx, uid in enumerate(users, start=1):
            status = "dry"
            detail = ""
            if args.dry:
                skipped += 1
            else:
                ok = False
                if photo_path or args.photo_url:
                    ok, detail = tg_send_photo(
                        chat_id=uid,
                        photo_url=args.photo_url,
                        photo_file=photo_path,
                        caption=args.text or None,
                        parse_mode=args.parse_mode,
                    )
                else:
                    ok, detail = tg_send_message(
                        chat_id=uid,
                        text=args.text,
                        parse_mode=args.parse_mode,
                        disable_preview=args.disable_preview,
                    )
                if ok:
                    sent += 1
                    status = "sent"
                else:
                    failed += 1
                    status = f"error:{detail}"

            rep.write(json.dumps({
                "idx": idx,
                "user_id": uid,
                "status": status,
                "detail": detail,
            }, ensure_ascii=False) + "\n")
            rep.flush()

            # Handle simple rate-limiting
            if isinstance(detail, str) and detail.startswith("rate_limited:"):
                try:
                    retry_after = int(detail.split(":", 1)[1])
                except Exception:
                    retry_after = 1
                time.sleep(retry_after + 0.5)
            else:
                time.sleep(max(0.0, args.sleep))

    print(json.dumps({
        "users": total,
        "sent": sent,
        "failed": failed,
        "skipped": skipped,
        "report": args.report,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()

