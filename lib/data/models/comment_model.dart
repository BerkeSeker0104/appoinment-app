class CommentModel {
  final String id;
  final String? companyId;
  final String? customerId;
  final String? customerName;
  final String? customerSurname;
  final String? customerImage;
  final String comment;
  final int score; // Backend uses 'score' instead of 'rating'
  final String? appointmentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommentModel({
    required this.id,
    this.companyId,
    this.customerId,
    this.customerName,
    this.customerSurname,
    this.customerImage,
    required this.comment,
    required this.score,
    this.appointmentId,
    this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? surname;
    String? id;
    
    // Parse user object if exists
    if (json['user'] is Map) {
      final user = json['user'];
      name = user['name']?.toString();
      surname = user['surname']?.toString();
      id = user['id']?.toString();
    }
    
    // Fallback to root fields
    name ??= json['customerName']?.toString() ?? json['customer_name']?.toString();
    surname ??= json['customerSurname']?.toString() ?? json['customer_surname']?.toString();
    id ??= json['customerId']?.toString() ?? json['customer_id']?.toString();

    // Parse appointmentId - backend returns it inside "appointment" object
    String? appointmentId;
    if (json['appointmentId'] != null) {
      appointmentId = json['appointmentId'].toString();
    } else if (json['appointment_id'] != null) {
      appointmentId = json['appointment_id'].toString();
    } else if (json['appointment'] is Map) {
      // Backend returns appointment object with id inside
      final appointment = json['appointment'] as Map;
      appointmentId = appointment['id']?.toString();
    }

    return CommentModel(
      id: json['id']?.toString() ?? '',
      companyId:
          json['companyId']?.toString() ?? json['company_id']?.toString(),
      customerId: id,
      customerName: name,
      customerSurname: surname,
      customerImage: json['customerImage']?.toString() ??
          json['customer_image']?.toString(),
      comment: json['comment']?.toString() ?? '',
      score: _parseScore(json['score']),
      appointmentId: appointmentId,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'score': score,
      'comment': comment,
    };
  }

  static int _parseScore(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseDateTime(dynamic dateString) {
    if (dateString == null) return null;
    if (dateString is DateTime) return dateString;
    if (dateString is String) {
      return DateTime.tryParse(dateString);
    }
    return null;
  }

  CommentModel copyWith({
    String? id,
    String? companyId,
    String? customerId,
    String? customerName,
    String? customerSurname,
    String? customerImage,
    String? comment,
    int? score,
    String? appointmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerSurname: customerSurname ?? this.customerSurname,
      customerImage: customerImage ?? this.customerImage,
      comment: comment ?? this.comment,
      score: score ?? this.score,
      appointmentId: appointmentId ?? this.appointmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String get formattedDate {
    if (createdAt == null) return 'Tarih bilinmiyor';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays < 1) {
      return 'Bugün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} hafta önce';
    } else {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
  }

  // Getter for backward compatibility with rating
  int get rating => score;

  String get maskedFullName {
    if (customerName == null) return 'Anonim Kullanıcı';
    
    final name = customerName!.trim();
    if (name.isEmpty) return 'Anonim Kullanıcı';

    String surnameMasked = '';
    if (customerSurname != null && customerSurname!.isNotEmpty) {
      final surname = customerSurname!.trim();
      if (surname.isNotEmpty) {
        surnameMasked = '${surname[0]}**';
        return '$name $surnameMasked';
      }
    }

    return name;
  }
}
