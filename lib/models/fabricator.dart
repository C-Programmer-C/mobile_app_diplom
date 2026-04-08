class Fabricator {
  final int id;
  final String name;
  final String? imageUrl;
  final String? description;
  final String? phone;
  final String? email;
  final String? address;
  final double rating;
  final int totalProducts;

  Fabricator({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.phone,
    this.email,
    this.address,
    required this.rating,
    required this.totalProducts,
  });

  factory Fabricator.fromJson(Map<String, dynamic> json) {
    return Fabricator(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?),
      description: (json['description'] as String?),
      phone: (json['phone'] as String?),
      email: (json['email'] as String?),
      address: (json['address'] as String?),
      rating: _asDouble(json['rating']) ?? 0.0,
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
    );
  }
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
