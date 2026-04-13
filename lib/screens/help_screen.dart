import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Не удалось открыть $url';
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Помощь')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Как оформить заказ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте товар в корзину, откройте корзину и нажмите кнопку «Оформить заказ». '
            'Укажите адрес или пункт выдачи и телефон.',
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
          SizedBox(height: 24),

          Text(
            'Оплата и доставка',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Способы оплаты и сроки доставки уточняйте при оформлении. '
            'Заказ можно отслеживать в разделе «Заказы» в профиле.',
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
          SizedBox(height: 24),

          Text(
            'Возврат',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Условия возврата товара надлежащего качества — в течение 14 дней '
            'при сохранении товарного вида и упаковки.',
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
          SizedBox(height: 24),

          Text(
            'Поддержка',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'По вопросам работы приложения обратитесь к администратору магазина '
            'или напишите на email, указанный ниже.',
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
          SizedBox(height: 24),

          Text(
            'Контакты',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),

          // Email
          GestureDetector(
            onTap: () => _openUrl('mailto:support@yourshop.com'),
            child: Text(
              '📧 support@yourshop.com',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          SizedBox(height: 8),

          // Телефон
          GestureDetector(
            onTap: () => _openUrl('tel:+11234567890'),
            child: Text(
              '📞 +1 (123) 456-78-90',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          SizedBox(height: 8),

          // Telegram
          GestureDetector(
            onTap: () => _openUrl('https://t.me/your_username'),
            child: Text(
              '💬 Telegram',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          SizedBox(height: 8),

          // WhatsApp
          GestureDetector(
            onTap: () => _openUrl('https://wa.me/11234567890'),
            child: Text(
              '🟢 WhatsApp',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
