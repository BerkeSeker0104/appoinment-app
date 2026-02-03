import 'dart:convert';

enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

class AppointmentModel {
  final String id;
  final String companyId;
  final String? companyName;
  final String? branchName;
  final String customerName;
  final String? customerLastName;
  final String? customerPhone;
  final String startDate; // YYYY-MM-DD format
  final String startHour; // HH:MM format
  final String? finishHour; // HH:MM format (optional)
  final List<ServiceInfo> services;
  final double? totalPrice;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paidType;
  final String? cardNumber;
  final String? cardExpirationMonth;
  final String? cardExpirationYear;
  final String? cardCvc;
  final String? approveCode;

  const AppointmentModel({
    required this.id,
    required this.companyId,
    this.companyName,
    this.branchName,
    required this.customerName,
    this.customerLastName,
    this.customerPhone,
    required this.startDate,
    required this.startHour,
    this.finishHour,
    required this.services,
    this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.paidType,
    this.cardNumber,
    this.cardExpirationMonth,
    this.cardExpirationYear,
    this.cardCvc,
    this.approveCode,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // ID'yi farklı field isimlerinden almayı dene
    final id = json['id']?.toString() ?? 
               json['_id']?.toString() ?? 
               json['appointmentId']?.toString() ?? 
               json['appointment_id']?.toString() ?? 
               '';
    
    return AppointmentModel(
      id: id,
      companyId:
          json['companyId']?.toString() ?? json['company_id']?.toString() ?? '',
      companyName: json['companyName'] ??
          json['company_name'] ??
          (json['company'] is Map ? json['company']['name'] : null) ??
          (json['barber'] is Map ? json['barber']['name'] : null) ??
          (json['business'] is Map ? json['business']['name'] : null),
      branchName: json['branchName'] ?? json['branch_name'],
      customerName: json['customerName'] ?? json['customer_name'] ?? '',
      customerLastName: json['customerLastName'] ?? json['customer_last_name'],
      customerPhone: json['customerPhone'] ?? json['customer_phone'],
      startDate: (json['startDate'] ??
              json['start_date'] ??
              json['appointment_date'] ??
              '')
          .toString()
          .trim()
          .split(' ') // Split datetime to get just the date part
          .first, // Take the first part (YYYY-MM-DD)
      startHour: (json['startHour'] ??
              json['start_hour'] ??
              json['time_slot'] ??
              '')
          .toString()
          .trim(),
      finishHour: json['finishHour'] ?? json['finish_hour'],
      services: _parseServices(json['services']),
      totalPrice: _parsePrice(json['totalPrice'] ?? json['total_price']),
      status: _parseStatus(json['status']),
      notes: json['notes'],
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt: json['updatedAt'] != null || json['updated_at'] != null
          ? DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '')
          : null,
      paidType: json['paidType'],
      approveCode: json['approveCode'] ?? json['approve_code'],
    );
  }

  static List<ServiceInfo> _parseServices(dynamic services) {
    if (services == null) return [];

    try {
      // "['...']" veya "[{...}]" gibi String JSON ise decode et
      if (services is String) {
        final decoded = jsonDecode(services);
        if (decoded is List) {
          return decoded
              .map((e) => ServiceInfo.fromJson(_asMap(e)))
              .whereType<ServiceInfo>()
              .toList();
        }
        // tek obje string'i gelirse onu da listele
        if (decoded is Map<String, dynamic>) {
          return [ServiceInfo.fromJson(decoded)];
        }
      }

      if (services is List) {
        return services
            .map((service) => ServiceInfo.fromJson(_asMap(service)))
            .whereType<ServiceInfo>()
            .toList();
      }
    } catch (e) {
      // Gözlem için log bırak
    }

    return [];
  }

