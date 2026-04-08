class CartItem {
  final int id;
  final int productId;
  final int quantity;

  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

