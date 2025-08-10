import os
import requests
from typing import Dict, Any, Optional, List
from common import SUPABASE_URL, supabase_headers, TELEGRAM_BOT_TOKEN, get_subscription_channels

# --- Supabase helpers ---

def _get_rows(endpoint: str, params: Optional[Dict[str, Any]] = None, select: Optional[str] = None):
    q = params.copy() if params else {}
    if select:
        q['select'] = select
    r = requests.get(f"{SUPABASE_URL}/rest/v1/{endpoint}", headers=supabase_headers, params=q, timeout=20)
    if r.status_code in (200, 206):
        return r.json() if r.content else []
    return []


def _post_rows(endpoint: str, rows: List[Dict[str, Any]], prefer: str = 'return=representation', params: Optional[Dict[str, Any]] = None):
    hdrs = {**supabase_headers, 'Prefer': prefer}
    return requests.post(
        f"{SUPABASE_URL}/rest/v1/{endpoint}",
        headers=hdrs,
        params=params or {},
        json=rows,
        timeout=30,
    )


def _patch_users(telegram_id: int, payload: Dict[str, Any]):
    return requests.patch(
        f"{SUPABASE_URL}/rest/v1/users",
        headers={**supabase_headers, 'Prefer': 'return=representation'},
        params={'telegram_id': f"eq.{telegram_id}"},
        json=payload,
        timeout=20,
    )


def _rpc(name: str, body: Dict[str, Any]):
    return requests.post(f"{SUPABASE_URL}/rest/v1/rpc/{name}", headers=supabase_headers, json=body, timeout=30)

# --- Telegram helper ---

def _send_tg_message(chat_id: int, text: str):
    if not TELEGRAM_BOT_TOKEN:
        return
    try:
        requests.get(
            f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage",
            params={'chat_id': chat_id, 'text': text},
            timeout=15,
        )
    except Exception:
        pass

# --- Tasks ---

def process_referral_join(referral_code: str, referred_telegram_id: int) -> Dict[str, Any]:
    """Award a ticket to referrer when a referred user starts via code.
    Protect against self-referrals and duplicates.
    """
    # Find owner
    owner_id: Optional[int] = None
    # Try referrals table first
    rows = _get_rows('referrals', params={'referral_code': f"eq.{referral_code}"}, select='telegram_id,referral_code')
    if isinstance(rows, list) and rows:
        try:
            owner_id = int(rows[0].get('telegram_id'))
        except Exception:
            owner_id = None
    if owner_id is None:
        rows = _get_rows('users', params={'referral_code': f"eq.{referral_code}"}, select='telegram_id')
        if isinstance(rows, list) and rows:
            try:
                owner_id = int(rows[0].get('telegram_id'))
            except Exception:
                owner_id = None
    if not owner_id:
        return {'success': False, 'error': 'invalid_referral_code'}
    if int(owner_id) == int(referred_telegram_id):
        return {'success': False, 'error': 'self_referral'}

    # Duplicate protection
    joins = _get_rows('referral_joins', params={
        'referrer_id': f"eq.{owner_id}",
        'referred_id': f"eq.{referred_telegram_id}"
    }, select='id')
    if isinstance(joins, list) and joins:
        return {'success': True, 'message': 'already_counted'}

    # Insert join
    _post_rows('referral_joins', [{'referrer_id': int(owner_id), 'referred_id': int(referred_telegram_id)}], prefer='return=minimal')

    # Stamp invited_by_* on referred user (if not set yet)
    try:
        referred_rows = _get_rows('users', params={'telegram_id': f"eq.{int(referred_telegram_id)}"}, select='invited_by_referral_code,invited_by_user_id')
        need_update = False
        payload = {}
        if isinstance(referred_rows, list) and referred_rows:
            r = referred_rows[0]
            if not r.get('invited_by_referral_code'):
                payload['invited_by_referral_code'] = referral_code
                need_update = True
            if not r.get('invited_by_user_id'):
                payload['invited_by_user_id'] = int(owner_id)
                need_update = True
        else:
            payload = {
                'invited_by_referral_code': referral_code,
                'invited_by_user_id': int(owner_id),
            }
            need_update = True
        if need_update:
            _patch_users(int(referred_telegram_id), payload)
    except Exception:
        pass

    # Increment tickets with cap 10
    user_rows = _get_rows('users', params={'telegram_id': f"eq.{owner_id}"}, select='subscription_tickets,referral_tickets,total_tickets')
    if not user_rows:
        return {'success': False, 'error': 'referrer_not_found'}
    u = user_rows[0]
    current_ref = int(u.get('referral_tickets', 0) or 0)
    if current_ref >= 10:
        return {'success': True, 'message': 'referral cap reached'}
    # Keep total as consistent sum of subscription + referral (capped)
    new_ref = current_ref + 1
    subs = int(u.get('subscription_tickets', 0) or 0)
    payload = {
        'referral_tickets': new_ref,
        'total_tickets': subs + min(new_ref, 10)
    }
    _patch_users(int(owner_id), payload)

    # Notify referrer
    _send_tg_message(int(owner_id), "🎫 Вам начислен билет за приглашенного друга! Спасибо!")
    return {'success': True, 'ticket_awarded': True}


