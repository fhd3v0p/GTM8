import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'screens/giveaway_casino_screen.dart'; // FORCE: Ensure casino screen is included
import 'screens/giveaway_screen.dart';
import 'services/telegram_webapp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/api_config.dart';

// FORCE: Глобальная переменная для принудительного включения казино скрина в production билд
final GiveawayCasinoScreen globalCasinoScreen = GiveawayCasinoScreen();

Future<void> main() async {
  print('🚀 GTM App Starting...');
  print('🔍 Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
  print('🔍 Debug mode: ${kDebugMode}');
  
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');
  
  // Загрузка .env файла
  print('🔍 Loading .env file...');
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env file loaded successfully');
    
    // Проверяем загруженные переменные
    print('🔍 Checking loaded environment variables:');
    print('  SUPABASE_URL: ${dotenv.env['SUPABASE_URL']?.isNotEmpty == true ? "✅ loaded" : "❌ empty"}');
    print('  SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true ? "✅ loaded" : "❌ empty"}');
    print('  RATING_API_BASE_URL: ${dotenv.env['RATING_API_BASE_URL']?.isNotEmpty == true ? "✅ loaded" : "❌ empty"}');
    
  } catch (e) {
    print('⚠️ Failed to load .env file: $e');
    // Продолжаем без .env файла
  }
  
  print('🔍 Loading environment variables...');
  
  // Инициализация Supabase с безопасной проверкой
  try {
    print('🔍 Environment Variables Status:');
    print('  SUPABASE_URL: ${ApiConfig.supabaseUrl.isNotEmpty ? "✅ found (${ApiConfig.supabaseUrl.substring(0, 20)}...)" : "❌ missing"}');
    print('  SUPABASE_ANON_KEY: ${ApiConfig.supabaseAnonKey.isNotEmpty ? "✅ found (${ApiConfig.supabaseAnonKey.substring(0, 10)}...)" : "❌ missing"}');
    print('  RATING_API_BASE_URL: ${ApiConfig.ratingApiBaseUrl.isNotEmpty ? "✅ found (${ApiConfig.ratingApiBaseUrl})" : "❌ missing"}');
    print('  TELEGRAM_BOT_TOKEN: ${ApiConfig.telegramBotToken.isNotEmpty ? "✅ found" : "❌ missing"}');
    
    if (ApiConfig.isConfigured) {
      await Supabase.initialize(
        url: ApiConfig.supabaseUrl,
        anonKey: ApiConfig.supabaseAnonKey,
      );
      print('✅ Supabase initialized successfully');
    } else {
      print('⚠️ Supabase credentials not found, skipping initialization');
      print('SUPABASE_URL: ${ApiConfig.supabaseUrl.isNotEmpty ? "found" : "missing"}');
      print('SUPABASE_ANON_KEY: ${ApiConfig.supabaseAnonKey.isNotEmpty ? "found" : "missing"}');
    }
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    // Продолжаем выполнение без Supabase
  }

  // Безопасная инициализация Telegram WebApp
  try {
    TelegramWebAppService.initializeWebApp();
    TelegramWebAppService.disableVerticalSwipe();
    print('✅ Telegram WebApp initialized successfully');
  } catch (e) {
    print('⚠️ Failed to initialize Telegram WebApp: $e');
    // Продолжаем работу без WebApp функций
  }

  // FORCE: Ensure casino screen is compiled into build
  print('🎰 Casino screen type: ${GiveawayCasinoScreen}');
  
  // FORCE: Принудительно используем казино скрин чтобы он был включен в production билд
  final casinoScreen = GiveawayCasinoScreen;
  print('🎰 Casino screen forced usage: $casinoScreen');
  
  // FORCE: Используем глобальную переменную для гарантии включения в production билд
  print('🎰 Global casino screen: $globalCasinoScreen');
  
  // FORCE: Создаем экземпляр для гарантии включения в билд
  final testCasino = GiveawayCasinoScreen();
  print('🎰 Test casino instance: $testCasino');

  print('🚀 Starting Flutter app...');
  
  // FORCE: Принудительно создаем экземпляр казино скрина для включения в билд
  final forcedCasino = GiveawayCasinoScreen();
  print('🎰 Forced casino instance created: $forcedCasino');
  
  // FORCE: Принудительно используем казино скрин чтобы он был включен в production билд
  if (forcedCasino.runtimeType == GiveawayCasinoScreen) {
    print('🎰 Casino screen type verified: ${forcedCasino.runtimeType}');
  }
  
  // FORCE: Принудительно используем все методы казино скрина для включения в билд
  final casinoState = forcedCasino.createState();
  print('🎰 Casino state created: $casinoState');
  
  runApp(const MyApp());
  print('✅ Flutter app started successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MaterialApp...');
    
    // FORCE: Принудительно создаем экземпляр казино скрина для включения в билд
    final forcedCasinoInApp = GiveawayCasinoScreen();
    print('🎰 Forced casino instance in MyApp: $forcedCasinoInApp');
    
    return MaterialApp(
      title: 'Gotham\'s Top Model',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'OpenSans',
        scaffoldBackgroundColor: const Color(0xFFE3C8F1),
        iconTheme: const IconThemeData(color: Color(0xFFFF6EC7)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF6EC7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
            // FORCE: Add routes to ensure casino screen is included
      routes: {
        '/': (context) => const SplashScreen(),
        '/giveaway': (context) => const GiveawayScreen(),
        '/casino': (context) => const GiveawayCasinoScreen(),
        '/giveaway_casino': (context) => const GiveawayCasinoScreen(),
        '/casino_screen': (context) => const GiveawayCasinoScreen(),
        // FORCE: Принудительно добавляем маршрут для включения в билд
        '/force_casino': (context) => const GiveawayCasinoScreen(),
      },
      home: const SplashScreen(), // Вернули как было
      // home: const SplashScreen(),
      // FORCE: Временно используем казино скрин как home для гарантированного включения в production билд
      // home: const GiveawayCasinoScreen(),
    );
  }
}


