import 'package:flutter/material.dart';
import 'dart:async';
import '../models/master_model.dart';
import 'package:url_launcher/url_launcher.dart';
// Removed direct dart:html usage to keep iOS/Android builds working
import 'package:shared_preferences/shared_preferences.dart';
import '../services/telegram_webapp_service.dart';
import '../services/api_service.dart';
import '../services/supabase_artists_service.dart';

class MasterDetailScreen extends StatefulWidget {
  final MasterModel master;
  const MasterDetailScreen({super.key, required this.master});

  @override
  State<MasterDetailScreen> createState() => _MasterDetailScreenState();
}

class _MasterDetailScreenState extends State<MasterDetailScreen> with SingleTickerProviderStateMixin {
  int? _galleryIndex;
  double? _averageRating;
  int? _votes;
  int? _userRating;
  bool _isLoadingRating = true;
  
  // Booking calendar state
  bool _showBooking = false;
  String? _selectedCityCode;
  DateTime? _selectedDate;
  String? _selectedTime;
  final DateTime _today = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final ScrollController _bookingScrollController = ScrollController();
  // Rating tip typing
  late final AnimationController _typingController;
  final String _ratingTip = 'Оцените';
  bool _tipHidden = false;
  Timer? _tipWaitTimer;
  Timer? _tipHideTimer;
  List<String> _supabaseCityCodes = const [];

