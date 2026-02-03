import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/services/push_notification_service.dart';
import '../../core/services/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

/// AuthRepositoryImpl - Manages authentication state
/// 
/// Singleton pattern ensures consistent auth state across the app
class AuthRepositoryImpl implements AuthRepository {
  static final AuthRepositoryImpl _instance = AuthRepositoryImpl._internal();
  factory AuthRepositoryImpl() => _instance;
  AuthRepositoryImpl._internal();

  User? _currentUser;
  bool _isLoggedOut = false;
  DateTime? _lastLoginTime;
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  final AuthApiService _authApiService = AuthApiService();
  
  // Grace period after login where token expiration is ignored
  // This prevents race conditions where API calls happen before token is fully propagated
  // Set to 60 seconds to account for slow networks and multiple API calls on login
  static const Duration _loginGracePeriod = Duration(seconds: 60);
  
  // Flag to indicate auth is in progress (login/register)
  // Prevents race conditions where session expiration clears tokens during auth
  static bool _isAuthInProgress = false;
  
  /// Set auth in progress flag - call before starting auth operations
  static void setAuthInProgress(bool value) {
    _isAuthInProgress = value;
    if (kDebugMode) {
      debugPrint('AuthRepo: Auth in progress: $value');
    }
  }
  
  /// Check if auth is in progress
  static bool get isAuthInProgress => _isAuthInProgress;

  @override
  Future<User?> getCurrentUser() async {
    // If user explicitly logged out, return null
    if (_isLoggedOut) {
      if (kDebugMode) {
        debugPrint('AuthRepo: User is logged out');
      }
      return null;
    }

    // Return cached user if available
    if (_currentUser != null) {
      if (kDebugMode) {
        debugPrint('AuthRepo: Returning cached user: ${_currentUser!.name}');
      }
      return _currentUser;
    }

    // Try to load user from storage
    try {
      final userJson = await _authApiService.getUserJson();
      
      if (userJson != null && userJson.isNotEmpty) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap).toEntity();
        _currentUser = user;
        
        if (kDebugMode) {
          debugPrint('AuthRepo: Loaded user from storage: ${user.name}');
        }
        return user;
      }
      
