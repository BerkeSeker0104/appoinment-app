import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../core/services/locale_service.dart';

class BranchModel {
  final String id;
  final String name;
  final String type;
  final String? typeId; // Kategori ID'si - filtreleme için gerekli
  final String address;
  final String phone;
  final String email;
  final String status; // active, inactive
  final String? image; // Profil görseli
  final List<String>? interiorImages; // İç görseller (YENİ)
  final List<int>?
      interiorImageIds; // İç görsellerin ID'leri (backend update için)
  final double? latitude;
  final double? longitude;
  final int? countryId; // YENİ
  final int? cityId; // YENİ
  final int? stateId; // YENİ
  final String? companyId; // Ana şirket ID'si - YENİ (UUID string)
  final double? averageRating; // Ortalama puan
  final int? totalReviews; // Toplam yorum sayısı
  final Map<String, String> workingHours;
  final List<String> services;
  final List<int>? featureIds; // Backend'den gelen özellik ID'leri
  final String? paidTypes; // YENİ - virgülle ayrılmış string
  final bool isMain; // Whether this is the main branch
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? followerCount;

  const BranchModel({
    required this.id,
    required this.name,
    required this.type,
    this.typeId, // Kategori ID'si - filtreleme için gerekli
    required this.address,
    required this.phone,
    required this.email,
    required this.status,
    this.image,
    this.interiorImages, // YENİ
    this.interiorImageIds,
    this.latitude,
    this.longitude,
    this.countryId, // YENİ
    this.cityId, // YENİ
    this.stateId, // YENİ
    this.companyId, // Ana şirket ID'si - YENİ
    this.averageRating, // Ortalama puan
    this.totalReviews, // Toplam yorum sayısı
    required this.workingHours,
    required this.services,
    this.featureIds, // Backend'den gelen özellik ID'leri
    this.paidTypes, // YENİ
    this.isMain = false,
    required this.createdAt,
    required this.updatedAt,
    this.followerCount,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final parsedModel = BranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: _parseType(json),
      typeId: _parseTypeId(json),
      address: json['address'] ?? '',
      phone: _parsePhone(json),
      email: json['email'] ?? '',
      status: json['status'] ?? 'active',
      image: _parseImageUrl(json['picture'] ?? json['image']),
      interiorImages: _parseInteriorImages(
        json['pictures'] ?? json['interior_images'],
      ), // YENİ
      interiorImageIds: _parseInteriorImageIds(
        json['pictures'] ?? json['interior_images'],
      ),
      latitude: _parseCoordinate(json['lat'] ?? json['latitude']),
      longitude: _parseCoordinate(json['lng'] ?? json['longitude']),
      countryId: json['countryId'] ?? json['country_id'], // YENİ
      cityId: json['cityId'] ?? json['city_id'], // YENİ
      stateId: json['stateId'] ?? json['state_id'], // YENİ
      companyId: (json['companyId'] ?? json['company_id'])
          ?.toString(), // Ana şirket ID'si - YENİ (String'e çevir)
      workingHours: _parseWorkingHours(
        json['hours'] ?? json['working_hours'],
        isAlwaysOpen: json['isAlwaysOpen'],
      ),
      services: _parseServicesFromFeatures(
        json['features'] ?? json['services'],
      ),
      featureIds: _parseFeatureIdsFromFeatures(
        json['features'] ?? json['services'],
      ), // Backend'den gelen özellik ID'leri
      paidTypes:
          _parsePaidTypes(json['paidTypes'] ?? json['paid_types']), // YENİ
      averageRating: _parseRating(json), // Rating'i daha esnek parse et
      totalReviews: _parseInt(json['totalReviews'] ?? json['total_reviews']),
      isMain: json['isMain'] == 1 ||
          json['isMain'] == true ||
          json['isMain'] == '1',
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
              DateTime.now(),
      followerCount: _parseInt(json['followerCount'] ?? json['follower_count']),
    );

    return parsedModel;
  }

