import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/master_model.dart';

class ArtistsService {
  static String get baseUrl => ApiConfig.supabaseUrl;
  static String get anonKey => ApiConfig.supabaseAnonKey;
  static String get storageBucket => ApiConfig.storageBucket;
  
  // Кэширование
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheTimeout = Duration(minutes: 10);
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
        Uri.parse('$baseUrl/rest/v1/cities?select=*&is_active=eq.true&order=name.asc'),
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
        Uri.parse('$baseUrl/rest/v1/categories?select=*&is_active=eq.true&order=name.asc'),
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

  /// Получение артистов с фильтрацией
  static Future<List<MasterModel>> getArtists({
    String? city,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final cacheKey = 'artists:${city ?? 'all'}:${category ?? 'all'}:$limit:$offset';
    
    _cleanExpiredCache();
    
    if (_cache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      print('DEBUG: Using cached artists');
      return _cache[cacheKey];
    }
    
    try {
      print('DEBUG: Loading artists from Supabase with filters: city=$city, category=$category');
      
      // Пока используем прямой запрос без RPC функции
      String query = '$baseUrl/rest/v1/artists?select=*,artist_gallery(image_url)&is_active=eq.true';
      
      // Добавляем фильтр по городу
      if (city != null && city.isNotEmpty) {
        query += '&city=ilike.*$city*';
      }
      
      // Добавляем лимит и смещение
      query += '&limit=$limit&offset=$offset';
      
      final response = await http.get(
        Uri.parse(query),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final artists = (data as List)
            .map((a) => _processArtistData(a))
            .where((a) => _matchesFilters(a, city, category))
            .map((a) => MasterModel.fromSupabaseData(a))
            .toList();
        
        _cache[cacheKey] = artists;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        print('DEBUG: Loaded ${artists.length} artists from Supabase');
        return artists;
      } else {
        print('DEBUG: Supabase returned status ${response.statusCode}');
        throw Exception('Failed to load artists: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading artists from Supabase: $e');
      return [];
    }
  }

  /// Получение артистов по городу
  static Future<List<MasterModel>> getArtistsByCity(String city) async {
    return getArtists(city: city);
  }

  /// Получение артистов по категории
  static Future<List<MasterModel>> getArtistsByCategory(String category) async {
    return getArtists(category: category);
  }

  /// Получение артистов по городу и категории
  static Future<List<MasterModel>> getArtistsByCityAndCategory(String city, String category) async {
    return getArtists(city: city, category: category);
  }

  /// Получение всех артистов
  static Future<List<MasterModel>> getAllArtists() async {
    return getArtists();
  }

  /// Получение URL изображения из Storage
  static String getStorageUrl(String path) {
    if (path.startsWith('http')) {
      return path; // Уже полный URL
    }
    
    if (path.startsWith('assets/')) {
      return path; // Локальный ассет
    }
    
    // Формируем URL для Supabase Storage
    return '$baseUrl/storage/v1/object/public/$storageBucket/$path';
  }

  /// Получение URL аватара артиста
  static String getArtistAvatarUrl(String artistId) {
    return getStorageUrl('artists/$artistId/avatar.png');
  }

  /// Получение URL изображения галереи артиста
  static String getArtistGalleryImageUrl(String artistId, int imageNumber) {
    return getStorageUrl('artists/$artistId/gallery$imageNumber.jpg');
  }

  /// Получение списка URL изображений галереи артиста
  static List<String> getArtistGalleryUrls(String artistId, {int maxImages = 10}) {
    final urls = <String>[];
    for (int i = 1; i <= maxImages; i++) {
      urls.add(getArtistGalleryImageUrl(artistId, i));
    }
    return urls;
  }

  /// Проверка существования файла в Storage
  static Future<bool> checkFileExists(String path) async {
    try {
      final url = getStorageUrl(path);
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Получение списка файлов в папке (через Storage API)
  static Future<List<String>> listFilesInFolder(String folderPath) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/storage/v1/object/list/$storageBucket?prefix=$folderPath/'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = (data['data'] as List)
            .map((file) => file['name'] as String)
            .where((name) => name.isNotEmpty)
            .toList();
        
        return files;
      }
    } catch (e) {
      print('DEBUG: Error listing files in folder $folderPath: $e');
    }
    
    return [];
  }

  /// Получение артистов из папок Storage (fallback метод)
  static Future<List<MasterModel>> getArtistsFromStorage() async {
    try {
      print('DEBUG: Loading artists from Storage folders');
      
      // Получаем список папок артистов
      final artistFolders = await listFilesInFolder('artists');
      final artists = <MasterModel>[];
      
      for (final folder in artistFolders) {
        try {
          // Извлекаем ID артиста из пути
          final artistId = folder.split('/').last;
          
          // Проверяем существование аватара
          final hasAvatar = await checkFileExists('artists/$artistId/avatar.png');
          
          if (hasAvatar) {
            // Создаем базовую модель артиста
            final artist = MasterModel(
              id: artistId,
              name: artistId.replaceAll('_', ' ').replaceAll('-', ' '),
              city: '', // Будет заполнено из БД
              category: '', // Будет заполнено из БД
              avatar: getArtistAvatarUrl(artistId),
              telegram: '',
              instagram: '',
              tiktok: '',
              gallery: getArtistGalleryUrls(artistId),
            );
            
            artists.add(artist);
          }
        } catch (e) {
          print('DEBUG: Error processing artist folder $folder: $e');
        }
      }
      
      print('DEBUG: Loaded ${artists.length} artists from Storage');
      return artists;
    } catch (e) {
      print('DEBUG: Error loading artists from Storage: $e');
      return [];
    }
  }

  /// Очистка кэша
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('DEBUG: Artists cache cleared');
  }
  
  /// Принудительная очистка кэша при изменении категорий
  static void forceClearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    print('DEBUG: Artists cache force cleared - categories updated');
  }

  /// Очистка кэша для конкретного ключа
  static void clearCacheForKey(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    print('DEBUG: Artists cache cleared for key: $key');
  }

  /// Обработка данных артиста для добавления галереи
  static Map<String, dynamic> _processArtistData(Map<String, dynamic> artistData) {
    // Извлекаем URL галереи из связанной таблицы
    final galleryData = artistData['artist_gallery'] as List<dynamic>? ?? [];
    final galleryUrls = galleryData.map((g) => g['image_url'] as String).toList();
    
    // Добавляем gallery_urls к данным артиста
    artistData['gallery_urls'] = galleryUrls;
    
    return artistData;
  }
  
  /// Проверка соответствия фильтрам
  static bool _matchesFilters(Map<String, dynamic> artistData, String? city, String? category) {
    // Проверка города
    if (city != null && city.isNotEmpty) {
      final artistCity = artistData['city'] as String? ?? '';
      if (!artistCity.toLowerCase().contains(city.toLowerCase())) {
        return false;
      }
    }
    
    // Проверка категории
    if (category != null && category.isNotEmpty) {
      final specialties = artistData['specialties'] as List<dynamic>? ?? [];
      
      // Ищем точное совпадение категории в specialties
      final hasCategory = specialties.any((s) => 
        s.toString() == category);
      
      if (!hasCategory) {
        return false;
      }
    }
    
    return true;
  }

  /// Получение статистики
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final cities = await getCities();
      final categories = await getCategories();
      final artists = await getAllArtists();
      
      return {
        'cities_count': cities.length,
        'categories_count': categories.length,
        'artists_count': artists.length,
        'cache_size': _cache.length,
        'cache_keys': _cache.keys.toList(),
      };
    } catch (e) {
      print('DEBUG: Error getting stats: $e');
      return {};
    }
  }
} 