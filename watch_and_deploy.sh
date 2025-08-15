#!/bin/bash

# Скрипт для автоматического пересоздания и развертывания при изменениях

set -e

echo "👀 Запуск watch-режима для автоматического развертывания..."
echo "📁 Отслеживаю изменения в lib/, assets/, pubspec.yaml"
echo "🛑 Для остановки нажмите Ctrl+C"
echo ""

# Функция развертывания
deploy() {
    echo "🔄 Обнаружены изменения, пересоздаю билд..."
    ./deploy_web_local.sh
    echo "✅ Развертывание завершено в $(date)"
    echo "---"
}

# Проверяем наличие fswatch
if ! command -v fswatch &> /dev/null; then
    echo "⚠️  fswatch не установлен. Устанавливаю..."
    if command -v brew &> /dev/null; then
        brew install fswatch
    else
        echo "❌ Не удалось установить fswatch. Установите его вручную:"
        echo "   macOS: brew install fswatch"
        echo "   Linux: sudo apt-get install fswatch"
        exit 1
    fi
fi

# Первое развертывание
deploy

# Запуск watch-режима
fswatch -o lib/ assets/ pubspec.yaml | while read change; do
    deploy
done