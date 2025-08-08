// Автоматически сгенерированный код категорий
// Обновлен: 2025-08-05 12:15:00
// Синхронизировано с Django админ панелью
// ОСНОВНЫЕ КАТЕГОРИИ ДЛЯ MASTER CLOUD SCREEN

class MasterCloudCategories {
  // Основные категории для отображения в Master Cloud Screen (8 штук)
  static const List<String> categories = [
    'GTM BRAND',    // Товары
    'Jewelry',      // Товары  
    'Custom',       // Товары
    'Second',       // Товары
    'Tattoo',       // Услуги
    'Hair',         // Услуги
    'Nails',        // Услуги
    'Piercing',     // Услуги
  ];

  // Категории товаров (для перехода на product screen)
  static const List<String> productCategories = [
    'GTM BRAND',
    'Jewelry',
    'Custom', 
    'Second',
  ];

  // Категории услуг (для перехода на master detail screen)
  static const List<String> serviceCategories = [
    'Tattoo',
    'Hair',
    'Nails',
    'Piercing',
  ];
  
  // Проверка, является ли категория товарной
  static bool isProductCategory(String category) {
    return productCategories.contains(category);
  }
  
  // Проверка, является ли категория услугой
  static bool isServiceCategory(String category) {
    return serviceCategories.contains(category);
  }
  
  // Получение типа категории
  static String getCategoryType(String category) {
    if (isProductCategory(category)) {
      return 'product';
    } else if (isServiceCategory(category)) {
      return 'service';
    }
    return 'unknown';
  }
  
  // Получение категорий по типу
  static List<String> getCategoriesByType(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return productCategories;
      case 'service':
        return serviceCategories;
      default:
        return categories;
    }
  }
  
  // Получение отображаемого названия типа
  static String getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return 'Товары';
      case 'service':
        return 'Услуги';
      default:
        return 'Все';
    }
  }
  
  // Получение описания категории
  static String getCategoryDescription(String category) {
    switch (category) {
      case 'GTM BRAND':
        return 'Брендовые товары GTM';
      case 'Jewelry':
        return 'Украшения';
      case 'Custom':
        return 'Индивидуальные заказы';
      case 'Second':
        return 'Вторые руки';
      case 'Tattoo':
        return 'Татуировки';
      case 'Hair':
        return 'Парикмахерские услуги';
      case 'Nails':
        return 'Маникюр и педикюр';
      case 'Piercing':
        return 'Пирсинг';
      default:
        return '';
    }
  }
} 