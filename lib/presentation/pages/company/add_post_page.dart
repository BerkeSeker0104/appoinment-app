import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/usecases/post_usecases.dart';
import '../../../domain/usecases/branch_usecases.dart';
import '../../../data/repositories/post_repository_impl.dart';
import '../../../data/repositories/branch_repository_impl.dart';
import '../../../data/models/branch_model.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  final PostUseCases _postUseCases = PostUseCases(PostRepositoryImpl());
  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  final ImagePicker _imagePicker = ImagePicker();

  BranchModel? _selectedCompany;
  List<BranchModel> _companies = [];
  bool _isLoadingCompanies = true;
  bool _isLoading = false;
  List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Backend'e gönderilecek companyId'yi döner
  // Backend artık UUID string kabul ediyor, direkt branch.id'yi gönder
  String _getBackendCompanyId(BranchModel company) {
    // UUID veya sayısal ID olabilir, her ikisini de backend kabul ediyor
    return company.id;
  }

  Future<void> _loadCompanies() async {
    try {
      setState(() => _isLoadingCompanies = true);
      final branches = await _branchUseCases.getBranches();
      setState(() {
        _companies = branches;
        // TEMPORARILY: Auto-select the first branch since there's only one branch now
        if (_companies.isNotEmpty) {
          _selectedCompany = _companies.first;
        }
        _isLoadingCompanies = false;
      });
    } catch (e) {
      setState(() => _isLoadingCompanies = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firmalar yüklenemedi: ${e.toString().replaceFirst('Exception: ', '')}',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        List<File> validFiles = [];

        for (var image in images) {
          final File imageFile = File(image.path);
          final int fileSizeInBytes = await imageFile.length();
          final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${image.name} dosyası 5MB\'dan büyük, atlandı',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            continue;
          }

          validFiles.add(imageFile);
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(validFiles);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resimler seçilirken hata oluştu',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _onFileReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    setState(() {
      final movedFile = _selectedFiles.removeAt(oldIndex);
      _selectedFiles.insert(newIndex, movedFile);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // TEMPORARILY: Company validation - since we auto-select the only branch
    if (_selectedCompany == null || _companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Şube bulunamadı. Lütfen önce şube oluşturun.',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen en az bir dosya seçiniz',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Backend için gerçek companyId'yi al
      // UUID'li şubeler için companyId field'ını kullan (sayısal)
      // Sayısal ID'li şubeler için direkt id kullan
      final backendCompanyId = _getBackendCompanyId(_selectedCompany!);

      await _postUseCases.createPost(
        companyId: backendCompanyId,
        description: _descriptionController.text.trim(),
        files: _selectedFiles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gönderi başarıyla oluşturuldu',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Gönderi',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoadingCompanies
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: AppSpacing.screenHorizontal,
                            right: AppSpacing.screenHorizontal,
                            top: AppSpacing.screenHorizontal,
                            bottom: AppSpacing.screenHorizontal,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSpacing.md),

                                // TEMPORARILY COMMENTED OUT - Company selection (only one branch now, auto-selected)
                                // // Company Selection
                                // Text(
                                //   'Firma Seçimi',
                                //   style: AppTypography.body1.copyWith(
                                //     color: AppColors.textPrimary,
                                //     fontWeight: FontWeight.w600,
                                //   ),
                                // ),
                                // const SizedBox(height: AppSpacing.sm),
                                // _buildCompanyDropdown(),
                                // const SizedBox(height: AppSpacing.lg),

                                // Description
                                Text(
                                  'Açıklama',
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PremiumInput(
                                  controller: _descriptionController,
                                  label: 'Gönderi açıklaması',
                                  hint: 'Gönderinizi açıklayın...',
                                  maxLines: 5,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Lütfen açıklama giriniz';
                                    }
                                    if (value.length < 10) {
                                      return 'Açıklama en az 10 karakter olmalıdır';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Files
                                Text(
                                  'Dosyalar',
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                _buildFilePicker(),
                                const SizedBox(height: AppSpacing.md),
                                _buildFilePreview(),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fixed Bottom Button
                    Container(
                      padding: EdgeInsets.only(
                        left: AppSpacing.screenHorizontal,
                        right: AppSpacing.screenHorizontal,
                        top: AppSpacing.screenHorizontal,
                        bottom: MediaQuery.of(context).padding.bottom +
                            AppSpacing.screenHorizontal,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: PremiumButton(
                        text: 'Gönderiyi Paylaş',
                        onPressed: _isLoading ? null : _handleSubmit,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
                // Loading Overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  // TEMPORARILY COMMENTED OUT - Company dropdown (only one branch now, auto-selected)
  // Widget _buildCompanyDropdown() {
  //   if (_companies.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(AppSpacing.md),
  //       decoration: BoxDecoration(
  //         color: AppColors.surface,
  //         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //         border: Border.all(color: AppColors.border),
  //       ),
  //       child: Text(
  //         'Henüz firma bulunamadı',
  //         style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
  //       ),
  //     );
  //   }

  //   return Container(
  //     decoration: BoxDecoration(
  //       color: AppColors.surface,
  //       borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //       border: Border.all(color: AppColors.border),
  //     ),
  //     child: DropdownButtonHideUnderline(
  //       child: DropdownButton<BranchModel>(
  //         value: _selectedCompany,
  //         isExpanded: true,
  //         padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  //         icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
  //         dropdownColor: AppColors.surface,
  //         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //         style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
  //         items: _companies.map((company) {
  //           return DropdownMenuItem<BranchModel>(
  //             value: company,
  //             child: Row(
  //               children: [
  //                 Icon(Icons.business, size: 20, color: AppColors.primary),
  //                 const SizedBox(width: AppSpacing.sm),
  //                 Expanded(
  //                   child: Text(
  //                     company.name,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //         onChanged: (BranchModel? value) {
  //           setState(() {
  //             _selectedCompany = value;
  //           });
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Dosya Seç',
              style: AppTypography.body1.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maksimum 5MB, birden fazla dosya seçebilirsiniz',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    if (_selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seçilen Dosyalar (${_selectedFiles.length})',
          style: AppTypography.body2.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ReorderableGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
          onReorder: _onFileReorder,
          children: _selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildFilePreviewItem(file, index);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilePreviewItem(File file, int index) {
    return Container(
      key: ValueKey('file_${file.path}'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Drag handle indicator (sol üst)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.surface,
                size: 14,
              ),
            ),
          ),
          // Delete button (sağ üst)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeFile(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
