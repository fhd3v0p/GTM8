FROM python:3.11-slim

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование файлов зависимостей
COPY requirements.txt .

# Установка Python зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY . .

# Логи выводим в stdout/stderr (без записи в файлы внутри контейнера)
ENV GUNICORN_ACCESSLOG=- \
    GUNICORN_ERRORLOG=-

# Создание пользователя для безопасности
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Открытие порта
EXPOSE 5000

# Запуск приложения (хост/порт берём из переменных окружения API_HOST/API_PORT)
CMD ["/bin/sh", "-c", "gunicorn --bind ${API_HOST:-0.0.0.0}:${API_PORT:-5000} --workers 4 --timeout 120 --access-logfile ${GUNICORN_ACCESSLOG} --error-logfile ${GUNICORN_ERRORLOG} rating_api:app"]