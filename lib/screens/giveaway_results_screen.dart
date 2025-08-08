import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class GiveawayResultsScreen extends StatefulWidget {
  final int giveawayId;
  
  const GiveawayResultsScreen({
    super.key,
    required this.giveawayId,
  });

  @override
  State<GiveawayResultsScreen> createState() => _GiveawayResultsScreenState();
}

class _GiveawayResultsScreenState extends State<GiveawayResultsScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGiveawayResults();
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
      body: _buildBody(),
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
              borderRadius: BorderRadius.circular(16),
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

    // Определяем цвет и иконку в зависимости от места
    Color cardColor;
    IconData placeIcon;
    String placeText;

    switch (placeNumber) {
      case 1:
        cardColor = const Color(0xFFFFD700); // Золотой
        placeIcon = Icons.emoji_events;
        placeText = '🥇 1 МЕСТО';
        break;
      case 2:
        cardColor = const Color(0xFFC0C0C0); // Серебряный
        placeIcon = Icons.emoji_events;
        placeText = '🥈 2 МЕСТО';
        break;
      case 3:
        cardColor = const Color(0xFFCD7F32); // Бронзовый
        placeIcon = Icons.emoji_events;
        placeText = '🥉 3 МЕСТО';
        break;
      default:
        cardColor = const Color(0xFF4A4A4A);
        placeIcon = Icons.star;
        placeText = '${placeNumber} МЕСТО';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        border: Border.all(color: cardColor, width: 2),
        borderRadius: BorderRadius.circular(12),
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
                if (isManualWinner) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'РУЧНОЙ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
} 