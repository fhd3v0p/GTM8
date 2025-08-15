#!/bin/bash

# Скрипт для тестирования казино в разных режимах

echo "🎰 Тестирование отображения Casino screen в разных режимах..."
echo ""

echo "📋 1. Проверяем DEBUG режим (flutter run):"
echo "   - Запустите: flutter run -d chrome --web-port=8087"
echo "   - Ожидаем в консоли: 'Casino screen type: GiveawayCasinoScreen'"
echo ""

echo "📦 2. Проверяем PRODUCTION режим (flutter build web):"
echo "   - Запустите: ./deploy_web_local.sh"
echo "   - Затем откройте web_local/index.html в браузере"
echo "   - В консоли браузера (F12) должно быть: 'Casino screen type: GiveawayCasinoScreen'"
echo ""

echo "🌐 3. Проверяем на сервере:"
echo "   - Запустите: ./deploy_to_server.sh"
echo "   - Откройте: https://gtm.baby или http://31.56.39.165"
echo "   - В консоли браузера (F12) должно быть: 'Casino screen type: GiveawayCasinoScreen'"
echo ""

echo "🔍 Для отладки:"
echo "   - Откройте консоль браузера (F12)"
echo "   - Во вкладке Console ищите сообщение о casino screen"
echo "   - Если сообщения нет - проверьте .env файлы"
echo ""

echo "📁 Файлы для проверки:"
echo "   - lib/main.dart (строки 22-27) - код инициализации казино"
echo "   - assets/.env - конфигурация для Flutter"
echo "   - .env - основная конфигурация"
echo ""

echo "🚨 Основные различия режимов:"
echo "   DEBUG (flutter run):    kDebugMode = true"
echo "   PRODUCTION (build web): kDebugMode = false"
echo "   Оба режима теперь должны показывать casino screen!"