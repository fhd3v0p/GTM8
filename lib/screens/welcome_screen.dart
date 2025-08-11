import 'dart:math';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'giveaway_screen.dart';
 

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  final List<String> avatars = [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar4.png',
    'assets/avatar5.png',
    'assets/avatar6.png',
  ];

  double _sliderProgress = 0.0;
  double _orbitAngle = 0.0;

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
    const double baseSpeed = 0.009;
    const double maxAdditionalSpeed = 0.01;
    const Duration frameDuration = Duration(milliseconds: 16);

    void tick() {
      if (!mounted) return;
      final double speed = baseSpeed + (_sliderProgress * maxAdditionalSpeed);
      _orbitAngle += speed;
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

  // удален кастомный обработчик drag — используем чистый SlideAction

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 5), // отступ сверху 5мм
                SizedBox(
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
                              child: framedMemoji(avatars[i]),
                            ),
                          for (int i = 0; i < 2; i++)
                            Transform.translate(
                              offset: calculateOrbitPosition(
                                  -_orbitAngle + (i * pi), 112),
                              child: framedMemoji(avatars[3 + i]),
                            ),
                          Transform.translate(
                            offset: calculateOrbitPosition(_orbitAngle, 86),
                            child: framedMemoji(avatars[5]),
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
                const SizedBox(height: 32),
                const Text(
                  "GOTHAM'S",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 37, // уменьшено в 2 раза с 74
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NauryzKeds',
                  ),
                ),
                const SizedBox(height: 0.25), // уменьшено в 4 раза с 1
                const Text(
                  'TOP MODEL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 37, // уменьшено в 2 раза с 74
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NauryzKeds',
                  ),
                ),
                const SizedBox(height: 1.5), // уменьшено в 4 раза с 6
                const Text(
                  'Find smarter, connect faster with AI search!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16, // уменьшено с 20 для более тонкого вида
                    color: Colors.white70,
                    fontWeight: FontWeight.w300, // тонкий шрифт
                  ),
                ),
                const SizedBox(height: 15), // отступ снизу до слайдера увеличен в 3 раза (было 5, стало 15)
                SlideAction(
                  text: 'Проведите для начала',
                  textStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 20,
                  ),
                  outerColor: Colors.white70.withOpacity(0.35),
                  innerColor: Colors.white,
                  sliderButtonIcon: Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFFF6EC7),
                  ),
                  elevation: 0,
                  borderRadius: 50,
                  sliderRotate: false,
                  onSubmit: () {
                    print('DEBUG: Слайдер завершен, переход к GiveawayScreen');
                    Future.microtask(() {
                      try {
                        navigateWithFadeReplacement(context, const GiveawayScreen());
                        print('DEBUG: Навигация к GiveawayScreen выполнена');
                      } catch (e) {
                        print('DEBUG: Ошибка при навигации к GiveawayScreen: $e');
                      }
                    });
                    return null;
                  },
                ),
                const SizedBox(height: 5), // отступ снизу от края до нижней границы слайдера 5мм
              ],
          ),
        ),
      ),
    );
  }

  Widget framedMemoji(String path) {
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
}

// Исправленный DottedCirclePainter (без дублирования и ошибок)
class DottedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 5;
    const double dashSpace = 5;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final circumference = 2 * pi * radius;
    final dashCount = circumference ~/ (dashWidth + dashSpace);
    final adjustedDashAngle = 2 * pi / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * adjustedDashAngle;
      final x1 = radius + radius * cos(startAngle);
      final y1 = radius + radius * sin(startAngle);
      final x2 = radius + radius * cos(startAngle + adjustedDashAngle / 2);
      final y2 = radius + radius * sin(startAngle + adjustedDashAngle / 2);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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