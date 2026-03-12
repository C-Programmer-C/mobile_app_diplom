import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/models/supplier.dart';
import 'package:mobile_app/models/review.dart';
import 'package:mobile_app/providers/cart_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/database/database_helper.dart';
import 'package:mobile_app/screens/order/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Supplier? _supplier;
  List<Review> _reviews = [];
  List<Product> _similarProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final db = await DatabaseHelper().database;

    if (widget.product.supplierId != null) {
      final suppliers = await db.query(
        'suppliers',
        where: 'id = ?',
        whereArgs: [widget.product.supplierId],
      );
      if (suppliers.isNotEmpty) {
        _supplier = Supplier.fromMap(suppliers.first);
      }
    }

    final reviews = await db.query(
      'reviews',
      where: 'product_id = ?',
      whereArgs: [widget.product.id],
      orderBy: 'created_at DESC',
    );
    _reviews = reviews.map((map) => Review.fromMap(map)).toList();

    final similarProducts = await db.query(
      'products',
      where: 'category_id = ? AND id != ?',
      whereArgs: [widget.product.categoryId, widget.product.id],
      limit: 4,
    );
    _similarProducts = similarProducts.map((map) => Product.fromMap(map)).toList();

    setState(() {
      _isLoading = false;
    });
  }

  void _showSupplierInfo() {
    if (_supplier == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _supplier!.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_supplier!.description != null) ...[
              Text(
                _supplier!.description!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
            ],
            _buildInfoRow(Icons.star, 'Рейтинг', _supplier!.rating?.toStringAsFixed(1) ?? 'Нет'),
            _buildInfoRow(Icons.inventory, 'Товаров', _supplier!.totalProducts?.toString() ?? '0'),
            if (_supplier!.phone != null)
              _buildInfoRow(Icons.phone, 'Телефон', _supplier!.phone!),
            if (_supplier!.email != null)
              _buildInfoRow(Icons.email, 'Email', _supplier!.email!),
            if (_supplier!.address != null)
              _buildInfoRow(Icons.location_on, 'Адрес', _supplier!.address!),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addReview() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Войдите в аккаунт, чтобы оставить отзыв')),
      );
      return;
    }

    final rating = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Оцените товар'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Выберите оценку от 1 до 5'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(Icons.star, color: Colors.amber),
                  onPressed: () => Navigator.pop(context, (index + 1).toDouble()),
                );
              }),
            ),
          ],
        ),
      ),
    );

    if (rating != null) {
      final commentController = TextEditingController();
      final comment = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Оставить отзыв'),
          content: TextField(
            controller: commentController,
            decoration: InputDecoration(
              labelText: 'Ваш отзыв',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, commentController.text),
              child: Text('Отправить'),
            ),
          ],
        ),
      );

      if (comment != null && comment.isNotEmpty) {
        final db = await DatabaseHelper().database;
        final user = authProvider.currentUser;
        await db.insert('reviews', {
          'product_id': widget.product.id,
          'user_id': user?.id,
          'user_name': user?.fullName ?? user?.username ?? 'Пользователь',
          'rating': rating,
          'comment': comment,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Спасибо за отзыв!')),
        );
        _loadDetails();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (_supplier != null)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: _showSupplierInfo,
              tooltip: 'Информация о поставщике',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение товара
                  Container(
                    height: 350,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: Stack(
                      children: [
                        Center(
                          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? Image.asset(
                                  product.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.photo, size: 100, color: Colors.grey);
                                  },
                                )
                              : Icon(Icons.photo, size: 100, color: Colors.grey),
                        ),
                        if (product.isNew)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'НОВИНКА',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        if (product.discountPercent > 0)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '-${product.discountPercent.toStringAsFixed(0)}%',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Основная информация
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (product.isPopular)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ПОПУЛЯРНО',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${product.reviewCount} отзывов)',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            if (product.originalPrice != null) ...[
                              Text(
                                '${product.originalPrice!.toStringAsFixed(0)} ₽',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 12),
                            ],
                            Text(
                              '${product.price.toStringAsFixed(0)} ₽',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (product.brand != null) ...[
                          SizedBox(height: 12),
                          Text(
                            'Бренд: ${product.brand}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        ],
                        SizedBox(height: 16),
                        Text(
                          'Описание',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        ),

                        // Характеристики
                        SizedBox(height: 24),
                        Text(
                          'Характеристики',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              if (product.specifications != null)
                                _buildSpecRow('Характеристики', product.specifications!),
                              if (product.color != null)
                                _buildSpecRow('Цвет', product.color!),
                              if (product.dimensions != null)
                                _buildSpecRow('Размеры', product.dimensions!),
                              if (product.weight != null)
                                _buildSpecRow('Вес', product.weight!),
                              if (product.warranty != null)
                                _buildSpecRow('Гарантия', product.warranty!),
                              _buildSpecRow('В наличии', '${product.stockQuantity} шт.'),
                            ],
                          ),
                        ),

                        // Поставщик
                        if (_supplier != null) ...[
                          SizedBox(height: 24),
                          InkWell(
                            onTap: _showSupplierInfo,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.store, color: Colors.red),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Поставщик',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          _supplier!.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Отзывы
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Отзывы (${_reviews.length})',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addReview,
                              icon: Icon(Icons.edit, size: 18, color: Colors.red),
                              label: Text(
                                'Оставить отзыв',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (_reviews.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Пока нет отзывов',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _addReview,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Оставить первый отзыв'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._reviews.map((review) => _buildReviewCard(review)),

                        // Похожие товары
                        if (_similarProducts.isNotEmpty) ...[
                          SizedBox(height: 32),
                          Text(
                            'Похожие товары',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _similarProducts.length,
                              itemBuilder: (context, index) {
                                final similarProduct = _similarProducts[index];
                                return Container(
                                  width: 200,
                                  margin: EdgeInsets.only(right: 12),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailScreen(product: similarProduct),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                              ),
                                              child: similarProduct.imageUrl != null && similarProduct.imageUrl!.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                                      child: ColoredBox(
                                                        color: Colors.white,
                                                        child: Image.asset(
                                                          similarProduct.imageUrl!,
                                                          fit: BoxFit.contain,
                                                          alignment: Alignment.center,
                                                          filterQuality: FilterQuality.medium,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Icon(Icons.photo, color: Colors.grey);
                                                          },
                                                        ),
                                                      ),
                                                    )
                                                  : Icon(Icons.photo, color: Colors.grey),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  similarProduct.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.star, size: 14, color: Colors.amber),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      similarProduct.rating.toStringAsFixed(1),
                                                      style: TextStyle(fontSize: 12, color: Colors.black87),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${similarProduct.price.toStringAsFixed(0)} ₽',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    cartProvider.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Товар добавлен в корзину')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Добавить в корзину'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await cartProvider.addToCart(product);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Купить сейчас'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red[100],
                  child: Text(review.userName[0].toUpperCase()),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              size: 16,
                              color: index < review.rating ? Colors.amber : Colors.grey[300],
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                if (review.createdAt != null)
                  Text(
                    review.createdAt!,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}
