import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/telegram_webapp_service.dart';
import '../services/supabase_service.dart';

const bool kCasinoUseDebugId = true; // включено для локальных тестов
const String kCasinoDebugUserId = '6931629845';

class GiveawayCasinoScreen extends StatefulWidget {
  const GiveawayCasinoScreen({super.key});

  @override
  State<GiveawayCasinoScreen> createState() => _GiveawayCasinoScreenState();
}

class _GiveawayCasinoScreenState extends State<GiveawayCasinoScreen> with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _celebrateCtrl;
  int _r1 = 7, _r2 = 7, _r3 = 7; // стартовые семерки
  bool _spinning = false;
  int _attemptsLeft = 20; // по умолчанию; сервер вернет точное
  int _userWins = 0; // сколько бонусов выиграл юзер (не более 2)
  int _awardedTotal = 0; // скольким уже выдано глобально (<=50)
  String? _error;
  bool _celebrating = false;
  late final List<_ConfettiPiece> _confettiPieces;

  @override
  void initState() {
    super.initState();
    TelegramWebAppService.disableVerticalSwipe();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _celebrateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    final rnd = Random(42);
    _confettiPieces = List.generate(80, (i) {
      return _ConfettiPiece(
        xSeed: rnd.nextDouble(),
        vSeed: 0.6 + rnd.nextDouble() * 0.8,
        size: 6.0 + rnd.nextDouble() * 10.0,
        color: [Colors.white, const Color(0xFFFF6EC7), const Color(0xFFFFB3E6), Colors.pinkAccent][rnd.nextInt(4)],
        rotSeed: rnd.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _celebrateCtrl.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    String? idStr = TelegramWebAppService.getPluginUserId();
    if (kCasinoUseDebugId) {
      idStr = kCasinoDebugUserId;
    }
    if (idStr == null) {
      TelegramWebAppService.showAlert('Не удалось определить пользователя');
      return;
    }
    setState(() { _spinning = true; _error = null; });

    try {
      // Локальная визуальная прокрутка до ответа сервера
      await _runFakeSpin();
      final res = await SupabaseService().casinoSpin(int.parse(idStr));
      final reel1 = (res['reel1'] as int?) ?? 7;
      final reel2 = (res['reel2'] as int?) ?? 7;
      final reel3 = (res['reel3'] as int?) ?? 7;
      final isWin = res['is_win'] == true;
      final attempts = (res['attempts_left'] as int?) ?? _attemptsLeft;
      final wins = (res['user_wins'] as int?) ?? _userWins;
      final total = (res['total_awarded'] as int?) ?? _awardedTotal;

      setState(() {
        _r1 = reel1; _r2 = reel2; _r3 = reel3;
        _attemptsLeft = attempts;
        _userWins = wins;
        _awardedTotal = total;
      });

      if (isWin) {
        if (!mounted) return;
        setState(() { _celebrating = true; });
        _celebrateCtrl.forward(from: 0);
        Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() { _celebrating = false; }); });
      }
    } catch (e) {
      setState(() { _error = 'Ошибка: $e'; });
    } finally {
      setState(() { _spinning = false; });
    }
  }

  Future<void> _runFakeSpin() async {
    final rnd = Random();
    final completer = Completer<void>();
    int ticks = 0;
    const totalTicks = 18;
    Timer.periodic(const Duration(milliseconds: 60), (t) {
      ticks++;
      setState(() {
        _r1 = 1 + rnd.nextInt(9);
        _r2 = 1 + rnd.nextInt(9);
        _r3 = 1 + rnd.nextInt(9);
      });
      if (ticks >= totalTicks) {
        t.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('🎰 Рулетка', style: TextStyle(color: Colors.white, fontFamily: 'NauryzKeds')),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // Кольцо 20% белой прозрачности вокруг мемоджи
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Text('🎰', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 24),
              _slotRow(_r1, _r2, _r3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statChip('Попытки', _attemptsLeft.toString()),
                  const SizedBox(width: 8),
                  _statChip('Побед', _userWins.toString()),
                  const SizedBox(width: 8),
                  _statChip('Выдано всего', _awardedTotal.toString()),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final bool enabled = !_spinning && _attemptsLeft > 0; // пер-юзер капы убираем на UI
                final String label = _attemptsLeft <= 0
                    ? 'Попыток нет'
                    : (_spinning ? 'Крутим...' : 'Крутить');
                return GestureDetector(
                  onTap: enabled ? _spin : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: enabled
                          ? const LinearGradient(
                              colors: [Colors.white, Color(0xFFFF6EC7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🎰',
                          style: TextStyle(
                            fontSize: 20,
                            color: enabled ? Colors.black : Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: TextStyle(
                            color: enabled ? Colors.black : Colors.white54,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NauryzKeds',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
                ],
              ),
              if (_celebrating)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _celebrateCtrl,
                    builder: (context, _) {
                      final v = _celebrateCtrl.value;
                      final bg = Color.lerp(const Color(0xFFFFB3E6).withOpacity(0.9), const Color(0xFFFF6EC7).withOpacity(0.7), (sin(v * pi * 6).abs()));
                      return Stack(
                        children: [
                          Container(color: bg),
                          Center(
                            child: Transform.scale(
                              scaleX: 1.2 + 0.3 * sin(v * pi * 4).abs(),
                              scaleY: 1.0 + 0.2 * sin(v * pi * 4).abs(),
                              child: Container(
                                width: 260,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6EC7).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(180),
                                ),
                              ),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;
                              return Stack(
                                children: _confettiPieces.map((p) {
                                  final y = v * h * p.vSeed;
                                  final x = (p.xSeed * w + sin(v * 12 + p.rotSeed) * 30) % w;
                                  final r = v * pi * 6 + p.rotSeed;
                                  return Positioned(
                                    left: x,
                                    top: y - p.size,
                                    child: Transform.rotate(
                                      angle: r,
                                      child: Container(
                                        width: p.size,
                                        height: p.size,
                                        color: p.color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotRow(int a, int b, int c) {
    Widget cell(int v) => Container(
          width: 72,
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            v.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 58, fontFamily: 'NauryzKeds'),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [cell(a), const SizedBox(width: 8), cell(b), const SizedBox(width: 8), cell(c)],
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'NauryzKeds')),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  final double xSeed;
  final double vSeed;
  final double size;
  final Color color;
  final double rotSeed;
  _ConfettiPiece({
    required this.xSeed,
    required this.vSeed,
    required this.size,
    required this.color,
    required this.rotSeed,
  });
}

