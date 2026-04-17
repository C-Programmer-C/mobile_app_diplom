import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/cart_item.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/checkout.dart';
import 'package:mobile_app/screens/login.dart';
import 'package:mobile_app/screens/product_detail.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/cart_sync.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<_CartEntry>> _future;
  bool _isMutating = false;
  late VoidCallback _cartSyncListener;
  late VoidCallback _sessionListener;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _cartSyncListener = () {
      if (!mounted) return;
      if (_isMutating) return;
      _refresh();
    };
    CartSync.listenable.addListener(_cartSyncListener);
    _sessionListener = () {
      if (!mounted) return;
      if (_isMutating) return;
      _refresh();
    };
    AuthService.sessionEpoch.addListener(_sessionListener);
  }

  Future<List<_CartEntry>> _load() async {
    final items = await ApiService.fetchCartItems();
    if (items.isEmpty) return [];
    final products = await ApiService.fetchProducts();
    final productsById = {for (final p in products) p.id: p};
    return items
        .map((e) => _CartEntry(item: e, product: productsById[e.productId]))
        .where((e) => e.product != null)
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    if (_isMutating) return;
    setState(() {
      _isMutating = true;
    });
    try {
      await action();
      await _refresh();
      CartSync.notifyChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    AuthService.sessionEpoch.removeListener(_sessionListener);
    CartSync.listenable.removeListener(_cartSyncListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.isAuthorized) {
      return _UnauthorizedCartState(
        onLoginPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          if (result == true && mounted) {
            await _refresh();
          }
        },
      );
    }

    return FutureBuilder<List<_CartEntry>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ServerErrorView(
            message: _friendlyError(snapshot.error),
            onRetry: _refresh,
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Корзина пуста',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final total = entries.fold<double>(
          0,
          (sum, e) => sum + e.product!.price * e.item.quantity,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Количество: ${entries.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isMutating
                        ? null
                        : () async {
                            await _runMutation(() async {
                              await ApiService.clearCart();
                            });
                          },
                    icon: const Icon(
                      Icons.delete_sweep,
                      size: 28,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Удалить всё',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final product = entry.product!;
                    final item = entry.item;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 8,
                                bottom: 8,
                              ),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: (product.imageUrl.trim().isEmpty)
                                    ? const Icon(
                                        Icons.photo,
                                        size: 48,
                                        color: Colors.grey,
                                      )
                                    : Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.photo,
                                                size: 48,
                                                color: Colors.grey,
                                              );
                                            },
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 11),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          onPressed: _isMutating
                                              ? null
                                              : () async {
                                                  await _runMutation(() async {
                                                    await ApiService.removeFromCart(
                                                      productId: item.productId,
                                                    );
                                                  });
                                                },
                                          icon: const Icon(
                                            Icons.delete_rounded,
                                            size: 32,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, -6),
                                    child: Text(
                                      '${product.price.toStringAsFixed(0)} ₽',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        onPressed:
                                            (_isMutating || item.quantity <= 1)
                                            ? null
                                            : () async {
                                                final newQty =
                                                    item.quantity - 1;
                                                await _runMutation(() async {
                                                  await ApiService.setCartItemQuantity(
                                                    productId: item.productId,
                                                    quantity: newQty,
                                                  );
                                                });
                                              },
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 24,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                        onPressed: _isMutating
                                            ? null
                                            : () async {
                                                final newQty =
                                                    item.quantity + 1;
                                                await _runMutation(() async {
                                                  await ApiService.setCartItemQuantity(
                                                    productId: item.productId,
                                                    quantity: newQty,
                                                  );
                                                });
                                              },
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailScreen(
                                                  product: product,
                                                ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(0, 36),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Подробнее'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Итого:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${total.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CheckoutScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Оформить заказ'),
                    ),
                  ),
                ],
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
    return 'Войдите в профиль, чтобы пользоваться корзиной';
  }
  final normalized = text.startsWith('Exception: ')
      ? text.substring('Exception: '.length)
      : text;
  return normalized.isEmpty ? 'Произошла ошибка. Попробуйте снова.' : normalized;
}

class _CartEntry {
  final CartItem item;
  final Product? product;

  _CartEntry({required this.item, required this.product});
}

class _UnauthorizedCartState extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const _UnauthorizedCartState({required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Корзина доступна после входа в профиль',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onLoginPressed,
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}
