import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/branch_model.dart';

class MultiSelectCompanyDropdown extends StatefulWidget {
  final List<BranchModel> companies;
  final List<int> selectedCompanyIds;
  final Function(List<int>) onSelectionChanged;
  final String label;
  final bool isRequired;

  const MultiSelectCompanyDropdown({
    Key? key,
    required this.companies,
    required this.selectedCompanyIds,
    required this.onSelectionChanged,
    this.label = 'Firmalar',
    this.isRequired = true,
  }) : super(key: key);

  @override
  State<MultiSelectCompanyDropdown> createState() =>
      _MultiSelectCompanyDropdownState();
}

class _MultiSelectCompanyDropdownState
    extends State<MultiSelectCompanyDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<BranchModel> _filteredCompanies = [];

  @override
  void initState() {
    super.initState();
    _filteredCompanies = widget.companies;
  }

  // Helper function to get unique identifier for company selection
  // Her şube için benzersiz bir identifier döner
  // UUID kullanan şubeler için UUID string'ini hash'e çevir
  // Sayısal ID kullanan şubeler için direkt sayı kullan
  int _getCompanySelectionId(BranchModel company) {
    final parsedId = int.tryParse(company.id);
    if (parsedId != null && parsedId > 0) {
      // id sayısal ise direkt kullan
      return parsedId;
    } else {
      // UUID ise, UUID string'ini hash'e çevir (benzersiz olması için)
      // UUID'ler zaten benzersiz, hash'i de benzersiz olacak
      return company.id.hashCode;
    }
  }

  @override
  void didUpdateWidget(MultiSelectCompanyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Companies listesi güncellendiğinde filtered list'i de güncelle
    if (oldWidget.companies != widget.companies) {
      _filteredCompanies = widget.companies;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCompanies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCompanies = widget.companies;
      } else {
        _filteredCompanies =
            widget.companies
                .where(
                  (company) =>
                      company.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  void _showSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firma Seçimi',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setDialogState(() {
                        _filterCompanies(value);
                      });
                    },
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Firma ara...',
                      hintStyle: AppTypography.body2.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child:
                    _filteredCompanies.isEmpty
                        ? Center(
                          child: Text(
                            'Firma bulunamadı',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredCompanies.length,
                          itemBuilder: (context, index) {
                            final company = _filteredCompanies[index];
                            final companySelectionId = _getCompanySelectionId(company);
                            final isSelected = widget.selectedCompanyIds
                                .contains(companySelectionId);

                            return CheckboxListTile(
                              title: Text(
                                company.name,
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                company.address,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (bool? value) {
                                // Mounted kontrolü ekle - memory leak önlemi
                                if (!mounted) return;

                                setDialogState(() {
                                  if (!mounted) return; // Double check

                                  setState(() {
                                    final updatedIds = List<int>.from(
                                      widget.selectedCompanyIds,
                                    );
                                    if (value == true) {
                                      if (!updatedIds.contains(companySelectionId)) {
                                        updatedIds.add(companySelectionId);
                                      }
                                    } else {
                                      updatedIds.remove(companySelectionId);
                                    }
                                    widget.onSelectionChanged(updatedIds);
                                  });
                                });
                              },
                            );
                          },
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _filteredCompanies = widget.companies;
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Kapat',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedCompanyIds.length;
    final selectedCompanies =
        widget.companies
            .where(
              (c) =>
                  widget.selectedCompanyIds.contains(_getCompanySelectionId(c)),
            )
            .toList();

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
        GestureDetector(
          onTap: _showSelectionDialog,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color:
                    widget.isRequired && selectedCount == 0
                        ? AppColors.error.withValues(alpha: 0.3)
                        : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color:
                      selectedCount > 0
                          ? AppColors.primary
                          : AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child:
                      selectedCount == 0
                          ? Text(
                            'Firma seçiniz',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          )
                          : Text(
                            '$selectedCount firma seçildi',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
        // Selected companies chips
        if (selectedCount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children:
                selectedCompanies.map((company) {
                  final companySelectionId = _getCompanySelectionId(company);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          company.name,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              final updatedIds = List<int>.from(
                                widget.selectedCompanyIds,
                              );
                              updatedIds.remove(companySelectionId);
                              widget.onSelectionChanged(updatedIds);
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
        if (widget.isRequired && selectedCount == 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'En az bir firma seçmelisiniz',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