def check_subscriptions_and_award(telegram_id: int) -> Dict[str, Any]:
    """Check user's subscription across all channels and award 1 ticket via Supabase RPC.
    Also stores per-channel subscription records and notifies the user.
    """
    channels = get_subscription_channels()
    is_all = True
    not_subscribed: List[int] = []
    subscribed_rows: List[Dict[str, Any]] = []

    if not TELEGRAM_BOT_TOKEN:
        return {'success': False, 'error': 'BOT TOKEN not configured'}

    for channel in channels:
        try:
            r = requests.get(
                f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChatMember",
                params={'chat_id': channel['channel_id'], 'user_id': telegram_id},
                timeout=15,
            )
            if r.status_code != 200:
                is_all = False
                not_subscribed.append(channel['channel_id'])
                continue
            status = (r.json() or {}).get('result', {}).get('status')
            if status in ('member', 'administrator', 'creator'):
                subscribed_rows.append({
                    'telegram_id': int(telegram_id),
                    'channel_id': channel['channel_id'],
                    'channel_name': channel.get('channel_name', ''),
                    'channel_username': channel.get('channel_username', ''),
                })
            else:
                is_all = False
                not_subscribed.append(channel['channel_id'])
        except Exception:
            is_all = False
            not_subscribed.append(channel['channel_id'])

    if subscribed_rows:
        try:
            _post_rows(
                'subscriptions',
                subscribed_rows,
                prefer='resolution=merge-duplicates',
                params={'on_conflict': 'telegram_id,channel_id'},
            )
        except Exception:
            pass

    # Supabase RPC for awarding (idempotent logic on DB side preferred)
    rpc_resp = _rpc('check_subscription_and_award_ticket', {
        'p_telegram_id': int(telegram_id),
        'p_is_subscribed': bool(is_all),
    })

    ticket_awarded = False
    if rpc_resp.status_code == 200:
        body = rpc_resp.json() or {}
        ticket_awarded = bool(body.get('ticket_awarded', False))
    else:
        # Fallback: if subscribed to all now, upsert user totals locally without giving duplicate tickets
        if is_all:
            user_rows = _get_rows('users', params={'telegram_id': f"eq.{int(telegram_id)}"}, select='subscription_tickets,referral_tickets,total_tickets')
            if isinstance(user_rows, list) and user_rows:
                u = user_rows[0]
                subs = int(u.get('subscription_tickets', 0) or 0)
                ref = int(u.get('referral_tickets', 0) or 0)
                if subs <= 0:
                    subs = 1
                    _patch_users(int(telegram_id), {
                        'subscription_tickets': subs,
                        'total_tickets': subs + min(ref, 10)
                    })
    # Notify user
    if is_all:
        if ticket_awarded:
            _send_tg_message(int(telegram_id), "✅ Подписки подтверждены. Билет начислен!")
        else:
            _send_tg_message(int(telegram_id), "✅ Подписки подтверждены. Билет ранее был начислен.")
    else:
        _send_tg_message(int(telegram_id), "⚠️ Подпишитесь на все каналы GTM, чтобы получить билет")

    return {
        'success': True,
        'is_subscribed_to_all': is_all,
        'not_subscribed': not_subscribed,
        'ticket_awarded': ticket_awarded,
    }


def direct_update_user_counters(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Coherently update users counters based on small deltas or sets, and recompute total_tickets.
    Expected keys: telegram_id, inc_referral_tickets?, inc_subscription_tickets?,
                   set_invited_by_referral_code?, set_invited_by_user_id?
    """
    telegram_id = int(payload.get('telegram_id'))
    user_rows = _get_rows('users', params={'telegram_id': f"eq.{telegram_id}"}, select='subscription_tickets,referral_tickets,invited_by_referral_code,invited_by_user_id')
    subs = 0
    ref = 0
    if isinstance(user_rows, list) and user_rows:
        u = user_rows[0]
        subs = int(u.get('subscription_tickets', 0) or 0)
        ref = int(u.get('referral_tickets', 0) or 0)
    inc_ref = int(payload.get('inc_referral_tickets') or 0)
    inc_subs = int(payload.get('inc_subscription_tickets') or 0)
    ref = min(10, max(0, ref + inc_ref))
    subs = min(1, max(0, subs + inc_subs))
    patch: Dict[str, Any] = {
        'subscription_tickets': subs,
        'referral_tickets': ref,
        'total_tickets': subs + ref,
    }
    if payload.get('set_invited_by_referral_code') is not None:
        patch['invited_by_referral_code'] = payload['set_invited_by_referral_code']
    if payload.get('set_invited_by_user_id') is not None:
        patch['invited_by_user_id'] = int(payload['set_invited_by_user_id'])
    _patch_users(telegram_id, patch)
    return {'success': True, **patch}