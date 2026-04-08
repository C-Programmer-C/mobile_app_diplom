class Review {
  final int id;
  final int userId;
  final int productId;
  final String comment;
  final double rating;
  final DateTime? createdAt;
  final String userName;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.comment,
    required this.rating,
    this.createdAt,
    required this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      comment: (json['comment'] as String?) ?? '',
      rating: _asDouble(json['rating']) ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      userName: (json['user_name'] as String?) ?? 'Анонимный пользователь',
    );
  }
}

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
