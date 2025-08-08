import 'dart:async';
import 'package:flutter/material.dart';
import '../services/telegram_webapp_service.dart';
import '../services/supabase_service.dart';

class InviteFriendsScreen extends StatefulWidget {
  final String? referralCode;
  
  const InviteFriendsScreen({super.key, this.referralCode});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  bool _isLoading = false;
  String? _referralCode;
  String? _referralLink;
  int _invitesSent = 0;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
    TelegramWebAppService.disableVerticalSwipe();
  }

  Future<void> _loadReferralCode() async {
    final userId = TelegramWebAppService.getUserId();
    if (userId != null) {
      try {
        final telegramId = int.tryParse(userId);
        if (telegramId == null) {
          throw Exception('Некорректный Telegram ID');
        }

        final supabase = SupabaseService();
        final user = await supabase.getUser(telegramId);
        final code = user?['referral_code']?.toString();

        if (code != null && code.isNotEmpty) {
          setState(() {
            _referralCode = code;
            _referralLink = "https://t.me/GTM_ROBOT?start=$_referralCode";
          });
          return;
        }
      } catch (e) {
        print('Error loading referral code: $e');
      }
    }
    // Ошибка — не используем клиентские рефкоды
    setState(() {
      _referralCode = null;
      _referralLink = null;
    });
    TelegramWebAppService.showAlert('Не удалось получить реферальную ссылку. Попробуйте позже.');
  }



  Future<void> _shareWithFriends() async {
    setState(() => _isLoading = true);
      final success = await TelegramWebAppService.inviteFriendsWithShare();
    setState(() => _isLoading = false);
      if (success) {
      // Всё ок, диалог открылся
      } else {
      // Fallback: показать ссылку
    }
  }

  // Убрано: не используется

  // Убрано: не используется

  void _showLinkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Ссылка для приглашения',
          style: TextStyle(color: Colors.white, fontFamily: 'NauryzKeds'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Скопируйте эту ссылку и отправьте друзьям:',
              style: TextStyle(color: Colors.white, fontFamily: 'NauryzKeds'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.white24),
              ),
              child: SelectableText(
                _referralLink ?? 'Ошибка генерации ссылки',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'За каждого приглашенного друга получите +100 XP!',
              style: TextStyle(color: Colors.green, fontFamily: 'NauryzKeds', fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Color(0xFFFF6EC7)),
            ),
          ),
        ],
      ),
    );
  }

  // Убрано: не используется

  // Убрано: не используется

  void _showSuccess(String message) {
    TelegramWebAppService.showAlert(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/giveaway_banner.png',
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Поделиться с друзьями',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NauryzKeds',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Пригласи друзей и получи бонусы',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'NauryzKeds',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Информация о бонусах
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: Color(0xFFFF6EC7), size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Бонусы за приглашения:',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'NauryzKeds',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 12),
                            Text(
                              '+100 XP тебе за каждого друга',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'NauryzKeds',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 12),
                            Text(
                              '+100 XP другу за регистрацию',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'NauryzKeds',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Шанс выиграть призы на 123,500₽',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'NauryzKeds',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Статистика приглашений
                  if (_invitesSent > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Приглашений отправлено: $_invitesSent',
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'NauryzKeds',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Кнопка поделиться
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _shareWithFriends,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.share, color: Colors.white, size: 28),
                      label: Text(
                        _isLoading ? 'Загрузка...' : 'Показать ссылку',
                        style: const TextStyle(
                          fontFamily: 'NauryzKeds',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6EC7),
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Дополнительная информация
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Как это работает:',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NauryzKeds',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Нажмите "Поделиться с друзьями"\n'
                          '2. Выберите друзей из контактов или чатов\n'
                          '3. Отправьте им приглашение\n'
                          '4. Получите бонусы за каждого друга!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'NauryzKeds',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 