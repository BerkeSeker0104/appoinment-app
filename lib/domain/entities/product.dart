class Product {
  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final List<String> pictures;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String companyName;

  const Product({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.pictures,
    required this.createdAt,
    required this.updatedAt,
    required this.companyName,
  });

  Product copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    List<String>? pictures,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyName,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      pictures: pictures ?? this.pictures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyName: companyName ?? this.companyName,
    );
  }

  String get mainImage => pictures.isNotEmpty ? pictures.first : '';
}
