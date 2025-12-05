class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imgURL;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imgURL,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'No name',
      description: json['des'] ?? '', // 👈 JSON bạn dùng key là "des"
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] ?? 0.0).toDouble(),
      imgURL: json['imgURL'] ?? '',
    );
  }
}
