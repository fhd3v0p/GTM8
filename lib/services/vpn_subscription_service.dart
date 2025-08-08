import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import './telegram_webapp_service.dart';
import './api_service.dart';

class VpnSubscriptionService {
  // Используем Supabase API вместо VPN URL
  static String get _apiUrl => ApiConfig.supabaseUrl;
  static Map<String, String> get headers => ApiConfig.headers;

  // === VPN SUBSCRIPTION OPERATIONS ===
  static Future<List<Map<String, dynamic>>> getVpnUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${_apiUrl}/rest/v1/vpn_users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load VPN users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching VPN users: $e');
    }
  }

  static Future<Map<String, dynamic>?> createVpnUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiUrl}/rest/v1/vpn_users'),
        headers: headers,
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to create VPN user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating VPN user: $e');
    }
  }

  static Future<Map<String, dynamic>?> generateVpnConfig(int userId, String username) async {
    try {
      final response = await http.post(
        Uri.parse('${_apiUrl}/rest/v1/vpn_configs'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to generate VPN config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating VPN config: $e');
    }
  }

  static Future<bool> deleteVpnUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${_apiUrl}/rest/v1/vpn_users?user_id=eq.$userId'),
        headers: headers,
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting VPN user: $e');
    }
  }

  // === SUBSCRIPTION CHECK ===
  static Future<bool> checkSubscription() async {
    try {
      final userIdStr = TelegramWebAppService.getUserId();
      if (userIdStr == null) {
        print('DEBUG: Telegram userId is null');
        return false;
      }
      final telegramId = int.tryParse(userIdStr);
      if (telegramId == null) {
        print('DEBUG: Invalid Telegram userId: ' + userIdStr);
        return false;
      }

      final result = await ApiService.checkSubscriptions(telegramId);

      bool isSubscribed = false;
      if (result.containsKey('is_subscribed') && result['is_subscribed'] is bool) {
        isSubscribed = result['is_subscribed'] as bool;
      } else if (result.containsKey('success') && result['success'] is bool) {
        isSubscribed = result['success'] as bool;
      } else if (result.containsKey('subscription_tickets') && result['subscription_tickets'] is int) {
        isSubscribed = (result['subscription_tickets'] as int) > 0;
      }

      return isSubscribed;
    } catch (e) {
      print('Error checking subscription: ' + e.toString());
      return false;
    }
  }
} 