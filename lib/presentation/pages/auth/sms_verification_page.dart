import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/auth_wrapper.dart';

class SmsVerificationPage extends StatefulWidget {
  final String phoneCode;
  final String phone;
  final String name;
  final String surname;
  final String email;
  final String password;
  final String gender;
  final String? companyName;
  final String? companyType;
  final String? companyAddress;
  final String? companyPhoneCode;
  final String? companyPhone;
  final String? companyEmail;
  final bool isCompanyRegistration;

  const SmsVerificationPage({
    super.key,
    required this.phoneCode,
    required this.phone,
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.gender,
    this.companyName,
    this.companyType,
    this.companyAddress,
    this.companyPhoneCode,
    this.companyPhone,
    this.companyEmail,
    this.isCompanyRegistration = false,
  });

  @override
  State<SmsVerificationPage> createState() => _SmsVerificationPageState();
}

class _SmsVerificationPageState extends State<SmsVerificationPage> {
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
    _sendSms();
  }

  @override
  void dispose() {
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
                _buildForm(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildVerifyButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: AppSpacing.xl),
                _buildResendButton(),
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
          'SMS Doğrulama',
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${widget.phoneCode}${widget.phone} numarasına gönderilen doğrulama kodunu girin',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        PremiumInput(
          label: 'Doğrulama Kodu',
          hint: '6 haneli kodu girin',
          controller: _smsCodeController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.sms_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Doğrulama kodu gerekli';
            }
            if (value.length != 6) {
              return '6 haneli kod girin';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return PremiumButton(
      text: 'Doğrula',
      onPressed: _isLoading ? null : _handleVerification,
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

  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: _countdown > 0 ? null : _sendSms,
        child: Text(
          _countdown > 0
              ? 'Tekrar gönder (${_countdown}s)'
              : 'Kodu tekrar gönder',
          style: AppTypography.bodyMedium.copyWith(
            color: _countdown > 0 ? AppColors.textTertiary : AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _sendSms() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await _authUseCases.sendSms(
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

  void _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authUseCases.verifySmsCode(
        phoneCode: widget.phoneCode,
        phone: widget.phone,
        smsCode: _smsCodeController.text.trim(),
        name: widget.name,
        surname: widget.surname,
        email: widget.email,
        gender: widget.gender,
        companyName: widget.companyName,
        companyType: widget.companyType,
        companyAddress: widget.companyAddress,
        companyPhoneCode: widget.companyPhoneCode,
        companyPhone: widget.companyPhone,
        companyEmail: widget.companyEmail,
        isCompanyRegistration: widget.isCompanyRegistration,
      );

      if (mounted) {
        _navigateToMainApp(user);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');

        // Berber kaydı onay bekliyorsa özel durum
        if (errorMessage.startsWith('COMPANY_PENDING_APPROVAL|')) {
          final message = errorMessage.split('|').last;
          _showSuccessDialogAndNavigateToLogin(message);
        } else {
          setState(() {
            _errorMessage = errorMessage;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialogAndNavigateToLogin(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Kayıt Başarılı!',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                text: 'Tamam',
                onPressed: () {
                  // Login sayfasına geri dön (tüm stack'i temizle)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMainApp(User user) {
    // Navigate to AuthWrapper which will show the correct page based on user type
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }
}
