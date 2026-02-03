import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

enum DurationUnit { minutes, hours }

class DurationPickerWidget extends StatefulWidget {
  final int initialDurationInMinutes;
  final Function(int) onDurationChanged;
  final String label;
  final bool isRequired;

  const DurationPickerWidget({
    Key? key,
    required this.initialDurationInMinutes,
    required this.onDurationChanged,
    this.label = 'Süre',
    this.isRequired = true,
  }) : super(key: key);

  @override
  State<DurationPickerWidget> createState() => _DurationPickerWidgetState();
}

class _DurationPickerWidgetState extends State<DurationPickerWidget> {
  late TextEditingController _durationController;
  late DurationUnit _selectedUnit;
  int _currentDurationInMinutes = 0;

  @override
  void initState() {
    super.initState();
    _currentDurationInMinutes = widget.initialDurationInMinutes;
    _initializeDuration();
  }

  void _initializeDuration() {
    // Eğer dakika 60'ın katıysa, saat olarak göster
    if (_currentDurationInMinutes > 0 && _currentDurationInMinutes % 60 == 0) {
      _selectedUnit = DurationUnit.hours;
      final hours = _currentDurationInMinutes ~/ 60;
      _durationController = TextEditingController(text: hours.toString());
    } else {
      _selectedUnit = DurationUnit.minutes;
      _durationController = TextEditingController(
        text:
            _currentDurationInMinutes > 0
                ? _currentDurationInMinutes.toString()
                : '',
      );
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _updateDuration() {
    final inputValue = int.tryParse(_durationController.text) ?? 0;
    if (inputValue <= 0) {
      _currentDurationInMinutes = 0;
      widget.onDurationChanged(0);
      return;
    }

    // Convert to minutes based on unit
    if (_selectedUnit == DurationUnit.hours) {
      _currentDurationInMinutes = inputValue * 60;
    } else {
      _currentDurationInMinutes = inputValue;
    }

    widget.onDurationChanged(_currentDurationInMinutes);
  }

  void _onUnitChanged(DurationUnit? newUnit) {
    if (newUnit == null || newUnit == _selectedUnit) return;

    setState(() {
      final currentValue = int.tryParse(_durationController.text) ?? 0;

      if (newUnit == DurationUnit.hours) {
        // Dakika → Saat
        // Eğer dakika 60'ın katıysa, saat'e dönüştür
        if (currentValue % 60 == 0) {
          _durationController.text = (currentValue ~/ 60).toString();
        } else {
          // Tam bölünmüyorsa, en yakın saate yuvarla
          _durationController.text = ((currentValue / 60).round()).toString();
        }
      } else {
        // Saat → Dakika
        _durationController.text = (currentValue * 60).toString();
      }

      _selectedUnit = newUnit;
      _updateDuration();
    });
  }

  String _getDurationDisplay() {
    if (_currentDurationInMinutes <= 0) return '';
    return '$_currentDurationInMinutes dakika';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: AppTypography.body2.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            // Duration input
            Expanded(
              flex: 2,
              child: TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Miktar',
                  hintStyle: AppTypography.body1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (_) => _updateDuration(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Unit dropdown
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DurationUnit>(
                    value: _selectedUnit,
                    isExpanded: true,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textTertiary,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DurationUnit.minutes,
                        child: Text('Dakika'),
                      ),
                      DropdownMenuItem(
                        value: DurationUnit.hours,
                        child: Text('Saat'),
                      ),
                    ],
                    onChanged: _onUnitChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Duration display helper
        if (_currentDurationInMinutes > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _getDurationDisplay(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Validation message
        if (widget.isRequired && _currentDurationInMinutes <= 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Süre girmelisiniz',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
