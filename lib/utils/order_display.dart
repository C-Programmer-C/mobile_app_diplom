String orderStatusRu(String? raw) {
  switch (raw) {
    case 'pending':
      return 'Принят, ждёт обработки';
    case 'processing':
      return 'Собираем заказ';
    case 'shipped':
      return 'Передан в доставку';
    case 'in_transit':
      return 'В пути';
    case 'delivered':
      return 'Доставлен';
    case 'pickup':
      return 'Самовывоз';
    case 'ready_for_pickup':
      return 'Готов к выдаче';
    case 'canceled':
      return 'Отменён';
    default:
      return raw?.isNotEmpty == true ? raw! : '—';
  }
}

String formatRuDeliveryRange(DateTime startLocal) {
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
  final end = startLocal.add(const Duration(days: 3));
  if (startLocal.year == end.year && startLocal.month == end.month) {
    if (startLocal.day == end.day) {
      return '${startLocal.day} ${months[startLocal.month - 1]}';
    }
    return '${startLocal.day}–${end.day} ${months[startLocal.month - 1]}';
  }
  return '${startLocal.day} ${months[startLocal.month - 1]} – '
      '${end.day} ${months[end.month - 1]}';
}
