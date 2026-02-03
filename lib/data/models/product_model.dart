import '../../core/constants/api_constants.dart';

class ProductModel {
  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String companyName;
  final List<String> pictures;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.companyName,
    required this.pictures,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _parseDouble(json['price']),
      companyName: json['userDetail']?['company']?['name'] as String? ?? '',
      pictures: _parsePictures(json['pictures'] ?? json['images']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static List<String> _parsePictures(dynamic pictures) {
    if (pictures == null || pictures is! List) return [];

    return pictures
        .map((item) {
          if (item is Map) {
            final picturePath = item['picture'] as String?;
            if (picturePath != null) {
              // FILE_URL + picture.file (backend mantığı)
              return '${ApiConstants.fileUrl}$picturePath';
            }
          }
          return null;
        })
        .whereType<String>()
        .toList();
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'companyName': companyName,
      'pictures': pictures,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? companyName,
    List<String>? pictures,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      companyName: companyName ?? this.companyName,
      pictures: pictures ?? this.pictures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
