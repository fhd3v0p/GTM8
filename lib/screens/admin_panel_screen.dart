import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String apiBase = 'https://gtm.baby/api';
  
  // Данные для форм
  final _productFormKey = GlobalKey<FormState>();
  final _artistFormKey = GlobalKey<FormState>();
  final _channelFormKey = GlobalKey<FormState>();
  
  // Контроллеры для форм товаров
  final _productIdController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productCategoryController = TextEditingController();
  final _productBrandController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productOldPriceController = TextEditingController();
  final _productDiscountController = TextEditingController();
  final _productSizeController = TextEditingController();
  final _productColorController = TextEditingController();
  final _productMasterController = TextEditingController();
  final _productMasterTelegramController = TextEditingController();
  final _productAvatarController = TextEditingController();
  
  // Контроллеры для форм артистов
  final _artistIdController = TextEditingController();
  final _artistNameController = TextEditingController();
  final _artistCityController = TextEditingController();
  final _artistCategoryController = TextEditingController();
  final _artistTelegramController = TextEditingController();
  final _artistInstagramController = TextEditingController();
  final _artistTiktokController = TextEditingController();
  final _artistPinterestController = TextEditingController();
  final _artistAvatarController = TextEditingController();
  final _artistBioController = TextEditingController();
  
  // Список городов
  final List<String> _cities = [
    'Москва',
    'Санкт-Петербург', 
    'Новосибирск',
    'Казань',
    'Екатеринбург'
  ];
  
  String? _selectedArtistCity;
  String? _selectedArtistCategory;
  
  // Переменные для загрузки файлов
  File? _artistAvatarFile;
  List<File> _artistGalleryFiles = [];
  
  // Контроллеры для форм каналов
  final _channelUsernameController = TextEditingController();
  final _channelNameController = TextEditingController();
  final _channelDescriptionController = TextEditingController();
  
  // Состояние
  bool _productIsNew = false;
  bool _productIsAvailable = true;
  bool _channelIsActive = true;
  bool _channelRequired = true;
  String? _selectedProductCategory;
  String? _selectedProductSize;
  String? _selectedProductMaster;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _channels = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productIdController.dispose();
    _productNameController.dispose();
    _productCategoryController.dispose();
    _productBrandController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    _productOldPriceController.dispose();
    _productDiscountController.dispose();
    _productSizeController.dispose();
    _productColorController.dispose();
    _productMasterController.dispose();
    _productMasterTelegramController.dispose();
    _productAvatarController.dispose();
    _artistIdController.dispose();
    _artistNameController.dispose();
    _artistCityController.dispose();
    _artistCategoryController.dispose();
    _artistTelegramController.dispose();
    _artistInstagramController.dispose();
    _artistTiktokController.dispose();
    _artistPinterestController.dispose();
    _artistAvatarController.dispose();
    _artistBioController.dispose();
    _channelUsernameController.dispose();
    _channelNameController.dispose();
    _channelDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadProducts(),
        _loadArtists(),
        _loadChannels(),
        _loadAnalytics(),
      ]);
    } catch (e) {
      _showMessage('Ошибка загрузки данных: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http.get(Uri.parse('$apiBase/products'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['products'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadArtists() async {
    try {
      final response = await http.get(Uri.parse('$apiBase/artists'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _artists = List<Map<String, dynamic>>.from(data['artists'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading artists: $e');
    }
  }

  Future<void> _loadChannels() async {
    try {
      final response = await http.get(Uri.parse('$apiBase/subscription-channels'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _channels = List<Map<String, dynamic>>.from(data['channels'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading channels: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final response = await http.get(Uri.parse('$apiBase/products/analytics'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analytics = data;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _addProduct() async {
    if (!_productFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final productData = {
        'id': _productIdController.text,
        'name': _productNameController.text,
        'category': _selectedProductCategory,
        'brand': _productBrandController.text,
        'description': _productDescriptionController.text,
        'price': double.parse(_productPriceController.text),
        'old_price': _productOldPriceController.text.isNotEmpty 
            ? double.parse(_productOldPriceController.text) 
            : null,
        'discount_percent': int.parse(_productDiscountController.text),
        'size': _selectedProductSize,
        'color': _productColorController.text,
        'master_id': _selectedProductMaster,
        'avatar': _productAvatarController.text,
        'is_new': _productIsNew,
        'is_available': _productIsAvailable,
      };

      final response = await http.post(
        Uri.parse('$apiBase/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        _showMessage('Товар успешно добавлен!');
        _clearProductForm();
        await _loadProducts();
      } else {
        final error = jsonDecode(response.body);
        _showMessage('Ошибка: ${error['error']}', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addArtist() async {
    if (!_artistFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Генерируем уникальный ID артиста
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final artistId = 'artist_${timestamp}';
      
      // Создаем multipart request для загрузки файлов
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBase/artists'),
      );
      
      // Добавляем основные данные артиста
      request.fields['id'] = artistId;
      request.fields['name'] = _artistNameController.text;
      request.fields['city'] = _selectedArtistCity ?? _artistCityController.text;
      request.fields['category'] = _selectedArtistCategory ?? _artistCategoryController.text;
      request.fields['telegram'] = _artistTelegramController.text;
      request.fields['instagram'] = _artistInstagramController.text;
      request.fields['tiktok'] = _artistTiktokController.text;
      request.fields['pinterest'] = _artistPinterestController.text;
      request.fields['bio'] = _artistBioController.text;
      
      // Добавляем аватар если выбран
      if (_artistAvatarFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          _artistAvatarFile!.path,
        ));
      }
      
      // Добавляем файлы галереи
      for (int i = 0; i < _artistGalleryFiles.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'gallery_$i',
          _artistGalleryFiles[i].path,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _showMessage('Артист успешно добавлен!');
        _clearArtistForm();
        await _loadArtists();
      } else {
        final error = jsonDecode(responseData);
        _showMessage('Ошибка: ${error['error']}', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addChannel() async {
    if (!_channelFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final channelData = {
        'channel_username': _channelUsernameController.text,
        'channel_name': _channelNameController.text,
        'channel_description': _channelDescriptionController.text,
        'is_active': _channelIsActive,
        'required_for_giveaway': _channelRequired,
      };

      final response = await http.post(
        Uri.parse('$apiBase/subscription-channels'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(channelData),
      );

      if (response.statusCode == 200) {
        _showMessage('Канал успешно добавлен!');
        _clearChannelForm();
        await _loadChannels();
      } else {
        final error = jsonDecode(response.body);
        _showMessage('Ошибка: ${error['error']}', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearProductForm() {
    _productFormKey.currentState!.reset();
    _productIdController.clear();
    _productNameController.clear();
    _productBrandController.clear();
    _productDescriptionController.clear();
    _productPriceController.clear();
    _productOldPriceController.clear();
    _productDiscountController.clear();
    _productSizeController.clear();
    _productColorController.clear();
    _productMasterController.clear();
    _productMasterTelegramController.clear();
    _productAvatarController.clear();
    setState(() {
      _selectedProductCategory = null;
      _selectedProductSize = null;
      _selectedProductMaster = null;
      _productIsNew = false;
      _productIsAvailable = true;
    });
  }

  void _clearArtistForm() {
    _artistFormKey.currentState!.reset();
    _artistNameController.clear();
    _artistCityController.clear();
    _artistCategoryController.clear();
    _artistTelegramController.clear();
    _artistInstagramController.clear();
    _artistTiktokController.clear();
    _artistPinterestController.clear();
    _artistAvatarController.clear();
    _artistBioController.clear();
    setState(() {
      _selectedArtistCity = null;
      _selectedArtistCategory = null;
      _artistAvatarFile = null;
      _artistGalleryFiles.clear();
    });
  }
  
  // Методы для выбора файлов
  Future<void> _pickAvatarFile() async {
    // В веб-версии используем input file
    // Это упрощенная версия для демонстрации
    setState(() {
      _artistAvatarFile = null; // Сброс для демонстрации
    });
  }
  
  Future<void> _pickGalleryFiles() async {
    // В веб-версии используем input file
    // Это упрощенная версия для демонстрации
    setState(() {
      _artistGalleryFiles.clear(); // Сброс для демонстрации
    });
  }

  void _clearChannelForm() {
    _channelFormKey.currentState!.reset();
    _channelUsernameController.clear();
    _channelNameController.clear();
    _channelDescriptionController.clear();
    setState(() {
      _channelIsActive = true;
      _channelRequired = true;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('GTM Product Admin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Товары'),
            Tab(text: 'Артисты'),
            Tab(text: 'Каналы подписки'),
            Tab(text: 'Аналитика'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6EC7),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6EC7)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildArtistsTab(),
                _buildChannelsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _productFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Добавить новый товар', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productIdController,
                            decoration: const InputDecoration(labelText: 'ID товара *'),
                            validator: (value) => value?.isEmpty == true ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productNameController,
                            decoration: const InputDecoration(labelText: 'Название товара *'),
                            validator: (value) => value?.isEmpty == true ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedProductCategory,
                            decoration: const InputDecoration(labelText: 'Категория *'),
                            items: const [
                              DropdownMenuItem(value: 'Jewelry', child: Text('Jewelry')),
                              DropdownMenuItem(value: 'GTM BRAND', child: Text('GTM BRAND')),
                              DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                              DropdownMenuItem(value: 'Second', child: Text('Second')),
                            ],
                            onChanged: (value) => setState(() => _selectedProductCategory = value),
                            validator: (value) => value == null ? 'Обязательное поле' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productBrandController,
                            decoration: const InputDecoration(labelText: 'Бренд'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productColorController,
                            decoration: const InputDecoration(labelText: 'Цвет'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedProductSize,
                            decoration: const InputDecoration(labelText: 'Размер *'),
                            items: const [
                              DropdownMenuItem(value: 'ONE SIZE', child: Text('ONE SIZE')),
                              DropdownMenuItem(value: 'XXS', child: Text('XXS')),
                              DropdownMenuItem(value: 'XS', child: Text('XS')),
                              DropdownMenuItem(value: 'S', child: Text('S')),
                              DropdownMenuItem(value: 'M', child: Text('M')),
                              DropdownMenuItem(value: 'L', child: Text('L')),
                              DropdownMenuItem(value: 'XL', child: Text('XL')),
                            ],
                            onChanged: (value) => setState(() => _selectedProductSize = value),
                            validator: (value) => value == null ? 'Обязательное поле' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _productDescriptionController,
                      decoration: const InputDecoration(labelText: 'Описание'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _productPriceController,
                            decoration: const InputDecoration(labelText: 'Цена *'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value?.isEmpty == true ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productOldPriceController,
                            decoration: const InputDecoration(labelText: 'Старая цена'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productDiscountController,
                            decoration: const InputDecoration(labelText: 'Скидка (%)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedProductMaster,
                            decoration: const InputDecoration(labelText: 'Артист *'),
                            items: _artists.map((artist) => DropdownMenuItem<String>(
                              value: artist['id']?.toString(),
                              child: Text(artist['name']?.toString() ?? 'Unknown'),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedProductMaster = value),
                            validator: (value) => value == null ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productMasterTelegramController,
                            decoration: const InputDecoration(labelText: 'Telegram артиста'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _productAvatarController,
                            decoration: const InputDecoration(labelText: 'Аватар товара'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _productIsNew,
                          onChanged: (value) => setState(() => _productIsNew = value ?? false),
                        ),
                        const Text('Новинка'),
                        const SizedBox(width: 32),
                        Checkbox(
                          value: _productIsAvailable,
                          onChanged: (value) => setState(() => _productIsAvailable = value ?? true),
                        ),
                        const Text('Доступен'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addProduct,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6EC7)),
                          child: const Text('Добавить товар', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Обновить список', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Список товаров', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._products.map((product) => Card(
            child: ListTile(
              title: Text(product['name'] ?? 'Unknown'),
              subtitle: Text('Категория: ${product['category']} | Размер: ${product['size']} | Цена: ${product['price']} ₽'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editProduct(product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(product['id']),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _artistFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Добавить нового артиста', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _artistNameController,
                            decoration: const InputDecoration(labelText: 'Имя артиста *'),
                            validator: (value) => value?.isEmpty == true ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedArtistCity,
                            decoration: const InputDecoration(labelText: 'Город'),
                            items: _cities.map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            )).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedArtistCity = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedArtistCategory,
                            decoration: const InputDecoration(labelText: 'Категория'),
                            items: const [
                              DropdownMenuItem(value: 'Tattoo', child: Text('Tattoo')),
                              DropdownMenuItem(value: 'Hair', child: Text('Hair')),
                              DropdownMenuItem(value: 'Nails', child: Text('Nails')),
                              DropdownMenuItem(value: 'Piercing', child: Text('Piercing')),
                            ],
                            onChanged: (value) => setState(() => _selectedArtistCategory = value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _artistTelegramController,
                            decoration: const InputDecoration(labelText: 'Telegram'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _artistInstagramController,
                            decoration: const InputDecoration(labelText: 'Instagram'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _artistTiktokController,
                            decoration: const InputDecoration(labelText: 'TikTok'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _artistPinterestController,
                            decoration: const InputDecoration(labelText: 'Pinterest'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _artistAvatarController,
                            decoration: const InputDecoration(labelText: 'Аватар'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _artistBioController,
                      decoration: const InputDecoration(labelText: 'Биография'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickAvatarFile,
                            icon: const Icon(Icons.upload_file),
                            label: Text(_artistAvatarFile != null ? 'Аватар выбран' : 'Загрузить аватар'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickGalleryFiles,
                            icon: const Icon(Icons.photo_library),
                            label: Text(_artistGalleryFiles.isNotEmpty ? 'Галерея выбрана (${_artistGalleryFiles.length})' : 'Загрузить галерею'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addArtist,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6EC7)),
                          child: const Text('Добавить артиста', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _loadArtists,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Обновить список', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Список артистов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._artists.map((artist) => Card(
            child: ListTile(
              title: Text(artist['name'] ?? 'Unknown'),
              subtitle: Text('ID: ${artist['id']} | Город: ${artist['city'] ?? 'Не указан'} | Категория: ${artist['category'] ?? 'Не указана'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editArtist(artist),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteArtist(artist['id']),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildChannelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _channelFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Добавить канал для подписки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _channelUsernameController,
                            decoration: const InputDecoration(labelText: 'Username канала *'),
                            validator: (value) => value?.isEmpty == true ? 'Обязательное поле' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _channelNameController,
                            decoration: const InputDecoration(labelText: 'Название канала *'),
                            validator: (value) => value?.isEmpty == true ? 'Обязательное поле' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _channelDescriptionController,
                      decoration: const InputDecoration(labelText: 'Описание'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _channelIsActive,
                          onChanged: (value) => setState(() => _channelIsActive = value ?? true),
                        ),
                        const Text('Активен'),
                        const SizedBox(width: 32),
                        Checkbox(
                          value: _channelRequired,
                          onChanged: (value) => setState(() => _channelRequired = value ?? true),
                        ),
                        const Text('Обязателен для гивевея'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addChannel,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6EC7)),
                          child: const Text('Добавить канал', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _loadChannels,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Обновить список', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Список каналов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._channels.map((channel) => Card(
            child: ListTile(
              title: Text(channel['channel_name'] ?? 'Unknown'),
              subtitle: Text('Username: ${channel['channel_username']} | Статус: ${channel['is_active'] ? 'Активен' : 'Неактивен'} | Гивевей: ${channel['required_for_giveaway'] ? 'Обязателен' : 'Необязателен'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editChannel(channel),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteChannel(channel['id']),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Аналитика товаров', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_analytics != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Общая статистика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsCard('Общие просмотры', '${_analytics!['total_views'] ?? 0}'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnalyticsCard('Общие продажи', '${_analytics!['total_sales'] ?? 0}'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnalyticsCard('Общая выручка', '${_analytics!['total_revenue'] ?? 0} ₽'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Популярные товары', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...(_analytics!['popular_products'] as List? ?? []).map((product) => Card(
              child: ListTile(
                title: Text(product['name'] ?? 'Unknown'),
                subtitle: Text('Просмотры: ${product['views']} | Продажи: ${product['sales']} | Артист: ${product['master_name']}'),
              ),
            )).toList(),
          ] else ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Данные аналитики не загружены'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    // Заполняем форму данными товара
    _productIdController.text = product['id'] ?? '';
    _productNameController.text = product['name'] ?? '';
    _selectedProductCategory = product['category'];
    _productBrandController.text = product['brand'] ?? '';
    _productDescriptionController.text = product['description'] ?? '';
    _productPriceController.text = (product['price'] ?? 0).toString();
    _productOldPriceController.text = (product['old_price'] ?? '').toString();
    _productDiscountController.text = (product['discount_percent'] ?? 0).toString();
    _selectedProductSize = product['size'];
    _productColorController.text = product['color'] ?? '';
    _selectedProductMaster = product['master_id'];
    _productMasterTelegramController.text = product['master_telegram'] ?? '';
    _productAvatarController.text = product['avatar'] ?? '';
    _productIsNew = product['is_new'] ?? false;
    _productIsAvailable = product['is_available'] ?? true;
    
    setState(() {});
    
    // Переключаемся на вкладку товаров
    _tabController.animateTo(0);
    
    _showMessage('Заполните форму и нажмите "Обновить товар" для сохранения изменений');
  }

  Future<void> _deleteProduct(String? productId) async {
    if (productId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить этот товар?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$apiBase/products/$productId'));
      
      if (response.statusCode == 200) {
        _showMessage('Товар успешно удален!');
        await _loadProducts();
      } else {
        final error = jsonDecode(response.body);
        _showMessage('Ошибка: ${error['error']}', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editArtist(Map<String, dynamic> artist) async {
    // Заполняем форму данными артиста
    _artistIdController.text = artist['id'] ?? '';
    _artistNameController.text = artist['name'] ?? '';
    _artistCityController.text = artist['city'] ?? '';
    _artistCategoryController.text = artist['category'] ?? '';
    _artistTelegramController.text = artist['telegram'] ?? '';
    _artistInstagramController.text = artist['instagram'] ?? '';
    _artistTiktokController.text = artist['tiktok'] ?? '';
    _artistPinterestController.text = artist['pinterest'] ?? '';
    _artistAvatarController.text = artist['avatar'] ?? '';
    _artistBioController.text = artist['bio'] ?? '';
    
    setState(() {});
    
    // Переключаемся на вкладку артистов
    _tabController.animateTo(1);
    
    _showMessage('Заполните форму и нажмите "Обновить артиста" для сохранения изменений');
  }

  Future<void> _deleteArtist(String? artistId) async {
    if (artistId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить этого артиста?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$apiBase/artists/$artistId'));
      
      if (response.statusCode == 200) {
        _showMessage('Артист успешно удален!');
        await _loadArtists();
      } else {
        final error = jsonDecode(response.body);
        _showMessage('Ошибка: ${error['error']}', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editChannel(Map<String, dynamic> channel) async {
    // Заполняем форму данными канала
    _channelUsernameController.text = channel['channel_username'] ?? '';
    _channelNameController.text = channel['channel_name'] ?? '';
    _channelDescriptionController.text = channel['channel_description'] ?? '';
    _channelIsActive = channel['is_active'] ?? true;
    _channelRequired = channel['required_for_giveaway'] ?? true;
    
    setState(() {});
    
    // Переключаемся на вкладку каналов
    _tabController.animateTo(2);
    
    _showMessage('Заполните форму и нажмите "Обновить канал" для сохранения изменений');
  }

  Future<void> _deleteChannel(String? channelId) async {
    if (channelId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить этот канал?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$apiBase/subscription-channels/$channelId'));
      
      if (response.statusCode == 200) {
        _showMessage('Канал успешно удален!');
        await _loadChannels();
      } else {
        final error = jsonDecode(response.body);
        _showMessage('Ошибка: ${error['error']}', isError: true);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 