# 🚀 GTM Flutter Web - Vercel Deployment

## 📋 Конфигурация

### ✅ Файлы готовы:
- `vercel.json` - конфигурация сборки и роутинга 
- `build.sh` - скрипт сборки Flutter
- `build/web/` - готовые файлы для деплоя

### 🔧 Environment Variables в Vercel:

Добавь эти переменные в **Vercel Dashboard** → **Settings** → **Environment Variables**:

```bash
SUPABASE_URL=https://rxmtovqxjsvogyywyrha.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4bXRvdnF4anN2b2d5eXd5cmhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1Mjg1NTAsImV4cCI6MjA3MDEwNDU1MH0.L-b1QT0sVEDBZfT5ZGVOdUGm0Pax1y94OcKqlEXKEvo
WEBAPP_VERSION=1.0.10
RATING_API_BASE_URL=https://api.gtm.baby
SUPABASE_AI_BUCKET=gtm-ai-uploads
SUPABASE_AI_FOLDER=img
TELEGRAM_BOT_TOKEN=(если нужен)
```

## 🚀 Способы деплоя:

### 1️⃣ Автоматический (через GitHub):
1. Подключи репозиторий к Vercel
2. Vercel автоматически запустит `build.sh`
3. Настрой environment variables
4. Каждый push будет автоматически деплоиться

### 2️⃣ Manual Deploy (ready файлы):
1. Запусти `./build.sh` локально
2. Загрузи содержимое `build/web/` на Vercel
3. Настрой redirects через `vercel.json`

### 3️⃣ Vercel CLI:
```bash
npm i -g vercel
vercel --prod
```

## 🎯 Конфигурация Vercel:

- **Build Command:** `./build.sh`
- **Output Directory:** `build/web`  
- **Install Command:** `echo 'Skipping npm install'`

## ✅ Результат:
- Быстрая загрузка через Vercel Edge Network
- Правильные redirects для SPA
- Оптимизированное кеширование
- Support Telegram WebApp
- Environment variables через --dart-define

## 🔗 URLs:
- **Production:** `https://your-project.vercel.app`
- **Preview:** автоматические preview для каждого PR