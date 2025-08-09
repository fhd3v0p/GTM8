import 'dart:math';
import 'package:flutter/material.dart';
import 'master_cloud_screen.dart';
import '../services/telegram_webapp_service.dart';
import '../services/artists_service.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CityPoint {
  final String name;
  final double dx;
  final double dy;
  final double size;
  final String abbr;
  final int population;

  _CityPoint(this.name, this.dx, this.dy, this.size, this.abbr, this.population);
}

class _CitySelectionScreenState extends State<CitySelectionScreen> with SingleTickerProviderStateMixin {
  String? _selectedCity;
  late final AnimationController _controller;
  List<_CityPoint> _cities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    TelegramWebAppService.disableVerticalSwipe();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      print('DEBUG: Загружаем города из Supabase');
      final citiesData = await ArtistsService.getCities();
      
      if (citiesData.isNotEmpty) {
        // Используем наши фиксированные координаты
        final cityPositions = {
          'Москва': _CityPoint('Москва', 0.5, 0.5, 100.0, 'MSC', 0), // +25% (80 * 1.25 = 100)
          'Санкт-Петербург': _CityPoint('Санкт-Петербург', 0.22, 0.23, 92.0, 'SPB', 0), // +15% (80 * 1.15 = 92)
          'Новосибирск': _CityPoint('Новосибирск', 0.5, 0.73, 80.0, 'NSK', 0),
          'Казань': _CityPoint('Казань', 0.73, 0.60, 80.0, 'KAZ', 0),
          'Екатеринбург': _CityPoint('Екатеринбург', 0.80, 0.73, 80.0, 'EKB', 0),
        };
        
        final cities = <_CityPoint>[];
        for (final city in citiesData) {
          final name = city['name'] as String;
          final cityPoint = cityPositions[name];
          if (cityPoint != null) {
            cities.add(cityPoint);
          }
        }
        
        // Если нет совпадений, используем fallback
        final finalCities = cities.isNotEmpty ? cities : _createCitiesInCircle();
        
        setState(() {
          _cities = finalCities;
          _loading = false;
        });
        
        print('DEBUG: Загружено ${finalCities.length} городов из Supabase');
      } else {
        // Fallback на статические города если Supabase пустой
        _loadFallbackCities();
      }
    } catch (e) {
      print('DEBUG: Ошибка загрузки городов из Supabase: $e');
      _loadFallbackCities();
    }
  }

  void _loadFallbackCities() {
    print('DEBUG: Используем fallback города');
    setState(() {
      _cities = _createCitiesInCircle();
      _loading = false;
    });
  }

  List<_CityPoint> _createCitiesInCircle() {
    // Используем координаты из вашего кода с обновленными размерами
    return [
      _CityPoint('Москва', 0.5, 0.5, 100.0, 'MSC', 0), // +25%
      _CityPoint('Санкт-Петербург', 0.22, 0.23, 92.0, 'SPB', 0), // +15%
      _CityPoint('Новосибирск', 0.5, 0.73, 80.0, 'NSK', 0),
      _CityPoint('Казань', 0.73, 0.60, 80.0, 'KAZ', 0),
      _CityPoint('Екатеринбург', 0.80, 0.73, 80.0, 'EKB', 0),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void navigateWithCircularLoading(BuildContext context, Widget page) async {
    // Показать такой же лоадер, как на welcome/master cloud
    await Navigator.of(context).push(
      PageRouteBuilder(opaque: false, pageBuilder: (_, __, ___) => const _CityLoadingOverlay()),
    );
    // После короткой имитации перехода — открыть экран
    // Примечание: _CityLoadingOverlay сам закрывается через 1.8с
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_loading) {
      return const _CityInlineLoader();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF232026),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/city_selection_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.18),
            ),
          ),
          // Кнопка назад
          Positioned(
            top: 36,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).maybePop(),
              splashRadius: 24,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48), // Отступ для кнопки назад
                Expanded(
                  child: Stack(
                    children: [

                      ..._cities.map((city) {
                        final double citySize = city.size * 1.15;
                        final selected = _selectedCity == city.name;
                        final bool dimmed = _selectedCity != null && !selected;
                        return Positioned(
                          left: city.dx * width - citySize / 2,
                          top: city.dy * (height - 120) - citySize / 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCity = city.name;
                              });
                            },
                            child: Column(
                              children: [
                                Opacity(
                                  opacity: dimmed ? 0.18 : 1,
                                  child: !selected
                                      ? AnimatedBuilder(
                                          animation: _controller,
                                          builder: (context, child) {
                                            final double stroke = citySize / 13;
                                            final double paintSize = citySize + stroke * 2;
                                            return SizedBox(
                                              width: paintSize,
                                              height: paintSize,
                                              child: CustomPaint(
                                                painter: DottedCirclePainter(
                                                  color: Colors.white.withOpacity(0.85),
                                                  circleSize: citySize,
                                                  animationValue: _controller.value,
                                                ),
                                                child: Center(
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 180),
                                                    width: citySize,
                                                    height: citySize,
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFFF6EC7), Color(0xFFFFB3E6)],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Transform.translate(
                                                        offset: Offset(0, citySize * 0.05),
                                                        child: Text(
                                                          city.abbr,
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: citySize / 2.2,
                                                            fontFamily: 'NauryzKeds',
                                                            letterSpacing: 1,
                                                            height: 1,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          width: citySize + 18,
                                          height: citySize + 18,
                                          decoration: BoxDecoration(
                                            color: Colors.white, // как у активной кнопки "Далее"
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFFF6EC7), // розовая окантовка как у активной кнопки
                                              width: 5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF6EC7).withOpacity(0.15),
                                                blurRadius: 18,
                                                spreadRadius: 4,
                                              )
                                            ],
                                          ),
                                          child: Center(
                                            child: Transform.translate(
                                              offset: Offset(0, citySize * 0.05),
                                              child: Text(
                                                city.abbr,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black, // как у активной кнопки "Далее"
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: citySize / 2.2,
                                                  fontFamily: 'NauryzKeds',
                                                  letterSpacing: 1,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 8),
                                if (selected) ...[
                                  Text(
                                    city.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'NauryzKeds',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: GestureDetector(
                    onTap: _selectedCity == null
                        ? null
                        : () {
                            print('DEBUG: Переход к MasterCloudScreen с городом: $_selectedCity');
                            try {
                              navigateWithCircularLoading(
                                context,
                                MasterCloudScreen(city: _selectedCity!),
                              );
                              print('DEBUG: Навигация выполнена успешно');
                            } catch (e) {
                              print('DEBUG: Ошибка при навигации: $e');
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero, // острые углы
                        color: _selectedCity != null
                            ? Colors.white // выбран — белый фон
                            : Colors.white.withOpacity(0.08), // не выбран — прозрачный
                        border: Border.all(
                          color: _selectedCity != null
                              ? const Color(0xFFFF6EC7) // выбран — розовая окантовка
                              : Colors.white, // не выбран — белая окантовка
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Далее',
                          style: TextStyle(
                            color: _selectedCity != null
                                ? Colors.black // выбран — чёрный текст
                                : Colors.white.withOpacity(0.5), // не выбран — белый полупрозрачный
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NauryzKeds',
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CityLoadingOverlay extends StatefulWidget {
  const _CityLoadingOverlay();
  @override
  State<_CityLoadingOverlay> createState() => _CityLoadingOverlayState();
}

class _CityLoadingOverlayState extends State<_CityLoadingOverlay> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  double _orbitAngle = 0.0;
  final List<String> avatars = const [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar7.png',
    'assets/avatar5.png',
    'assets/avatar6.png',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _startOrbitAnimation();
    Future.delayed(const Duration(milliseconds: 1800), () => mounted ? Navigator.of(context).pop() : null);
  }

  void _startOrbitAnimation() {
    const double baseSpeed = 0.012;
    const Duration frameDuration = Duration(milliseconds: 16);
    void tick() {
      if (!mounted) return;
      _orbitAngle += baseSpeed;
      if (_orbitAngle > 2 * pi) _orbitAngle -= 2 * pi;
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

  Offset _pos(double angle, double radius) => Offset(radius * cos(angle), radius * sin(angle));

  Widget _framedMemoji(String path) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Color(0xFFF3E0E6), shape: BoxShape.circle),
      child: CircleAvatar(radius: 20, backgroundImage: AssetImage(path), backgroundColor: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: SizedBox(
          width: 320,
          height: 320,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: const Size(320, 320), painter: DottedCirclePainter(color: Colors.white.withOpacity(0.7), circleSize: 180, animationValue: _pulseController.value)),
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(width: 224, height: 224, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6EC7).withOpacity(0.4))),
                  ),
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6EC7).withOpacity(0.85))),
                  ),
                  for (int i = 0; i < 3; i++)
                    Transform.translate(offset: _pos(_orbitAngle + (i * 2 * pi / 3), 160), child: _framedMemoji(avatars[i])),
                  for (int i = 0; i < 2; i++)
                    Transform.translate(offset: _pos(-_orbitAngle + (i * pi), 112), child: _framedMemoji(avatars[3 + i])),
                  Transform.translate(offset: _pos(_orbitAngle, 86), child: _framedMemoji('assets/avatar7.png')),
                  // Центр мемоджи
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
      ),
    );
  }
}

class _CityInlineLoader extends StatefulWidget {
  const _CityInlineLoader();
  @override
  State<_CityInlineLoader> createState() => _CityInlineLoaderState();
}

class _CityInlineLoaderState extends State<_CityInlineLoader> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  double _orbitAngle = 0.0;
  final List<String> avatars = const [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar7.png',
    'assets/avatar5.png',
    'assets/avatar6.png',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _startOrbitAnimation();
  }

  void _startOrbitAnimation() {
    const double baseSpeed = 0.012;
    const Duration frameDuration = Duration(milliseconds: 16);
    void tick() {
      if (!mounted) return;
      _orbitAngle += baseSpeed;
      if (_orbitAngle > 2 * pi) _orbitAngle -= 2 * pi;
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

  Offset _pos(double angle, double radius) => Offset(radius * cos(angle), radius * sin(angle));
  Widget _framedMemoji(String path) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Color(0xFFF3E0E6), shape: BoxShape.circle),
      child: CircleAvatar(radius: 20, backgroundImage: AssetImage(path), backgroundColor: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232026),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 320,
              height: 320,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
              return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(size: const Size(320, 320), painter: DottedCirclePainter(color: Colors.white.withOpacity(0.7), circleSize: 180, animationValue: _pulseController.value)),
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(width: 224, height: 224, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6EC7).withOpacity(0.4))),
                      ),
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6EC7).withOpacity(0.85))),
                      ),
                      for (int i = 0; i < 3; i++)
                        Transform.translate(offset: _pos(_orbitAngle + (i * 2 * pi / 3), 160), child: _framedMemoji(avatars[i])),
                      for (int i = 0; i < 2; i++)
                        Transform.translate(offset: _pos(-_orbitAngle + (i * pi), 112), child: _framedMemoji(avatars[3 + i])),
                  Transform.translate(offset: _pos(_orbitAngle, 86), child: _framedMemoji('assets/avatar7.png')),
                  // Центр мемоджи
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
            const SizedBox(height: 16),
            const Text(
              'Загружаем города...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'NauryzKeds',
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedCirclePainter extends CustomPainter {
  final Color color;
  final double circleSize;
  final double animationValue;

  DottedCirclePainter({
    required this.color,
    required this.circleSize,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double dashWidth = circleSize / 6;
    final double dashSpace = circleSize / 6;
    // Линия тоньше в 6 раз
    final double stroke = circleSize / 78;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final circumference = 2 * pi * radius;
    double distance = 0;

    final double startRotation = 2 * pi * animationValue;

    while (distance < circumference) {
      final startAngle = startRotation + distance / radius;
      final endAngle = startRotation + (distance + dashWidth) / radius;
      canvas.drawLine(
        center.translate(radius * cos(startAngle), radius * sin(startAngle)),
        center.translate(radius * cos(endAngle), radius * sin(endAngle)),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DottedCirclePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.circleSize != circleSize ||
        oldDelegate.color != color;
  }
}