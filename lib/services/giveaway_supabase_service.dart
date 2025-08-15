import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'supabase_service.dart';

/// Узконаправленный сервис для Giveaway: быстрые чтения X/Y из Supabase
/// без обращения к Rating API. Предназначен для мгновенного заполнения UI.
class GiveawaySupabaseService {
  GiveawaySupabaseService._();
  static final GiveawaySupabaseService instance = GiveawaySupabaseService._();

  /// Быстрые пользовательские статсы напрямую из users
  /// Возвращает: total_tickets, subscription_tickets, referral_tickets, referral_code
  Future<Map<String, dynamic>> getUserStatsQuick(int telegramId) async {
    try {
      if (!ApiConfig.isConfigured) {
        print('⚠️ [GIVEAWAY] API not configured, returning fallback user stats');
        return {
          'total_tickets': 5,
          'subscription_tickets': 1,
          'referral_tickets': 2,
          'referral_code': 'DEMO123'
        };
      }
      return await SupabaseService().getUserStatsFast(telegramId);
    } catch (e) {
      print('❌ [GIVEAWAY] Error in getUserStatsQuick: $e');
      return {
        'total_tickets': 5,
        'subscription_tickets': 1,
        'referral_tickets': 2,
        'referral_code': 'DEMO123'
      };
    }
  }

  /// Общая сумма билетов по системе (Y)
  /// Пытается прочитать из представления total_all_tickets, иначе суммирует users.total_tickets
  Future<int> getTotalAllTicketsQuick() async {
    try {
      if (!ApiConfig.isConfigured) {
        print('⚠️ [GIVEAWAY] API not configured, returning fallback total tickets');
        return 42; // Fallback значение для локальной разработки
      }
      return await SupabaseService().getTotalAllTicketsFast();
    } catch (e) {
      print('❌ [GIVEAWAY] Error in getTotalAllTicketsQuick: $e');
      return 42; // Fallback значение
    }
  }

  /// Альтернативная прямая загрузка представления (если нужно использовать отдельно)
  Future<int?> tryReadTotalAllTicketsView() async {
    try {
      // Проверяем конфигурацию API
      if (!ApiConfig.isConfigured) {
        print('⚠️ [GIVEAWAY] API not configured, skipping total_all_tickets view');
        return null;
      }
      
      final viewUrl = '${ApiConfig.apiBaseUrl}/total_all_tickets?select=*';
      print('🔍 [GIVEAWAY] Fetching total tickets from: $viewUrl');
      
      final resp = await http.get(Uri.parse(viewUrl), headers: ApiConfig.headers);
      print('🔍 [GIVEAWAY] Response status: ${resp.statusCode}');
      print('🔍 [GIVEAWAY] Response body: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}...');
      
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List && data.isNotEmpty) {
          final row = data.first as Map<String, dynamic>;
          for (final key in ['total_all_tickets','total_all','total','value','count']) {
            if (row.containsKey(key)) {
              final v = row[key];
              final parsed = (v is int) ? v : int.tryParse('$v') ?? 0;
              print('✅ [GIVEAWAY] Found total tickets: $parsed');
              return parsed;
            }
          }
        }
      } else {
        print('❌ [GIVEAWAY] HTTP error ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      print('❌ [GIVEAWAY] Exception in tryReadTotalAllTicketsView: $e');
    }
    return null;
  }
}

 