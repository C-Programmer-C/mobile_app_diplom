import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/screens/product_card.dart';

class FavoritesPlaceholderScreen extends StatefulWidget {
  const FavoritesPlaceholderScreen({super.key});

  @override
  State<FavoritesPlaceholderScreen> createState() =>
      _FavoritesPlaceholderScreenState();
}

class _FavoritesPlaceholderScreenState
    extends State<FavoritesPlaceholderScreen> {
  Future<void> reload() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: reload,
      child: FutureBuilder<List<Product>>(
        future: ApiService.fetchFavoriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text('Ошибка: ${snapshot.error}'),
                ),
              ],
            );
          }

          final products = snapshot.data ?? [];
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
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: products[index],
                initiallyFavorite: true,
                onFavoriteChanged: (isFavorite) {
                  if (!isFavorite) {
                    // если товар убрали из избранного — перезагружаем список
                    reload();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
