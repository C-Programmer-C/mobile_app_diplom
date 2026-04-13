import 'package:flutter/material.dart';
import 'package:mobile_app/api.dart';
import 'package:mobile_app/models/product.dart';
import 'package:mobile_app/services/cart_sync.dart';
import 'package:mobile_app/utils/card_pan_input_formatter.dart';
import 'package:mobile_app/utils/ru_phone_input_formatter.dart';

class CheckoutScreen extends StatefulWidget {
  final List<int>? selectedProductIds;

  const CheckoutScreen({super.key, this.selectedProductIds});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardPanController = TextEditingController();
  bool _submitting = false;

  bool _loading = true;

  int? _deliveryTypeId;
  int? _pickupTypeId;
  String _deliveryMode = 'delivery'; // delivery | pickup
  String _paymentMethod = 'cash'; // card | cash

  List<Map<String, dynamic>> _cities = [];
  int? _selectedCityId;
  List<Map<String, dynamic>> _pickupPoints = [];
  int? _selectedPickupPointId;

  List<_CartLine> _lines = [];
  double _total = 0;
  bool _hadPhoneBefore = false;

  int _estimatedDaysForCurrentSelection() {
    if (_deliveryMode == 'pickup' && _selectedPickupPointId != null) {
      final point = _pickupPoints.cast<Map<String, dynamic>?>().firstWhere(
        (p) => p?['id'] == _selectedPickupPointId,
        orElse: () => null,
      );
      final days = (point?['estimated_days'] as num?)?.toInt();
      if (days != null && days > 0) return days;
    }
    return 3;
  }

