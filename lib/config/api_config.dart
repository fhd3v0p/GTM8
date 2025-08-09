import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Env
  static final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  static final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static final String ratingApiBaseUrl = dotenv.env['RATING_API_BASE_URL'] ?? 'https://api.gtm.baby';

  // Supabase Storage Configuration
  static const String storageBucket = 'gtm-assets-public';
  // AI uploads (private bucket)
  static final String aiUploadsBucket = dotenv.env['SUPABASE_AI_BUCKET'] ?? 'gtm-ai-uploads';
  static final String aiUploadsFolder = dotenv.env['SUPABASE_AI_FOLDER'] ?? 'img';
  
  // Storage Paths
  static const String avatarsPath = 'avatars';
  static const String galleryPath = 'gallery';
  static const String artistsPath = 'artists';
  static const String bannersPath = 'banners';
  static const String productsPath = 'GTM_products';
  
  // API Endpoints
  static String get apiBaseUrl => '$supabaseUrl/rest/v1';
  
  // Database Tables
  static const String usersTable = 'users';
  static const String artistsTable = 'artists';
  static const String subscriptionsTable = 'subscriptions';
  static const String referralsTable = 'referrals';
  static const String giveawaysTable = 'giveaways';
  static const String artistGalleryTable = 'artist_gallery';
  static const String productsTable = 'products';
  
  // Headers for Supabase API
  static Map<String, String> get headers => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
  };
  
  // Storage URLs
  static String getStorageUrl(String path, String fileName) {
    return '$supabaseUrl/storage/v1/object/public/$storageBucket/$path/$fileName';
  }
  
  // API URLs
  static String getTableUrl(String table) {
    return '$apiBaseUrl/$table';
  }

  static Map<String, String> get ratingApiHeaders => {
    'Content-Type': 'application/json',
  };
  
  // Telegram Bot Token (используется в веб только для deep-links, не для авторизации)
  static String get telegramBotToken => dotenv.env['TELEGRAM_BOT_TOKEN'] ?? '';
  
  // Validation
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}