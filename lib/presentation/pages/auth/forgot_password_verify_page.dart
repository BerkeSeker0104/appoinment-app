import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import 'forgot_password_reset_page.dart';

class ForgotPasswordVerifyPage extends StatefulWidget {
  final String phoneCode;
  final String phone;

  const ForgotPasswordVerifyPage({
    super.key,
    required this.phoneCode,
    required this.phone,
  });

  @override
  State<ForgotPasswordVerifyPage> createState() =>
      _ForgotPasswordVerifyPageState();
}

class _ForgotPasswordVerifyPageState extends State<ForgotPasswordVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _smsCodeController = TextEditingController();

  late final AuthUseCases _authUseCases;
  bool _isLoading = false;
  String? _errorMessage;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _authUseCases = AuthUseCases(AuthRepositoryImpl());
  }

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                _buildHeader(l10n),
                const SizedBox(height: AppSpacing.xxxl),
                _buildForm(l10n),
                const SizedBox(height: AppSpacing.xxxl),
                _buildVerifyButton(l10n),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: AppSpacing.xl),
                _buildResendButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.forgotPasswordVerifyTitle,
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.forgotPasswordVerifySubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      children: [
        PremiumInput(
          label: l10n.verificationCode,
          hint: l10n.enterSmsCode,
          controller: _smsCodeController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.sms_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.smsCodeRequired;
            }
            if (value.length != 6) {
              return l10n.smsCodeInvalid;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVerifyButton(AppLocalizations l10n) {
    return PremiumButton(
      text: l10n.verifyCode,
      onPressed: _isLoading ? null : _handleVerify,
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

  Widget _buildResendButton(AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: _countdown > 0 ? null : _resendCode,
        child: Text(
          _countdown > 0
              ? '${l10n.resendCode} (${_countdown}s)'
              : l10n.resendCode,
          style: AppTypography.bodyMedium.copyWith(
            color: _countdown > 0 ? AppColors.textTertiary : AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _resendCode() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await _authUseCases.forgotPasswordRequest(
        phoneCode: widget.phoneCode,
        phone: widget.phone,
      );

      if (mounted) {
        setState(() {
          _countdown = 60;
        });
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  void _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authUseCases.forgotPasswordVerify(
        phoneCode: widget.phoneCode,
        phone: widget.phone,
        smsCode: _smsCodeController.text.trim(),
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.codeVerifiedMessage),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordResetPage(
              phoneCode: widget.phoneCode,
              phone: widget.phone,
              smsCode: _smsCodeController.text.trim(),
            ),
          ),
        );
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
}

