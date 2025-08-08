#!/usr/bin/env python3
"""
API для обработки рейтингов артистов из Flutter приложения
+ Проверка подписок через Telegram Bot API и начисление билета
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import json
import os

app = Flask(__name__)
CORS(app)

# Конфигурация Supabase
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://rxmtovqxjsvogyywyrha.supabase.co")
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

# Telegram Bot
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")

supabase_headers = {
    'apikey': SUPABASE_SERVICE_KEY or SUPABASE_ANON_KEY,
    'Authorization': f'Bearer {SUPABASE_SERVICE_KEY or SUPABASE_ANON_KEY}',
    'Content-Type': 'application/json'
}

SUBSCRIPTION_CHANNELS = [
    { 'channel_id': -1002088959587, 'channel_username': 'rejmenyavseryoz', 'channel_name': 'Режь меня всерьёз' },
    { 'channel_id': -1001971855072, 'channel_username': 'chchndra_tattoo', 'channel_name': 'Чучундра' },
    { 'channel_id': -1002133674248, 'channel_username': 'naidenka_tattoo', 'channel_name': 'naidenka_tattoo' },
    { 'channel_id': -1001508215942, 'channel_username': 'l1n_ttt', 'channel_name': 'Lin++' },
    { 'channel_id': -1001555462429, 'channel_username': 'murderd0lll', 'channel_name': 'MurderdOll' },
    { 'channel_id': -1002132954014, 'channel_username': 'poteryashkatattoo', 'channel_name': 'Потеряшка' },
    { 'channel_id': -1001689395571, 'channel_username': 'EMI3MO', 'channel_name': 'EMI' },
    { 'channel_id': -1001767997947, 'channel_username': 'bloodivamp', 'channel_name': 'bloodivamp' },
    { 'channel_id': -1001973736826, 'channel_username': 'G_T_MODEL', 'channel_name': "Gothams top model" },
]

# === API for Giveaway (X/Y and referrals) ===
@app.route('/api/giveaway/total_all', methods=['GET'])
def total_all_tickets():
    """Вернуть total_all_tickets из таблицы/представления total_all_tickets"""
    try:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/total_all_tickets",
            headers=supabase_headers,
            params={'select': '*'},
            timeout=15,
        )
        if resp.status_code in (200, 206):
            rows = resp.json() if resp.content else []
            value = None
            if isinstance(rows, list) and rows:
                row = rows[0]
                for key in ['total_all_tickets', 'total_all', 'total', 'value', 'count']:
                    if key in row:
                        v = row[key]
                        try:
                            value = int(v)
                            break
                        except Exception:
                            pass
                if value is None:
                    for v in row.values():
                        try:
                            value = int(v)
                            break
                        except Exception:
                            continue
            if value is not None:
                return jsonify({'success': True, 'total_all_tickets': value})
            return jsonify({'success': False, 'error': 'no value'}), 404
        return jsonify({'success': False, 'error': 'supabase error', 'status': resp.status_code, 'detail': resp.text}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/giveaway/user_stats/<int:telegram_id>', methods=['GET'])
def giveaway_user_stats(telegram_id: int):
    """Вернуть user tickets и referral tickets по telegram_id из users"""
    try:
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/users",
            headers=supabase_headers,
            params={'telegram_id': f"eq.{telegram_id}", 'select': 'total_tickets,subscription_tickets,referral_tickets,referral_code'},
            timeout=15,
        )
        if resp.status_code in (200, 206):
            rows = resp.json() if resp.content else []
            if isinstance(rows, list) and rows:
                u = rows[0]
                return jsonify({
                    'success': True,
                    'total_tickets': u.get('total_tickets', 0),
                    'subscription_tickets': u.get('subscription_tickets', 0),
                    'referral_tickets': u.get('referral_tickets', 0),
                    'referral_code': u.get('referral_code', ''),
                })
            return jsonify({'success': True, 'total_tickets': 0, 'subscription_tickets': 0, 'referral_tickets': 0, 'referral_code': ''})
        return jsonify({'success': False, 'error': 'supabase error', 'status': resp.status_code, 'detail': resp.text}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/referral-code', methods=['POST'])
def get_or_create_referral_code():
    try:
        data = request.get_json() or {}
        telegram_id = data.get('telegram_id')
        if not telegram_id:
            return jsonify({'success': False, 'error': 'telegram_id required'}), 400
        # 1) get user
        get_resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/users",
            headers=supabase_headers,
            params={
                'telegram_id': f"eq.{telegram_id}",
                'select': 'telegram_id,referral_code'
            },
            timeout=15
        )
        if get_resp.status_code not in (200, 206):
            return jsonify({'success': False, 'error': 'Failed to query user', 'detail': get_resp.text}), 500
        rows = get_resp.json() if get_resp.content else []
        # 2) If exists and has code
        if isinstance(rows, list) and rows:
            user = rows[0]
            code = user.get('referral_code')
            if code:
                return jsonify({'success': True, 'referral_code': code})
            # 3) else create code and patch
            import random, string
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            patch_resp = requests.patch(
                f"{SUPABASE_URL}/rest/v1/users",
                headers={**supabase_headers, 'Prefer': 'return=representation'},
                params={'telegram_id': f"eq.{telegram_id}"},
                json={'referral_code': code},
                timeout=15
            )
            if patch_resp.status_code in (200, 204):
                return jsonify({'success': True, 'referral_code': code})
            return jsonify({'success': False, 'error': 'Failed to set referral_code', 'detail': patch_resp.text}), 500
        # 4) user doesn't exist -> insert with minimal fields
        import random, string
        code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        insert_resp = requests.post(
            f"{SUPABASE_URL}/rest/v1/users",
            headers={**supabase_headers, 'Prefer': 'return=representation'},
            json={
                'telegram_id': int(telegram_id),
                'username': '',
                'first_name': '',
                'last_name': '',
                'subscription_tickets': 0,
                'referral_tickets': 0,
                'total_tickets': 0,
                'referral_code': code
            },
            timeout=15
        )
        if insert_resp.status_code in (200, 201):
            return jsonify({'success': True, 'referral_code': code})
        return jsonify({'success': False, 'error': 'Failed to create user', 'detail': insert_resp.text}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/check-subscriptions', methods=['POST'])
def check_subscriptions():
    """Проверить подписку пользователя на все каналы и начислить билет 1 раз"""
    try:
        data = request.get_json() or {}
        telegram_id = data.get('telegram_id')
        if not telegram_id:
            return jsonify({'success': False, 'error': 'telegram_id required'}), 400

        if not TELEGRAM_BOT_TOKEN:
            return jsonify({'success': False, 'error': 'BOT TOKEN not configured'}), 500

        # Проверяем подписку на все каналы
        is_all = True
        not_subscribed = []
        subscribed_rows = []
        for channel in SUBSCRIPTION_CHANNELS:
            chat_id = channel['channel_id']
            url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChatMember"
            resp = requests.get(url, params={'chat_id': chat_id, 'user_id': telegram_id}, timeout=15)
            if resp.status_code != 200:
                is_all = False
                not_subscribed.append(chat_id)
                continue
            member = resp.json().get('result', {})
            status = member.get('status')
            if status in ('member', 'administrator', 'creator'):
                subscribed_rows.append({
                    'telegram_id': int(telegram_id),
                    'channel_id': channel['channel_id'],
                    'channel_name': channel['channel_name'],
                    'channel_username': channel['channel_username']
                })
            else:
                is_all = False
                not_subscribed.append(chat_id)

        # Зафиксировать подписки в таблицу subscriptions (idempotent upsert)
        if subscribed_rows:
            try:
                subs_headers = { **supabase_headers, 'Prefer': 'resolution=merge-duplicates' }
                subs_resp = requests.post(
                    f"{SUPABASE_URL}/rest/v1/subscriptions",
                    headers=subs_headers,
                    params={'on_conflict': 'telegram_id,channel_id'},
                    json=subscribed_rows,
                    timeout=20
                )
                # не прерываем поток даже при ошибке
            except Exception:
                pass

        # Вызываем RPC для начисления билета
        rpc_url = f"{SUPABASE_URL}/rest/v1/rpc/check_subscription_and_award_ticket"
        rpc_body = {'p_telegram_id': int(telegram_id), 'p_is_subscribed': bool(is_all)}
        rpc_resp = requests.post(rpc_url, headers=supabase_headers, json=rpc_body, timeout=20)

        payload = {'success': False, 'is_subscribed_to_all': is_all, 'not_subscribed': not_subscribed}

        if rpc_resp.status_code == 200:
            body = rpc_resp.json()
            payload.update(body)
            payload['success'] = True
            return jsonify(payload)
        else:
            return jsonify({**payload, 'error': f'RPC error {rpc_resp.status_code}', 'rpc_body': rpc_resp.text}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/rate-artist', methods=['POST'])
def rate_artist():
    """API эндпоинт для получения рейтингов из Flutter"""
    try:
        data = request.get_json()
        
        # Валидация данных
        if not data:
            return jsonify({"success": False, "error": "No data provided"}), 400
            
        artist_name = data.get('artist_name')
        user_id = data.get('user_id') 
        rating = data.get('rating')
        comment = data.get('comment', '')
        
        if not all([artist_name, user_id, rating]):
            return jsonify({"success": False, "error": "Missing required fields"}), 400
            
        if not isinstance(rating, int) or rating < 1 or rating > 5:
            return jsonify({"success": False, "error": "Rating must be between 1 and 5"}), 400
        
        print(f"📝 Получен рейтинг от Flutter: {user_id} оценил {artist_name} на {rating} звезд")
        
        # Вызываем RPC функцию в Supabase для добавления рейтинга
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/add_artist_rating",
            headers=supabase_headers,
            json={
                "artist_name_param": artist_name,
                "user_id_param": str(user_id),
                "rating_param": rating,
                "comment_param": comment if comment else None
            }
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print(f"✅ Рейтинг успешно сохранен для {artist_name}")
                
                # Получаем обновленную статистику
                stats_response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/rpc/get_artist_rating",
                    headers=supabase_headers,
                    json={"artist_name_param": artist_name}
                )
                
                stats = {}
                if stats_response.status_code == 200:
                    stats = stats_response.json()
                
                return jsonify({
                    "success": True,
                    "message": "Rating saved successfully",
                    "stats": stats
                })
            else:
                error = result.get("error", "Unknown error")
                print(f"❌ Ошибка от Supabase: {error}")
                return jsonify({"success": False, "error": error}), 400
        else:
            print(f"❌ Ошибка HTTP от Supabase: {response.status_code}")
            return jsonify({"success": False, "error": f"Supabase error: {response.status_code}"}), 500
            
    except Exception as e:
        print(f"❌ Исключение в rate_artist: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/get-rating/<artist_name>', methods=['GET'])
def get_artist_rating(artist_name):
    """API эндпоинт для получения рейтинга артиста"""
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/get_artist_rating",
            headers=supabase_headers,
            json={"artist_name_param": artist_name}
        )
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({"error": f"Failed to get rating: {response.status_code}"}), 500
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Проверка работоспособности API"""
    return jsonify({"status": "ok", "message": "Rating API is working"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"🚀 Запускаем Rating API на порту {port}")
    app.run(host='0.0.0.0', port=port, debug=True)