import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/comment_model.dart';
import '../../widgets/premium_button.dart';
import '../../../domain/usecases/appointment_usecases.dart';
import '../../../domain/usecases/comment_usecases.dart';
import '../../../data/repositories/appointment_repository_impl.dart';
import '../../../data/repositories/comment_repository_impl.dart';
import '../../../data/services/company_api_service.dart';
import 'rating_page.dart';

class CustomerAppointmentDetailPage extends StatefulWidget {
  final AppointmentModel appointment;

  const CustomerAppointmentDetailPage({
    super.key,
    required this.appointment,
  });

  @override
  State<CustomerAppointmentDetailPage> createState() =>
      _CustomerAppointmentDetailPageState();
}

class _CustomerAppointmentDetailPageState
    extends State<CustomerAppointmentDetailPage> {
  late AppointmentModel appointment;
  final AppointmentUseCases _appointmentUseCases =
      AppointmentUseCases(AppointmentRepositoryImpl());
  final CommentUseCases _commentUseCases =
      CommentUseCases(CommentRepositoryImpl());
  bool _isLoading = false;
  bool _isCancelling = false;
  bool _isFetchingDetails = true; // Detaylar yüklenirken gösterilecek
  CommentModel? _existingComment;

  @override
  void initState() {
    super.initState();
    appointment = widget.appointment;
    _fetchAppointmentDetails(); // Detayları API'den çek (approveCode dahil)
    _checkRatingStatus();
  }

  /// Randevu detaylarını API'den çeker (approveCode dahil)
  /// Liste API'si approveCode döndürmediği için bu gerekli
  Future<void> _fetchAppointmentDetails() async {
    try {
      setState(() => _isFetchingDetails = true);
      
      final updated = await _appointmentUseCases.getAppointmentDetail(appointment.id);
      if (mounted) {
        setState(() {
          appointment = updated;
          _isFetchingDetails = false;
        });
        await _checkCompanyName();
      }
    } catch (e) {
      // Hata durumunda mevcut veriyi kullan
      if (mounted) {
        setState(() => _isFetchingDetails = false);
        _checkCompanyName();
      }
    }
  }

  Future<void> _checkCompanyName() async {
    if (appointment.companyName == null || appointment.companyName!.isEmpty) {
      try {
        final companyService = CompanyApiService();
        final company = await companyService.getCompanyById(appointment.companyId);
        if (mounted) {
          setState(() {
            appointment = appointment.copyWith(companyName: company.name);
          });
        }
      } catch (_) {
        // Hata durumunda sessiz kal
      }
    }
  }

  Future<void> _checkRatingStatus() async {
    if (appointment.status != AppointmentStatus.completed) return;

    setState(() => _isLoading = true);

    try {
      // Get all comments for this company and check if any belongs to this appointment
      final comments = await _commentUseCases.fetchCompanyComments(
        companyId: appointment.companyId,
        page: 1,
        limit: 100, // Get enough to find the comment
      );

      // Daha güvenli eşleştirme - String dönüşümü ile
      CommentModel? matchingComment;
      try {
        matchingComment = comments.firstWhere(
          (c) => c.appointmentId.toString() == appointment.id.toString(),
        );
      } catch (_) {
        // Eşleşme yok
        matchingComment = null;
      }

      if (mounted) {
        setState(() => _existingComment = matchingComment);
      }
    } catch (e) {
      // If error, assume no comment exists
      if (mounted) {
        setState(() => _existingComment = null);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshAppointment() async {
    try {
      final updated =
          await _appointmentUseCases.getAppointmentDetail(appointment.id);
      if (mounted) {
        setState(() {
          appointment = updated;
        });
        await _checkCompanyName();
        await _checkRatingStatus();
      }
    } catch (e) {
      // Ignore errors on refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Randevu Detayları',
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshAppointment,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildApproveCodeInfo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildCompanyInfo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAppointmentInfo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildServicesInfo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPaymentInfo(),
                    if (appointment.notes != null &&
                        appointment.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildNotesSection(),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _buildTimelineSection(),
                    if (appointment.status == AppointmentStatus.completed &&
                        _existingComment != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildRatingSection(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _getStatusColor(appointment.status),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(appointment.status),
              color: AppColors.textInverse,
              size: AppSpacing.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.statusText,
                  style: AppTypography.h6.copyWith(
                    color: _getStatusColor(appointment.status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _getStatusDescription(appointment.status),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApproveCodeInfo() {
    // Onay kodunu confirmed ve pending durumlarında göster
    if ((appointment.status != AppointmentStatus.confirmed &&
            appointment.status != AppointmentStatus.pending) ||
        appointment.approveCode == null ||
        appointment.approveCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTimeArrived = _isAppointmentTimeArrived();
    final primaryColor = isTimeArrived ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isTimeArrived ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: primaryColor.withValues(alpha: isTimeArrived ? 0.5 : 1.0),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isTimeArrived) ...[
                Icon(
                  Icons.verified_rounded,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                isTimeArrived
                    ? 'Hizmet Onay Kodu (Şimdi Gösterin!)'
                    : 'Hizmet Onay Kodu',
                style: AppTypography.bodyMedium.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            appointment.approveCode!,
            style: AppTypography.h3.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isTimeArrived
                ? 'Bu kodu şimdi işletmeye gösterin'
                : 'Randevu saatinde bu kodu işletmeye gösterin',
            style: AppTypography.caption.copyWith(
              color: primaryColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return _buildInfoCard(
      title: 'İşletme Bilgileri',
      icon: Icons.store,
      child: Column(
        children: [
          _buildInfoRow('İşletme Adı', appointment.companyName ?? 'Bilinmiyor'),
          if (appointment.branchName != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow('Şube', appointment.branchName!),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentInfo() {
    final totalDuration = appointment.services.fold<int>(
      0,
      (sum, s) => sum + (s.durationMinutes ?? 0),
    );

    return _buildInfoCard(
      title: 'Randevu Bilgileri',
      icon: Icons.calendar_today,
      child: Column(
        children: [
          _buildInfoRow('Tarih', _formatDate(appointment.startDate)),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Saat', appointment.startHour),
          if (totalDuration > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow('Süre', '$totalDuration dakika'),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            'Randevu ID',
            '#${appointment.id.length >= 8 ? appointment.id.substring(0, 8).toUpperCase() : appointment.id.toUpperCase()}',
          ),
        ],
      ),
    );
  }

  Widget _buildServicesInfo() {
    return _buildInfoCard(
      title: 'Hizmetler',
      icon: Icons.content_cut,
      child: Column(
        children: appointment.services.map((service) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (service.durationMinutes != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${service.durationMinutes} dakika',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '₺${service.price.toStringAsFixed(0)}',
                  style: AppTypography.monoMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return _buildInfoCard(
      title: 'Ödeme Bilgileri',
      icon: Icons.payment,
      child: Column(
        children: [
          ...appointment.services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    service.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₺${service.price.toStringAsFixed(0)}',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₺${appointment.totalPrice?.toStringAsFixed(0) ?? appointment.services.fold<double>(0, (sum, s) => sum + s.price).toStringAsFixed(0)}',
                style: AppTypography.monoLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildInfoCard(
      title: 'Notlar',
      icon: Icons.note,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(
          appointment.notes!,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return _buildInfoCard(
      title: 'Randevu Geçmişi',
      icon: Icons.history,
      child: Column(
        children: [
          _buildTimelineItem(
            'Randevu Oluşturuldu',
            appointment.createdAt,
            Icons.event_note,
            AppColors.info,
            isCompleted: true,
          ),
          if (appointment.status != AppointmentStatus.pending)
            _buildTimelineItem(
              'Randevu Onaylandı',
              appointment.updatedAt ?? appointment.createdAt,
              Icons.check_circle,
              AppColors.success,
              isCompleted: true,
            ),
          if (appointment.status == AppointmentStatus.inProgress)
            _buildTimelineItem(
              'Hizmet Başladı',
              DateTime.now(),
              Icons.play_circle,
              AppColors.primary,
              isCompleted: true,
            ),
          if (appointment.status == AppointmentStatus.completed)
            _buildTimelineItem(
              'Hizmet Tamamlandı',
              appointment.updatedAt ?? DateTime.now(),
              Icons.task_alt,
              AppColors.success,
              isCompleted: true,
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    if (_existingComment == null) return const SizedBox.shrink();

    return _buildInfoCard(
      title: 'Değerlendirmeniz',
      icon: Icons.star,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < _existingComment!.score
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${_existingComment!.score}/5',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (_existingComment!.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                _existingComment!.comment,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime time,
    IconData icon,
    Color color, {
    bool isCompleted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppSpacing.iconSm,
              color: isCompleted ? AppColors.textInverse : color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDateTime(time),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    void addButton(Widget button) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(height: AppSpacing.md));
      }
      buttons.add(button);
    }

    // Show rating button for completed appointments without rating
    if (appointment.status == AppointmentStatus.completed &&
        _existingComment == null &&
        !_isLoading) {
      addButton(
        PremiumButton(
          text: 'Değerlendir',
          onPressed: _navigateToRating,
          variant: ButtonVariant.primary,
        ),
      );
    }

    // Show cancel button for upcoming appointments
    if (appointment.canBeCancelled &&
        appointment.status != AppointmentStatus.completed) {
      addButton(
        PremiumButton(
          text: 'İptal Et',
          onPressed: _isCancelling ? null : _cancelAppointment,
          isLoading: _isCancelling,
          variant: ButtonVariant.secondary,
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(children: buttons),
    );
  }

  Future<void> _navigateToRating() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage(
          barberName: appointment.companyName ?? 'İşletme',
          serviceName: appointment.services.isNotEmpty
              ? appointment.services.first.name
              : 'Hizmet',
          appointmentId: appointment.id,
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh appointment and check rating status
      await _refreshAppointment();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Değerlendirmeniz için teşekkürler!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(
          'Randevuyu İptal Et',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu randevuyu iptal etmek istediğinizden emin misiniz?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.companyName ?? 'İşletme',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatDate(appointment.startDate)} • ${appointment.startHour}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Vazgeç',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'İptal Et',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      await _appointmentUseCases.cancelAppointment(appointment.id);
      if (mounted) {
        setState(() {
          appointment = appointment.copyWith(
            status: AppointmentStatus.cancelled,
            updatedAt: DateTime.now(),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Randevu başarıyla iptal edildi',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            margin: const EdgeInsets.all(AppSpacing.lg),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.info;
      case AppointmentStatus.inProgress:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.inProgress:
        return Icons.play_circle;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }

  String _getStatusDescription(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Randevu onay bekliyor';
      case AppointmentStatus.confirmed:
        return 'Randevu onaylandı ve zamanında başlayacak';
      case AppointmentStatus.inProgress:
        return 'Hizmet şu anda devam ediyor';
      case AppointmentStatus.completed:
        return 'Hizmet başarıyla tamamlandı';
      case AppointmentStatus.cancelled:
        return 'Randevu iptal edildi';
      case AppointmentStatus.noShow:
        return 'Randevuya gelinmedi';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime.toIso8601String().split('T')[0])} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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