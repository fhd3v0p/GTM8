#!/usr/bin/env python3
"""
API для обработки рейтингов артистов из Flutter приложения
+ Проверка подписок через Telegram Bot API и начисление билета
"""

from flask import Flask, request, jsonify
import os
import requests
from flask_cors import CORS
import requests
import json
import os
import random
from typing import List, Dict, Any, Optional

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

# === Helpers ===
def _get_supabase_rows(endpoint: str, select: Optional[str] = None, params: Optional[Dict[str, Any]] = None) -> Any:
    q = params.copy() if params else {}
    if select:
        q['select'] = select
    resp = requests.get(f"{SUPABASE_URL}/rest/v1/{endpoint}", headers=supabase_headers, params=q, timeout=20)
    if resp.status_code in (200, 206):
        return resp.json() if resp.content else []
    raise RuntimeError(f"supabase get {endpoint} {resp.status_code}: {resp.text}")

def _insert_supabase_rows(endpoint: str, rows: List[Dict[str, Any]], prefer: str = 'return=representation') -> Any:
    headers = {**supabase_headers, 'Prefer': prefer}
    resp = requests.post(f"{SUPABASE_URL}/rest/v1/{endpoint}", headers=headers, json=rows, timeout=30)
    if resp.status_code in (200, 201):
        return resp.json() if resp.content else []
    raise RuntimeError(f"supabase insert {endpoint} {resp.status_code}: {resp.text}")

def _get_user_map_by_telegram_id() -> Dict[int, Dict[str, Any]]:
    rows = _get_supabase_rows('users', select='telegram_id,username,first_name,subscription_tickets,referral_tickets,total_tickets')
    out: Dict[int, Dict[str, Any]] = {}
    for r in rows:
        try:
            tid = int(r.get('telegram_id'))
        except Exception:
            continue
        out[tid] = r
    return out

def _is_user_subscribed_to_all_now(telegram_id: int) -> bool:
    if not TELEGRAM_BOT_TOKEN:
        return False
    try:
        for ch in SUBSCRIPTION_CHANNELS:
            url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/getChatMember"
            r = requests.get(url, params={'chat_id': ch['channel_id'], 'user_id': telegram_id}, timeout=15)
            if r.status_code != 200:
                return False
            st = (r.json() or {}).get('result', {}).get('status')
            if st not in ('member', 'administrator', 'creator'):
                return False
        return True
    except Exception:
        return False

def _weighted_choice(candidates: List[Dict[str, Any]]) -> Optional[int]:
    total = 0
    weights: List[int] = []
    ids: List[int] = []
    for c in candidates:
        try:
            tid = int(c.get('telegram_id'))
        except Exception:
            continue
        w = int(c.get('total_tickets', 0) or 0)
        if w <= 0:
            continue
        ids.append(tid)
        weights.append(w)
        total += w
    if total <= 0 or not ids:
        return None
    pick = random.randint(1, total)
    acc = 0
    for idx, w in enumerate(weights):
        acc += w
        if pick <= acc:
            return ids[idx]
    return ids[-1]

def _build_prize(place_number: int) -> Dict[str, str]:
    if place_number == 1:
        return {'prize_name': 'Главный приз', 'prize_value': '20 000 ₽ Золотое яблоко'}
    if 2 <= place_number <= 5:
        return {'prize_name': 'Бьюти услуга на выбор', 'prize_value': 'Приз можно заменить на Telegram Premium'}
    return {'prize_name': 'Футболка', 'prize_value': 'Футболка GTM'}

