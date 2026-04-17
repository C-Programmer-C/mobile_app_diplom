import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/cart_item.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/product_card.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/cart_sync.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}


class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSort;
  bool _showPopular = false;
  bool _showHighRating = false;
  bool _showBigDiscount = false;
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  String? _categoriesError;



  IconData _categoryIcon(String slug) {
    switch (slug) {
      case 'smartphone':
        return Icons.smartphone;
      case 'laptop':
        return Icons.laptop_mac;
      case 'tablet':
        return Icons.tablet_android;
      default:
        return Icons.category;
    }
  }

  String _normalizeIconUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.baseUrl}$trimmed';
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
    _loadCategories();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoriesError = toUserMessage(e);
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Фильтры',
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
                  const SizedBox(height: 12),
                  const Text(
                    'Сортировка',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Дешевле'),
                        selected: _selectedSort == 'price_asc',
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedSort = selected ? 'price_asc' : null;
                          });
                          setState(() {
                            _selectedSort = selected ? 'price_asc' : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Дороже'),
                        selected: _selectedSort == 'price_desc',
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedSort = selected ? 'price_desc' : null;
                          });
                          setState(() {
                            _selectedSort = selected ? 'price_desc' : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Высокий рейтинг'),
                        selected: _selectedSort == 'rating',
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedSort = selected ? 'rating' : null;
                          });
                          setState(() {
                            _selectedSort = selected ? 'rating' : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Новинки'),
                        selected: _selectedSort == 'newest',
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedSort = selected ? 'newest' : null;
                          });
                          setState(() {
                            _selectedSort = selected ? 'newest' : null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Показать только',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Популярное'),
                        selected: _showPopular,
                        onSelected: (selected) {
                          setModalState(() => _showPopular = selected);
                          setState(() => _showPopular = selected);
                        },
                      ),
                      FilterChip(
                        label: const Text('Высокий рейтинг'),
                        selected: _showHighRating,
                        onSelected: (selected) {
                          setModalState(() => _showHighRating = selected);
                          setState(() => _showHighRating = selected);
                        },
                      ),
                      FilterChip(
                        label: const Text('Большие скидки'),
                        selected: _showBigDiscount,
                        onSelected: (selected) {
                          setModalState(() => _showBigDiscount = selected);
                          setState(() => _showBigDiscount = selected);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Категория',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    )
                  else if (_categoriesError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Не удалось загрузить категории',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _loadCategories();
                            setModalState(() {});
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilterChip(
                              label: const Text('Все категории'),
                              selected: _selectedCategoryId == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => _selectedCategoryId = null);
                                  setState(() => _selectedCategoryId = null);
                                }
                              },
                            ),
                            ..._categories.map((category) {
                              final id = (category['id'] as num?)?.toInt();
                              final name = category['name']?.toString() ?? '';
                              return FilterChip(
                                label: Text(name),
                                selected: _selectedCategoryId == id,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedCategoryId = selected ? id : null;
                                  });
                                  setState(() {
                                    _selectedCategoryId = selected ? id : null;
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedSort = null;
                              _showPopular = false;
                              _showHighRating = false;
                              _showBigDiscount = false;
                              _selectedCategoryId = null;
                            });
                            setState(() {
                              _selectedSort = null;
                              _showPopular = false;
                              _showHighRating = false;
                              _showBigDiscount = false;
                              _selectedCategoryId = null;
                            });
                          },
                          child: const Text('Сбросить'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Применить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const crossAxisCount = 2;
    const spacing = 6.0;
    const padding = 9.0;
    const imageHeight = 180.0;
    const bottomSectionHeight = 140.0;
    final tileHeight = imageHeight + bottomSectionHeight;

    final isLoggedIn = ApiService.isAuthorized;

    final showFilter = _selectedCategoryId != null;
    final showCategoryCards = _selectedCategoryId == null && _searchQuery.isEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              if (_selectedCategoryId != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedSort = null;
                      _showPopular = false;
                      _showHighRating = false;
                      _showBigDiscount = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Назад к категориям',
                ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _selectedCategoryId == null
                        ? 'Поиск товаров...'
                        : 'Поиск в категории...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (showFilter) ...[
                const SizedBox(width: 2),
                Material(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _showFilters,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.tune_rounded, size: 22),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showCategoryCards)
          Expanded(
            child: _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _categoriesError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_categoriesError!, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text('Обновить'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final c = _categories[index];
                      final id = (c['id'] as num?)?.toInt();
                      final name = c['name']?.toString() ?? '';
                      final iconPath = c['icon_path']?.toString() ?? '';
                      final normalizedIconUrl = _normalizeIconUrl(iconPath);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = id;
                          });
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: normalizedIconUrl.isEmpty
                                    ? Icon(_categoryIcon(''), size: 28)
                                    : Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            normalizedIconUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                _categoryIcon(''),
                                                size: 28,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        else
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              AuthService.sessionEpoch,
              CartSync.listenable,
            ]),
            builder: (context, _) {
              return FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _searchQuery.isNotEmpty
                      ? ApiService.searchProducts(_searchQuery)
                      : (_selectedSort != null ||
                              _showPopular ||
                              _showHighRating ||
                              _showBigDiscount ||
                              _selectedCategoryId != null)
                          ? ApiService.fetchFilteredProducts(
                              sortBy: _selectedSort,
                              popular: _showPopular,
                              highRating: _showHighRating,
                              bigDiscount: _showBigDiscount,
                              categoryId: _selectedCategoryId,
                            )
                          : ApiService.fetchProducts(),
                  if (isLoggedIn)
                    ApiService.fetchFavoriteIds().catchError((_) => <int>[])
                  else
                    Future.value(<int>[]),
                  if (isLoggedIn)
                    ApiService.fetchCartItems().catchError(
                      (_) => <CartItem>[],
                    )
                  else
                    Future.value(<CartItem>[]),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ServerErrorView(
                      message: toUserMessage(snapshot.error),
                      onRetry: () => setState(() {}),
                    );
                  }

                  final data = snapshot.data;
                  final products =
                      (data != null ? data[0] : <Product>[]) as List<Product>;
                  final favoriteIds =
                      (data != null ? data[1] : <int>[]) as List<int>;
                  final cartItems =
                      (data != null ? data[2] : <CartItem>[]) as List<CartItem>;
                  final cartProductIds =
                      cartItems.map((e) => e.productId).toSet();

                  if (products.isEmpty) {
                    return const Center(child: Text('Товары не найдены'));
                  }

                  var list = products;
                  if (_selectedCategoryId != null && _searchQuery.isNotEmpty) {
                    list = products
                        .where((p) => p.categoryId == _selectedCategoryId)
                        .toList();
                  }

                  if (list.isEmpty) {
                    return const Center(child: Text('Нет товаров по фильтру'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(padding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: tileHeight,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final product = list[index];
                      final isFavorite = favoriteIds.contains(product.id);
                      final isInCart = cartProductIds.contains(product.id);
                      return ProductCard(
                        product: product,
                        initiallyFavorite: isFavorite,
                        initiallyInCart: isInCart,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
