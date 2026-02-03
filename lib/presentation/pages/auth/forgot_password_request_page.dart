import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import 'forgot_password_verify_page.dart';

class ForgotPasswordRequestPage extends StatefulWidget {
  const ForgotPasswordRequestPage({super.key});

  @override
  State<ForgotPasswordRequestPage> createState() =>
      _ForgotPasswordRequestPageState();
}

class _ForgotPasswordRequestPageState extends State<ForgotPasswordRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCodeController = TextEditingController(text: '90');
  final _phoneController = TextEditingController();

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
    _phoneCodeController.dispose();
    _phoneController.dispose();
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
                _buildSendButton(l10n),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorMessage(),
                ],
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
          l10n.forgotPasswordTitle,
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.forgotPasswordSubtitle,
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
                hint: '555 555 5555',
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

  Widget _buildSendButton(AppLocalizations l10n) {
    return PremiumButton(
      text: l10n.sendCode,
      onPressed: _isLoading || _countdown > 0 ? null : _handleRequest,
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

  void _handleRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cleanPhone = _phoneController.text.replaceAll(' ', '');
      await _authUseCases.forgotPasswordRequest(
        phoneCode: _phoneCodeController.text.trim(),
        phone: cleanPhone,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.smsCodeSentMessage),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordVerifyPage(
              phoneCode: _phoneCodeController.text.trim(),
              phone: cleanPhone,
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

