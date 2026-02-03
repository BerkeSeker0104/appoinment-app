import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/user_address.dart';
import '../../providers/address_provider.dart';
import '../../widgets/address_card_widget.dart';
import '../../widgets/premium_button.dart';
import 'add_edit_address_page.dart';
import '../../../l10n/app_localizations.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myAddresses,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.deliveryAddresses),
            Tab(text: AppLocalizations.of(context)!.invoiceAddresses),
          ],
        ),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.addresses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppLocalizations.of(context)!.error,
                    style: AppTypography.h5,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    provider.errorMessage ?? AppLocalizations.of(context)!.unknownError,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PremiumButton(
                    text: AppLocalizations.of(context)!.retry,
                    onPressed: () => provider.loadAddresses(),
                    variant: ButtonVariant.primary,
                    isFullWidth: false,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddressList(
                      context,
                      provider.deliveryAddresses,
                      AddressType.delivery,
                      provider.selectedDeliveryAddress,
                      (address) => provider.selectDeliveryAddress(address),
                    ),
                    _buildAddressList(
                      context,
                      provider.invoiceAddresses,
                      AddressType.invoice,
                      provider.selectedInvoiceAddress,
                      (address) => provider.selectInvoiceAddress(address),
                    ),
                  ],
                ),
              ),
              _buildAddButton(context, _tabController.index),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressList(
    BuildContext context,
    List<UserAddress> addresses,
    AddressType type,
    UserAddress? selectedAddress,
    Function(UserAddress) onSelect,
  ) {
    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.noAddressYet,
              style: AppTypography.h6.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.addAddressPrompt,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AddressProvider>().loadAddresses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          final isSelected = selectedAddress?.id == address.id;

          return AddressCardWidget(
            address: address,
            isSelected: isSelected,
            showSelection: true,
            onTap: () => onSelect(address),
            onEdit: () => _navigateToEdit(context, address),
            onDelete: () => _showDeleteDialog(context, address),
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, int tabIndex) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: PremiumButton(
          text: AppLocalizations.of(context)!.addNewAddress,
          onPressed: () => _navigateToAdd(
            context,
            tabIndex == 0 ? AddressType.delivery : AddressType.invoice,
          ),
          variant: ButtonVariant.primary,
          icon: Icons.add,
        ),
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

  void _navigateToEdit(BuildContext context, UserAddress address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressPage(address: address),
      ),
    );

    if (result == true && context.mounted) {
      context.read<AddressProvider>().loadAddresses();
    }
  }

  void _showDeleteDialog(BuildContext context, UserAddress address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteAddress,
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteAddressConfirm,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await context.read<AddressProvider>().deleteAddress(address.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.addressDeletedSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

