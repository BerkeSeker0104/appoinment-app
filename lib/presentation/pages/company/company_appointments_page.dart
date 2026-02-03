import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/company_service_model.dart';
import '../../../data/services/branch_api_service.dart';
import '../../../domain/usecases/company_service_usecases.dart';
import '../../../data/repositories/company_service_repository_impl.dart';
import '../../../domain/usecases/appointment_usecases.dart';
import '../../../data/repositories/appointment_repository_impl.dart';
import '../../../data/services/company_user_api_service.dart';
import '../../../data/models/company_user_model.dart';

// Service name parsing helper
String _parseServiceName(String? value, BuildContext context) {
  if (value == null || value.isEmpty)
    return AppLocalizations.of(context)!.serviceDefaultName;
  final trimmed = value.trim();
  // Düz metin ise JSON parse etmeye çalışma
  if (!trimmed.startsWith('{')) return value;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      // Önce Türkçe, sonra İngilizce, son olarak orijinal string
      return decoded['tr'] as String? ?? decoded['en'] as String? ?? value;
    }
  } catch (_) {
    // Sessizce değeri olduğu gibi döndür
    // Normalde loglayabiliriz
  }
  return value;
}

// Date and time formatting helpers
String _formatDateTime(String dateString, String timeString) {
  try {
    // Eğer dateString ISO formatındaysa (2025-10-09T06:00:00.000Z)
    if (dateString.contains('T')) {
      final dateTime = DateTime.parse(dateString);
      final formattedDate =
          '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
      final formattedTime =
          timeString.split(':').take(2).join(':'); // Saniyeleri kaldır
      return '$formattedDate $formattedTime';
    }

    // Normal format: 2025-10-09
    final formattedTime =
        timeString.split(':').take(2).join(':'); // Saniyeleri kaldır
    return '$dateString $formattedTime';
  } catch (e) {
    return '$dateString ${timeString.split(':').take(2).join(':')}';
  }
}

// Date formatting helper
class DateHelper {
  static String formatToApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CompanyAppointmentsPage extends StatefulWidget {
  const CompanyAppointmentsPage({super.key});

  @override
  State<CompanyAppointmentsPage> createState() =>
      _CompanyAppointmentsPageState();
}

class _CompanyAppointmentsPageState extends State<CompanyAppointmentsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<AppointmentModel> _appointments = [];
  List<BranchModel> _branches = [];
  String? _selectedCompanyId;
  late TabController _tabController;

