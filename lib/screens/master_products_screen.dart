import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/master_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class MasterProductsScreen extends StatefulWidget {
  final MasterModel master;
  final String category;

  const MasterProductsScreen({
    Key? key,
    required this.master,
    required this.category,
  }) : super(key: key);

  @override
  State<MasterProductsScreen> createState() => _MasterProductsScreenState();
}

class _MasterProductsScreenState extends State<MasterProductsScreen> {
  List<ProductModel> products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      print('🚨 DEBUG: Начинаем загрузку продуктов для мастера ${widget.master.id}');
      
      print('🚨 DEBUG: ID мастера из widget: ${widget.master.id}');
      print('🚨 DEBUG: Тип ID мастера: ${widget.master.id.runtimeType}');
      
      // Парсим ID мастера
      final masterId = int.tryParse(widget.master.id.toString()) ?? 0;
      
      // Проверяем, что ID не равен 0
      if (masterId == 0) {
        print('🚨 DEBUG: ОШИБКА! Не удалось получить корректный ID мастера');
        setState(() {
          _loading = false;
        });
        return;
      }
      
      print('🚨 DEBUG: Парсированный ID мастера: $masterId');
      
      // Загружаем товары мастера по категории
      final productsList = await ApiService.getProducts(
        masterId: masterId.toString(),
        category: widget.category,
      );
      
      print('🚨 DEBUG: Получено данных продуктов: ${productsList.length}');
      
      if (mounted) {
        setState(() {
          products = productsList;
          _loading = false;
        });
        
        print('🚨 DEBUG: Продукты загружены: ${products.length}');
        for (var product in products) {
          print('🚨 DEBUG: Продукт: ${product.name} (ID: ${product.id})');
        }
      }
    } catch (e) {
      print('🚨 DEBUG: Ошибка загрузки товаров: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
              'assets/master_detail_banner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
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
            child: Column(
              children: [
                const SizedBox(height: 64),
                // Заголовок
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Товары ${widget.master.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'NauryzKeds',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Категория: ${widget.category}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'NauryzKeds',
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Список товаров
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : products.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Товары пока не добавлены',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontFamily: 'NauryzKeds',
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Скоро здесь появятся товары ${widget.master.name}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontFamily: 'NauryzKeds',
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                ],
                              ),
                            )
                          : Column(
                              children: [

                                // Список продуктов
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Изображение товара
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: NetworkImage(product.avatar),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Информация о товаре
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'NauryzKeds',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product.description,
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontFamily: 'NauryzKeds',
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${product.price} ₽',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'NauryzKeds',
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (product.oldPrice != null && product.oldPrice! > product.price)
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 8),
                                                          child: Text(
                                                            '${product.oldPrice} ₽',
                                                            style: TextStyle(
                                                              color: Colors.white.withOpacity(0.5),
                                                              fontFamily: 'NauryzKeds',
                                                              fontSize: 14,
                                                              decoration: TextDecoration.lineThrough,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Кнопка "Купить"
                                            GestureDetector(
                                              onTap: () {
                                                // Формируем текст сообщения
                                                final discountPrice = (product.price * 0.92).round(); // 8% скидка
                                                final message = Uri.encodeComponent(
                                                  'Привет! Хочу купить ${product.name}, цена со скидкой 8% - $discountPrice ₽, спасибо!'
                                                );
                                                final telegramUrl = 'https://t.me/GTM_ADM?text=$message';
                                                
                                                // Открываем Telegram
                                                launchUrl(Uri.parse(telegramUrl));
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6EC7),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Text(
                                                  'Купить',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'NauryzKeds',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
} 