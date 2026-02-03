class Category {
  final String id;
  final String nameTr;
  final String nameEn;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.nameTr,
    this.nameEn = '',
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? id,
    String? nameTr,
    String? nameEn,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      nameTr: nameTr ?? this.nameTr,
      nameEn: nameEn ?? this.nameEn,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String getName([String locale = 'tr']) {
    if (locale == 'en' && nameEn.isNotEmpty) {
      return nameEn;
    }
    return nameTr;
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
}
