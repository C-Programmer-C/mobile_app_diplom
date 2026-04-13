String paymentStatusRu(String? raw) {
  switch (raw) {
    case 'paid':
      return 'Оплачен';
    case 'failed':
      return 'Ошибка оплаты';
    case 'pending':
    default:
      return 'Ожидает оплаты';
  }
}

String paymentMethodRu(String? raw) {
  switch (raw) {
    case 'card':
      return 'Карта';
    case 'cash':
      return 'Наличные';
    default:
      return raw?.isNotEmpty == true ? raw! : '—';
  }
}
