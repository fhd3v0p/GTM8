#!/bin/bash

# Скрипт для развертывания Flutter веб-приложения на удаленный сервер

set -e

SERVER="31.56.39.165"
USER="root"
REMOTE_PATH="/root/GTM8/"

echo "🚀 Развертывание Flutter веб-приложения на сервер $SERVER..."

# 1. Создать production билд
echo "📦 Создаю production билд..."
flutter build web --release

# 2. Очистить старые файлы из web_local
echo "🧹 Очищаю старые файлы..."
rm -rf web_local/*

# 3. Скопировать новый билд в web_local
echo "📋 Копирую новый билд в web_local..."
cp -r build/web/* web_local/

echo "🔧 Копирую .env файл для production..."
cp assets/.env web_local/assets/assets/.env

# 4. Отправить на сервер через SCP
echo "🌐 Отправляю web_local на сервер $SERVER..."
scp -r web_local/ $USER@$SERVER:$REMOTE_PATH

# 5. Пересоздать nginx контейнер для подхвата обновлений
echo "🐳 Пересоздаю nginx контейнер для подхвата обновлений..."
ssh $USER@$SERVER "cd $REMOTE_PATH && docker-compose -f docker-compose-fixed.yml stop nginx && docker-compose -f docker-compose-fixed.yml rm -f nginx && docker-compose -f docker-compose-fixed.yml up -d nginx"

echo "✅ Развертывание на сервер завершено успешно!"
echo ""
echo "📊 Размер билда:"
du -sh web_local/
echo ""
echo "🌐 Доступно по адресам:"
echo "   - https://gtm.baby (production)"
echo "   - http://$SERVER (прямой доступ к серверу)"
echo ""
echo "🔧 Для перезапуска nginx на сервере:"
echo "   ssh $USER@$SERVER 'docker restart gtm_nginx'"