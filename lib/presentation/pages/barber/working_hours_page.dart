import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class WorkingHoursPage extends StatefulWidget {
  const WorkingHoursPage({super.key});

  @override
  State<WorkingHoursPage> createState() => _WorkingHoursPageState();
}

class _WorkingHoursPageState extends State<WorkingHoursPage> {
  final Map<String, Map<String, dynamic>> _workingHours = {
    'Pazartesi': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 9, minute: 0),
      'closeTime': const TimeOfDay(hour: 18, minute: 0),
    },
    'Salı': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 9, minute: 0),
      'closeTime': const TimeOfDay(hour: 18, minute: 0),
    },
    'Çarşamba': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 9, minute: 0),
      'closeTime': const TimeOfDay(hour: 18, minute: 0),
    },
    'Perşembe': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 9, minute: 0),
      'closeTime': const TimeOfDay(hour: 18, minute: 0),
    },
    'Cuma': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 9, minute: 0),
      'closeTime': const TimeOfDay(hour: 18, minute: 0),
    },
    'Cumartesi': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 10, minute: 0),
      'closeTime': const TimeOfDay(hour: 16, minute: 0),
    },
    'Pazar': {
      'isOpen': false,
      'openTime': const TimeOfDay(hour: 10, minute: 0),
      'closeTime': const TimeOfDay(hour: 16, minute: 0),
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCurrentStatus(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildWorkingHoursList(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Çalışma Saatleri',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Haftalık program ayarları',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Text(
              'Kaydet',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final today = DateTime.now();
    final dayNames = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
    final todayName = dayNames[today.weekday % 7];
    final todaySchedule = _workingHours[todayName]!;
    final isOpenToday = todaySchedule['isOpen'] as bool;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isOpenToday 
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              isOpenToday ? Icons.schedule : Icons.schedule_outlined,
              color: isOpenToday ? AppColors.success : AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün ($todayName)',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isOpenToday 
                      ? '${_formatTime(todaySchedule['openTime'])} - ${_formatTime(todaySchedule['closeTime'])}'
                      : 'Kapalı',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isOpenToday ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isOpenToday 
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isOpenToday ? AppColors.success : AppColors.error,
                width: 1,
              ),
            ),
            child: Text(
              isOpenToday ? 'AÇIK' : 'KAPALI',
              style: AppTypography.bodySmall.copyWith(
                color: isOpenToday ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Haftalık Program',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._workingHours.entries.map((entry) => 
            _buildDayCard(entry.key, entry.value)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, Map<String, dynamic> schedule) {
    final isOpen = schedule['isOpen'] as bool;
    final openTime = schedule['openTime'] as TimeOfDay;
    final closeTime = schedule['closeTime'] as TimeOfDay;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isOpen
                ? Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(day, 'open'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _formatTime(openTime),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.textTertiary,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(day, 'close'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _formatTime(closeTime),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Kapalı',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: isOpen,
            onChanged: (value) {
              setState(() {
                _workingHours[day]!['isOpen'] = value;
              });
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Ayarlar',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Tümünü Aç',
                  Icons.schedule,
                  AppColors.success,
                  _openAllDays,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildQuickActionButton(
                  'Tümünü Kapat',
                  Icons.schedule_outlined,
                  AppColors.error,
                  _closeAllDays,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Standart Mesai',
                  Icons.business_center,
                  AppColors.primary,
                  _setStandardHours,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildQuickActionButton(
                  'Hafta Sonu',
                  Icons.weekend,
                  AppColors.secondary,
                  _setWeekendHours,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(String day, String type) async {
    final currentTime = _workingHours[day]![type == 'open' ? 'openTime' : 'closeTime'] as TimeOfDay;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentTime) {
      setState(() {
        _workingHours[day]![type == 'open' ? 'openTime' : 'closeTime'] = picked;
      });
    }
  }

  void _openAllDays() {
    setState(() {
      _workingHours.forEach((key, value) {
        value['isOpen'] = true;
      });
    });
  }

  void _closeAllDays() {
    setState(() {
      _workingHours.forEach((key, value) {
        value['isOpen'] = false;
      });
    });
  }

  void _setStandardHours() {
    setState(() {
      final standardDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma'];
      for (final day in standardDays) {
        _workingHours[day]!['isOpen'] = true;
        _workingHours[day]!['openTime'] = const TimeOfDay(hour: 9, minute: 0);
        _workingHours[day]!['closeTime'] = const TimeOfDay(hour: 18, minute: 0);
      }
      _workingHours['Cumartesi']!['isOpen'] = false;
      _workingHours['Pazar']!['isOpen'] = false;
    });
  }

  void _setWeekendHours() {
    setState(() {
      _workingHours['Cumartesi']!['isOpen'] = true;
      _workingHours['Cumartesi']!['openTime'] = const TimeOfDay(hour: 10, minute: 0);
      _workingHours['Cumartesi']!['closeTime'] = const TimeOfDay(hour: 16, minute: 0);
      
      _workingHours['Pazar']!['isOpen'] = true;
      _workingHours['Pazar']!['openTime'] = const TimeOfDay(hour: 10, minute: 0);
      _workingHours['Pazar']!['closeTime'] = const TimeOfDay(hour: 16, minute: 0);
    });
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Çalışma saatleri başarıyla kaydedildi'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
