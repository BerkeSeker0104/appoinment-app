import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/category.dart' as entity;
import '../../../domain/usecases/product_usecases.dart';
import '../../../data/repositories/product_repository_impl.dart';
import '../../../data/services/system_api_service.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import '../../../l10n/app_localizations.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final ProductUseCases _productUseCases =
      ProductUseCases(ProductRepositoryImpl());
  final SystemApiService _systemApiService = SystemApiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  List<File> _selectedImages = [];
  List<entity.Category> _categories = [];
  entity.Category? _selectedCategory;
  double _commissionRate = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSystemConfig();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productUseCases.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
    }
  }

  Future<void> _loadSystemConfig() async {
    try {
      final config = await _systemApiService.getSystemConfig();
      if (mounted) {
        setState(() {
          _commissionRate = config.productCommissionRate;
        });
      }
    } catch (e) {
      debugPrint('Error loading system config: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final List<File> imageFiles =
            images.map((image) => File(image.path)).toList();

        // Check file sizes
        for (final file in imageFiles) {
          final int fileSizeInBytes = await file.length();
          final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.fileSizeError,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }

        setState(() {
          _selectedImages.addAll(imageFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.imagePickError,
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text(
            AppLocalizations.of(context)!.selectCategoryError,
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text(
            AppLocalizations.of(context)!.selectImageError,
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _productUseCases.createProduct(
        categoryId: _selectedCategory!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        pictures: _selectedImages,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.productCreatedSuccess,
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
          AppLocalizations.of(context)!.newProductTitle,
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Product Images
                      Text(
                        AppLocalizations.of(context)!.productImages,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildImagePicker(),
                      const SizedBox(height: AppSpacing.md),
                      _buildImagePreview(),
                      const SizedBox(height: AppSpacing.lg),

                      // Product Name
                      Text(
                        AppLocalizations.of(context)!.productName,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PremiumInput(
                        controller: _nameController,
                        label: AppLocalizations.of(context)!.productNameLabel,
                        hint: AppLocalizations.of(context)!.productNameHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.productNameRequired;
                          }
                          if (value.length < 2) {
                            return AppLocalizations.of(context)!.productNameMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Description
                      Text(
                        AppLocalizations.of(context)!.description,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PremiumInput(
                        controller: _descriptionController,
                        label: AppLocalizations.of(context)!.productDescriptionLabel,
                        hint: AppLocalizations.of(context)!.productDescriptionHint,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.productDescriptionRequired;
                          }
                          if (value.length < 10) {
                            return AppLocalizations.of(context)!.productDescriptionMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Price
                      Text(
                        AppLocalizations.of(context)!.price,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PremiumInput(
                        controller: _priceController,
                        label: AppLocalizations.of(context)!.priceCurrency,
                        hint: AppLocalizations.of(context)!.priceHint,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.priceRequired;
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return AppLocalizations.of(context)!.invalidPrice;
                          }
                          return null;
                        },
                      ),
                      if (_commissionRate > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _priceController,
                          builder: (context, value, child) {
                            final price = double.tryParse(value.text.trim());
                            if (price == null || price <= 0) {
                              return const SizedBox.shrink();
                            }

                            final commissionAmount =
                                price * (_commissionRate / 100);
                            final earning = price - commissionAmount;

                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.commissionRate(_commissionRate.toStringAsFixed(0)),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '-${commissionAmount.toStringAsFixed(2)} TL',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.estimatedEarnings,
                                        style: AppTypography.body2.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${earning.toStringAsFixed(2)} TL',
                                        style: AppTypography.body2.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),

                      // Category Selection
                      Text(
                        AppLocalizations.of(context)!.category,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildCategoryDropdown(),
                      const SizedBox(height: AppSpacing.xl),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: PremiumButton(
              text: AppLocalizations.of(context)!.createProduct,
              onPressed: _isLoading ? null : _handleSubmit,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              color: AppColors.accent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.pickImage,
              style: AppTypography.body1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Image.file(
                      image,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<entity.Category>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.selectCategory,
          labelStyle: AppTypography.body1.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem<entity.Category>(
            value: category,
            child: Text(
              category.nameTr,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (entity.Category? newValue) {
          setState(() {
            _selectedCategory = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return AppLocalizations.of(context)!.selectCategoryError;
          }
          return null;
        },
      ),
    );
  }
}
