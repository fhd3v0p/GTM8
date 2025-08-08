import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/master_detail_screen.dart';
import '../screens/master_products_screen.dart';
import '../models/master_model.dart';
import '../services/api_service.dart';
import '../services/artists_service.dart';
import 'dart:math';
import '../services/telegram_webapp_service.dart';
import '../models/product_model.dart';
import '../models/categories.dart';

class MasterCloudScreen extends StatefulWidget {
  // Используем категории из синхронизированного файла
  static List<String> get categories => MasterCloudCategories.categories;
  static List<String> get productCategories => MasterCloudCategories.productCategories;
  static List<String> get serviceCategories => MasterCloudCategories.serviceCategories;

  final String city;
  const MasterCloudScreen({super.key, required this.city});

  @override
  State<MasterCloudScreen> createState() => _MasterCloudScreenState();
}

class _MasterCloudScreenState extends State<MasterCloudScreen> {
  String selectedCategory = 'Tattoo';

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _isPaused = false;

  static List<MasterModel>? _cachedMasters; // Кэш мастеров
  List<MasterModel> masters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _loadMasters();
    TelegramWebAppService.disableVerticalSwipe();
  }

  Future<void> _loadMasters() async {
    print('DEBUG: Начинаем загрузку мастеров');
    
    // Принудительно очищаем кэш ArtistsService чтобы применить новые категории
    ArtistsService.forceClearCache();
    
    // ВРЕМЕННО: Принудительно очищаем локальный кэш для применения новых категорий
    _cachedMasters = null;
    
    // Убираем использование локального кэша для тестирования категорий
    // if (_cachedMasters != null) {
    //   print('DEBUG: Используем кэшированные данные');
    //   setState(() {
    //     masters = _cachedMasters!;
    //     _loading = false;
    //   });
    //   return;
    // }
    
    try {
      // Сначала пытаемся загрузить из Supabase с фильтрацией по городу
      print('DEBUG: Загружаем мастеров из Supabase для города: ${widget.city}');
      final supabaseMasters = await ArtistsService.getArtistsByCity(widget.city);
      
      if (supabaseMasters.isNotEmpty) {
        print('DEBUG: Загружено из Supabase: ${supabaseMasters.length} мастеров');
        
        if (!mounted) return;
        setState(() {
          masters = supabaseMasters;
          _loading = false;
        });
        _cachedMasters = supabaseMasters;
        return;
      }
    } catch (e) {
      print('DEBUG: Ошибка загрузки из Supabase: $e');
    }
    
    try {
      // Fallback: загружаем через старый API
      print('DEBUG: Fallback - загружаем через старый API...');
      final loadedData = await ApiService.getMasters();
      
      if (loadedData.isNotEmpty) {
        print('DEBUG: Загружено с сервера: ${loadedData.length} мастеров');
        
        // Конвертируем Map<String, dynamic> в MasterModel
        final loadedMasters = loadedData.map((data) => MasterModel.fromApiData(data)).toList();
        
        if (!mounted) return;
        setState(() {
          masters = loadedMasters;
          _loading = false;
        });
        _cachedMasters = loadedMasters;
        return;
      }
    } catch (e) {
      print('DEBUG: Ошибка загрузки с сервера: $e');
    }
    
    // Fallback: загружаем из папок
    final artistFolders = [
      'assets/artists/Lin++',
      'assets/artists/Blodivamp',
      'assets/artists/EMI',
      'assets/artists/Чучундра',
      'assets/artists/Клубника',
      'assets/artists/msk_tattoo_EMI',
      'assets/artists/msk_tattoo_Alena',
      'assets/artists/alena',
      'assets/artists/aspergill',
      'assets/artists/naidi',
      'assets/artists/MurderDoll',
    ];
    print('DEBUG: Fallback - загружаем из папок: $artistFolders');
    final results = await Future.wait(
      artistFolders.map((folder) => MasterModel.fromArtistFolder(folder).catchError((e) {
        print('DEBUG: Ошибка загрузки из $folder: $e');
        return null;
      })),
    );
    var loaded = results.whereType<MasterModel>().toList();
    print('DEBUG: Загружено мастеров из папок: ${loaded.length}');
    
    // Если не удалось загрузить из папок, используем sample data
    if (loaded.isEmpty) {
      print('DEBUG: Используем sample data');
      loaded = MasterModel.sampleData;
    }
    
    if (!mounted) return;
    setState(() {
      masters = loaded;
      _loading = false;
    });
    _cachedMasters = loaded;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isPaused) return;
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final newScroll = currentScroll + 1.0;
        if (newScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(newScroll);
        }
      }
    });
  }

  void _pauseAutoScroll() {
    if (!mounted) return;
    setState(() {
      _isPaused = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isPaused = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _MasterCloudLoadingScreen();
    }
    final filtered = masters.where((m) {
      final categoryMatch = m.category.toLowerCase() == selectedCategory.toLowerCase() || selectedCategory == '';
      // Более гибкая фильтрация по городу - если город пустой или содержит название
      final cityMatch = widget.city == '' || m.city == '' || 
                       m.city.toLowerCase().contains(widget.city.toLowerCase()) ||
                       widget.city.toLowerCase().contains(m.city.toLowerCase());
      print('DEBUG: Мастер ${m.name} - категория: ${m.category} (${categoryMatch}), город: ${m.city} vs ${widget.city} (${cityMatch})');
      return categoryMatch && cityMatch;
    }).toList();
    print('DEBUG: Отфильтровано мастеров: ${filtered.length}');
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = (screenWidth - 24 * 2 - 40) / 3 * 0.7; // уменьшили на 30%

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/master_cloud_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
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
                const SizedBox(height: 64), // Было 48, увеличил чтобы не перекрывать стрелку
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: MasterCloudScreen.categories.length,
                    itemBuilder: (context, index) {
                      final cat = MasterCloudScreen.categories[index];
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = cat);
                            _pauseAutoScroll();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontFamily: 'NauryzKeds',
                                  fontSize: 20,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: GridView.builder(
                      clipBehavior: Clip.none,
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        return GestureDetector(
                          onTap: () {
                            // Проверяем, является ли категория товарной
                            if (MasterCloudCategories.isProductCategory(selectedCategory)) {
                              // Для товарных категорий переходим на список товаров мастера
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MasterProductsScreen(
                                    master: m,
                                    category: selectedCategory,
                                  ),
                                ),
                              );
                            } else {
                              // Для услуг переходим на детальную страницу мастера
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MasterDetailScreen(master: m),
                                ),
                              );
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  color: Color(0xFFF3E0E6), // фон для PNG
                                ),
                                child: CircleAvatar(
                                  backgroundImage: m.avatar.startsWith('assets/') 
                                    ? AssetImage(m.avatar) 
                                    : NetworkImage(m.avatar) as ImageProvider,
                                  radius: avatarSize / 2.3,
                                  backgroundColor: Colors.transparent,
                                  onBackgroundImageError: (exception, stackTrace) {
                                    print('❌ Ошибка загрузки аватара для ${m.name}: $exception');
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Вместо обычного Text(m.name)
                              SizedBox(
                                height: 22,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    m.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'NauryzKeds',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

// Добавьте extension для copyWith
extension MasterModelCopy on MasterModel {
  MasterModel copyWith({
    String? name,
    String? city,
    String? category,
    String? avatar,
    String? telegram,
    String? instagram,
    String? tiktok,
    List<String>? gallery,
  }) {
    return MasterModel(
      id: this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      category: category ?? this.category,
      avatar: avatar ?? this.avatar,
      telegram: telegram ?? this.telegram,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      gallery: gallery ?? this.gallery,
    );
  }
}

class _MasterCloudLoadingScreen extends StatefulWidget {
  const _MasterCloudLoadingScreen();
  @override
  State<_MasterCloudLoadingScreen> createState() => _MasterCloudLoadingScreenState();
}
class _MasterCloudLoadingScreenState extends State<_MasterCloudLoadingScreen> with TickerProviderStateMixin {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
      ),
    );
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
}

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
