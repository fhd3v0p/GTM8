import 'package:flutter/material.dart';
import '../services/artists_service.dart';
import '../services/telegram_webapp_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  bool _loading = false;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];
  List<dynamic> _artists = [];

  @override
  void initState() {
    super.initState();
    TelegramWebAppService.disableVerticalSwipe();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      // Загружаем статистику
      final stats = await ArtistsService.getStats();
      
      // Загружаем города
      final cities = await ArtistsService.getCities();
      
      // Загружаем категории
      final categories = await ArtistsService.getCategories();
      
      // Загружаем артистов
      final artists = await ArtistsService.getAllArtists();
      
      setState(() {
        _stats = stats;
        _cities = cities;
        _categories = categories;
        _artists = artists.map((a) => a.toJson()).toList();
        _loading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading test data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testArtistsByCity(String city) async {
    setState(() {
      _loading = true;
    });

    try {
      final artists = await ArtistsService.getArtistsByCity(city);
      setState(() {
        _artists = artists.map((a) => a.toJson()).toList();
        _loading = false;
      });
    } catch (e) {
      print('DEBUG: Error testing artists by city: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testArtistsByCategory(String category) async {
    setState(() {
      _loading = true;
    });

    try {
      final artists = await ArtistsService.getArtistsByCategory(category);
      setState(() {
        _artists = artists.map((a) => a.toJson()).toList();
        _loading = false;
      });
    } catch (e) {
      print('DEBUG: Error testing artists by category: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    ArtistsService.clearCache();
    await _loadData();
  }

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'API Test Screen',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NauryzKeds',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Кнопки действий
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6EC7),
                          ),
                          child: const Text('Reload Data'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _clearCache,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Clear Cache'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Статистика
                  if (_stats.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistics:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cities: ${_stats['cities_count'] ?? 0}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Categories: ${_stats['categories_count'] ?? 0}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Artists: ${_stats['artists_count'] ?? 0}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            'Cache Size: ${_stats['cache_size'] ?? 0}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Города
                  if (_cities.isNotEmpty) ...[
                    const Text(
                      'Cities:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cities.length,
                        itemBuilder: (context, index) {
                          final city = _cities[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _testArtistsByCity(city['name']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6EC7),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(city['name'] ?? 'Unknown'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Категории
                  if (_categories.isNotEmpty) ...[
                    const Text(
                      'Categories:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _testArtistsByCategory(category['name']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6EC7),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(category['name'] ?? 'Unknown'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Артисты
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artists (${_artists.length}):',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _artists.length,
                              itemBuilder: (context, index) {
                                final artist = _artists[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Name: ${artist['name'] ?? 'Unknown'}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                        'City: ${artist['city'] ?? 'Unknown'}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Category: ${artist['category'] ?? 'Unknown'}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Индикатор загрузки
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 