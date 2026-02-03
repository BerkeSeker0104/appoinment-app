class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String iconName;
  final bool isActive;
  final String barberId;
  final String? companyServiceId; // Company-service ID for appointment creation

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.iconName,
    this.isActive = true,
    required this.barberId,
    this.companyServiceId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes:
          (json['duration_minutes'] as num?)?.toInt() ??
          (json['duration'] as num?)?.toInt() ??
          30,
      iconName:
          json['icon_name']?.toString() ??
          json['iconName']?.toString() ??
          'content_cut',
      isActive:
          json['is_active'] == true ||
          json['isActive'] == true ||
          json['status'] == 'active',
      barberId:
          json['barber_id']?.toString() ??
          json['barberId']?.toString() ??
          json['company_id']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'icon_name': iconName,
      'is_active': isActive,
      'barber_id': barberId,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? iconName,
    bool? isActive,
    String? barberId,
    String? companyServiceId,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      barberId: barberId ?? this.barberId,
      companyServiceId: companyServiceId ?? this.companyServiceId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ServiceModel(id: $id, name: $name, price: $price)';
  }
}
