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


# Predefined templates (ru)
TEMPLATES = {
    # 1) Long ref-fix announcement (requested to be first)
    "ref_fix_long": (
        "Хеееей, {first_name}! ✨\n"
        "Мы починили отображение билетов за приглашённых друзей и доначислили всё, что могло не подтянуться раньше. Теперь вся актуальная статистика у тебя в Mini App — загляни, чтобы увидеть обновлённые цифры.\n"
        "Хочешь быстро и без кликов? Просто отправь боту команду /tickets — там сразу видно: за папку, за друзей и общий итог.\n"
        "Спасибо, что зовёшь друзей и делишься нашим приложением — ты реально помогаешь нам расти! 🖤\n"
        "Дальше — ещё интереснее: готовим новые фичи, дропы и сюрпризы для участников. Следи за обновлениями, будет жарко! 🔥"
    ),
}


def fetch_all_users(batch_size: int = 2000, start_from: int = 0, limit: Optional[int] = None) -> List[dict]:
    headers = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    }
    out: List[dict] = []
    offset = start_from
    remaining = limit if limit is not None else 10**12
    while remaining > 0:
        page = min(batch_size, remaining)
        params = {
            "select": "telegram_id,first_name,username",
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
        users_batch: List[dict] = []
        for row in rows:
            try:
                tid = int(row.get("telegram_id"))
            except Exception:
                continue
            users_batch.append({
                "telegram_id": tid,
                "first_name": (row.get("first_name") or "").strip(),
                "username": (row.get("username") or "").strip(),
            })
        out.extend(users_batch)
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
    ap.add_argument("--template", choices=sorted(TEMPLATES.keys()), default=None, help="Use predefined template text if --text is not provided")
    ap.add_argument("--list-templates", action="store_true", help="List available templates and exit")
    ap.add_argument("--parse-mode", choices=["HTML", "Markdown", "MarkdownV2"], default=None)
    ap.add_argument("--disable-preview", action="store_true", help="Disable link preview for text messages")
    ap.add_argument("--photo-url", default=None, help="Photo URL to send")
    ap.add_argument("--photo-file", default=None, help="Local photo file path to send")
    ap.add_argument("--start-from", type=int, default=0, help="Offset in users list")
    ap.add_argument("--limit", type=int, default=None, help="Max users to send to")
    ap.add_argument("--sleep", type=float, default=None, help="Sleep between requests (seconds). If omitted, you will be prompted (default 0.3s)")
    ap.add_argument("--report", default="logs/broadcast_report.jsonl", help="Path to JSONL report")
    ap.add_argument("--dry", action="store_true", help="Dry run (no sends)")
    ap.add_argument("--yes", action="store_true", help="Do not ask for confirmation (non-interactive)")
    args = ap.parse_args()

    # List templates and exit
    if args.list_templates:
        listing = {name: (TEMPLATES[name][:120] + ("…" if len(TEMPLATES[name]) > 120 else "")) for name in sorted(TEMPLATES.keys())}
        print(json.dumps({"templates": listing}, ensure_ascii=False, indent=2))
        return

    if not TELEGRAM_BOT_TOKEN:
        raise SystemExit("TELEGRAM_BOT_TOKEN not set")
    if not (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY):
        raise SystemExit("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required")

    photo_path = Path(args.photo_file).resolve() if args.photo_file else None
    if photo_path and not photo_path.exists():
        raise SystemExit(f"Photo file not found: {photo_path}")

    # Resolve message text from template if not provided
    if (not args.text) and args.template:
        args.text = TEMPLATES[args.template]

    users = fetch_all_users(start_from=args.start_from, limit=args.limit)
    total = len(users)
    sent = failed = skipped = 0

    # Determine sleep (rate limiting safety)
    sleep_s: float
    if args.sleep is None:
        # prompt user
        try:
            user_in = input("Задержка между отправками, сек [0.3]: ").strip()
            sleep_s = float(user_in) if user_in else 0.3
        except Exception:
            sleep_s = 0.3
    else:
        sleep_s = max(0.0, args.sleep)

    # Summary and confirmation
    summary = {
        "users": total,
        "sleep": sleep_s,
        "dry": args.dry,
        "parse_mode": args.parse_mode,
        "photo_url": bool(args.photo_url),
        "photo_file": bool(photo_path),
    }
    print(json.dumps({"broadcast": summary}, ensure_ascii=False))
    if total == 0:
        print("Нет пользователей для отправки")
        return
    if not args.dry and not args.yes:
        try:
            go = input("Стартуем отправку? [y/N]: ").strip().lower()
        except Exception:
            go = "n"
        if go not in ("y", "yes"):  # abort
            print("Отменено пользователем")
            return

    Path(args.report).parent.mkdir(parents=True, exist_ok=True)
    with open(args.report, "w", encoding="utf-8") as rep:
        for idx, user in enumerate(users, start=1):
            uid = int(user["telegram_id"])  # chat id
            # Per-user templating
            first_name = user.get("first_name") or ""
            username = user.get("username") or ""
            text = (args.text or "").replace("{first_name}", first_name).replace("{username}", username)
            status = "dry"
            detail = ""
            if args.dry:
                skipped += 1
                print(f"[{idx}/{total}] {uid}: DRY-RUN", flush=True)
            else:
                ok = False
                if photo_path or args.photo_url:
                    ok, detail = tg_send_photo(
                        chat_id=uid,
                        photo_url=args.photo_url,
                        photo_file=photo_path,
                        caption=(text or None),
                        parse_mode=args.parse_mode,
                    )
                else:
                    ok, detail = tg_send_message(
                        chat_id=uid,
                        text=text,
                        parse_mode=args.parse_mode,
                        disable_preview=args.disable_preview,
                    )
                if ok:
                    sent += 1
                    status = "sent"
                    print(f"[{idx}/{total}] {uid}: OK", flush=True)
                else:
                    failed += 1
                    status = f"error:{detail}"
                    print(f"[{idx}/{total}] {uid}: ERROR -> {detail}", flush=True)

            rep.write(json.dumps({
                "idx": idx,
                "user_id": uid,
                "first_name": first_name,
                "username": username,
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
                print(f"rate limited: sleep {retry_after + 0.5:.1f}s", flush=True)
                time.sleep(retry_after + 0.5)
            else:
                time.sleep(sleep_s)

    print(json.dumps({
        "users": total,
        "sent": sent,
        "failed": failed,
        "skipped": skipped,
        "report": args.report,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()

