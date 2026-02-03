import 'dart:io';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCases {
  final AuthRepository _authRepository;

  AuthUseCases(this._authRepository);

  Future<User?> getCurrentUser() async {
    try {
      return await _authRepository.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<User> signIn({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    return await _authRepository.signInWithEmailAndPassword(email, password);
  }

  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('All fields are required');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    return await _authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      userType: userType,
    );
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      throw Exception('Email is required');
    }

    await _authRepository.resetPassword(email);
  }

  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  // Phone-based login
  Future<User> signInWithPhone({
    required String phoneCode,
    required String phone,
    required String password,
  }) async {
    if (phoneCode.isEmpty || phone.isEmpty || password.isEmpty) {
      throw Exception('Tüm alanlar gerekli');
    }

    return await (_authRepository as dynamic).signInWithPhone(
      phoneCode: phoneCode,
      phone: phone,
      password: password,
    );
  }

  // Customer registration
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
    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        phoneCode.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      throw Exception('Tüm alanlar gerekli');
    }

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalı');
    }

    return await (_authRepository as dynamic).customerRegister(
      name: name,
      surname: surname,
      email: email,
      phoneCode: phoneCode,
      phone: phone,
      password: password,
      gender: gender,
      referenceNumber: referenceNumber,
    );
  }

  // Company registration
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
    required int countryId, // YENİ
    required int cityId, // YENİ
    required int stateId, // YENİ
    required String iban, // YENİ
    required String taxNumber, // YENİ
    File? taxPlate, // YENİ
    File? masterCertificate,
    String? deviceToken, // OPSİYONEL
    String? paidTypes, // YENİ - virgülle ayrılmış string
    String? referenceNumber, // REFERANS KODU - opsiyonel
    // proQualification, idCardFront, idCardBack KALDIRILDI
  }) async {
    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        phoneCode.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        companyName.isEmpty ||
        companyType == 0 ||
        companyAddress.isEmpty ||
        companyPhoneCode.isEmpty ||
        companyPhone.isEmpty ||
        companyEmail.isEmpty ||
        iban.isEmpty ||
        taxNumber.isEmpty) {
      throw Exception('Tüm alanlar gerekli');
    }

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalı');
    }

    return await (_authRepository as dynamic).companyRegister(
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
      taxNumber: taxNumber, // YENİ
      taxPlate: taxPlate,
      masterCertificate: masterCertificate,
      deviceToken: deviceToken, // YENİ
      paidTypes: paidTypes, // YENİ
      referenceNumber: referenceNumber, // REFERANS KODU
    );
  }

  // SMS verification
  Future<void> sendSms({
    required String phoneCode,
    required String phone,
  }) async {
    if (phoneCode.isEmpty || phone.isEmpty) {
      throw Exception('Telefon bilgileri gerekli');
    }

    return await (_authRepository as dynamic).sendSms(
      phoneCode: phoneCode,
      phone: phone,
    );
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
    if (phoneCode.isEmpty || phone.isEmpty || smsCode.isEmpty) {
      throw Exception('Tüm alanlar gerekli');
    }

    return await (_authRepository as dynamic).verifySmsCode(
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
  }

  Future<User> googleSignIn({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? avatar,
  }) async {
    if (idToken.isEmpty) {
      throw Exception('Google oturum bilgisi alınamadı.');
    }

    return await (_authRepository as dynamic).signInWithGoogle(
      idToken: idToken,
      accessToken: accessToken,
      email: email,
      name: name,
      avatar: avatar,
    );
  }

  Future<User> appleSignIn({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? name,
  }) async {
    if (identityToken.isEmpty || authorizationCode.isEmpty) {
      throw Exception('Apple oturum bilgisi alınamadı.');
    }

    return await (_authRepository as dynamic).signInWithApple(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      email: email,
      name: name,
    );
  }

  // Forgot Password methods
  Future<void> forgotPasswordRequest({
    required String phoneCode,
    required String phone,
  }) async {
    if (phoneCode.isEmpty || phone.isEmpty) {
      throw Exception('Telefon bilgileri gerekli');
    }

    return await _authRepository.forgotPasswordRequest(
      phoneCode: phoneCode,
      phone: phone,
    );
  }

  Future<void> forgotPasswordVerify({
    required String phoneCode,
    required String phone,
    required String smsCode,
  }) async {
    if (phoneCode.isEmpty || phone.isEmpty || smsCode.isEmpty) {
      throw Exception('Tüm alanlar gerekli');
    }

    return await _authRepository.forgotPasswordVerify(
      phoneCode: phoneCode,
      phone: phone,
      smsCode: smsCode,
    );
  }

  Future<void> forgotPasswordReset({
    required String phoneCode,
    required String phone,
    required String smsCode,
    required String password,
  }) async {
    if (phoneCode.isEmpty || phone.isEmpty || smsCode.isEmpty || password.isEmpty) {
      throw Exception('Tüm alanlar gerekli');
    }

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalı');
    }

    return await _authRepository.forgotPasswordReset(
      phoneCode: phoneCode,
      phone: phone,
      smsCode: smsCode,
      password: password,
    );
  }
}