  static double? _parsePrice(dynamic price) {
    if (price == null) return null;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price);
    return null;
  }

  // List/Map "loose" dönüşümü için küçük yardımcı
  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{}; // boş düşer, fromJson default'ları çalışır
  }

  static AppointmentStatus _parseStatus(dynamic status) {
    if (status == null) return AppointmentStatus.pending;

    final statusStr = status.toString().toLowerCase();

    // Backend'den sayısal değerler geliyorsa
    if (statusStr == '0') return AppointmentStatus.pending;
    if (statusStr == '1') return AppointmentStatus.confirmed;
    if (statusStr == '2') return AppointmentStatus.completed;
    if (statusStr == '3') return AppointmentStatus.cancelled;
    if (statusStr == '4') return AppointmentStatus.noShow;     // Ödenmedi
    if (statusStr == '5') return AppointmentStatus.inProgress; // Başlatıldı

    // String değerler için
    switch (statusStr) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
      case 'canceled':
        return AppointmentStatus.cancelled;
      case 'no_show':
      case 'noshow':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'branchName': branchName,
      'customerName': customerName,
      'customerLastName': customerLastName,
      'customerPhone': customerPhone,
      'startDate': startDate,
      'startHour': startHour,
      'services': services.map((service) => service.toJson()).toList(),
      'totalPrice': totalPrice,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paidType': paidType,
      'cardNumber': cardNumber,
      'cardExpirationMonth': cardExpirationMonth,
      'cardExpirationYear': cardExpirationYear,
      'cardCvc': cardCvc,
      'approveCode': approveCode,
    };
  }

  // Create appointment request format for API
  Map<String, dynamic> toCreateRequest() {
    return {
      'companyId': companyId,
      'customerName': customerName,
      'customerLastName': customerLastName ?? '',
      'customerPhone': customerPhone ?? '',
      'startDate': startDate,
      'startHour': startHour,
      'paidType': paidType,
      'services': services
          .map(
            (service) => {
              'id': service.id,
              'price': service.price.toString(),
            },
          )
          .toList(),
      'cardNumber': cardNumber,
      'cardExpirationMonth': cardExpirationMonth,
      'cardExpirationYear': cardExpirationYear,
      'cardCvc': cardCvc,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? branchName,
    String? customerName,
    String? customerLastName,
    String? customerPhone,
    String? startDate,
    String? startHour,
    List<ServiceInfo>? services,
    double? totalPrice,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paidType,
    String? cardNumber,
    String? cardExpirationMonth,
    String? cardExpirationYear,
    String? cardCvc,
    String? approveCode,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      branchName: branchName ?? this.branchName,
      customerName: customerName ?? this.customerName,
      customerLastName: customerLastName ?? this.customerLastName,
      customerPhone: customerPhone ?? this.customerPhone,
      startDate: startDate ?? this.startDate,
      startHour: startHour ?? this.startHour,
      services: services ?? this.services,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidType: paidType ?? this.paidType,
      cardNumber: cardNumber ?? this.cardNumber,
      cardExpirationMonth: cardExpirationMonth ?? this.cardExpirationMonth,
      cardExpirationYear: cardExpirationYear ?? this.cardExpirationYear,
      cardCvc: cardCvc ?? this.cardCvc,
      approveCode: approveCode ?? this.approveCode,
    );
  }

  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Beklemede';
      case AppointmentStatus.confirmed:
        return 'Onaylandı';
      case AppointmentStatus.inProgress:
        return 'Devam Ediyor';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelled:
        return 'Reddedildi / İptal';
      case AppointmentStatus.noShow:
        return 'Gelmedi';
    }
  }

  String get fullCustomerName {
    if (customerLastName != null && customerLastName!.isNotEmpty) {
      return '$customerName $customerLastName';
    }
    return customerName;
  }

  String get formattedDateTime {
    return '$startDate $startHour';
  }

  bool get canBeCancelled =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get canBeApproved => status == AppointmentStatus.pending;

  bool get canBeCompleted => 
      status == AppointmentStatus.confirmed || status == AppointmentStatus.inProgress;

  bool get isRejected => status == AppointmentStatus.cancelled;

  bool get isActive =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.inProgress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppointmentModel(id: $id, date: $startDate, status: $status)';
  }
}

class ServiceInfo {
  final String id;
  final String name;
  final double price;
  final int? durationMinutes;

  const ServiceInfo({
    required this.id,
    required this.name,
    required this.price,
    this.durationMinutes,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    String serviceName = 'Hizmet';

    // 1) name bir Map ise (doğrudan)
    if (json['name'] is Map) {
      final nameMap = Map<String, dynamic>.from(json['name']);
      serviceName = _pickLocalizedName(nameMap);
    }
    // 2) name bir String JSON ise
    else if (json['name'] is String) {
      final nameStr = json['name'] as String;
      final maybeMap = _tryDecodeMap(nameStr);
      if (maybeMap != null) {
        serviceName = _pickLocalizedName(maybeMap);
      } else {
        // düz string ise olduğu gibi kullan (örn: "Saç Kesim")
        serviceName = nameStr;
      }
    }
    // 3) alternatif anahtarlar
    else {
      serviceName = json['name']?.toString() ??
          json['serviceName']?.toString() ??
          json['service_name']?.toString() ??
          'Hizmet';
    }

    return ServiceInfo(
      id: json['id']?.toString() ?? '',
      name: serviceName,
      price: _parsePrice(json['price']),
      durationMinutes: (json['duration_minutes'] ?? json['durationMinutes']) !=
              null
          ? int.tryParse(
              (json['duration_minutes'] ?? json['durationMinutes']).toString(),
            )
          : null,
    );
  }

  static Map<String, dynamic>? _tryDecodeMap(String raw) {
    try {
      if (raw.trim().startsWith('{')) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      // sessiz geç
    }
    return null;
  }

  static String _pickLocalizedName(Map<String, dynamic> nameMap) {
    // Öncelik: tr > en > ilk değer
    return (nameMap['tr'] ??
            nameMap['TR'] ??
            nameMap['tr-TR'] ??
            nameMap['en'] ??
            nameMap['EN'] ??
            nameMap.values.first)
        .toString();
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration_minutes': durationMinutes,
    };
  }
}

class AvailabilitySlot {
  final String startDate;
  final String finishDate;
  final String startHour;
  final String finishHour;

  const AvailabilitySlot({
    required this.startDate,
    required this.finishDate,
    required this.startHour,
    required this.finishHour,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      startDate: (json['startDate'] ?? json['start_date'] ?? '').toString(),
      finishDate: (json['finishDate'] ?? json['finish_date'] ?? '').toString(),
      startHour: (json['startHour'] ?? json['start_hour'] ?? '').toString(),
      finishHour: (json['finishHour'] ?? json['finish_hour'] ?? '').toString(),
    );
  }

  String get normalizedStartHour =>
      _normalizeTime(startHour.isEmpty ? startDate.split(' ').last : startHour);

  String get normalizedFinishHour =>
      _normalizeTime(finishHour.isEmpty ? finishDate.split(' ').last : finishHour);

  String _normalizeTime(String time) {
    if (time.isEmpty) return '00:00';
    final trimmed = time.trim();
    if (!trimmed.contains(':')) return trimmed;
    final parts = trimmed.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    }
    return trimmed;
  }
}
