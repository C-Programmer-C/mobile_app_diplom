import 'package:mobile_app/api.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const spacing = 6.0;
        const padding = 9.0;

        const imageHeight = 180.0;
        const bottomSectionHeight = 140.0;
        final tileHeight = imageHeight + bottomSectionHeight;

        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            ApiService.fetchProducts(),
            // Если избранное недоступно (не авторизован), считаем список избранного пустым
            ApiService.fetchFavoriteIds().catchError((_) => <int>[]),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Ошибка загрузки'));
            }

            final products = snapshot.data![0] as List<Product>;
            final favoriteIds = snapshot.data![1] as List<int>;

            return GridView.builder(
              padding: const EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: tileHeight,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final isFavorite = favoriteIds.contains(product.id);
                return ProductCard(
                  product: product,
                  initiallyFavorite: isFavorite,
                );
              },
            );
          },
        );
      },
    );
  }
}
