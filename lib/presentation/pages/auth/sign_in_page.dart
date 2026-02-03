import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/auth_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/auth_wrapper.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthUseCases _authUseCases;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _errorMessage;

  bool get _isAppleAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String? get _googleClientIdOverride {
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AuthConstants.googleIosClientId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _authUseCases = AuthUseCases(AuthRepositoryImpl());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                _buildHeader(),
                const SizedBox(height: AppSpacing.xxxl),
                // Demo accounts removed for production
                _buildForm(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildSignInButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: AppSpacing.xl),
                _buildSocialLogins(),
                const SizedBox(height: AppSpacing.xl),
                _buildSignUpPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeBack,
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.welcomeBackSubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Demo account UI removed for production

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        PremiumInput(
          label: l10n.email,
          hint: l10n.emailPlaceholder,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.emailRequired;
            }
            if (!value.contains('@')) {
              return l10n.validEmail;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: l10n.password,
          hint: l10n.enterPassword,
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.passwordRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    final l10n = AppLocalizations.of(context)!;
    return PremiumButton(
      text: l10n.loginButton,
      onPressed: _isLoading ? null : _handleSignIn,
      isLoading: _isLoading,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogins() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'veya',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildSocialButton(
          'Google',
          Icons.g_mobiledata,
          Colors.red,
          isLoading: _isGoogleLoading,
          onTap: _handleGoogleSignIn,
        ),
        if (_isAppleAvailable) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSocialButton(
            'Apple',
            Icons.apple,
            Colors.black,
            isLoading: _isAppleLoading,
            onTap: _handleAppleSignIn,
          ),
        ],
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color color, {
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null || isLoading;
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: AppSpacing.iconMd,
                width: AppSpacing.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                ),
              )
            else ...[
              Icon(icon, color: color, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${l10n.signUpPrompt} ',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => _navigateToSignUp(),
          child: Text(
            l10n.createAccount,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Removed: _fillDemoAccount helper for demo

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authUseCases.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        _navigateToMainApp(user);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMainApp(User user) {
    // Navigate to AuthWrapper which will show the correct page based on user type
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  void _navigateToSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isLoading) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientIdOverride,
        serverClientId: AuthConstants.googleWebClientId,
        scopes: const ['email'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        return;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      final accessToken = authentication.accessToken;

      if (idToken == null) {
        throw Exception('Google oturum bilgisi alınamadı.');
      }

      final user = await _authUseCases.googleSignIn(
        idToken: idToken,
        accessToken: accessToken,
        email: account.email,
        name: account.displayName,
        avatar: account.photoUrl,
      );

      if (!mounted) return;
      _navigateToMainApp(user);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      } else {
        _isGoogleLoading = false;
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (!_isAppleAvailable || _isAppleLoading || _isLoading) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    setState(() {
      _isAppleLoading = true;
      _errorMessage = null;
    });

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple ile giriş bu cihazda desteklenmiyor.');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (identityToken == null ||
          identityToken.isEmpty ||
          authorizationCode.isEmpty) {
        throw Exception('Apple oturum bilgisi alınamadı.');
      }

      final fullNameParts = [
        credential.givenName,
        credential.familyName,
      ]
          .whereType<String>()
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty);
      final fullName = fullNameParts.join(' ');

      final user = await _authUseCases.appleSignIn(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: credential.email,
        name: fullName.isNotEmpty ? fullName : null,
      );

      if (!mounted) return;
      _navigateToMainApp(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return;
      }
      final errorMessage = e.message;
      if (!mounted) return;
      setState(() {
        _errorMessage = errorMessage.isNotEmpty
            ? errorMessage
            : 'Apple ile giriş başarısız oldu.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      } else {
        _isAppleLoading = false;
      }
    }
  }

}
