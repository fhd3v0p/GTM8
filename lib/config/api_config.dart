class ApiConfig {
  // Environment variables через --dart-define
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String ratingApiBaseUrl = String.fromEnvironment('RATING_API_BASE_URL', defaultValue: 'https://api.gtm.baby');

  // Supabase Storage Configuration
  static const String storageBucket = String.fromEnvironment('SUPABASE_STORAGE_BUCKET', defaultValue: 'gtm-assets-public');
  // AI uploads (private bucket)
  static const String aiUploadsBucket = String.fromEnvironment('SUPABASE_AI_BUCKET', defaultValue: 'gtm-ai-uploads');
  static const String aiUploadsFolder = String.fromEnvironment('SUPABASE_AI_FOLDER', defaultValue: 'img');
  
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
  static const String telegramBotToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN', defaultValue: '');
  
  // Validation
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}