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
  // String? _userId; // ID пользователя для работы с корзиной
  String? _selectedSize;
  bool _galleryDescriptionExpanded = false;

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
      TelegramWebAppService.getUserId();
      // Если потребуется, можно подгрузить корзину из бэкенда здесь
    } catch (e) {
      print('Error loading user cart: $e');
    }
  }

  void _openGallery(int index) {
    setState(() { _galleryIndex = index; });
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
    final base = _product!;
    final ProductModel item = (_selectedSize != null && _selectedSize!.isNotEmpty)
        ? base.copyWithSize(_selectedSize!)
        : base;
    setState(() { _cart = _cart.addItem(item); });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${item.name} добавлен в корзину'),
        backgroundColor: const Color(0xFFFF6EC7),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 12,
          right: 12,
        ),
      ),
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
    print('[BUY_NOW] pressed');
    if (_cart.isEmpty) {
      // Если корзина пуста — формируем времочное сообщение по текущему товару
      if (_product == null) return;
      final ProductModel base = _product!;
      final ProductModel item = (_selectedSize != null && _selectedSize!.isNotEmpty)
          ? base.copyWithSize(_selectedSize!)
          : base;
      final tempMessage = _buildSingleProductMessage(item);
      print('[BUY_NOW] cart empty → using single item message');
      await _openTelegram(overrideMessage: tempMessage);
      return;
    }

    await _openTelegram();
  }

  Future<void> _openTelegram({String? overrideMessage}) async {
    if (_product == null) return;
    final message = overrideMessage ?? _cart.telegramMessage;
    print('[OPEN_TELEGRAM] message length=${message.length}');
    String? bookingUrl;
    try {
      final artistIdInt = int.tryParse(_product!.artistId);
      if (artistIdInt != null) {
        final artist = await ApiService.getArtist(artistIdInt);
        bookingUrl = artist?['booking_url'] as String?;
        print('[OPEN_TELEGRAM] fetched booking_url=$bookingUrl');
      }
    } catch (e) {
      print('[OPEN_TELEGRAM] getArtist error: $e');
    }
    String baseUrl;
    if (bookingUrl != null && bookingUrl.isNotEmpty) {
      baseUrl = bookingUrl;
    } else {
      // Нормализуем username: убираем @ если есть
      final raw = _product!.masterTelegram;
      final handle = raw.startsWith('@') ? raw.substring(1) : raw;
      baseUrl = 'https://t.me/$handle';
    }
    final url = '$baseUrl?text=${Uri.encodeComponent(message)}';
    print('[OPEN_TELEGRAM] opening: $url');
    final uri = Uri.parse(url);
    final can = await canLaunchUrl(uri);
    print('[OPEN_TELEGRAM] canLaunch=$can');
    if (can) {
      final ok = await launchUrl(uri);
      print('[OPEN_TELEGRAM] launch result=$ok');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть Telegram'), backgroundColor: Colors.red),
      );
    }
  }

  String _buildSingleProductMessage(ProductModel item) {
    final buffer = StringBuffer();
    buffer.writeln('Привет, интересует данный товар со скидкой, проконсультируйте меня 🙏');
    buffer.writeln('');
    buffer.writeln('🛒 Товар:');
    buffer.writeln('• ${item.name}');
    buffer.writeln('  Размер: ${item.displaySize}');
    buffer.writeln('  Цвет: ${item.color}');
    buffer.writeln('  Количество: 1');
    buffer.writeln('  Цена: ${item.formattedPrice}');
    buffer.writeln('');
    buffer.writeln('Скидка 8% применяется при оформлении.');
    return buffer.toString();
  }

  Widget _buildCartModal() {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
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
                                            final newQuantity = item.quantity - 1;
                                            print('[CART][-] before qty=${item.quantity} id=${item.product.id} -> new=$newQuantity');
                                            if (newQuantity <= 0) {
                                              setState(() { _cart = _cart.removeItem(item.product.id); });
                                              print('[CART][-] removed item');
                                              setModalState(() {});
                                            } else {
                                              setState(() { _cart = _cart.updateQuantity(item.product.id, newQuantity); });
                                              print('[CART][-] after qty=${_cart.items[index].quantity}');
                                              setModalState(() {});
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
                                          print('[CART][+] before qty=${item.quantity} id=${item.product.id}');
                                          setState(() { _cart = _cart.addItem(item.product); });
                                          final pos = _cart.items.indexWhere((it) => it.product.id == item.product.id);
                                          if (pos != -1) {
                                            print('[CART][+] after qty=${_cart.items[pos].quantity}');
                                          }
                                          setModalState(() {});
                                        },
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      print('[CART][DEL] remove id=${item.product.id}');
                                      setState(() { _cart = _cart.removeItem(item.product.id); });
                                      print('[CART][DEL] items left=${_cart.items.length}');
                                      setModalState(() {});
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
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Товар не найден',
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: const Color(0xFF232026),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      FractionallySizedBox(
                        widthFactor: 0.89,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () => _openGallery(0),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.zero,
                                    image: DecorationImage(
                                      image: NetworkImage(product.avatar),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.brand, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                                const SizedBox(height: 12),
                                const Text('Размер', style: TextStyle(color: Colors.white, fontSize: 14)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: product.availableSizes.map((s) {
                                    final bool selected = _selectedSize == s || (_selectedSize == null && s == product.displaySize);
                                    return GestureDetector(
                                      onTap: () => setState(() { _selectedSize = s; }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: selected ? const Color(0xFFFF6EC7).withOpacity(0.15) : Colors.transparent,
                                          border: Border.all(color: selected ? const Color(0xFFFF6EC7) : Colors.white24, width: 1),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Text(
                                          s,
                                          style: TextStyle(
                                            color: selected ? const Color(0xFFFF6EC7) : Colors.white,
                                            fontFamily: 'OpenSans',
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.39),
                                    border: Border.all(color: Colors.white24, width: 1),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (product.hasDiscount) ...[
                                        Text(product.formattedOldPrice, style: const TextStyle(color: Colors.white70, decoration: TextDecoration.lineThrough, fontSize: 16)),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(product.formattedPrice, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Builder(builder: (context) {
                                        final bool requiresSize = product.sizeType != 'one_size';
                                        final bool hasSize = !requiresSize || (_selectedSize != null && _selectedSize!.isNotEmpty);
                                        final Color activePink = const Color(0xFFFF6EC7);
                                        return ElevatedButton(
                                          onPressed: () async {
                                            if (!hasSize) {
                                              final messenger = ScaffoldMessenger.of(context);
                                              messenger.hideCurrentSnackBar();
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: const Text('Пожалуйста, выберите размер'),
                                                  backgroundColor: activePink,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: EdgeInsets.only(
                                                    top: MediaQuery.of(context).padding.top + 12,
                                                    left: 12,
                                                    right: 12,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            await _addToCart();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: hasSize ? activePink : activePink.withOpacity(0.1),
                                            foregroundColor: hasSize ? Colors.white : Colors.white70,
                                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                          ),
                                          child: const Text('В корзину', style: TextStyle(fontWeight: FontWeight.bold)),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _buyNow,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Colors.white),
                                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: const Text('Купить'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (product.description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Описание', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                if (product.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      product.description,
                      style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5, fontFamily: 'OpenSans'),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_galleryIndex != null) ...[
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.18))),
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
                    _nextPhoto();
                  } else if (details.primaryVelocity! > 0) {
                    _prevPhoto();
                  }
                },
                child: Builder(
                  builder: (context) {
                    final images = (product.gallery.isNotEmpty) ? product.gallery : <String>[product.avatar];
                    final index = _galleryIndex!.clamp(0, images.length - 1);
                    return Stack(
                      children: [
                        Positioned(
                          top: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: Text('${index + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontFamily: 'OpenSans', fontSize: 12)),
                            ),
                          ),
                        ),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              images[index],
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                height: MediaQuery.of(context).size.height * 0.6,
                                color: Colors.grey[800],
                                child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64)),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: MediaQuery.of(context).size.width * 0.85,
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  color: Colors.grey[800],
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                                );
                              },
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width * 0.85,
                              height: MediaQuery.of(context).size.height * 0.6,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header row and collapse button (square with hover inversion)
                                if (_galleryDescriptionExpanded)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() { _galleryDescriptionExpanded = false; });
                                        },
                                        style: ButtonStyle(
                                          shape: MaterialStateProperty.all(const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                          side: MaterialStateProperty.all(const BorderSide(color: Colors.white24)),
                                          foregroundColor: MaterialStateProperty.resolveWith((states) {
                                            if (states.contains(MaterialState.hovered)) return Colors.black;
                                            return Colors.white;
                                          }),
                                          backgroundColor: MaterialStateProperty.resolveWith((states) {
                                            if (states.contains(MaterialState.hovered)) return Colors.white;
                                            return Colors.transparent;
                                          }),
                                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                        ),
                                        child: const Text('Свернуть'),
                                      ),
                                    ],
                                  ),

                                // Description content and price only when expanded
                                if (_galleryDescriptionExpanded) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    product.description,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35, fontFamily: 'OpenSans'),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (product.hasDiscount) ...[
                                            Text(product.formattedOldPrice, style: const TextStyle(color: Colors.white70, decoration: TextDecoration.lineThrough, fontSize: 16)),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(product.formattedPrice, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(border: Border.all(color: Colors.white24, width: 1), borderRadius: BorderRadius.circular(6)),
                                            child: Text('${product.category} · ${product.displaySize}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () async { await _buyNow(); },
                                        style: ButtonStyle(
                                          shape: MaterialStateProperty.all(const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                          foregroundColor: MaterialStateProperty.resolveWith((states) {
                                            if (states.contains(MaterialState.hovered)) return Colors.white;
                                            return Colors.black;
                                          }),
                                          backgroundColor: MaterialStateProperty.resolveWith((states) {
                                            if (states.contains(MaterialState.hovered)) return Colors.black;
                                            return Colors.white;
                                          }),
                                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                        ),
                                        child: const Text('Купить'),
                                      ),
                                    ],
                                  ),
                                ]
                                else ...[
                                  // Collapsed state: only small 'Показать описание' button shown
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() { _galleryDescriptionExpanded = true; });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white24),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      ),
                                      child: const Text('Показать описание'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (index > 0)
                          Positioned(
                            left: 12,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 38),
                                onPressed: _prevPhoto,
                                splashRadius: 28,
                              ),
                            ),
                          ),
                        if (index < images.length - 1)
                          Positioned(
                            right: 12,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 38),
                                onPressed: _nextPhoto,
                                splashRadius: 28,
                              ),
                            ),
                          ),
                        Positioned(
                          top: 32,
                          right: 24,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 36),
                            onPressed: _closeGallery,
                            splashRadius: 28,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF232026),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.zero,
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
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${_cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (product.sizeType != 'one_size' && (_selectedSize == null || _selectedSize!.isEmpty)) ? null : () async { await _addToCart(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6EC7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text('Добавить в корзину', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 