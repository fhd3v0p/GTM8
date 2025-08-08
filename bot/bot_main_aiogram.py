#!/usr/bin/env python3
"""
aiogram GTM Telegram Bot с Supabase интеграцией (без Router, регистрация напрямую на Dispatcher)
"""
import os
import asyncio
import logging
import random
import string
from datetime import datetime
from typing import List

from dotenv import load_dotenv
from aiogram import Bot, Dispatcher, F
from aiogram.types import (
    Message,
    InlineKeyboardMarkup,
    InlineKeyboardButton,
    WebAppInfo
)
from aiogram.filters import Command
from aiogram.utils.keyboard import InlineKeyboardBuilder
from aiogram.client.session.aiohttp import AiohttpSession
from aiohttp import ClientTimeout

from supabase_client import supabase_client
from supabase_config import validate_supabase_config

load_dotenv()

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO,
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', '')
TELEGRAM_FOLDER_LINK = os.getenv('TELEGRAM_FOLDER_LINK', 'https://t.me/addlist/6HRxDLe0Gdk2M2E1')
WEBAPP_URL = os.getenv('WEBAPP_URL', 'https://gtm.baby')
WEBAPP_VERSION = os.getenv('WEBAPP_VERSION', '')
ADMIN_ID = int(os.getenv('ADMIN_ID', '6358105675'))
LOG_CHAT_ID = int(os.getenv('TELEGRAM_LOG_CHAT_ID', '0'))

# 9 каналов
SUBSCRIPTION_CHANNELS: List[dict] = [
    {'channel_id': -1002088959587, 'channel_username': 'rejmenyavseryoz', 'channel_name': 'Режь меня всерьёз'},
    {'channel_id': -1001971855072, 'channel_username': 'chchndra_tattoo', 'channel_name': 'Чучундра'},
    {'channel_id': -1002133674248, 'channel_username': 'naidenka_tattoo', 'channel_name': 'naidenka_tattoo'},
    {'channel_id': -1001508215942, 'channel_username': 'l1n_ttt', 'channel_name': 'Lin++'},
    {'channel_id': -1001555462429, 'channel_username': 'murderd0lll', 'channel_name': 'MurderdOll'},
    {'channel_id': -1002132954014, 'channel_username': 'poteryashkatattoo', 'channel_name': 'Потеряшка'},
    {'channel_id': -1001689395571, 'channel_username': 'EMI3MO', 'channel_name': 'EMI'},
    {'channel_id': -1001767997947, 'channel_username': 'bloodivamp', 'channel_name': 'bloodivamp'},
    {'channel_id': -1001973736826, 'channel_username': 'G_T_MODEL', 'channel_name': 'Gothams top model'},
]

if not validate_supabase_config():
    logger.error("❌ Неверная конфигурация Supabase")

# Используем дефолтную HTTP-сессию aiogram (избегаем несовместимости таймаутов)
bot = Bot(token=TELEGRAM_BOT_TOKEN)


def get_webapp_keyboard() -> InlineKeyboardMarkup:
    kb = InlineKeyboardBuilder()
    # Принудительное обновление кеша у веб-аппа: добавляем параметр версии
    versioned_url = WEBAPP_URL if not WEBAPP_VERSION else f"{WEBAPP_URL}?v={WEBAPP_VERSION}"
    kb.row(
        InlineKeyboardButton(text="🔮 Open GTM", web_app=WebAppInfo(url=versioned_url)),
        InlineKeyboardButton(text="💭 CHAT", url="https://t.me/G_T_MODEL/10"),
    )
    return kb.as_markup()


async def get_or_create_referral_code(telegram_id: int) -> str:
    # Сохраняем код в таблице referrals (и дублируем в users для обратной совместимости)
    code = await supabase_client.get_or_create_referral_code_for_owner(telegram_id)
    if code:
        await supabase_client.update_user(telegram_id, {'referral_code': code})
        return code
    # fallback на users, если не удалось
    user = await supabase_client.get_user(telegram_id)
    if user and user.get('referral_code'):
        return user['referral_code']
    code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    await supabase_client.update_user(telegram_id, {'referral_code': code})
    return code


async def log_to_admin(text: str):
    try:
        if LOG_CHAT_ID:
            await bot.send_message(chat_id=LOG_CHAT_ID, text=text)
    except Exception as e:
        logger.warning(f"Не удалось отправить лог в админ-чат: {e}")


