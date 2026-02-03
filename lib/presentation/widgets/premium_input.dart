import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class PremiumInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final bool enabled;
  final int? maxLines;
  final bool isPhoneNumber;
  final TextInputAction? textInputAction; // DÜZELTİLDİ: TextInputAction eklendi
  final List<TextInputFormatter>? inputFormatters;

  const PremiumInput({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.controller,
    this.prefixIcon,
    this.enabled = true,
    this.maxLines,
    this.isPhoneNumber = false,
    this.textInputAction, // DÜZELTİLDİ: TextInputAction parametresi eklendi
    this.inputFormatters,
  });

  @override
  State<PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<PremiumInput> {
  bool _obscureText = true;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatPhoneNumber(String value) {
    // Sadece rakamları al
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // 10 haneden fazla olamaz
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }
    
    // Format: XXX XXX XXXX
    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 6) {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
    } else {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
    }
  }

  int _calculateCursorPosition(String oldText, String newText, int oldCursorPosition) {
    // Kürsörün solundaki rakam sayısını hesapla (boşlukları saymadan)
    String oldDigitsOnly = oldText.substring(0, oldCursorPosition).replaceAll(RegExp(r'[^\d]'), '');
    int digitCount = oldDigitsOnly.length;
    
    // Yeni formatta aynı sayıda rakamın pozisyonunu bul
    String newDigitsOnly = newText.replaceAll(RegExp(r'[^\d]'), '');
    if (digitCount > newDigitsOnly.length) {
      digitCount = newDigitsOnly.length;
    }
    
    // Yeni formatta, belirtilen sayıda rakamın sonrasına kürsörü yerleştir
    int newPosition = 0;
    int digitsFound = 0;
    
    for (int i = 0; i < newText.length && digitsFound < digitCount; i++) {
      if (RegExp(r'\d').hasMatch(newText[i])) {
        digitsFound++;
      }
      newPosition = i + 1;
    }
    
    return newPosition;
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
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType:
          widget.isPhoneNumber ? TextInputType.phone : widget.keyboardType,
      textInputAction:
          widget.textInputAction, // DÜZELTİLDİ: TextInputAction eklendi
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      textAlign: TextAlign.left,
      textAlignVertical: TextAlignVertical.center,
      onChanged: (value) {
        if (widget.isPhoneNumber) {
          final oldText = _controller.text;
          final oldSelection = _controller.selection.baseOffset;
          final formatted = _formatPhoneNumber(value);
          final newCursorPosition = _calculateCursorPosition(
            oldText,
            formatted,
            oldSelection,
          );
          _controller.value = _controller.value.copyWith(
            text: formatted,
            selection: TextSelection.collapsed(offset: newCursorPosition),
          );
        }
        widget.onChanged?.call(
          widget.isPhoneNumber ? _formatPhoneNumber(value) : value,
        );
      },
      validator: widget.validator,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 0.0,
      ),
      decoration: InputDecoration(
        hintText: widget.hint ?? widget.label,
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: AppSpacing.iconSm,
                color: AppColors.textTertiary,
              )
            : null,
        prefixIconConstraints: widget.prefixIcon != null
            ? const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              )
            : null,
        suffixIcon: widget.isPassword ? _buildPasswordToggle() : null,
        filled: true,
        fillColor: widget.enabled
            ? AppColors.surfaceInput
            : AppColors.backgroundSecondary,
        border: _getBorder(AppColors.border),
        enabledBorder: _getBorder(AppColors.border),
        focusedBorder: _getBorder(AppColors.primary),
        errorBorder: _getBorder(AppColors.error),
        focusedErrorBorder: _getBorder(AppColors.error),
        isDense: false,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ).copyWith(
          left: widget.prefixIcon != null ? AppSpacing.md : AppSpacing.lg,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
          height: null,
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

  Widget? _buildPasswordToggle() {
    return IconButton(
      icon: Icon(
        _obscureText
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        size: AppSpacing.iconSm,
        color: AppColors.textTertiary,
      ),
      onPressed: () {
        setState(() {
          _obscureText = !_obscureText;
        });
      },
    );
  }
}
