import 'dart:html' as html;
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:telegram_web_app/telegram_web_app.dart';

class TelegramWebAppService {
  // Определяем, что приложение запущено в Telegram WebApp
  static bool get isTelegramWebApp {
    try {
      return js.context.hasProperty('Telegram') &&
          js.context['Telegram'].hasProperty('WebApp');
    } catch (_) {
      return false;
    }
  }
  static void initializeWebApp() {
    if (kIsWeb) {
      try {
        expand();
        ready();
        disableVerticalSwipe();
      } catch (_) {}
    }
  }

  static void disableVerticalSwipe() {
    if (!kIsWeb) return;
    try {
      // Блокируем вертикальный скролл и pull-to-refresh (CSS)
      html.document.documentElement?.style.overflow = 'hidden';
      html.document.body?.style.overflow = 'hidden';
      html.document.documentElement?.style.setProperty('overscroll-behavior-y', 'contain');
      html.document.body?.style.setProperty('overscroll-behavior-y', 'contain');
      // Разрешаем жесты по оси X и Y (Telegram сам перехватывает закрытие)
      html.document.documentElement?.style.setProperty('touch-action', 'pan-x pan-y');
      html.document.body?.style.setProperty('touch-action', 'pan-x pan-y');

      // Пытаемся отправить событие Telegram WebApp для отключения свайпа вниз
      try {
        final data = js.JsObject.jsify({
          'eventType': 'web_app_setup_swipe_behavior',
          'eventData': {'allow_vertical_swipe': false},
        });
        html.window.parent?.postMessage(data, 'https://web.telegram.org');
      } catch (_) {
        // Fallback через TelegramWebviewProxy
        try {
          final params = js.JsObject.jsify({'allow_vertical_swipe': false});
          if (js.context.hasProperty('TelegramWebviewProxy')) {
            js.context['TelegramWebviewProxy'].callMethod('postEvent', [
              'web_app_setup_swipe_behavior',
              js.context['JSON'].callMethod('stringify', [params])
            ]);
          }
        } catch (_) {}
      }

      // Останавливаем всплытие touchmove (на всякий случай)
      html.document.addEventListener('touchmove', (e) {
        e.stopPropagation();
      }, true);
    } catch (_) {}
  }

  static void enableVerticalSwipe() {
    if (!kIsWeb) return;
    try {
      html.document.documentElement?.style.overflow = 'auto';
      html.document.body?.style.overflow = 'auto';
    } catch (_) {}
  }

  static String? getUserId() {
    try {
      final t = TelegramWebApp.instance;
      if (t.isSupported && t.initDataUnsafe?.user?.id != null) {
        return t.initDataUnsafe!.user!.id.toString();
      }
    } catch (_) {}
    final data = getUserData();
    return data?['id']?.toString();
  }

  static String? getUsername() {
    if (!kIsWeb) return null;
    try {
      final tg = js.context['Telegram'];
      final username = tg?['WebApp']?['initDataUnsafe']?['user']?['username'];
      if (username != null) return username.toString();
    } catch (_) {}
    return null;
  }

  static String? getFirstName() {
    if (!kIsWeb) return null;
    try {
      final tg = js.context['Telegram'];
      final firstName = tg?['WebApp']?['initDataUnsafe']?['user']?['first_name'];
      if (firstName != null) return firstName.toString();
    } catch (_) {}
    return null;
  }

  static String? getLastName() {
    if (!kIsWeb) return null;
    try {
      final tg = js.context['Telegram'];
      final lastName = tg?['WebApp']?['initDataUnsafe']?['user']?['last_name'];
      if (lastName != null) return lastName.toString();
    } catch (_) {}
    return null;
  }

  static void showAlert(String message) {
    if (kIsWeb) {
      try {
        final tg = js.context['Telegram'];
        if (tg != null) {
          final webApp = tg['WebApp'];
          if (webApp != null && webApp['showAlert'] != null) {
            webApp.callMethod('showAlert', [message]);
            return;
          }
        }
      } catch (_) {}
    }
    html.window.alert(message);
  }

