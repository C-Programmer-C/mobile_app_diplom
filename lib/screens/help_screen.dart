import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Помощь')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Как оформить заказ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Добавьте товар в корзину, откройте корзину и нажмите оформление. '
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
            'при сохранении товарного вида и упаковки (если иное не указано в заказе).',
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
            'или напишите на email, указанный на сайте.',
            style: TextStyle(fontSize: 15, height: 1.45),
          ),
        ],
      ),
    );
  }
}
