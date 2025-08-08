import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MasterJoinInfoScreen extends StatefulWidget {
  const MasterJoinInfoScreen({super.key});

  @override
  State<MasterJoinInfoScreen> createState() => _MasterJoinInfoScreenState();
}

class _MasterJoinInfoScreenState extends State<MasterJoinInfoScreen> with TickerProviderStateMixin {
  final List<_AdvantageItem> advantages = [
    _AdvantageItem(
      icon: Icons.schedule,
      text: '1. Постоянная занятость\nКлиенты находят вас через нашу платформу — ваш график всегда заполнен, поток клиентов не прекращается.',
    ),
    _AdvantageItem(
      icon: Icons.trending_up,
      text: '2. Ваше творчество — наш контент\nВаши работы становятся частью нашего контента: публикации, истории, специальные проекты и розыгрыши.',
    ),
    _AdvantageItem(
      icon: Icons.star,
      text: '3. Профессиональный рост\nС Gotham\'s Top Model вы входите в сообщество лучших в своем деле: участие в челленджах, повышение цен, рост клиентской базы и меньше рутины.',
    ),
  ];

  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _offsetAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < advantages.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0, -1.2),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.elasticOut)).animate(controller);
      final fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeIn),
      );
      _controllers.add(controller);
      _offsetAnimations.add(offset);
      _fadeAnimations.add(fade);
    }
    _runAnimations();
  }

  Future<void> _runAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/master_join_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 22),
                // Кнопка назад теперь над фразой FOR ARTISTS
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).maybePop(),
                      splashRadius: 24,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'FOR ARTISTS',
                    style: const TextStyle(
                      fontFamily: 'NauryzKeds',
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      itemCount: advantages.length,
                      itemBuilder: (context, i) {
                        final item = advantages[i];
                        return AnimatedBuilder(
                          animation: _controllers[i],
                          builder: (context, child) => FadeTransition(
                            opacity: _fadeAnimations[i],
                            child: SlideTransition(
                              position: _offsetAnimations[i],
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900]!.withOpacity(0.7),
                                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(item.icon, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'OpenSans',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Кнопка присоединиться с теми же отступами, что и баннеры
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24, top: 0),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFFF6EC7),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.zero,
                        onTap: () async {
                          final url = 'https://t.me/GTM_ADM?text=${Uri.encodeComponent("Привет! Хочу узнать условия размещения в приложении для креаторов. Спасибо!")}';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Center(
                          child: Text(
                            'ПРИСОЕДИНИТЬСЯ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'NauryzKeds',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
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

class _AdvantageItem {
  final IconData icon;
  final String text;
  const _AdvantageItem({required this.icon, required this.text});
}
