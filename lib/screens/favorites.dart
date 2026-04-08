import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/cart_item.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/login.dart';
import 'package:mobile_app/screens/product_card.dart';
import 'package:mobile_app/services/cart_sync.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class FavoritesPlaceholderScreen extends StatefulWidget {
  const FavoritesPlaceholderScreen({super.key});

  @override
  State<FavoritesPlaceholderScreen> createState() =>
      _FavoritesPlaceholderScreenState();
}

class _FavoritesPlaceholderScreenState
    extends State<FavoritesPlaceholderScreen> {
  int? _categoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCat = true;
  String? _selectedSort;
  bool _showPopular = false;
  bool _showHighRating = false;
  bool _showBigDiscount = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final c = await ApiService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = c;
          _loadingCat = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCat = false);
    }
  }

  Future<void> reload() async {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Product> _applyLocalFilter(List<Product> products) {
    var list = products;
    if (_showPopular) {
      list = list.where((p) => p.isPopular == true).toList();
    }
    if (_showHighRating) {
      list = list.where((p) => p.evaluation >= 4.0).toList();
    }
    if (_showBigDiscount) {
      list = list.where((p) => p.discount > 0).toList();
    }
    if (_categoryId != null) {
      list = list.where((p) => p.categoryId == _categoryId).toList();
    }
    // сортировка
    if (_selectedSort == 'price_asc') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'price_desc') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'rating') {
      list.sort((a, b) => b.evaluation.compareTo(a.evaluation));
    } else if (_selectedSort == 'newest') {
      list.sort((a, b) => b.id.compareTo(a.id));
    }
    return list;
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
                    'Подобрать товары',
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
                  if (_loadingCat)
                    const Padding(
                      padding: EdgeInsets.all(16),
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
                              selected: _categoryId == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => _categoryId = null);
                                  setState(() => _categoryId = null);
                                }
                              },
                            ),
                            ..._categories.map((category) {
                              final id = (category['id'] as num?)?.toInt();
                              final name = category['name']?.toString() ?? '';
                              return FilterChip(
                                label: Text(name),
                                selected: _categoryId == id,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _categoryId = selected ? id : null;
                                  });
                                  setState(() {
                                    _categoryId = selected ? id : null;
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
                              _categoryId = null;
                            });
                            setState(() {
                              _selectedSort = null;
                              _showPopular = false;
                              _showHighRating = false;
                              _showBigDiscount = false;
                              _categoryId = null;
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
    if (!ApiService.isAuthorized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_border, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Избранное доступно после входа в профиль',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (result == true && mounted) {
                    reload();
                  }
                },
                child: const Text('Войти'),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: CartSync.listenable,
      builder: (context, _, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: ApiService.fetchFavoriteProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final products = snapshot.data as List<Product>;
                          final count = products.length;
                          final sum = products.fold<double>(
                            0.0,
                            (s, p) => s + p.price,
                          );
                          String getWord(int n) {
                            if (n % 10 == 1 && n % 100 != 11) return 'товар';
                            if (n % 10 >= 2 &&
                                n % 10 <= 4 &&
                                (n % 100 < 10 || n % 100 >= 20)) {
                              return 'товара';
                            }
                            return 'товаров';
                          }

                          return Text(
                            '$count ${getWord(count)} на сумму: ${sum.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const Text(
                          'Загрузка...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: _showFilters,
                    icon: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: reload,
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    ApiService.fetchFavoriteProducts(),
                    ApiService.fetchCartItems().catchError((_) => <CartItem>[]),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          ServerErrorView(
                            message: _friendlyError(snapshot.error),
                            onRetry: reload,
                          ),
                        ],
                      );
                    }

                    final data = snapshot.data;
                    final products =
                        (data != null ? data[0] : <Product>[]) as List<Product>;
                    final cartItems =
                        (data != null ? data[1] : <CartItem>[])
                            as List<CartItem>;
                    final cartProductIds = cartItems
                        .map((e) => e.productId)
                        .toSet();

                    final filtered = _applyLocalFilter(products);

                    if (products.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'В избранном пока пусто',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (filtered.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          Center(child: Text('Ничего не найдено по фильтру')),
                        ],
                      );
                    }

                    const crossAxisCount = 2;
                    const spacing = 6.0;
                    const padding = 9.0;
                    const imageHeight = 180.0;
                    const bottomSectionHeight = 155.0;
                    final tileHeight = imageHeight + bottomSectionHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.all(padding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: tileHeight,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final productId = filtered[index].id;
                        return ProductCard(
                          product: filtered[index],
                          initiallyFavorite: true,
                          initiallyInCart: cartProductIds.contains(productId),
                          onFavoriteChanged: (isFavorite) {
                            if (!isFavorite) {
                              reload();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _friendlyError(Object? error) {
  final text = (error ?? '').toString();
  if (text.contains('войти в профиль') || text.contains('авторизац')) {
    return 'Войдите в профиль, чтобы пользоваться избранным';
  }
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text.isEmpty ? 'Произошла ошибка. Попробуйте снова.' : text;
}
