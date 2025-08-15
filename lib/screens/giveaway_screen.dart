import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'role_selection_screen.dart';
// import 'invite_friends_screen.dart'; // Временно убрано
import 'dart:async';
import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'city_selection_screen.dart' show DottedCirclePainter;
import '../services/telegram_webapp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'giveaway_results_screen.dart';

import '../services/giveaway_supabase_service.dart';

// Заглушка для будущего демонстрационного перехода на экран результатов
// В проде держим false, чтобы ничего не отображалось и автоперехода не было
const bool kEnableGiveawayResultsDemo = false;
const int kGiveawayResultsDemoDelaySec = 10;
// Показать кнопку DEBUG на экране гивевея
const bool kShowGiveawayDebugButton = false;
// DEBUG-фоллбек отключён: используем только ID из плагина Telegram WebApp
const bool kUseDebugTelegramIdForX = false; // Используем только реальный Telegram ID
const String kDebugTelegramUserId = '5237968922';

class GiveawayScreen extends StatefulWidget {
  const GiveawayScreen({super.key});

  @override
  State<GiveawayScreen> createState() => _GiveawayScreenState();
}

class _GiveawayScreenState extends State<GiveawayScreen> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;
  // Стартовая имитация загрузки экрана (10 секунд)
  bool _isInitialLoading = true;
  int _initialDelayLeft = 10;
  Timer? _initialDelayTimer;

  // UI flags (minimal set in use)
  bool _task1ButtonPressed = false;
  bool _task2ButtonPressed = false;
  // bool _canGoToApp = false; // not used
  bool _isCheckingSubscriptions = false; // Состояние проверки подписок

  // удалено: username не используется в UI
  int _tickets = 0; // Всего билетов
  // int _invitedFriends = 0; // Только за друзей
  int _totalTickets = 0;

  String folderCounter = '0/1';
  String friendsCounter = '0/10';
  Color folderCounterColor = Colors.white.withOpacity(0.7);
  Color friendsCounterColor = Colors.white.withOpacity(0.7);
  int _giveawayTickets = 0; // сумма is_in_folder + invited_friends
  // int _totalEarnedTickets = 0; // Общее количество заработанных билетов

  String _telegramFolderUrl = 'https://t.me/addlist/6HRxDLe0Gdk2M2E1';
  final DateTime giveawayDate = DateTime(2025, 8, 18, 18, 0, 0); // 18 августа 2025, 18:00

  // derived helpers are not used directly

  @override
  void initState() {
    super.initState();
    // Инициализация Telegram WebApp (ready/expand/disable swipe)
    TelegramWebAppService.initializeWebApp();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
    _loadSavedState();
    // Заглушка: при kEnableGiveawayResultsDemo == true запускаем демо-таймер и автопереход
    if (kEnableGiveawayResultsDemo) {
      _initialDelayLeft = kGiveawayResultsDemoDelaySec;
      _initialDelayTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        if (_initialDelayLeft > 0) {
          setState(() { _initialDelayLeft--; });
        }
        if (_initialDelayLeft <= 0) {
          t.cancel();
          setState(() { _isInitialLoading = false; });
          _fetchUserTickets();
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GiveawayResultsScreen(
                  giveawayId: 1,
                  mockResults: [
                    {
                      'place_number': 1,
                      'prize_name': 'Главный приз',
                      'prize_value': '20 000 ₽ Золотое яблоко',
                      'winner_username': 'gold_winner',
                      'winner_first_name': 'Виктория',
                      'is_manual_winner': true,
                    },
                    {
                      'place_number': 2,
                      'prize_name': 'Бьюти услуга на выбор',
                      'prize_value': 'Можно заменить на Telegram Premium',
                      'winner_username': 'beauty_2',
                      'winner_first_name': 'Иван',
                      'is_manual_winner': false,
                    },
                    {
                      'place_number': 3,
                      'prize_name': 'Бьюти услуга на выбор',
                      'prize_value': 'Можно заменить на Telegram Premium',
                      'winner_username': 'beauty_3',
                      'winner_first_name': 'Марина',
                      'is_manual_winner': false,
                    },
                    {
                      'place_number': 4,
                      'prize_name': 'Бьюти услуга на выбор',
                      'prize_value': 'Можно заменить на Telegram Premium',
                      'winner_username': 'beauty_4',
                      'winner_first_name': 'Сергей',
                      'is_manual_winner': false,
                    },
                    {
                      'place_number': 5,
                      'prize_name': 'Бьюти услуга на выбор',
                      'prize_value': 'Можно заменить на Telegram Premium',
                      'winner_username': 'beauty_5',
                      'winner_first_name': 'Алёна',
                      'is_manual_winner': false,
                    },
                    {
                      'place_number': 6,
                      'prize_name': 'Футболка',
                      'prize_value': 'Футболка GTM',
                      'winner_username': 'tee_6',
                      'winner_first_name': 'Дима',
                      'is_manual_winner': false,
                    },
                  ],
                ),
              ),
            );
          }
        }
      });
    } else {
      // В обычном режиме не показываем имитацию задержки и автопереход
      setState(() { _isInitialLoading = false; });
      _fetchUserTickets();
    }
    TelegramWebAppService.disableVerticalSwipe();
  }

  void _updateTimeLeft() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    setState(() {
      _timeLeft = giveawayDate.difference(now);
      if (_timeLeft.isNegative) {
        _timeLeft = Duration.zero;
      }
    });
  }

  Future<void> _fetchUserTickets() async {
    try {
      // Всегда обновляем Y (total_all_tickets) при входе на экран, независимо от userId
      await _refreshTotalAllTicketsQuick();

      // X: грузим только если пришёл userId из плагина; для отладки можно подставить фиксированный id
      String? userId = TelegramWebAppService.getPluginUserId();
      if (userId == null && kUseDebugTelegramIdForX) {
        userId = kDebugTelegramUserId;
        print('[GIVEAWAY][DEBUG] using fallback debug telegram id = '+userId);
      }
      // ignore: avoid_print
      print('[GIVEAWAY] resolved telegram userId = '+ (userId ?? 'null'));
      if (userId == null) return;
      final prefs = await SharedPreferences.getInstance();
      final lastTicketCheck = prefs.getInt('last_ticket_check_$userId') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastTicketCheck < 25 * 1000) {
        final cachedTickets = prefs.getInt('cached_tickets_$userId');
        // username ранее кэшировался, но сейчас не используется
        final cachedTotal = prefs.getInt('cached_total_tickets');
        if (cachedTickets != null && cachedTotal != null) {
          setState(() {
            _tickets = cachedTickets;
            _totalTickets = cachedTotal;
          });
          return;
        }
      }
      // 1) Быстрый источник: Supabase напрямую
      final intTelegramId = int.tryParse(userId) ?? 0;
      try {
        final statsFast = await GiveawaySupabaseService.instance.getUserStatsQuick(intTelegramId);
        if (statsFast.isNotEmpty) {
          final tickets = statsFast['total_tickets'] ?? 0;
          final subsTickets = statsFast['subscription_tickets'] ?? 0;
          final referralTickets = statsFast['referral_tickets'] ?? 0;
          setState(() {
            _tickets = tickets is int ? tickets : int.tryParse('$tickets') ?? 0;
            final int subs = subsTickets is int ? subsTickets : int.tryParse('$subsTickets') ?? 0;
            folderCounter = subs > 0 ? '1/1' : '0/1';
            folderCounterColor = subs > 0 ? Colors.green : Colors.white.withOpacity(0.7);
            final int ref = referralTickets is int ? referralTickets : int.tryParse('$referralTickets') ?? 0;
            final int cappedRef = ref > 10 ? 10 : ref;
            friendsCounter = '$cappedRef/10';
            friendsCounterColor = cappedRef > 0 ? Colors.green : Colors.white.withOpacity(0.7);
            // X в строке "Подарки": используем суммарные билеты из users.total_tickets (включает бонусные)
            _giveawayTickets = _tickets;
          });
          await prefs.setInt('cached_tickets_$userId', _tickets);
          await prefs.setInt('last_ticket_check_$userId', now);
          // Сохраняем флаг о билете за папку
          await prefs.setBool('folder_awarded_$userId', (statsFast['subscription_tickets'] ?? 0) > 0);
        }
      } catch (e) {
        print('❌ [DEBUG] Supabase fast stats error: $e');
      }

      // 2) Y: сначала view (если есть), fallback на сумму
      await _refreshTotalAllTicketsQuick();
    } catch (e) {
      print('❌ [DEBUG] Error fetching tickets: $e');
    }
  }

  Future<void> _checkSubscriptions() async {
    try {
      setState(() {
        _isCheckingSubscriptions = true;
      });

      // Для CHECK используем плагин id; если его нет и включён debug-флаг — подставляем тестовый id
      String? userId = TelegramWebAppService.getPluginUserId();
      if (userId == null && kUseDebugTelegramIdForX) {
        userId = kDebugTelegramUserId;
        print('[GIVEAWAY][DEBUG] CHECK using fallback debug telegram id = '+userId);
      }
      if (userId == null) {
        print('❌ [DEBUG] User ID is null - cannot check subscriptions');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final awarded = prefs.getBool('folder_awarded_$userId') ?? false;
      if (awarded) {
        // Уже начисляли билет за папку — не дергаем Telegram, просто подтверждаем и обновляем Supabase
        TelegramWebAppService.showAlert('✅ Билет за папку уже начислен');
        await _fetchUserTickets();
        return;
      }

      print('🔍 [DEBUG] Checking subscriptions for user ID: $userId via API (full check)');

      final response = await ApiService.checkSubscriptions(int.tryParse(userId) ?? 0);
      {
        final data = response;
        final bool success = (data['success'] == true) || (data['status'] == 'ok') || (data['ok'] == true);
        final bool isAll = (data['is_subscribed_to_all'] == true) || (data['is_all'] == true) || (data['subscribed'] == true);
        final bool ticketAwarded = data['ticket_awarded'] == true || data['awarded'] == true;

        if (!success && !isAll) {
          TelegramWebAppService.showAlert('❌ Ошибка проверки подписок');
        }

        // Немедленный визуальный фидбек по ответу API: обновляем и цвет, и счётчик 0/1
        setState(() {
          folderCounter = isAll ? '1/1' : '0/1';
          folderCounterColor = isAll ? Colors.green : Colors.red;
        });

        // Мягкий откат цвета
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              folderCounterColor = Colors.white.withOpacity(0.7);
            });
          }
        });

        // Сообщение пользователю
        if (isAll) {
          if (ticketAwarded) {
            TelegramWebAppService.showAlert('✅ Подписка подтверждена! +1 билет начислен');
          } else {
            TelegramWebAppService.showAlert('✅ Подписка подтверждена! Билет уже начислялся ранее');
          }
        } else {
          TelegramWebAppService.showAlert('❌ Недостаточно подписок! Подпишитесь на все каналы из папки и попробуйте снова');
        }

        // Фоново перечитываем состояние из Rating API (X/Y, 0/1, 0..10)
        await _fetchUserTickets();
      }
    } catch (e) {
      print('❌ [DEBUG] Error checking subscriptions: $e');
      TelegramWebAppService.showAlert('❌ Ошибка проверки подписки');
    } finally {
      setState(() {
        _isCheckingSubscriptions = false;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _initialDelayTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
        setState(() {
          _task1ButtonPressed = prefs.getBool('task1_button_pressed') ?? false;
          _task2ButtonPressed = prefs.getBool('task2_button_pressed') ?? false;
        });
    } catch (e) {
      print('Error loading saved state: $e');
    }
  }

  Future<void> _saveTask1ButtonPressed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('task1_button_pressed', true);
      setState(() {
        _task1ButtonPressed = true;
      });
    } catch (e) {
      print('Error saving task1 button state: $e');
    }
  }

  Future<void> _saveTask2ButtonPressed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('task2_button_pressed', true);
      setState(() {
        _task2ButtonPressed = true;
      });
    } catch (e) {
      print('Error saving task2 button state: $e');
    }
  }

  // Future<void> _saveCanGoToApp() async {}

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // logging of tasks to Supabase removed to avoid direct REST calls

  // Future<void> _logFolderSubscription(String userId) async {}

  Future<void> _openContactsForInvite() async {
    try {
      // Используем userId из плагина; для отладки подставляем фиксированный id при его отсутствии
      String? userId = TelegramWebAppService.getPluginUserId();
      if (userId == null && kUseDebugTelegramIdForX) {
        userId = kDebugTelegramUserId;
        print('[GIVEAWAY][DEBUG] INVITE using fallback debug telegram id = '+userId);
      }
      if (userId == null) {
        TelegramWebAppService.showAlert('Ошибка: не удалось определить пользователя');
        return;
      }

      // Получаем referral_code через Rating API
      String? referralCode;
      final telegramId = int.tryParse(userId);
      if (telegramId == null) {
        TelegramWebAppService.showAlert('Ошибка: некорректный Telegram ID');
        return;
      }
      referralCode = await ApiService.getOrCreateReferralCode(telegramId);
      if (referralCode == null || referralCode.isEmpty) {
        TelegramWebAppService.showAlert('Не удалось получить реферальную ссылку. Повторите позже.');
        return;
      }

      final shareLink = 'https://t.me/GTM_ROBOT?start=$referralCode';

      final inviteMessage = '''🖤 Привет! Нашёл крутую платформу — GOTHAM'S TOP MODEL! ✨

🔥 Что тут происходит:
• 🤖 AI-поиск мастеров по фото
• 🖤 Запись к топ артистам: тату, пирсинг, окрашивание
• 💸 Розыгрыши на >130,000₽
• 💄 Скидки 8% на бьюти-услуги
• 🎀 Подарочные сертификаты
• 🗨️ Большой чат между мастерами и клиентами

🌪️ А впереди:
• 🧃 Дропы с лимитками и стилем
• 🖤 Мемы и крутые коллабы
• 🥀 Движ, интриги и сюрпризы

🎁 Хочешь бонусы? Лови:
$shareLink

💗 Присоединяйся — и будь в игре 🎲
#GTM #GothamsTopModel #Giveaway''';

      final telegramUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(shareLink)}&text=${Uri.encodeComponent(inviteMessage)}';
      TelegramWebAppService.openTelegramLink(telegramUrl);
    } catch (e) {
      print('❌ Error opening contacts for invite: $e');
      TelegramWebAppService.showAlert('Ошибка при открытии списка контактов');
    }
  }

  void _showPrizesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          '🎁 Подарки гивевея',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NauryzKeds',
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Призы
              _PrizeCard(
                title: 'Золотое яблоко',
                descriptionWidget: _buildRichText([
                  TextSpan(text: 'Будет '),
                  TextSpan(text: 'одно', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' призовое место — сертификат на покупку в '),
                  TextSpan(text: 'Золотом Яблоке', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' на сумму 20000 рублей'),
                ]),
                value: '20,000₽',
                icon: Icons.emoji_events,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              _PrizeCard(
                title: 'Бьюти-услуги',
                descriptionWidget: _buildRichText([
                  TextSpan(text: '4 победителя,', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' каждый из которых по очереди может выбрать:\n\n'),
                  TextSpan(text: 'Татуировку до 15 см', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' у: '),
                  ..._tgLinksInline(['@naidenka_tatto0', '@emi3mo', '@ufantasiesss']),
                  TextSpan(text: '\n'),
                  TextSpan(text: 'Татуировку до 10 см', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' у: '),
                  ..._tgLinksInline(['@g9r1a', '@murderd0lll']),
                  TextSpan(text: '\n'),
                  TextSpan(text: 'Сертификат на пирсинг', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' у: '),
                  ..._tgLinksInline(['@bloodivampin']),
                  TextSpan(text: '\n'),
                  TextSpan(text: 'Стрижку ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: 'или ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'авторский проект', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' у: '),
                  ..._tgLinksInline(['@punk2_n0t_d34d']),
                  TextSpan(text: '\n'),
                  TextSpan(text: '50% скидку', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' на любой тату-проект у: '),
                  ..._tgLinksInline(['@chchndra_tattoo']),
                ]),
                value: '100,000₽',
                icon: Icons.spa,
                color: Colors.pink,
              ),
              const SizedBox(height: 16),
              _PrizeCard(
                title: 'Telegram Premium (3 мес)',
                descriptionWidget: _buildRichText([
                  TextSpan(text: ''),
                  TextSpan(text: 'Х3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' подписки Telegram Premium на 3 месяца, для тех победителей которые не могут воспользоваться бьюти-услугами артистов.'),
                ]),
                value: '3,500₽',
                icon: Icons.telegram,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              // Мерч GTM x CRYSQUAD
              _PrizeCard(
                title: 'GTM x CRYSQUAD',
                descriptionWidget: _buildRichText([
                  TextSpan(text: 'Эксклюзивный мерч от '),
                  TextSpan(text: 'Gotham\'s Top Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' в коллаборации с '),
                  TextSpan(text: 'CRYSQUAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: '. Ограниченная серия.'),
                  TextSpan(text: '\n\nЕсли не полагаешься на удачу, жми кнопку BUY'),
                ]),
                value: '3,799₽',
                icon: Icons.shopping_bag,
                color: Colors.white,
                showViewButton: true,
                onViewPressed: () {
                  Navigator.of(context).pop();
                  _showTshirtGallery();
                },
                showBuyButton: true,
                onBuyPressed: () {
                  Navigator.of(context).pop();
                  _openMerchLink();
                },
              ),
              const SizedBox(height: 16),
              _PrizeCard(
                title: 'Скидки всем',
                descriptionWidget: _buildRichText([
                  TextSpan(text: ''),
                  TextSpan(text: '8% всем участникам', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ', получившим '),
                  TextSpan(text: 'хотя бы 1 билет', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' розыгрыша на услуги всех резидентов '),
                  TextSpan(text: 'Gotham\'s Top Model', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
                value: '8%',
                icon: Icons.percent,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              // Общая стоимость призов по центру снизу
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6EC7).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFFFF6EC7)),
                  borderRadius: BorderRadius.zero, // Квадратная рамка
                ),
                child: const Text(
                  '🏆 Общая стоимость призов: > 130,000₽',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NauryzKeds',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Условия начисления билетов
              Container(
                margin: const EdgeInsets.only(top: 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.zero, // Квадратная рамка
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.confirmation_num, color: Color(0xFFFF6EC7), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Как получить билеты:',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NauryzKeds',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 15),
                              children: [
                                TextSpan(text: '+1 билет', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                TextSpan(text: ' — за подписку на Telegram-папку (не отписываться до конца розыгрыша, условия проверяются)'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 15),
                              children: [
                                TextSpan(text: '+1 билет', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                TextSpan(text: ' — за каждого друга, который стартует бота по вашей реферальной ссылке'),
                              ],
                            ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(
                color: Color(0xFFFF6EC7),
                fontFamily: 'NauryzKeds',
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTshirtGallery() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GTM x CRYSQUAD',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NauryzKeds',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  children: [
                    Image.network(
                      'https://rxmtovqxjsvogyywyrha.supabase.co/storage/v1/object/public/gtm-assets-public/gtm-mer4/gtm_tshirt.jpg',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/GTM_products/gtm_tshirt.jpg',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                    // Можно добавить больше фото тишки
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openMerchLink();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'BUY',
                  style: TextStyle(
                    fontFamily: 'NauryzKeds',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMerchLink() async {
    final userId = TelegramWebAppService.getUserId();
    final message = 'Йо! 💀 хочу мерч!\nВот моя скидка early bird 10% – MER410-$userId\n🎱 Можно, пожалуйста, инфу и подробности по товарам?\n🖤';
    
    // Открываем Telegram с предзаполненным сообщением в личку GTM_ADM
    final telegramUrl = 'https://t.me/GTM_ADM?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(telegramUrl))) {
      await launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication);
    }
  }

  // void _openTelegramFolder() async {}

  // void _openInviteFriends() async {}

  

  List<TextSpan> _tgLinksInline(List<String> handles) {
    List<TextSpan> spans = [];
    for (int i = 0; i < handles.length; i++) {
      spans.add(TextSpan(
        text: handles[i],
        style: const TextStyle(
          color: Color(0xFFFF6EC7),
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final username = handles[i].replaceFirst('@', '');
            final telegramUrl = 'https://t.me/$username';
            try {
              if (kIsWeb) {
                html.window.open(telegramUrl, '_blank');
              } else {
                await launchUrl(Uri.parse(telegramUrl), mode: LaunchMode.externalApplication);
              }
            } catch (e) {
              print('❌ Error opening Telegram profile: $e');
            }
          },
      ));
      if (i < handles.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }
    return spans;
  }

  RichText _buildRichText(List<TextSpan> spans) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white70,
          fontFamily: 'OpenSans',
          fontSize: 14,
        ),
        children: spans,
      ),
    );
  }

  Future<void> _debugShowTotalTickets() async {
    try {
      int? fromView = await GiveawaySupabaseService.instance.tryReadTotalAllTicketsView();
      int total = fromView ?? await GiveawaySupabaseService.instance.getTotalAllTicketsQuick();
      print('[GIVEAWAY][DEBUG] total_all_tickets = $total');
      if (!mounted) return;
      setState(() { _totalTickets = total; });
      TelegramWebAppService.showAlert('Всего билетов (Y): $total');
    } catch (e) {
      print('❌ [GIVEAWAY][DEBUG] error reading total_all_tickets: $e');
      TelegramWebAppService.showAlert('Ошибка чтения total_all_tickets');
    }
  }

  Future<void> _refreshTotalAllTicketsQuick() async {
    try {
      int? fromView = await GiveawaySupabaseService.instance.tryReadTotalAllTicketsView();
      int total = fromView ?? await GiveawaySupabaseService.instance.getTotalAllTicketsQuick();
      if (!mounted) return;
      setState(() { _totalTickets = total; });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_total_tickets', total);
    } catch (e) {
      print('❌ [GIVEAWAY] refresh total_all_tickets error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGoToAppButtonEnabled = true; // Always enabled - no longer depends on tasks
    // final int task2Max = task2Progress < 10 ? task2Progress + 1 : 10;
    // final int totalTickets = task1Progress + task2Progress;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/giveaway_back_banner.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final height = constraints.maxHeight;
                      return Transform.translate(
                        offset: Offset(0, -height * 0.06),
                        child: Transform.scale(
                          scale: 1.13,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/giveaway_banner.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
          ),
          if (kShowGiveawayDebugButton)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: _debugShowTotalTickets,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF6EC7)),
                        foregroundColor: const Color(0xFFFF6EC7),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text(
                        'DEBUG',
                        style: TextStyle(
                          fontFamily: 'NauryzKeds',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05 + 45),
                Container(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'GIVEAWAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NauryzKeds',
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 220,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        fontFamily: 'NauryzKeds',
                        height: 0.9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                      child: GestureDetector(
                        onTap: _showPrizesDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6EC7).withOpacity(0.2),
                            border: Border.all(color: const Color(0xFFFF6EC7), width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Подарки',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NauryzKeds',
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Icon(Icons.confirmation_num, color: Color(0xFFFF6EC7), size: 22),
                              const SizedBox(width: 4),
                              Text(
                                '$_giveawayTickets/$_totalTickets',
                                style: const TextStyle(
                                  color: Color(0xFFFF6EC7),
                                  fontFamily: 'NauryzKeds',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                    // Список заданий и кнопка
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SubscribeFolderCard(
                            folderCounter: folderCounter,
                            folderCounterColor: folderCounterColor,
                            isChecking: _isCheckingSubscriptions,
                            onCheckTap: _isCheckingSubscriptions ? null : _checkSubscriptions,
                            onSubscribeTap: () async {
                              await _saveTask1ButtonPressed();
                              if (await canLaunchUrl(Uri.parse(_telegramFolderUrl))) {
                                await launchUrl(Uri.parse(_telegramFolderUrl), mode: LaunchMode.externalApplication);
                              } else {
                                TelegramWebAppService.showAlert('Ошибка: не удается открыть ссылку');
                              }
                               // visual flag no longer used
                              // Логика чека выполняется отдельной кнопкой ЧЕК; здесь только открываем папку и обновляем статус
                              await _fetchUserTickets();
                            },
                          ),
                          _TaskTile(
                            title: 'Пригласить друзей',
                            subtitle: 'За каждого друга: +1 билет',
                            icon: Icons.person_add_alt_1,
                            onTap: () async {
                              // Сохраняем состояние нажатия кнопки
                              await _saveTask2ButtonPressed();
                              
                              // Показываем индикатор загрузки
                               // start invite flow
                              
                              // Открываем список контактов с реферальной ссылкой
                              await _openContactsForInvite();
                              
                               // invite flow finished
                              
                              // Показываем уведомление об успехе
                              TelegramWebAppService.showAlert('Отлично! Список контактов открыт');
                              
                              // Обновляем состояние с бэка
                              await _fetchUserTickets();
                            },
                            done: (int.tryParse(friendsCounter.split('/').first) ?? 0) > 0 || _task2ButtonPressed,
                            taskNumber: 2,
                            counter: friendsCounter,
                            counterColor: friendsCounterColor,
                            onCheckTap: null,
                            isChecking: false,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4).copyWith(bottom: 22),
                      child: GradientButton(
                        text: 'Перейти в приложение',
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 350),
                            ),
                          );
                        },
                        enabled: isGoToAppButtonEnabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isInitialLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Тонкий штрих‑пунктирный круг
                        CustomPaint(
                          size: const Size(320, 320),
                          painter: DottedCirclePainter(
                            color: Colors.white.withOpacity(0.6),
                            circleSize: 180,
                            animationValue: (_initialDelayLeft % 2) / 2,
                          ),
                        ),
                        // Софт засвет в момент загрузки
                        Container(
                          width: 224,
                          height: 224,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF6EC7).withOpacity(0.25),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFF6EC7).withOpacity(0.25), blurRadius: 36, spreadRadius: 8),
                            ],
                          ),
                        ),
                        // Центровой мемодзи
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Color(0xFFF3E0E6), shape: BoxShape.circle),
                          child: const CircleAvatar(
                            radius: 36,
                            backgroundImage: AssetImage('assets/center_memoji.png'),
                            backgroundColor: Color(0xFF33272D),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          child: Text(
                            'Загрузка... ${_initialDelayLeft}s',
                            style: const TextStyle(color: Colors.white70, fontFamily: 'OpenSans', fontSize: 14),
                          ),
                        )
                      ],
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

class _SubscribeFolderCard extends StatelessWidget {
  final String folderCounter;
  final Color folderCounterColor;
  final bool isChecking;
  final VoidCallback? onCheckTap;
  final VoidCallback onSubscribeTap;

  const _SubscribeFolderCard({
    required this.folderCounter,
    required this.folderCounterColor,
    required this.isChecking,
    required this.onCheckTap,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.7),
        borderRadius: BorderRadius.zero,
      ),
      child: InkWell(
        onTap: onSubscribeTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF6EC7),
                    radius: 20,
                    child: const Icon(Icons.folder_special, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Подписаться на Telegram-папку',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Подписка на папку: +1 билет',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 80,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (folderCounter == '1/1') ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          border: Border.all(color: (folderCounter == '1/1') ? Colors.green : Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          folderCounter,
                          style: TextStyle(
                            color: folderCounterColor,
                            fontFamily: 'NauryzKeds',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: onCheckTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6EC7).withOpacity(0.2),
                            foregroundColor: const Color(0xFFFF6EC7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            side: const BorderSide(color: Color(0xFFFF6EC7)),
                            padding: EdgeInsets.zero,
                          ),
                          child: isChecking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF6EC7),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'ЧЕК',
                                  style: TextStyle(
                                    fontFamily: 'NauryzKeds',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool done;
  final int taskNumber;
  final String counter;
  final Color counterColor;
  final VoidCallback? onCheckTap;
  final bool isChecking;

  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.done,
    required this.taskNumber,
    required this.counter,
    required this.counterColor,
    this.onCheckTap,
    this.isChecking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.7),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          onTap: onTap,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFF6EC7),
              child: Icon(icon, color: Colors.white),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
            trailing: Container(
              width: 80,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                border: Border.all(color: done ? Colors.green : Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                counter,
                style: TextStyle(
                  color: counterColor,
                  fontFamily: 'NauryzKeds',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final String title;
  final RichText descriptionWidget;
  final String value;
  final IconData icon;
  final Color color;
  final bool showViewButton;
  final VoidCallback? onViewPressed;
  final bool showBuyButton;
  final VoidCallback? onBuyPressed;

  const _PrizeCard({
    required this.title,
    required this.descriptionWidget,
    required this.value,
    required this.icon,
    required this.color,
    this.showViewButton = false,
    this.onViewPressed,
    this.showBuyButton = false,
    this.onBuyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.zero, // Квадратные рамки
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'NauryzKeds',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          descriptionWidget,
          // Сумма призов в прямоугольнике снизу по центру
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.5)),
                borderRadius: BorderRadius.zero, // Квадратная рамка
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontFamily: 'NauryzKeds',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (showViewButton || showBuyButton) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (showViewButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'VIEW',
                        style: TextStyle(
                          fontFamily: 'NauryzKeds',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (showViewButton && showBuyButton) const SizedBox(width: 8),
                if (showBuyButton)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onBuyPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Text(
                        'BUY',
                        style: TextStyle(
                          fontFamily: 'NauryzKeds',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool enabled;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Colors.white, Color(0xFFFF6EC7)], // Бело-розовый градиент
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
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled ? Colors.black : Colors.white54, // Черный текст на бело-розовом фоне
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'NauryzKeds',
          ),
        ),
      ),
    );
  }
}