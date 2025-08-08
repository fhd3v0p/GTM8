FROM python:3.11-slim

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование файлов зависимостей
COPY requirements.txt .

# Установка Python зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY . .

# Создание директории для логов
RUN mkdir -p /app/logs

# Проверка наличия необходимых файлов
RUN ls -la /app/

# Создание пользователя для безопасности
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Проверка конфигурации перед запуском
RUN python -c "from supabase_config import validate_supabase_config; print('✅ Supabase config loaded')"

# Запуск aiogram-бота
CMD ["python", "-u", "bot_main_aiogram.py"] 