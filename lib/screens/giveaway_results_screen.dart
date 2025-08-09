import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class GiveawayResultsScreen extends StatefulWidget {
  final int giveawayId;
  // Если передан mockResults – экран показывает их без запросов к API
  final List<Map<String, dynamic>>? mockResults;

  const GiveawayResultsScreen({
    super.key,
    required this.giveawayId,
    this.mockResults,
  });

  @override
  State<GiveawayResultsScreen> createState() => _GiveawayResultsScreenState();
}

class _GiveawayResultsScreenState extends State<GiveawayResultsScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String? _error;

  // Animation state
  bool _isAnimating = true;
  int _animCurrentPlace = 0;
  final List<String> _animLog = [];
  int? _totalAllTickets;

  @override
  void initState() {
    super.initState();
    _loadTotalTickets();
    if (widget.mockResults != null) {
      // Используем мок-данные
      _results = List<Map<String, dynamic>>.from(widget.mockResults!);
      _isLoading = false;
      _error = null;
      setState(() {});
      _startAnimation();
    } else {
      _loadGiveawayResults().then((_) => _startAnimation());
    }
  }

  Future<void> _loadGiveawayResults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('${ApiConfig.ratingApiBaseUrl}/api/giveaway/results/${widget.giveawayId}'),
        headers: ApiConfig.ratingApiHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _results = List<Map<String, dynamic>>.from(data['results']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Ошибка загрузки результатов';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Ошибка загрузки результатов (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка сети: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Результаты розыгрыша',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NauryzKeds',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isAnimating) _buildAnimationOverlay(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6EC7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Перейти в приложение',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6EC7)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGiveawayResults,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6EC7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: Colors.white54,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Результаты пока не готовы',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontFamily: 'NauryzKeds',
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Заголовок
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6EC7), Color(0xFF7366FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  '🏆 ПОБЕДИТЕЛИ РОЗЫГРЫША',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NauryzKeds',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Перечень бьюти-призов (как в GiveawayScreen)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              border: Border.all(color: const Color(0xFF444444), width: 1),
              borderRadius: BorderRadius.zero,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Бьюти-услуги (2–5 место):',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NauryzKeds',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                _BeautyPrizeLine('Татуировку до 15 см у: @naidenka_tatto0, @emi3mo, @ufantasiesss'),
                _BeautyPrizeLine('Татуировку до 10 см у: @g9r1a, @murderd0lll'),
                _BeautyPrizeLine('Сертификат на пирсинг у: @bloodivampin'),
                _BeautyPrizeLine('Стрижка или авторский проект у: @punk2_n0t_d34d'),
                _BeautyPrizeLine('50% скидка на любой тату-проект у: @chchndra_tattoo'),
                SizedBox(height: 8),
                Text(
                  'По желанию победителя — можно заменить на Telegram Premium (3 мес).',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Список победителей
          ..._results.map((result) => _buildWinnerCard(result)).toList(),
        ],
      ),
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> result) {
    final placeNumber = result['place_number'] ?? 0;
    final prizeName = result['prize_name'] ?? '';
    final prizeValue = result['prize_value'] ?? '';
    final winnerUsername = result['winner_username'] ?? '';
    final winnerFirstName = result['winner_first_name'] ?? '';
    final isManualWinner = result['is_manual_winner'] ?? false;

    // Цвет и иконка по правилам: 1 — золото, 2-5 — серебро, 6 — бронза
    Color cardColor;
    IconData placeIcon = Icons.emoji_events;
    String placeText;
    if (placeNumber == 1) {
      cardColor = const Color(0xFFFFD700);
      placeText = '🥇 1 МЕСТО';
    } else if (placeNumber >= 2 && placeNumber <= 5) {
      cardColor = const Color(0xFFC0C0C0);
      placeText = '🥈 $placeNumber МЕСТО';
    } else if (placeNumber == 6) {
      cardColor = const Color(0xFFCD7F32);
      placeText = '🥉 6 МЕСТО';
    } else {
      cardColor = const Color(0xFF4A4A4A);
      placeIcon = Icons.star;
      placeText = '$placeNumber МЕСТО';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        border: Border.all(color: cardColor, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  placeIcon,
                  color: cardColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  placeText,
                  style: TextStyle(
                    color: cardColor,
                    fontFamily: 'NauryzKeds',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              prizeName,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'NauryzKeds',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prizeValue,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            if (placeNumber >= 2 && placeNumber <= 5) ...[
              const SizedBox(height: 10),
              const _BeautyPrizeLine('Татуировку до 15 см у: @naidenka_tatto0, @emi3mo, @ufantasiesss'),
              const _BeautyPrizeLine('Татуировку до 10 см у: @g9r1a, @murderd0lll'),
              const _BeautyPrizeLine('Сертификат на пирсинг у: @bloodivampin'),
              const _BeautyPrizeLine('Стрижка или авторский проект у: @punk2_n0t_d34d'),
              const _BeautyPrizeLine('50% скидка на любой тату-проект у: @chchndra_tattoo'),
              const SizedBox(height: 6),
              const Text(
                'По желанию победителя — можно заменить на Telegram Premium (3 мес).',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              )
            ],
            if (winnerUsername.isNotEmpty || winnerFirstName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    winnerFirstName.isNotEmpty ? winnerFirstName : '@$winnerUsername',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === Animation helpers ===
  void _pushAnim(String line) {
    setState(() {
      _animLog.add(line);
      if (_animLog.length > 40) {
        _animLog.removeAt(0);
      }
    });
  }

  Future<void> _loadTotalTickets() async {
    try {
      final total = await ApiService.getTotalAllTicketsFromApi();
      if (!mounted) return;
      setState(() {
        _totalAllTickets = total ?? 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _totalAllTickets = null; });
    }
  }

  Future<void> _simulatePlace(int place, {bool forceFailFirst = false}) async {
    _animCurrentPlace = place;
    _pushAnim('— — — — —');
    _pushAnim('Место $place:');
    await Future.delayed(const Duration(milliseconds: 400));
    _pushAnim('• Собираем всех юзеров с билетами...');
    await Future.delayed(const Duration(milliseconds: 500));
    _pushAnim('• Выбираем случайного претендента...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Имя победителя из результатов (если есть)
    String display = '';
    try {
      final row = _results.firstWhere((r) => (r['place_number'] ?? 0) == place, orElse: () => {});
      final u = (row['winner_username'] ?? '') as String?;
      final f = (row['winner_first_name'] ?? '') as String?;
      display = (u != null && u.isNotEmpty) ? '@$u' : (f ?? 'пользователь');
    } catch (_) {
      display = 'пользователь';
    }

    if (forceFailFirst) {
      _pushAnim('• Проверяем подписку на каналы...');
      await Future.delayed(const Duration(milliseconds: 600));
      _pushAnim('❌ Не подписан на все каналы — выбираем другого');
      await Future.delayed(const Duration(milliseconds: 700));
      _pushAnim('• Выбираем другого претендента...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _pushAnim('• Проверяем подписку на каналы...');
    await Future.delayed(const Duration(milliseconds: 600));
    _pushAnim('✅ Успешно! Победитель: $display');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _startAnimation() async {
    try {
      // Вставляем заголовок о количестве билетов
      if (_totalAllTickets != null) {
        _pushAnim('Всего билетов в розыгрыше: ${_totalAllTickets}');
        await Future.delayed(const Duration(milliseconds: 400));
      } else {
        _pushAnim('Всего билетов в розыгрыше: —');
        await Future.delayed(const Duration(milliseconds: 400));
      }
      // Проводим розыгрыш по всем местам
      for (int place = 1; place <= 6; place++) {
        final failFirst = (place == 5);
        await _simulatePlace(place, forceFailFirst: failFirst);
      }
    } catch (_) {}
  }

  Widget _buildAnimationOverlay() {
    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          width: 720,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            border: Border.all(color: const Color(0xFF444444), width: 1),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '🎰 Проводим розыгрыш...',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'NauryzKeds',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() { _isAnimating = false; });
                    },
                    icon: const Icon(Icons.close, color: Colors.white70),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                  borderRadius: BorderRadius.zero,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _animLog.length,
                  itemBuilder: (context, index) {
                    final line = _animLog[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        line,
                        style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6EC7)),
                  ),
                  SizedBox(width: 10),
                  Text('Определяем победителей...', style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Место: ${_animCurrentPlace.clamp(0, 6)} / 6',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() { _isAnimating = false; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6EC7),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'Посмотреть результаты',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
} 

class _BeautyPrizeLine extends StatelessWidget {
  const _BeautyPrizeLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          )
        ],
      ),
    );
  }
}