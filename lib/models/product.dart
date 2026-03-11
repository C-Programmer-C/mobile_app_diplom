class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final double discount;
  final int countFeedbacks;
  final double evaluation;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.discount,
    required this.countFeedbacks,
    required this.evaluation,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      discount: (json['discount'] as num).toDouble(),
      countFeedbacks: json['count_feedbacks'] as int,
      evaluation: (json['evaluation'] as num).toDouble(),
    );
  }
}
