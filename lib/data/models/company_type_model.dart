import 'dart:convert';
import '../../core/services/locale_service.dart';

class CompanyTypeModel {
  final String id;
  final String name;
  final String? description;
  // Backend görsel alanı (admin panel: picture veya imageUrl olarak gelebilir)
  final String? imageUrl;

  const CompanyTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
  });

  factory CompanyTypeModel.fromJson(Map<String, dynamic> json) {
    final localeService = LocaleService();
    final currentLang = localeService.currentLanguageCode;
    final fallbackLang = currentLang == 'tr' ? 'en' : 'tr';

    String parsedName = '';
    dynamic nameValue = json['name'] ?? json['company_type'] ?? json['type'];

    if (nameValue is String) {
      // Check if the string is a JSON object
      try {
        final decodedName = jsonDecode(nameValue);
        if (decodedName is Map<String, dynamic>) {
          // Aktif dil, fallback dil, son olarak orijinal string
          parsedName = decodedName[currentLang] as String? ??
              decodedName[fallbackLang] as String? ??
              nameValue;
        } else {
          parsedName = nameValue;
        }
      } catch (_) {
        // Not a JSON string, use as is
        parsedName = nameValue;
      }
    } else {
      parsedName = nameValue?.toString() ?? '';
    }

    return CompanyTypeModel(
      id: json['id']?.toString() ?? '',
      name: parsedName,
      description: json['description'] as String?,
      imageUrl: (json['picture'] ?? json['imageUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  String toString() => name;

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http')) return imageUrl;
    const baseUrl = 'https://api.mandw.com.tr';
    final path = imageUrl!.startsWith('/') ? imageUrl! : '/$imageUrl';
    return '$baseUrl$path';
  }
}