  @override
  void initState() {
    super.initState();
    _fetchRating();
    TelegramWebAppService.disableVerticalSwipe();
    _typingController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _typingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait 60s visible, then hide 1s, then restart typing
        _tipWaitTimer?.cancel();
        _tipWaitTimer = Timer(const Duration(minutes: 1), () {
          setState(() {
            _tipHidden = true;
          });
          _tipHideTimer?.cancel();
          _tipHideTimer = Timer(const Duration(seconds: 1), () {
            setState(() {
              _tipHidden = false;
            });
            _typingController.reset();
            _typingController.forward();
          });
        });
      }
    });
    _typingController.forward();
    _loadArtistCityCodes();
  }

  Future<void> _fetchRating() async {
    setState(() { _isLoadingRating = true; });
    try {
      final masterId = widget.master.name;
      final data = await ApiService.getArtistRating(masterId);
      if (!mounted) return;
      if (data != null) {
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
      // ignore: avoid_print
      print('Error fetching rating: $e');
    } finally {
      if (!mounted) return;
      setState(() { _isLoadingRating = false; });
    }
  }

  Future<void> _loadArtistCityCodes() async {
    try {
      final codes = await SupabaseArtistsService.getArtistCityCodes(widget.master.id);
      if (codes.isNotEmpty) {
        // Удаляем дубли, нормализуем в верхний регистр, сохраняем порядок
        final seen = <String>{};
        final distinct = <String>[];
        for (final c in codes) {
          final up = c.toUpperCase();
          if (!seen.contains(up)) {
            seen.add(up);
            distinct.add(up);
          }
        }
        setState(() {
          _supabaseCityCodes = distinct;
          _selectedCityCode ??= distinct.first;
        });
      }
    } catch (_) {}
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
      final Map<String, dynamic>? data = await ApiService.rateArtist(
        artistName: masterId,
        userId: userId,
        rating: rating,
        comment: '',
      );
      if (!mounted) return;
      if (data != null && data['success'] == true) {
        setState(() {
          _userRating = rating;
          final stats = data['stats'];
          if (stats != null) {
            _averageRating = (stats['average_rating'] as num?)?.toDouble();
            _votes = stats['total_ratings'] as int?;
          }
        });
        TelegramWebAppService.showAlert('✅ Спасибо за вашу оценку!');
        _fetchRating();
      } else {
        final err = (data != null)
            ? ((data['error'] as String?) ?? 'Неизвестная ошибка')
            : 'Неизвестная ошибка';
        TelegramWebAppService.showAlert('❌ Ошибка: $err');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error setting rating: $e');
      TelegramWebAppService.showAlert('❌ Ошибка при отправке оценки');
    } finally {
      if (!mounted) return;
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

  @override
  void dispose() {
    _typingController.dispose();
    _tipWaitTimer?.cancel();
    _tipHideTimer?.cancel();
    _bookingScrollController.dispose();
    super.dispose();
  }

  // --- Booking helpers ---
  List<String> _extractCityCodes(String raw) {
    final upper = (raw).toUpperCase();
    final regex = RegExp(r"\b(MSC|SPB|NSK|EKB|KAZ)\b");
    final matches = regex.allMatches(upper).map((m) => m.group(1)!).toSet().toList();
    return matches;
  }

  List<String> _generateTimes() {
    final times = <String>[];
    for (int hour = 10; hour <= 20; hour++) {
      final h = hour.toString().padLeft(2, '0');
      times.add('$h:00');
    }
    return times;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _openBooking([String? code]) {
    setState(() {
      _selectedCityCode = code ?? _selectedCityCode ?? (_extractCityCodes(widget.master.city).isNotEmpty ? _extractCityCodes(widget.master.city).first : null);
      _showBooking = true;
    });
  }

  void _closeBooking() {
    setState(() {
      _showBooking = false;
    });
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday; // 1..7 (Mon..Sun)
    final leadingEmpty = (firstWeekday + 6) % 7; // make Monday=0
    final totalDays = lastDay.day;
    final cells = <Widget>[];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(Container());
    }
    for (int d = 1; d <= totalDays; d++) {
      final date = DateTime(month.year, month.month, d);
      final isPast = date.isBefore(DateTime(_today.year, _today.month, _today.day));
      final isSelected = _selectedDate != null && _isSameDay(_selectedDate!, date);
      cells.add(GestureDetector(
        onTap: isPast ? null : () {
          setState(() {
            _selectedDate = date;
            _selectedTime = null;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6EC7).withOpacity(0.18) : Colors.transparent,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Text(
            '$d',
            style: TextStyle(
              color: isPast ? Colors.white24 : Colors.white,
              fontFamily: 'OpenSans',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ));
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
        padding: const EdgeInsets.all(6),
        children: cells,
      ),
    );
  }

  String _russianMonthName(DateTime date) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[date.month - 1];
  }

  void _changeMonth(int delta) {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + delta, 1);
      // Reset selection when month changes
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  Widget _buildCityChips(List<String> codes, {bool selectable = true}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: codes.map((code) {
        final selected = _selectedCityCode == code;
        return GestureDetector(
          onTap: selectable
              ? () {
                  setState(() {
                    _selectedCityCode = code;
                  });
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFF6EC7).withOpacity(0.15) : Colors.transparent,
              border: Border.all(color: selected ? const Color(0xFFFF6EC7) : Colors.white24, width: 1),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              code,
              style: TextStyle(
                color: selected ? const Color(0xFFFF6EC7) : Colors.white,
                fontFamily: 'NauryzKeds',
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeChips() {
    final times = _generateTimes();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((t) {
        final selected = _selectedTime == t;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = t;
            });
            // После выбора времени — прокрутить вниз, чтобы показать кнопку "Записаться"
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_bookingScrollController.hasClients) {
                _bookingScrollController.animateTo(
                  _bookingScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFF6EC7).withOpacity(0.15) : Colors.transparent,
              border: Border.all(color: selected ? const Color(0xFFFF6EC7) : Colors.white24, width: 1),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              t,
              style: TextStyle(
                color: selected ? const Color(0xFFFF6EC7) : Colors.white,
                fontFamily: 'OpenSans',
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<String> _getOrCreatePromo(String userId, String masterName) async {
    final key = 'promo_GTM_${userId}_$masterName';
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    // Генерируем новый промокод
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = (List.generate(3, (i) => chars[(DateTime.now().millisecondsSinceEpoch + i * 17) % chars.length])).join();
    final promo = 'GTM-NEW7$rand';
    await prefs.setString(key, promo);
    return promo;
  }

  String buildBookingMessage(String masterName, String promocode) {
    return 'Привет, $masterName! 🖤 Я из GOTHAM\'S TOP MODEL и хочу записаться к тебе ✨. Вот мой промокод на 8% скидки: $promocode 💎';
  }

  @override
  Widget build(BuildContext context) {
    final master = widget.master;
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
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                // Подсказка "Оцените" с эффектом машинописи
                                                SizedBox(
                                                  height: 18,
                                                  child: AnimatedBuilder(
                                                    animation: _typingController,
                                                    builder: (context, _) {
                                                      if (_tipHidden) return const SizedBox();
                                                      final count = (_typingController.value * _ratingTip.length).clamp(0, _ratingTip.length).floor();
                                                      final text = _ratingTip.substring(0, count);
                                                      return Text(
                                                        text,
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 12,
                                                          fontFamily: 'OpenSans',
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
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
                              label: master.telegram,
                              url: master.telegramUrl ?? '',
                              color: Color(0xFF229ED9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0),
                            child: _SocialButton(
                              icon: Icons.music_note,
                              label: master.tiktok,
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
                                final promocode = await _getOrCreatePromo(userId, masterName);
                                print('userId: $userId, masterName: $masterName, promocode: $promocode');
                                final message = buildBookingMessage(master.name, promocode);
                                final baseUrl = master.bookingUrl != null && master.bookingUrl!.isNotEmpty
                                    ? master.bookingUrl!
                                    : 'https://t.me/GTM_ADM?text=${Uri.encodeComponent("Привет! Хочу узнать условия размещения в приложении для креаторов. Спасибо!")}';
                                // --- Исправлено: ручное кодирование текста ---
                                final encodedMessage = Uri.encodeComponent(message);
                                final finalUrl = '$baseUrl?text=$encodedMessage';
                                await launchUrl(Uri.parse(finalUrl));
                                // --- конец исправления ---
                                // Логируем использование промокода в БД (через ApiService)
                                try {
                                  final ok = await ApiService.logPromocodeUsage(
                                    userId: userId,
                                    promocode: promocode,
                                    masterName: masterName,
                                  );
                                  if (ok) {
                                    // ignore: avoid_print
                                    print('Промокод успешно залогирован');
                                  }
                                } catch (e) {
                                  // ignore: avoid_print
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
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.calendar_month, color: Color(0xFFFF6EC7), size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Booking calendar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'NauryzKeds',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Builder(builder: (context) {
                            final parsedCodes = _extractCityCodes(master.city);
                            final codes = _supabaseCityCodes.isNotEmpty ? _supabaseCityCodes : parsedCodes;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (codes.isNotEmpty) _buildCityChips(codes),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _openBooking(),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.white24, width: 1),
                                            color: Colors.transparent,
                                          ),
                                          child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 22),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (codes.isNotEmpty)
                                        Text(
                                          _selectedCityCode ?? codes.first,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'NauryzKeds',
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
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
          // --- Модальное окно Бронирования ---
          if (_showBooking)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.88)),
            ),
          if (_showBooking)
            Positioned.fill(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth * 0.9;
                    final height = constraints.maxHeight * 0.86;
                    final month = _calendarMonth;
                    final codes = _extractCityCodes(master.city);
                    return Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.92),
                        border: Border.all(color: Colors.white24, width: 1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              controller: _bookingScrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Выбор даты и времени',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'NauryzKeds',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (codes.isNotEmpty) _buildCityChips(codes),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () => _changeMonth(-1),
                                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                                        splashRadius: 22,
                                      ),
                                      Text(
                                        '${_russianMonthName(month)} ${month.year}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'NauryzKeds',
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _changeMonth(1),
                                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                                        splashRadius: 22,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _buildCalendarGrid(month),
                                  const SizedBox(height: 14),
                                  if (_selectedDate != null) ...[
                                    const Text(
                                      'Доступное время',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'NauryzKeds',
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTimeChips(),
                                  ],
                                  const SizedBox(height: 16),
                                  if (_selectedDate != null && _selectedTime != null)
                                    GestureDetector(
                                      onTap: () async {
                                        final userId = TelegramWebAppService.getUserId();
                                        final masterName = master.name;
                                        if (userId == null || userId.isEmpty) {
                                          print('Ошибка: userId пустой!');
                                          return;
                                        }
                                        final promocode = await _getOrCreatePromo(userId, masterName);
                                        final message = buildBookingMessage(master.name, promocode);
                                        final baseUrl = master.bookingUrl != null && master.bookingUrl!.isNotEmpty
                                            ? master.bookingUrl!
                                            : 'https://t.me/GTM_ADM?text=${Uri.encodeComponent("Привет! Хочу узнать условия размещения в приложении для креаторов. Спасибо!")}';
                                        final encodedMessage = Uri.encodeComponent(message);
                                        final finalUrl = '$baseUrl?text=$encodedMessage';
                                        await launchUrl(Uri.parse(finalUrl));
                                        try {
                                          final ok = await ApiService.logPromocodeUsage(
                                            userId: userId,
                                            promocode: promocode,
                                            masterName: masterName,
                                          );
                                          if (ok) {
                                            // ignore: avoid_print
                                            print('Промокод успешно залогирован');
                                          }
                                        } catch (e) {
                                          // ignore: avoid_print
                                          print('Ошибка логирования промокода: $e');
                                        }
                                        _closeBooking();
                                      },
                                      child: Container(
                                        height: 44,
                                        width: double.infinity,
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
                                        child: const Center(
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
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                              onPressed: _closeBooking,
                              splashRadius: 24,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
