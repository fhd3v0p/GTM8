import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../config/api_config.dart';

class MasterModel {
  final String id; // Уникальный ID артиста
  final String name;
  final String city;
  final String category;
  final String avatar;
  final String telegram;
  final String? telegramLs;
  final String instagram;
  final String tiktok;
  final List<String> gallery;
  // Новые поля для ссылок и html
  final String? pinterest;
  final String? pinterestUrl;
  final String? telegramUrl;
  final String? tiktokUrl;
  final String? bookingUrl;
  final String? bio;
  final String? locationHtml;
  final String? galleryHtml;
  final List<String>? subscriptionChannels; // Telegram каналы для проверки подписки

  MasterModel({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.avatar,
    required this.telegram,
    this.telegramLs,
    required this.instagram,
    required this.tiktok,
    required this.gallery,
    this.pinterest,
    this.pinterestUrl,
    this.telegramUrl,
    this.tiktokUrl,
    this.bookingUrl,
    this.bio,
    this.locationHtml,
    this.galleryHtml,
    this.subscriptionChannels,
  });

  // Тестовые данные удалены - используем реальных партистов из assets/artists
  static List<MasterModel> sampleData = [];

  static Future<MasterModel> fromArtistFolder(String folderPath) async {
    print('DEBUG: Загружаем артиста из папки: $folderPath');
    String bio = '';
    Map<String, dynamic> links = {};
    final gallery = <String>[];
    
    try {
      bio = await rootBundle.loadString('$folderPath/bio.txt');
      print('DEBUG: bio.txt загружен успешно');
    } catch (e) {
      print('Ошибка чтения bio.txt для $folderPath: $e');
    }
    
    try {
      final linksJson = await rootBundle.loadString('$folderPath/links.json');
      links = jsonDecode(linksJson);
      print('DEBUG: links.json загружен успешно: $links');
    } catch (e) {
      print('Ошибка чтения или парсинга links.json для $folderPath: $e');
    }
    
    // Получаем имя артиста (последняя часть пути)
    final artistName = folderPath.split('/').last;
    
    // Используем локальные ассеты вместо MinIO
    final avatarPath = '$folderPath/avatar.png';
    
    // Загружаем галерею из локальных файлов
    for (var i = 1; i <= 10; i++) {
      final galleryPath = '$folderPath/gallery$i.jpg';
      // Проверяем, существует ли файл
      try {
        await rootBundle.load(galleryPath);
        gallery.add(galleryPath);
      } catch (e) {
        // Файл не существует, пропускаем
        print('DEBUG: Файл $galleryPath не найден');
      }
    }
    
    final master = MasterModel(
      id: links['id'] ?? artistName, // Используем ID из links.json или имя папки
      name: links['name'] ?? 'Artist',
      city: links['city'] ?? '',
      category: links['category'] ?? '',
      avatar: avatarPath, // Используем локальный путь
      telegram: links['telegram'] ?? '',
      instagram: links['instagram'] ?? '',
      tiktok: links['tiktok'] ?? '',
      gallery: gallery, // Локальные пути к галерее
      pinterest: links['pinterest'],
      pinterestUrl: links['pinterestUrl'],
      telegramUrl: links['telegramUrl'],
      tiktokUrl: links['tiktokUrl'],
      bookingUrl: links['bookingUrl'],
      bio: bio, // bio только из файла
      locationHtml: links['locationHtml'],
      galleryHtml: links['galleryHtml'],
      subscriptionChannels: links['subscription_channels'] != null 
          ? List<String>.from(links['subscription_channels'])
          : null,
    );
    
    print('DEBUG: Создан мастер: ${master.name} из города ${master.city}');
    return master;
  }

  // Новый метод для создания MasterModel из API данных
  static MasterModel fromApiData(Map<String, dynamic> data) {
    final gallery = <String>[];
    
    // Формируем галерею из MinIO если есть ID артиста
    if (data['id'] != null) {
      final artistId = data['id'];
      final minioBaseUrl = const String.fromEnvironment('MINIO_BASE_URL', 
          defaultValue: 'https://gtm.baby/api/minio/download/gtm-assets/');
      final minioBase = '$minioBaseUrl$artistId/';
      
      // Добавляем изображения галереи
      for (var i = 1; i <= 10; i++) {
        gallery.add('${minioBase}gallery$i.jpg');
      }
    }
    
    return MasterModel(
      id: data['id'] ?? data['name'] ?? 'artist',
      name: data['name'] ?? 'Artist',
      city: data['city'] ?? '',
      category: data['category'] ?? '',
      avatar: data['avatar'] ?? 'assets/avatar1.png',
      telegram: data['telegram'] ?? '',
      telegramLs: data['telegram_ls'],
      instagram: data['instagram'] ?? '',
      tiktok: data['tiktok'] ?? '',
      gallery: gallery,
      pinterest: data['pinterest'],
      pinterestUrl: data['pinterest_url'],
      telegramUrl: data['telegram_url'],
      tiktokUrl: data['tiktok_url'],
      bookingUrl: data['booking_url'],
      bio: data['bio'],
      locationHtml: data['location_html'],
      galleryHtml: data['gallery_html'],
      subscriptionChannels: data['subscription_channels'] != null 
          ? List<String>.from(data['subscription_channels'])
          : null,
    );
  }

