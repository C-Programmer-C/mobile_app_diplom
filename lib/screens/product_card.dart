
import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/product.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool initiallyFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    this.initiallyFavorite = false,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initiallyFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Card(
      elevation: 2,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // фото с рамкой + избранное сверху справа
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
                        child: Image.network(product.imageUrl),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          key: ValueKey<bool>(_isFavorite),
                          size: 20,
                          color: _isFavorite ? Colors.red : Colors.grey,
                        ),
                      ),
                      onPressed: () async {
                        // оптимистичное обновление UI
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                        try {
                          final isFavorite =
                              await ApiService.toggleFavorite(product.id);
                          if (!mounted) return;
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
                          if (!mounted) return;
                          // откатываем состояние при ошибке
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Не удалось изменить избранное: $e',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // контент + кнопка, растянутые на оставшуюся высоту
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7.0, 7.0, 7.0, 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // верхний блок: цены, название, рейтинг
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ЦЕНЫ
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
                              color: Color.fromARGB(255, 54, 52, 52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // НАЗВАНИЕ — до 2 строк
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
                      // РЕЙТИНГ + ОТЗЫВЫ
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.orange),
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
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // кнопка под рейтингом с фиксированным отступом
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 240, 9, 9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await ApiService.addToCart(product.id);
                          if (context.mounted) {
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
                                  'Не удалось добавить в корзину: $e',
                                ),
                              ),
                            );
                          }
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
    );
  }
}
