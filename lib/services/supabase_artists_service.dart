import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/master_model.dart';

class SupabaseArtistsService {
  static String get baseUrl => ApiConfig.supabaseUrl;
  static String get anonKey => ApiConfig.supabaseAnonKey;
  
  // Кэширование
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Headers для Supabase API
  static Map<String, String> get headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  /// Проверка актуальности кэша
  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Очистка устаревшего кэша
  static void _cleanExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) >= _cacheTimeout) {
        _cache.remove(key);
        return true;
      }
      return false;
    });
  }

  /// Получение всех городов
  static Future<List<Map<String, dynamic>>> getCities() async {
    const cacheKey = 'cities';
    
    _cleanExpiredCache();
    
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      print('DEBUG: Using cached cities');
      return _cache[cacheKey];
    }
    
    try {
      print('DEBUG: Loading cities from Supabase');
      final response = await http.get(
        Uri.parse('$baseUrl/rest/v1/cities?select=*&is_active=eq.true'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final cities = List<Map<String, dynamic>>.from(json.decode(response.body));
        
        _cache[cacheKey] = cities;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        print('DEBUG: Loaded ${cities.length} cities from Supabase');
        return cities;
      } else {
        print('DEBUG: Supabase returned status ${response.statusCode}');
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading cities from Supabase: $e');
      return [];
    }
  }

  /// Получение всех категорий
  static Future<List<Map<String, dynamic>>> getCategories() async {
    const cacheKey = 'categories';
    
    _cleanExpiredCache();
    
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      print('DEBUG: Using cached categories');
      return _cache[cacheKey];
    }
    
    try {
      print('DEBUG: Loading categories from Supabase');
      final response = await http.get(
        Uri.parse('$baseUrl/rest/v1/categories?select=*&is_active=eq.true'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final categories = List<Map<String, dynamic>>.from(json.decode(response.body));
        
        _cache[cacheKey] = categories;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        print('DEBUG: Loaded ${categories.length} categories from Supabase');
        return categories;
      } else {
        print('DEBUG: Supabase returned status ${response.statusCode}');
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading categories from Supabase: $e');
      return [];
    }
  }

  /// Получение артистов с фильтрацией по городу и категории
  static Future<List<MasterModel>> getArtistsFiltered({
    String? city,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final cacheKey = 'artists_filtered:${city ?? 'all'}:${category ?? 'all'}:$limit:$offset';
    
    _cleanExpiredCache();
    
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      print('DEBUG: Using cached filtered artists');
      return _cache[cacheKey];
    }
    
    try {
      print('DEBUG: Loading filtered artists from Supabase');
      
      // Используем функцию get_artists_filtered
      final queryParams = <String, String>{
        'p_city': city ?? '',
        'p_category': category ?? '',
        'p_limit': limit.toString(),
        'p_offset': offset.toString(),
      };
      
      final uri = Uri.parse('$baseUrl/rest/v1/rpc/get_artists_filtered')
          .replace(queryParameters: queryParams);
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final artists = (data as List)
            .map((a) => MasterModel.fromSupabaseData(a))
            .toList();
        
        _cache[cacheKey] = artists;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        print('DEBUG: Loaded ${artists.length} filtered artists from Supabase');
        return artists;
      } else {
        print('DEBUG: Supabase returned status ${response.statusCode}');
        throw Exception('Failed to load filtered artists: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading filtered artists from Supabase: $e');
      return [];
    }
  }

  /// Получение всех артистов (без фильтрации)
  static Future<List<MasterModel>> getAllArtists() async {
    return getArtistsFiltered();
  }

  /// Получение артистов по городу
  static Future<List<MasterModel>> getArtistsByCity(String city) async {
    return getArtistsFiltered(city: city);
  }

  /// Получение артистов по категории
  static Future<List<MasterModel>> getArtistsByCategory(String category) async {
    return getArtistsFiltered(category: category);
  }

  /// Получение артистов по городу и категории
  static Future<List<MasterModel>> getArtistsByCityAndCategory(String city, String category) async {
    return getArtistsFiltered(city: city, category: category);
  }

  /// Очистка кэша
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('DEBUG: Supabase cache cleared');
  }

  /// Очистка кэша для конкретного ключа
  static void clearCacheForKey(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    print('DEBUG: Supabase cache cleared for key: $key');
  }
} 