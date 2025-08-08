import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class TelegramWebAppService {
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
    if (!kIsWeb) return null;
    try {
      final tg = js.context['Telegram'];
      if (tg != null) {
        final webApp = tg['WebApp'];
        final initDataUnsafe = webApp != null ? webApp['initDataUnsafe'] : null;
        final user = initDataUnsafe != null ? initDataUnsafe['user'] : null;
        final id = user != null ? user['id'] : null;
        if (id != null) return id.toString();
      }
    } catch (_) {}
    return null;
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

  static Future<Map<String, dynamic>?> getUserData() async {
    final id = getUserId();
    final username = getUsername();
    final firstName = getFirstName();
    final lastName = getLastName();
    if (id == null) return null;
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  static Future<bool> uploadPhoto(Map<String, dynamic> params) async { return true; }
  static Future<bool> showMainButtonPopup(Map<String, dynamic> params) async { return true; }
  static Future<bool> copyToClipboard(String text) async { return true; }
}