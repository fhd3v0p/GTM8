# 🔧 Настройка Environment Variables в Vercel

## Проблема
Приложение загружается с черным экраном из-за отсутствующих environment переменных на Vercel.

## Решение

### 1. Откройте настройки проекта в Vercel
1. Перейдите в [Vercel Dashboard](https://vercel.com/dashboard)
2. Выберите проект `GTM8`
3. Перейдите в `Settings` → `Environment Variables`

### 2. Добавьте следующие переменные

#### Обязательные переменные Supabase:
```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
```

#### Дополнительные переменные:
```
RATING_API_BASE_URL = https://api.gtm.baby
SUPABASE_AI_BUCKET = gtm-ai-uploads  
SUPABASE_AI_FOLDER = img
TELEGRAM_BOT_TOKEN = your-bot-token-here
WEBAPP_VERSION = 1.0.0
```

### 3. Настройки для каждой переменной
- **Environment**: Выберите `Production`, `Preview`, и `Development` для всех переменных
- **Git Branch**: Оставьте пустым (применится ко всем веткам)

### 4. Пример правильно настроенной переменной
```
Name: SUPABASE_URL
Value: https://xyzabc123.supabase.co
Environments: ✅ Production ✅ Preview ✅ Development
Git Branch: (empty)
```

### 5. После добавления переменных
1. Сохраните изменения
2. Перейдите в `Deployments`
3. Нажмите `Redeploy` на последнем деплойменте
4. Или сделайте новый commit для автоматического передеплоя

## Отладка

### Проверка переменных в приложении
1. Откройте https://your-app.vercel.app
2. Нажмите кнопку `ENV Debug` (синяя кнопка внизу слева)
3. Проверьте статус всех переменных:
   - ✅ Зеленая галочка = переменная настроена
   - ❌ Красный крестик = переменная отсутствует

### Проверка в консоли браузера
Откройте Developer Tools (F12) и найдите сообщения:
```
🔍 Environment Variables Status:
  SUPABASE_URL: ✅ found (https://xyzabc123...)
  SUPABASE_ANON_KEY: ✅ found (eyJhbGciOi...)
  RATING_API_BASE_URL: ✅ found (https://api.gtm.baby)
  TELEGRAM_BOT_TOKEN: ✅ found
```

## Важные заметки

1. **Безопасность**: Все переменные, передаваемые через `--dart-define`, будут видны в финальном bundle. Используйте только публичные ключи (anon key, не service key).

2. **Кэширование**: После изменения переменных может потребоваться несколько минут для применения изменений.

3. **Preview deployments**: Переменные должны быть настроены для `Preview` окружения, чтобы работать на ветках и PR.

## Контакты для получения переменных
Обратитесь к администратору проекта для получения актуальных значений:
- SUPABASE_URL
- SUPABASE_ANON_KEY  
- TELEGRAM_BOT_TOKEN