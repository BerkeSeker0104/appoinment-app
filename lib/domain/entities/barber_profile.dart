class BarberProfile {
  final String id;
  final String userId;
  final String businessName;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final List<String> services;
  final Map<String, double> pricing;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final Map<String, String> workingHours; // day -> "09:00-18:00"
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BarberProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.services,
    required this.pricing,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.workingHours,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  BarberProfile copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    List<String>? services,
    Map<String, double>? pricing,
    double? rating,
    int? reviewCount,
    List<String>? images,
    Map<String, String>? workingHours,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BarberProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      services: services ?? this.services,
      pricing: pricing ?? this.pricing,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      images: images ?? this.images,
      workingHours: workingHours ?? this.workingHours,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);
  String get priceRange {
    if (pricing.isEmpty) return 'N/A';
    final prices = pricing.values.toList()..sort();
    if (prices.length == 1) return '₺${prices.first.toInt()}';
    return '₺${prices.first.toInt()} - ₺${prices.last.toInt()}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarberProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
