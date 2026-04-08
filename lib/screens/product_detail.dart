import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/models/review.dart';
import 'package:mobile_app/services/bottom_nav_sync.dart';
import 'package:mobile_app/services/cart_sync.dart';
import 'package:mobile_app/screens/checkout.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product detailedProduct;
  List<Review> reviews = [];
  List<Product> similarProducts = [];
  bool isLoading = true;
  String? errorMessage;
  double _newReviewRating = 0;
  String _newReviewComment = '';

  static const String _sortPositiveFirst = 'positive';
  static const String _sortNegativeFirst = 'negative';
  int _currentImageIndex = 0;
  late final PageController _imagePageController;

  bool _isInCart = false;
  late VoidCallback _cartSyncListener;

  String _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('/')) {
      return '${ApiService.baseUrl}$trimmed';
    }
    if (trimmed.startsWith('http://127.0.0.1:8000')) {
      return trimmed.replaceFirst('http://127.0.0.1:8000', ApiService.baseUrl);
    }
    if (trimmed.startsWith('http://localhost:8000')) {
      return trimmed.replaceFirst('http://localhost:8000', ApiService.baseUrl);
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _cartSyncListener = () {
      _syncCartPresence();
    };
    CartSync.listenable.addListener(_cartSyncListener);
    _loadProductDetails();
    _syncCartPresence();
  }

  Future<void> _syncCartPresence() async {
    if (!ApiService.isAuthorized) {
      if (!mounted) return;
      setState(() {
        _isInCart = false;
      });
      return;
    }

    try {
      final items = await ApiService.fetchCartItems();
      final inCart = items.any((e) => e.productId == widget.product.id);
      if (!mounted) return;
      setState(() {
        _isInCart = inCart;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInCart = false;
      });
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    CartSync.listenable.removeListener(_cartSyncListener);
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    try {
      final details = await ApiService.fetchProductDetails(widget.product.id);
      final reviewsData = await ApiService.fetchProductReviews(
        widget.product.id,
        limit: 3,
      );
      final similarData = await ApiService.fetchSimilarProducts(
        widget.product.id,
        limit: 8,
      );

      setState(() {
        detailedProduct = details;
        reviews = reviewsData;
        similarProducts = similarData;
        _currentImageIndex = 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = toUserMessage(e);
        // Use basic product info if detailed loading fails
        detailedProduct = widget.product;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Загрузка...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          detailedProduct.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manufacturer Card

            // Product Image
            _buildProductImage(),

            // Product Info
            _buildProductInfo(),

            // Additional Info (includes specifications)
            _buildAdditionalInfo(),

            // Reviews Section
            _buildReviewsSection(context),

            // Similar Products
            if (similarProducts.isNotEmpty) _buildSimilarProducts(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    if (_isInCart) {
                      BottomNavSync.setIndex(2);
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      return;
                    }
                    if (!ApiService.isAuthorized) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Чтобы добавить товар в корзину нужно войти в профиль')),
                      );
                      return;
                    }
                    try {
                      await ApiService.addToCart(detailedProduct.id);
                      if (context.mounted) {
                        setState(() {
                          _isInCart = true;
                        });
                        CartSync.notifyChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Товар добавлен в корзину'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Не удалось оформить заказ: ${toUserMessage(e)}',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    _isInCart ? 'В корзине' : 'В корзину',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      if (!_isInCart) {
                        await ApiService.addToCart(detailedProduct.id);
                        if (context.mounted) {
                          setState(() {
                            _isInCart = true;
                          });
                          CartSync.notifyChanged();
                        }
                      }

                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              selectedProductIds: [detailedProduct.id],
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Чтобы купить товар, нужно войти в свой профиль',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Купить сейчас',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final images = detailedProduct.images ?? [];
    final hasGallery = images.isNotEmpty;

    return Column(
      children: [
        Container(
          height: 320,
          width: double.infinity,
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: hasGallery
              ? PageView.builder(
                  controller: _imagePageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final url = _normalizeUrl(
                      (images[index]['url'] as String?) ?? '',
                    );
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: url.trim().isEmpty
                          ? const Icon(Icons.photo, size: 96, color: Colors.grey)
                          : Image.network(
                              url,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.photo,
                                  size: 96,
                                  color: Colors.grey,
                                );
                              },
                            ),
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: (detailedProduct.imageUrl.trim().isEmpty)
                      ? const Icon(Icons.photo, size: 96, color: Colors.grey)
                      : Image.network(
                          detailedProduct.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.photo,
                              size: 96,
                              color: Colors.grey,
                            );
                          },
                        ),
                ),
        ),
        if (hasGallery && images.length > 1)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final url = _normalizeUrl(
                  (images[index]['url'] as String?) ?? '',
                );
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                    _imagePageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? Colors.red
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: url.isEmpty
                        ? const Icon(Icons.photo, color: Colors.grey)
                        : Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.photo,
                                color: Colors.grey,
                              );
                            },
                          ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (detailedProduct.isNew == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Новое',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              if (detailedProduct.isPopular == true)
                Container(
                  margin: detailedProduct.isNew == true
                      ? const EdgeInsets.only(left: 8)
                      : EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Популярное',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detailedProduct.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (detailedProduct.brand.isNotEmpty)
            Text(
              'Бренд: ${detailedProduct.brand}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${detailedProduct.price.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${detailedProduct.discount.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, size: 18, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                detailedProduct.evaluation.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${detailedProduct.countFeedbacks})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              // Removed incomplete if statement for soldCount
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Описание
          if (detailedProduct.description != null &&
              detailedProduct.description!.isNotEmpty) ...[
            const Text(
              'Описание',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detailedProduct.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Характеристики
          const Text(
            'Характеристики',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (detailedProduct.specifications != null &&
                    detailedProduct.specifications!.isNotEmpty)
                  _buildSpecRow(
                    'Характеристики',
                    detailedProduct.specifications!,
                  ),
                if (detailedProduct.color != null &&
                    detailedProduct.color!.isNotEmpty)
                  _buildSpecRow('Цвет', detailedProduct.color!),
                if (detailedProduct.dimensions != null &&
                    detailedProduct.dimensions!.isNotEmpty)
                  _buildSpecRow('Размеры', detailedProduct.dimensions!),
                if (detailedProduct.weight != null &&
                    detailedProduct.weight!.isNotEmpty)
                  _buildSpecRow('Вес', detailedProduct.weight!),
                if (detailedProduct.warranty != null &&
                    detailedProduct.warranty! > 0)
                  _buildSpecRow(
                    'Гарантия',
                    '${detailedProduct.warranty!} месяцев',
                  ),
                _buildSpecRow(
                  'В наличии',
                  (detailedProduct.quantity == null ||
                          detailedProduct.quantity! <= 0)
                      ? 'Нет в наличии'
                      : '${detailedProduct.quantity} шт.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Отзывы (${detailedProduct.countFeedbacks})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(-10, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        if (!ApiService.isAuthorized) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Чтобы оставить отзыв, нужно войти в профиль',
                              ),
                            ),
                          );
                          return;
                        }
                        _showAddReviewDialog(context);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Оставить отзыв'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        minimumSize: const Size(44, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAllReviews(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        minimumSize: const Size(44, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Все отзывы',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reviews.map((review) => _buildReviewCard(review)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final ratingInt = review.rating.round().clamp(1, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 14,
                      color: i < ratingInt ? Colors.orange : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$ratingInt / 5',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (review.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatDate(review.createdAt!),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 14),
          const Text(
            'Похожие товары',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: similarProducts.length,
              itemBuilder: (context, index) {
                final product = similarProducts[index];
                return Container(
                  margin: EdgeInsets.only(
                    right: index < similarProducts.length - 1 ? 12 : 0,
                  ),
                  width: 160,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: product.imageUrl.isNotEmpty
                                ? Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.photo,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(Icons.photo, color: Colors.grey),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.price.toStringAsFixed(0)} ₽',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      product.evaluation.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
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
      ),
    );
  }

  void _showAllReviews(BuildContext context) {
    var sortMode = _sortPositiveFirst;
    var reviewsFuture = ApiService.fetchAllProductReviews(widget.product.id);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: const Text('Все отзывы'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  PopupMenuButton<String>(
                    initialValue: sortMode,
                    onSelected: (value) {
                      setState(() {
                        sortMode = value;
                      });
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _sortPositiveFirst,
                        child: Text('Сначала положительные'),
                      ),
                      PopupMenuItem(
                        value: _sortNegativeFirst,
                        child: Text('Сначала отрицательные'),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.sort),
                          const SizedBox(width: 6),
                          Text(
                            sortMode == _sortPositiveFirst
                                ? 'Положительные'
                                : 'Отрицательные',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.expand_more),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              body: FutureBuilder<List<Review>>(
                future: reviewsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ServerErrorView(
                      message:
                          'Ошибка загрузки отзывов: ${toUserMessage(snapshot.error)}',
                      onRetry: () {
                        setState(() {
                          reviewsFuture = ApiService.fetchAllProductReviews(
                            widget.product.id,
                          );
                        });
                      },
                    );
                  }

                  final allReviews = snapshot.data ?? [];
                  if (allReviews.isEmpty) {
                    return const Center(child: Text('Нет отзывов'));
                  }

                  final sortedReviews = List<Review>.from(allReviews)
                    ..sort((a, b) {
                      final byRating = sortMode == _sortPositiveFirst
                          ? b.rating.compareTo(a.rating)
                          : a.rating.compareTo(b.rating);
                      if (byRating != 0) return byRating;
                      final ad = a.createdAt;
                      final bd = b.createdAt;
                      if (ad == null && bd == null) return 0;
                      if (ad == null) return 1;
                      if (bd == null) return -1;
                      return bd.compareTo(ad);
                    });

                  return ListView.builder(
                    itemCount: sortedReviews.length,
                    itemBuilder: (context, index) {
                      final review = sortedReviews[index];
                      return _buildFullReviewCard(review);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    _newReviewRating = 0;
    _newReviewComment = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Оставить отзыв'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Оценка'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        icon: Icon(
                          Icons.star,
                          color: index < _newReviewRating
                              ? Colors.orange
                              : Colors.grey[300],
                        ),
                        onPressed: () {
                          setState(() {
                            _newReviewRating = (index + 1).toDouble();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Комментарий (необязательно)'),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    onChanged: (value) {
                      _newReviewComment = value;
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Поделитесь своим впечатлением',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentContext = context;
                if (_newReviewRating <= 0) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(content: Text('Поставьте оценку')),
                  );
                  return;
                }
                try {
                  final review = await ApiService.createProductReview(
                    productId: detailedProduct.id,
                    rating: _newReviewRating,
                    comment: _newReviewComment.trim().isEmpty
                        ? null
                        : _newReviewComment,
                  );
                  if (mounted) {
                    setState(() {
                      reviews.insert(0, review);
                    });
                    await _loadProductDetails();
                    if (!currentContext.mounted) return;
                    Navigator.of(currentContext).pop();
                    ScaffoldMessenger.of(currentContext).showSnackBar(
                      const SnackBar(content: Text('Отзыв отправлен')),
                    );
                  }
                } catch (e) {
                  if (!currentContext.mounted) return;
                  Navigator.of(currentContext).pop();
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(content: Text(toUserMessage(e))),
                  );
                }
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFullReviewCard(Review review) {
    final ratingInt = review.rating.round().clamp(1, 5);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.userName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 16,
                      color: i < ratingInt ? Colors.orange : Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$ratingInt / 5',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          if (review.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatDate(review.createdAt!),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).toStringAsFixed(0)} недель назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
