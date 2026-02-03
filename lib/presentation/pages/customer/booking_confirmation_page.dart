import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/service_model.dart';
import '../../widgets/premium_button.dart';
import 'customer_main_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String barberId;
  final String barberName;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final List<ServiceModel> selectedServices;
  final double totalPrice;
  final int totalDuration;
  final String paymentMethod;

  const BookingConfirmationPage({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.selectedServices,
    required this.totalPrice,
    required this.totalDuration,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    _buildSuccessIcon(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildSuccessMessage(context),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildAppointmentDetails(context),
                    const SizedBox(height: AppSpacing.xxl),
                    // Buton için alt boşluk
                    SizedBox(
                        height: AppSpacing.lg +
                            MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
            // Buton sayfanın en altına sabitlenmiş
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.appointmentBooked,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.appointmentBookedMessage,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.appointmentDetails,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Barber info
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barberName,
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            AppLocalizations.of(context)!.verifiedProfessional,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Date and time
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  icon: Icons.calendar_today,
                  label: AppLocalizations.of(context)!.date,
                  value: _formatDate(context),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildDetailCard(
                  icon: Icons.access_time,
                  label: AppLocalizations.of(context)!.time,
                  value: selectedTimeSlot,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Duration and price
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  icon: Icons.schedule,
                  label: AppLocalizations.of(context)!.durationLabel,
                  value:
                      '${totalDuration}${AppLocalizations.of(context)!.minuteShort}',
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildDetailCard(
                  icon: Icons.payments,
                  label: AppLocalizations.of(context)!.totalLabel,
                  value: '₺${_formatPrice(context, totalPrice)}',
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Payment Method
          _buildDetailCard(
            icon: Icons.payment,
            label: 'Ödeme Yöntemi',
            value: _getPaymentMethodText(context),
            // valueColor: AppColors.primary,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Services
          Text(
            AppLocalizations.of(context)!.services,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...selectedServices.map((service) => Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        _getIconData(service.iconName),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${service.durationMinutes} ${AppLocalizations.of(context)!.minutes}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${_formatPrice(context, service.price)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        child: PremiumButton(
          text: AppLocalizations.of(context)!.backToHome,
          onPressed: () => _navigateToHome(context),
          variant: ButtonVariant.primary,
        ),
      ),
    );
  }

  String _formatDate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december
    ];
    // Day abbreviations - need to add to ARB
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return '${days[selectedDate.weekday - 1]}, ${selectedDate.day} ${months[selectedDate.month - 1]}';
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return Icons.content_cut;
      case 'face_retouching_natural':
        return Icons.face_retouching_natural;
      case 'water_drop':
        return Icons.water_drop;
      case 'brush':
        return Icons.brush;
      case 'diamond':
        return Icons.diamond;
      case 'face':
        return Icons.face;
      default:
        return Icons.cut;
    }
  }

  void _navigateToHome(BuildContext context) {
    // Tüm sayfaları kaldır ve CustomerMainPage'e git
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const CustomerMainPage(),
      ),
      (route) => false,
    );
  }

  String _formatPrice(BuildContext context, double price) {
    // Eğer fiyat 0 ise "Ücretsiz" göster
    if (price == 0.0) {
      return AppLocalizations.of(context)!.free;
    }

    // Ondalık kısmı kontrol et
    if (price == price.toInt().toDouble()) {
      // Tam sayı ise ondalık kısmı gösterme
      return price.toInt().toString();
    } else {
      // Ondalık sayı ise 2 basamak göster
      return price.toStringAsFixed(2);
    }
  }

  String _getPaymentMethodText(BuildContext context) {
    switch (paymentMethod) {
      case 'cash':
        return 'Nakit (Salon)';
      case 'creditCard':
        return 'Kredi/Banka Kartı (Salon)';
      case 'online':
        return 'Online Ödeme';
      default:
        return 'Kredi/Banka Kartı';
    }
  }
}
