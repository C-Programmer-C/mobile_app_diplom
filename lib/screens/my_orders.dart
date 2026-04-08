import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/screens/order_detail_screen.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchMyOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Мои заказы'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ServerErrorView(
              message: 'Ошибка загрузки заказов: ${toUserMessage(snapshot.error)}',
              onRetry: () {
                setState(() {
                  _future = ApiService.fetchMyOrders();
                });
              },
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Пока нет заказов'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final o = orders[index];
              final id = (o['id'] as num?)?.toInt() ?? 0;
              final status = o['status']?.toString() ?? '';
              final deliveryType = o['delivery_type']?.toString() ?? '';
              final shippingAddress = o['shipping_address']?.toString() ?? '';
              final deliveryAt = DateTime.tryParse(
                o['delivery_at']?.toString() ?? '',
              )?.toLocal();
              final deliveryComment = o['delivery_comment']?.toString() ?? '';
              final totalAmount = (o['total_amount'] as num?)?.toDouble() ?? 0;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Заказ #$id',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${totalAmount.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deliveryType.isEmpty
                            ? shippingAddress
                            : '$deliveryType • $shippingAddress',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (deliveryAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Доставим ${_formatRuDate(deliveryAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (deliveryComment.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          deliveryComment.trim(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(orderId: id),
                              ),
                            );
                          },
                          child: const Text('Подробнее'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'canceled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'in_transit':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'pickup':
      case 'ready_for_pickup':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

String _formatRuDate(DateTime date) {
  const months = <String>[
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

