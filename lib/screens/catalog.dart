import 'package:flutter/material.dart';

class CatalogPlaceholderScreen extends StatelessWidget {
  const CatalogPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Каталог (заглушка)',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
