#!/bin/bash

# Скрипт для развертывания Flutter веб-приложения в web_local

set -e  # Остановить при ошибке

echo "🚀 Начинаю развертывание Flutter веб-приложения..."

# 1. Создать production билд
echo "📦 Создаю production билд..."
flutter build web --release

# 2. Очистить старые файлы из web_local
echo "🧹 Очищаю старые файлы..."
rm -rf web_local/*

# 3. Скопировать новый билд
echo "📋 Копирую новый билд в web_local..."
cp -r build/web/* web_local/

echo "🔧 Копирую .env файл для production..."
cp assets/.env web_local/assets/assets/.env

# 4. Проверить, запущен ли Docker
echo "🐳 Проверяю состояние Docker контейнеров..."
if docker ps | grep -q "gtm_nginx"; then
    echo "✅ Nginx контейнер работает"
    
    # 5. Перезапустить nginx для подхвата изменений (опционально)
    echo "🔄 Перезапускаю nginx для подхвата изменений..."
    docker restart gtm_nginx
    
    echo "✅ Развертывание завершено успешно!"
    echo "🌐 Приложение доступно по адресам:"
    echo "   - https://gtm.baby (production)"
    echo "   - http://localhost (локальный Docker)"
else
    echo "⚠️  Nginx контейнер не запущен"
    echo "🚀 Запустить Docker: docker-compose -f docker-compose-fixed.yml up -d"
fi

echo ""
echo "📊 Размер билда:"
du -sh web_local/
echo ""
echo "🎯 Для локальной разработки используйте:"
echo "   flutter run -d chrome --web-port=8087"