import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../services/telegram_webapp_service.dart';
import '../services/vpn_subscription_service.dart';
import 'ai_photo_search_screen.dart';
 
import 'city_selection_screen.dart';

class SearchMethodScreen extends StatefulWidget {
  const SearchMethodScreen({super.key});

  @override
  State<SearchMethodScreen> createState() => _SearchMethodScreenState();
}

class _SearchMethodScreenState extends State<SearchMethodScreen> {
  bool _isCheckingSubscription = false;
  bool _hasSubscription = false;
  bool _isLoading = false;
  bool _vpnEnabled = false; // Состояние VPN переключателя

  @override
  void initState() {
    super.initState();
    TelegramWebAppService.disableVerticalSwipe();
    _checkSubscription();
  }

  // Определение платформы не используется — удалено для чистоты

  Future<void> _checkSubscription() async {
    setState(() {
      _isCheckingSubscription = true;
    });

    try {
      print('🔍 Проверяем подписку...');
      final hasSub = await VpnSubscriptionService.checkSubscription();
      print('🔍 Результат проверки подписки: $hasSub');
      setState(() {
        _hasSubscription = hasSub;
        _isCheckingSubscription = false;
      });
    } catch (e) {
      print('❌ Ошибка проверки подписки: $e');
      setState(() {
        _isCheckingSubscription = false;
      });
      _showError('Ошибка проверки подписки: $e');
    }
  }

  void _showError(String message) {
    TelegramWebAppService.showAlert(message);
  }

  Future<void> _openVpnBot() async {
    final vpnBotUrl = 'https://t.me/GTMVPNROBOT';
    try {
      // Небольшая задержка для лучшего UX
      await Future.delayed(const Duration(milliseconds: 300));
      html.window.open(vpnBotUrl, '_blank');
    } catch (e) {
      print('Ошибка при открытии ссылки: $e');
      // Fallback - показываем алерт с ссылкой
      TelegramWebAppService.showAlert(
        '🔐 GTM VPN - Твой приватный доступ\n\n'
        '📱 Переходи к VPN боту:\n'
        '$vpnBotUrl\n\n'
        '💎 Получи приватный VPN:\n'
        '• 4K контент без ограничений\n'
        '• TikTok, Twitch, YouTube\n'
        '• Защищенное соединение\n\n'
        'Поддержка: https://t.me/glamour_SBT'
      );
    }
  }

  void _openTelegram() {
    // Открываем канал GTM в Telegram
    const url = 'https://t.me/G_T_MODEL';
    html.window.open(url, '_blank');
  }

  // _toggleVpn больше не используется: клики ведут напрямую к боту

  

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Фоновое изображение
          Positioned.fill(
            child: Image.asset(
              'assets/giveaway_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          // Затемнение
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
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
          // Основной контент
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Заголовок
                  const Text(
                    'Выберите способ\nпоиска',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NauryzKeds',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Кнопка Каталог
                  _buildMenuButton(
                    icon: Icons.grid_view_rounded,
                    title: 'Каталог',
                    subtitle: 'Все артисты GTM',
                    color: const Color(0xFFFF6EC7), // GTM розовый
                    onTap: () {
                      print('DEBUG: Кнопка каталога нажата');
                      try {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) {
                              print('DEBUG: Создаю CitySelectionScreen');
                              return const CitySelectionScreen();
                            },
                          ),
                        );
                        print('DEBUG: Навигация выполнена успешно');
                      } catch (e) {
                        print('DEBUG: Ошибка при навигации: $e');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Кнопка AI Поиск
                  _buildMenuButton(
                    icon: Icons.camera_alt_rounded,
                    title: 'AI Поиск',
                    subtitle: 'По фото-референсу',
                    color: const Color(0xFFFF6EC7), // GTM розовый
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AiPhotoSearchScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Кнопка VPN
                  _buildVpnButton(),
                  const SizedBox(height: 24),
                  
                  // Статус подписки
                  if (_isCheckingSubscription)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Проверка доступа...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'NauryzKeds',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else if (_hasSubscription)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Доступ открыт',
                            style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'NauryzKeds',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Подпишись на GTM',
                            style: TextStyle(
                              color: Colors.orange,
                              fontFamily: 'OpenSans',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),
                  // Нижний баннер с подписью
                  Text(
                    'GTM VPN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.4,
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

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero, // острые углы как в giveaway
          color: Colors.black.withOpacity(0.45), // затемнение как в giveaway
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontFamily: 'NauryzKeds',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'NauryzKeds',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVpnButton() {
    final vpnColor = _hasSubscription ? const Color(0xFFFF6EC7) : Colors.orange; // GTM розовый для подписчиков
    return GestureDetector(
      onTap: _isLoading ? null : _openVpnBot, // вся кнопка ведёт к боту
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero, // острые углы как в giveaway
          color: Colors.black.withOpacity(0.45), // затемнение как в giveaway
          border: Border.all(
            color: vpnColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: vpnColor.withOpacity(0.25),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Мемо-эмоджи + ключ
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF3E0E6),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('assets/center_memoji.png'),
                    backgroundColor: Color(0xFF33272D),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.vpn_key_rounded, color: vpnColor, size: 28),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Описание преимуществ VPN
                  Text(
                    'Бесплатный YouTube, Twitch и TikTok на скорости',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontFamily: 'OpenSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => _openTelegram(),
                            child: const Text(
                              'Подпишитесь на GTM',
                              style: TextStyle(
                                color: Colors.orange,
                                fontFamily: 'OpenSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Переключатель ВКЛ/ВЫКЛ
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  setState(() { _vpnEnabled = !_vpnEnabled; });
                  _openVpnBot();
                }, // ползунок: движется в зелёное состояние и ведёт к боту
                child: Container(
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _vpnEnabled ? Colors.greenAccent : Colors.grey.withOpacity(0.3),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _vpnEnabled ? 26 : 2,
                        top: 2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 