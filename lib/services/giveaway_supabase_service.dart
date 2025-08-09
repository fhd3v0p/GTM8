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
    return SupabaseService().getUserStatsFast(telegramId);
  }

  /// Общая сумма билетов по системе (Y)
  /// Пытается прочитать из представления total_all_tickets, иначе суммирует users.total_tickets
  Future<int> getTotalAllTicketsQuick() async {
    return SupabaseService().getTotalAllTicketsFast();
  }

  /// Альтернативная прямая загрузка представления (если нужно использовать отдельно)
  Future<int?> tryReadTotalAllTicketsView() async {
    try {
      final viewUrl = '${ApiConfig.apiBaseUrl}/total_all_tickets?select=*';
      final resp = await http.get(Uri.parse(viewUrl), headers: ApiConfig.headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List && data.isNotEmpty) {
          final row = data.first as Map<String, dynamic>;
          for (final key in ['total_all_tickets','total_all','total','value','count']) {
            if (row.containsKey(key)) {
              final v = row[key];
              final parsed = (v is int) ? v : int.tryParse('$v') ?? 0;
              return parsed;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}

 