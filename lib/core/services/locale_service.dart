import 'package:flutter/material.dart';
import 'settings_service.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  final SettingsService _settingsService = SettingsService();

  Locale _currentLocale = const Locale('tr', 'TR');
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _settingsService.initialize();
    final savedLanguage = await _settingsService.getAppLanguage();
    _currentLocale = _parseLocale(savedLanguage);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = _parseLocale(languageCode);
    await _settingsService.setAppLanguage(languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLanguage = _currentLocale.languageCode == 'tr' ? 'en' : 'tr';
    await setLanguage(newLanguage);
  }

  bool get isTurkish => _currentLocale.languageCode == 'tr';
  bool get isEnglish => _currentLocale.languageCode == 'en';

  Locale _parseLocale(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'tr':
      default:
        return const Locale('tr', 'TR');
    }
  }

  // Language display names
  String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'tr':
      default:
        return 'Türkçe';
    }
  }

  // Available languages
  List<Map<String, String>> get availableLanguages => [
        {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
        {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      ];
}
