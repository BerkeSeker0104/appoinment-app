import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Stream<User?> get authStateChanges;
  
  // Forgot Password methods
  Future<void> forgotPasswordRequest({
    required String phoneCode,
    required String phone,
  });
  Future<void> forgotPasswordVerify({
    required String phoneCode,
    required String phone,
    required String smsCode,
  });
  Future<void> forgotPasswordReset({
    required String phoneCode,
    required String phone,
    required String smsCode,
    required String password,
  });
}