  // Categorized appointments
  List<AppointmentModel> _pendingAppointments = [];
  List<AppointmentModel> _activeAppointments = [];
  List<AppointmentModel> _completedAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];

  final AppointmentUseCases _appointmentUseCases =
      AppointmentUseCases(AppointmentRepositoryImpl());
  final BranchApiService _branchService = BranchApiService();

  final Set<String> _approvingAppointments = {};
  final Set<String> _completingAppointments = {};
  final Set<String> _startingAppointments = {};

  // Daily Schedule State
  DateTime _selectedDate = DateTime.now();
  final List<String> _bookedSlots = [];
  final Map<String, String> _slotEndTimes = {};
  bool _isLoadingBookedSlots = false;
  final ScrollController _timeSlotScrollController = ScrollController();
  
  // Constants
  static const int _slotIntervalMinutes = 30;
  static const int _minDurationMinutes = 30;
  static const String _weekdayOpenTime = '09:00';
  static const String _weekdayCloseTime = '18:00';
  static const String _saturdayOpenTime = '10:00';
  static const String _saturdayCloseTime = '16:00';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timeSlotScrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadBranches();
    
    // Load appointments and slots in parallel after branch (companyId) is available
    if (_selectedCompanyId != null) {
      await Future.wait([
        _loadAppointments(),
        _loadBookedSlots(),
      ]);
    }
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _branchService.getBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          // TEMPORARILY: Auto-select the first branch since there's only one branch now
          if (_branches.isNotEmpty && _selectedCompanyId == null) {
            _selectedCompanyId = _branches.first.id;
          }
        });
      }
    } catch (e) {
      // Continue even if branches fail to load
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all appointments without date filter
      final appointments = await _appointmentUseCases.fetchAppointments(
        startDate: null, // Fetch all
        companyId: _selectedCompanyId,
      );

      _categorizeAppointments(appointments);

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _categorizeAppointments(List<AppointmentModel> appointments) {
    _pendingAppointments = [];
    _activeAppointments = [];
    _completedAppointments = [];
    _cancelledAppointments = [];

    final processedAppointments = appointments
        .map((appointment) => _shouldAutoCancel(appointment)
            ? appointment.copyWith(status: AppointmentStatus.cancelled)
            : appointment)
        .toList();

    for (var appointment in processedAppointments) {
      switch (appointment.status) {
        case AppointmentStatus.pending:
          _pendingAppointments.add(appointment);
          break;
        case AppointmentStatus.confirmed:
        case AppointmentStatus.inProgress:
          _activeAppointments.add(appointment);
          break;
        case AppointmentStatus.completed:
          _completedAppointments.add(appointment);
          break;
        case AppointmentStatus.cancelled:
        case AppointmentStatus.noShow:
          _cancelledAppointments.add(appointment);
          break;
      }
    }

    // Sort lists
    // Pending: Newest date first (Descending date & time)
    _pendingAppointments.sort((a, b) {
      final dateComparison = b.startDate.compareTo(a.startDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return b.startHour.compareTo(a.startHour);
    });

    // Active: Newest start date first (Descending)
    _activeAppointments.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Completed & Cancelled: Newest date first
    _completedAppointments.sort((a, b) => b.startDate.compareTo(a.startDate));
    _cancelledAppointments.sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  bool _shouldAutoCancel(AppointmentModel appointment) {
    if (appointment.status != AppointmentStatus.pending) {
      return false;
    }

    final appointmentDateTime = _parseAppointmentDateTime(appointment);
    if (appointmentDateTime == null) {
      return false;
    }

    return appointmentDateTime.isBefore(DateTime.now());
  }

  DateTime? _parseAppointmentDateTime(AppointmentModel appointment) {
    final date = appointment.startDate.trim();
    if (date.isEmpty) return null;

    var time = appointment.startHour.trim();
    if (time.isEmpty) {
      time = '00:00';
    }

    // Ensure we always pass seconds for ISO parsing
    if (time.split(':').length == 2) {
      time = '$time:00';
    }

    final isoString = '${date}T$time';
    return DateTime.tryParse(isoString);
  }

  // TEMPORARILY COMMENTED OUT - Company filter changed handler (only one branch now, auto-selected)
  // void _onCompanyFilterChanged(String? companyId) {
  //   setState(() {
  //     _selectedCompanyId = companyId;
  //   });
  //   _loadAppointments();
  // }

  Future<void> _showCreateAppointmentDialog({String? selectedDate, String? selectedHour}) async {
    final createdAppointment = await Navigator.push<AppointmentModel>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAppointmentDialog(
          branches: _branches,
          selectedDate: selectedDate ?? DateHelper.formatToApiDate(DateTime.now()),
          selectedHour: selectedHour,
        ),
      ),
    );

    if (createdAppointment != null) {
      await _loadAppointments();
      await _loadBookedSlots(); // Refresh slots
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Randevu başarıyla oluşturuldu'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.appointmentDetails,
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                appointment.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Text(
                              appointment.statusText,
                              style: AppTypography.caption.copyWith(
                                color: _getStatusColor(appointment.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Customer Info
                _buildDetailSection(
                  title: AppLocalizations.of(context)!.customerInformation,
                  icon: Icons.person,
                  color: AppColors.primary,
                  children: [
                    _buildDetailItem(
                      AppLocalizations.of(context)!.fullName,
                      appointment.fullCustomerName.trim().isEmpty 
                          ? 'Müşteri' 
                          : appointment.fullCustomerName,
                      Icons.person_outline,
                    ),
                    if (appointment.customerPhone != null)
                      _buildDetailItem(
                        AppLocalizations.of(context)!.phoneNumber,
                        appointment.customerPhone!,
                        Icons.phone_outlined,
                        onTap: () => _makePhoneCall(appointment.customerPhone!),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Appointment Info
                _buildDetailSection(
                  title: AppLocalizations.of(context)!.appointmentInformation,
                  icon: Icons.access_time,
                  color: AppColors.primary,
                  children: [
                    _buildDetailItem(
                      AppLocalizations.of(context)!.dateAndTime,
                      _formatDateTime(
                        appointment.startDate,
                        appointment.startHour,
                      ),
                      Icons.calendar_today_outlined,
                    ),
                    if (appointment.branchName != null)
                      _buildDetailItem(
                        'Şube',
                        appointment.branchName!,
                        Icons.business_outlined,
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Services
                _buildDetailSection(
                  title: 'Hizmetler',
                  icon: Icons.content_cut,
                  color: AppColors.success,
                  children: [
                    ...appointment.services.map(
                      (service) => Container(
                        margin: const EdgeInsets.only(
                          bottom: AppSpacing.sm,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.content_cut,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _parseServiceName(service.name, context),
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (service.durationMinutes != null)
                                    Text(
                                      '${service.durationMinutes} ${AppLocalizations.of(context)!.dakika}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${service.price.toStringAsFixed(0)}',
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Toplam Tutar',
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          appointment.totalPrice != null
                              ? '₺${appointment.totalPrice!.toStringAsFixed(0)}'
                              : '₺0',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Additional Info
                _buildDetailSection(
                  title: 'Ek Bilgiler',
                  icon: Icons.info_outline,
                  color: AppColors.warning,
                  children: [
                    _buildDetailItem(
                      'Randevu No',
                      '#${_getAppointmentId(appointment.id)}',
                      Icons.tag,
                    ),
                    _buildDetailItem(
                      'Oluşturulma',
                      _formatDateTimeForDisplay(appointment.createdAt),
                      Icons.schedule,
                    ),
                    if (appointment.notes != null &&
                        appointment.notes!.isNotEmpty)
                      _buildDetailItem(
                        'Notlar',
                        appointment.notes!,
                        Icons.note,
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.body2.copyWith(
                  color:
                      onTap != null ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: content,
    );
  }

  String _getAppointmentId(String id) {
    if (id.length >= 8) {
      return id.substring(0, 8);
    } else {
      return id;
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.textSecondary;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.inProgress:
        return AppColors.info;
      case AppointmentStatus.noShow:
        return AppColors.textTertiary;
    }
  }

  String _formatDateTimeForDisplay(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelConfirmation(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.appointmentCancelTitle),
        content: Text(
          AppLocalizations.of(context)!
              .cancelAppointmentForCustomer(
                  appointment.fullCustomerName.trim().isEmpty 
                      ? 'Müşteri' 
                      : appointment.fullCustomerName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelAppointment(appointment);
            },
            child: Text(
              AppLocalizations.of(context)!.cancelButton,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    try {
      await _appointmentUseCases.cancelAppointment(appointment.id);
      setState(() {
        _appointments.removeWhere((a) => a.id == appointment.id);
        _categorizeAppointments(_appointments);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Randevu başarıyla iptal edildi'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _isApproving(String appointmentId) =>
      _approvingAppointments.contains(appointmentId);

  bool _isCompleting(String appointmentId) =>
      _completingAppointments.contains(appointmentId);

  Future<void> _approveAppointment(AppointmentModel appointment) async {
    if (appointment.id.isEmpty) return;

    setState(() {
      _approvingAppointments.add(appointment.id);
    });

    try {
      final updatedAppointment =
          await _appointmentUseCases.approveAppointment(appointment.id);

      setState(() {
        final index =
            _appointments.indexWhere((element) => element.id == appointment.id);
        if (index != -1) {
          _appointments[index] = updatedAppointment;
          _categorizeAppointments(_appointments);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başarıyla onaylandı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _approvingAppointments.remove(appointment.id);
        });
      }
    }
  }

  Future<void> _completeAppointment(AppointmentModel appointment) async {
    if (appointment.id.isEmpty) return;

    setState(() {
      _completingAppointments.add(appointment.id);
    });

    try {
      final updatedAppointment =
          await _appointmentUseCases.completeAppointment(appointment.id);

      setState(() {
        final index =
            _appointments.indexWhere((element) => element.id == appointment.id);
        if (index != -1) {
          _appointments[index] = updatedAppointment;
          _categorizeAppointments(_appointments);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu tamamlandı olarak işaretlendi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingAppointments.remove(appointment.id);
        });
      }
    }
  }

  bool _shouldShowCompleteButton(AppointmentModel appointment) {
    if (!appointment.canBeCompleted) return false;

    final dateString = appointment.startDate;
    final timeString = appointment.startHour;

    if (dateString.isEmpty || timeString.isEmpty) {
      return false;
    }

    try {
      final dateParts = dateString.split('-');
      final timeParts = timeString.split(':');

      if (dateParts.length < 3 || timeParts.length < 2) {
        return false;
      }

      final startDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final totalDuration = appointment.services.fold<int>(
        0,
        (sum, service) => sum + (service.durationMinutes ?? 0),
      );

      final expectedFinish = totalDuration > 0
          ? startDateTime.add(Duration(minutes: totalDuration))
          : startDateTime.add(const Duration(hours: 1));

      return DateTime.now().isAfter(expectedFinish);
    } catch (_) {
      return false;
    }
  }

  bool _isStarting(String appointmentId) =>
      _startingAppointments.contains(appointmentId);

  bool _shouldShowVerifyButton(AppointmentModel appointment) {
    if (appointment.status != AppointmentStatus.confirmed) return false;

    final dateString = appointment.startDate;
    final timeString = appointment.startHour;

    if (dateString.isEmpty || timeString.isEmpty) {
      return false;
    }

    try {
      final dateParts = dateString.split('-');
      final timeParts = timeString.split(':');

      if (dateParts.length < 3 || timeParts.length < 2) {
        return false;
      }

      final startDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      return DateTime.now().isAfter(startDateTime) ||
          DateTime.now().isAtSameMomentAs(startDateTime);
    } catch (_) {
      return false;
    }
  }

  Future<void> _showVerifyCodeDialog(AppointmentModel appointment) async {
    final codeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Kodu Doğrula',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Müşterinin ekranındaki onay kodunu giriniz:',
              style: AppTypography.body2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                hintText: 'Onay Kodu',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: const Text('Doğrula', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _startAppointment(appointment, codeController.text);
    }
  }

  Future<void> _startAppointment(
      AppointmentModel appointment, String code) async {
    if (appointment.id.isEmpty) return;

    setState(() {
      _startingAppointments.add(appointment.id);
    });

    try {
      final updatedAppointment =
          await _appointmentUseCases.startAppointment(appointment.id, code);

      setState(() {
        final index =
            _appointments.indexWhere((element) => element.id == appointment.id);
        if (index != -1) {
          _appointments[index] = updatedAppointment;
          _categorizeAppointments(_appointments);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu başlatıldı'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _startingAppointments.remove(appointment.id);
        });
      }
    }
  }

  // --- Daily Schedule & Slots Logic ---

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), 
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _loadBookedSlots();
    }
  }

  Future<void> _loadBookedSlots() async {
    if (_isLoadingBookedSlots || _selectedCompanyId == null) return;

    setState(() {
      _isLoadingBookedSlots = true;
      _bookedSlots.clear();
    });

    try {
      final bookedSlotsSet = <String>{};
      final slotEndTimesMap = <String, String>{};
      final formattedDate = DateHelper.formatToApiDate(_selectedDate);
      
      try {
        final availabilitySlots =
            await _appointmentUseCases.getAppointmentAvailability(
          companyId: _selectedCompanyId!,
          date: formattedDate,
        );

        for (final slot in availabilitySlots) {
          final startMinutes = _timeToMinutes(slot.normalizedStartHour);
          final endMinutes = _timeToMinutes(slot.normalizedFinishHour);
          if (startMinutes == null || endMinutes == null) continue;

          final actualStartMinutes = _roundDownToSlot(startMinutes);
          _markAppointmentSlots(
            actualStartMinutes,
            endMinutes,
            bookedSlotsSet,
            slotEndTimesMap,
          );
        }
      } catch (e) {
        debugPrint('Availability slots could not be loaded: $e');
      }

      try {
        final dayAppointments = _appointments.where((a) => 
          _isAppointmentDateMatch(a.startDate, _selectedDate) &&
          a.status != AppointmentStatus.cancelled &&
          a.status != AppointmentStatus.noShow
        ).toList();

        for (final appointment in dayAppointments) {
          final startHour = appointment.startHour;
          if (startHour.isEmpty) continue;

          final normalizedStartHour = _normalizeTime(startHour);
          final startMinutes = _timeToMinutes(normalizedStartHour);
          if (startMinutes == null) continue;

          final actualStartMinutes = _roundDownToSlot(startMinutes);
          final totalDurationMinutes = _roundUpToSlotInterval(
            _calculateDuration(
              appointment,
              normalizedStartHour,
              actualStartMinutes,
            ),
          );
          final endMinutes = _calculateEndMinutes(
            appointment,
            actualStartMinutes,
            totalDurationMinutes,
          );

          _markAppointmentSlots(
            actualStartMinutes,
            endMinutes,
            bookedSlotsSet,
            slotEndTimesMap,
          );
        }
      } catch (e) {
        debugPrint('Fallback appointment processing failed: $e');
      } finally {
        setState(() {
          _bookedSlots
            ..clear()
            ..addAll(bookedSlotsSet);
          _slotEndTimes
            ..clear()
            ..addAll(slotEndTimesMap);
          _isLoadingBookedSlots = false;
        });

        // Scroll to current time if viewing today
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentTime();
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBookedSlots = false;
      });
    }
  }

  void _scrollToCurrentTime() {
    if (!_timeSlotScrollController.hasClients) return;

    // Only scroll if viewing today
    final now = DateTime.now();
    if (_selectedDate.year != now.year ||
        _selectedDate.month != now.month ||
        _selectedDate.day != now.day) {
      // If not today, jump to start (00:00)
      _timeSlotScrollController.jumpTo(0);
      return;
    }

    final availableSlots = _getAvailableTimeSlots();
    if (availableSlots.isEmpty) return;

    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTimeInMinutes = currentHour * 60 + currentMinute;

    int targetIndex = 0;

    for (int i = 0; i < availableSlots.length; i++) {
      final slotParts = availableSlots[i].split(':');
      final slotHour = int.parse(slotParts[0]);
      final slotMinute = int.parse(slotParts[1]);
      final slotTimeInMinutes = slotHour * 60 + slotMinute;

      // Find the slot that is current or just after current time
      if (slotTimeInMinutes >= currentTimeInMinutes) {
        // Show context by starting slightly before (e.g. 1 slot before)
        targetIndex = (i > 0) ? i - 1 : 0;
        break;
      }
      // If we are past all slots, target the last one
      if (i == availableSlots.length - 1) {
        targetIndex = availableSlots.length - 1;
      }
    }

    // Slot width (70) + padding right (AppSpacing.sm = 8) = 78
    const double itemWidth = 70.0 + AppSpacing.sm;
    final double offset = targetIndex * itemWidth;

    _timeSlotScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  List<String> _getAvailableTimeSlots() {
    if (_branches.isEmpty || _selectedCompanyId == null) return [];
    
    final branch = _branches.firstWhere(
      (b) => b.id == _selectedCompanyId || b.companyId == _selectedCompanyId,
      orElse: () => _branches.first,
    );

    final is24Hours = branch.workingHours.containsKey('all') &&
        branch.workingHours['all'] == '7/24 Açık';

    final workingHours = _getWorkingHoursForSelectedDate(branch);
    String? openTime;
    String? closeTime;

    if (workingHours != null && !is24Hours) {
      openTime = workingHours['openTime'];
      closeTime = workingHours['closeTime'];
    }

    final timeSlots = _getTimeSlots(
      is24Hours: is24Hours,
      openTime: openTime,
      closeTime: closeTime,
    );

    return timeSlots;
  }

  List<String> _getTimeSlots(
      {bool is24Hours = false, String? openTime, String? closeTime}) {
    if (is24Hours) {
      final slots = <String>[];
      for (int minutes = 0;
          minutes < 24 * 60;
          minutes += _slotIntervalMinutes) {
        slots.add(_minutesToTime(minutes));
      }
      return slots;
    } else if (openTime != null && closeTime != null) {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final openTotalMinutes = openHour * 60 + openMinute;
      final closeTotalMinutes = closeHour * 60 + closeMinute;

      if (closeTotalMinutes <= openTotalMinutes) {
        return [];
      }

      final slots = <String>[];
      var currentMinutes = openTotalMinutes;

      while (currentMinutes < closeTotalMinutes) {
        slots.add(_minutesToTime(currentMinutes));
        currentMinutes += _slotIntervalMinutes;
      }

      return slots;
    } else {
      final slots = <String>[];
      final startMinutes = 9 * 60;
      final endMinutes = 18 * 60;
      for (int minutes = startMinutes;
          minutes < endMinutes;
          minutes += _slotIntervalMinutes) {
        slots.add(_minutesToTime(minutes));
      }
      return slots;
    }
  }

  Map<String, String>? _getWorkingHoursForSelectedDate(BranchModel branch) {
    if (branch.workingHours.isNotEmpty) {
      if (branch.workingHours.containsKey('all') &&
          branch.workingHours['all'] == '7/24 Açık') {
        return {
          'openTime': '00:00',
          'closeTime': '23:59',
          'isAlwaysOpen': 'true'
        };
      }

      final weekday = _selectedDate.weekday;
      final dayMap = {
        1: 'monday',
        2: 'tuesday',
        3: 'wednesday',
        4: 'thursday',
        5: 'friday',
        6: 'saturday',
        7: 'sunday',
      };

      final dayName = dayMap[weekday];
      if (dayName == null) return null;

      final hours = branch.workingHours[dayName];
      if (hours == null || hours.trim().isEmpty) return null;

      final normalized = hours.trim().toLowerCase();
      if (normalized.contains('kapalı') || normalized == 'closed') {
        return null;
      }

      String normalizedHours = hours.trim();
      List<String> parts;

      if (normalizedHours.contains(' - ')) {
        parts = normalizedHours.split(' - ');
      } else if (normalizedHours.contains('-')) {
        parts = normalizedHours.split('-');
      } else {
        return {'openTime': _weekdayOpenTime, 'closeTime': _weekdayCloseTime};
      }

      if (parts.length >= 2) {
        return {
          'openTime': parts[0].trim(),
          'closeTime': parts[1].trim(),
        };
      }
    }

    final weekday = _selectedDate.weekday;
    if (weekday == DateTime.sunday) return null;
    if (weekday == DateTime.saturday)
      return {'openTime': _saturdayOpenTime, 'closeTime': _saturdayCloseTime};
    return {'openTime': _weekdayOpenTime, 'closeTime': _weekdayCloseTime};
  }

  bool _isPastTime(String timeSlot) {
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeSlot.split(':')[0]),
      int.parse(timeSlot.split(':')[1]),
    );

    if (_selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year) {
      return selectedDateTime.isBefore(now);
    }
    if (_selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
        return true;
    }
    return false;
  }

  bool _isSlotBooked(String slot) {
    return _bookedSlots.contains(slot);
  }

  bool _isAppointmentDateMatch(
      String appointmentDateStr, DateTime selectedDate) {
    if (appointmentDateStr.isEmpty) return false;
    try {
      final dateStr = appointmentDateStr.contains(' ')
          ? appointmentDateStr.split(' ')[0]
          : appointmentDateStr;
      final appointmentDate = DateTime.tryParse(dateStr);
      if (appointmentDate == null) return false;
      return appointmentDate.year == selectedDate.year &&
          appointmentDate.month == selectedDate.month &&
          appointmentDate.day == selectedDate.day;
    } catch (_) {
      return false;
    }
  }

  int _calculateDuration(AppointmentModel appointment,
      String normalizedStartHour, int actualStartMinutes) {
    if (appointment.finishHour != null && appointment.finishHour!.isNotEmpty) {
      final normalizedFinishHour = _normalizeTime(appointment.finishHour!);
      final finishMinutes = _timeToMinutes(normalizedFinishHour);
      final startMinutes = _timeToMinutes(normalizedStartHour);

      if (finishMinutes != null && startMinutes != null) {
        final duration = finishMinutes - startMinutes;
        if (duration > 0) return duration;
      }
    }

    final totalDuration = appointment.services.fold<int>(
      0,
      (sum, service) => sum + (service.durationMinutes ?? _minDurationMinutes),
    );
    return totalDuration;
  }

  int _calculateEndMinutes(AppointmentModel appointment, int currentMinutes,
      int totalDurationMinutes) {
    if (appointment.finishHour != null && appointment.finishHour!.isNotEmpty) {
      final normalizedFinishHour = _normalizeTime(appointment.finishHour!);
      final finishMinutes = _timeToMinutes(normalizedFinishHour);
      if (finishMinutes != null) return finishMinutes;
    }
    return currentMinutes + totalDurationMinutes;
  }

  void _markAppointmentSlots(int startMinutes, int endMinutes,
      Set<String> bookedSlotsSet, Map<String, String> slotEndTimesMap) {
    final endTime = _minutesToTime(endMinutes);
    int currentMinutes = startMinutes;
    String? lastSlot;

    if (endMinutes <= currentMinutes) {
      final slotTime = _minutesToTime(currentMinutes);
      bookedSlotsSet.add(slotTime);
      lastSlot = slotTime;
    } else {
      while (currentMinutes < endMinutes) {
        final slotTime = _minutesToTime(currentMinutes);
        bookedSlotsSet.add(slotTime);
        lastSlot = slotTime;
        currentMinutes += _slotIntervalMinutes;
      }
    }

    if (lastSlot != null) {
      slotEndTimesMap[lastSlot] = endTime;
    }
  }

  String _normalizeTime(String time) {
    if (!time.contains(':')) return time;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  int? _timeToMinutes(String time) {
    final parts = _normalizeTime(time).split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _roundDownToSlot(int minutes) {
    final minute = minutes % 60;
    final roundedMinute =
        (minute ~/ _slotIntervalMinutes) * _slotIntervalMinutes;
    return (minutes ~/ 60) * 60 + roundedMinute;
  }

  int _roundUpToSlotInterval(int minutes) {
    if (minutes < _minDurationMinutes) return _minDurationMinutes;
    return ((minutes + _slotIntervalMinutes - 1) ~/ _slotIntervalMinutes) *
        _slotIntervalMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildDailySchedule(),
            // TEMPORARILY COMMENTED OUT - Company filter (only one branch now, auto-selected)
            // _buildCompanyFilter(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAppointmentsList(
                            _pendingAppointments, 'Bekleyen Randevu Yok'),
                        _buildAppointmentsList(
                            _activeAppointments, 'Aktif Randevu Yok'),
                        _buildAppointmentsList(
                            _completedAppointments, 'Tamamlanan Randevu Yok'),
                        _buildAppointmentsList(
                            _cancelledAppointments, 'İptal Edilen Randevu Yok'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySchedule() {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Program',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateHelper.formatToApiDate(_selectedDate),
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tarih Seç',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          SizedBox(
            height: 60,
            child: _isLoadingBookedSlots
                ? const Center(child: CircularProgressIndicator())
                : _buildTimelineSlotsList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildTimelineSlotsList() {
    final availableTimeSlots = _getAvailableTimeSlots();

    if (availableTimeSlots.isEmpty) {
      return Center(
        child: Text(
          'Bu tarihte uygun saat yok',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _timeSlotScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = availableTimeSlots[index];
        final isBooked = _isSlotBooked(timeSlot);
        final isPast = _isPastTime(timeSlot);

        // Colors
        Color bgColor;
        Color textColor;
        Color borderColor;

        if (isBooked) {
          bgColor = AppColors.error.withValues(alpha: 0.1);
          textColor = AppColors.error;
          borderColor = AppColors.error.withValues(alpha: 0.3);
        } else if (isPast) {
          // Grey out past time slots
          bgColor = AppColors.backgroundSecondary.withValues(alpha: 0.3);
          textColor = AppColors.textTertiary;
          borderColor = AppColors.border.withValues(alpha: 0.3);
        } else {
          bgColor = AppColors.success.withValues(alpha: 0.1);
          textColor = AppColors.success;
          borderColor = AppColors.success.withValues(alpha: 0.3);
        }

        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (isBooked || isPast)
                  ? null
                  : () => _showCreateAppointmentDialog(
                        selectedDate: DateHelper.formatToApiDate(_selectedDate),
                        selectedHour: timeSlot,
                      ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  timeSlot,
                  style: AppTypography.body2.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // TEMPORARILY COMMENTED OUT - Company filter (only one branch now, auto-selected)
  // Widget _buildCompanyFilter() {
  //   if (_branches.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   return Container(
  //     padding: const EdgeInsets.symmetric(
  //       horizontal: AppSpacing.screenHorizontal,
  //       vertical: AppSpacing.sm,
  //     ),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(
  //         horizontal: AppSpacing.lg,
  //         vertical: AppSpacing.sm,
  //       ),
  //       decoration: BoxDecoration(
  //         color: AppColors.surface,
  //         borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
  //         border: Border.all(color: AppColors.border, width: 1),
  //         boxShadow: [
  //           BoxShadow(
  //             color: AppColors.shadow,
  //             blurRadius: 8,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(AppSpacing.xs),
  //             decoration: BoxDecoration(
  //               gradient: const LinearGradient(
  //                 colors: [AppColors.primary, AppColors.primaryLight],
  //               ),
  //               borderRadius: BorderRadius.circular(
  //                 AppSpacing.radiusSm,
  //               ),
  //             ),
  //             child: const Icon(
  //               Icons.filter_list,
  //               size: 18,
  //               color: Colors.white,
  //             ),
  //           ),
  //           const SizedBox(width: AppSpacing.md),
  //           Expanded(
  //             child: DropdownButtonHideUnderline(
  //               child: DropdownButton<String>(
  //                 value: _selectedCompanyId,
  //                 hint: Text(
  //                   AppLocalizations.of(context)!.allBranches,
  //                   style: AppTypography.body2.copyWith(
  //                     color: AppColors.textSecondary,
  //                   ),
  //                 ),
  //                 isExpanded: true,
  //                 icon: Icon(
  //                   Icons.arrow_drop_down,
  //                   color: AppColors.textSecondary,
  //                 ),
  //                 items: [
  //                   DropdownMenuItem<String>(
  //                     value: null,
  //                     child: Text(
  //                       AppLocalizations.of(context)!.allBranches,
  //                       style: AppTypography.body2.copyWith(
  //                         color: AppColors.textPrimary,
  //                       ),
  //                     ),
  //                   ),
  //                   ..._branches.map((branch) {
  //                     return DropdownMenuItem<String>(
  //                       value: branch.id,
  //                       child: Text(
  //                         branch.name,
  //                         style: AppTypography.body2.copyWith(
  //                           color: AppColors.textPrimary,
  //                         ),
  //                       ),
  //                     }),
  //                   }).toList(),
  //                 ],
  //                 onChanged: _onCompanyFilterChanged,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: AppTypography.bodySmall,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        tabs: [
          Tab(text: 'Onay Bekleyen (${_pendingAppointments.length})'),
          Tab(text: 'Aktif (${_activeAppointments.length})'),
          Tab(text: 'Tamamlananlar'),
          Tab(text: 'İptal Edilenler'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.appointmentsLoading,
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
      List<AppointmentModel> appointments, String emptyMessage) {
    const double navHeight = 72; // Matches ModernNavBar height
    final double bottomSafePadding =
        MediaQuery.of(context).padding.bottom + navHeight + AppSpacing.xxxl;

    if (appointments.isEmpty) {
      // Wrap empty state with RefreshIndicator too
      return RefreshIndicator(
        onRefresh: () async {
          await _loadAppointments();
          await _loadBookedSlots();
        },
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomSafePadding),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      emptyMessage,
                      style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadAppointments();
        await _loadBookedSlots();
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.screenHorizontal,
          AppSpacing.screenHorizontal,
          bottomSafePadding,
        ),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    Color statusColor;
    Color statusColorSingle;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = AppColors.success;
        statusColorSingle = AppColors.primary;
        break;
      case AppointmentStatus.pending:
        statusColor = AppColors.warning;
        statusColorSingle = AppColors.primary;
        break;
      case AppointmentStatus.completed:
        statusColor = AppColors.textSecondary;
        statusColorSingle = AppColors.primary;
        break;
      case AppointmentStatus.cancelled:
        statusColor = AppColors.error;
        statusColorSingle = AppColors.primary;
        break;
      case AppointmentStatus.inProgress:
        statusColor = AppColors.info;
        statusColorSingle = AppColors.primary;
        break;
      case AppointmentStatus.noShow:
        statusColor = AppColors.textTertiary;
        statusColorSingle = AppColors.primary;
        break;
    }

    // We don't have a global index here, so animation might just be standard
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.backgroundSecondary],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          onTap: () => _showAppointmentDetails(appointment),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Customer name + Status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        appointment.fullCustomerName.trim().isEmpty 
                            ? 'Müşteri' 
                            : appointment.fullCustomerName,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: statusColorSingle,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        appointment.statusText,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                if (appointment.isRejected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Bu randevu reddedildi.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Info rows with gradient icon containers
                if (appointment.branchName != null)
                  _buildInfoRow(
                    Icons.business,
                    appointment.branchName!,
                    [AppColors.success, AppColors.successLight],
                  ),

                _buildInfoRow(
                  Icons.access_time,
                  _formatDateTime(
                    appointment.startDate,
                    appointment.startHour,
                  ),
                  [AppColors.primary, AppColors.primaryLight],
                ),

                if (appointment.services.isNotEmpty)
                  _buildInfoRow(
                    Icons.content_cut,
                    appointment.services
                        .map((s) => _parseServiceName(s.name, context))
                        .join(', '),
                    [AppColors.primary, AppColors.primaryLight],
                    maxLines: 2,
                  ),

                if (appointment.totalPrice != null)
                  _buildInfoRow(
                    Icons.attach_money,
                    '${appointment.totalPrice!.toStringAsFixed(0)} ₺',
                    [AppColors.primary, AppColors.primaryLight],
                  ),

                if (appointment.customerPhone != null)
                  _buildInfoRow(
                    Icons.phone,
                    appointment.customerPhone!,
                    [AppColors.primary, AppColors.primaryLight],
                    onTap: () => _makePhoneCall(appointment.customerPhone!),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Action Buttons - Two main buttons + overflow menu
                Row(
                  children: [
                    // Detaylar button - always visible
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primaryLight.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            onTap: () => _showAppointmentDetails(
                              appointment,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    AppLocalizations.of(context)!.details,
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Onayla button - for pending appointments
                    if (appointment.canBeApproved) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withValues(alpha: 0.1),
                                AppColors.successLight.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            border: Border.all(
                              color: AppColors.success,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                              onTap: _isApproving(appointment.id)
                                  ? null
                                  : () => _approveAppointment(
                                        appointment,
                                      ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: _isApproving(appointment.id)
                                    ? const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.success,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.xs,
                                          ),
                                          Text(
                                            'Onayla',
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Kodu Gir button - for confirmed appointments
                    if (_shouldShowVerifyButton(appointment)) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warning.withValues(alpha: 0.1),
                                AppColors.warning.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            border: Border.all(
                              color: AppColors.warning,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                              onTap: _isStarting(appointment.id)
                                  ? null
                                  : () => _showVerifyCodeDialog(
                                        appointment,
                                      ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: _isStarting(appointment.id)
                                    ? const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.verified_user,
                                            size: 18,
                                            color: AppColors.warning,
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.xs,
                                          ),
                                          Text(
                                            'Kodu Gir',
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Bitir button - for in-progress appointments
                    if (appointment.status == AppointmentStatus.inProgress) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.success.withValues(alpha: 0.1),
                                AppColors.successLight.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusLg,
                            ),
                            border: Border.all(
                              color: AppColors.success,
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                              onTap: _isCompleting(appointment.id)
                                  ? null
                                  : () => _completeAppointment(appointment),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: _isCompleting(appointment.id)
                                    ? const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.success,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.xs,
                                          ),
                                          Text(
                                            'Bitir',
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Three dot menu for secondary actions
                    if (_shouldShowCompleteButton(appointment) || appointment.canBeCancelled) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          color: AppColors.surface,
                          elevation: 8,
                          onSelected: (value) {
                            if (value == 'complete') {
                              _completeAppointment(appointment);
                            } else if (value == 'cancel') {
                              _showCancelConfirmation(appointment);
                            }
                          },
                          itemBuilder: (context) => [
                            if (_shouldShowCompleteButton(appointment))
                              PopupMenuItem<String>(
                                value: 'complete',
                                enabled: !_isCompleting(appointment.id),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.task_alt,
                                      size: 20,
                                      color: _isCompleting(appointment.id)
                                          ? AppColors.textTertiary
                                          : AppColors.success,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      'Tamamla',
                                      style: AppTypography.body2.copyWith(
                                        color: _isCompleting(appointment.id)
                                            ? AppColors.textTertiary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (appointment.canBeCancelled)
                              PopupMenuItem<String>(
                                value: 'cancel',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cancel_outlined,
                                      size: 20,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      'İptal Et',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    List<Color> gradientColors, {
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    Widget content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: content,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: content,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Telefon numarasından boşlukları ve özel karakterleri temizle
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Eğer + ile başlamıyorsa, Türkiye için +90 ekle
    String phoneUri;
    if (cleanedPhone.startsWith('+')) {
      phoneUri = cleanedPhone;
    } else if (cleanedPhone.startsWith('90')) {
      phoneUri = '+$cleanedPhone';
    } else if (cleanedPhone.startsWith('0')) {
      // 0 ile başlıyorsa, 0'ı kaldır ve +90 ekle
      phoneUri = '+90${cleanedPhone.substring(1)}';
    } else {
      // Direkt numara ise +90 ekle
      phoneUri = '+90$cleanedPhone';
    }

    final uri = Uri.parse('tel:$phoneUri');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefon araması başlatılamadı'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Randevu oluşturma dialog'u
class CreateAppointmentDialog extends StatefulWidget {
  final List<BranchModel> branches;
  final String? selectedDate;
  final String? selectedHour;

  const CreateAppointmentDialog({
    required this.branches,
    this.selectedDate,
    this.selectedHour,
  });

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerLastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '90');
  final _cardNumberController = TextEditingController();
  final _cardExpirationMonthController = TextEditingController();
  final _cardExpirationYearController = TextEditingController();
  final _cardCvcController = TextEditingController();

  String? _selectedBranchId;
  String? _selectedCompanyId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedHour;
  List<CompanyServiceModel> _availableServices = [];
  List<CompanyServiceModel> _selectedServices = [];
  String _selectedPaymentMethod = 'cash'; // cash, creditCard, online

  // Employee selection
  String? _selectedUserId;
  List<CompanyUserModel> _availableEmployees = [];
  bool _isLoadingEmployees = false;

  final AppointmentUseCases _appointmentUseCases =
      AppointmentUseCases(AppointmentRepositoryImpl());
  final CompanyServiceUseCases _companyServiceUseCases = CompanyServiceUseCases(
    CompanyServiceRepositoryImpl(),
  );
  final CompanyUserApiService _companyUserApiService = CompanyUserApiService();

  // Time slot constants
  static const int _slotIntervalMinutes = 30;
  static const int _minDurationMinutes = 30;
  static const String _weekdayOpenTime = '09:00';
  static const String _weekdayCloseTime = '18:00';
  static const String _saturdayOpenTime = '10:00';
  static const String _saturdayCloseTime = '16:00';

  final List<String> _bookedSlots = [];
  final Map<String, String> _slotEndTimes = {};
  bool _isLoadingBookedSlots = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      try {
        _selectedDate = DateTime.parse(widget.selectedDate!);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
    _selectedHour = widget.selectedHour;
    if (widget.branches.isNotEmpty) {
      final firstBranch = widget.branches.first;
      _selectedBranchId = firstBranch.id;
      _selectedCompanyId = firstBranch.companyId ?? firstBranch.id;
    }
    _loadServices();
    _loadBookedSlots();
    _loadEmployees();
  }

  Future<void> _loadServices() async {
    try {
      final services = await _companyServiceUseCases.getCompanyServices();
      setState(() {
        _availableServices = services;
      });
    } catch (e) {
      setState(() {
        _availableServices = [];
      });
    }
  }

  Future<void> _loadEmployees() async {
    if (_selectedCompanyId == null) return;
    
    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await _companyUserApiService.getCompanyEmployees(_selectedCompanyId!);
      setState(() {
        _availableEmployees = employees;
        // İlk çalışanı varsayılan olarak seç
        if (_availableEmployees.isNotEmpty && _selectedUserId == null) {
          _selectedUserId = _availableEmployees.first.userId;
        }
      });
    } catch (e) {
      debugPrint('Çalışanlar yüklenirken hata: $e');
    } finally {
      setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerLastNameController.dispose();
    _phoneController.dispose();
    _countryCodeController.dispose();
    _cardNumberController.dispose();
    _cardExpirationMonthController.dispose();
    _cardExpirationYearController.dispose();
    _cardCvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Yeni Randevu',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Müşteri Adı
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Müşteri Adı (Opsiyonel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Müşteri Soyadı
                      TextFormField(
                        controller: _customerLastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Müşteri Soyadı',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Telefon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: TextFormField(
                              controller: _countryCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Kod',
                                border: OutlineInputBorder(),
                                prefixText: '+',
                                counterText: '',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Gerekli';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Flexible(
                            flex: 5,
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon (Opsiyonel)',
                                border: OutlineInputBorder(),
                                hintText: '5XX XXX XX XX',
                                counterText: '',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                // Telefon opsiyonel, ama girildiyse doğru format olmalı
                                if (value != null && value.isNotEmpty) {
                                  if (!_isValidPhoneFormat(value)) {
                                    return '10 haneli numara giriniz';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Şube Seçimi
                      if (widget.branches.length > 1) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedBranchId,
                          decoration: const InputDecoration(
                            labelText: 'Şube',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.branches.map((branch) {
                            return DropdownMenuItem<String>(
                              value: branch.id,
                              child: Text(branch.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBranchId = value;
                              if (value != null) {
                                final branch = widget.branches.firstWhere(
                                  (b) => b.id == value,
                                  orElse: () => widget.branches.first,
                                );
                                _selectedCompanyId =
                                    branch.companyId ?? branch.id;
                              }
                            });
                            _loadBookedSlots(); // Şube değişince slotları yeniden yükle
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şube seçimi gereklidir';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Çalışan Seçimi
                      if (_isLoadingEmployees)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_availableEmployees.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Çalışan',
                            border: OutlineInputBorder(),
                          ),
                          items: _availableEmployees.map((employee) {
                            return DropdownMenuItem<String>(
                              value: employee.userId,
                              child: Text('${employee.userDetail.name} ${employee.userDetail.surname}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedUserId = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Çalışan seçimi zorunludur';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Tarih Seçimi
                      ListTile(
                        title: Text(
                          'Tarih: ${DateHelper.formatToApiDate(_selectedDate)}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectDate,
                        tileColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Hizmet Seçimi
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            'Hizmetler (${_selectedServices.length} seçildi)',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          initiallyExpanded: false,
                          tilePadding: EdgeInsets.zero,
                          children: [
                            if (_availableServices.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                                child: Text(
                                  'Hizmetler yükleniyor...',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                ),
                                child: Column(
                                  children: _availableServices.map((service) {
                                    final isSelected = _selectedServices.any(
                                      (s) => s.id == service.id,
                                    );
                                    return CheckboxListTile(
                                      title: Text(_parseServiceName(
                                          service.serviceName, context)),
                                      subtitle: Text(
                                        '₺${service.minPrice.toStringAsFixed(0)} • ${service.duration} dk',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedServices.add(service);
                                          } else {
                                            _selectedServices.removeWhere(
                                              (s) => s.id == service.id,
                                            );
                                          }
                                        });
                                      },
                                      activeColor: AppColors.primary,
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Ödeme Yöntemi Seçimi (Şirket tarafında sadece fiziki ödeme seçenekleri)
                      Text(
                        'Ödeme Yöntemi',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPaymentOption(
                        'cash',
                        'Nakit',
                        'Salon başında ödeme yapın',
                        Icons.payments_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPaymentOption(
                        'creditCard',
                        'Kredi/Banka Kartı',
                        'Salon başında kart ile ödeme yapın',
                        Icons.credit_card,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // cash ve creditCard fiziki mağazada ödeme için - kart bilgileri gerekmiyor
                      // online seçildiğinde backend ödeme sistemine yönlendirecek
                      // if (_selectedPaymentMethod == 'creditCard') ...[
                      //   _buildCardForm(),
                      //   const SizedBox(height: AppSpacing.lg),
                      // ],

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),

              // Kaydet Butonu
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: const Text('Randevu Oluştur'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
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
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kart Bilgileri',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Kart Numarası',
              border: OutlineInputBorder(),
              hintText: '1234 5678 9012 3456',
            ),
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kart numarası zorunludur';
              }
              if (value.length < 13 || value.length > 19) {
                return 'Geçerli bir kart numarası giriniz';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cardExpirationMonthController,
                  decoration: const InputDecoration(
                    labelText: 'Ay',
                    border: OutlineInputBorder(),
                    hintText: 'MM',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ay zorunludur';
                    }
                    final month = int.tryParse(value);
                    if (month == null || month < 1 || month > 12) {
                      return '01-12 arası';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cardExpirationYearController,
                  decoration: const InputDecoration(
                    labelText: 'Yıl',
                    border: OutlineInputBorder(),
                    hintText: 'YY',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yıl zorunludur';
                    }
                    if (value.length != 2) {
                      return '2 haneli yıl';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cardCvcController,
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    border: OutlineInputBorder(),
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'CVC zorunludur';
                    }
                    if (value.length < 3 || value.length > 4) {
                      return '3-4 haneli CVC';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    final availableTimeSlots = _getAvailableTimeSlots();

    if (availableTimeSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Bu tarih için uygun saat bulunamadı.',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columns
        childAspectRatio: 1.8,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: availableTimeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = availableTimeSlots[index];
        final isSelected = _selectedHour == timeSlot;

        final isBooked = _isSlotBooked(timeSlot);
        final isPastTime = _isPastTime(timeSlot);
        final isOutsideWorkingHours = _isOutsideWorkingHours(timeSlot);

        // Şirket tarafında "Yetersiz" durumunu kontrol etmeyebiliriz,
        // çünkü şirket her türlü randevu girebilmeli belki de?
        // Ama kullanıcı deneyimi "müşteri sistemi gibi" dendiği için
        // çakışmaları engellemek daha doğru olur.
        // Ancak süre henüz seçilmemiş olabilir (hizmetler seçilmediyse).
        // Bu yüzden süre kontrolünü sadece hizmet seçiliyse yapabiliriz veya yapmayız.
        // Müşteri tarafında hizmetler önce seçiliyor. Burada hizmetler en sonda da seçilebilir.
        // Şimdilik sadece "Dolu" kontrolü yapalım.

        final isDisabled = isBooked || isPastTime || isOutsideWorkingHours;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: isDisabled
                ? null
                : () => setState(() => _selectedHour = timeSlot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isDisabled
                        ? AppColors.backgroundSecondary.withValues(alpha: 0.5)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isDisabled
                          ? AppColors.border.withValues(alpha: 0.3)
                          : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  timeSlot,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? Colors.white
                        : isDisabled
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedHour = null; // Reset time when date changes
      });
      _loadBookedSlots();
    }
  }

  bool _isValidPhoneFormat(String value) {
    return value.length == 10;
  }

  String _formatPhoneWithCountryCode() {
    final countryCode = _countryCodeController.text.trim();
    final phone = _phoneController.text.trim();

    if (countryCode.isEmpty || phone.isEmpty) {
      throw Exception('Telefon numarası boş olamaz');
    }

    return '$countryCode $phone';
  }

  // --- Logic copied and adapted from AppointmentBookingPage ---

  Future<void> _loadBookedSlots() async {
    if (_isLoadingBookedSlots || _selectedBranchId == null) return;

    setState(() {
      _isLoadingBookedSlots = true;
      _bookedSlots.clear();
    });

    try {
      final bookedSlotsSet = <String>{};
      final slotEndTimesMap = <String, String>{};
      final formattedDate = DateHelper.formatToApiDate(_selectedDate);
      final availabilityCompanyId = _selectedCompanyId ?? _selectedBranchId!;

      // 1) Önce yeni availability endpoint'inden dolu saat aralıklarını çek
      try {
        final availabilitySlots =
            await _appointmentUseCases.getAppointmentAvailability(
          companyId: availabilityCompanyId,
          date: formattedDate,
          userId: _selectedUserId,
        );

        for (final slot in availabilitySlots) {
          final startMinutes = _timeToMinutes(slot.normalizedStartHour);
          final endMinutes = _timeToMinutes(slot.normalizedFinishHour);
          if (startMinutes == null || endMinutes == null) continue;

          final actualStartMinutes = _roundDownToSlot(startMinutes);
          _markAppointmentSlots(
            actualStartMinutes,
            endMinutes,
            bookedSlotsSet,
            slotEndTimesMap,
          );
        }
      } catch (e) {
        debugPrint('Availability slots could not be loaded: $e');
      }

      // 2) Ekstra güvenlik için mevcut randevuları da kontrol etmeye devam et
      try {
        final appointments = await _appointmentUseCases.fetchAppointments(
          startDate: null,
          companyId: _selectedBranchId,
        );

        final activeAppointments = appointments
            .where((a) =>
                a.status != AppointmentStatus.cancelled &&
                a.status != AppointmentStatus.noShow)
            .toList();

        for (final appointment in activeAppointments) {
          if (!_isAppointmentDateMatch(appointment.startDate, _selectedDate)) {
            continue;
          }

          final startHour = appointment.startHour;
          if (startHour.isEmpty) continue;

          final normalizedStartHour = _normalizeTime(startHour);
          final startMinutes = _timeToMinutes(normalizedStartHour);
          if (startMinutes == null) continue;

          final actualStartMinutes = _roundDownToSlot(startMinutes);
          final totalDurationMinutes = _roundUpToSlotInterval(
            _calculateDuration(
              appointment,
              normalizedStartHour,
              actualStartMinutes,
            ),
          );
          final endMinutes = _calculateEndMinutes(
            appointment,
            actualStartMinutes,
            totalDurationMinutes,
          );

          _markAppointmentSlots(
            actualStartMinutes,
            endMinutes,
            bookedSlotsSet,
            slotEndTimesMap,
          );
        }
      } catch (e) {
        debugPrint('Fallback appointment fetch failed: $e');
      } finally {
        setState(() {
          _bookedSlots
            ..clear()
            ..addAll(bookedSlotsSet);
          _slotEndTimes
            ..clear()
            ..addAll(slotEndTimesMap);
          _isLoadingBookedSlots = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBookedSlots = false;
      });
    }
  }

  List<String> _getAvailableTimeSlots() {
    final branch = widget.branches.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => widget.branches.first,
    );

    final is24Hours = branch.workingHours.containsKey('all') &&
        branch.workingHours['all'] == '7/24 Açık';

    final workingHours = _getWorkingHoursForSelectedDate(branch);
    String? openTime;
    String? closeTime;

    if (workingHours != null && !is24Hours) {
      openTime = workingHours['openTime'];
      closeTime = workingHours['closeTime'];
    }

    final timeSlots = _getTimeSlots(
      is24Hours: is24Hours,
      openTime: openTime,
      closeTime: closeTime,
    );

    // Filter out past time slots
    return timeSlots.where((slot) => !_isPastTime(slot)).toList();
  }

  List<String> _getTimeSlots(
      {bool is24Hours = false, String? openTime, String? closeTime}) {
    if (is24Hours) {
      final slots = <String>[];
      for (int minutes = 0;
          minutes < 24 * 60;
          minutes += _slotIntervalMinutes) {
        slots.add(_minutesToTime(minutes));
      }
      return slots;
    } else if (openTime != null && closeTime != null) {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final openTotalMinutes = openHour * 60 + openMinute;
      final closeTotalMinutes = closeHour * 60 + closeMinute;

      if (closeTotalMinutes <= openTotalMinutes) {
        return [];
      }

      final slots = <String>[];
      var currentMinutes = openTotalMinutes;

      while (currentMinutes < closeTotalMinutes) {
        slots.add(_minutesToTime(currentMinutes));
        currentMinutes += _slotIntervalMinutes;
      }

      return slots;
    } else {
      // Default fallback
      final slots = <String>[];
      final startMinutes = 9 * 60;
      final endMinutes = 18 * 60;
      for (int minutes = startMinutes;
          minutes < endMinutes;
          minutes += _slotIntervalMinutes) {
        slots.add(_minutesToTime(minutes));
      }
      return slots;
    }
  }

  Map<String, String>? _getWorkingHoursForSelectedDate(BranchModel branch) {
    if (branch.workingHours.isNotEmpty) {
      if (branch.workingHours.containsKey('all') &&
          branch.workingHours['all'] == '7/24 Açık') {
        return {
          'openTime': '00:00',
          'closeTime': '23:59',
          'isAlwaysOpen': 'true'
        };
      }

      final weekday = _selectedDate.weekday;
      final dayMap = {
        1: 'monday',
        2: 'tuesday',
        3: 'wednesday',
        4: 'thursday',
        5: 'friday',
        6: 'saturday',
        7: 'sunday',
      };

      final dayName = dayMap[weekday];
      if (dayName == null) return null;

      final hours = branch.workingHours[dayName];
      if (hours == null || hours.trim().isEmpty) return null;

      final normalized = hours.trim().toLowerCase();
      if (normalized.contains('kapalı') || normalized == 'closed') {
        return null;
      }

      String normalizedHours = hours.trim();
      List<String> parts;

      if (normalizedHours.contains(' - ')) {
        parts = normalizedHours.split(' - ');
      } else if (normalizedHours.contains('-')) {
        parts = normalizedHours.split('-');
      } else {
        return {'openTime': _weekdayOpenTime, 'closeTime': _weekdayCloseTime};
      }

      if (parts.length >= 2) {
        return {
          'openTime': parts[0].trim(),
          'closeTime': parts[1].trim(),
        };
      }
    }

    // Fallback logic
    final weekday = _selectedDate.weekday;
    if (weekday == DateTime.sunday) return null;
    if (weekday == DateTime.saturday)
      return {'openTime': _saturdayOpenTime, 'closeTime': _saturdayCloseTime};
    return {'openTime': _weekdayOpenTime, 'closeTime': _weekdayCloseTime};
  }

  bool _isPastTime(String timeSlot) {
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeSlot.split(':')[0]),
      int.parse(timeSlot.split(':')[1]),
    );

    if (_selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year) {
      return selectedDateTime.isBefore(now);
    }
    return false;
  }

  bool _isOutsideWorkingHours(String timeSlot) {
    if (_selectedBranchId == null) return true;
    final branch = widget.branches.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => widget.branches.first,
    );
    final workingHours = _getWorkingHoursForSelectedDate(branch);

    if (workingHours == null) return true;
    if (workingHours['isAlwaysOpen'] == 'true') return false;

    final timeParts = timeSlot.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final timeInMinutes = hour * 60 + minute;

    final openTimeParts = workingHours['openTime']!.split(':');
    final openHour = int.parse(openTimeParts[0]);
    final openMinute = int.parse(openTimeParts[1]);
    final openTimeInMinutes = openHour * 60 + openMinute;

    final closeTimeParts = workingHours['closeTime']!.split(':');
    final closeHour = int.parse(closeTimeParts[0]);
    final closeMinute = int.parse(closeTimeParts[1]);
    final closeTimeInMinutes = closeHour * 60 + closeMinute;

    return timeInMinutes < openTimeInMinutes ||
        timeInMinutes >= closeTimeInMinutes;
  }

  bool _isSlotBooked(String slot) {
    return _bookedSlots.contains(slot);
  }

  // bool _isEndTimeSlot(String slot) {
  //   return _slotEndTimes.values.contains(slot);
  // }

  bool _isAppointmentDateMatch(
      String appointmentDateStr, DateTime selectedDate) {
    if (appointmentDateStr.isEmpty) return false;
    try {
      final dateStr = appointmentDateStr.contains(' ')
          ? appointmentDateStr.split(' ')[0]
          : appointmentDateStr;
      final appointmentDate = DateTime.tryParse(dateStr);
      if (appointmentDate == null) return false;
      return appointmentDate.year == selectedDate.year &&
          appointmentDate.month == selectedDate.month &&
          appointmentDate.day == selectedDate.day;
    } catch (_) {
      return false;
    }
  }

  int _calculateDuration(AppointmentModel appointment,
      String normalizedStartHour, int actualStartMinutes) {
    if (appointment.finishHour != null && appointment.finishHour!.isNotEmpty) {
      final normalizedFinishHour = _normalizeTime(appointment.finishHour!);
      final finishMinutes = _timeToMinutes(normalizedFinishHour);
      final startMinutes = _timeToMinutes(normalizedStartHour);

      if (finishMinutes != null && startMinutes != null) {
        final duration = finishMinutes - startMinutes;
        if (duration > 0) return duration;
      }
    }

    final totalDuration = appointment.services.fold<int>(
      0,
      (sum, service) => sum + (service.durationMinutes ?? _minDurationMinutes),
    );
    return totalDuration;
  }

  int _calculateEndMinutes(AppointmentModel appointment, int currentMinutes,
      int totalDurationMinutes) {
    if (appointment.finishHour != null && appointment.finishHour!.isNotEmpty) {
      final normalizedFinishHour = _normalizeTime(appointment.finishHour!);
      final finishMinutes = _timeToMinutes(normalizedFinishHour);
      if (finishMinutes != null) return finishMinutes;
    }
    return currentMinutes + totalDurationMinutes;
  }

  void _markAppointmentSlots(int startMinutes, int endMinutes,
      Set<String> bookedSlotsSet, Map<String, String> slotEndTimesMap) {
    final endTime = _minutesToTime(endMinutes);
    int currentMinutes = startMinutes;
    String? lastSlot;

    if (endMinutes <= currentMinutes) {
      final slotTime = _minutesToTime(currentMinutes);
      bookedSlotsSet.add(slotTime);
      lastSlot = slotTime;
    } else {
      while (currentMinutes < endMinutes) {
        final slotTime = _minutesToTime(currentMinutes);
        bookedSlotsSet.add(slotTime);
        lastSlot = slotTime;
        currentMinutes += _slotIntervalMinutes;
      }
    }

    if (lastSlot != null) {
      slotEndTimesMap[lastSlot] = endTime;
    }
  }

  String _adjustStartHourForBackend(String selectedHour) {
    // Seçilen saat 17:01 gibi bir dolu slot başlangıcı mı? (Slotlar 30 dk aralıklı olduğu için bu nadirdir ama kontrol edelim)
    // Asıl sorun: Dolu slotlar x:00 ve x:30 başlıyor.
    // Eğer seçilen saat (örn 17:00) bir randevunun bitiş saatiyse ve sistem çakışmayı engellemek için +1 dk ekliyorsa
    // bu durumda backend'e 17:01 gidiyor olabilir.
    // Ancak backend tam saat (veya boşluklu saat) bekliyor olabilir.

    // Eğer seçilen saat, bir önceki randevunun tam bitiş saatine denk geliyorsa +1 dakika eklemiştik.
    // Ama yeni availability mantığında zaten dolu slotları gri yaptığımız için,
    // kullanıcının seçebildiği her saat "başlangıç saati" olarak uygundur.
    // Dolayısıyla burada artık +1 dakika eklemeye gerek olmayabilir.
    // Yine de eski mantığı tamamen kaldırmadan önce, seçilen saatin "dolu slot bitişi" olup olmadığını kontrol edelim.

    // Kullanıcı zaten sadece boş slotları seçebiliyor.
    // Seçilen slot 17:00 ise ve bu slot boşsa, backend'e 17:00 gitmeli.
    // Eğer 17:00 dolu olsaydı zaten seçemezdi.
    // Tek istisna: Bir randevu 16:00-17:00 arası ise, 17:00 slotu serbesttir.
    // Bu durumda 17:00 seçilebilir. Backend bunu "çakışma" sayıyorsa +1 dk gerekir.
    // Ama genelde [start, end) mantığı varsa 17:00 çakışmaz.

    // Gelen hata "Oluşturulurken hata oluştu" -> muhtemelen backend validasyonu veya çakışma.
    // Log'da giden saat: 17:31. Demek ki +1 dk eklenmiş.
    // Eğer backend 30 dakikalık slotlara katıysa (00 veya 30 bekliyorsa) 17:31'i kabul etmiyor olabilir.

    // Şimdilik bu metodu pasif hale getirip tam saati gönderelim.
    // Eğer çakışma hatası alırsak tekrar değerlendiririz.

    // if (!_isEndTimeSlot(selectedHour)) return selectedHour;
    // final minutes = _timeToMinutes(selectedHour);
    // if (minutes == null) return selectedHour;
    // return _minutesToTime(minutes + 1);

    return selectedHour;
  }

  // Helper conversions
  String _normalizeTime(String time) {
    if (!time.contains(':')) return time;
    final parts = time.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : time;
  }

  int? _timeToMinutes(String time) {
    final parts = _normalizeTime(time).split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int _roundDownToSlot(int minutes) {
    final minute = minutes % 60;
    final roundedMinute =
        (minute ~/ _slotIntervalMinutes) * _slotIntervalMinutes;
    return (minutes ~/ 60) * 60 + roundedMinute;
  }

  int _roundUpToSlotInterval(int minutes) {
    if (minutes < _minDurationMinutes) return _minDurationMinutes;
    return ((minutes + _slotIntervalMinutes - 1) ~/ _slotIntervalMinutes) *
        _slotIntervalMinutes;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksik Bilgi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Lütfen hatalı alanları düzeltiniz');
      return;
    }

    if (_selectedBranchId == null && _selectedCompanyId == null) {
      _showErrorDialog('Lütfen bir şube seçin');
      return;
    }

    // Hizmet seçimi opsiyonel
    // if (_selectedServices.isEmpty) { ... } -> Kaldırıldı

    if (_selectedHour == null) {
      _showErrorDialog('Lütfen bir saat seçin');
      return;
    }

    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      _showErrorDialog('Lütfen bir çalışan seçin');
      return;
    }

    // cash ve creditCard fiziki mağazada ödeme için - kart bilgileri kontrolü gerekmiyor
    // online seçildiğinde backend ödeme sistemine yönlendirecek

    // Seçilen hizmetleri ServiceInfo formatına çevir
    final services = _selectedServices.map((service) {
      return ServiceInfo(
        id: service.serviceId,
        name: service.serviceName ?? 'Hizmet',
        price: service.minPrice,
        durationMinutes: service.duration,
      );
    }).toList();

    // Telefon numarasını müşteri tarafıyla aynı formatta hazırla
    String formattedPhone = '';
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isNotEmpty) {
      try {
        formattedPhone = _formatPhoneWithCountryCode();
      } catch (e) {
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
        return;
      }
    }

    // Müşteri tarafıyla aynı format: price.toStringAsFixed(0)
    final servicesPayload = services.map((service) {
      return {
        'id': service.id.toString(),
        'price': service.price.toStringAsFixed(0),
      };
    }).toList();

    final adjustedStartHour = _adjustStartHourForBackend(_selectedHour!);

    final appointmentData = {
      'companyId': (_selectedCompanyId ?? _selectedBranchId).toString(),
      'userId': _selectedUserId,
      'customerName': _customerNameController.text.trim(), // Boş olabilir
      'customerLastName': _customerLastNameController.text.trim(),
      'customerPhone': formattedPhone, // Boş olabilir
      'startDate': DateHelper.formatToApiDate(_selectedDate),
      'startHour': adjustedStartHour,
      'services': servicesPayload, // Boş olabilir
      'paidType': _selectedPaymentMethod,
    };

    // cash ve creditCard fiziki mağazada ödeme için - kart bilgileri gönderilmiyor
    // online seçildiğinde backend ödeme sistemine yönlendirecek ve HTML içerik dönecek
    // if (_selectedPaymentMethod == 'creditCard') {
    //   // Kart bilgileri fiziki mağazada alınacak, uygulama içinde gönderilmiyor
    // }

    try {
      // 1. Randevuyu oluştur
      final createdAppointment =
          await _appointmentUseCases.createAppointment(appointmentData);

      // 2. Listenin doğru görünmesi için detaylı veriyi (populate edilmiş) çek
      // Backend create yanıtında müşteri detaylarını (customer ilişkisini) dönmüyor olabilir.
      AppointmentModel finalAppointment = createdAppointment;
      try {
        if (createdAppointment.id.isNotEmpty) {
          finalAppointment = await _appointmentUseCases
              .getAppointmentDetail(createdAppointment.id);
        }
      } catch (detailError) {
        debugPrint(
            'Randevu detayı çekilemedi (UI güncellenemedi): $detailError');
        // Hata durumunda oluşturulan ilk objeyi kullanmaya devam et
      }

      Navigator.pop(context, finalAppointment);
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

