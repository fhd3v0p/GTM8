#!/usr/bin/env python3
"""
GTM Supabase Configuration
Конфигурация для интеграции с Supabase
"""

import os
from dotenv import load_dotenv

# Загружаем переменные окружения
load_dotenv()

# Supabase Configuration
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://your-project.supabase.co')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', 'your-anon-key')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', 'your-service-role-key')

# Supabase Storage Configuration
SUPABASE_STORAGE_BUCKET = os.getenv('SUPABASE_STORAGE_BUCKET', 'gtm-assets')

# Database Tables
SUPABASE_TABLES = {
    'users': 'users',
    'artists': 'artists',
    'subscriptions': 'subscriptions',
    'tickets': 'tickets',
    'referrals': 'referrals',
    'giveaways': 'giveaways'
}

# Storage Paths
SUPABASE_STORAGE_PATHS = {
    'avatars': 'avatars',
    'gallery': 'gallery',
    'artists': 'artists',
    'banners': 'banners'
}

def validate_supabase_config():
    """Проверка конфигурации Supabase"""
    required_vars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"⚠️ Отсутствуют переменные окружения: {missing_vars}")
        return False
    return True

# Экспортируем конфигурацию
__all__ = [
    'SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_ROLE_KEY',
    'SUPABASE_STORAGE_BUCKET', 'SUPABASE_TABLES', 'SUPABASE_STORAGE_PATHS',
    'validate_supabase_config'
] 