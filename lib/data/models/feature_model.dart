import 'dart:convert';
import '../../core/services/locale_service.dart';

class FeatureModel {
  final String id;
  final String name;
  final String? icon;
  final bool isActive;

  const FeatureModel({
    required this.id,
    required this.name,
    this.icon,
    this.isActive = true,
  });

  factory FeatureModel.fromJson(Map<String, dynamic> json) {
    final extractedName = _extractName(json);
    return FeatureModel(
      id: json['id']?.toString() ?? '',
      name: extractedName,
      icon: json['icon']?.toString(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'isActive': isActive};
  }

  static String _extractName(Map<String, dynamic> json) {
    final localeService = LocaleService();
    final currentLang = localeService.currentLanguageCode;
    final fallbackLang = currentLang == 'tr' ? 'en' : 'tr';

    // Backend'den gelen name field'ını kontrol et
    if (json['name'] is String) {
      final nameString = json['name'] as String;

      // Eğer string JSON formatındaysa parse et
      if (nameString.startsWith('{') && nameString.contains('"')) {
        try {
          final decoded = jsonDecode(nameString);
          if (decoded is Map<String, dynamic>) {
            final currentLangName = decoded[currentLang]?.toString();
            final fallbackLangName = decoded[fallbackLang]?.toString();

            if (currentLangName != null && currentLangName.isNotEmpty) {
              return currentLangName;
            } else if (fallbackLangName != null &&
                fallbackLangName.isNotEmpty) {
              return fallbackLangName;
            }
          }
        } catch (e) {
          // JSON parse hatası durumunda orijinal string'i döndür
        }
      }

      return nameString;
    }

    // Nested name structure (tr/en) - Backend formatı: {"tr":"Özellik 1","en":"Feature 1"}
    if (json['name'] is Map<String, dynamic>) {
      final nameMap = json['name'] as Map<String, dynamic>;

      final currentLangName = nameMap[currentLang]?.toString();
      final fallbackLangName = nameMap[fallbackLang]?.toString();

      if (currentLangName != null && currentLangName.isNotEmpty) {
        return currentLangName;
      } else if (fallbackLangName != null && fallbackLangName.isNotEmpty) {
        return fallbackLangName;
      }
      return currentLang == 'tr' ? 'Bilinmeyen Özellik' : 'Unknown Feature';
    }

    // title field'ını kontrol et
    if (json['title'] is String) {
      return json['title'] as String;
    }

    // featureName field'ını kontrol et
    if (json['featureName'] is String) {
      return json['featureName'] as String;
    }

    return json['name']?.toString() ??
        (currentLang == 'tr' ? 'Bilinmeyen Özellik' : 'Unknown Feature');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeatureModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    // Sadece name döndür - Bu UI'da gösterilecek
    return name;
  }

  // Debug amaçlı detaylı string
  String toDebugString() {
    return 'FeatureModel(id: $id, name: $name, icon: $icon, isActive: $isActive)';
  }

  // Kopya oluşturma metodu (ihtiyaç duyarsanız)
  FeatureModel copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isActive,
  }) {
    return FeatureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
    );
  }
}
