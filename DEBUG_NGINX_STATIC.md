# 🔧 Диагностика проблем со статикой nginx

## 🎯 Проблема: nginx не подхватывает обновления статики

### ❌ Симптомы:
- Локально приложение работает корректно
- На сервере отсутствуют обновления (например, кнопки казино)
- Файлы отправились на сервер, но не отображаются

### 🔍 Диагностика:

#### 1. Проверить время файлов на сервере:
```bash
ssh root@31.56.39.165 'ls -la /root/GTM8/web_local/main.dart.js'
ssh root@31.56.39.165 'docker exec gtm_nginx ls -la /usr/share/nginx/html/main.dart.js'
```

#### 2. Сравнить содержимое:
```bash
ssh root@31.56.39.165 'docker exec gtm_nginx grep "FORCE_" /usr/share/nginx/html/index.html'
```

### ⚡ Быстрое решение:

#### Пересоздать nginx контейнер:
```bash
ssh root@31.56.39.165 'cd /root/GTM8 && docker-compose -f docker-compose-fixed.yml stop nginx && docker-compose -f docker-compose-fixed.yml rm -f nginx && docker-compose -f docker-compose-fixed.yml up -d nginx'
```

### 🔧 Причина проблемы:

**Docker bind mount** создает снимок папки на момент создания контейнера. Если файлы обновляются после создания контейнера, то изменения могут не синхронизироваться автоматически.

### ✅ Автоматическое решение:

Обновленный скрипт `deploy_to_server.sh` теперь автоматически пересоздает nginx контейнер при каждом развертывании.

### 📋 Проверочный чек-лист:

1. **Файлы отправлены** ✅
   ```bash
   ssh root@31.56.39.165 'ls -la /root/GTM8/web_local/main.dart.js'
   ```

2. **nginx подхватил файлы** ✅
   ```bash
   ssh root@31.56.39.165 'docker exec gtm_nginx ls -la /usr/share/nginx/html/main.dart.js'
   ```

3. **Время файлов совпадает** ✅
   - Время файла в `/root/GTM8/web_local/` должно совпадать с временем в `/usr/share/nginx/html/`

4. **Кэш-бастинг работает** ✅
   ```bash
   ssh root@31.56.39.165 'docker exec gtm_nginx grep "FORCE_" /usr/share/nginx/html/index.html'
   ```

### 🌐 Тестирование:

1. Откройте https://gtm.baby или http://31.56.39.165
2. Принудительно обновите страницу: **Ctrl+F5** (Windows) или **Cmd+Shift+R** (Mac)
3. Проверьте консоль браузера (F12) на наличие ошибок
4. Убедитесь, что функциональность работает корректно

### 🚨 В экстренных случаях:

Если ничего не помогает:
```bash
# Полная перезагрузка всей системы
ssh root@31.56.39.165 'cd /root/GTM8 && docker-compose -f docker-compose-fixed.yml down && docker-compose -f docker-compose-fixed.yml up -d'
```