      if (kDebugMode) {
        debugPrint('AuthRepo: No user in storage');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthRepo: Error loading user: $e');
      }
      return null;
    }
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    throw Exception('Email login not supported. Please use phone login.');
  }

  @override
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    throw Exception('Please use phone-based registration methods.');
  }

  Future<User> signInWithPhone({
    required String phoneCode,
    required String phone,
    required String password,
  }) async {
    AuthRepositoryImpl.setAuthInProgress(true);
    try {
      final deviceToken = await _getDeviceToken();
      final user = await _authApiService.login(
        phoneCode: phoneCode,
        phone: phone,
        password: password,
        deviceToken: deviceToken,
      );

      _setCurrentUser(user);
      return user;
    } finally {
      AuthRepositoryImpl.setAuthInProgress(false);
    }
  }

  Future<User> customerRegister({
    required String name,
    required String surname,
    required String email,
    required String phoneCode,
    required String phone,
    required String password,
    required String gender,
    String? referenceNumber,
  }) async {
    AuthRepositoryImpl.setAuthInProgress(true);
    try {
      final deviceToken = await _getDeviceToken();
      final user = await _authApiService.customerRegister(
        name: name,
        surname: surname,
        email: email,
        phoneCode: phoneCode,
        phone: phone,
        password: password,
        gender: gender,
        deviceToken: deviceToken,
        referenceNumber: referenceNumber,
      );

      _setCurrentUser(user);
      return user;
    } finally {
      AuthRepositoryImpl.setAuthInProgress(false);
    }
  }

  Future<User> companyRegister({
    required String name,
    required String surname,
    required String email,
    required String phoneCode,
    required String phone,
    required String password,
    required String gender,
    required String companyName,
    required int companyType,
    required String companyAddress,
    required String companyPhoneCode,
    required String companyPhone,
    required String companyEmail,
    double? companyLatitude,
    double? companyLongitude,
    required int countryId,
    required int cityId,
    required int stateId,
    required String iban,
    required String taxNumber,
    File? taxPlate,
    File? masterCertificate,
    String? deviceToken,
    String? paidTypes,
    String? referenceNumber,
  }) async {
    AuthRepositoryImpl.setAuthInProgress(true);
    try {
      final resolvedDeviceToken = deviceToken ?? await _getDeviceToken();
      final user = await _authApiService.companyRegister(
        name: name,
        surname: surname,
        email: email,
        phoneCode: phoneCode,
        phone: phone,
        password: password,
        gender: gender,
        companyName: companyName,
        companyType: companyType,
        companyAddress: companyAddress,
        companyPhoneCode: companyPhoneCode,
        companyPhone: companyPhone,
        companyEmail: companyEmail,
        companyLatitude: companyLatitude,
        companyLongitude: companyLongitude,
        countryId: countryId,
        cityId: cityId,
        stateId: stateId,
        iban: iban,
        taxNumber: taxNumber,
        taxPlate: taxPlate,
        masterCertificate: masterCertificate,
        deviceToken: resolvedDeviceToken,
        paidTypes: paidTypes,
        referenceNumber: referenceNumber,
      );

      _setCurrentUser(user);
      return user;
    } finally {
      AuthRepositoryImpl.setAuthInProgress(false);
    }
  }

  Future<void> sendSms({
    required String phoneCode,
    required String phone,
  }) async {
    await _authApiService.sendSms(phoneCode: phoneCode, phone: phone);
  }

  Future<User> verifySmsCode({
    required String phoneCode,
    required String phone,
    required String smsCode,
    String? name,
    String? surname,
    String? email,
    String? gender,
    String? companyName,
    String? companyType,
    String? companyAddress,
    String? companyPhoneCode,
    String? companyPhone,
    String? companyEmail,
    bool isCompanyRegistration = false,
  }) async {
    AuthRepositoryImpl.setAuthInProgress(true);
    try {
      final user = await _authApiService.checkSmsCode(
        phoneCode: phoneCode,
        phone: phone,
        smsCode: smsCode,
        name: name,
        surname: surname,
        email: email,
        gender: gender,
        companyName: companyName,
        companyType: companyType,
        companyAddress: companyAddress,
        companyPhoneCode: companyPhoneCode,
        companyPhone: companyPhone,
        companyEmail: companyEmail,
        isCompanyRegistration: isCompanyRegistration,
      );

      _setCurrentUser(user);
      return user;
    } finally {
      AuthRepositoryImpl.setAuthInProgress(false);
    }
  }

  Future<User> signInWithGoogle({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? avatar,
  }) async {
    AuthRepositoryImpl.setAuthInProgress(true);
    try {
      var deviceToken = await _getDeviceToken();
      deviceToken ??= await PushNotificationService().getDeviceToken(forceRefresh: true);
      
      if (deviceToken == null || deviceToken.isEmpty) {
        throw Exception('Bildirim izni gerekli. Lütfen bildirimlere izin verdikten sonra tekrar deneyin.');
      }
      
      final user = await _authApiService.googleRegister(
        idToken: idToken,
        accessToken: accessToken,
        email: email,
        name: name,
        avatar: avatar,
        deviceToken: deviceToken,
      );

      _setCurrentUser(user);
      return user;
    } finally {
      AuthRepositoryImpl.setAuthInProgress(false);
    }
  }

  Future<User> signInWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? name,
  }) async {
    AuthRepositoryImpl.setAuthInProgress(true);
    try {
      var deviceToken = await _getDeviceToken();
      deviceToken ??= await PushNotificationService().getDeviceToken(forceRefresh: true);
      
      if (deviceToken == null || deviceToken.isEmpty) {
        throw Exception('Bildirim izni gerekli. Lütfen bildirimlere izin verdikten sonra tekrar deneyin.');
      }
      
      final user = await _authApiService.appleRegister(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: email,
        name: name,
        deviceToken: deviceToken,
      );

      _setCurrentUser(user);
      return user;
    } finally {
      AuthRepositoryImpl.setAuthInProgress(false);
    }
  }

  @override
  Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('AuthRepo: Signing out');
    }
    
    try {
      await _authApiService.logout();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthRepo: Logout API error (ignored): $e');
      }
    }
    
    _clearCurrentUser();
  }

  @override
  Future<void> resetPassword(String email) async {
    throw Exception('Password reset not implemented yet.');
  }

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> forgotPasswordRequest({
    required String phoneCode,
    required String phone,
  }) async {
    await _authApiService.forgotPasswordRequest(phoneCode: phoneCode, phone: phone);
  }

  @override
  Future<void> forgotPasswordVerify({
    required String phoneCode,
    required String phone,
    required String smsCode,
  }) async {
    await _authApiService.forgotPasswordVerify(
      phoneCode: phoneCode,
      phone: phone,
      smsCode: smsCode,
    );
  }

  @override
  Future<void> forgotPasswordReset({
    required String phoneCode,
    required String phone,
    required String smsCode,
    required String password,
  }) async {
    await _authApiService.forgotPasswordReset(
      phoneCode: phoneCode,
      phone: phone,
      smsCode: smsCode,
      password: password,
    );
  }

  /// Called when token expires - clears user and notifies listeners
  /// 
  /// This is protected by a grace period after login to prevent race conditions
  void handleTokenExpiration() {
    // Check if we're within the login grace period
    if (_lastLoginTime != null) {
      final timeSinceLogin = DateTime.now().difference(_lastLoginTime!);
      if (timeSinceLogin < _loginGracePeriod) {
        if (kDebugMode) {
          debugPrint('AuthRepo: Ignoring token expiration - within grace period (${timeSinceLogin.inSeconds}s since login)');
        }
        return;
      }
    }
    
    // Only clear if we actually have a user
    if (_currentUser == null && _isLoggedOut) {
      if (kDebugMode) {
        debugPrint('AuthRepo: Ignoring token expiration - already logged out');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('AuthRepo: Token expired - clearing user');
    }
    _clearCurrentUser();
  }

  /// Check if we're within the login grace period
  /// Returns true if user logged in within the last 60 seconds
  bool isWithinGracePeriod() {
    if (_lastLoginTime == null) return false;
    final timeSinceLogin = DateTime.now().difference(_lastLoginTime!);
    return timeSinceLogin < _loginGracePeriod;
  }

  // Private helpers
  
  void _setCurrentUser(User user) {
    if (kDebugMode) {
      debugPrint('AuthRepo: Setting current user: ${user.name}');
    }
    _currentUser = user;
    _isLoggedOut = false;
    _lastLoginTime = DateTime.now();
    _authStateController.add(user);
  }

  void _clearCurrentUser() {
    if (kDebugMode) {
      debugPrint('AuthRepo: Clearing current user');
    }
    _currentUser = null;
    _isLoggedOut = true;
    _lastLoginTime = null;
    _authStateController.add(null);
  }

  Future<String?> _getDeviceToken() async {
    try {
      var token = await PushNotificationService().getCachedToken();

      if (token == null || token.isEmpty) {
        await PushNotificationService().initialize();
        token = await PushNotificationService().getDeviceToken();
      }

      if (token == null || token.isEmpty) {
        token = await PushNotificationService().getDeviceToken(forceRefresh: true);
      }

      if (token == null || token.isEmpty) {
        token = await _waitForDeviceToken();
      }

      return (token != null && token.isNotEmpty) ? token : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthRepo: Device token error: $e');
      }
      return null;
    }
  }

  Future<String?> _waitForDeviceToken({Duration timeout = const Duration(seconds: 3)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final cached = await PushNotificationService().getCachedToken();
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  void dispose() {
    _authStateController.close();
  }
}
