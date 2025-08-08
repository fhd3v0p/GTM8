import 'package:flutter/material.dart';
import 'giveaway_screen.dart';
import 'city_selection_screen.dart';
import 'master_join_info_screen.dart';
import 'choose_search_mode_screen.dart';
import '../services/api_service.dart';
import '../services/telegram_webapp_service.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = screenWidth * 0.45;
    final overlap = circleSize * 0.3;

    return Scaffold(
      backgroundColor: Colors.black,
      // Убрали AppBar и верхнюю стрелку
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/role_selection_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.25),
            ),
          ),
          // Контент
          Center(
            child: SizedBox(
              height: circleSize + overlap,
              width: circleSize * 2 - overlap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Круг "Клиент"
                  Positioned(
                    left: 0,
                    child: _RoleCircle(
                      label: 'client',
                      icon: Icons.person_outline,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChooseSearchModeScreen()),
                        );
                      },
                      size: circleSize,
                    ),
                  ),
                  // Круг "Артист"
                  Positioned(
                    right: 0,
                    child: _RoleCircle(
                      label: 'artist',
                      icon: Icons.star_outline,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MasterJoinInfoScreen()),
                        );
                      },
                      size: circleSize,
                    ),
                  ),
                  // Буква "Я" в центре пересечения
                  Text(
                    'Я',
                    style: TextStyle(
                      fontFamily: 'NauryzKeds',
                      fontSize: 70, // Подберите максимальный размер под ваш дизайн
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Верхняя стрелка назад (как на CitySelectionScreen)
          Positioned(
            top: 36,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GiveawayScreen()),
                );
              },
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCircle extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _RoleCircle({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.size,
    Key? key,
  }) : super(key: key);

  @override
  State<_RoleCircle> createState() => _RoleCircleState();
}

class _RoleCircleState extends State<_RoleCircle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        onHighlightChanged: (value) {
          setState(() {
            _pressed = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.28) // осветление при нажатии
                : Colors.white.withOpacity(0.13),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.7),
              width: 4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Color(0xFFFF6EC7), size: 48),
              const SizedBox(height: 18),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}