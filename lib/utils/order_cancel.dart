import 'package:flutter/material.dart';

const Duration kOrderCancelWindow = Duration(minutes: 15);

DateTime? parseOrderCreatedAt(Object? raw) {
  final s = raw?.toString();
  if (s == null || s.isEmpty) return null;
  final dt = DateTime.tryParse(s);
  if (dt == null) return null;
  if (dt.isUtc) return dt.toUtc();
  return DateTime.utc(
    dt.year,
    dt.month,
    dt.day,
    dt.hour,
    dt.minute,
    dt.second,
    dt.millisecond,
    dt.microsecond,
  );
}

bool orderCanCancelWithinWindow(String status, DateTime? createdAtUtc) {
  if (status == 'canceled') return false;
  if (createdAtUtc == null) return false;
  final now = DateTime.now().toUtc();
  return now.difference(createdAtUtc) < kOrderCancelWindow;
}

Future<bool> showCancelOrderConfirmDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Отмена заказа'),
      content: const Text('Вы точно хотите отменить заказ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Нет'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Да, отменить'),
        ),
      ],
    ),
  );
  return ok == true;
}
