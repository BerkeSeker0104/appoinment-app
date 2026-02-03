import 'dart:convert';
import '../../core/services/locale_service.dart';

class CompanyServiceModel {
  final String id;
  final List<dynamic> companyIds; // int (sayısal ID) veya String (UUID) olabilir
  final String serviceId;
  final String? serviceName; // Service detayı API'den gelecek
  final double minPrice;
  final double? maxPrice; // Nullable - tek fiyat durumunda null
  final int duration; // Dakika cinsinden
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyServiceModel({
    required this.id,
    required this.companyIds,
    required this.serviceId,
    this.serviceName,
    required this.minPrice,
    this.maxPrice,
    required this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

    factory CompanyServiceModel.fromJson(Map<String, dynamic> json) {
    // Parse company IDs - array olarak gelecek
    // int (sayısal ID) veya String (UUID) olabilir
    List<dynamic> parsedCompanyIds = [];

    // 1. Önce liste formatlarını kontrol et
    if (json['companyIds'] is List) {
      parsedCompanyIds = (json['companyIds'] as List).map((e) {
        if (e is int) return e;
        final str = e.toString();
        final parsed = int.tryParse(str);
        return parsed ?? str;
      }).toList();
    } 
    
    if (parsedCompanyIds.isEmpty && json['company_ids'] is List) {
      parsedCompanyIds = (json['company_ids'] as List).map((e) {
        if (e is int) return e;
        final str = e.toString();
        final parsed = int.tryParse(str);
        return parsed ?? str;
      }).toList();
    }
    
    if (parsedCompanyIds.isEmpty && json['companies'] is List) {
      parsedCompanyIds = (json['companies'] as List).map((company) {
        if (company is Map<String, dynamic>) {
          final id = company['id']?.toString() ?? '0';
          final parsed = int.tryParse(id);
          return parsed ?? id;
        }
        final str = company.toString();
        final parsed = int.tryParse(str);
        return parsed ?? str;
      }).toList();
    }

    // 2. Liste boşsa veya yoksa tekil ID alanlarını kontrol et
    if (parsedCompanyIds.isEmpty) {
      if (json['companyId'] != null) {
        final companyIdValue = json['companyId'];
        final companyIdStr = companyIdValue.toString();
        final companyId = int.tryParse(companyIdStr);
        
        if (companyId != null && companyId > 0) {
          parsedCompanyIds = [companyId];
        } else if (companyIdStr.isNotEmpty && companyIdStr != 'null') {
          parsedCompanyIds = [companyIdStr];
        }
      } else if (json['company_id'] != null) {
        final companyIdValue = json['company_id'];
        final companyIdStr = companyIdValue.toString();
        final companyId = int.tryParse(companyIdStr);
        
        if (companyId != null && companyId > 0) {
          parsedCompanyIds = [companyId];
        } else if (companyIdStr.isNotEmpty && companyIdStr != 'null') {
          parsedCompanyIds = [companyIdStr];
        }
      }
    }
    
    // 3. Hala boşsa company objesini kontrol et
    if (parsedCompanyIds.isEmpty && json['company'] is Map<String, dynamic>) {
      final company = json['company'] as Map<String, dynamic>;
      final companyIdValue = company['id'];
      if (companyIdValue != null) {
        final companyIdStr = companyIdValue.toString();
        if (companyIdStr.isNotEmpty && companyIdStr != 'null') {
          final parsedId = int.tryParse(companyIdStr);
          parsedCompanyIds = [parsedId ?? companyIdStr];
        }
      }
    }

    // Parse service name - nested object olabilir
    String? parsedServiceName;
    if (json['service'] is Map<String, dynamic>) {
      final serviceMap = json['service'] as Map<String, dynamic>;
      parsedServiceName = _parseMultiLangString(serviceMap['name']);
    } else if (json['serviceName'] != null) {
      parsedServiceName = _parseMultiLangString(json['serviceName']);
    } else if (json['service_name'] != null) {
      parsedServiceName = _parseMultiLangString(json['service_name']);
    }

    return CompanyServiceModel(
      id: json['id']?.toString() ?? '',
      companyIds: parsedCompanyIds,
      serviceId:
          json['serviceId']?.toString() ?? json['service_id']?.toString() ?? '',
      serviceName: parsedServiceName,
      minPrice: _parsePrice(json['minPrice'] ?? json['min_price']),
      maxPrice: _parsePrice(json['maxPrice'] ?? json['max_price']),
      duration: _parseDuration(json['duration']),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({
    bool includeId = false,
    bool isUpdate = false, // PUT için farklı format
  }) {
    // Backend format - Postman'den gelen format
    // ÖNEMLİ: serviceId ve duration STRING olmalı!
    final json = <String, dynamic>{
      'serviceId': serviceId, // STRING olarak gönder
      'minPrice': minPrice.toInt(), // Int olarak gönder
      'duration': duration.toString(), // STRING olarak gönder
    };

    // UPDATE için: companyId (tekil) - ID BODY'DE YOK!
    // CREATE için: companyIds (array)
    if (isUpdate) {
      // PUT: Backend TEKİL companyId bekliyor (array değil!)
      if (companyIds.isNotEmpty) {
        json['companyId'] = companyIds.first; // İlk company ID'yi al
      }
      // ❌ ID'yi body'e EKLEME - sadece URL'de!
      // Backend body'de ID istemiyor (validation.invalid hatası veriyor)
    } else {
      // POST: companyIds array olarak
      json['companyIds'] = companyIds;
      // Create işleminde ID'yi body'e ekle (istenirse)
      if (includeId && id.isNotEmpty) {
        json['id'] = int.tryParse(id) ?? id;
      }
    }

    // maxPrice varsa ekle (null ise ekleme)
    if (maxPrice != null) {
      json['maxPrice'] = maxPrice!.toInt(); // Int olarak gönder
    } else {
      json['maxPrice'] = null; // Explicitly null gönder
    }

    return json;
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseDuration(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static String? _parseMultiLangString(dynamic value) {
    if (value == null) return null;

    final localeService = LocaleService();
    final currentLang = localeService.currentLanguageCode;
    final fallbackLang = currentLang == 'tr' ? 'en' : 'tr';

    if (value is String) {
      // Check if the string is a JSON object
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          // Aktif dil, fallback dil, sonra orijinal string
          return decoded[currentLang] as String? ??
              decoded[fallbackLang] as String? ??
              value;
        } else {
          return value;
        }
      } catch (_) {
        // Not a JSON string, use as is
        return value;
      }
    } else if (value is Map<String, dynamic>) {
      // Already a Map
      return value[currentLang] as String? ??
          value[fallbackLang] as String? ??
          value.toString();
    }

    return value.toString();
  }

  CompanyServiceModel copyWith({
    String? id,
    List<dynamic>? companyIds,
    String? serviceId,
    String? serviceName,
    double? minPrice,
    double? maxPrice,
    int? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyServiceModel(
      id: id ?? this.id,
      companyIds: companyIds ?? this.companyIds,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper: Fiyat gösterimi için
  String get priceDisplay {
    if (maxPrice != null && maxPrice! > minPrice) {
      return '₺${minPrice.toStringAsFixed(0)} - ₺${maxPrice!.toStringAsFixed(0)}';
    }
    return '₺${minPrice.toStringAsFixed(0)}';
  }

  // Helper: Süre gösterimi için
  String get durationDisplay {
    return '$duration dakika';
  }

  // Helper: Tek fiyat mı fiyat aralığı mı?
  bool get isSinglePrice => maxPrice == null || maxPrice == minPrice;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CompanyServiceModel(id: $id, serviceId: $serviceId, companies: ${companyIds.length})';
}