  Map<String, dynamic> toJson({bool includeCoordinates = true}) {
    // Backend format - Postman'den gelen format
    final json = <String, dynamic>{
      'name': name,
      'address': address,
      'email': email,
    };

    // Phone ve phoneCode'u ayır
    if (phone.isNotEmpty) {
      // Eğer telefon 90 ile başlıyorsa ayır, değilse direkt gönder
      if (phone.startsWith('90') && phone.length > 10) {
        json['phoneCode'] = '90';
        json['phone'] = phone.substring(2);
      } else if (phone.startsWith('+90')) {
        json['phoneCode'] = '90';
        json['phone'] = phone.substring(3);
      } else {
        json['phoneCode'] = '90'; // Default
        json['phone'] = phone;
      }
    }

    // Koordinatlar - String olarak gönder (form-data uyumlu)
    if (includeCoordinates) {
      if (latitude != null) json['lat'] = latitude.toString();
      if (longitude != null) json['lng'] = longitude.toString();
    }

    // Location IDs - YENİ
    if (countryId != null) json['countryId'] = countryId.toString();
    if (cityId != null) json['cityId'] = cityId.toString();
    if (stateId != null) json['stateId'] = stateId.toString();

    // Backend JWT token'dan user bilgisini otomatik alıyor, manuel göndermeye gerek yok

    // Type ID - backend typeId bekliyor (string olarak gönder, backend parse eder)
    if (type.isNotEmpty) {
      json['typeId'] = type;
    }

    // Picture - Backend path bekliyor, URL değil
    if (image != null && image!.isNotEmpty) {
      // Eğer tam URL ise path'e çevir
      String pictureValue = image!;
      if (pictureValue.startsWith('http://') ||
          pictureValue.startsWith('https://')) {
        // URL'den path'i çıkar: https://api.mandw.com.tr/uploads/... -> /uploads/...
        final uri = Uri.parse(pictureValue);
        pictureValue = uri.path;
      }
      json['picture'] = pictureValue;
    }

    // Working hours - backend hours array bekliyor
    if (workingHours.isNotEmpty) {
      // Önce 7/24 açık kontrolü yap
      final isAlwaysOpen =
          workingHours.containsKey('all') && workingHours['all'] == '7/24 Açık';

      final hoursList = <Map<String, dynamic>>[];
      final dayMap = {
        'monday': 0,
        'tuesday': 1,
        'wednesday': 2,
        'thursday': 3,
        'friday': 4,
        'saturday': 5,
        'sunday': 6,
      };

      if (isAlwaysOpen) {
        // Backend string format bekliyor: "1" veya "0"
        json['isAlwaysOpen'] = "1";
        // 7/24 açık için tüm günleri isAlwaysOpen:1 ile ekle
        dayMap.forEach((_, dayOfWeek) {
          hoursList.add(_buildHoursPayload(
            dayOfWeek: dayOfWeek,
            openTime: '00:00',
            closeTime: '00:00',
            isAlwaysOpen: true,
          ));
        });
      } else {
        json['isAlwaysOpen'] = "0";

        // Backend 7 gün için ayrı ayrı obje bekliyor (0-6 index)
        // Postman formatı: hours[0][day], hours[0][openTime], hours[0][closeTime], etc.
        // Eksik günleri default değerlerle doldur
        for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
          final dayName = dayMap.keys.firstWhere(
            (key) => dayMap[key] == dayOfWeek,
            orElse: () => 'monday',
          );

          final hours = workingHours[dayName];
          if (hours != null) {
            final isClosed = hours.toLowerCase() == 'kapalı' ||
                hours.toLowerCase() == 'closed';

            if (isClosed) {
              hoursList.add(_buildHoursPayload(
                dayOfWeek: dayOfWeek,
                openTime: '00:00',
                closeTime: '00:00',
                isClosed: true,
              ));
            } else {
              // Parse "09:00 - 18:00" formatı
              // Hem " - " hem de "-" ile ayrılmış formatları destekle
              String normalizedHours = hours.trim();
              List<String> parts;

              if (normalizedHours.contains(' - ')) {
                parts = normalizedHours.split(' - ');
              } else if (normalizedHours.contains('-')) {
                parts = normalizedHours.split('-');
              } else {
                // Format tanınmıyorsa default değerler kullan
                parts = ['09:00', '18:00'];
              }

              hoursList.add(_buildHoursPayload(
                dayOfWeek: dayOfWeek,
                openTime: parts.isNotEmpty ? parts[0].trim() : '09:00',
                closeTime: parts.length > 1 ? parts[1].trim() : '18:00',
              ));
            }
          } else {
            // Eksik gün için default değer
            hoursList.add(_buildHoursPayload(
              dayOfWeek: dayOfWeek,
              openTime: '09:00',
              closeTime: '18:00',
            ));
          }
        }
      }

      json['hours'] = hoursList;
    } else {
      json['isAlwaysOpen'] = "0";
      final hoursList = <Map<String, dynamic>>[];
      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
        hoursList.add(_buildHoursPayload(
            dayOfWeek: dayOfWeek, openTime: '09:00', closeTime: '18:00'));
      }
      json['hours'] = hoursList;
    }

    // Features - Backend feature ID array bekliyor
    // Postman'de features[] array formatında gönderiliyor
    if (featureIds != null && featureIds!.isNotEmpty) {
      json['features'] = featureIds!;
    } else {
      json['features'] = <int>[];
    }

    return json;
  }

  static Map<String, dynamic> _buildHoursPayload({
    required int dayOfWeek,
    required String openTime,
    required String closeTime,
    bool isClosed = false,
    bool isAlwaysOpen = false,
  }) {
    // Backend dayOfWeek'i int olarak bekliyor, ancak FormData string'e çevirir
    // Bu yüzden string olarak gönderiyoruz, backend parse eder
    return {
      'dayOfWeek': dayOfWeek.toString(),
      'openTime': openTime,
      'closeTime': closeTime,
      'isClosed': isClosed ? "1" : "0",
      'isAlwaysOpen': isAlwaysOpen ? "1" : "0",
    };
  }

  static String _parseType(Map<String, dynamic> json) {
    // Backend sends: typeId (int) and type (object with id and name)
    // Extract the type name for description
    if (json['type'] is Map<String, dynamic>) {
      final typeMap = json['type'] as Map<String, dynamic>;
      if (typeMap['name'] is String) {
        // Parse multi-language string: "{\"tr\":\"Tip 422\",\"en\":\"Type 4\"}"
        return _parseMultiLangString(typeMap['name']);
      }
      return typeMap['name']?.toString() ?? '';
    }
    if (json['type'] is String) {
      return json['type'];
    }
    if (json['typeId'] != null) {
      // Fallback to typeId if no type name available
      return 'Tip ${json['typeId']}';
    }
    if (json['branch_type'] != null) {
      return json['branch_type'].toString();
    }
    return '';
  }

  static String? _parseTypeId(Map<String, dynamic> json) {
    // Backend sends: typeId (int) and type (object with id and name)
    // Extract the type ID for filtering
    if (json['typeId'] != null) {
      return json['typeId'].toString();
    }
    if (json['type'] is Map<String, dynamic>) {
      final typeMap = json['type'] as Map<String, dynamic>;
      if (typeMap['id'] != null) {
        return typeMap['id'].toString();
      }
    }
    return null;
  }

  static String _parsePhone(Map<String, dynamic> json) {
    // Backend sends: phoneCode and phone separately
    final phoneCode = json['phoneCode']?.toString() ?? '';
    final phone = json['phone']?.toString() ?? '';

    if (phoneCode.isNotEmpty && phone.isNotEmpty) {
      return phoneCode + phone;
    }
    return phone;
  }

  static double? _parseCoordinate(dynamic value) {
    // Safely parse coordinates that can be String or num
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static String? _parseImageUrl(dynamic value) {
    // Backend'den gelen resim path'ini tam URL'e çevir
    if (value == null) return null;
    final imagePath = value.toString();
    if (imagePath.isEmpty) return null;

    // Eğer zaten tam URL ise (http/https ile başlıyorsa) direkt döndür
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Relative path ise base URL ekle
    const baseUrl = ApiConstants.fileUrl;
    // Path / ile başlamıyorsa ekle
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$baseUrl$path';
  }

  static String? _parsePaidTypes(dynamic paidTypes) {
    if (paidTypes == null) return null;

    if (paidTypes is String) {
      // String formatında geliyorsa, array bracket'larını temizle
      String cleaned =
          paidTypes.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
      return cleaned.isEmpty ? null : cleaned;
    } else if (paidTypes is List) {
      // Array formatından string formatına çevir
      return paidTypes.map((e) => e.toString()).join(',');
    }

    return null;
  }

  static List<String>? _parseInteriorImages(dynamic value) {
    // Backend'den gelen iç görseller listesini parse et
    // Backend format: [{"id": 5, "picture": "/uploads/...", "order": 0}, ...]
    if (value == null) return null;

    if (value is List) {
      if (value.isEmpty) return null;

      final List<Map<String, dynamic>> pictureObjects = [];

      // Object array'i parse et
      for (var item in value) {
        if (item is Map<String, dynamic>) {
          pictureObjects.add(item);
        } else if (item is String) {
          // String ise direkt kullan (backward compatibility)
          final imageUrl = _parseImageUrl(item);
          if (imageUrl != null) {
            return [imageUrl];
          }
        }
      }

      // Order'a göre sırala
      pictureObjects.sort((a, b) {
        final orderA = a['order'] ?? 0;
        final orderB = b['order'] ?? 0;
        return orderA.compareTo(orderB);
      });

      // Picture URL'lerini çıkar
      final List<String> images = [];
      for (var obj in pictureObjects) {
        final pictureUrl = _parseImageUrl(obj['picture']);
        if (pictureUrl != null) {
          images.add(pictureUrl);
        }
      }

      return images.isNotEmpty ? images : null;
    }

    if (value is String && value.isNotEmpty) {
      final imageUrl = _parseImageUrl(value);
      return imageUrl != null ? [imageUrl] : null;
    }

    return null;
  }

  static List<int>? _parseInteriorImageIds(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      if (value.isEmpty) return null;

      final List<Map<String, dynamic>> pictureObjects = [];

      for (var item in value) {
        if (item is Map<String, dynamic>) {
          pictureObjects.add(item);
        } else if (item is int) {
          pictureObjects.add({'id': item});
        } else if (item is String) {
          pictureObjects.add({'id': int.tryParse(item)});
        }
      }

      pictureObjects.sort((a, b) {
        final orderA = a['order'] ?? 0;
        final orderB = b['order'] ?? 0;
        return orderA.compareTo(orderB);
      });

      final List<int> ids = [];
      for (final obj in pictureObjects) {
        final idValue = obj['id'];
        if (idValue is int) {
          ids.add(idValue);
        } else if (idValue is String) {
          final parsed = int.tryParse(idValue);
          if (parsed != null) ids.add(parsed);
        } else if (idValue is double) {
          ids.add(idValue.toInt());
        }
      }

      return ids.isNotEmpty ? ids : null;
    }

    return null;
  }

  static Map<String, String> _parseWorkingHours(
    dynamic workingHours, {
    dynamic isAlwaysOpen,
  }) {
    // Parent seviyede isAlwaysOpen kontrolü
    final parentIsAlwaysOpen =
        isAlwaysOpen == 1 || isAlwaysOpen == true || isAlwaysOpen == '1';

    if (parentIsAlwaysOpen) {
      return {'all': '7/24 Açık'};
    }

    // Backend sends hours as array: [{dayOfWeek: 0, openTime: "09:00:00", closeTime: "18:00:00", isClosed: false, isAlwaysOpen: false}]
    if (workingHours is List) {
      // Eğer hours array'i boşsa, default değerler döndür
      if (workingHours.isEmpty) {
        return {
          'monday': '09:00 - 18:00',
          'tuesday': '09:00 - 18:00',
          'wednesday': '09:00 - 18:00',
          'thursday': '09:00 - 18:00',
          'friday': '09:00 - 18:00',
          'saturday': '10:00 - 16:00',
          'sunday': 'Kapalı',
        };
      }

      final Map<String, String> hours = {};
      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ];

      // Tüm günlerin isAlwaysOpen olup olmadığını kontrol et
      bool allDaysAlwaysOpen = true;
      int validDaysCount = 0;

      // İlk döngü: Tüm günlerin isAlwaysOpen olup olmadığını kontrol et
      for (var hour in workingHours) {
        if (hour is Map<String, dynamic>) {
          int? dayOfWeekInt;
          final dayOfWeek = hour['dayOfWeek'];
          if (dayOfWeek is int) {
            dayOfWeekInt = dayOfWeek;
          } else if (dayOfWeek is String) {
            dayOfWeekInt = int.tryParse(dayOfWeek);
          } else if (dayOfWeek is double) {
            dayOfWeekInt = dayOfWeek.toInt();
          }

          if (dayOfWeekInt != null && dayOfWeekInt >= 0 && dayOfWeekInt < 7) {
            validDaysCount++;
            final hourIsAlwaysOpen = hour['isAlwaysOpen'] == 1 ||
                hour['isAlwaysOpen'] == true ||
                hour['isAlwaysOpen'] == '1' ||
                hour['isAlwaysOpen'] == 'true';

            if (!hourIsAlwaysOpen) {
              allDaysAlwaysOpen = false;
              break; // Bir gün bile isAlwaysOpen değilse, döngüden çık
            }
          }
        }
      }

      // Eğer tüm günler isAlwaysOpen ise, direkt döndür
      if (allDaysAlwaysOpen && validDaysCount > 0) {
        return {'all': '7/24 Açık'};
      }

      // Normal parse işlemi - tüm günleri parse et
      for (var hour in workingHours) {
        if (hour is Map<String, dynamic>) {
          // dayOfWeek'i parse et - int, string veya double olabilir
          int? dayOfWeekInt;
          final dayOfWeek = hour['dayOfWeek'];
          if (dayOfWeek is int) {
            dayOfWeekInt = dayOfWeek;
          } else if (dayOfWeek is String) {
            dayOfWeekInt = int.tryParse(dayOfWeek);
          } else if (dayOfWeek is double) {
            dayOfWeekInt = dayOfWeek.toInt();
          }

          if (dayOfWeekInt != null && dayOfWeekInt >= 0 && dayOfWeekInt < 7) {
            final dayName = dayNames[dayOfWeekInt];
            
            // Backend'den gelen isClosed boolean olarak gelebilir (false/true)
            final isClosed = hour['isClosed'] == 1 ||
                hour['isClosed'] == true ||
                hour['isClosed'] == '1' ||
                hour['isClosed'] == 'true';

            if (isClosed) {
              // Kapalı gün: isClosed: true, openTime: "00:00:00", closeTime: "00:00:00"
              hours[dayName] = 'Kapalı';
            } else {
              // Normal açık gün veya 7/24 açık gün
              // Backend'den gelen zaman formatı "09:00:00" (saniye dahil) olabilir
              final openTimeRaw = hour['openTime']?.toString() ?? '09:00';
              final closeTimeRaw = hour['closeTime']?.toString() ?? '18:00';
              
              // Eğer zamanlar "00:00:00" ve isClosed false ise, bu 7/24 açık olabilir
              // Ama yukarıda zaten kontrol edildi, burada sadece parse ediyoruz
              // Normal açık gün: isClosed: false, isAlwaysOpen: false, openTime: "09:00:00", closeTime: "18:00:00"
              final openTime = _normalizeTime(openTimeRaw);
              final closeTime = _normalizeTime(closeTimeRaw);
              hours[dayName] = '$openTime - $closeTime';
            }
          }
        }
      }

      // Eksik günler için default değerler ekle
      // Backend'den gelen array'de bazı günler eksik olabilir
      for (int i = 0; i < 7; i++) {
        final dayName = dayNames[i];
        if (!hours.containsKey(dayName)) {
          // Eksik gün için default değer (Pazar günü kapalı, diğerleri 09:00-18:00)
          if (i == 6) {
            hours[dayName] = 'Kapalı';
          } else {
            hours[dayName] = '09:00 - 18:00';
          }
        }
      }

      // Backend'den gelen veriler varsa direkt döndür
      // Böylece tüm günleri kapalı olan işletmeler de gösterilir
      // Eğer hours Map'i hala boşsa (ki bu olmamalı), default değerler döndür
      if (hours.isEmpty) {
        return {
          'monday': '09:00 - 18:00',
          'tuesday': '09:00 - 18:00',
          'wednesday': '09:00 - 18:00',
          'thursday': '09:00 - 18:00',
          'friday': '09:00 - 18:00',
          'saturday': '10:00 - 16:00',
          'sunday': 'Kapalı',
        };
      }
      return hours;
    }

    if (workingHours is Map<String, dynamic>) {
      return workingHours.map((key, value) => MapEntry(key, value.toString()));
    }
    if (workingHours is String) {
      try {
        final decoded = jsonDecode(workingHours);
        if (decoded is Map<String, dynamic>) {
          return decoded.map((key, value) => MapEntry(key, value.toString()));
        }
      } catch (_) {}
    }
    return {
      'monday': '09:00 - 18:00',
      'tuesday': '09:00 - 18:00',
      'wednesday': '09:00 - 18:00',
      'thursday': '09:00 - 18:00',
      'friday': '09:00 - 18:00',
      'saturday': '10:00 - 16:00',
      'sunday': 'Kapalı',
    };
  }

  static List<String> _parseServicesFromFeatures(dynamic features) {
    if (features is List) {
      final Set<String> uniqueFeatures = <String>{};
      final List<String> result = [];

      for (var feature in features) {
        String? featureName;

        if (feature is Map<String, dynamic>) {
          // API'den gelen features yapısı: {"companyId": 9, "featureId": 1, "feature": {"id": 1, "name": "{\"tr\":\"Özellik 1\",\"en\":\"Feature 1\"}"}}
          final featureData = feature['feature'];
          if (featureData is Map<String, dynamic>) {
            final name = featureData['name'];
            if (name is String) {
              // Multi-language string'i parse et: "{\"tr\":\"Özellik 1\",\"en\":\"Feature 1\"}"
              featureName = _parseMultiLangString(name);
            }
          }
          // Fallback: direkt string ise
          if (featureName == null) {
            featureName = feature.toString();
          }
        } else {
          featureName = feature.toString();
        }

        // Duplicate kontrolü - aynı isme sahip feature'ları tekrar ekleme
        if (featureName.isNotEmpty && !uniqueFeatures.contains(featureName)) {
          uniqueFeatures.add(featureName);
          result.add(featureName);
        }
      }

      return result;
    }
    return [];
  }

  static List<int>? _parseFeatureIdsFromFeatures(dynamic features) {
    if (features == null) {
      return null;
    }

    if (features is List) {
      final List<int> ids = [];

      for (var feature in features) {
        if (feature is Map<String, dynamic>) {
          int? featureId;

          if (feature['featureId'] != null) {
            final idValue = feature['featureId'];
            if (idValue is int) {
              featureId = idValue;
            } else if (idValue is String) {
              featureId = int.tryParse(idValue);
            } else if (idValue is double) {
              featureId = idValue.toInt();
            }
          }

          if (featureId == null) {
            final featureData = feature['feature'];
            if (featureData is Map<String, dynamic> &&
                featureData['id'] != null) {
              final idValue = featureData['id'];
              if (idValue is int) {
                featureId = idValue;
              } else if (idValue is String) {
                featureId = int.tryParse(idValue);
              } else if (idValue is double) {
                featureId = idValue.toInt();
              }
            }
          }

          if (featureId == null && feature['id'] != null) {
            final idValue = feature['id'];
            if (idValue is int) {
              featureId = idValue;
            } else if (idValue is String) {
              featureId = int.tryParse(idValue);
            } else if (idValue is double) {
              featureId = idValue.toInt();
            }
          }

          if (featureId != null && !ids.contains(featureId)) {
            ids.add(featureId);
          }
        } else if (feature is int) {
          if (!ids.contains(feature)) {
            ids.add(feature);
          }
        } else if (feature is String) {
          final parsedId = int.tryParse(feature);
          if (parsedId != null && !ids.contains(parsedId)) {
            ids.add(parsedId);
          }
        }
      }

      return ids;
    } else if (features is Map<String, dynamic>) {
      final idValue =
          features['featureId'] ?? features['id'] ?? features['feature']?['id'];
      if (idValue != null) {
        final id = idValue is int
            ? idValue
            : (idValue is String ? int.tryParse(idValue) : null);
        if (id != null) {
          return [id];
        }
      }
    }

    return null;
  }

  // Removed unused _parseServices function
  /*
  static List<String> _parseServices(dynamic services) {
    if (services is List) {
      return services.map((e) => _extractServiceName(e)).toList();
    }
    if (services is String) {
      try {
        final decoded = jsonDecode(services);
        if (decoded is List) {
          return decoded.map((e) => _extractServiceName(e)).toList();
        }
      } catch (e) {
        // JSON parse hatası durumunda boş liste döndür
      }
    }
    return [];
  }

  static String _extractServiceName(dynamic service) {
    if (service is String) {
      // Backend'den gelen JSON string formatını kontrol et
      if (service.startsWith('{') && service.contains('"tr"')) {
        try {
          final decoded = jsonDecode(service);
          if (decoded is Map<String, dynamic>) {
            return decoded['tr']?.toString() ??
                decoded['en']?.toString() ??
                'Bilinmeyen Hizmet';
          }
        } catch (e) {
          // JSON parse hatası durumunda orijinal string'i döndür
        }
      }
      return service;
    }

    if (service is Map<String, dynamic>) {
      // Check if it's a complex feature object with nested name structure
      if (service.containsKey('feature') &&
          service['feature'] is Map<String, dynamic>) {
        final feature = service['feature'] as Map<String, dynamic>;
        if (feature.containsKey('name')) {
          final name = feature['name'];
          if (name is Map<String, dynamic>) {
            return name['tr']?.toString() ??
                name['en']?.toString() ??
                'Bilinmeyen Hizmet';
          }
          return name.toString();
        }
      }

      // Check for direct name field
      if (service.containsKey('name')) {
        final name = service['name'];
        if (name is Map<String, dynamic>) {
          return name['tr']?.toString() ??
              name['en']?.toString() ??
              'Bilinmeyen Hizmet';
        }
        return name.toString();
      }

      // Check for featureName field
      if (service.containsKey('featureName')) {
        return service['featureName'].toString();
      }

      // Check for title field
      if (service.containsKey('title')) {
        return service['title'].toString();
      }
    }

    // Fallback to string representation
    return service.toString();
  }
  */

  BranchModel copyWith({
    String? id,
    String? name,
    String? type,
    String? typeId,
    String? address,
    String? phone,
    String? email,
    String? status,
    String? image,
    List<String>? interiorImages, // YENİ
    List<int>? interiorImageIds,
    double? latitude,
    double? longitude,
    int? countryId, // YENİ
    int? cityId, // YENİ
    int? stateId, // YENİ
    String? companyId, // YENİ
    double? averageRating, // YENİ
    int? totalReviews, // YENİ
    Map<String, String>? workingHours,
    List<String>? services,
    List<int>? featureIds, // Backend'den gelen özellik ID'leri
    String? paidTypes, // YENİ
    bool? isMain,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BranchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      typeId: typeId ?? this.typeId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      image: image ?? this.image,
      interiorImages: interiorImages ?? this.interiorImages, // YENİ
      interiorImageIds: interiorImageIds ?? this.interiorImageIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      countryId: countryId ?? this.countryId, // YENİ
      cityId: cityId ?? this.cityId, // YENİ
      stateId: stateId ?? this.stateId, // YENİ
      companyId: companyId ?? this.companyId, // YENİ
      averageRating: averageRating ?? this.averageRating, // YENİ
      totalReviews: totalReviews ?? this.totalReviews, // YENİ
      workingHours: workingHours ?? this.workingHours,
      services: services ?? this.services,
      featureIds:
          featureIds ?? this.featureIds, // Backend'den gelen özellik ID'leri
      paidTypes: paidTypes ?? this.paidTypes, // YENİ
      isMain: isMain ?? this.isMain,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'active';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BranchModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BranchModel(id: $id, name: $name, type: $type)';

  static String _parseMultiLangString(dynamic value) {
    if (value == null) return '';

    final localeService = LocaleService();
    final currentLang = localeService.currentLanguageCode;
    final fallbackLang = currentLang == 'tr' ? 'en' : 'tr';

    if (value is String) {
      // Check if the string is a JSON object
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          // Aktif dil, fallback dil, son olarak orijinal string
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

  /// Rating'i parse et - farklı key'leri kontrol et
  static double? _parseRating(Map<String, dynamic> json) {
    // Önce farklı key'leri kontrol et
    final ratingKeys = [
      'averageRating',
      'average_rating',
      'avgRating',
      'avg_rating',
      'rating',
      'score',
      'averageScore',
      'average_score',
    ];

    for (final key in ratingKeys) {
      if (json.containsKey(key)) {
        final value = json[key];
        if (value != null) {
          final parsed = _parseDouble(value);
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }
      }
    }

    // Eğer hiçbir key bulunamazsa null döndür
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Zaman formatını normalize et: "09:00:00" -> "09:00"
  static String _normalizeTime(String time) {
    if (time.isEmpty) return '09:00';
    
    // "09:00:00" veya "09:00" formatını destekle
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    }
    
    return time;
  }
}
