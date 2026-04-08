import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/widgets/server_error_view.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ServerErrorView(
              message: 'Ошибка загрузки заказа: ${toUserMessage(snapshot.error)}',
              onRetry: () {
                setState(() {
                  _future = ApiService.fetchOrderDetail(widget.orderId);
                });
              },
            );
          }

          final order = snapshot.data ?? {};
          final status = order['status']?.toString() ?? '';
          final deliveryType = order['delivery_type']?.toString() ?? '';
          final shippingAddress = order['shipping_address']?.toString() ?? '';
          final deliveryAt = DateTime.tryParse(
            order['delivery_at']?.toString() ?? '',
          )?.toLocal();
          final deliveryComment = order['delivery_comment']?.toString() ?? '';
          final phone = order['phone']?.toString() ?? '';
          final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
          final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Статус: $status',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _statusColor(status),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (deliveryType.isNotEmpty)
                          Text(
                            'Получение: $deliveryType',
                            style: const TextStyle(fontSize: 13),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Адрес: $shippingAddress',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Телефон: $phone',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (deliveryAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Примерная дата доставки: ${_formatRuDate(deliveryAt)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (deliveryComment.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            deliveryComment.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Итого: ${totalAmount.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Товары в заказе',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Text('В заказе нет товаров')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      final name = it['product_name']?.toString() ?? '';
                      final imageUrl = it['product_image_url']?.toString() ?? '';
                      final qty = (it['quantity'] as num?)?.toInt() ?? 0;
                      final price = (it['price'] as num?)?.toDouble() ?? 0;
                      final lineTotal =
                          (it['line_total'] as num?)?.toDouble() ?? price * qty;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: imageUrl.trim().isEmpty
                                    ? const Icon(Icons.photo, color: Colors.grey)
                                    : Image.network(
                                        _normalizeUrl(imageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.photo,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Количество: $qty'),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Цена: ${price.toStringAsFixed(0)} ₽',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${lineTotal.toStringAsFixed(0)} ₽',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
              ],
            ),
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

  String _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.baseUrl}$trimmed';
    return trimmed;
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

