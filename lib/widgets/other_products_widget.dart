import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/master_model.dart';
import '../services/api_service.dart';

class OtherProductsWidget extends StatefulWidget {
  final String? currentProductId;
  final String? category;
  final String? masterId;

  const OtherProductsWidget({
    Key? key,
    this.currentProductId,
    this.category,
    this.masterId,
  }) : super(key: key);

  @override
  State<OtherProductsWidget> createState() => _OtherProductsWidgetState();
}

class _OtherProductsWidgetState extends State<OtherProductsWidget> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _selectedCategory;
  String? _selectedMasterId;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _selectedMasterId = widget.masterId;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await ApiService.getProducts(
        category: _selectedCategory,
        masterId: _selectedMasterId,
      );

      // Фильтруем текущий товар
      final filteredProducts = products
          .where((product) => product.id != widget.currentProductId)
          .toList();

      setState(() {
        _products = filteredProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading other products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Другие товары',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_products.isNotEmpty)
                Text(
                  '${_products.length} товаров',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Фильтры
          if (_products.isNotEmpty) ...[
            _buildFilters(),
            const SizedBox(height: 16),
          ],

          // Список товаров
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_products.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Товары не найдены',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            _buildProductsGrid(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фильтры',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCategoryFilter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMasterFilter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Категория',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Все категории'),
        ),
        const DropdownMenuItem<String>(
          value: 'Jewelry',
          child: Text('Jewelry'),
        ),
        const DropdownMenuItem<String>(
          value: 'GTM BRAND',
          child: Text('GTM BRAND'),
        ),
        const DropdownMenuItem<String>(
          value: 'Custom',
          child: Text('Custom'),
        ),
        const DropdownMenuItem<String>(
          value: 'Second',
          child: Text('Second'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
        _loadProducts();
      },
    );
  }

  Widget _buildMasterFilter() {
    return FutureBuilder<List<MasterModel>>(
      future: ApiService.getArtists().then((list) => list.map(MasterModel.fromApiData).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Артист',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [],
            onChanged: (value) {},
          );
        }

        final artists = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: _selectedMasterId,
          decoration: const InputDecoration(
            labelText: 'Артист',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Все артисты'),
            ),
            ...artists.map((artist) => DropdownMenuItem<String>(
              value: artist.id,
              child: Text(artist.name),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedMasterId = value;
            });
            _loadProducts();
          },
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        // Навигация к деталям товара
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение товара
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      product.gallery.isNotEmpty 
                          ? product.gallery.first 
                          : product.avatar,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Бейдж "NEW"
                    if (product.isNew)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Бейдж скидки
                    if (product.hasDiscount)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${product.discountPercent}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Информация о товаре
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        if (product.hasDiscount)
                          Text(
                            product.formattedOldPrice,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 