  static void close() {
    if (!kIsWeb) return;
    try {
      final tg = js.context['Telegram'];
      tg?['WebApp']?.callMethod('close');
    } catch (_) {}
  }

  static void expand() {
    if (!kIsWeb) return;
    try {
      final tg = js.context['Telegram'];
      tg?['WebApp']?.callMethod('expand');
    } catch (_) {}
  }

  static void ready() {
    if (!kIsWeb) return;
    try {
      final tg = js.context['Telegram'];
      tg?['WebApp']?.callMethod('ready');
    } catch (_) {}
  }

  static Future<bool> inviteFriendsWithShare() async { return true; }

  // Получаем данные пользователя из Telegram WebApp
  static Map<String, dynamic>? getUserData() {
    if (!isTelegramWebApp) return null;
    try {
      final webApp = js.context['Telegram']['WebApp'];
      final user = webApp['initDataUnsafe']['user'];

      // Отладка
      // ignore: avoid_print
      print('🔍 Telegram WebApp Debug:');
      // ignore: avoid_print
      print('  WebApp available: ${webApp != null}');
      // ignore: avoid_print
      print('  initDataUnsafe: ${webApp['initDataUnsafe']}');
      // ignore: avoid_print
      print('  User data: $user');

      if (user != null) {
        final map = {
          'id': user['id'],
          'first_name': user['first_name'],
          'last_name': user['last_name'],
          'username': user['username'],
          'language_code': user['language_code'],
        };
        // ignore: avoid_print
        print('  Parsed user data: $map');
        return map;
      }

      // ignore: avoid_print
      print('  ❌ User data is null');
      // Fallback: пробуем разобрать tgWebAppData из URL
      try {
        final parsed = _parseTgWebAppDataFromUrl();
        if (parsed != null && parsed.containsKey('user')) {
          final userJson = parsed['user'];
          final decoded = (userJson is String) ? jsonDecode(userJson) : userJson;
          if (decoded is Map) {
            final map = {
              'id': decoded['id'],
              'first_name': decoded['first_name'],
              'last_name': decoded['last_name'],
              'username': decoded['username'],
              'language_code': decoded['language_code'],
            };
            // ignore: avoid_print
            print('  ✅ Fallback from tgWebAppData: $map');
            return map;
          }
        }
      } catch (e2) {
        // ignore: avoid_print
        print('  Fallback parse tgWebAppData error: $e2');
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting user data: $e');
      return null;
    }
  }

  // Парсим tgWebAppData из query или hash
  static Map<String, dynamic>? _parseTgWebAppDataFromUrl() {
    try {
      // 1) query
      String? raw = Uri.base.queryParameters['tgWebAppData'];
      // 2) иногда кладут в hash (#tgWebAppData=...)
      if (raw == null || raw.isEmpty) {
        final frag = Uri.base.fragment; // без leading '#'
        if (frag.contains('tgWebAppData=')) {
          final idx = frag.indexOf('tgWebAppData=');
          if (idx >= 0) {
            raw = frag.substring(idx + 'tgWebAppData='.length);
          }
        }
      }
      if (raw == null || raw.isEmpty) return null;
      final decoded = Uri.decodeFull(raw);
      final Map<String, dynamic> out = {};
      for (final part in decoded.split('&')) {
        final kv = part.split('=');
        if (kv.isEmpty) continue;
        final key = Uri.decodeComponent(kv[0]);
        final value = kv.length > 1 ? Uri.decodeComponent(kv[1]) : '';
        out[key] = value;
      }
      // Отладка
      // ignore: avoid_print
      print('  Parsed tgWebAppData map: ${out.keys.toList()}');
      return out;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> uploadPhoto(Map<String, dynamic> params) async { return true; }
  static Future<bool> showMainButtonPopup(Map<String, dynamic> params) async { return true; }
  static Future<bool> copyToClipboard(String text) async { return true; }
}