#!/usr/bin/env python3
"""
GTM Supabase Client
Клиент для работы с Supabase API
"""

import os
import logging
import aiohttp
import json
import requests
from typing import Dict, List, Optional
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

class SupabaseClient:
    def __init__(self, use_service_role: bool = False):
        self.base_url = os.getenv('SUPABASE_URL')
        self.anon_key = os.getenv('SUPABASE_ANON_KEY')
        self.service_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
        
        # Используем service role для полного доступа
        self.api_key = self.service_key if use_service_role else self.anon_key
        self.headers = {
            'apikey': self.api_key,
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
        # Общая aiohttp-сессия (keep-alive, таймауты)
        timeout = aiohttp.ClientTimeout(total=20)
        connector = aiohttp.TCPConnector(limit=50, keepalive_timeout=30)
        self._session = aiohttp.ClientSession(timeout=timeout, connector=connector)
    
    async def _make_request(self, method: str, endpoint: str, data: Dict = None, params: Dict = None) -> Dict:
        """Выполнить HTTP запрос к Supabase (aiohttp)"""
        url = f"{self.base_url}/rest/v1/{endpoint}"
        for attempt in range(2):
            try:
                async with self._session.request(method.upper(), url, headers=self.headers, json=data, params=params) as resp:
                    status = resp.status
                    text = await resp.text()
                    if 200 <= status < 300:
                        if text:
                            try:
                                return json.loads(text)
                            except Exception:
                                return {}
                        return {}
                    else:
                        logger.error(f"Ошибка Supabase API {status} @ {endpoint} - {text}")
                        if attempt == 0 and status >= 500:
                            continue
                        return {'error': text, 'status': status}
            except Exception as e:
                logger.error(f"Ошибка запроса к Supabase: {e}")
                if attempt == 0:
                    continue
                return {'error': str(e)}
        return {'error': 'unknown'}
    
    async def create_user(self, user_data: Dict) -> Dict:
        """Создание пользователя"""
        return await self._make_request('POST', 'users', user_data)
    
    async def get_user(self, telegram_id: int) -> Optional[Dict]:
        """Получение пользователя по telegram_id"""
        result = await self._make_request('GET', f'users?telegram_id=eq.{telegram_id}&select=*')
        if isinstance(result, dict) and result.get('error'):
            return None
        return result[0] if result else None
    
    async def update_user(self, telegram_id: int, user_data: Dict) -> Dict:
        """Обновление пользователя"""
        return await self._make_request('PATCH', f'users?telegram_id=eq.{telegram_id}', user_data)
    
    async def get_user_tickets(self, telegram_id: int) -> int:
        """Получение количества билетов пользователя"""
        user = await self.get_user(telegram_id)
        return user.get('total_tickets', 0) if user else 0
    
    async def add_user_ticket(self, telegram_id: int, count: int = 1) -> Dict:
        """Добавление билета пользователю"""
        user = await self.get_user(telegram_id)
        if user:
            new_total = user.get('total_tickets', 0) + count
            return self._make_request('PATCH', f'users?telegram_id=eq.{telegram_id}', 
                                   {'total_tickets': new_total})
        return {}
    
    async def check_subscription(self, telegram_id: int, channel_id: int) -> bool:
        """Проверка подписки на канал"""
        result = await self._make_request('GET', f'subscriptions?telegram_id=eq.{telegram_id}&channel_id=eq.{channel_id}')
        if isinstance(result, dict) and result.get('error'):
            return False
        return len(result) > 0
    
    async def add_subscription(self, telegram_id: int, channel_data: Dict) -> Dict:
        """Добавление подписки"""
        subscription_data = {
            'telegram_id': telegram_id,
            'channel_id': channel_data['channel_id'],
            'channel_name': channel_data['channel_name'],
            'channel_username': channel_data.get('channel_username', '')
        }
        return await self._make_request('POST', 'subscriptions', subscription_data)
    
    async def get_user_subscriptions(self, telegram_id: int) -> List[Dict]:
        """Получение подписок пользователя"""
        result = await self._make_request('GET', f'subscriptions?telegram_id=eq.{telegram_id}')
        if isinstance(result, dict) and result.get('error'):
            return []
        return result
    
    async def create_referral_code(self, telegram_id: int, referral_code: str) -> Dict:
        """Создание реферального кода"""
        referral_data = {
            'telegram_id': telegram_id,
            'referral_code': referral_code
        }
        return await self._make_request('POST', 'referrals', referral_data)
    
    async def get_referral_by_owner(self, telegram_id: int) -> Optional[Dict]:
        """Получение записи из referrals по владельцу"""
        result = await self._make_request('GET', f'referrals?telegram_id=eq.{telegram_id}')
        if isinstance(result, dict) and result.get('error'):
            return None
        return result[0] if result else None

    async def get_referral_by_code(self, referral_code: str) -> Optional[Dict]:
        """Получение реферала по коду"""
        result = await self._make_request('GET', f'referrals?referral_code=eq.{referral_code}')
        if isinstance(result, dict) and result.get('error'):
            return None
        return result[0] if result else None
    
    async def get_or_create_referral_code_for_owner(self, telegram_id: int) -> Optional[str]:
        """Вернуть код владельца из referrals или создать новый"""
        existing = await self.get_referral_by_owner(telegram_id)
        if existing and existing.get('referral_code'):
            return existing['referral_code']
        import random, string
        code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        resp = await self.create_referral_code(telegram_id, code)
        if isinstance(resp, dict) and resp.get('error'):
            return None
        return code

    async def get_referral_owner_id(self, referral_code: str) -> Optional[int]:
        """Вернуть telegram_id владельца кода.
        Сначала ищем в таблице referrals. Если не найдено — fallback на users.referral_code.
        """
        referral = await self.get_referral_by_code(referral_code)
        if referral and 'telegram_id' in referral:
            try:
                return int(referral['telegram_id'])
            except Exception:
                return None
        # Fallback: поиск владельца по users.referral_code
        try:
            result = await self._make_request('GET', f"users?referral_code=eq.{referral_code}&select=telegram_id")
            if isinstance(result, list) and result:
                owner_row = result[0]
                owner_id_raw = owner_row.get('telegram_id')
                if owner_id_raw is not None:
                    try:
                        return int(owner_id_raw)
                    except Exception:
                        return None
        except Exception:
            pass
        return None

    async def has_referral_join(self, referrer_id: int, referred_id: int) -> bool:
        result = await self._make_request('GET', f'referral_joins?referrer_id=eq.{referrer_id}&referred_id=eq.{referred_id}')
        if isinstance(result, dict) and result.get('error'):
            return False
        return len(result) > 0

    async def record_referral_join(self, referrer_id: int, referred_id: int) -> Dict:
        data = {'referrer_id': referrer_id, 'referred_id': referred_id}
        return await self._make_request('POST', 'referral_joins', data)

    async def increment_referrer_ticket(self, referrer_id: int) -> Dict:
        user = await self.get_user(referrer_id)
        if not user:
            return {}
        current_ref = int(user.get('referral_tickets', 0) or 0)
        if current_ref >= 10:
            return {'message': 'referral cap reached'}
        new_referral_tickets = current_ref + 1
        new_total_tickets = int(user.get('total_tickets', 0) or 0) + 1
        return await self._make_request('PATCH', f'users?telegram_id=eq.{referrer_id}', {
            'referral_tickets': new_referral_tickets,
            'total_tickets': new_total_tickets
        })

    async def add_referral_ticket(self, referral_code: str, referred_id: int) -> Dict:
        """Начисление билета за реферала с защитой от саморефералов и дублей"""
        owner_id = await self.get_referral_owner_id(referral_code)
        if not owner_id:
            return {'error': 'invalid_referral_code'}
        if int(owner_id) == int(referred_id):
            return {'error': 'self_referral'}
        if await self.has_referral_join(owner_id, referred_id):
            return {'message': 'already_counted'}
        # Запишем связь и увеличим билеты
        _ = await self.record_referral_join(owner_id, referred_id)
        return await self.increment_referrer_ticket(owner_id)
    
    async def get_artists(self) -> List[Dict]:
        """Получение всех артистов"""
        result = await self._make_request('GET', 'artists?is_active=eq.true')
        if isinstance(result, dict) and result.get('error'):
            return []
        return result
    
    async def get_artist(self, artist_id: int) -> Optional[Dict]:
        """Получение артиста по ID"""
        result = await self._make_request('GET', f'artists?id=eq.{artist_id}')
        if isinstance(result, dict) and result.get('error'):
            return None
        return result[0] if result else None
    
    async def upload_file(self, file_path: str, storage_path: str, file_name: str) -> Dict:
        """Загрузка файла в Supabase Storage"""
        try:
            url = f"{self.base_url}/storage/v1/object/{storage_path}/{file_name}"
            # aiohttp требует form-data по-другому
            with open(file_path, 'rb') as f:
                data = aiohttp.FormData()
                data.add_field('file', f, filename=file_name, content_type='application/octet-stream')
                async with self._session.post(url, headers={k:v for k,v in self.headers.items() if k != 'Content-Type'}, data=data) as resp:
                    status = resp.status
                    if status == 200:
                        try:
                            return await resp.json()
                        except Exception:
                            return {}
                    else:
                        text = await resp.text()
                        logger.error(f"Ошибка загрузки файла: {status} - {text}")
                        return {'error': text}
        except Exception as e:
            logger.error(f"Ошибка загрузки файла: {e}")
            return {'error': str(e)}
    
    async def get_file_url(self, storage_path: str, file_name: str) -> str:
        """Получение URL файла"""
        return f"{self.base_url}/storage/v1/object/public/{storage_path}/{file_name}"
    
    async def get_total_tickets(self) -> int:
        """Получение общего количества билетов"""
        result = await self._make_request('GET', 'users?select=total_tickets')
        if isinstance(result, dict) and result.get('error'):
            return 0
        total = sum(user.get('total_tickets', 0) for user in result)
        return total
    
    async def get_user_stats(self, telegram_id: int) -> Dict:
        """Получение статистики пользователя"""
        user = await self.get_user(telegram_id)
        if user:
            return {
                'subscription_tickets': user.get('subscription_tickets', 0),
                'referral_tickets': user.get('referral_tickets', 0),
                'total_tickets': user.get('total_tickets', 0),
                'referral_code': user.get('referral_code', '')
            }
        return {
            'subscription_tickets': 0,
            'referral_tickets': 0,
            'total_tickets': 0,
            'referral_code': ''
        }
    
    async def check_subscription_and_award_ticket(self, telegram_id: int, is_subscribed: bool) -> Dict:
        """Проверка подписки и начисление билета"""
        try:
            data = {
                'p_telegram_id': telegram_id,
                'p_is_subscribed': is_subscribed
            }
            url = f"{self.base_url}/rest/v1/rpc/check_subscription_and_award_ticket"
            response = requests.post(url, headers=self.headers, json=data)
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Ошибка вызова функции: {response.status_code} - {response.text}")
                return {
                    'success': False,
                    'message': 'Ошибка проверки подписки',
                    'subscription_tickets': 0,
                    'referral_tickets': 0,
                    'total_tickets': 0,
                    'ticket_awarded': False
                }
        except Exception as e:
            logger.error(f"Ошибка проверки подписки: {e}")
            return {
                'success': False,
                'message': 'Ошибка проверки подписки',
                'subscription_tickets': 0,
                'referral_tickets': 0,
                'total_tickets': 0,
                'ticket_awarded': False
            }
    
    async def get_tickets_stats(self) -> Dict:
        """Получение общей статистики билетов"""
        try:
            url = f"{self.base_url}/rest/v1/rpc/get_tickets_stats"
            response = requests.post(url, headers=self.headers)
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Ошибка получения статистики: {response.status_code} - {response.text}")
                return {
                    'total_subscription_tickets': 0,
                    'total_referral_tickets': 0,
                    'total_user_tickets': 0
                }
        except Exception as e:
            logger.error(f"Ошибка получения статистики: {e}")
            return {
                'total_subscription_tickets': 0,
                'total_referral_tickets': 0,
                'total_user_tickets': 0
            }
    
    async def clear_cache(self):
        """Очистка кэша (для совместимости)"""
        pass
    
    async def get_stats(self) -> Dict:
        """Получение статистики (для совместимости)"""
        return {
            'cache_size': 0,
            'total_requests': 0
        }

# Создаем глобальный экземпляр клиента
supabase_client = SupabaseClient(use_service_role=True) 