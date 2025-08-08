import 'dart:convert';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final String brand;
  final String description;
  final double price;
  final double? oldPrice; // Для скидок
  final int discountPercent; // Процент скидки
  final String size;
  final String? sizeClothing; // Детальные размеры
  final String? sizePants;
  final int? sizeShoesEu;
  final String sizeType; // 'clothing', 'shoes', 'one_size'
  final String color;
  final String masterId; // ID мастера/артиста, который продает
  final String masterName;
  final String masterTelegram;
  final String avatar;
  final List<String> gallery;
  final bool isNew; // Флаг "NEW"
  final bool isAvailable; // Доступность товара

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.description,
    required this.price,
    this.oldPrice,
    this.discountPercent = 0,
    required this.size,
    this.sizeClothing,
    this.sizePants,
    this.sizeShoesEu,
    this.sizeType = 'clothing',
    required this.color,
    required this.masterId,
    required this.masterName,
    required this.masterTelegram,
    required this.avatar,
    required this.gallery,
    this.isNew = false,
    this.isAvailable = true,
  });

  // Создание из JSON (API)
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(), // Конвертируем int в String
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      oldPrice: json['old_price'] != null ? (json['old_price'] as num).toDouble() : null,
      discountPercent: json['discount_percent'] as int? ?? 0,
      size: json['size'] as String,
      sizeClothing: json['size_clothing'] as String?,
      sizePants: json['size_pants'] as String?,
      sizeShoesEu: json['size_shoes_eu'] as int?,
      sizeType: json['size_type'] as String? ?? 'clothing',
      color: json['color'] as String,
      masterId: json['master_id'].toString(), // Конвертируем int в String
      masterName: json['master_name'] as String? ?? '',
      masterTelegram: json['master_telegram'] as String,
      avatar: json['avatar'] as String,
      gallery: List<String>.from(json['gallery'] ?? []),
      isNew: json['is_new'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  // Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'description': description,
      'price': price,
      'old_price': oldPrice,
      'discount_percent': discountPercent,
      'size': size,
      'color': color,
      'master_id': masterId,
      'master_name': masterName,
      'master_telegram': masterTelegram,
      'avatar': avatar,
      'gallery': gallery,
      'is_new': isNew,
      'is_available': isAvailable,
    };
  }

  // Получение цены со скидкой
  double get discountedPrice {
    if (discountPercent > 0) {
      return price * (1 - discountPercent / 100);
    }
    return price;
  }

  // Проверка наличия скидки
  bool get hasDiscount => discountPercent > 0;

  // Форматированная цена
  String get formattedPrice {
    return '${discountedPrice.toInt()} ₽';
  }

  // Форматированная старая цена
  String get formattedOldPrice {
    if (oldPrice != null) {
      return '${oldPrice!.toInt()} ₽';
    }
    return '';
  }

  // Получение размера для отображения
  String get displaySize {
    // Используем детальные размеры если они есть
    if (sizeType == 'clothing' && sizeClothing != null && sizeClothing!.isNotEmpty) {
      return sizeClothing!;
    } else if (sizeType == 'shoes' && sizeShoesEu != null) {
      return 'EU $sizeShoesEu';
    } else if (sizeType == 'one_size') {
      return 'ONE SIZE';
    } else if (sizePants != null && sizePants!.isNotEmpty) {
      return sizePants!;
    }
    
    // Fallback на общее поле size
    switch (size.toUpperCase()) {
      case 'ONE SIZE':
        return 'ONE SIZE';
      case 'XS':
        return 'XS';
      case 'S':
        return 'S';
      case 'M':
        return 'M';
      case 'L':
        return 'L';
      case 'XL':
        return 'XL';
      default:
        return size;
    }
  }

  // Проверка возможности апгрейда размера
  bool get canUpgradeSize {
    return category == 'Jewelry' || category == 'GTM BRAND' || category == 'Custom';
  }

  // Получение доступных размеров для апгрейда
  List<String> get availableSizes {
    if (!canUpgradeSize) return [size];
    
    switch (category) {
      case 'Jewelry':
        return ['ONE SIZE'];
      case 'GTM BRAND':
      case 'Custom':
        return ['XS', 'S', 'M', 'L', 'XL'];
      case 'Second':
        return ['XXS', 'XS', 'S', 'M', 'L', 'XL'];
      default:
        return [size];
    }
  }

  // Создание копии с новым размером
  ProductModel copyWithSize(String newSize) {
    return ProductModel(
      id: '${id}_$newSize', // Уникальный ID для каждого размера
      name: name,
      category: category,
      brand: brand,
      description: description,
      price: price,
      oldPrice: oldPrice,
      discountPercent: discountPercent,
      size: newSize,
      color: color,
      masterId: masterId,
      masterName: masterName,
      masterTelegram: masterTelegram,
      avatar: avatar,
      gallery: gallery,
      isNew: isNew,
      isAvailable: isAvailable,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, category: $category, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Модель корзины
class CartItem {
  final ProductModel product;
  final int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Создание из JSON (API)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  // Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  double get totalPrice => product.discountedPrice * quantity;

  CartItem copyWith({ProductModel? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.product.id == product.id;
  }

  @override
  int get hashCode => product.id.hashCode;
}

// Модель корзины
class Cart {
  final List<CartItem> items;

  Cart({this.items = const []});

  // Создание из JSON (API)
  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final items = itemsList.map((item) => CartItem.fromJson(item)).toList();
    return Cart(items: items);
  }

  // Конвертация в JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Добавление товара в корзину
  Cart addItem(ProductModel product) {
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      // Увеличиваем количество
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      return Cart(items: updatedItems);
    } else {
      // Добавляем новый товар
      return Cart(items: [...items, CartItem(product: product)]);
    }
  }

  // Удаление товара из корзины
  Cart removeItem(String productId) {
    return Cart(items: items.where((item) => item.product.id != productId).toList());
  }

  // Изменение количества товара
  Cart updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }
    
    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    return Cart(items: updatedItems);
  }

  // Очистка корзины
  Cart clear() {
    return Cart();
  }

  // Общая стоимость без скидки
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Скидка 8% на всю корзину
  double get discount {
    return subtotal * 0.08;
  }

  // Итоговая стоимость со скидкой
  double get total {
    return subtotal - discount;
  }

  // Количество товаров в корзине
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Проверка пустоты корзины
  bool get isEmpty => items.isEmpty;

  // Форматированная итоговая стоимость
  String get formattedTotal {
    return '${total.toInt()} ₽';
  }

  // Форматированная стоимость без скидки
  String get formattedSubtotal {
    return '${subtotal.toInt()} ₽';
  }

  // Форматированная скидка
  String get formattedDiscount {
    return '${discount.toInt()} ₽';
  }

  // Генерация текста для сообщения в Telegram
  String get telegramMessage {
    if (isEmpty) return 'Корзина пуста';
    
    final buffer = StringBuffer();
    buffer.writeln('🛒 *Корзина:*\n');
    
    for (final item in items) {
      buffer.writeln('• ${item.product.name}');
      buffer.writeln('  Размер: ${item.product.displaySize}');
      buffer.writeln('  Цвет: ${item.product.color}');
      buffer.writeln('  Количество: ${item.quantity}');
      buffer.writeln('  Цена: ${item.product.formattedPrice}');
      buffer.writeln('');
    }
    
    buffer.writeln('📊 *Итого:*');
    buffer.writeln('Подытог: ${formattedSubtotal}');
    buffer.writeln('Скидка 8%: -${formattedDiscount}');
    buffer.writeln('**Итого: ${formattedTotal}**');
    
    return buffer.toString();
  }
} 