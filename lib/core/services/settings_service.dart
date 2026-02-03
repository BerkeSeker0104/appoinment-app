import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Settings keys
  static const String _notificationsAppointmentsKey =
      'notifications_appointments';
  static const String _notificationsPromotionsKey = 'notifications_promotions';
  static const String _notificationsEmailKey = 'notifications_email';
  static const String _appLanguageKey = 'app_language';
  static const String _permissionsRequestedKey = 'permissions_requested';

  // Default values
  static const bool _defaultNotificationsAppointments = true;
  static const bool _defaultNotificationsPromotions = true;
  static const bool _defaultNotificationsEmail = false;
  static const String _defaultAppLanguage = 'tr';
  static const bool _defaultPermissionsRequested = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Notification Settings
  Future<bool> getNotificationsAppointments() async {
    await _ensureInitialized();
    return _prefs!.getBool(_notificationsAppointmentsKey) ??
        _defaultNotificationsAppointments;
  }

  Future<void> setNotificationsAppointments(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_notificationsAppointmentsKey, value);
  }

  Future<bool> getNotificationsPromotions() async {
    await _ensureInitialized();
    return _prefs!.getBool(_notificationsPromotionsKey) ??
        _defaultNotificationsPromotions;
  }

  Future<void> setNotificationsPromotions(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_notificationsPromotionsKey, value);
  }

  Future<bool> getNotificationsEmail() async {
    await _ensureInitialized();
    return _prefs!.getBool(_notificationsEmailKey) ??
        _defaultNotificationsEmail;
  }

  Future<void> setNotificationsEmail(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_notificationsEmailKey, value);
  }

  // Language Settings
  Future<String> getAppLanguage() async {
    await _ensureInitialized();
    return _prefs!.getString(_appLanguageKey) ?? _defaultAppLanguage;
  }

  Future<void> setAppLanguage(String language) async {
    await _ensureInitialized();
    await _prefs!.setString(_appLanguageKey, language);
  }

  // Permission Settings
  Future<bool> getPermissionsRequested() async {
    await _ensureInitialized();
    return _prefs!.getBool(_permissionsRequestedKey) ??
        _defaultPermissionsRequested;
  }

  Future<void> setPermissionsRequested(bool value) async {
    await _ensureInitialized();
    await _prefs!.setBool(_permissionsRequestedKey, value);
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _ensureInitialized();
    await _prefs!.remove(_notificationsAppointmentsKey);
    await _prefs!.remove(_notificationsPromotionsKey);
    await _prefs!.remove(_notificationsEmailKey);
    await _prefs!.remove(_appLanguageKey);
    await _prefs!.remove(_permissionsRequestedKey);
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }
}
