import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/appointment_model.dart';

enum AppointmentCardType { upcoming, past, cancelled }

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final AppointmentCardType type;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRebook;
  final VoidCallback? onRate;
  /// Randevu daha önce değerlendirilmiş mi? Eğer değerlendirildiyse buton gizlenir.
  final bool hasRated;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.type,
    this.onTap,
    this.onCancel,
    this.onRebook,
    this.onRate,
    this.hasRated = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AppointmentCardType.upcoming:
        return _buildUpcomingCard(context);
      case AppointmentCardType.past:
        return _buildPastCard(context);
      case AppointmentCardType.cancelled:
        return _buildCancelledCard(context);
    }
  }

  Widget _buildUpcomingCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 360, // Yükseklik artırıldı (onay kodu alanı için)
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with company image
            Row(
              children: [
                // Company avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(Icons.store, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.companyName ?? AppLocalizations.of(context)!.barberDefaultName,
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.appointmentDetails,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Services with icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.content_cut, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _getServicesText(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Approve Code Section (for confirmed/pending appointments)
            if (appointment.status == AppointmentStatus.confirmed ||
                appointment.status == AppointmentStatus.pending) ...[
              // Eğer approveCode varsa göster
              if (appointment.approveCode != null &&
                  appointment.approveCode!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _isAppointmentTimeArrived()
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: _isAppointmentTimeArrived()
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isAppointmentTimeArrived())
                            Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                              size: 16,
                            ),
                          if (_isAppointmentTimeArrived())
                            const SizedBox(width: AppSpacing.xs),
                          Text(
                            _isAppointmentTimeArrived()
                                ? 'Onay Kodunuz (İşletmeye Gösterin)'
                                : 'Onay Kodu',
                            style: AppTypography.caption.copyWith(
                              color: _isAppointmentTimeArrived()
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        appointment.approveCode!,
                        style: AppTypography.h5.copyWith(
                          color: _isAppointmentTimeArrived()
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // approveCode null ise, kullanıcıyı detay sayfasına yönlendir
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Onay kodunuz için tıklayın',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],

            // Date and Time with enhanced design
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatDate(appointment.startDate),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        appointment.startHour,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (appointment.totalPrice != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          '₺${_formatPrice(appointment.totalPrice!)}',
                          style: AppTypography.h6.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            if (onCancel != null) ...[
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCancel,
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.cancelButton,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPastCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 300,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with completed badge
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.companyName ?? AppLocalizations.of(context)!.barberDefaultName,
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Tamamlandı',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'Tamamlandı',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Services
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.content_cut, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _getServicesText(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date and Price
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _formatDate(appointment.startDate),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (appointment.totalPrice != null) ...[
                        Text(
                          '₺${_formatPrice(appointment.totalPrice!)}',
                          style: AppTypography.h6.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Değerlendirme durumunu göster - hasRated veya onRate'e göre
                  if (hasRated) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Değerlendirildi',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else if (onRate != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Değerlendir',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            const Spacer(),
            Row(
              children: [
                if (onRate != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRate,
                      icon: Icon(
                        Icons.star_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Değerlendir',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onRebook != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onRebook,
                      icon: Icon(Icons.repeat, size: 16, color: Colors.white),
                      label: Text(
                        'Tekrar Al',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.companyName ?? AppLocalizations.of(context)!.barberDefaultName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_formatDate(appointment.startDate)} • ${appointment.startHour}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        appointment.statusText,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.inProgress:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.textTertiary;
    }
  }

  String _getServicesText() {
    if (appointment.services.isEmpty) return 'Hizmetler';

    final serviceNames = appointment.services
        .map((s) => s.name.isNotEmpty ? s.name : 'Hizmet')
        .where((name) => name.isNotEmpty)
        .toList();

    if (serviceNames.isEmpty) return 'Hizmetler';

    return serviceNames.join(', ');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatPrice(double price) {
    // Eğer fiyat 0 ise "Ücretsiz" göster
    if (price == 0.0) {
      return 'Ücretsiz';
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

  /// Randevu başlama saatinin gelip gelmediğini kontrol eder.
  /// startDate ve startHour değerlerini birleştirerek şu anki zamanla karşılaştırır.
  bool _isAppointmentTimeArrived() {
    try {
      // startDate formatı: "2026-01-16" veya "2026-01-16 13:30:00"
      // startHour formatı: "13:30:00" veya "13:30"
      final datePart = appointment.startDate.split(' ').first;
      final timePart = appointment.startHour.split(':');
      
      final hour = int.tryParse(timePart[0]) ?? 0;
      final minute = timePart.length > 1 ? (int.tryParse(timePart[1]) ?? 0) : 0;
      
      final appointmentDateTime = DateTime.parse(datePart).add(
        Duration(hours: hour, minutes: minute),
      );
      
      return DateTime.now().isAfter(appointmentDateTime) ||
          DateTime.now().isAtSameMomentAs(appointmentDateTime);
    } catch (e) {
      return false;
    }
  }
}
