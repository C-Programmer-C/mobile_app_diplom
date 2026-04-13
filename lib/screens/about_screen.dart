import 'package:flutter/material.dart';



class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('О приложении'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Логотип
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.75,
                child: Image.asset(
                  'assets/splash.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              ),
              // Версия
              const Text(
                'Версия 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              // Слоган (карточка)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: const Color.fromARGB(255, 155, 151, 150).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Лучшие технологии по доступной цене',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Описание
              const Text(
                'ЭлектроМир — это удобный сервис для покупки электроники: '
                'каталог товаров, быстрый заказ и отслеживание доставки.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Преимущества
              _feature(Icons.shopping_cart_outlined, 'Быстрый заказ'),
              _feature(Icons.local_shipping_outlined, 'Доставка до двери'),
              _feature(Icons.star_border, 'Отзывы и рейтинг'),
              _feature(Icons.payment_outlined, 'Удобная оплата'),

              const SizedBox(height: 30),

              // Разделитель
              Divider(),

              const SizedBox(height: 10),

              // Копирайт
              const Text(
                '© 2026 ЭлектроМир',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
