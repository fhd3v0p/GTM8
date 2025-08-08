import 'package:flutter/material.dart';
import '../models/master_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../services/telegram_webapp_service.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;

class MasterDetailScreen extends StatefulWidget {
  final MasterModel master;
  const MasterDetailScreen({super.key, required this.master});

  @override
  State<MasterDetailScreen> createState() => _MasterDetailScreenState();
}

class _MasterDetailScreenState extends State<MasterDetailScreen> {
  int? _galleryIndex;
  double? _averageRating;
  int? _votes;
  int? _userRating;
  bool _isLoadingRating = true;
  String? _testUserId;
  String? _testPromo;
  String? _testMasterName;

  @override
  void initState() {
    super.initState();
    _fetchRating();
    TelegramWebAppService.disableVerticalSwipe();
  }

  Future<void> _fetchRating() async {
    setState(() { _isLoadingRating = true; });
    try {
      final masterId = widget.master.name;
      // Получаем рейтинг артиста через наш API → RPC get_artist_rating
      final response = await http.get(
        Uri.parse('${ApiConfig.ratingApiBaseUrl}/api/get-rating/$masterId'),
        headers: ApiConfig.ratingApiHeaders,
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        // Ожидаем от RPC поля average_rating и total_ratings
        final avg = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
        final votes = data['total_ratings'] is int
            ? data['total_ratings'] as int
            : int.tryParse('${data['total_ratings']}') ?? 0;
        setState(() {
          _averageRating = avg;
          _votes = votes;
          _userRating = null;
        });
      }
    } catch (e) {
      print('Error fetching rating: $e');
    } finally {
      setState(() { _isLoadingRating = false; });
    }
  }

