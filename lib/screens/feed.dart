import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/cart_item.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/product_card.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const Color _searchAccentColor = Color(0xFFF4A261);
  String _searchQuery = '';
  String? _searchSort;
  bool _searchShowPopular = false;
  bool _searchShowHighRating = false;
  bool _searchShowBigDiscount = false;
  int? _searchCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = data;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _loadingCategories = false;
      });
    }
  }

  void _showSearchFilters() {
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
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтр поиска',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Дешевле'),
                      selected: _searchSort == 'price_asc',
                      onSelected: (v) {
                        setModalState(() => _searchSort = v ? 'price_asc' : null);
                        setState(() => _searchSort = v ? 'price_asc' : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Дороже'),
                      selected: _searchSort == 'price_desc',
                      onSelected: (v) {
                        setModalState(() => _searchSort = v ? 'price_desc' : null);
                        setState(() => _searchSort = v ? 'price_desc' : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Рейтинг'),
                      selected: _searchSort == 'rating',
                      onSelected: (v) {
                        setModalState(() => _searchSort = v ? 'rating' : null);
                        setState(() => _searchSort = v ? 'rating' : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Новинки'),
                      selected: _searchSort == 'newest',
                      onSelected: (v) {
                        setModalState(() => _searchSort = v ? 'newest' : null);
                        setState(() => _searchSort = v ? 'newest' : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Популярное'),
                      selected: _searchShowPopular,
                      onSelected: (v) {
                        setModalState(() => _searchShowPopular = v);
                        setState(() => _searchShowPopular = v);
                      },
                    ),
                    FilterChip(
                      label: const Text('Высокий рейтинг'),
                      selected: _searchShowHighRating,
                      onSelected: (v) {
                        setModalState(() => _searchShowHighRating = v);
                        setState(() => _searchShowHighRating = v);
                      },
                    ),
                    FilterChip(
                      label: const Text('Большие скидки'),
                      selected: _searchShowBigDiscount,
                      onSelected: (v) {
                        setModalState(() => _searchShowBigDiscount = v);
                        setState(() => _searchShowBigDiscount = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Категория',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_loadingCategories)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
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
                            selected: _searchCategoryId == null,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _searchCategoryId = null);
                                setState(() => _searchCategoryId = null);
                              }
                            },
                          ),
                          ..._categories.map((c) {
                            final id = (c['id'] as num?)?.toInt();
                            final name = c['name']?.toString() ?? '';
                            return FilterChip(
                              label: Text(name),
                              selected: _searchCategoryId == id,
                              onSelected: (selected) {
                                setModalState(() {
                                  _searchCategoryId = selected ? id : null;
                                });
                                setState(() {
                                  _searchCategoryId = selected ? id : null;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _searchSort = null;
                            _searchShowPopular = false;
                            _searchShowHighRating = false;
                            _searchShowBigDiscount = false;
                            _searchCategoryId = null;
                          });
                          setState(() {
                            _searchSort = null;
                            _searchShowPopular = false;
                            _searchShowHighRating = false;
                            _searchShowBigDiscount = false;
                            _searchCategoryId = null;
                          });
                        },
                        child: const Text('Сбросить'),
                      ),
                    ),
                    const SizedBox(width: 8),
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
            )
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  InputDecoration _searchInputDecoration({required String hintText}) {
    final hasText = _searchController.text.trim().isNotEmpty;
    final borderColor = hasText ? Colors.black : Colors.grey.shade400;

    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        Icons.search,
        size: 24,
        color: hasText ? Colors.black : Colors.grey.shade600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            cursorColor: _searchAccentColor,
            style: const TextStyle(fontSize: 16),
            decoration: _searchInputDecoration(hintText: 'Поиск товаров...'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
_CarouselBlock(
                title: '⭐ Свежие поступления',
                future: ApiService.fetchFilteredProducts(isNew: true),
              ),
              _CarouselBlock(
                title: '🔥 Хиты продаж',
                future: ApiService.fetchFilteredProducts(popular: true),
              ),
              _CarouselBlock(
                title: '💸 Скидки от 30% — забирай выгодно',
                future: ApiService.fetchFilteredProducts(bigDiscount: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    const crossAxisCount = 2;
    const spacing = 6.0;
    const padding = 9.0;
    const imageHeight = 180.0;
    const bottomSectionHeight = 140.0;
    const tileHeight = imageHeight + bottomSectionHeight;

    final isLoggedIn = AuthService.currentUserName != null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  cursorColor: _searchAccentColor,
                  style: const TextStyle(fontSize: 16),
                  decoration: _searchInputDecoration(hintText: 'Поиск товаров...'),
                ),
              ),
              IconButton(
                onPressed: _showSearchFilters,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([
              ApiService.searchProducts(_searchQuery),
              if (isLoggedIn)
                ApiService.fetchFavoriteIds().catchError((_) => <int>[])
              else
                Future.value(<int>[]),
              if (isLoggedIn)
                ApiService.fetchCartItems().catchError((_) => <CartItem>[])
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
              final data = snapshot.data!;
              final products = data[0] as List<Product>;
              final favoriteIds = data[1] as List<int>;
              final cartItems = data[2] as List<CartItem>;
              final cartIds = cartItems.map((e) => e.productId).toSet();
              if (products.isEmpty) {
                return const Center(child: Text('Ничего не найдено'));
              }
              var sortedProducts = List<Product>.from(products);
              if (_searchShowPopular) {
                sortedProducts =
                    sortedProducts.where((p) => p.isPopular == true).toList();
              }
              if (_searchShowHighRating) {
                sortedProducts =
                    sortedProducts.where((p) => p.evaluation >= 4.0).toList();
              }
              if (_searchShowBigDiscount) {
                sortedProducts =
                    sortedProducts.where((p) => p.discount > 0).toList();
              }
              if (_searchCategoryId != null) {
                sortedProducts = sortedProducts
                    .where((p) => p.categoryId == _searchCategoryId)
                    .toList();
              }
              if (_searchSort == 'price_asc') {
                sortedProducts.sort((a, b) => a.price.compareTo(b.price));
              } else if (_searchSort == 'price_desc') {
                sortedProducts.sort((a, b) => b.price.compareTo(a.price));
              } else if (_searchSort == 'rating') {
                sortedProducts.sort((a, b) => b.evaluation.compareTo(a.evaluation));
              } else if (_searchSort == 'newest') {
                sortedProducts.sort((a, b) => b.id.compareTo(a.id));
              }
              if (sortedProducts.isEmpty) {
                return const Center(child: Text('Ничего не найдено по фильтру'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(padding),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: tileHeight,
                ),
                itemCount: sortedProducts.length,
                itemBuilder: (context, index) {
                  final p = sortedProducts[index];
                  return ProductCard(
                    product: p,
                    initiallyFavorite: favoriteIds.contains(p.id),
                    initiallyInCart: cartIds.contains(p.id),
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

class _CarouselBlock extends StatelessWidget {
  final String title;
  final Future<List<Product>> future;

  const _CarouselBlock({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 320,
          child: FutureBuilder<List<Product>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    snapshot.hasError ? 'Ошибка загрузки' : 'Пока пусто',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              final list = snapshot.data!;
              final show = list.length > 20 ? list.sublist(0, 20) : list;
              final isLoggedIn = AuthService.currentUserName != null;
              return FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  if (isLoggedIn)
                    ApiService.fetchFavoriteIds().catchError((_) => <int>[])
                  else
                    Future.value(<int>[]),
                  if (isLoggedIn)
                    ApiService.fetchCartItems().catchError((_) => <CartItem>[])
                  else
                    Future.value(<CartItem>[]),
                ]),
                builder: (context, favSnap) {
                  final favIds = favSnap.hasData
                      ? (favSnap.data![0] as List<int>)
                      : <int>[];
                  final cartItems = favSnap.hasData
                      ? (favSnap.data![1] as List<CartItem>)
                      : <CartItem>[];
                  final cartIds = cartItems.map((e) => e.productId).toSet();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: show.length,
                    itemBuilder: (context, index) {
                      final p = show[index];
                      return SizedBox(
                        width: 170,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ProductCard(
                            product: p,
                            initiallyFavorite: favIds.contains(p.id),
                            initiallyInCart: cartIds.contains(p.id),
                          ),
                        ),
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
