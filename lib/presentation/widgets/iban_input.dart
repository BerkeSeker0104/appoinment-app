import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'iban_input_formatter.dart';

class IbanInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final bool enabled;

  const IbanInput({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.isRequired = false,
    this.onChanged,
    this.validator,
    this.controller,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  State<IbanInput> createState() => _IbanInputState();
}

class _IbanInputState extends State<IbanInput> {
  late final TextEditingController _controller;
  static const String _prefix = 'TR';

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    // Eğer initial value varsa ve TR ile başlamıyorsa, TR ekle
    if (widget.initialValue != null &&
        !widget.initialValue!.toUpperCase().startsWith(_prefix)) {
      // Initial value'dan rakamları çıkar ve formatla
      final digitsOnly = widget.initialValue!.replaceAll(RegExp(r'[^\d]'), '');
      _controller.text = IbanInputFormatter.formatIban(digitsOnly);
    } else if (widget.initialValue == null) {
      _controller.text = _prefix;
    } else {
      // Initial value zaten TR ile başlıyorsa, formatla
      final digitsOnly = widget.initialValue!.replaceAll(RegExp(r'[^\d]'), '').substring(2);
      _controller.text = IbanInputFormatter.formatIban(digitsOnly);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _getCleanIban(String formattedIban) {
    // Formatlanmış IBAN'dan temiz IBAN'ı al (TR + 24 rakam)
    String clean =
        formattedIban.replaceAll(RegExp(r'[^\dA-Za-z]'), '').toUpperCase();
    if (clean.startsWith(_prefix)) {
      return clean;
    }
    return _prefix + clean.replaceAll(RegExp(r'[^\d]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(),
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.label,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        children: widget.isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      enabled: widget.enabled,
      inputFormatters: [
        // IBAN formatter'ı kullan
        IbanInputFormatter(),
      ],
      onChanged: (value) {
        // Temiz IBAN'ı callback'e gönder
        final cleanIban = _getCleanIban(value);
        widget.onChanged?.call(cleanIban);
      },
      validator: widget.validator,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        textBaseline: TextBaseline.alphabetic,
        height: 1.0,
        letterSpacing: 0.0,
        fontFamily: 'monospace', // IBAN için monospace font daha iyi görünür
      ),
      decoration: InputDecoration(
        hintText: widget.hint ?? 'TR00 0000 0000 0000 0000 0000 00',
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: AppSpacing.iconSm,
                color: AppColors.textTertiary,
              )
            : null,
        filled: true,
        fillColor: widget.enabled
            ? AppColors.surfaceInput
            : AppColors.backgroundSecondary,
        border: _getBorder(AppColors.border),
        enabledBorder: _getBorder(AppColors.border),
        focusedBorder: _getBorder(AppColors.primary),
        errorBorder: _getBorder(AppColors.error),
        focusedErrorBorder: _getBorder(AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  OutlineInputBorder _getBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(
        color: color,
        width: color == AppColors.primary ? 1.2 : 0.5,
      ),
    );
  }
}
