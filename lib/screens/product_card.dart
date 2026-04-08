import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/product_detail.dart';
import 'package:mobile_app/services/cart_sync.dart';
import 'package:mobile_app/services/bottom_nav_sync.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool initiallyFavorite;
  final bool initiallyInCart;
  final ValueChanged<bool>? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    this.initiallyFavorite = false,
    this.initiallyInCart = false,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;
  late bool _isInCart;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initiallyFavorite;
    _isInCart = widget.initiallyInCart;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyInCart != widget.initiallyInCart) {
      setState(() {
        _isInCart = widget.initiallyInCart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isLoggedIn = ApiService.isAuthorized;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(4.0),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (product.imageUrl.trim().isEmpty)
                              ? const Icon(
                                  Icons.photo,
                                  size: 48,
                                  color: Colors.grey,
                                )
                              : Image.network(
                                  product.imageUrl,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.photo,
                                      size: 48,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (!isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Чтобы добавить товар в избранное, нужно войти в профиль',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        try {
                          final isFavorite = await ApiService.toggleFavorite(
                            product.id,
                          );
                          if (!context.mounted) return;
                          setState(() {
                            _isFavorite = isFavorite;
                          });
                          widget.onFavoriteChanged?.call(isFavorite);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite
                                    ? 'Товар добавлен в избранное'
                                    : 'Товар удалён из избранного',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_friendlyError(e)),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: _isFavorite ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7.0, 7.0, 7.0, 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(0)} ₽',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${product.discount.toStringAsFixed(0)} ₽',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 2.0,
                                color: Color.fromARGB(255, 3, 3, 3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.evaluation.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${product.countFeedbacks})',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 105, 103, 103),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      child: _isInCart
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.red),
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                BottomNavSync.setIndex(2);
                              },
                              child: const Text('В корзине'),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  240,
                                  9,
                                  9,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () async {
                                if (!isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Чтобы добавить товар в корзину, нужно войти в профиль',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await ApiService.addToCart(product.id);
                                  if (!context.mounted) return;
                                  setState(() {
                                    _isInCart = true;
                                  });
                                  CartSync.notifyChanged();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Товар добавлен в корзину'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_friendlyError(e)),
                                    ),
                                  );
                                }
                              },
                              child: const Text('В корзину'),
                            ),
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

String _friendlyError(Object? error) {
  final text = (error ?? '').toString();
  if (text.contains('войти в профиль') || text.contains('авторизац')) {
    return 'Войдите в профиль, чтобы выполнить это действие';
  }
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text.isEmpty ? 'Произошла ошибка. Попробуйте снова.' : text;
}
