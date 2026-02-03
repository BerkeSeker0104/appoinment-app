import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../domain/entities/user_address.dart';
import '../providers/address_provider.dart';
import '../pages/customer/add_edit_address_page.dart';
import 'premium_button.dart';

class AddressSelectionWidget extends StatelessWidget {
  final AddressType addressType;
  final UserAddress? selectedAddress;
  final Function(UserAddress?) onAddressSelected;
  final String label;

  const AddressSelectionWidget({
    super.key,
    required this.addressType,
    this.selectedAddress,
    required this.onAddressSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (context, provider, child) {
        final addresses = addressType == AddressType.delivery
            ? provider.deliveryAddresses
            : provider.invoiceAddresses;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToAdd(context, addressType),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (addresses.isEmpty)
              _buildEmptyState(context, addressType)
            else
              _buildAddressList(context, addresses, selectedAddress),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AddressType type) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Henüz adres eklenmemiş',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PremiumButton(
            text: 'Yeni Adres Ekle',
            onPressed: () => _navigateToAdd(context, type),
            variant: ButtonVariant.secondary,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(
    BuildContext context,
    List<UserAddress> addresses,
    UserAddress? selectedAddress,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: addresses.asMap().entries.map((entry) {
          final index = entry.key;
          final address = entry.value;
          final isSelected = selectedAddress?.id == address.id;
          final isLast = index == addresses.length - 1;

          return InkWell(
            onTap: () => onAddressSelected(address),
            borderRadius: BorderRadius.vertical(
              top: index == 0
                  ? const Radius.circular(AppSpacing.radiusXl)
                  : Radius.zero,
              bottom: isLast
                  ? const Radius.circular(AppSpacing.radiusXl)
                  : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.addressName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          address.fullName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          address.address,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToAdd(BuildContext context, AddressType type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressPage(addressType: type),
      ),
    );

    if (result == true && context.mounted) {
      context.read<AddressProvider>().loadAddresses();
    }
  }
}

