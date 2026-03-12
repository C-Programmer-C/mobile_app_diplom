import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/cart_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/database/database_helper.dart';
import 'package:mobile_app/utils/user_friendly_error.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'card';

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final total = cartProvider.cartItems.fold(0.0, (sum, item) {
      return sum + (item.product!.price * item.quantity);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Оформление заказа'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Контактная информация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) {
                    return 'Введите телефон';
                  }
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Адрес доставки',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 3,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) {
                    return 'Введите адрес доставки';
                  }
                  if (v.length < 8) {
                    return 'Адрес слишком короткий';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text(
                'Способ оплаты',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              RadioListTile(
                title: Text('Банковская карта'),
                value: 'card',
                groupValue: _paymentMethod,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value.toString();
                  });
                },
              ),
              RadioListTile(
                title: Text('Наличные при получении'),
                value: 'cash',
                groupValue: _paymentMethod,
                activeColor: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value.toString();
                  });
                },
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Доставка:', style: TextStyle(fontSize: 16)),
                        Text('Бесплатно'),
                      ],
                    ),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Итого к оплате:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final cartProvider = Provider.of<CartProvider>(context, listen: false);
                      if (cartProvider.cartItems.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Корзина пуста'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final orderId = await _createOrder(total);
                      
                      if (orderId != null && mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 28),
                                SizedBox(width: 8),
                                Expanded(child: Text('Заказ оформлен!')),
                              ],
                            ),
                            content: Text(
                              'Ваш заказ успешно оформлен.\nНомер заказа: #$orderId',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  );
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Подтвердить заказ',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _createOrder(double total) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Войдите в аккаунт, чтобы оформить заказ'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      final db = await DatabaseHelper().database;
      
      final orderId = await db.insert('orders', {
        'user_id': userId,
        'total_amount': total,
        'status': 'pending',
        'shipping_address': _addressController.text,
        'phone': _phoneController.text,
      });

      for (var item in cartProvider.cartItems) {
        await db.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.product!.price,
        });
      }

      await cartProvider.clearAllCartItems();
      
      return orderId;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
