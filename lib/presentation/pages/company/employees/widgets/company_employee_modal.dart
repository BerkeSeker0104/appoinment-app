import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../domain/usecases/company_user_usecases.dart';
import '../../../../../data/models/company_user_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../l10n/app_localizations.dart';

class CompanyEmployeeModal extends StatefulWidget {
  final CompanyUserModel? employee;
  final String companyId;
  final Function() onSuccess;

  const CompanyEmployeeModal({
    Key? key,
    this.employee,
    required this.companyId,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<CompanyEmployeeModal> createState() => _CompanyEmployeeModalState();
}

class _CompanyEmployeeModalState extends State<CompanyEmployeeModal> {
  final _formKey = GlobalKey<FormState>();
  final _companyUserUseCases = CompanyUserUseCases();
  
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  
  String _selectedGender = 'male';
  String _selectedState = '0';
  String _phoneCode = '90';

  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?.userDetail.name ?? '');
    _surnameController = TextEditingController(text: widget.employee?.userDetail.surname ?? '');
    _emailController = TextEditingController(text: widget.employee?.userDetail.email ?? '');
    _phoneController = TextEditingController(text: widget.employee?.userDetail.phone ?? '');
    _passwordController = TextEditingController();
    
    if (widget.employee != null) {
      _selectedGender = widget.employee!.userDetail.gender;
      _selectedState = widget.employee!.state;
      // If state is '1' (SMS verified but pending approval), show as '0' (Pending) in UI logic if needed,
      // but here we just keep it. However, dropdown only has 0, 2, 3.
      // So if it is '1', map it to '0' for the dropdown to work, or add '1' to items?
      // User said "selectte seçemeyecek 1", so map 1 -> 0.
      if (_selectedState == '1') _selectedState = '0';

      _phoneCode = widget.employee!.userDetail.phoneCode;
      if (_phoneCode.isEmpty) _phoneCode = '90';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.employee == null) {
        // Add new employee
        final data = {
          "companyId": widget.companyId,
          "name": _nameController.text.trim(),
          "surname": _surnameController.text.trim(),
          "email": _emailController.text.trim(),
          "phoneCode": _phoneCode,
          "phone": _phoneController.text.trim().replaceAll(' ', ''),
          "gender": _selectedGender,
          "password": _passwordController.text.trim(),
          "state": _selectedState,
          "picture": _selectedImage?.path,
        };
        debugPrint('Adding employee with data: $data');
        await _companyUserUseCases.addCompanyUser(data);
      } else {
        // Update existing employee
        final data = <String, dynamic>{
          "userId": widget.employee!.userId,
          "companyId": widget.companyId,
          "name": _nameController.text.trim(),
          "surname": _surnameController.text.trim(),
          "email": _emailController.text.trim(),
          "phoneCode": widget.employee!.userDetail.phoneCode.isNotEmpty 
              ? widget.employee!.userDetail.phoneCode 
              : _phoneCode,
          "phone": widget.employee!.userDetail.phone,
          "gender": _selectedGender,
          "state": _selectedState, // Send as string, not int - backend expects string
        };
        
        // Only send picture if a NEW image was selected (local file path)
        // Don't send existing server path - backend will preserve the current picture
        if (_selectedImage != null) {
          data["picture"] = _selectedImage!.path;
        }
        
        // Add password only if it's not empty
        final passwordVal = _passwordController.text.trim();
        debugPrint('DEBUG_PASSWORD_VAL: "$passwordVal" isEmpty: ${passwordVal.isEmpty}');
        
        if (passwordVal.isNotEmpty) {
          data['password'] = passwordVal;
        } else {
          data.remove('password'); // Verify it is gone
        }
        
        debugPrint('Updating employee with data: $data');
        await _companyUserUseCases.updateCompanyUser(data);
      }

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSuccess();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.employee == null 
                ? AppLocalizations.of(context)!.employeeAddedSuccess 
                : AppLocalizations.of(context)!.employeeUpdatedSuccess
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: ${e.toString().replaceAll("Exception:", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine title text
    final title = widget.employee == null ? AppLocalizations.of(context)!.newEmployee : AppLocalizations.of(context)!.editEmployee;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Profile Picture
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : (widget.employee?.userDetail.picture != null && 
                                 widget.employee!.userDetail.picture!.isNotEmpty)
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        widget.employee!.userDetail.picture!.startsWith('http')
                                            ? widget.employee!.userDetail.picture!
                                            : '${ApiConstants.fileUrl}${widget.employee!.userDetail.picture!}',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_selectedImage == null && 
                                (widget.employee?.userDetail.picture == null || 
                                 widget.employee!.userDetail.picture!.isEmpty))
                            ? Icon(Icons.camera_alt, color: AppColors.textSecondary, size: 32)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _buildTextField(
                controller: _nameController,
                label: AppLocalizations.of(context)!.firstName,
                validator: (v) => v?.isEmpty == true ? AppLocalizations.of(context)!.firstNameRequired : null,
              ),
              const SizedBox(height: 16),

              // Surname
              _buildTextField(
                controller: _surnameController,
                label: AppLocalizations.of(context)!.lastName,
                validator: (v) => v?.isEmpty == true ? AppLocalizations.of(context)!.lastNameRequired : null,
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: AppLocalizations.of(context)!.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty == true ? AppLocalizations.of(context)!.emailRequired : null,
              ),
              const SizedBox(height: 16),

              // Phone (Only editable for new users appropriately, or if API supports update)
              // Assuming phone update is not supported in the provided PUT body example, or risky. 
              // But let's allow editing for now based on typical needs, or disable if critical.
              // The API update example didn't include phone, but let's assume it might or might not.
              // For safety on update, maybe we disable phone editing or keep it enabled but API might ignore it.
              // API PUT example: userId, companyId, name, surname, email, gender, state, password.
              // Phone is NOT in PUT example. So let's disable phone for edit.
              Opacity(
                opacity: widget.employee == null ? 1.0 : 0.5,
                child: _buildTextField(
                  controller: _phoneController,
                  label: AppLocalizations.of(context)!.phoneHint,
                  keyboardType: TextInputType.phone,
                  enabled: widget.employee == null,
                  inputFormatters: [
                    _PhoneInputFormatter(),
                  ],
                  validator: (v) {
                    if (widget.employee != null) return null;
                    if (v?.isEmpty == true) return AppLocalizations.of(context)!.phoneNumberRequired;
                    final cleanPhone = v!.replaceAll(' ', '');
                    if (cleanPhone.length != 10) return AppLocalizations.of(context)!.phoneNumberInvalid;
                    return null;
                  },
                ),
              ),
              if (widget.employee != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    AppLocalizations.of(context)!.phoneNotEditable,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 16),

              // Gender
              Text(AppLocalizations.of(context)!.gender, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderOption('male', AppLocalizations.of(context)!.male),
                  const SizedBox(width: 16),
                  _buildGenderOption('female', AppLocalizations.of(context)!.female),
                ],
              ),
              const SizedBox(height: 16),

              // State Dropdown
              Text(AppLocalizations.of(context)!.status, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceCard,
                    items: [
                      DropdownMenuItem(value: '0', child: Text(AppLocalizations.of(context)!.statusPending)),
                      DropdownMenuItem(value: '2', child: Text(AppLocalizations.of(context)!.statusApproved)),
                      DropdownMenuItem(value: '3', child: Text(AppLocalizations.of(context)!.statusBanned)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedState = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              _buildTextField(
                controller: _passwordController,
                label: widget.employee == null ? AppLocalizations.of(context)!.password : AppLocalizations.of(context)!.newPasswordOptional,
                obscureText: true,
                validator: (v) {
                  if (widget.employee == null && (v?.isEmpty == true)) {
                    return AppLocalizations.of(context)!.passwordRequired;
                  }
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return AppLocalizations.of(context)!.passwordLengthError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          AppLocalizations.of(context)!.save,
                          style: AppTypography.buttonLarge.copyWith(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.surfaceCard,
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'male' ? Icons.male : Icons.female,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Sadece rakamları al
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Maksimum 10 hane
    final truncated = digits.length > 10 ? digits.substring(0, 10) : digits;

    final buffer = StringBuffer();
    // 5XX XXX XX XX formatı
    for (int i = 0; i < truncated.length; i++) {
      buffer.write(truncated[i]);
      // 3. karakterden sonra (indis 2), 6. karakterden sonra (indis 5) ve 8. karakterden sonra (indis 7) boşluk ekle
      // Ancak son karakterse boşluk ekleme (yazarken imleç sorunu olmaması için)
      if ((i == 2 || i == 5 || i == 7) && i != truncated.length - 1) {
        buffer.write(' ');
      }
    }
    
    final newText = buffer.toString();
    
    return TextEditingValue(
      text: newText,
      // İmleci her zaman sona al (basit çözüm)
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
