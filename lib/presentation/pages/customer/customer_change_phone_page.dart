import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/profile_api_service.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/premium_button.dart';

class CustomerChangePhonePage extends StatefulWidget {
  const CustomerChangePhonePage({super.key});

  @override
  State<CustomerChangePhonePage> createState() => _CustomerChangePhonePageState();
}

class _CustomerChangePhonePageState extends State<CustomerChangePhonePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCodeController = TextEditingController(text: '90');
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  final ProfileApiService _profileApiService = ProfileApiService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSmsSent = false;
  int _countdown = 0;

  @override
  void dispose() {
    _phoneCodeController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
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
        title: Text(
          AppLocalizations.of(context)!.changePhonePageTitle,
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
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
                const SizedBox(height: AppSpacing.lg),
                _buildHeader(),
                const SizedBox(height: AppSpacing.xxxl),
                if (!_isSmsSent) _buildPhoneForm() else _buildSmsForm(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: AppSpacing.xxxl),
                _buildActionButton(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSmsSent ? AppLocalizations.of(context)!.smsVerificationCode : AppLocalizations.of(context)!.newPhoneNumber,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isSmsSent
              ? AppLocalizations.of(context)!.enterSmsVerificationCode
              : AppLocalizations.of(context)!.enterNewPhoneNumber,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: PremiumInput(
                label: l10n.countryCode,
                hint: '90',
                controller: _phoneCodeController,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.flag,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.countryCodeRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              flex: 5,
              child: PremiumInput(
                label: l10n.phoneNumber,
                hint: l10n.enterPhoneNumber,
                controller: _phoneController,
                isPhoneNumber: true,
                prefixIcon: Icons.phone,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.phoneNumberRequired;
                  }
                  final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (digitsOnly.length != 10) {
                    return l10n.phoneNumber10Digits;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmsForm() {
    return Column(
      children: [
        PremiumInput(
          label: AppLocalizations.of(context)!.verificationCodeLabel,
          hint: AppLocalizations.of(context)!.verificationCodeHint,
          controller: _smsCodeController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.sms_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.verificationCodeRequired;
            }
            if (value.length != 6) {
              return AppLocalizations.of(context)!.verificationCodeLengthError;
            }
            return null;
          },
        ),
        if (_countdown > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.waitForNewCode(_countdown),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Column(
      children: [
        PremiumButton(
          text: _isSmsSent ? AppLocalizations.of(context)!.confirm : AppLocalizations.of(context)!.sendSms,
          onPressed: _isLoading ? null : (_isSmsSent ? _handleApprove : _handleSendSms),
          isLoading: _isLoading,
        ),
        if (_isSmsSent) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: _countdown > 0 ? null : _handleResendSms,
            child: Text(
              AppLocalizations.of(context)!.resendCode,
              style: AppTypography.bodyMedium.copyWith(
                color: _countdown > 0
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSendSms() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clean phone number - remove all non-digit characters
      final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      await _profileApiService.requestPhoneChange(
        phoneCode: _phoneCodeController.text.trim(),
        phone: cleanPhone,
      );

      if (mounted) {
        setState(() {
          _isSmsSent = true;
          _isLoading = false;
          _countdown = 60; // 60 saniye countdown
        });

        // Start countdown
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApprove() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _profileApiService.approvePhoneChange(
        smsCode: _smsCodeController.text.trim(),
      );

      if (mounted) {
        final message = result['message'] as String?;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.success,
            ),
          );
        }
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendSms() async {
    await _handleSendSms();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          }
        });
      }
      return _countdown > 0;
    });
  }
}

