import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/appointment_model.dart';
import '../../widgets/premium_button.dart';
import '../../../domain/usecases/appointment_usecases.dart';
import '../../../data/repositories/appointment_repository_impl.dart';

class AppointmentDetailPage extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailPage({super.key, required this.appointment});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  late AppointmentModel appointment;
  final AppointmentUseCases _appointmentUseCases =
      AppointmentUseCases(AppointmentRepositoryImpl());
  bool _isApproving = false;
  bool _isCompleting = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    appointment = widget.appointment;
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
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: _showOptionsMenu,
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
                    _buildCustomerInfo(),
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

  Widget _buildCustomerInfo() {
    return _buildInfoCard(
      title: 'Müşteri Bilgileri',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoRow('Ad Soyad', appointment.fullCustomerName),
          if (appointment.customerPhone != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow('Telefon', appointment.customerPhone!),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  text: 'Müşteri Profili',
                  onPressed: _viewCustomerProfile,
                  variant: ButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PremiumButton(
                  text: 'Mesaj Gönder',
                  onPressed: _sendMessage,
                  variant: ButtonVariant.secondary,
                ),
              ),
            ],
          ),
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
          _buildInfoRow('Tarih', appointment.startDate),
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
        children:
            appointment.services.map((service) {
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
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${service.durationMinutes} dakika',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
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
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
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

    if (appointment.canBeApproved) {
      addButton(
        PremiumButton(
          text: 'Onayla',
          onPressed: _isApproving ? null : _approveAppointment,
          isLoading: _isApproving,
          variant: ButtonVariant.primary,
        ),
      );
    }

    if (_shouldShowCompleteButton()) {
      addButton(
        PremiumButton(
          text: 'Tamamla',
          onPressed: _isCompleting ? null : _completeAppointment,
          isLoading: _isCompleting,
          variant: ButtonVariant.primary,
        ),
      );
    }

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

    if (appointment.status == AppointmentStatus.completed) {
      addButton(
        PremiumButton(
          text: 'Yeni Randevu Oluştur',
          onPressed: _createNewAppointment,
          variant: ButtonVariant.primary,
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

  bool _shouldShowCompleteButton() {
    if (!appointment.canBeCompleted) return false;

    final dateString = appointment.startDate;
    final timeString = appointment.startHour;

    if (dateString.isEmpty || timeString.isEmpty) return false;

    try {
      final dateParts = dateString.split('-');
      final timeParts = timeString.split(':');

      if (dateParts.length < 3 || timeParts.length < 2) return false;

      final startDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final serviceDuration = appointment.services.fold<int>(
        0,
        (sum, service) => sum + (service.durationMinutes ?? 0),
      );

      final expectedFinish = serviceDuration > 0
          ? startDateTime.add(Duration(minutes: serviceDuration))
          : startDateTime.add(const Duration(hours: 1));

      return DateTime.now().isAfter(expectedFinish);
    } catch (_) {
      return false;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _updateAppointment(AppointmentModel updated) {
    setState(() {
      appointment = updated;
    });
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('Randevuyu Düzenle'),
                  onTap: () {
                    Navigator.pop(context);
                    _editAppointment();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule, color: AppColors.warning),
                  title: const Text('Zamanı Değiştir'),
                  onTap: () {
                    Navigator.pop(context);
                    _rescheduleAppointment();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: AppColors.info),
                  title: const Text('Paylaş'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareAppointment();
                  },
                ),
                if (appointment.canBeApproved)
                  ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: AppColors.success),
                    title: const Text('Randevuyu Onayla'),
                    onTap: () {
                      Navigator.pop(context);
                      _approveAppointment();
                    },
                  ),
                if (_shouldShowCompleteButton())
                  ListTile(
                    leading:
                        const Icon(Icons.task_alt, color: AppColors.primary),
                    title: const Text('Randevuyu Tamamla'),
                    onTap: () {
                      Navigator.pop(context);
                      _completeAppointment();
                    },
                  ),
                if (appointment.canBeCancelled)
                  ListTile(
                    leading: const Icon(Icons.cancel, color: AppColors.error),
                    title: const Text('İptal Et'),
                    onTap: () {
                      Navigator.pop(context);
                      _cancelAppointment();
                    },
                  ),
              ],
            ),
          ),
    );
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
        return 'Randevu reddedildi';
      case AppointmentStatus.noShow:
        return 'Müşteri randevuya gelmedi';
    }
  }

  String _formatDate(DateTime date) {
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
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveAppointment() async {
    if (_isApproving) return;

    setState(() {
      _isApproving = true;
    });

    try {
      final updated =
          await _appointmentUseCases.approveAppointment(appointment.id);
      _updateAppointment(updated);
      _showMessage('Randevu başarıyla onaylandı');
    } catch (e) {
      _showMessage(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
        });
      }
    }
  }

  Future<void> _completeAppointment() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final updated =
          await _appointmentUseCases.completeAppointment(appointment.id);
      _updateAppointment(updated);
      _showMessage('Randevu tamamlandı');
    } catch (e) {
      _showMessage(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _performCancelAppointment() async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _appointmentUseCases.cancelAppointment(appointment.id);
      _updateAppointment(
        appointment.copyWith(
          status: AppointmentStatus.cancelled,
          updatedAt: DateTime.now(),
        ),
      );
      _showMessage('Randevu iptal edildi');
    } catch (e) {
      _showMessage(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _cancelAppointment() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Randevuyu İptal Et'),
            content: const Text(
              'Bu randevuyu iptal etmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performCancelAppointment();
                },
                child: const Text('İptal Et'),
              ),
            ],
          ),
    );
  }

  void _viewCustomerProfile() {
    // Müşteri profili sayfasına yönlendir
  }

  void _sendMessage() {
    // Müşteriye mesaj gönder
  }

  void _editAppointment() {
    // Randevu düzenleme sayfasına git
  }

  void _rescheduleAppointment() {
    // Randevu zamanını değiştir
  }

  void _shareAppointment() {
    // Randevu bilgilerini paylaş
  }

  void _createNewAppointment() {
    // Aynı müşteri için yeni randevu oluştur
  }
}
