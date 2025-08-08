import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';

class ApiService {
  // Используем Supabase API вместо legacy
  static String get baseUrl => ApiConfig.apiBaseUrl;
  static String get supabaseUrl => ApiConfig.supabaseUrl;
  static String get supabaseAnonKey => ApiConfig.supabaseAnonKey;
  // Rating API (Flask)
  static String get ratingApiBase => '${ApiConfig.ratingApiBaseUrl}/api';

  // Headers для Supabase API
  static Map<String, String> get headers => ApiConfig.headers;
  static Map<String, String> get ratingHeaders => ApiConfig.ratingApiHeaders;

  // === ARTISTS ===
  static Future<List<Map<String, dynamic>>> getArtists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.artistsTable}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load artists: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching artists: $e');
    }
  }

  static Future<Map<String, dynamic>?> getArtist(int artistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.artistsTable}?id=eq.$artistId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? Map<String, dynamic>.from(data.first) : null;
      } else {
        throw Exception('Failed to load artist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching artist: $e');
    }
  }

  // === USERS ===
  static Future<Map<String, dynamic>?> getUser(int telegramId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.usersTable}?telegram_id=eq.$telegramId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? Map<String, dynamic>.from(data.first) : null;
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConfig.usersTable}'),
        headers: headers,
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser(int telegramId, Map<String, dynamic> userData) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/${ApiConfig.usersTable}?telegram_id=eq.$telegramId'),
        headers: headers,
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // === SUBSCRIPTIONS ===
  static Future<List<Map<String, dynamic>>> getUserSubscriptions(int telegramId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.subscriptionsTable}?telegram_id=eq.$telegramId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load subscriptions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscriptions: $e');
    }
  }

  static Future<Map<String, dynamic>> addSubscription(Map<String, dynamic> subscriptionData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConfig.subscriptionsTable}'),
        headers: headers,
        body: json.encode(subscriptionData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to add subscription: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding subscription: $e');
    }
  }

  // === REFERRALS ===
  static Future<Map<String, dynamic>?> getReferralByCode(String referralCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.referralsTable}?referral_code=eq.$referralCode'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? Map<String, dynamic>.from(data.first) : null;
      } else {
        throw Exception('Failed to load referral: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching referral: $e');
    }
  }

  static Future<Map<String, dynamic>> createReferral(Map<String, dynamic> referralData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/${ApiConfig.referralsTable}'),
        headers: headers,
        body: json.encode(referralData),
      );

      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to create referral: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating referral: $e');
    }
  }

  // === GIVEAWAYS ===
  static Future<List<Map<String, dynamic>>> getActiveGiveaways() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.giveawaysTable}?is_active=eq.true'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load giveaways: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching giveaways: $e');
    }
  }

  // === STATISTICS ===
  static Future<int> getTotalTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.usersTable}?select=tickets_count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.fold<int>(0, (sum, user) => sum + ((user['tickets_count'] as int?) ?? 0));
      } else {
        throw Exception('Failed to load total tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching total tickets: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserStats(int telegramId) async {
    try {
      final user = await getUser(telegramId);
      final subscriptions = await getUserSubscriptions(telegramId);
      
      return {
        'user': user,
        'subscriptions': subscriptions,
        'tickets_count': user?['tickets_count'] ?? 0,
        'has_subscription_ticket': user?['has_subscription_ticket'] ?? false,
      };
    } catch (e) {
      throw Exception('Error fetching user stats: $e');
    }
  }

  // === MASTERS ===
  static Future<List<Map<String, dynamic>>> getMasters() async {
    try {
      // Используем таблицу artists как masters
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.artistsTable}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load masters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching masters: $e');
    }
  }

  // === PRODUCTS (Unified) ===
  /// Получение списка продуктов с необязательными фильтрами
  static Future<List<ProductModel>> getProducts({String? category, String? masterId}) async {
    try {
      final buffer = StringBuffer('${baseUrl}/${ApiConfig.productsTable}?select=*');
      if (category != null && category.isNotEmpty) {
        buffer.write('&category=eq.${Uri.encodeComponent(category)}');
      }
      if (masterId != null && masterId.isNotEmpty) {
        buffer.write('&master_id=eq.${Uri.encodeComponent(masterId)}');
      }
      final response = await http.get(Uri.parse(buffer.toString()), headers: headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body) as List;
        return data.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  /// Получение одного продукта по ID
  static Future<ProductModel?> getProduct(String productId) async {
    try {
      final url = '${baseUrl}/${ApiConfig.productsTable}?id=eq.${Uri.encodeComponent(productId)}&limit=1';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final List list = json.decode(response.body) as List;
        if (list.isEmpty) return null;
        return ProductModel.fromJson(Map<String, dynamic>.from(list.first));
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // === PRODUCTS ===
  static Future<List<Map<String, dynamic>>> getProductsByMasterAndCategory(int masterId, int categoryId) async {
    try {
      print('🚨 DEBUG: Запрашиваем продукты для мастера ID: $masterId');
      print('🚨 DEBUG: URL запроса: $baseUrl/${ApiConfig.productsTable}?master_id=eq.$masterId');
      print('🚨 DEBUG: Headers: $headers');
      
      // Используем таблицу products
      final response = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.productsTable}?master_id=eq.$masterId'),
        headers: headers,
      );

      print('🚨 DEBUG: Ответ API - статус: ${response.statusCode}');
      print('🚨 DEBUG: Ответ API - тело: ${response.body}');

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(json.decode(response.body));
        print('🚨 DEBUG: Загружено продуктов: ${products.length}');
        for (var product in products) {
          print('🚨 DEBUG: Продукт: ${product['name']} (категория: ${product['category']})');
        }
        return products;
      } else {
        print('🚨 DEBUG: Ошибка загрузки продуктов: ${response.statusCode}');
        print('🚨 DEBUG: Тело ошибки: ${response.body}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 DEBUG: Исключение при загрузке продуктов: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  // === HEALTH CHECK ===
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$supabaseUrl/rest/v1/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // === RATING / GIVEAWAY HELPERS (moved from TicketsApiService) ===
  /// Проверка подписки пользователя (вызывает Flask Rating API -> Telegram Bot API -> Supabase RPC)
  static Future<Map<String, dynamic>> checkSubscriptions(int telegramId) async {
    try {
      final resp = await http.post(
        Uri.parse('$ratingApiBase/check-subscriptions'),
        headers: ratingHeaders,
        body: jsonEncode({'telegram_id': telegramId}),
      );
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Subscription check failed: ${resp.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // === GIVEAWAY (via Rating API) ===
  static Future<int?> getTotalAllTicketsFromApi() async {
    final uri = Uri.parse('$ratingApiBase/giveaway/total_all');
    final resp = await http.get(uri, headers: ratingHeaders);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true) {
        final v = body['total_all_tickets'];
        if (v is int) return v;
        if (v is String) return int.tryParse(v);
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getGiveawayUserStats(int telegramId) async {
    final uri = Uri.parse('$ratingApiBase/giveaway/user_stats/$telegramId');
    final resp = await http.get(uri, headers: ratingHeaders);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
    }
    return null;
  }

  static Future<String?> getOrCreateReferralCode(int telegramId) async {
    final uri = Uri.parse('$ratingApiBase/referral-code');
    final resp = await http.post(
      uri,
      headers: ratingHeaders,
      body: jsonEncode({'telegram_id': telegramId}),
    );
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true) {
        final code = body['referral_code'];
        if (code is String && code.isNotEmpty) return code;
      }
    }
    return null;
  }

  /// Общая сумма выданных билетов всем пользователям (view/RPC total_all_tickets)
  static Future<int?> getTotalAllTickets() async {
    try {
      // 0) Прямо из таблицы total_all_tickets (если это таблица)
      // ignore: avoid_print
      print('[total_all_tickets] TRY table total_all_tickets');
      final tableResp = await http.get(
        Uri.parse('$baseUrl/total_all_tickets?select=*'),
        headers: headers,
      );
      // ignore: avoid_print
      print('[total_all_tickets] table status: ${tableResp.statusCode} body: ${tableResp.body}');
      if (tableResp.statusCode == 200 || tableResp.statusCode == 206) {
        final list = jsonDecode(tableResp.body);
        if (list is List && list.isNotEmpty) {
          // Попробуем вытащить по известным именам полей
          final Map<String, dynamic> row = Map<String, dynamic>.from(list.first as Map);
          final candidateKeys = ['total_all_tickets', 'total_all', 'total', 'value', 'count'];
          for (final key in candidateKeys) {
            if (row.containsKey(key)) {
              final v = row[key];
              if (v is int) return v;
              if (v is String) {
                final p = int.tryParse(v);
                if (p != null) return p;
              }
            }
          }
          // Если явных ключей нет — возьмём первое числовое поле
          for (final entry in row.entries) {
            final v = entry.value;
            if (v is int) return v;
            if (v is String) {
              final p = int.tryParse(v);
              if (p != null) return p;
            }
          }
          // Или суммируем по всем строкам все числовые поля
          int sum = 0;
          for (final item in list) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              for (final v in map.values) {
                if (v is int) sum += v; else if (v is String) sum += int.tryParse(v) ?? 0;
              }
            }
          }
          if (sum > 0) return sum;
        }
      }

      // 1) Пытаемся прочитать из view total_all_tickets
      // ignore: avoid_print
      print('[total_all_tickets] TRY view');
      final totalsResp = await http.get(
        Uri.parse('$baseUrl/total_all_tickets?select=*'),
        headers: headers,
      );
      // ignore: avoid_print
      print('[total_all_tickets] view status: ${totalsResp.statusCode} body: ${totalsResp.body}');
      if (totalsResp.statusCode == 200 || totalsResp.statusCode == 206) {
        final list = jsonDecode(totalsResp.body);
        if (list is List && list.isNotEmpty) {
          final row = Map<String, dynamic>.from(list.first as Map);
          for (final entry in row.entries) {
            final value = entry.value;
            if (value is int) return value;
            if (value is String) {
              final parsed = int.tryParse(value);
              if (parsed != null) return parsed;
            }
          }
        }
      }
      // 2) Фоллбек на RPC
      // ignore: avoid_print
      print('[total_all_tickets] TRY rpc');
      final rpcResponse = await http.post(
        Uri.parse('$baseUrl/rpc/get_total_all_tickets'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      // ignore: avoid_print
      print('[total_all_tickets] rpc status: ${rpcResponse.statusCode} body: ${rpcResponse.body}');
      if (rpcResponse.statusCode == 200) {
        final body = jsonDecode(rpcResponse.body);
        if (body is int) return body;
        final parsed = int.tryParse(body.toString());
        return parsed;
      }

      // 3) Третий фоллбек: суммируем по users.total_tickets (может быть ограничен RLS)
      // ignore: avoid_print
      print('[total_all_tickets] TRY sum users.total_tickets');
      final usersResp = await http.get(
        Uri.parse('$baseUrl/${ApiConfig.usersTable}?select=total_tickets'),
        headers: headers,
      );
      // ignore: avoid_print
      print('[total_all_tickets] users status: ${usersResp.statusCode} len: ${usersResp.body.length}');
      if (usersResp.statusCode == 200 || usersResp.statusCode == 206) {
        final list = jsonDecode(usersResp.body);
        if (list is List) {
          int sum = 0;
          for (final row in list) {
            final v = (row is Map) ? row['total_tickets'] : null;
            if (v is int) sum += v; else if (v is String) sum += int.tryParse(v) ?? 0;
          }
          // ignore: avoid_print
          print('[total_all_tickets] users sum = $sum');
          return sum;
        }
      }
    } catch (e) {
      // Для отладки в dev
      // ignore: avoid_print
      print('DEBUG getTotalAllTickets error: $e');
    }
    return null;
  }
} 