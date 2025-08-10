import os
import json
from typing import List, Dict

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", os.getenv("SUPABASE_SERVICE_KEY", ""))

# Channels can be overridden via SUBSCRIPTION_CHANNELS_JSON env var
_DEFAULT_CHANNELS = [
    { 'channel_id': -1002088959587, 'channel_username': 'rejmenyavseryoz', 'channel_name': 'Режь меня всерьёз' },
    { 'channel_id': -1001971855072, 'channel_username': 'chchndra_tattoo', 'channel_name': 'Чучундра' },
    { 'channel_id': -1002133674248, 'channel_username': 'naidenka_tattoo', 'channel_name': 'naidenka_tattoo' },
    { 'channel_id': -1001508215942, 'channel_username': 'l1n_ttt', 'channel_name': 'Lin++' },
    { 'channel_id': -1001555462429, 'channel_username': 'murderd0lll', 'channel_name': 'MurderdOll' },
    { 'channel_id': -1002132954014, 'channel_username': 'poteryashkatattoo', 'channel_name': 'Потеряшка' },
    { 'channel_id': -1001689395571, 'channel_username': 'EMI3MO', 'channel_name': 'EMI' },
    { 'channel_id': -1001767997947, 'channel_username': 'bloodivamp', 'channel_name': 'bloodivamp' },
    { 'channel_id': -1001973736826, 'channel_username': 'G_T_MODEL', 'channel_name': 'Gothams top model' },
]

def get_subscription_channels() -> List[Dict]:
    raw = os.getenv("SUBSCRIPTION_CHANNELS_JSON")
    if not raw:
        return _DEFAULT_CHANNELS
    try:
        data = json.loads(raw)
        if isinstance(data, list) and data:
            return data
    except Exception:
        pass
    return _DEFAULT_CHANNELS

supabase_headers = {
    'apikey': SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY,
    'Authorization': f"Bearer {SUPABASE_SERVICE_ROLE_KEY or SUPABASE_ANON_KEY}",
    'Content-Type': 'application/json'
}