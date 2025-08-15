import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/giveaway_casino_screen.dart'; // FORCE: Ensure casino screen is included
import 'services/telegram_webapp_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Безопасная загрузка .env файла
  try {
    await dotenv.load(fileName: 'assets/.env');
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Could not load .env file: $e');
    // Продолжаем выполнение без .env
  }

  // Инициализация Supabase с безопасной проверкой
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');
  } else {
    print('⚠️ Supabase credentials not found, skipping initialization');
    print('SUPABASE_URL: ${supabaseUrl != null ? "found" : "missing"}');
    print('SUPABASE_ANON_KEY: ${supabaseAnonKey != null ? "found" : "missing"}');
  }

  TelegramWebAppService.initializeWebApp();
  TelegramWebAppService.disableVerticalSwipe();

  // FORCE: Ensure casino screen is compiled into build
  assert(() {
    print('Casino screen type: ${GiveawayCasinoScreen}');
    return true;
  }());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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

void navigateWithFade(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

void navigateWithFadeReplacement(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}
