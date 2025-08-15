# 🚀 Развертывание Flutter веб-приложения GTM

## 📋 Обзор

Этот проект настроен для развертывания Flutter веб-приложения на локальном сервере через Docker nginx.

## 🗂️ Структура проекта

```
GTM8/
├── lib/                    # Исходный код Flutter
├── assets/                 # Ресурсы приложения
├── web/                    # Папка для разработки (flutter run)
├── build/web/              # Production билд (flutter build web)
├── web_local/              # Статика для nginx сервера ⭐
├── nginx.conf              # Конфигурация nginx
├── docker-compose-fixed.yml # Docker конфигурация
└── deploy_web_local.sh     # Скрипт развертывания ⭐
```

## 🔄 Как работает развертывание

### 1. 🏗️ Создание production билда
```bash
flutter build web --release
```
- Создает оптимизированный билд в `build/web/`
- Минифицирует JavaScript и CSS
- Оптимизирует шрифты и изображения

### 2. 📦 Копирование в web_local
```bash
cp -r build/web/* web_local/
```
- Копирует готовый билд в папку `web_local/`
- Эта папка монтируется в nginx контейнер

### 3. 🐳 Обслуживание через nginx
```yaml
volumes:
  - ./web_local:/usr/share/nginx/html:ro
```
- nginx обслуживает статику из `web_local/`
- Доступно по https://gtm.baby и http://localhost

## 🛠️ Команды развертывания

### Локальное развертывание
```bash
./deploy_web_local.sh
```

### Развертывание на удаленный сервер
```bash
./deploy_to_server.sh
```

### Watch-режим (автоматическое пересоздание)
```bash
./watch_and_deploy.sh
```

### Ручное развертывание
```bash
# 1. Создать билд
flutter build web --release

# 2. Скопировать в web_local
rm -rf web_local/*
cp -r build/web/* web_local/

# 3. Перезапустить nginx (если нужно)
docker restart gtm_nginx
```

## 🔧 Режимы разработки

### 🚀 Production режим
```bash
./deploy_web_local.sh
```
- **Доступ**: https://gtm.baby (через nginx)
- **Особенности**: Оптимизированный код, кэширование
- **Использование**: Тестирование перед продакшеном

### 💻 Development режим  
```bash
flutter run -d chrome --web-port=8087
```
- **Доступ**: http://localhost:8087
- **Особенности**: Hot reload, debug информация
- **Использование**: Активная разработка

## 🐳 Docker команды

### Запуск всех сервисов
```bash
docker-compose -f docker-compose-fixed.yml up -d
```

### Перезапуск только nginx
```bash
docker restart gtm_nginx
```

### Просмотр логов nginx
```bash
docker logs gtm_nginx
```

### Остановка всех сервисов
```bash
docker-compose -f docker-compose-fixed.yml down
```

## 🌐 URL-адреса

| Режим | URL | Описание |
|-------|-----|----------|
| Production | https://gtm.baby | Основной сайт через nginx |
| Remote Server | http://31.56.39.165 | Удаленный сервер |
| Local Docker | http://localhost | Локальный nginx |
| Development | http://localhost:8087 | Flutter dev server |
| API | https://api.gtm.baby | API сервер |

## 🔍 Отладка

### Проверка статуса контейнеров
```bash
docker ps
```

### Проверка содержимого web_local
```bash
ls -la web_local/
```

### Размер билда
```bash
du -sh web_local/
```

### Просмотр логов nginx
```bash
docker logs gtm_nginx -f
```

## ⚡ Быстрые команды

```bash
# Локальное развертывание
./deploy_web_local.sh

# Развертывание на удаленный сервер
./deploy_to_server.sh

# Запуск Docker
docker-compose -f docker-compose-fixed.yml up -d

# Разработка с hot reload
flutter run -d chrome --web-port=8087

# Watch-режим
./watch_and_deploy.sh

# Ручная отправка на сервер
scp -r web_local/ root@31.56.39.165:/root/gtm8/
```

## 🚨 Важные заметки

1. **Папка web_local** - это то, что видят пользователи на сервере
2. **Папка web** - используется только для разработки
3. **После изменений кода** нужно запустить `./deploy_web_local.sh`
4. **Для hot reload** используйте `flutter run -d chrome --web-port=8087`
5. **Docker должен быть запущен** для работы production режима