async def cmd_start(message: Message):
    user = message.from_user
    # Создаём/обновляем пользователя в БД (до реф-логики)
    await save_user(user.id, user.username, user.first_name, user.last_name)
    # Генерируем собственный код в referrals, если ещё нет
    _ = await get_or_create_referral_code(user.id)
    # обработка реф-кода из /start <code>
    args = message.text.split()
    if len(args) > 1:
        referral_code = args[1]
        # Начисляем билет пригласителю, если не самореферал и не дубль
        try:
            await supabase_client.add_referral_ticket(referral_code, referred_id=user.id)
        except Exception as e:
            logger.error(f"Ошибка начисления реф-билета: {e}")
    welcome_message = (
        f"☠️ Привет, {user.first_name}! ☠️\n\n"
        "👄 Добро пожаловать во Gotham's Top Model — платформу для поиска и бронирования лучших артистов в твоем городе!\n\n"
        "Что у нас есть:\n"
        "🤖 AI-поиск услуг по референсам\n"
        "🃏 Каталог топовых артистов\n"
        "🎰 Розыгрыш призов на >130,000₽\n"
        "🎱 Скидка 8% на услуги всех резидентов GTM\n"
        "💞 Реферальная система\n\n"
        "Нажми «🔮 Open GTM», чтобы ворваться!"
    )
    await message.answer(welcome_message, reply_markup=get_webapp_keyboard())
    # Лог в админ-чат о старте пользователя
    try:
        await log_to_admin(f"/start from {user.id} @{user.username or ''}")
    except Exception:
        pass
    # пользователь уже сохранён выше


async def save_user(user_id: int, username: str, first_name: str, last_name: str):
    user_data = {
        'telegram_id': user_id,
        'username': username,
        'first_name': first_name,
        'last_name': last_name,
        'subscription_tickets': 0,
        'referral_tickets': 0,
        'total_tickets': 0
    }
    existing_user = await supabase_client.get_user(user_id)
    if existing_user:
        await supabase_client.update_user(user_id, user_data)
    else:
        await supabase_client.create_user(user_data)


async def cmd_check(message: Message):
    user = message.from_user
    await message.answer("🔍 Проверяю подписки на каналы...")

    subscribed = []
    not_subscribed = []
    for ch in SUBSCRIPTION_CHANNELS:
        try:
            member = await bot.get_chat_member(chat_id=ch['channel_id'], user_id=user.id)
            if member.status in ('member', 'administrator', 'creator'):
                subscribed.append(ch)
            else:
                not_subscribed.append(ch)
        except Exception as e:
            logger.error(f"Ошибка проверки канала {ch['channel_name']}: {e}")
            not_subscribed.append(ch)

    is_all = len(subscribed) == 9
    result = await supabase_client.check_subscription_and_award_ticket(user.id, is_all)

    lines = ["📊 Результаты проверки подписок:\n"]
    if subscribed:
        lines.append("✅ Подписан на:")
        lines += [f"• {c['channel_name']}" for c in subscribed]
        lines.append("")
    if not_subscribed:
        lines.append("❌ Не подписан на:")
        lines += [f"• {c['channel_name']}" for c in not_subscribed]
        lines.append("")

    if result.get('ticket_awarded', False):
        lines.append("🎫 Билет начислен за подписку на папку!")
    else:
        if not is_all:
            lines.append(f"⚠️ Для получения билета нужно подписаться на все {len(SUBSCRIPTION_CHANNELS)} каналов")
            lines.append(f"📁 Подпишитесь на папку GTM: {TELEGRAM_FOLDER_LINK}")
            lines.append("🔒 Не отписывайтесь до конца розыгрыша!")
        else:
            lines.append("✅ Билет за подписки уже начислен")

    total_user = result.get('total_tickets', 0)
    total_all = await supabase_client.get_total_tickets()
    lines.append(f"\n🎫 Ваши билеты: {total_user}/{total_all}")

    await message.answer("\n".join(lines))


async def cmd_tickets(message: Message):
    user = message.from_user
    stats = await supabase_client.get_user_stats(user.id)
    text = (
        f"🎫 Билеты пользователя {user.first_name}\n\n"
        f"📊 Детализация билетов:\n"
        f"• За подписку на папку: {stats.get('subscription_tickets', 0)}/1\n"
        f"• За приглашенных друзей: {stats.get('referral_tickets', 0)}/10\n"
        f"• Всего билетов: {stats.get('total_tickets', 0)}\n\n"
        "🎁 Участвуйте в розыгрыше GTM!"
    )
    await message.answer(text)


async def cmd_folder(message: Message):
    text = (
        "📁 Telegram папка GTM\n\n"
        f"🔗 Ссылка на папку: {TELEGRAM_FOLDER_LINK}\n\n"
        "📋 В папке собраны все каналы GTM:\n"
        "• Режь меня всерьёз\n"
        "• Чучундра\n"
        "• naidenka_tattoo\n"
        "• Lin++\n"
        "• MurderdOll\n"
        "• Потеряшка\n"
        "• EMI\n"
        "• bloodivamp\n"
        "• Gothams top model\n\n"
        "🎫 Подпишитесь на папку для получения билетов!"
    )
    await message.answer(text)


