class Product {
  final int id;
  final String name;
  final String brand;
  final int? categoryId;
  final double price;
  final String imageUrl;
  // В UI используем это как "старая цена" (зачёркнутая).
  // На сервере поле `discount` похоже на % скидки, поэтому тут храним рассчитанную старую цену.
  final double discount;
  final int countFeedbacks;
  final double evaluation;

  // Детальная информация (может быть null для краткого отображения)
  final String? description;
  final String? specifications;
  final int? warranty;
  final String? color;
  final String? dimensions;
  final String? weight;
  final bool? isNew;
  final bool? isPopular;
  final int? quantity;
  final int? soldCount;
  final String? brandDetail; // Теперь просто имя бренда
  final List<Map<String, dynamic>>? images;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    this.categoryId,
    required this.price,
    required this.imageUrl,
    required this.discount,
    required this.countFeedbacks,
    required this.evaluation,
    this.description,
    this.specifications,
    this.warranty,
    this.color,
    this.dimensions,
    this.weight,
    this.isNew,
    this.isPopular,
    this.quantity,
    this.soldCount,
    this.brandDetail,
    this.images,
  });

  /// Процент скидки по [price] и зачёркнутой цене [discount] (как в UI).
  double get discountPercent {
    final oldPrice = discount;
    if (oldPrice <= 0 || price <= 0 || oldPrice <= price) return 0;
    return (1 - price / oldPrice) * 100;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final price = _asDouble(json['price']) ?? 0.0;
    final discountPercent = _asDouble(json['discount']) ?? 0.0;
    final oldPrice = discountPercent > 0
        ? price / (1 - (discountPercent / 100.0))
        : price;

    final imageUrl =
        (json['image_url'] as String?) ??
        _extractImageUrlFromImages(json['product_images']) ??
        '';

    List<Map<String, dynamic>>? images;
    if (json['images'] is List) {
      images = List<Map<String, dynamic>>.from(json['images'] as List);
    }

    return Product(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      categoryId: json['category_id'] != null
          ? (json['category_id'] as num).toInt()
          : null,
      price: price,
      imageUrl: imageUrl,
      discount: oldPrice,
      countFeedbacks:
          (json['count_feedbacks'] as int?) ??
          (json['reviews_count'] as int?) ??
          0,
      evaluation:
          _asDouble(json['evaluation']) ?? _asDouble(json['rating']) ?? 0.0,
      description: (json['description'] as String?),
      specifications: (json['specifications'] as String?),
      warranty: (json['warranty'] as int?),
      color: (json['color'] as String?),
      dimensions: (json['dimensions'] as String?),
      weight: (json['weight'] as String?),
      isNew: (json['is_new'] as bool?),
      isPopular: (json['is_popular'] as bool?),
      quantity: _asInt(json['quantity']),
      soldCount: (json['sold_count'] as int?),
      brandDetail: (json['brand'] as String?),
      images: images,
    );
  }
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _extractImageUrlFromImages(Object? images) {
  if (images is! List) return null;
  if (images.isEmpty) return null;
  final first = images.first;
  if (first is Map<String, dynamic>) {
    final url = first['image_url'];
    if (url is String) return url;
  }
  return null;
}
