import 'package:flutter/material.dart';
import 'package:mobile_app/database/database_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  final List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final db = await DatabaseHelper().database;
    
    final orders = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [widget.orderId],
    );

    if (orders.isNotEmpty) {
      setState(() {
        _order = orders.first;
      });

      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [widget.orderId],
      );

      for (var item in items) {
        final products = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [item['product_id']],
        );
        if (products.isNotEmpty) {
          _orderItems.add({
            'item': item,
            'product': products.first,
          });
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Отменить заказ?'),
        content: Text('Вы уверены, что хотите отменить этот заказ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Да, отменить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper().database;
      await db.update(
        'orders',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [widget.orderId],
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Заказ отменен')),
        );
      }
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'В обработке';
      case 'processing':
        return 'Обрабатывается';
      case 'shipped':
        return 'Отправлен';
      case 'delivered':
        return 'Доставлен';
      case 'cancelled':
        return 'Отменен';
      default:
        return 'Неизвестно';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Детали заказа'),
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Детали заказа'),
        ),
        body: Center(child: Text('Заказ не найден')),
      );
    }

    final canCancel = _order!['status'] == 'pending' || _order!['status'] == 'processing';

    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${_order!['id']}'),
        actions: [
          if (canCancel)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: _cancelOrder,
              tooltip: 'Отменить заказ',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Статус заказа',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_order!['status']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(_order!['status']),
                            style: TextStyle(
                              color: _getStatusColor(_order!['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Дата заказа', _order!['order_date'] ?? 'Не указана'),
                    _buildInfoRow('Телефон', _order!['phone'] ?? 'Не указан'),
                    _buildInfoRow('Адрес доставки', _order!['shipping_address'] ?? 'Не указан'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Товары в заказе',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._orderItems.map((item) {
              final orderItem = item['item'] as Map<String, dynamic>;
              final product = item['product'] as Map<String, dynamic>;
              final quantity = orderItem['quantity'] as int;
              final price = orderItem['price'] as double;
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ColoredBox(
                              color: Colors.white,
                              child: Image.asset(
                                product['image_url'].toString(),
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.photo, color: Colors.grey);
                                },
                              ),
                            ),
                          )
                        : Icon(Icons.photo, color: Colors.grey),
                  ),
                  title: Text(product['name'] ?? 'Товар'),
                  subtitle: Text('Количество: $quantity'),
                  trailing: Text(
                    '${(price * quantity).toStringAsFixed(0)} ₽',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              );
            }),
            SizedBox(height: 16),
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Итого:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(_order!['total_amount'] as double).toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