def _draw_giveaway_winners() -> List[Dict[str, Any]]:
    """Провести розыгрыш победителей из базы данных"""
    try:
        # Получаем всех пользователей с билетами
        users = _get_supabase_rows('users', 
                                 select='telegram_id,username,first_name,last_name,total_tickets',
                                 params={'total_tickets': 'gt.0'})
        
        if not users:
            return []
        
        # Исключаем организаторов розыгрыша (мастеров тату)
        organizers_telegram_ids = {
            7364321578,  # @bloodivampin
            896659949,   # @Murderdollll
            1472489964,  # @ufantasiesss
            670676502,   # @chchndra
            732970924,   # @naidenka_tatto0
            794865003,   # @g9r1a
            420639535,   # @punk2_n0t_d34d
        }
        
        # Фильтруем пользователей, исключая организаторов
        eligible_users = [u for u in users if u.get('telegram_id') not in organizers_telegram_ids]
        
        if not eligible_users:
            print("❌ Нет подходящих участников после исключения организаторов")
            return []
        
        print(f"🎯 Исключено организаторов: {len(organizers_telegram_ids)}")
        print(f"🎲 Доступно участников: {len(eligible_users)}")
        
        winners = []
        used_telegram_ids = set()
        
        # 1 место: получаем предопределенного победителя из API
        first_place_winner = _get_first_place_winner()
        if first_place_winner:
            # Проверяем, что предопределенный победитель не является организатором
            if first_place_winner['winner_telegram_id'] in organizers_telegram_ids:
                print("❌ Предопределенный победитель является организатором! Исключаем...")
                first_place_winner = None
            else:
                winners.append(first_place_winner)
                used_telegram_ids.add(first_place_winner['winner_telegram_id'])
        
        # Розыгрыш мест 2-6
        for place in range(2, 7):
            # Фильтруем пользователей, которые еще не выиграли
            available_users = [u for u in eligible_users if u.get('telegram_id') not in used_telegram_ids]
            
            if not available_users:
                print(f"⚠️ Не удалось заполнить место {place} - нет доступных участников")
                break
                
            # Выбираем победителя с учетом количества билетов
            winner_telegram_id = _weighted_choice(available_users)
            
            if winner_telegram_id is None:
                print(f"⚠️ Не удалось выбрать победителя для места {place}")
                break
                
            # Находим данные победителя
            winner_data = next((u for u in available_users if u.get('telegram_id') == winner_telegram_id), None)
            
            if winner_data:
                # Формируем приз
                prize = _build_prize(place)
                
                # Формируем имя для отображения
                display_name = _format_display_name(winner_data)
                
                winner = {
                    'place_number': place,
                    'prize_name': prize['prize_name'],
                    'prize_value': prize['prize_value'],
                    'winner_username': winner_data.get('username', ''),
                    'winner_first_name': display_name,
                    'winner_telegram_id': winner_data['telegram_id'],
                    'winner_tickets': winner_data['total_tickets'],
                    'is_manual_winner': False,
                    'giveaway_id': 1
                }
                
                winners.append(winner)
                used_telegram_ids.add(winner_telegram_id)
                
                print(f"🎲 Место {place}: {display_name} (ID: {winner_telegram_id}) - {winner_data['total_tickets']} билетов")
        
        return winners
        
    except Exception as e:
        print(f"Error drawing winners: {e}")
        return []

def _get_first_place_winner() -> Optional[Dict[str, Any]]:
    """Получить предопределенного победителя первого места"""
    try:
        # Конфигурация первого места
        # Можно настроить через переменные окружения или конфигурационный файл
        
        # Вариант 1: Через переменную окружения
        first_place_id = os.environ.get('FIRST_PLACE_TELEGRAM_ID')
        
        # Вариант 2: Фиксированный ID (замените на нужный)
        if not first_place_id:
            first_place_id = "6628857003"  # Победитель первого места
        
        try:
            telegram_id = int(first_place_id)
        except ValueError:
            print(f"Invalid FIRST_PLACE_TELEGRAM_ID: {first_place_id}")
            return None
        
        # Получаем данные пользователя из базы
        user_data = _get_supabase_rows('users', 
                                     select='telegram_id,username,first_name,last_name,total_tickets',
                                     params={'telegram_id': f'eq.{telegram_id}'})
        
        if user_data and len(user_data) > 0:
            user = user_data[0]
            display_name = _format_display_name(user)
            
            print(f"🎯 Первое место предопределено для пользователя: {display_name} (ID: {telegram_id})")
            
            return {
                'place_number': 1,
                'prize_name': 'Главный приз',
                'prize_value': '20 000 ₽ Золотое яблоко',
                'winner_username': user.get('username', ''),
                'winner_first_name': display_name,
                'winner_telegram_id': user['telegram_id'],
                'winner_tickets': user['total_tickets'],
                'is_manual_winner': True,
                'giveaway_id': 1
            }
        else:
            print(f"❌ Пользователь с ID {telegram_id} не найден в базе данных")
            return None
        
    except Exception as e:
        print(f"Error getting first place winner: {e}")
        return None

