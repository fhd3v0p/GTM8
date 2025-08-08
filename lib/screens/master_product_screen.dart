import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/telegram_webapp_service.dart';
import '../services/api_service.dart';
// import '../services/cart_service.dart';
import 'package:url_launcher/url_launcher.dart';
// unused imports removed

class MasterProductScreen extends StatefulWidget {
  final String productId; // Изменяем на ID вместо готового продукта
  const MasterProductScreen({super.key, required this.productId});

  @override
  State<MasterProductScreen> createState() => _MasterProductScreenState();
}

class _MasterProductScreenState extends State<MasterProductScreen> {
  int? _galleryIndex;
  Cart _cart = Cart();
  bool _isLoading = true;
  ProductModel? _product;
  String? _error;
  String? _userId; // ID пользователя для работы с корзиной

  @override
  void initState() {
    super.initState();
    TelegramWebAppService.disableVerticalSwipe();
    _loadProduct();
    _loadUserCart();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await ApiService.getProduct(widget.productId);
      
      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Товар не найден';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки товара: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserCart() async {
    // Получаем ID пользователя из Telegram WebApp
    try {
      final userId = TelegramWebAppService.getUserId();
      if (userId != null) {
        _userId = userId;
        // Если потребуется, можно подгрузить корзину из бэкенда здесь
      }
    } catch (e) {
      print('Error loading user cart: $e');
    }
  }

  void _openGallery(int index) {
    setState(() {
      _galleryIndex = index;
    });
  }

  void _closeGallery() {
    setState(() {
      _galleryIndex = null;
    });
  }

  void _prevPhoto() {
    if (_galleryIndex != null && _galleryIndex! > 0) {
      setState(() {
        _galleryIndex = _galleryIndex! - 1;
      });
    }
  }

  void _nextPhoto() {
    if (_galleryIndex != null && _galleryIndex! < _product!.gallery.length - 1) {
      setState(() {
        _galleryIndex = _galleryIndex! + 1;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;
    setState(() {
      _cart = _cart.addItem(_product!);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_product!.name} добавлен в корзину'), backgroundColor: Colors.green),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCartModal(),
    );
  }

  Future<void> _buyNow() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Корзина пуста. Добавьте что-то в корзину'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _openTelegram();
  }

  void _openTelegram() async {
    if (_product == null) return;
    
    final message = _cart.telegramMessage;
    final url = 'https://t.me/${_product!.masterTelegram}?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть Telegram'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCartModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Корзина',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Список товаров
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'Корзина пуста',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cart.items.length,
                    itemBuilder: (context, index) {
                      final item = _cart.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Изображение товара
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.product.avatar,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Информация о товаре
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Размер: ${item.product.displaySize}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    Text(
                                      'Цвет: ${item.product.color}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.product.formattedPrice,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Количество
                              Column(
                                children: [
                                  Row(
                                    children: [
                                                                        IconButton(
                                    onPressed: () async {
                                      if (_userId == null) return;
                                      
                                      final newQuantity = item.quantity - 1;
                                      if (newQuantity <= 0) {
                                        setState(() { _cart = _cart.removeItem(item.product.id); });
                                      } else {
                                        setState(() { _cart = _cart.updateQuantity(item.product.id, newQuantity); });
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          if (_userId == null) return;
                                          
                                          setState(() { _cart = _cart.addItem(item.product); });
                                        },
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      if (_userId == null) return;
                                      
                                      setState(() { _cart = _cart.removeItem(item.product.id); });
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Итого
          if (!_cart.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Подытог:', style: TextStyle(fontSize: 16)),
                      Text(_cart.formattedSubtotal, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Скидка 8%:', style: TextStyle(fontSize: 16, color: Colors.green)),
                      Text('-${_cart.formattedDiscount}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Итого:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_cart.formattedTotal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _buyNow();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Купить',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF232026),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF232026),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                _error ?? 'Товар не найден',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF232026),
      body: Stack(
        children: [
          // Основной контент
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхняя секция с аватаром и информацией
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Аватар и основная информация
                      Row(
                        children: [
                          // Аватар
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(_product!.avatar),
                            onBackgroundImageError: (exception, stackTrace) {
                              // Обработка ошибки загрузки изображения
                            },
                          ),
                          const SizedBox(width: 16),
                          
                          // Информация о мастере
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product!.masterName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _product!.category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Название товара
                      Text(
                        _product!.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Бренд
                      Text(
                        _product!.brand,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Цена
                      Row(
                        children: [
                          if (_product!.hasDiscount) ...[
                            Text(
                              _product!.formattedOldPrice,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _product!.formattedPrice,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Размер
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _product!.displaySize,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Описание
                if (_product!.description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Описание',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _product!.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Мини-магазин
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Другие товары',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Здесь будет список других товаров
                      // Пока заглушка
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Другие товары будут здесь',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Отступ для кнопок
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // Кнопки внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF232026),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Кнопка корзины
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          onPressed: _showCart,
                          icon: const Icon(Icons.shopping_cart, color: Colors.white),
                          iconSize: 28,
                        ),
                        if (_cart.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Кнопка "Добавить в корзину"
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _addToCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Добавить в корзину',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Кнопка назад
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
} 