  Future<void> _setRating(int rating) async {
    final userId = TelegramWebAppService.getUserId() ?? '';
    final masterId = widget.master.name;
    
    if (userId.isEmpty) {
      TelegramWebAppService.showAlert('❌ Ошибка: не удалось определить пользователя');
      return;
    }
    
    try {
      setState(() { _isLoadingRating = true; });
      
      // Отправляем рейтинг через API бота
      final response = await http.post(
        Uri.parse('${ApiConfig.ratingApiBaseUrl}/api/rate-artist'),
        headers: ApiConfig.ratingApiHeaders,
        body: jsonEncode({
          'artist_name': masterId,
          'user_id': userId,
          'rating': rating,
          'comment': '',
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Обновляем локальные данные
          setState(() {
            _userRating = rating;
            final stats = data['stats'];
            if (stats != null) {
              _averageRating = (stats['average_rating'] as num?)?.toDouble();
              _votes = stats['total_ratings'] as int?;
            }
          });
          
          TelegramWebAppService.showAlert('✅ Спасибо за вашу оценку!');
          
          // Перезагружаем рейтинг для актуальных данных
          _fetchRating();
        } else {
          TelegramWebAppService.showAlert('❌ Ошибка: ${data['error'] ?? 'Неизвестная ошибка'}');
        }
      } else {
        TelegramWebAppService.showAlert('❌ Ошибка сети: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting rating: $e');
      TelegramWebAppService.showAlert('❌ Ошибка при отправке оценки');
    } finally {
      setState(() { _isLoadingRating = false; });
    }
  }

  void _openGallery(int index) {
    setState(() {
      _galleryIndex = index;
    });
  }

  void _closeGallery() {
    setState(() {
      _galleryIndex = null;
    });
  }

  void _prevPhoto() {
    if (_galleryIndex != null && _galleryIndex! > 0) {
      setState(() {
        _galleryIndex = _galleryIndex! - 1;
      });
    }
  }

  void _nextPhoto() {
    if (_galleryIndex != null && _galleryIndex! < widget.master.gallery.length - 1) {
      setState(() {
        _galleryIndex = _galleryIndex! + 1;
      });
    }
  }

  // Для аватара с обводкой
  Widget buildAvatar(String avatarPath, double radius) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: Color(0xFFF3E0E6), // фон как на MasterCloudScreen
      ),
      child: ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          child: avatarPath.startsWith('assets/') 
            ? Image.asset(
                avatarPath,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
                fit: BoxFit.cover,
              )
            : Image.network(
                avatarPath,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: radius * 2,
                  height: radius * 2,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white54,
                      size: 32,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: radius * 2,
                    height: radius * 2,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6EC7),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                fit: BoxFit.cover,
              ),
        ),
      ),
    );
  }

  String _getOrCreatePromo(String userId, String masterName) {
    final key = 'promo_GTM_${userId}_$masterName';
    final existing = html.window.localStorage[key];
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    // Генерируем новый промокод
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = (List.generate(3, (i) => chars[(DateTime.now().millisecondsSinceEpoch + i * 17) % chars.length])).join();
    final promo = 'GTM-NEW7$rand';
    html.window.localStorage[key] = promo;
    return promo;
  }

  String buildBookingMessage(String masterName, String promocode) {
    return 'Привет, $masterName! 🖤 Я из GOTHAM\'S TOP MODEL и хочу записаться к тебе ✨. Вот мой промокод на 8% скидки: $promocode 💎';
  }

  @override
  Widget build(BuildContext context) {
    final master = widget.master;
    final userId = TelegramWebAppService.getUserId() ?? '';
    final masterName = master.name;
    final promocode = _getOrCreatePromo(userId, masterName);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- ФОН: master_detail_back_banner ---
          Positioned.fill(
            child: Image.asset(
              'assets/master_detail_back_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          // --- ЗАТЕМНЕНИЕ 10% ПОД ЛОГО, НО НАД ФОНОМ ---
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.10),
            ),
          ),
          // --- ЛОГО БАННЕР: master_detail_logo_banner ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/master_detail_logo_banner.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          // --- КОНТЕНТ (dark boxes) ---
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) => true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    // --- ВЕРХНЯЯ ТЁМНАЯ РАМКА с соцсетями и кнопкой ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: Row(
                              children: [
                                buildAvatar(master.avatar, 38),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        master.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'NauryzKeds',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      _isLoadingRating
                                          ? const SizedBox(height: 32)
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Звезды рейтинга (интерактивные)
                                                Row(
                                                  children: [
                                                    for (int i = 1; i <= 5; i++)
                                                      GestureDetector(
                                                        onTap: _isLoadingRating ? null : () => _setRating(i),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 200),
                                                          child: Icon(
                                                            Icons.star,
                                                            color: i <= (_userRating ?? (_averageRating ?? 0).round())
                                                                ? Color(0xFFFF6EC7)
                                                                : Colors.white24,
                                                            size: 28,
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(width: 8),
                                                    if (_isLoadingRating)
                                                      SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6EC7)),
                                                        ),
                                                      )
                                                    else
                                                      Text(
                                                        'Нажмите звезду',
                                                        style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                          fontFamily: 'OpenSans',
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                // Средний рейтинг и количество голосов
                                                if (_averageRating != null && _votes != null && _votes! > 0)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        _averageRating!.toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          color: Color(0xFFFF6EC7),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          fontFamily: 'OpenSans',
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '(${_votes} ${_votes == 1 ? 'оценка' : _votes! < 5 ? 'оценки' : 'оценок'})',
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 14,
                                                          fontFamily: 'OpenSans',
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                else
                                                  Text(
                                                    'Пока нет оценок',
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                      fontFamily: 'OpenSans',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: _SocialButton(
                              icon: Icons.telegram,
                              label: master.telegram ?? '',
                              url: master.telegramUrl ?? '',
                              color: Color(0xFF229ED9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: _SocialButton(
                              icon: Icons.music_note,
                              label: master.tiktok ?? '',
                              url: master.tiktokUrl ?? '',
                              color: Color(0xFF010101),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: _SocialButton(
                              icon: Icons.push_pin,
                              label: master.pinterest ?? '',
                              url: master.pinterestUrl ?? '',
                              color: Color(0xFFE60023),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Кнопка записаться — стиль как активная кнопка (градиент)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0),
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () async {
                                final userId = TelegramWebAppService.getUserId();
                                final masterName = master.name;
                                if (userId == null || userId.isEmpty) {
                                  // обработка ошибки
                                  print('Ошибка: userId пустой!');
                                  return;
                                }
                                final promocode = _getOrCreatePromo(userId, masterName);
                                print('userId: $userId, masterName: $masterName, promocode: $promocode');
                                setState(() {
                                  _testUserId = userId;
                                  _testPromo = promocode;
                                  _testMasterName = masterName;
                                });
                                final message = buildBookingMessage(master.name, promocode);
                                final baseUrl = master.bookingUrl != null && master.bookingUrl!.isNotEmpty
                                    ? master.bookingUrl!
                                    : 'https://t.me/GTM_ADM?text=${Uri.encodeComponent("Привет! Хочу узнать условия размещения в приложении для креаторов. Спасибо!")}';
                                // --- Исправлено: ручное кодирование текста ---
                                final encodedMessage = Uri.encodeComponent(message);
                                final finalUrl = '$baseUrl?text=$encodedMessage';
                                await launchUrl(Uri.parse(finalUrl));
                                // --- конец исправления ---
                                // Логируем использование промокода в БД
                                try {
                                  final response = await http.post(
                                    Uri.parse('${ApiConfig.apiBaseUrl}/promocode_usage'),
                                    headers: ApiConfig.headers,
                                    body: jsonEncode({
                                      'user_id': userId,
                                      'promocode': promocode,
                                      'master_name': masterName,
                                      'timestamp': DateTime.now().toIso8601String(),
                                    }),
                                  );
                                  if (response.statusCode == 201) {
                                    print('Промокод успешно залогирован');
                                  }
                                } catch (e) {
                                  print('Ошибка логирования промокода: $e');
                                }
                              },
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.zero,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFFFE3F3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Color(0xFFFF6EC7),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Записаться',
                                    style: TextStyle(
                                      color: Color(0xFFFF6EC7),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SFProDisplay',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // BIO блок
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BIO',
                            style: TextStyle(
                              color: Color(0xFFFF6EC7),
                              fontFamily: 'NauryzKeds',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            master.bio ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'OpenSans',
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- ЛОКАЦИЯ ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.white24, width: 1), // добавили белую/серую рамку
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFFF6EC7)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: 'NauryzKeds',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  master.locationHtml ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- КАЛЕНДАРЬ ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: Colors.white24, width: 1), // добавили белую/серую рамку
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFFFF6EC7), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Booking calendar\nComing soon',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16,
                                fontFamily: 'NauryzKeds',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // --- ГАЛЕРЕЯ ---
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.zero,
                        // border убран
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Галерея работ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'NauryzKeds',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: master.gallery.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                return GestureDetector(
                                  onTap: () => _openGallery(i),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: Image.network(
                                      master.gallery[i],
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white54,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFFF6EC7),
                                            ),
                                          ),
                                        );
                                      },
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- Модальное окно просмотра фото ---
          if (_galleryIndex != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.18),
              ),
            ),
          if (_galleryIndex != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.92),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          master.gallery[_galleryIndex!],
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.7,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white54,
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Изображение недоступно',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: MediaQuery.of(context).size.height * 0.7,
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6EC7),
                                  strokeWidth: 3,
                                ),
                              ),
                            );
                          },
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.height * 0.7,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 32,
                      right: 24,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
                        onPressed: _closeGallery,
                        splashRadius: 28,
                      ),
                    ),
                    if (_galleryIndex! > 0)
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 38),
                            onPressed: _prevPhoto,
                            splashRadius: 28,
                          ),
                        ),
                      ),
                    if (_galleryIndex! < master.gallery.length - 1)
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 38),
                            onPressed: _nextPhoto,
                            splashRadius: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Кнопка назад — теперь в самом конце, поверх всего
          Positioned(
            top: 51,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).maybePop(),
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (url.isNotEmpty) {
          await launchUrl(Uri.parse(url));
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'NauryzKeds',
            ),
          ),
        ],
      ),
    );
  }
}
