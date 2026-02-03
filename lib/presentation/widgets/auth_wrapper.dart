import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../pages/auth/welcome_page.dart';
import '../pages/customer/customer_main_page.dart';
import '../pages/company/company_main_page.dart';

/// AuthWrapper - Manages authentication state and navigation
/// 
/// Responsibilities:
/// - Check if user is logged in on app start
/// - Listen to auth state changes (login/logout)
/// - Navigate to appropriate page based on user type
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());
  
  User? _currentUser;
  bool _isLoading = true;
  StreamSubscription<User?>? _authSubscription;
  
  // Constants
  static const Duration _authTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Initialize authentication - check current user and listen to changes
  Future<void> _initializeAuth() async {
    // First, set up the auth state listener
    _setupAuthListener();
    
    // Then check current user
    await _checkCurrentUser();
  }

  /// Set up listener for auth state changes
  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _authUseCases.authStateChanges.listen(
      (User? user) {
        if (kDebugMode) {
          debugPrint('AuthWrapper: Auth state changed - user: ${user?.name ?? 'null'}');
        }
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('AuthWrapper: Auth stream error: $error');
        }
      },
    );
  }

  /// Check current user from storage
  Future<void> _checkCurrentUser() async {
    if (!mounted) return;

    try {
      if (kDebugMode) {
        debugPrint('AuthWrapper: Checking current user...');
      }
      
      final user = await _authUseCases.getCurrentUser().timeout(
        _authTimeout,
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('AuthWrapper: getCurrentUser timed out');
          }
          return null;
        },
      );

      if (kDebugMode) {
        debugPrint('AuthWrapper: Current user: ${user?.name ?? 'null'}');
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthWrapper: Error checking current user: $e');
      }
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Not logged in - show welcome page
    if (_currentUser == null) {
      return const WelcomePage();
    }

    // Logged in - navigate based on user type
    if (_currentUser!.isCustomer) {
      return const CustomerMainPage();
    } else {
      return const CompanyMainPage();
    }
  }
}