async def cmd_invite(message: Message):
    user = message.from_user
    code = await get_or_create_referral_code(user.id)
    text = (
        "🎰 <b>Приглашение в GTM</b>\n\n"
        f"👋 Привет! {user.first_name} приглашает тебя в Gotham's Top Model!\n\n"
        "🎁 Что ты получишь:\n"
        "• 🃏 Каталог топовых артистов\n"
        "• 🤖 AI-поиск услуг\n"
        "• 🎰 Розыгрыш призов на >130,000₽\n"
        "• 🎱 Скидка 8% на услуги\n"
        "• 💞 Реферальная система\n\n"
        f"🎫 За регистрацию по ссылке {user.first_name} получит +1 билет!\n\n"
        f"🔗 <a href=\"https://t.me/GTM_ROBOT?start={code}\">Присоединиться к GTM</a>"
    )
    kb = InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text="🎰 Присоединиться к GTM", url=f"https://t.me/GTM_ROBOT?start={code}")]])
    await message.answer(text, reply_markup=kb, parse_mode="HTML")


async def cmd_help(message: Message):
    text = (
        "🤖 GTM Bot - Помощь\n\n"
        "📋 Команды:\n"
        "/start - Начать работу с ботом\n"
        "/check - Проверить подписки на каналы\n"
        "/tickets - Показать количество билетов\n"
        "/folder - Ссылка на папку GTM\n"
        "/invite - Пригласить друзей\n"
        "/help - Показать эту справку\n\n"
        "🎫 Как получить билеты:\n"
        "• Подпишитесь на все 9 каналов GTM (+1 билет)\n"
        "• За каждого друга по реферальной ссылке (+1 билет, максимум 10)\n\n"
        "🎁 Розыгрыш GTM - главный приз 20000₽!"
    )
    await message.answer(text)


async def cmd_stats(message: Message):
    if message.from_user.id != ADMIN_ID:
        await message.answer("❌ У вас нет доступа к этой команде")
        return
    stats = await supabase_client.get_tickets_stats()
    text = (
        "🎰 <b>СТАТИСТИКА GTM БОТА (Supabase)</b>\n\n"
        f"🎫 Общая статистика билетов:\n"
        f"• За подписки на папку: {stats.get('total_subscription_tickets', 0)}\n"
        f"• За рефералов: {stats.get('total_referral_tickets', 0)}\n"
        f"• Всего билетов: {stats.get('total_user_tickets', 0)}\n\n"
        f"📅 Обновлено: {datetime.now().strftime('%d.%m.%Y %H:%M')}"
    )
    await message.answer(text, parse_mode="HTML")


async def cmd_start_text(message: Message):
    """Обработчик текста "start" без слеша (/)."""
    await cmd_start(message)


async def handle_any_message(message: Message):
    """Фолбэк: подтверждаем, что апдейты доходят, подсказываем про /start."""
    logger.info(f"Update received: chat={message.chat.id} text={message.text!r}")
    await message.answer("🔹 Напишите /start, чтобы начать работу с ботом")

def register_handlers(dp: Dispatcher):
    dp.message.register(cmd_start, Command("start"))
    dp.message.register(cmd_start_text, F.text.casefold() == "start")
    dp.message.register(cmd_check, Command("check"))
    dp.message.register(cmd_tickets, Command("tickets"))
    dp.message.register(cmd_folder, Command("folder"))
    dp.message.register(cmd_invite, Command("invite"))
    dp.message.register(cmd_help, Command("help"))
    dp.message.register(cmd_stats, Command("stats"))
    dp.message.register(cmd_invite, F.text == "🃏 Пригласить друзей")
    dp.message.register(handle_any_message)


async def main():
    if not TELEGRAM_BOT_TOKEN:
        raise RuntimeError("TELEGRAM_BOT_TOKEN not set")
    dp = Dispatcher()
    register_handlers(dp)
    logger.info("🚀 Запуск GTM Supabase aiogram Bot...")
    # На всякий случай удаляем вебхук, чтобы гарантировать polling
    try:
        await bot.delete_webhook(drop_pending_updates=True)
    except Exception as e:
        logger.warning(f"Не удалось удалить webhook перед polling: {e}")
    # Информируем админ-чат о запуске бота
    try:
        await log_to_admin("🚀 Бот запущен и перешёл на polling")
    except Exception:
        pass
    # Устанавливаем команды бота (не критично, но полезно)
    try:
        from aiogram.types import BotCommand
        await bot.set_my_commands([
            BotCommand(command="start", description="Запуск GTM"),
            BotCommand(command="check", description="Проверить подписки"),
            BotCommand(command="tickets", description="Мои билеты"),
            BotCommand(command="invite", description="Пригласить друзей"),
            BotCommand(command="help", description="Помощь"),
        ])
    except Exception as e:
        logger.warning(f"Не удалось установить команды бота: {e}")
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())