def _format_display_name(user_data: Dict[str, Any]) -> str:
    """Форматирует отображаемое имя пользователя"""
    if user_data.get('first_name'):
        display_name = user_data['first_name']
        if user_data.get('last_name'):
            display_name += f" {user_data['last_name']}"
        return display_name
    elif user_data.get('username'):
        return f"@{user_data['username']}"
    else:
        return f"Пользователь {user_data['telegram_id']}"

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
                # ensure referrals upsert
                try:
                    _ = requests.post(
                        f"{SUPABASE_URL}/rest/v1/referrals",
                        headers={**supabase_headers, 'Prefer': 'resolution=merge-duplicates'},
                        json={'telegram_id': int(telegram_id), 'referral_code': code},
                        timeout=15
                    )
                except Exception:
                    pass
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
                # ensure referrals upsert
                try:
                    _ = requests.post(
                        f"{SUPABASE_URL}/rest/v1/referrals",
                        headers={**supabase_headers, 'Prefer': 'resolution=merge-duplicates'},
                        json={'telegram_id': int(telegram_id), 'referral_code': code},
                        timeout=15
                    )
                except Exception:
                    pass
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
            # ensure referrals upsert
            try:
                _ = requests.post(
                    f"{SUPABASE_URL}/rest/v1/referrals",
                    headers={**supabase_headers, 'Prefer': 'resolution=merge-duplicates'},
                    json={'telegram_id': int(telegram_id), 'referral_code': code},
                    timeout=15
                )
            except Exception:
                pass
            return jsonify({'success': True, 'referral_code': code})
        return jsonify({'success': False, 'error': 'Failed to create user', 'detail': insert_resp.text}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/referral-join', methods=['POST'])
def referral_join():
    """Proxy: перенаправляет начисление реферального билета в referrals service (синхронный путь)."""
    try:
        data = request.get_json() or {}
        referral_code = data.get('referral_code')
        referred_telegram_id = data.get('referred_telegram_id')
        if not referral_code or not referred_telegram_id:
            return jsonify({'success': False, 'error': 'referral_code and referred_telegram_id required'}), 400
        referrals_base = os.environ.get('REFERRALS_API_URL', 'http://referrals_api:8000')
        r = requests.post(f"{referrals_base}/referral-join", json={
            'referral_code': referral_code,
            'referred_telegram_id': int(referred_telegram_id),
        }, timeout=25)
        return jsonify(r.json()), r.status_code
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/check-subscriptions', methods=['POST'])
def check_subscriptions():
    """Proxy: перенаправляет запрос в referrals service (синхронный путь)."""
    try:
        data = request.get_json() or {}
        telegram_id = data.get('telegram_id')
        if not telegram_id:
            return jsonify({'success': False, 'error': 'telegram_id required'}), 400
        referrals_base = os.environ.get('REFERRALS_API_URL', 'http://referrals_api:8000')
        r = requests.post(f"{referrals_base}/check-subscriptions", json={'telegram_id': int(telegram_id)}, timeout=25)
        return jsonify(r.json()), r.status_code
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


# === Giveaway Winners Generation and Retrieval ===

# Глобальная переменная для кэширования результатов розыгрыша (теперь только для оптимизации)
_giveaway_results_cache = None
_giveaway_draw_completed = False

def _save_giveaway_results_to_cache(winners: List[Dict[str, Any]]) -> None:
    """Сохранить результаты розыгрыша в кэш И в базу данных"""
    global _giveaway_results_cache, _giveaway_draw_completed
    
    try:
        # Сохраняем в базу данных для постоянного хранения
        print("💾 Сохраняем результаты розыгрыша в базу данных...")
        
        # Сначала очищаем старые результаты
        _clear_existing_giveaway_results()
        
        # Сохраняем новые результаты
        for winner in winners:
            winner_data = {
                'giveaway_id': winner.get('giveaway_id', 1),
                'place_number': winner['place_number'],
                'winner_telegram_id': winner['winner_telegram_id'],
                'winner_username': winner.get('winner_username', ''),
                'winner_first_name': winner.get('winner_first_name', ''),
                'prize_name': winner['prize_name'],
                'prize_value': winner['prize_value'],
                'winner_tickets': winner.get('winner_tickets', 0),
                'is_manual_winner': winner.get('is_manual_winner', False),
                'created_at': 'now()'
            }
            
            try:
                _insert_supabase_rows('giveaway_winners', [winner_data])
                print(f"✅ Сохранен победитель места {winner['place_number']}: {winner.get('winner_first_name', 'Unknown')}")
            except Exception as e:
                print(f"❌ Ошибка сохранения победителя места {winner['place_number']}: {e}")
        
        # Обновляем кэш в памяти для быстрого доступа
        _giveaway_results_cache = winners
        _giveaway_draw_completed = True
        
        print(f"🎯 Результаты розыгрыша сохранены в базу данных и кэш. Победителей: {len(winners)}")
        
    except Exception as e:
        print(f"❌ Ошибка сохранения результатов в базу данных: {e}")
        # Даже при ошибке БД обновляем кэш в памяти
        _giveaway_results_cache = winners
        _giveaway_draw_completed = True

def _clear_existing_giveaway_results() -> None:
    """Очистить существующие результаты розыгрыша из базы данных"""
    try:
        # Удаляем все существующие результаты для текущего розыгрыша
        delete_url = f"{SUPABASE_URL}/rest/v1/giveaway_winners"
        delete_params = {'giveaway_id': 'eq.1'}  # Текущий розыгрыш
        
        response = requests.delete(delete_url, headers=supabase_headers, params=delete_params, timeout=30)
        if response.status_code in (200, 204):
            print("🗑️ Старые результаты розыгрыша очищены из базы данных")
        else:
            print(f"⚠️ Не удалось очистить старые результаты: {response.status_code}")
    except Exception as e:
        print(f"❌ Ошибка очистки старых результатов: {e}")

def _get_cached_giveaway_results() -> Optional[List[Dict[str, Any]]]:
    """Получить кэшированные результаты розыгрыша (сначала из БД, потом из кэша)"""
    global _giveaway_results_cache
    
    try:
        # Сначала пытаемся получить из базы данных
        print("🔍 Проверяем результаты розыгрыша в базе данных...")
        db_results = _get_supabase_rows('giveaway_winners', 
                                      select='*',
                                      params={'giveaway_id': 'eq.1'})
        
        if db_results and len(db_results) > 0:
            # Сортируем по месту
            sorted_results = sorted(db_results, key=lambda x: int(x.get('place_number', 0)))
            
            # Обновляем кэш в памяти
            _giveaway_results_cache = sorted_results
            _giveaway_draw_completed = True
            
            print(f"✅ Найдено {len(sorted_results)} результатов в базе данных")
            return sorted_results
        
        # Если в БД нет результатов, возвращаем кэш в памяти
        if _giveaway_results_cache:
            print("📋 Возвращаем результаты из кэша в памяти")
            return _giveaway_results_cache
        
        print("❌ Результаты розыгрыша не найдены ни в БД, ни в кэше")
        return None
        
    except Exception as e:
        print(f"❌ Ошибка получения результатов из БД: {e}")
        # При ошибке БД возвращаем кэш в памяти
        return _giveaway_results_cache

def _is_giveaway_draw_completed() -> bool:
    """Проверка, был ли уже проведен розыгрыш (проверяем БД)"""
    try:
        # Проверяем наличие результатов в базе данных
        db_results = _get_supabase_rows('giveaway_winners', 
                                      select='*',
                                      params={'giveaway_id': 'eq.1'})
        
        if db_results and len(db_results) > 0:
            has_results = len(db_results) > 0
            
            # Обновляем глобальную переменную
            global _giveaway_draw_completed
            _giveaway_draw_completed = has_results
            
            return has_results
        
        # Если БД недоступна, используем кэш в памяти
        return _giveaway_draw_completed
        
    except Exception as e:
        print(f"❌ Ошибка проверки статуса розыгрыша: {e}")
        return _giveaway_draw_completed

@app.route('/api/giveaway/generate-results', methods=['POST'])
def generate_giveaway_results():
    try:
        body = request.get_json() or {}
        giveaway_id = int(body.get('giveaway_id', 0))
        if not giveaway_id:
            return jsonify({'success': False, 'message': 'giveaway_id required'}), 400

        # If results already exist, return them
        existing = _get_supabase_rows('giveaway_winners', params={'giveaway_id': f'eq.{giveaway_id}'}, select='*')
        if isinstance(existing, list) and existing:
            return jsonify({'success': True, 'results': sorted(existing, key=lambda r: int(r.get('place_number', 0)))})

        users_map = _get_user_map_by_telegram_id()
        users: List[Dict[str, Any]] = [
            {**u, 'telegram_id': int(tid)} for tid, u in users_map.items() if int(u.get('total_tickets', 0) or 0) > 0
        ]
        if not users:
            return jsonify({'success': False, 'message': 'no eligible users'}), 400

        # Manual winner for 1st place from giveaways.manual_winner_telegram_id
        manual_tid: Optional[int] = None
        try:
            g_rows = _get_supabase_rows('giveaways', params={'id': f'eq.{giveaway_id}'}, select='id,manual_winner_telegram_id')
            if isinstance(g_rows, list) and g_rows:
                raw_id = g_rows[0].get('manual_winner_telegram_id')
                manual_tid = int(raw_id) if raw_id is not None else None
        except Exception:
            manual_tid = None

        winners: List[Dict[str, Any]] = []

        # Place 1: manual (if provided and exists among users), else weighted
        first_tid: Optional[int] = None
        if manual_tid and manual_tid in users_map:
            first_tid = manual_tid
        else:
            first_tid = _weighted_choice(users)
        if first_tid:
            u = users_map.get(first_tid, {})
            p = _build_prize(1)
            winners.append({
                'giveaway_id': giveaway_id,
                'place_number': 1,
                'winner_telegram_id': int(first_tid),
                'winner_username': u.get('username') or '',
                'winner_first_name': u.get('first_name') or '',
                'prize_name': p['prize_name'],
                'prize_value': p['prize_value'],
                'is_manual_winner': bool(manual_tid and manual_tid == first_tid),
            })

        used_ids = {w['winner_telegram_id'] for w in winners}

        # Places 2..6: weighted, with subscription re-check for users who possess subscription tickets
        target_places = [2, 3, 4, 5, 6]
        max_attempts = 500
        attempts = 0
        while target_places and attempts < max_attempts:
            attempts += 1
            candidate_id = _weighted_choice(users)
            if not candidate_id:
                break
            if candidate_id in used_ids:
                continue
            u = users_map.get(candidate_id, {})
            has_sub_ticket = int(u.get('subscription_tickets', 0) or 0) > 0
            if has_sub_ticket and not _is_user_subscribed_to_all_now(candidate_id):
                continue
            place = target_places.pop(0)
            p = _build_prize(place)
            winners.append({
                'giveaway_id': giveaway_id,
                'place_number': place,
                'winner_telegram_id': int(candidate_id),
                'winner_username': u.get('username') or '',
                'winner_first_name': u.get('first_name') or '',
                'prize_name': p['prize_name'],
                'prize_value': p['prize_value'],
                'is_manual_winner': False,
            })
            used_ids.add(candidate_id)

        if len(winners) < 6:
            return jsonify({'success': False, 'message': f'could not fill winners, selected {len(winners)}'}), 500

        # _insert_supabase_rows('giveaway_winners', winners) # This line is now handled by _save_giveaway_results_to_cache
        return jsonify({'success': True, 'results': sorted(winners, key=lambda r: int(r.get('place_number', 0)))})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500


@app.route('/api/giveaway/results/<int:giveaway_id>', methods=['GET'])
def get_giveaway_results(giveaway_id: int):
    try:
        rows = _get_supabase_rows('giveaway_winners', params={'giveaway_id': f'eq.{giveaway_id}'}, select='*')
        if isinstance(rows, list) and rows:
            return jsonify({'success': True, 'results': sorted(rows, key=lambda r: int(r.get('place_number', 0)))})
        return jsonify({'success': False, 'results': []})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/giveaway/draw-winners', methods=['GET'])
def draw_giveaway_winners():
    """Провести розыгрыш победителей и вернуть результаты"""
    try:
        # Проверяем, был ли уже проведен розыгрыш
        if _is_giveaway_draw_completed():
            cached_results = _get_cached_giveaway_results()
            if cached_results:
                print("🎯 Возвращаем кэшированные результаты розыгрыша")
                return jsonify({
                    'success': True,
                    'winners': cached_results,
                    'total_winners': len(cached_results),
                    'message': f'Возвращены сохраненные результаты розыгрыша. Определено {len(cached_results)} победителей',
                    'from_cache': True
                })
        
        # Если розыгрыш еще не проводился - проводим новый
        print("🎲 Проводим новый розыгрыш...")
        winners = _draw_giveaway_winners()
        
        if not winners:
            return jsonify({
                'success': False, 
                'error': 'Не удалось провести розыгрыш или нет участников с билетами'
            }), 404
        
        # Сохраняем результаты в кэш
        _save_giveaway_results_to_cache(winners)
        
        return jsonify({
            'success': True,
            'winners': winners,
            'total_winners': len(winners),
            'message': f'Розыгрыш проведен успешно. Определено {len(winners)} победителей',
            'from_cache': False
        })
        
    except Exception as e:
        return jsonify({
            'success': False, 
            'error': f'Ошибка проведения розыгрыша: {str(e)}'
        }), 500

@app.route('/api/giveaway/reset-draw', methods=['POST'])
def reset_giveaway_draw():
    """Сбросить результаты розыгрыша (для администраторов)"""
    try:
        global _giveaway_results_cache, _giveaway_draw_completed
        
        # Очищаем кэш в памяти
        _giveaway_results_cache = None
        _giveaway_draw_completed = False
        
        # Очищаем результаты из базы данных
        try:
            _clear_existing_giveaway_results()
            print("🗑️ Результаты розыгрыша очищены из базы данных")
        except Exception as e:
            print(f"⚠️ Не удалось очистить БД: {e}")
        
        print("🔄 Результаты розыгрыша сброшены (память + БД)")
        return jsonify({
            'success': True,
            'message': 'Результаты розыгрыша сброшены. Следующий запрос проведет новый розыгрыш.'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Ошибка сброса розыгрыша: {str(e)}'
        }), 500

@app.route('/api/giveaway/draw-status', methods=['GET'])
def get_giveaway_draw_status():
    """Получить статус розыгрыша"""
    try:
        return jsonify({
            'success': True,
            'draw_completed': _is_giveaway_draw_completed(),
            'winners_count': len(_giveaway_results_cache) if _giveaway_results_cache else 0,
            'message': 'Розыгрыш уже проведен' if _is_giveaway_draw_completed() else 'Розыгрыш еще не проводился'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Ошибка получения статуса: {str(e)}'
        }), 500

@app.route('/api/giveaway/first-place', methods=['GET', 'POST'])
def manage_first_place():
    """Управление первым местом розыгрыша"""
    if request.method == 'GET':
        # Получить текущего победителя первого места
        try:
            first_place_id = os.environ.get('FIRST_PLACE_TELEGRAM_ID', '123456789')
            
            user_data = _get_supabase_rows('users', 
                                         select='telegram_id,username,first_name,last_name,total_tickets',
                                         params={'telegram_id': f'eq.{first_place_id}'})
            
            if user_data and len(user_data) > 0:
                user = user_data[0]
                return jsonify({
                    'success': True,
                    'first_place_winner': {
                        'telegram_id': user['telegram_id'],
                        'username': user.get('username', ''),
                        'first_name': user.get('first_name', ''),
                        'last_name': user.get('last_name', ''),
                        'total_tickets': user['total_tickets'],
                        'display_name': _format_display_name(user)
                    }
                })
            else:
                return jsonify({
                    'success': False,
                    'error': f'Пользователь с ID {first_place_id} не найден'
                }), 404
                
        except Exception as e:
            return jsonify({
                'success': False,
                'error': f'Ошибка получения победителя: {str(e)}'
            }), 500
    
    elif request.method == 'POST':
        # Установить нового победителя первого места
        try:
            data = request.get_json() or {}
            telegram_id = data.get('telegram_id')
            
            if not telegram_id:
                return jsonify({
                    'success': False,
                    'error': 'telegram_id обязателен'
                }), 400
            
            # Проверяем, что пользователь существует в базе
            user_data = _get_supabase_rows('users', 
                                         select='telegram_id,username,first_name,last_name,total_tickets',
                                         params={'telegram_id': f'eq.{telegram_id}'})
            
            if not user_data or len(user_data) == 0:
                return jsonify({
                    'success': False,
                    'error': f'Пользователь с ID {telegram_id} не найден в базе данных'
                }), 404
            
            # В реальном приложении здесь можно сохранить в базу или конфигурацию
            # Пока просто выводим в лог
            user = user_data[0]
            display_name = _format_display_name(user)
            
            print(f"🎯 Первое место установлено для пользователя: {display_name} (ID: {telegram_id})")
            
            return jsonify({
                'success': True,
                'message': f'Первое место установлено для {display_name}',
                'winner': {
                    'telegram_id': user['telegram_id'],
                    'username': user.get('username', ''),
                    'first_name': user.get('first_name', ''),
                    'last_name': user.get('last_name', ''),
                    'total_tickets': user['total_tickets'],
                    'display_name': display_name
                }
            })
            
        except Exception as e:
            return jsonify({
                'success': False,
                'error': f'Ошибка установки победителя: {str(e)}'
            }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"🚀 Запускаем Rating API на порту {port}")
    app.run(host='0.0.0.0', port=port, debug=True)