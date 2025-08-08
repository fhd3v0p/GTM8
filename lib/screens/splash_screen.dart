import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../services/telegram_webapp_service.dart';
import 'dart:math';

class OrbitingAvatarsLoader extends StatefulWidget {
  const OrbitingAvatarsLoader({super.key});
  @override
  State<OrbitingAvatarsLoader> createState() => _OrbitingAvatarsLoaderState();
}

class _OrbitingAvatarsLoaderState extends State<OrbitingAvatarsLoader> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  double _orbitAngle = 0.0;
  final List<String> avatars = [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar4.png',
    'assets/avatar5.png',
    'assets/avatar6.png',
  ];
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startOrbitAnimation();
  }
  void _startOrbitAnimation() {
    const double baseSpeed = 0.012;
    const Duration frameDuration = Duration(milliseconds: 16);
    void tick() {
      if (!mounted) return;
      _orbitAngle += baseSpeed;
      if (_orbitAngle > 2 * pi) {
        _orbitAngle -= 2 * pi;
      }
      setState(() {});
      Future.delayed(frameDuration, tick);
    }
    tick();
  }
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  Offset calculateOrbitPosition(double angle, double radius) {
    return Offset(radius * cos(angle), radius * sin(angle));
  }
  Widget _framedMemoji(String path) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFFF3E0E6),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: AssetImage(path),
        backgroundColor: Colors.black,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 320,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(320, 320),
                  painter: DottedCirclePainter(),
                ),
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6EC7).withOpacity(0.4),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6EC7).withOpacity(0.85),
                    ),
                  ),
                ),
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFB3E6).withOpacity(0.2),
                  ),
                ),
                for (int i = 0; i < 3; i++)
                  Transform.translate(
                    offset: calculateOrbitPosition(
                        _orbitAngle + (i * 2 * pi / 3), 160),
                    child: _framedMemoji(avatars[i]),
                  ),
                for (int i = 0; i < 2; i++)
                  Transform.translate(
                    offset: calculateOrbitPosition(
                        -_orbitAngle + (i * pi), 112),
                    child: _framedMemoji(avatars[3 + i]),
                  ),
                Transform.translate(
                  offset: calculateOrbitPosition(_orbitAngle, 86),
                  child: _framedMemoji(avatars[5]),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E0E6),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/center_memoji.png'),
                    backgroundColor: Color(0xFF33272D),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _expandTelegramWebApp();
    // Авто‑переход через 2.5 сек
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_navigated) _navigateToWelcome();
    });
    // Дублируем expand после построения первого кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        TelegramWebAppService.expand();
      } catch (_) {}
    });
  }

  void _expandTelegramWebApp() {
    // Открываем Mini App на весь экран
    try {
      TelegramWebAppService.expand();
      TelegramWebAppService.ready();
      TelegramWebAppService.disableVerticalSwipe();
    } catch (_) {}
  }

  void _navigateToWelcome() {
    print('DEBUG: Переход к WelcomeScreen');
    _navigated = true;
    
    try {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
      print('DEBUG: Навигация к WelcomeScreen выполнена');
    } catch (e) {
      print('DEBUG: Ошибка при навигации к WelcomeScreen: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const OrbitingAvatarsLoader(),
          
          // Кнопка пропуска - поднята на 10% от экрана
          Positioned(
            top: MediaQuery.of(context).size.height * 0.10, // 10% от экрана (было 20%)
            right: 16,
            child: GestureDetector(
              onTap: _navigateToWelcome,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Пропустить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'NauryzKeds',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 