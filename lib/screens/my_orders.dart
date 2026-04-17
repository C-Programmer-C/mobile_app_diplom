import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/screens/order_detail_screen.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/utils/order_cancel.dart';
import 'package:mobile_app/utils/order_display.dart';
import 'package:mobile_app/utils/payment_labels.dart';
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
                o['estimated_delivery_at']?.toString() ??
                    o['delivery_at']?.toString() ??
                    '',
              )?.toLocal();
              final totalAmount = (o['total_amount'] as num?)?.toDouble() ?? 0;
              final payStatus = o['payment_status']?.toString();
              final payMethod = o['payment_method']?.toString();
              final createdAt = parseOrderCreatedAt(o['created_at']);
              final canCancel =
                  orderCanCancelWithinWindow(status, createdAt);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Заказ #$id',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
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
                        orderStatusRu(status),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                      if (payStatus != null && payStatus.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${paymentStatusRu(payStatus)}'
                          '${payMethod != null && payMethod.isNotEmpty ? ' • ${paymentMethodRu(payMethod)}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _paymentStatusColor(payStatus),
                          ),
                        ),
                      ],
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
                          'Ожидаемая доставка: ${formatRuDeliveryRange(deliveryAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (canCancel) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: () => _tryCancelOrder(context, id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Отменить заказ'),
                          ),
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

  Future<void> _tryCancelOrder(BuildContext context, int orderId) async {
    if (!await showCancelOrderConfirmDialog(context)) return;
    if (!context.mounted) return;
    try {
      await ApiService.cancelOrder(orderId);
      if (!context.mounted) return;
      setState(() {
        _future = ApiService.fetchMyOrders();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ отменён')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toUserMessage(e))),
      );
    }
  }

  Color _paymentStatusColor(String raw) {
    switch (raw) {
      case 'paid':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
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