  // Метод для создания MasterModel из данных Supabase
  static MasterModel fromSupabaseData(Map<String, dynamic> data) {
    final gallery = <String>[];
    
    // Если есть gallery_urls из RPC функции, используем их
    if (data['gallery_urls'] != null && data['gallery_urls'] is List) {
      gallery.addAll(List<String>.from(data['gallery_urls']));
    } else if (data['id'] != null) {
      // Иначе формируем галерею из Supabase Storage
      final artistId = data['id'];
      final storageBaseUrl = '${ApiConfig.supabaseUrl}/storage/v1/object/public/${ApiConfig.storageBucket}/artists/$artistId/';
      
      // Добавляем изображения галереи
      for (var i = 1; i <= 10; i++) {
        gallery.add('${storageBaseUrl}gallery$i.jpg');
      }
    }
    
    // Получаем города и категории из разных источников
    String cityName = '';
    String categoryName = '';
    
    if (data['city_name'] != null) {
      cityName = data['city_name'].toString();
    } else if (data['city'] != null) {
      cityName = data['city'].toString();
    }
    
    if (data['category_name'] != null) {
      categoryName = data['category_name'].toString();
    } else {
      // Определяем категорию по specialties
      final specialties = data['specialties'] as List<dynamic>? ?? [];
      if (specialties.isNotEmpty) {
        // Используем первую специальность как основную категорию
        String firstSpecialty = specialties.first.toString();
        
        // Мапим специальности на категории MasterCloud
        if (firstSpecialty == 'Piercing') {
          categoryName = 'Piercing';
        } else if (firstSpecialty == 'Hair') {
          categoryName = 'Hair';
        } else if (firstSpecialty == 'Nails') {
          categoryName = 'Nails';
        } else if (firstSpecialty == 'GTM BRAND') {
          categoryName = 'GTM BRAND';
        } else if (firstSpecialty == 'Jewelry') {
          categoryName = 'Jewelry';
        } else if (firstSpecialty == 'Custom') {
          categoryName = 'Custom';
        } else if (firstSpecialty == 'Second') {
          categoryName = 'Second';
        } else {
          categoryName = 'Tattoo'; // По умолчанию для всех остальных
        }
      } else {
        categoryName = 'Tattoo'; // Если нет specialties - ставим Tattoo
      }
    }
    
    return MasterModel(
      id: data['id']?.toString() ?? 'artist',
      name: data['name'] ?? 'Artist',
      city: cityName,
      category: categoryName,
      avatar: data['avatar_url'] ?? 'assets/avatar1.png',
      telegram: data['telegram'] ?? '',
      telegramLs: null, // Не используется в Supabase
      instagram: data['instagram'] ?? '',
      tiktok: data['tiktok'] ?? '',
      gallery: gallery,
      pinterest: data['pinterest'],
      pinterestUrl: data['pinterest_url'],
      telegramUrl: data['telegram_url'],
      tiktokUrl: data['tiktok_url'],
      bookingUrl: data['booking_url'],
      bio: data['bio'],
      locationHtml: data['location_html'],
      galleryHtml: data['gallery_html'],
      subscriptionChannels: data['subscription_channels'] != null 
          ? List<String>.from(data['subscription_channels'])
          : null,
    );
  }

  static Future<List<MasterModel>> loadAllFromFolders(List<String> artistFolders) async {
    final loaded = <MasterModel>[];
    for (final folder in artistFolders) {
      try {
        final m = await MasterModel.fromArtistFolder(folder);
        loaded.add(m);
      } catch (_) {}
    }
    return loaded;
  }

  // Метод для конвертации в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'category': category,
      'avatar': avatar,
      'telegram': telegram,
      'instagram': instagram,
      'tiktok': tiktok,
      'gallery': gallery,
      'pinterest': pinterest,
      'pinterest_url': pinterestUrl,
      'telegram_url': telegramUrl,
      'tiktok_url': tiktokUrl,
      'booking_url': bookingUrl,
      'bio': bio,
      'location_html': locationHtml,
      'gallery_html': galleryHtml,
    };
  }
}
