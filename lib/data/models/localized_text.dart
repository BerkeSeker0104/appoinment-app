class LocalizedText {
  final String tr;
  final String en;

  const LocalizedText({
    required this.tr,
    this.en = '',
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      tr: json['tr'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tr': tr,
      'en': en,
    };
  }

  // Get text based on current locale (default to Turkish)
  String getText([String locale = 'tr']) {
    if (locale == 'en' && en.isNotEmpty) {
      return en;
    }
    return tr;
  }

  @override
  String toString() => tr;
}
