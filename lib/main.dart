import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/splash_screen.dart';
import 'screens/giveaway_casino_screen.dart'; // FORCE: Ensure casino screen is included
import 'services/telegram_webapp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/api_config.dart';

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

  print('🚀 Starting Flutter app...');
  runApp(const MyApp());
  print('✅ Flutter app started successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MaterialApp...');
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
        '/casino': (context) => const GiveawayCasinoScreen(),
      },
      home: const SplashScreen(),
    );
  }
}


