# GTM Flutter App - Railway Deployment

## Описание
Flutter Web приложение GTM (Gotham's Top Model) готово для деплоя на Railway.

## Структура проекта для Railway

### Конфигурационные файлы:
- `Dockerfile` - мультистадийная сборка Flutter Web + Nginx
- `railway.toml` - конфигурация Railway для автоматического деплоя  
- `nginx-railway.conf` - настройки Nginx для Railway (порт 8080)
- `.gitignore` - обновленный для Railway деплоя

### Особенности конфигурации:

**Dockerfile:**
- Использует `ghcr.io/cirruslabs/flutter:stable` для сборки
- Собирает Flutter Web приложение  
- Использует Nginx Alpine для production
- Копирует собранные файлы в `/usr/share/nginx/html`

**Railway.toml:**
- Настроен для Dockerfile-based сборки
- Автоматический рестарт при ошибках
- Переменные окружения для Flutter Web

**Nginx конфигурация:**
- Слушает порт 8080 (требование Railway)
- Настроены security headers
- Gzip сжатие
- Специальные правила кэширования для Flutter Web
- Health check endpoint `/health`

## Деплой на Railway

1. **Подключите репозиторий GTM9 к Railway**
2. **Railway автоматически:**
   - Определит Flutter как язык
   - Использует Dockerfile для сборки
   - Применит настройки из railway.toml
   - Развернет на порту 8080

3. **Переменные окружения (если нужны):**
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_key
   ```

## Локальная проверка Docker билда

```bash
# Собрать образ
docker build -t gtm-railway .

# Запустить локально на порту 8080
docker run -p 8080:8080 gtm-railway

# Проверить health check
curl http://localhost:8080/health
```

## Telegram WebApp интеграция

Приложение оптимизировано для работы в Telegram WebApp:
- Подключен Telegram Web App SDK
- Настроены anti-cache заголовки
- Отключен вертикальный скролл
- Полноэкранный режим

## Мониторинг

Railway предоставляет:
- Логи в реальном времени
- Метрики использования ресурсов
- Автоматические рестарты при сбоях

## Ссылки

- GitHub репозиторий: [https://github.com/fhd3v0p/GTM9](https://github.com/fhd3v0p/GTM9)
- Railway проект: [Настройте в Railway Dashboard]