import '../../core/services/locale_service.dart';

class ExtraFeatureModel {
  final int id;
  final String name; // Türkçe isim (default)
  final String? nameEn; // İngilizce isim (optional)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExtraFeatureModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.createdAt,
    this.updatedAt,
  });

  factory ExtraFeatureModel.fromJson(Map<String, dynamic> json) {
    // Backend: name: {"tr": "...", "en": "..."} veya String encoded JSON
    String parsedName = '';
    String? parsedNameEn;

    if (json['name'] is Map<String, dynamic>) {
      // Direkt Map ise
      final nameMap = json['name'] as Map<String, dynamic>;
      parsedName = nameMap['tr']?.toString() ?? '';
      parsedNameEn = nameMap['en']?.toString();
    } else if (json['name'] is String) {
      // String ise, JSON parse etmeyi dene
      final nameString = json['name'] as String;

      // JSON string mı kontrol et: {"tr":"...","en":"..."}
      if (nameString.trim().startsWith('{') &&
          nameString.trim().endsWith('}')) {
        try {
          // Basit JSON parse (dart:convert kullanmadan)
          final trMatch = RegExp(
            r'"tr"\s*:\s*"([^"]*)"',
          ).firstMatch(nameString);
          final enMatch = RegExp(
            r'"en"\s*:\s*"([^"]*)"',
          ).firstMatch(nameString);

          parsedName = trMatch?.group(1) ?? '';
          parsedNameEn = enMatch?.group(1);
        } catch (e) {
          // Parse edilemezse direkt kullan
          parsedName = nameString;
        }
      } else {
        // Normal string ise direkt kullan
        parsedName = nameString;
      }
    }

    return ExtraFeatureModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: parsedName,
      nameEn: parsedNameEn,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  // Aktif dile göre doğru ismi döndür
  String get displayName {
    final localeService = LocaleService();
    if (localeService.currentLanguageCode == 'en' &&
        nameEn != null &&
        nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return name;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': {
        'tr': name,
        if (nameEn != null && nameEn!.isNotEmpty) 'en': nameEn,
      },
    };
  }

  @override
  String toString() => 'ExtraFeatureModel(id: $id, name: $displayName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExtraFeatureModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