  DateTime _estimatedDateForCheckout() {
    final days = _estimatedDaysForCurrentSelection();
    return DateTime.now().add(Duration(days: days));
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _cardPanController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (!ApiService.isAuthorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Войдите в профиль для оформления заказа'),
          ),
        );
        Navigator.of(context).maybePop();
      }
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final cartItems = await ApiService.fetchCartItems();
      final products = await ApiService.fetchProducts();
      final currentUser = await ApiService.fetchCurrentUser();
      final productsById = {for (final p in products) p.id: p};

      final wantedIds = widget.selectedProductIds;
      final filtered = cartItems.where((ci) {
        if (wantedIds == null) return true;
        return wantedIds.contains(ci.productId);
      }).toList();

      final lines = <_CartLine>[];
      double total = 0;
      for (final ci in filtered) {
        final product = productsById[ci.productId];
        if (product == null) continue;
        final lineTotal = product.price * ci.quantity;
        total += lineTotal;
        lines.add(
          _CartLine(
            product: product,
            quantity: ci.quantity,
            lineTotal: lineTotal,
          ),
        );
      }

      final deliveryTypes = await ApiService.fetchDeliveryTypes();

      int? pickupId;
      int? deliveryId;
      for (final dt in deliveryTypes) {
        final name = (dt['name'] ?? '').toString();
        if (name.contains('Самовывоз')) pickupId = dt['id'] as int;
        if (name.contains('Курьер')) deliveryId = dt['id'] as int;
      }

      final cities = await ApiService.fetchCities();
      final defaultCityId = cities.isNotEmpty
          ? cities.first['id'] as int
          : null;
      final userPhone = RuPhoneInputFormatter.formatFromAny(
        currentUser['phone']?.toString() ?? '',
      );
      final hadPhoneBefore = (currentUser['phone']?.toString() ?? '')
          .trim()
          .isNotEmpty;

      setState(() {
        _lines = lines;
        _total = total;
        _pickupTypeId = pickupId;
        _deliveryTypeId =
            deliveryId ??
            (deliveryTypes.isNotEmpty
                ? deliveryTypes.first['id'] as int
                : null);
        _cities = cities;
        _selectedCityId = defaultCityId;
        _pickupPoints = [];
        _selectedPickupPointId = null;
        _hadPhoneBefore = hadPhoneBefore;
        _phoneController.text = userPhone;
        _loading = false;
      });

      // авто-подгрузим ПВЗ если пользователь выбрал самовывоз
      if (_deliveryMode == 'pickup') {
        await _loadPickupPointsForCity(_selectedCityId);
      }
    } catch (e) {
      if (e.toString().contains('войти в профиль') ||
          e.toString().contains('авторизац')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Войдите в профиль для оформления заказа'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).maybePop();
        }
        return;
      }
      setState(() {
        _lines = [];
        _total = 0;
        _deliveryTypeId = null;
        _pickupTypeId = null;
        _cities = [];
        _selectedCityId = null;
        _pickupPoints = [];
        _selectedPickupPointId = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadPickupPointsForCity(int? cityId) async {
    if (cityId == null) {
      setState(() {
        _pickupPoints = [];
        _selectedPickupPointId = null;
      });
      return;
    }

    final points = await ApiService.fetchPickupPoints(cityId: cityId);
    setState(() {
      _pickupPoints = points;
      _selectedPickupPointId = points.isNotEmpty
          ? points.first['id'] as int
          : null;
    });
  }

  String _normalizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('/')) return '${ApiService.baseUrl}$trimmed';
    return trimmed;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!ApiService.isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Войдите в профиль для оформления заказа'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет товаров для оформления'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });

    try {
      final freshProducts = await ApiService.fetchProducts();
      final freshById = {for (final p in freshProducts) p.id: p};
      final unavailable = _lines.where((line) {
        final actual = freshById[line.product.id];
        return actual?.quantity != null && actual!.quantity! <= 0;
      }).toList();
      if (unavailable.isNotEmpty) {
        final names = unavailable.map((e) => e.product.name).join(', ');
        throw Exception('Нет в наличии: $names');
      }

      final productIds = _lines.map((l) => l.product.id).toSet().toList();

      int? pickupPointId;
      int? cityId;
      String shippingAddress;
      late int deliveryTypeId;

      if (_deliveryMode == 'pickup') {
        if (_pickupTypeId == null ||
            _selectedCityId == null ||
            _selectedPickupPointId == null) {
          throw Exception('Выберите город и пункт выдачи');
        }
        deliveryTypeId = _pickupTypeId!;
        cityId = _selectedCityId;
        pickupPointId = _selectedPickupPointId;
        shippingAddress = '';
      } else {
        if (_deliveryTypeId == null) {
          throw Exception('Выберите способ получения');
        }
        deliveryTypeId = _deliveryTypeId!;
        cityId = null;
        pickupPointId = null;
        shippingAddress = _addressController.text.trim();
      }

      final orderResponse = await ApiService.checkoutOrder(
        deliveryTypeId: deliveryTypeId,
        cityId: cityId,
        shippingAddress: shippingAddress,
        phone: _phoneController.text.trim(),
        pickupPointId: pickupPointId,
        productIds: productIds,
        paymentMethod: _paymentMethod,
        cardPan: _paymentMethod == 'card'
            ? _cardPanController.text.trim()
            : null,
      );

      if (!_hadPhoneBefore) {
        final enteredPhone = _phoneController.text.trim();
        if (enteredPhone.isNotEmpty) {
          try {
            await ApiService.updateCurrentUser(phone: enteredPhone);
            _hadPhoneBefore = true;
          } catch (_) {}
        }
      }

      CartSync.notifyChanged();
      if (!mounted) return;

      final deliveryAtText = orderResponse['delivery_at']?.toString();
      DateTime? deliveryAt;
      if (deliveryAtText != null && deliveryAtText.isNotEmpty) {
        deliveryAt = DateTime.tryParse(deliveryAtText)?.toLocal();
      }
      deliveryAt ??= _estimatedDateForCheckout();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Заказ успешно оформлен. Доставим ${_formatRuDeliveryRange(deliveryAt)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Оформление заказа')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Оформление заказа')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_lines.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Вы покупаете',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 152,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _lines.map((l) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 158,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.white,
                                        child:
                                            (l.product.imageUrl.trim().isEmpty)
                                            ? const Icon(
                                                Icons.photo,
                                                color: Colors.grey,
                                              )
                                            : Image.network(
                                                _normalizeUrl(
                                                  l.product.imageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Icon(
                                                        Icons.photo,
                                                        color: Colors.grey,
                                                      );
                                                    },
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        height: 1.25,
                                      ),
                                    ),
                                    Text(
                                      'x${l.quantity} • ${l.lineTotal.toStringAsFixed(0)} ₽',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('В корзине нет товаров для оформления.'),
                ),

              const SizedBox(height: 16),
              const Text(
                'Контактная информация',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.black),
                inputFormatters: [RuPhoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Введите телефон';
                  if (!RuPhoneInputFormatter.isComplete(v)) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Способ оплаты',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Банковская карта'),
                subtitle: const Text(
                  'Оплата онлайн — заказ сразу отмечается оплаченным',
                ),
                value: 'card',
                groupValue: _paymentMethod,
                activeColor: Colors.red,
                onChanged: (v) {
                  setState(() => _paymentMethod = v ?? 'cash');
                },
              ),
              RadioListTile<String>(
                title: const Text('Наличные при получении'),
                subtitle: const Text(
                  'Оплата на месте — статус «ожидает оплаты»',
                ),
                value: 'cash',
                groupValue: _paymentMethod,
                activeColor: Colors.red,
                onChanged: (v) {
                  setState(() {
                    _paymentMethod = v ?? 'cash';
                    if (_paymentMethod == 'cash') {
                      _cardPanController.clear();
                    }
                  });
                },
              ),
              if (_paymentMethod == 'card') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cardPanController,
                  style: const TextStyle(color: Colors.black),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CardPanInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Номер карты',
                    hintText: '4242 4242 4242 4242',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Введите номер карты';
                    if (!CardPanInputFormatter.isComplete(v)) {
                      return 'Номер карты: 13–19 цифр';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),
              const Text(
                'Способ получения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Доставка'),
                value: 'delivery',
                groupValue: _deliveryMode,
                activeColor: Colors.red,
                onChanged: (v) async {
                  setState(() {
                    _deliveryMode = v ?? 'delivery';
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Самовывоз'),
                value: 'pickup',
                groupValue: _deliveryMode,
                activeColor: Colors.red,
                onChanged: (v) async {
                  setState(() {
                    _deliveryMode = v ?? 'pickup';
                  });
                  await _loadPickupPointsForCity(_selectedCityId);
                },
              ),

              const SizedBox(height: 12),
              if (_deliveryMode == 'pickup') ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedCityId,
                  decoration: const InputDecoration(
                    labelText: 'Город',
                    border: OutlineInputBorder(),
                  ),
                  items: _cities.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(c['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      _selectedCityId = value;
                      _selectedPickupPointId = null;
                    });
                    await _loadPickupPointsForCity(value);
                  },
                  validator: (v) {
                    if (v == null) return 'Выберите город';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedPickupPointId,
                  decoration: const InputDecoration(
                    labelText: 'Пункт выдачи',
                    border: OutlineInputBorder(),
                  ),
                  items: _pickupPoints.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(p['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPickupPointId = value;
                    });
                  },
                  validator: (v) {
                    if (v == null) return 'Выберите пункт выдачи';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_selectedPickupPointId != null)
                  Builder(
                    builder: (_) {
                      final pp = _pickupPoints.firstWhere(
                        (p) => p['id'] == _selectedPickupPointId,
                        orElse: () => const {},
                      );
                      if (pp.isEmpty) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pp['name']?.toString() ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pp['address']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Часы: ${pp['working_hours']?.toString() ?? ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ] else ...[
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Адрес доставки',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Введите адрес доставки';
                    if (v.length < 3) return 'Адрес слишком короткий';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _deliveryMode == 'pickup'
                              ? 'Самовывоз:'
                              : 'Доставка:',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Text('Бесплатно'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ожидаемая доставка:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const VerticalDivider(width: 24),
                        Flexible(
                          child: Text(
                            _formatRuDeliveryRange(_estimatedDateForCheckout()),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_deliveryMode == 'pickup' &&
                        _selectedPickupPointId != null)
                      const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Итого к оплате:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_total.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
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

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Оформить заказ',
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
}

/// Окно доставки: дата ожидания + 3 дня, напр. «14–17 апреля».
String _formatRuDeliveryRange(DateTime startLocal) {
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

String _friendlyError(Object? error) {
  final text = (error ?? '').toString();
  if (text.contains('войти в профиль') || text.contains('авторизац')) {
    return 'Войдите в профиль для оформления заказа';
  }
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text.isEmpty ? 'Не удалось оформить заказ. Попробуйте снова.' : text;
}

class _CartLine {
  final Product product;
  final int quantity;
  final double lineTotal;

  _CartLine({
    required this.product,
    required this.quantity,
    required this.lineTotal,
  });
}
