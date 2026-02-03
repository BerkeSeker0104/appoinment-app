import 'dart:convert';
import 'localized_text.dart';

class ProductCategoryModel {
  final String id;
  final LocalizedText name;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    LocalizedText name;

    // name alanı JSON string olarak geliyor, parse et
    if (json['name'] is String) {
      try {
        final nameJson = jsonDecode(json['name'] as String);
        if (nameJson is Map<String, dynamic>) {
          name = LocalizedText.fromJson(nameJson);
        } else {
          name = LocalizedText(tr: json['name'] as String);
        }
      } catch (e) {
        // Parse edilemezse direkt string olarak kullan
        name = LocalizedText(tr: json['name'] as String);
      }
    } else if (json['name'] is Map) {
      name = LocalizedText.fromJson(json['name']);
    } else {
      name = LocalizedText(tr: '');
    }

    return ProductCategoryModel(
      id: json['id']?.toString() ?? '',
      name: name,
      imageUrl: json['picture'] as String?, // Backend'den picture alanı
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;

    // If it's already a full URL, return as is
    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    // If it's a relative path, add base URL
    const baseUrl = 'https://api.mandw.com.tr';
    // Add leading slash if not present
    final path = imageUrl!.startsWith('/') ? imageUrl! : '/$imageUrl';
    return '$baseUrl$path';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProductCategoryModel copyWith({
    String? id,
    LocalizedText? name,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
