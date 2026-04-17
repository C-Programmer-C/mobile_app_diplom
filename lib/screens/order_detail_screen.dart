import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/screens/product_detail.dart';
import 'package:mobile_app/utils/error_message.dart';
import 'package:mobile_app/utils/order_cancel.dart';
import 'package:mobile_app/utils/order_display.dart';
import 'package:mobile_app/utils/payment_labels.dart';
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

  Future<void> _openProductFromOrderLine(
    BuildContext context,
    Map<String, dynamic> line,
  ) async {
    final productId = (line['product_id'] as num?)?.toInt();
    if (productId == null) return;
    try {
      final product = await ApiService.fetchProductDetails(productId);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toUserMessage(e))),
      );
    }
  }

  Future<void> _tryCancel(BuildContext context) async {
    if (!await showCancelOrderConfirmDialog(context)) return;
    if (!context.mounted) return;
    try {
      await ApiService.cancelOrder(widget.orderId);
      if (!context.mounted) return;
      setState(() {
        _future = ApiService.fetchOrderDetail(widget.orderId);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final loaded = snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError &&
            snapshot.hasData;
        final orderMap = loaded ? snapshot.data! : null;
        final headerStatus = orderMap?['status']?.toString() ?? '';
        final createdAt = orderMap != null
            ? parseOrderCreatedAt(orderMap['created_at'])
            : null;
        final canCancel = orderMap != null &&
            orderCanCancelWithinWindow(headerStatus, createdAt);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('Заказ #${widget.orderId}'),
            actions: [
              if (canCancel)
                TextButton(
                  onPressed: () => _tryCancel(context),
                  child: const Text(
                    'Отменить заказ',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          body: _orderDetailBody(context, snapshot),
        );
      },
    );
  }

  Widget _orderDetailBody(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
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
      order['estimated_delivery_at']?.toString() ??
          order['delivery_at']?.toString() ??
          '',
    )?.toLocal();
    final phone = order['phone']?.toString() ?? '';
    final paymentStatus = order['payment_status']?.toString();
    final paymentMethod = order['payment_method']?.toString();
    final paidAt = DateTime.tryParse(
      order['paid_at']?.toString() ?? '',
    )?.toLocal();
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
                    'Статус: ${orderStatusRu(status)}',
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
                  const SizedBox(height: 6),
                  Text(
                    'Оплата: ${paymentStatusRu(paymentStatus)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _paymentStatusColor(paymentStatus),
                    ),
                  ),
                  if (paymentMethod != null && paymentMethod.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Способ: ${paymentMethodRu(paymentMethod)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (paidAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Дата оплаты: ${_formatRuDate(paidAt)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (deliveryAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ожидаемая доставка: ${formatRuDeliveryRange(deliveryAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('В заказе нет товаров')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final it = items[index];
                final name = it['product_name']?.toString() ?? '';
                final imageUrl = it['product_image_url']?.toString() ?? '';
                final qty = (it['quantity'] as num?)?.toInt() ?? 0;
                final price = (it['price'] as num?)?.toDouble() ?? 0;
                final lineTotal =
                    (it['line_total'] as num?)?.toDouble() ?? price * qty;

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openProductFromOrderLine(context, it),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                                    errorBuilder: (context, error, stackTrace) {
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
                                const SizedBox(height: 4),
                                Text('Количество: $qty'),
                                const SizedBox(height: 4),
                                Text(
                                  'Цена: ${price.toStringAsFixed(0)} ₽',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Подробнее о товаре',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
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
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  Color _paymentStatusColor(String? raw) {
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

  String _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.baseUrl}$trimmed';
    if (trimmed.startsWith('http://127.0.0.1:8000')) {
      return trimmed.replaceFirst(
        'http://127.0.0.1:8000',
        ApiService.baseUrl,
      );
    }
    if (trimmed.startsWith('http://localhost:8000')) {
      return trimmed.replaceFirst(
        'http://localhost:8000',
        ApiService.baseUrl,
      );
    }
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

