import 'package:flutter/material.dart';
import '../models/master_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'master_product_detail.dart';

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
    // Этот экран — список товаров по мастеру/категории.
    // Детальная карточка — master_product_detail.dart.
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.92,
                          alignment: Alignment.center,
                          child: Text(
                            'Товары ${widget.master.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'NauryzKeds',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Категория: ${widget.category}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'OpenSans',
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
                                   color: Colors.black.withOpacity(0.22),
                                   borderRadius: BorderRadius.zero,
                                          border: Border.all(
                                     color: Colors.white24,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Изображение товара
                                      GestureDetector(
                                       onTap: () {
                                         Navigator.of(context).push(
                                           MaterialPageRoute(
                                             builder: (_) => MasterProductScreen(productId: product.id),
                                           ),
                                         );
                                       },
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.zero,
                                            border: Border.all(color: Colors.black, width: 1),
                                            image: DecorationImage(
                                              image: NetworkImage(product.avatar),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                            // Информация о товаре
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                           FractionallySizedBox(
                                             widthFactor: 0.8,
                                             alignment: Alignment.centerLeft,
                                             child: Text(
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
                                           ),
                                                  const SizedBox(height: 4),
                                            FractionallySizedBox(
                                             widthFactor: 0.92,
                                             alignment: Alignment.centerLeft,
                                             child: Text(
                                               product.description,
                                               style: const TextStyle(
                                                 color: Colors.white70,
                                                 fontFamily: 'OpenSans',
                                                 fontSize: 12,
                                               ),
                                               maxLines: 2,
                                               overflow: TextOverflow.ellipsis,
                                               textAlign: TextAlign.left,
                                             ),
                                           ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                               Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                 decoration: BoxDecoration(
                                                   color: Colors.black.withOpacity(0.39),
                                                   border: Border.all(color: Colors.white24, width: 1),
                                                 ),
                                                 child: Row(
                                                   children: [
                                                     if (product.oldPrice != null && product.oldPrice! > product.price)
                                                       Padding(
                                                         padding: const EdgeInsets.only(right: 8),
                                                         child: Text(
                                                           '${product.oldPrice!.toInt()} ₽',
                                                           style: const TextStyle(
                                                             color: Colors.white70,
                                                             decoration: TextDecoration.lineThrough,
                                                             fontSize: 14,
                                                           ),
                                                         ),
                                                       ),
                                                     Text(
                                                       '${product.price.toInt()} ₽',
                                                       style: const TextStyle(
                                                         color: Colors.white,
                                                         fontFamily: 'NauryzKeds',
                                                         fontSize: 18,
                                                         fontWeight: FontWeight.bold,
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                     // Кнопка перехода в деталь
                                     IconButton(
                                       onPressed: () {
                                         Navigator.of(context).push(
                                           MaterialPageRoute(
                                             builder: (_) => MasterProductScreen(productId: product.id),
                                           ),
                                         );
                                       },
                                       icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
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